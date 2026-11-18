#!/usr/bin/env python3
"""Validate cheer phrase bundles (assets/cheers/ko.json and en.json).

Checks schema, per-mood tier minimum counts, character lengths, exact and
punctuation/whitespace-normalized duplicates across all moods, forbidden words,
dashes, curly quotes, and emojis.
"""
import argparse
import json
import re
import sys
from pathlib import Path

MOODS = ("happy", "excited", "angry", "sad", "anxious")
TIERS = ("low", "high", "full", "complete")
DEFAULT_MIN_COUNTS = {"low": 400, "high": 400, "full": 150, "complete": 50}
LENGTH_BOUNDS = {"ko": (2, 12), "en": (2, 18)}

DASH_RE = re.compile(r"[\u2013\u2014]")
CURLY_RE = re.compile(r"[\u2018\u2019\u201c\u201d]")
EMOJI_RE = re.compile(r"[\U0001F300-\U0001FAFF\u2600-\u27BF\u2B50\u2B06\u2194-\u21FF]")
NORM_RE = re.compile(r"[\s\W_]+", re.UNICODE)

# Korean forbidden roots encoded as unicode escapes to keep Python source ASCII-clean.
KO_BANNED = (
    "\uc6b0\uc6b8\uc99d",  # depression
    "\uce58\ub8cc",        # medical treatment
    "\uce58\uc720",        # healing/cure
    "\uc644\uce58",        # complete cure
    "\uc9c4\ub2e8",        # diagnosis
    "\ucc98\ubc29",        # prescription
    "\uc758\ud559",        # medicine/medical
    "\uc784\uc0c1",        # clinical
    "\uc57d\ubb3c",        # medication
    "\uc7a5\uc560",        # disorder
    "\uc528\ubc1c",        # profanity
    "\uac1c\uc0c8",        # profanity
    "\ubcd1\uc2e0",        # slur
    "\uc9c0\ub784",        # profanity
    "\ubbf8\uce5c\ub188",  # slur
    "\uc8fd\uc5b4",        # violence
    "\uc790\uc0b4",        # self-harm
    "\ub300\ud1b5\ub839",  # political
    "\uc120\uac70",        # political
    "\uc815\ub2f9",        # political
    "\uc544\uba58",        # religious slogan
    "\ud560\ub810\ub8e8\uc57c",  # religious slogan
    "\ub098\ubb34\uc544\ubbf8\ud0c0\ubd88",  # religious slogan
)

EN_BANNED_RE = re.compile(
    r"\b(depression|disorder|cure|heal|healing|therapy|therapeutic|diagnos\w*"
    r"|clinical|medical|prescription|treatment|fuck\w*|shit\w*|bitch\w*|asshole"
    r"|bastard|idiot|moron|kill|suicide|amen|hallelujah|jesus|allah|election"
    r"|democrat|republican)\b",
    re.I,
)


def normalize_phrase(text: str) -> str:
    return NORM_RE.sub("", text).lower()


def check_bundle(
    data: dict,
    lang: str,
    min_counts: dict[str, int] | None = None,
) -> list[str]:
    errors: list[str] = []
    if lang not in LENGTH_BOUNDS:
        return [f"unsupported language: {lang}"]
    counts = DEFAULT_MIN_COUNTS if min_counts is None else min_counts
    min_len, max_len = LENGTH_BOUNDS[lang]

    if data.get("version") != 1:
        errors.append(f"{lang}: version must be 1")
    moods = data.get("moods")
    if not isinstance(moods, dict):
        return errors + [f"{lang}: missing moods object"]

    seen_exact: dict[str, str] = {}
    seen_norm: dict[str, str] = {}

    for mood in MOODS:
        mood_obj = moods.get(mood)
        if not isinstance(mood_obj, dict):
            errors.append(f"{lang}.{mood}: missing mood object")
            continue
        for tier in TIERS:
            arr = mood_obj.get(tier)
            if not isinstance(arr, list):
                errors.append(f"{lang}.{mood}.{tier}: missing list")
                continue
            req = counts.get(tier, 0)
            if len(arr) < req:
                errors.append(
                    f"{lang}.{mood}.{tier}: expected >= {req}, got {len(arr)}"
                )
            for idx, item in enumerate(arr):
                loc = f"{lang}.{mood}.{tier}[{idx}]"
                if not isinstance(item, str):
                    errors.append(f"{loc}: not a string")
                    continue
                if not (min_len <= len(item) <= max_len):
                    errors.append(
                        f"{loc}: length {len(item)} outside {min_len}..{max_len} ({item!r})"
                    )
                if DASH_RE.search(item):
                    errors.append(f"{loc}: contains dash ({item!r})")
                if CURLY_RE.search(item):
                    errors.append(f"{loc}: contains curly quote ({item!r})")
                if EMOJI_RE.search(item):
                    errors.append(f"{loc}: contains emoji ({item!r})")
                if lang == "ko" and any(bad in item for bad in KO_BANNED):
                    errors.append(f"{loc}: contains forbidden word ({item!r})")
                if lang == "en" and EN_BANNED_RE.search(item):
                    errors.append(f"{loc}: contains forbidden word ({item!r})")

                if item in seen_exact:
                    errors.append(
                        f"{loc}: exact duplicate of {seen_exact[item]} ({item!r})"
                    )
                else:
                    seen_exact[item] = loc

                norm = normalize_phrase(item)
                if norm in seen_norm and item not in seen_exact:
                    pass
                if norm in seen_norm:
                    if seen_norm[norm] != loc and seen_exact.get(item) == loc:
                        errors.append(
                            f"{loc}: normalized duplicate of {seen_norm[norm]} ({item!r})"
                        )
                else:
                    seen_norm[norm] = loc
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate cheer phrase JSON bundles.")
    parser.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parent.parent),
        help="Repository root path",
    )
    parser.add_argument(
        "--langs",
        nargs="+",
        default=["ko", "en"],
        help="Languages to validate",
    )
    args = parser.parse_args(argv)
    root = Path(args.root)
    all_errors: list[str] = []
    for lang in args.langs:
        path = root / "assets" / "cheers" / f"{lang}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        all_errors.extend(check_bundle(data, lang))
    if all_errors:
        for err in all_errors[:40]:
            print(err, file=sys.stderr)
        if len(all_errors) > 40:
            print(f"... and {len(all_errors) - 40} more", file=sys.stderr)
        return 1
    print(f"cheers_check OK ({', '.join(args.langs)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
