#!/usr/bin/env python3
"""글과 코드에 AI 티가 나는 흔적이 섞이지 않게 막는다.

pstack 의 unslop(글), deslop(코드) 스킬 규칙 가운데 기계로 판정할 수 있는 것만 옮겼다.
나머지(수동태, 군더더기 문장, 불필요한 방어 코드)는 리뷰 때 스킬로 본다.

  slop_scan.py --staged          스테이징된 변경 (pre-commit)
  slop_scan.py --message FILE    커밋 메시지 (commit-msg)
  slop_scan.py --range A..B      범위 안의 커밋 하나하나와 그 메시지 (pre-push, CI)

정말 필요한 줄이면 그 줄에 `slop-ok` 를 적는다.
"""
import re
import sys

from privacy_scan import MERGES, diff_lines, git, message_text, scissors_apply

JUDGED = re.compile(r"\.(md|txt|dart|py|sh|ya?ml|json)$|(^|/)\.githooks/[^/]+$")
NOT_JUDGED = re.compile(
    r"(^|/)(LICENSE|NOTICE|COPYING|THIRD_PARTY_NOTICES)[^/]*$|^licenses/|\.g\.dart$|\.lock$"
    r"|^tool/(slop_scan|test_slop_scan)\.py$"
)

DASH = re.compile(r"[—–]")
CURLY = re.compile(r"[“”‘’]")
AI_WORDS = re.compile(
    r"\b(delve|tapestry|testament|pivotal|showcas\w*|garner\w*|intricate|interplay|vibrant|fostering"
    r"|leverag\w*|utiliz\w*|serves as|stands as|in order to|it is important to note"
    r"|i hope this helps|let me know if|certainly!|great question|you're absolutely right)\b"
    r"|물론입니다|도움이 되셨|도움이 되길|결론적으로|다양한 측면",
    re.I,
)
EMOJI = "\U0001F300-\U0001FAFF☀-➿⭐⬆↔-⇿"
DECORATED = re.compile(rf"^\s*(#{{1,6}}|[-*+]|\d+\.)\s+[{EMOJI}]")
DEBUG_PRINT = re.compile(r"(?<![\w.])(print|debugPrint)\s*\(")
DYNAMIC_CAST = re.compile(r"\bas\s+dynamic\b")
# Code and comments are English only. Korean belongs in docs (.md), translations (.arb) and token data (.json).
HANGUL = re.compile(r"[\u1100-\u11ff\u3130-\u318f\uac00-\ud7a3]")
CODE_KINDS = ("dart", "dart-test", "code")


def findings_in_line(line, kind):
    """kind: md(글), dart(lib 코드), dart-test, py, msg(커밋 메시지) 등 파일 종류."""
    if "slop-ok" in line:
        return []
    out = []
    if DASH.search(line):
        out.append("대시")
    if CURLY.search(line):
        out.append("둥근 따옴표")
    if AI_WORDS.search(line):
        out.append("AI 말투")
    if kind in ("md", "msg") and DECORATED.search(line):
        out.append("꾸밈 이모지")
    if kind in CODE_KINDS and HANGUL.search(line):
        out.append("한글 코드")
    if kind == "dart":
        if DEBUG_PRINT.search(line):
            out.append("디버그 출력")
        if DYNAMIC_CAST.search(line):
            out.append("dynamic 캐스트")
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
    return [f"커밋 메시지:{i} {k}" for i, line in enumerate(text.splitlines(), 1) for k in findings_in_line(line, "msg")]


def report(hits):
    if not hits:
        return 0
    print("AI 티가 나는 흔적이 있습니다.", file=sys.stderr)
    for h in hits[:30]:
        print(f"  {h}", file=sys.stderr)
    print(
        "대시는 마침표나 연결어미로, 둥근 따옴표는 곧은 따옴표로, 꾸밈 이모지는 빼고, "
        "디버그 출력은 지우고, 코드와 주석은 영어로 씁니다. 정말 필요한 줄이면 그 줄에 slop-ok 를 적습니다.",
        file=sys.stderr,
    )
    return 1


def main(argv):
    if argv == ["--staged"]:
        return report(scan_diff(git("diff", "--cached", "-U0", "--no-color")))
    if len(argv) == 2 and argv[0] == "--message":
        with open(argv[1], encoding="utf-8", errors="ignore") as f:
            return report(scan_message(message_text(f.read(), scissors_apply())))
    if len(argv) == 2 and argv[0] == "--range":
        rng = argv[1]
        hits = scan_diff(git("log", MERGES, "-p", "-U0", "--no-color", "--format=", rng))
        return report(hits + scan_message(git("log", "--format=%B", rng)))
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
