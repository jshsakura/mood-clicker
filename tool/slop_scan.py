#!/usr/bin/env python3
"""Keep AI writing and code tells out of the repository.

This ports the mechanical subset of the pstack unslop (prose) and deslop (code) skills.
The rest (passive voice, filler, needless defensive code) stays a review step with those skills.

  slop_scan.py --staged          staged changes (pre-commit)
  slop_scan.py --message FILE    commit message (commit-msg)
  slop_scan.py --range A..B      what the range lands (net diff) and every commit message (pre-push, CI)

Put `slop-ok` on a line only when it is really needed.
"""
import re
import sys

from privacy_scan import NO_RENAMES, diff_lines, git, message_text

JUDGED = re.compile(r"\.(md|txt|dart|py|sh|ya?ml|json)$|(^|/)\.githooks/[^/]+$")
NOT_JUDGED = re.compile(
    r"(^|/)(LICENSE|NOTICE|COPYING|THIRD_PARTY_NOTICES)[^/]*$|^licenses/|\.g\.dart$|\.lock$"
    r"|^tool/(slop_scan|test_slop_scan)\.py$"
    # Verbatim records of what people and agents wrote. The privacy scan still reads them.
    r"|^docs/prompts/"
)

# An en dash between digits is a numeric range (3\u20135), not a sentence connector.
DASH = re.compile(r"\u2014|(?<!\d)\u2013|\u2013(?!\d)")
CURLY = re.compile(r"[“”‘’]")
AI_WORDS = re.compile(
    r"\b(delve|tapestry|testament|pivotal|showcas\w*|garner\w*|intricate|interplay|vibrant|fostering"
    r"|leverag\w*|utiliz\w*|serves as|stands as|in order to|it is important to note"
    r"|i hope this helps|let me know if|great question|you're absolutely right)\b|\bcertainly!"
    r"|\ubb3c\ub860\uc785\ub2c8\ub2e4|\ub3c4\uc6c0\uc774 \ub418\uc168|\ub3c4\uc6c0\uc774 \ub418\uae38|\uacb0\ub860\uc801\uc73c\ub85c",
    re.I,
)
EMOJI = "\U0001F300-\U0001FAFF☀-➿⭐⬆↔-⇿"
DECORATED = re.compile(rf"^\s*(#{{1,6}}|[-*+]|\d+\.)\s+([{EMOJI}])")
# Status marks carry meaning (done, failed, warning), so they are not decoration.
STATUS_MARKS = set("\u2705\u274c\u26a0\u2714\u2716")
DEBUG_PRINT = re.compile(r"(?<![\w.])(?:core\.)?(print|debugPrint)\s*\(")
# "String print()" or "void print()" declares a method; it does not call the global print.
PRINT_DECLARATION = re.compile(r"\b\w+[?>]?\s+(print|debugPrint)\s*\(")
DART_COMMENT = re.compile(r"^\s*//")
DYNAMIC_CAST = re.compile(r"\bas\s+dynamic\b")
# Code and comments are English only. Korean belongs in docs (.md), translations (.arb) and token data (.json).
HANGUL = re.compile(r"[\u1100-\u11ff\u3130-\u318f\uac00-\ud7a3]")
CODE_KINDS = ("dart", "dart-test", "code")
# Flat style (docs/DESIGN.md): no gradients, blurred shadows or glows. A nonzero elevation casts a shadow too.
FLAT_BANNED = re.compile(
    r"\b(?:Linear|Radial|Sweep)Gradient\b|(?<![\w.])Gradient\s*\(|\bBoxShadow\b|(?<![\w.])Shadow\s*\("
    r"|\bImageFilter\.blur\b|\bBackdropFilter\b|\bMaskFilter\.blur\b"
)
ELEVATION = re.compile(r"(?<![\w.])elevation\s*:\s*([^,)\s;]+)")
FLAT_ELEVATION_OK = {"0", "0.0"}
# The first string of test(...), testWidgets(...) and group(...) is a name, not code.
TEST_NAME = re.compile(r"""\b(?:test|testWidgets|group)\(\s*(?:'[^']*'|"[^"]*")""")
TRAILING_COMMENT = re.compile(r"(?<!:)//.*$")


