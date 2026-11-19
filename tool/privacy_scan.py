#!/usr/bin/env python3
"""Keep personal data and server details out of commits and pushes.

  privacy_scan.py --staged          staged changes (pre-commit)
  privacy_scan.py --message FILE    commit message (commit-msg)
  privacy_scan.py --range A..B      every commit in the range and its message (pre-push, CI)

Found values are never printed, only file:line and the kind.
Put `privacy-ok` on a line only when it is truly safe.
"""
import codecs
import ipaddress
import re
import subprocess
import sys

SKIP_PATH = re.compile(
    r"(pubspec\.lock|Podfile\.lock|package-lock\.json|\.svg|\.pbxproj)$"
    r"|(^|/)(LICENSE|NOTICE|COPYING)[^/]*$"
)
# Lock files, SVG and lines over 2000 chars are full of hashes and path data, so they get a partial scan:
# known key shapes and secret assignments are still caught there.
GENERATED_LINE = 2000

# Files that must never be committed: signing keys, store keys, env files, Firebase config.
SECRET_FILE = re.compile(
    r"(^|/)\.env(\.[^/]*)?$|\.(jks|keystore|p8|p12|pem|key|mobileprovision|cer)$"
    r"|(^|/)key\.properties$|(^|/)google-services\.json$|(^|/)GoogleService-Info\.plist$"
)
SECRET_FILE_OK = re.compile(r"\.env\.example$")

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})")
EMAIL_OK = re.compile(
    r"(^|\.)(example\.(com|org|net)|noreply\.github\.com|anthropic\.com|localhost|test|invalid|example)$",
    re.I,
)
# File names with a scale suffix such as Icon-App-20x20@2x.png are not emails.
FILE_EXT = re.compile(r"\.(png|jpe?g|gif|webp|svg|pdf|ttf|otf)$", re.I)
IPV4 = re.compile(r"(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])")
IP_OK = [ipaddress.ip_network(n) for n in (
    "127.0.0.0/8", "0.0.0.0/32", "255.255.255.0/24",
    "192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24",
    "1.1.1.1/32", "1.0.0.1/32", "8.8.8.8/32", "8.8.4.4/32",
)]
PRIVATE = [ipaddress.ip_network(n) for n in ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10")]
URL_OR_PORT = re.compile(r"://|:\d{2,5}\b")
# A version word counts only when it stands directly in front of the number (separators and quotes
# allowed), so a short version field earlier on the line cannot hide a host address after it.
VERSION_BEFORE = re.compile(r"(?:\bversion|\bbuild)[\s\"':=v]{0,6}$|\bv$", re.I)
IPV6 = re.compile(r"(?<![\w:.])([0-9a-fA-F]{0,4}(?::[0-9a-fA-F]{0,4}){2,7})(?![\w:])")
INTERNAL_HOST = re.compile(
    r"\b[a-z0-9-]+\.(lan|local|internal|intranet|corp|localdomain|home\.arpa)(?!\.?[\w-])", re.I
)
NET_CONTEXT = re.compile(r"://|\b(host|ip|addr|address|server|endpoint|connect|curl|ssh|ping)\b|:\d{2,5}\b", re.I)
TAILNET = re.compile(r"\.ts\.net\b")
OPS_PATH = re.compile(r"/mnt/[\w-]+|/srv/[\w-]+|appdata/|/volume\d/")  # privacy-ok
HOME = re.compile(r"(?:/home|/Users)/([A-Za-z_][\w.-]*)")
HOME_OK = {"user", "runner", "node", "ubuntu", "app", "me", "you", "example", "username", "Shared", "<user>"}
SHA_CONTEXT = re.compile(r"commit|\bsha|\brev\b|revision|checkout|github\.com|git\b|@", re.I)
SHA256_CONTEXT = re.compile(r"sha-?256", re.I)
HEX = re.compile(r"(?<![0-9a-fA-F])[0-9a-f]{40,}(?![0-9a-fA-F])")
SECRET = re.compile(r"(api[_-]?key|secret|token|password)['\"]?\s*[:=]\s*['\"]([A-Za-z0-9_\-./+=]{20,})['\"]", re.I)
KNOWN_KEY = re.compile(r"AIza[0-9A-Za-z_\-]{35}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{36}|-----BEGIN [A-Z ]*PRIVATE KEY")
# Latitude/longitude pairs with 4+ decimals (about 10 m) can point at a real home.
COORD = re.compile(r"(?<![\w.])-?\d{1,2}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}(?![\d])")


def strong_findings(line):
    """Checks that apply everywhere: known key shapes and secret assignments."""
    out = []
    for m in SECRET.finditer(line):
        v = m.group(2)
        if re.search(r"[a-z]", v) and re.search(r"[A-Z]", v) and re.search(r"\d", v) and len(set(v)) > 10:
            out.append("secret")
            break
    if KNOWN_KEY.search(line):
        out.append("key")
    return out


def ip_findings(line):
    for m in IPV4.finditer(line):
        parts = [int(p) for p in m.groups()]
        if max(parts) > 255 or line[m.end():m.end() + 1] == "/":
            continue
        ip = ipaddress.ip_address(".".join(map(str, parts)))
        if any(ip in n for n in IP_OK):
            continue
        net = NET_CONTEXT.search(line)
        if any(ip in n for n in PRIVATE):
            # Only a version word right before the number makes it a version.
            before = line[max(0, m.start() - 24):m.start()]
            versionish = VERSION_BEFORE.search(before) and not URL_OR_PORT.search(line)
            if parts[3] not in (0, 255) and not versionish:
                return ["IP"]
        elif ip.is_global and net:
            return ["IP"]
    for m in IPV6.finditer(line):
        try:
            ip = ipaddress.IPv6Address(m.group(1))
        except ValueError:
            continue
        if ip in ipaddress.ip_network("2001:db8::/32") or ip.is_loopback or ip.is_unspecified:
            continue
        if ip.is_private and not ip.is_reserved or ip.is_link_local or (ip.is_global and not ip.is_reserved and NET_CONTEXT.search(line)):
            return ["IP"]
    return []


def findings_in_line(line):
    if "privacy-ok" in line:
        return []
    out = []
    for m in EMAIL.finditer(line):
        if FILE_EXT.search(m.group(1)):
            continue
        if not EMAIL_OK.search(m.group(1)) and m.group(0).split("@")[0] != "git":
            out.append("email")
            break
    out += ip_findings(line)
    if INTERNAL_HOST.search(line) and NET_CONTEXT.search(line):
        out.append("internal host")
    if TAILNET.search(line):
        out.append("Tailscale address")
    if OPS_PATH.search(line):
        out.append("ops path")
    if any(m.group(1) not in HOME_OK for m in HOME.finditer(line)):
        out.append("home path")
    for m in HEX.finditer(line):
        v = m.group(0)
        sha = (len(v) == 40 and SHA_CONTEXT.search(line)) or (len(v) == 64 and SHA256_CONTEXT.search(line))
        if len(set(v)) > 4 and not sha:
            out.append("long hex")
            break
    out += strong_findings(line)
    if COORD.search(line):
        out.append("coordinates")
    return out


def diff_path(header):
    # git ends an unquoted header with a TAB when the path has a space.
    path = header[4:].rstrip("\t")
    if path.startswith('"') and path.endswith('"'):
        # git wraps special characters in C escapes (\" \t \354). Decode to bytes, then read UTF-8.
        path = codecs.escape_decode(path[1:-1].encode("utf-8"))[0].decode("utf-8", "replace")
    return path[2:] if path.startswith("b/") else path


HUNK = re.compile(r"^@@ -\d+(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")
# Combined diff of a merge (two parents): "@@@ -a,b -c,d +e,f @@@" and two prefix columns per line.
HUNK_CC = re.compile(r"^@@@ -\d+(?:,\d+)? -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@@")


def diff_lines(diff):
    """Yield (path, line number, added line). Hunk line counts decide what is content, so a line starting with '+++ ' is not taken for a header."""
    path, lineno, old_left, new_left, cc_left = "?", 0, 0, 0, 0
    # split on newline only: splitlines() also breaks on U+2028 and friends, which git does not.
    for raw in diff.split("\n"):
        if cc_left:
            prefix = raw[:2]
            if "-" not in prefix:
                cc_left -= 1
                lineno += 1
                if prefix == "++":
                    yield path, lineno, raw[2:]
            continue
        if old_left or new_left:
            if raw.startswith("-"):
                old_left -= 1
            elif raw.startswith("+"):
                new_left -= 1
                lineno += 1
                yield path, lineno, raw[1:]
            elif not raw.startswith("\\"):
                old_left, new_left, lineno = old_left - 1, new_left - 1, lineno + 1
            continue
        if raw.startswith("+++ "):
            path = diff_path(raw)
        m = HUNK_CC.match(raw)
        if m:
            cc_left = int(m.group(2) if m.group(2) is not None else 1)
            lineno = int(m.group(1)) - 1
            continue
        m = HUNK.match(raw)
        if m:
            old_left = int(m.group(1) if m.group(1) is not None else 1)
            new_left = int(m.group(3) if m.group(3) is not None else 1)
            lineno = int(m.group(2)) - 1


def scan_diff(diff):
    hits = []
    for path, lineno, line in diff_lines(diff):
        raw = "+" + line
        if "privacy-ok" in raw:
            continue
        partial = SKIP_PATH.search(path) or len(raw) > GENERATED_LINE
        kinds = strong_findings(raw[1:]) if partial else findings_in_line(raw[1:])
        hits += [f"{path}:{lineno} {kind}" for kind in kinds]
    return hits


def scan_text(label, text):
    return [f"{label}:{i} {kind}" for i, line in enumerate(text.splitlines(), 1) for kind in findings_in_line(line)]


def scan_files(names):
    return [f"{n} secret file" for n in names if SECRET_FILE.search(n) and not SECRET_FILE_OK.search(n)]


def git(*args):
    # With quotePath off, non-ASCII paths come out as-is instead of quoted octal.
    r = subprocess.run(["git", "-c", "core.quotePath=false", *args], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout


def report(hits):
    if not hits:
        return 0
    print("Found what looks like personal data or server details. Values are not printed.", file=sys.stderr)
    for h in hits[:30]:
        print(f"  {h}", file=sys.stderr)
    if len(hits) > 30:
        print(f"  and {len(hits) - 30} more", file=sys.stderr)
    print(
        "Use documentation values (192.0.2.x, example.com, fake keys, fake coordinates). "
        "Mark a line privacy-ok only when it is truly safe.",
        file=sys.stderr,
    )
    return 1


def names_z(out):
    return sorted({n.strip("\n") for n in out.split("\0") if n.strip("\n")})


SCISSORS = re.compile(r"^# -+ >8 -+$")


GIT_SCISSORS_NOTE = "# Do not modify or remove the line above."


def message_text(raw):
    """Scan comment lines too: -F and cleanup=verbatim keep them in the commit.
    Stop only at the scissors block git itself writes for `commit -v`, which git always cuts."""
    lines = raw.split("\n")
    for i, line in enumerate(lines):
        if SCISSORS.match(line) and i + 1 < len(lines) and lines[i + 1].strip() == GIT_SCISSORS_NOTE:
            return "\n".join(lines[:i])
    return "\n".join(lines)


# Plain git log -p hides merge diffs. Dense combined diff shows only what the merge itself adds
# relative to every parent, so lines that arrive from the base branch are not reported again.
MERGES = "--diff-merges=dense-combined"
# A rename is reported as delete + add, so a file moved into a stricter folder is scanned in full.
NO_RENAMES = "--no-renames"


def main(argv):
    if len(argv) == 1 and argv[0] == "--staged":
        names = names_z(git("diff", "--cached", NO_RENAMES, "--name-only", "-z", "--diff-filter=ACMR"))
        return report(scan_files(names) + scan_diff(git("diff", "--cached", NO_RENAMES, "-U0", "--no-color")))
    if len(argv) == 2 and argv[0] == "--message":
        with open(argv[1], encoding="utf-8", errors="ignore") as f:
            return report(scan_text("commit message", message_text(f.read())))
    if len(argv) == 2 and argv[0] == "--range":
        # Comparing only the end points misses what a middle commit added and a later one removed.
        rng = argv[1]
        names = names_z(git("log", MERGES, NO_RENAMES, "--name-only", "-z", "--diff-filter=ACMR", "--format=", rng))
        hits = scan_files(names) + scan_diff(git("log", MERGES, NO_RENAMES, "-p", "-U0", "--no-color", "--format=", rng))
        return report(hits + scan_text("commit message", git("log", "--format=%B", rng)))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
