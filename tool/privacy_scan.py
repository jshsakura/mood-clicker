#!/usr/bin/env python3
"""커밋과 push 에 개인정보와 서버 정보가 섞이지 않게 막는다.

  privacy_scan.py --staged          스테이징된 변경 (pre-commit)
  privacy_scan.py --message FILE    커밋 메시지 (commit-msg)
  privacy_scan.py --range A..B      범위 안의 커밋 하나하나와 그 메시지 (pre-push, CI)

찾은 값은 출력하지 않는다. 파일:줄과 종류만 알린다.
정말 괜찮은 줄이면 그 줄에 `privacy-ok` 를 적는다.
"""
import ipaddress
import re
import subprocess
import sys

SKIP_PATH = re.compile(
    r"(pubspec\.lock|Podfile\.lock|package-lock\.json|\.svg|\.pbxproj)$"
    r"|(^|/)(LICENSE|NOTICE|COPYING)[^/]*$"
)
# 잠금 파일, SVG, 2000자 넘는 줄은 해시와 경로 데이터가 많아 전부 보지 않는다.
# 그래도 키 모양과 비밀값 대입은 거기서도 찾는다.
GENERATED_LINE = 2000

# 올리면 안 되는 파일. 서명 키, 스토어 키, 환경 파일, 파이어베이스 설정.
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
# Icon-App-20x20@2x.png 같은 해상도 접미사 파일명은 이메일이 아니다.
FILE_EXT = re.compile(r"\.(png|jpe?g|gif|webp|svg|pdf|ttf|otf)$", re.I)
IPV4 = re.compile(r"(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])")
IP_OK = [ipaddress.ip_network(n) for n in (
    "127.0.0.0/8", "0.0.0.0/32", "255.255.255.0/24",
    "192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24",
    "1.1.1.1/32", "1.0.0.1/32", "8.8.8.8/32", "8.8.4.4/32",
)]
PRIVATE = [ipaddress.ip_network(n) for n in ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10")]
VERSION_CONTEXT = re.compile(r"\bversion\b|\bv(?=\d)|\bbuild\b", re.I)
IPV6 = re.compile(r"(?<![\w:.])([0-9a-fA-F]{0,4}(?::[0-9a-fA-F]{0,4}){2,7})(?![\w:])")
INTERNAL_HOST = re.compile(
    r"\b[a-z0-9-]+\.(lan|local|internal|intranet|corp|localdomain|home\.arpa)(?![\w.-])", re.I
)
NET_CONTEXT = re.compile(r"://|\b(host|ip|addr|address|server|endpoint|connect|curl|ssh|ping)\b|:\d{2,5}\b", re.I)
TAILNET = re.compile(r"\.ts\.net\b")
OPS_PATH = re.compile(r"/mnt/[\w-]+|/srv/[\w-]+|appdata/|/volume\d/")  # privacy-ok
HOME = re.compile(r"(?:/home|/Users)/([A-Za-z_][\w.-]*)")
HOME_OK = {"user", "runner", "node", "ubuntu", "app", "me", "you", "example", "username", "Shared", "<user>"}
SHA_CONTEXT = re.compile(r"commit|\bsha|\brev\b|revision|checkout|github\.com|git\b|@", re.I)
SHA256_CONTEXT = re.compile(r"sha-?256", re.I)
HEX = re.compile(r"(?<![0-9a-fA-F])[0-9a-f]{40,}(?![0-9a-fA-F])")
SECRET = re.compile(r"(api[_-]?key|secret|token|password)\s*[:=]\s*['\"]([A-Za-z0-9_\-./+=]{20,})['\"]", re.I)
KNOWN_KEY = re.compile(r"AIza[0-9A-Za-z_\-]{35}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{36}|-----BEGIN [A-Z ]*PRIVATE KEY")
# 소수점 넷째 자리(약 10m) 이상인 위도, 경도 쌍. 실제 집이나 동네를 가리킬 수 있다.
COORD = re.compile(r"(?<![\w.])-?\d{1,2}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}(?![\d])")


def strong_findings(line):
    """어디서든 찾는 것: 알려진 키 모양과 비밀값 대입."""
    out = []
    for m in SECRET.finditer(line):
        v = m.group(2)
        if re.search(r"[a-z]", v) and re.search(r"[A-Z]", v) and re.search(r"\d", v) and len(set(v)) > 10:
            out.append("비밀값")
            break
    if KNOWN_KEY.search(line):
        out.append("키")
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
            if parts[3] not in (0, 255) and (net or not VERSION_CONTEXT.search(line)):
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
        if ip.is_private and not ip.is_reserved or ip.is_link_local or (ip.is_global and NET_CONTEXT.search(line)):
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
            out.append("이메일")
            break
    out += ip_findings(line)
    if INTERNAL_HOST.search(line) and NET_CONTEXT.search(line):
        out.append("내부 호스트")
    if TAILNET.search(line):
        out.append("Tailscale 주소")
    if OPS_PATH.search(line):
        out.append("운영 경로")
    if any(m.group(1) not in HOME_OK for m in HOME.finditer(line)):
        out.append("홈 경로")
    for m in HEX.finditer(line):
        v = m.group(0)
        sha = (len(v) == 40 and SHA_CONTEXT.search(line)) or (len(v) == 64 and SHA256_CONTEXT.search(line))
        if len(set(v)) > 4 and not sha:
            out.append("긴 hex")
            break
    out += strong_findings(line)
    if COORD.search(line):
        out.append("좌표")
    return out


def diff_path(header):
    path = header[4:]
    if path.startswith('"') and path.endswith('"'):
        path = path[1:-1].encode("latin-1", "backslashreplace").decode("unicode_escape").encode("latin-1").decode("utf-8", "replace")
    return path[2:] if path.startswith("b/") else path


def scan_diff(diff):
    hits, path, lineno = [], "?", 0
    for raw in diff.splitlines():
        if raw.startswith("+++ "):
            path = diff_path(raw)
            continue
        if raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            lineno = int(m.group(1)) - 1 if m else 0
            continue
        if raw.startswith("-"):
            continue
        lineno += 1
        if not raw.startswith("+") or "privacy-ok" in raw:
            continue
        partial = SKIP_PATH.search(path) or len(raw) > GENERATED_LINE
        kinds = strong_findings(raw[1:]) if partial else findings_in_line(raw[1:])
        hits += [f"{path}:{lineno} {kind}" for kind in kinds]
    return hits


def scan_text(label, text):
    return [f"{label}:{i} {kind}" for i, line in enumerate(text.splitlines(), 1) for kind in findings_in_line(line)]


def scan_files(names):
    return [f"{n} 올리면 안 되는 파일" for n in names if SECRET_FILE.search(n) and not SECRET_FILE_OK.search(n)]


def git(*args):
    # 경로 인용을 끄면 한글 경로가 따옴표와 8진수 없이 그대로 나온다.
    r = subprocess.run(["git", "-c", "core.quotePath=false", *args], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"git {' '.join(args)} 실패: {r.stderr.strip()}")
    return r.stdout


def report(hits):
    if not hits:
        return 0
    print("개인정보나 서버 정보로 보이는 것이 있습니다. 값은 출력하지 않습니다.", file=sys.stderr)
    for h in hits[:30]:
        print(f"  {h}", file=sys.stderr)
    if len(hits) > 30:
        print(f"  외 {len(hits) - 30}건", file=sys.stderr)
    print(
        "문서용 값(192.0.2.x, example.com, 가짜 키, 가짜 좌표)으로 바꿉니다. "
        "정말 괜찮은 줄이면 그 줄에 privacy-ok 를 적습니다.",
        file=sys.stderr,
    )
    return 1


def names_z(out):
    return sorted({n.strip("\n") for n in out.split("\0") if n.strip("\n")})


SCISSORS = re.compile(r"^# -+ >8 -+$")


def message_text(raw):
    """git 이 지울 주석 줄도 본다. cleanup=verbatim 이면 그대로 남기 때문이다. 가위 줄 아래만 뺀다."""
    lines = []
    for line in raw.splitlines():
        if SCISSORS.match(line):
            break
        lines.append(line)
    return "\n".join(lines)


def main(argv):
    if len(argv) == 1 and argv[0] == "--staged":
        names = names_z(git("diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR"))
        return report(scan_files(names) + scan_diff(git("diff", "--cached", "-U0", "--no-color")))
    if len(argv) == 2 and argv[0] == "--message":
        with open(argv[1], encoding="utf-8", errors="ignore") as f:
            return report(scan_text("커밋 메시지", message_text(f.read())))
    if len(argv) == 2 and argv[0] == "--range":
        # 끝점끼리 비교하면 중간 커밋에서 넣었다 지운 것이 안 보인다. 커밋마다 본다.
        rng = argv[1]
        names = names_z(git("log", "--name-only", "-z", "--diff-filter=ACMR", "--format=", rng))
        hits = scan_files(names) + scan_diff(git("log", "-p", "-U0", "--no-color", "--format=", rng))
        return report(hits + scan_text("커밋 메시지", git("log", "--format=%B", rng)))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