def breaks_flat_style(line):
    code = TRAILING_COMMENT.sub("", TEST_NAME.sub("", line))
    if FLAT_BANNED.search(code):
        return True
    return any(m.group(1) not in FLAT_ELEVATION_OK for m in ELEVATION.finditer(code))


def findings_in_line(line, kind):
    """kind: md (prose), dart (lib code), dart-test, code, data (json) or msg (commit message)."""
    if "slop-ok" in line:
        return []
    out = []
    if DASH.search(line):
        out.append("dash")
    if CURLY.search(line):
        out.append("curly quote")
    if kind in ("md", "msg") and AI_WORDS.search(line):
        out.append("AI phrase")
    decorated = DECORATED.search(line) if kind in ("md", "msg") else None
    if decorated and decorated.group(2) not in STATUS_MARKS:
        out.append("decorative emoji")
    if kind in CODE_KINDS and HANGUL.search(line):
        out.append("Hangul in code")
    if kind == "dart":
        code = not DART_COMMENT.match(line)
        if code and DEBUG_PRINT.search(line) and not PRINT_DECLARATION.search(line):
            out.append("debug print")
        if DYNAMIC_CAST.search(line):
            out.append("dynamic cast")
    if kind in ("dart", "dart-test") and not DART_COMMENT.match(line) and breaks_flat_style(line):
        out.append("flat style")
    return out


def kind_of(path):
    if path.endswith(".dart"):
        return "dart" if path.startswith("lib/") else "dart-test"
    if path.endswith((".md", ".txt")):
        return "md"
    if path.endswith(".json"):
        return "data"
    return "code"


def scan_diff(diff):
    hits = []
    for path, lineno, line in diff_lines(diff):
        if JUDGED.search(path) and not NOT_JUDGED.search(path):
            hits += [f"{path}:{lineno} {k}" for k in findings_in_line(line, kind_of(path))]
    return hits


def scan_message(text):
    # Comment lines are git's template (file lists, hints); style rules apply to what the author wrote.
    lines = enumerate(text.split("\n"), 1)
    return [f"commit message:{i} {k}" for i, line in lines if not line.startswith("#") for k in findings_in_line(line, "msg")]


def report(hits):
    if not hits:
        return 0
    print("Found AI writing or code tells.", file=sys.stderr)
    for h in hits[:30]:
        print(f"  {h}", file=sys.stderr)
    print(
        "Replace dashes with a period or a joined sentence, curly quotes with straight ones, drop decorative emoji, "
        "remove debug prints, keep the style flat (no gradients, shadows, blurs or elevation), and write code and comments in English. "
        "Mark a line slop-ok only when really needed.",
        file=sys.stderr,
    )
    return 1


def main(argv):
    if argv == ["--staged"]:
        return report(scan_diff(git("diff", "--cached", NO_RENAMES, "-U0", "--no-color")))
    if len(argv) == 2 and argv[0] == "--message":
        with open(argv[1], encoding="utf-8", errors="ignore") as f:
            return report(scan_message(message_text(f.read())))
    if len(argv) == 2 and argv[0] == "--range":
        rng = argv[1]
        # Style is judged by what the range lands (its net diff), so a tell fixed later in the range passes.
        # Messages stay per commit. History leaks are privacy_scan's job, which still reads every commit.
        net = rng.replace("...", "..").replace("..", "...", 1) if ".." in rng else rng
        hits = scan_diff(git("diff", NO_RENAMES, "-U0", "--no-color", net))
        return report(hits + scan_message(git("log", "--format=%B", rng)))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
