#!/usr/bin/env python3
"""Build the lightweight fonts that ship with the app from the originals in design/fonts.

Kept characters: the 2,350 Hangul syllables of KS X 1001, Hangul jamo, Latin letters and digits, basic Latin symbols, general punctuation, circled symbols and so on.
Characters that are left out (rare Hangul, Hanja, emoji) are drawn with the system font of the device.
Run: python3 tool/subset_fonts.py   (needs fonttools)
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
        # A character that is not in the table is encoded as an 8-byte jamo sequence, so only the 2-byte ones are table characters.
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
        opts.layout_closure = False  # keep the jamo composition rules from pulling the dropped characters back in
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
