#!/usr/bin/env python3
"""design/fonts 의 원본 글꼴에서 앱에 넣을 가벼운 판을 만든다.

남기는 글자: KS X 1001 한글 2,350자, 한글 자모, 영문과 숫자, 라틴 기본 기호, 일반 문장부호, 원 기호 등.
빠진 글자(드문 한글, 한자, 이모지)는 기기의 시스템 글꼴로 그려진다.
실행: python3 tool/subset_fonts.py   (fonttools 필요)
"""
import sys
from pathlib import Path

from fontTools import subset

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "fonts"
OUT = ROOT / "assets" / "fonts"


def hangul_ksx1001():
    out = []
    for cp in range(0xAC00, 0xD7A4):
        # 표에 없는 글자는 8바이트 자모 조합으로 인코딩되므로 2바이트인 것만 표의 글자다.
        if len(chr(cp).encode("euc_kr")) == 2:
            out.append(cp)
    return out


def codepoints():
    ranges = [(0x20, 0x7E), (0xA0, 0xFF), (0x2000, 0x206F), (0x20A9, 0x20A9),
              (0x2190, 0x21FF), (0x2460, 0x24FF), (0x25A0, 0x25FF), (0x3000, 0x303F),
              (0x3131, 0x318E), (0xFF01, 0xFF5E)]
    cps = {cp for a, b in ranges for cp in range(a, b + 1)}
    return sorted(cps | set(hangul_ksx1001()))


def main():
    cps = codepoints()
    OUT.mkdir(parents=True, exist_ok=True)
    for src in sorted([*SRC.glob("*.otf"), *SRC.glob("*.ttf")]):
        opts = subset.Options()
        opts.layout_closure = False  # 자모 조합 규칙이 빠진 글자를 다시 끌어오지 않게 한다
        opts.name_IDs = ["*"]
        opts.notdef_outline = True
        font = subset.load_font(str(src), opts)
        s = subset.Subsetter(opts)
        s.populate(unicodes=cps)
        s.subset(font)
        dst = OUT / src.name
        subset.save_font(font, str(dst), opts)
        print(f"{src.name}: {src.stat().st_size // 1024}KB -> {dst.stat().st_size // 1024}KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
