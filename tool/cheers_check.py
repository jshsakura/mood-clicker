#!/usr/bin/env python3
"""Validate cheer phrase bundles (assets/cheers/ko.json and en.json).

Checks schema, per-mood tier minimum counts, per-mood minimum unique bases,
total phrase target, max variations per base, grapheme cluster lengths, exact
and normalized duplicates, global and per-mood forbidden words (Korean
substring stem, English word boundary), exclamation limits, emoji allowlists,
kaomoji/laughter limits, dashes, and curly quotes.
"""
import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

MOODS = ("happy", "excited", "angry", "sad", "anxious")
TIERS = ("low", "high", "full", "complete", "rare")
DEFAULT_MIN_COUNTS = {"low": 50, "high": 50, "full": 30, "complete": 20, "rare": 20}
DEFAULT_MIN_BASES_PER_MOOD = 150
DEFAULT_MIN_TOTAL = 5000
MAX_GROUP_SIZE = 4  # 1 base + up to 3 text-play variations
LENGTH_BOUNDS = {"ko": (2, 14), "en": (2, 20), "ja": (2, 14)}
DEFAULT_RULES_PATH = Path(__file__).resolve().parent / "cheers_rules.json"

DASH_RE = re.compile(r"[\u2013\u2014]")
CURLY_RE = re.compile(r"[\u2018\u2019\u201c\u201d]")
NORM_RE = re.compile(r"[\s\W_]+", re.UNICODE)
STRIP_PUNCT_RE = re.compile(r"[^\w\s]", re.UNICODE)
EMOJI_CP_RE = re.compile(r"[\U0001F300-\U0001FAFF\u2600-\u27BF\u2B50\u2B06]")
KAOMOJI_RE = re.compile(
    r"[()\u06f9\u0648\u30fd\u30ce\u03c9\u0298\u256d\u256e\u2570\u256f\u25bd\u25c7\u203f\u02d8\u02ca\u02cb\u00b4\u2022]"
)
KO_LAUGH_RE = re.compile(r"[\u314b\u314e]{2,}")
EN_LAUGH_RE = re.compile(r"\b(ha(?:ha)+|he(?:he)+|hi(?:hi)+|lol+|lmao+)\b", re.I)
JA_LAUGH_RE = re.compile(r"(?:\u7b11|\u3075\u3075|\u3042\u306f\u306f|w{2,})")

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


def split_graphemes(text: str) -> list[str]:
    """Split text into extended-grapheme-like clusters without external packages."""
    clusters: list[str] = []
    zwj_join = False
    ri_pending = False
    for ch in text:
        cp = ord(ch)
        if ch == "\u200D":
            if clusters:
                clusters[-1] += ch
            zwj_join = True
            ri_pending = False
            continue
        if zwj_join:
            if clusters:
                clusters[-1] += ch
            zwj_join = False
            continue
        if ch in ("\uFE0E", "\uFE0F") or 0x1F3FB <= cp <= 0x1F3FF:
            if clusters:
                clusters[-1] += ch
            continue
        if unicodedata.category(ch) in ("Mn", "Mc", "Me"):
            if clusters:
                clusters[-1] += ch
            continue
        if 0x1F1E6 <= cp <= 0x1F1FF:
            if ri_pending and clusters:
                clusters[-1] += ch
                ri_pending = False
                continue
            ri_pending = True
            clusters.append(ch)
            continue
        ri_pending = False
        clusters.append(ch)
    return clusters


def count_graphemes(text: str) -> int:
    return len(split_graphemes(text))


def _is_emoji_cluster(cluster: str) -> bool:
    return bool(EMOJI_CP_RE.search(cluster)) or any(
        0x1F1E6 <= ord(ch) <= 0x1F1FF for ch in cluster
    )


def load_rules(path: Path = DEFAULT_RULES_PATH) -> dict:
    if not path.is_file():
        return {"version": 1, "global": {}, "moods": {}}
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def normalize_phrase(text: str) -> str:
    return NORM_RE.sub("", text).lower()


def _strip_punct_spaces(text: str) -> str:
    return " ".join(STRIP_PUNCT_RE.sub(" ", text).split())


def _compile_en_ban_regex(words: list[str]) -> re.Pattern[str] | None:
    if not words:
        return None
    parts = [re.escape(w) for w in words]
    return re.compile(r"\b(?:" + "|".join(parts) + r")\b", re.I)


_EN_SELF_HARM_RE = re.compile(
    r"\b(?:hurt|harm|burn|cut)\s+(?:you|yourself|me|myself)\b", re.I
)
_EN_NEG_RE = re.compile(r"\b(?:not|don't|do not|never|no|without)\b", re.I)


def _has_unnegated_self_harm(item: str, lang: str) -> bool:
    if lang == "ko":
        if any(w in item for w in ("\ud574\uce58", "\ud574\uccd0", "\ub2e4\uce58", "\ub2e4\uccd0", "\uc790\ud574")):
            return not any(
                neg in item for neg in ("\uc54a", "\uc548 ", "\ub9c8", "\ub9d0", "\uc5c6")
            )
    elif lang == "ja":
        if "\u50b7\u3064\u3051" in item or "\u81ea\u50b7" in item:
            return not any(
                neg in item
                for neg in ("\u306a\u3044", "\u306a\u304f", "\u305a", "\u306c", "\u306a\u3044\u3067")
            )
    elif lang == "en":
        if _EN_SELF_HARM_RE.search(item):
            return _EN_NEG_RE.search(item) is None
    return False


_EN_TRUNC_RE = re.compile(r"(?:['\u2019]s|\b(?:for|to|the|a|of))$", re.I)
_JA_TRUNC_SUFFIXES = (
    "\u306a\u304c\u3089",  # nagara
    "\u3092",              # wo
    "\u304c",              # ga
    "\u697d\u3057",        # tanoshi
    "\u5f85\u3061\u9060\u3057",  # machidooshi
    "\u53e3\u305a\u3055",  # kuchizusa
    "\u899a\u3048\u3066\u304a",  # oboeteo
    "\u660e\u308b\u304f\u306a",  # akarukuna
    "\u7acb",              # tachi/tatsu stem
    "\u6c7a",              # ki stem
    "\u62b1",              # daki stem
    "\u7518",              # ama stem
    "\u8fbc",              # komi stem
    "\u9ad8",              # taka stem
)


def _strip_phrase_tail(item: str) -> str:
    clusters = split_graphemes(item.strip())
    while clusters and (
        clusters[-1] in set(" ~\u301c!\uff01?\uff1f.\u3002,\u3001")
        or _is_emoji_cluster(clusters[-1])
    ):
        clusters.pop()
    return "".join(clusters).strip()


def _has_truncated_ending(item: str, lang: str) -> bool:
    st = _strip_phrase_tail(item)
    if not st:
        return False
    if lang == "ko":
        return st[-1] in ("\uc788", "\uac19", "\uc5c6")
    if lang == "en":
        return _EN_TRUNC_RE.search(st) is not None
    if lang == "ja":
        return st.endswith(_JA_TRUNC_SUFFIXES)
    return False


def _parse_item(item: object, loc: str) -> tuple[str | None, str | None, str | None]:
    if isinstance(item, str):
        return item, None, None
    if isinstance(item, dict):
        keys = set(item.keys())
        if not keys.issubset({"t", "b"}) or "t" not in keys or "b" not in keys:
            return None, None, f"{loc}: object must have exactly 't' and 'b' keys"
        t = item["t"]
        b = item["b"]
        if not isinstance(t, str) or not isinstance(b, str) or not b.strip():
            return None, None, f"{loc}: 't' and 'b' must be strings with non-empty 'b'"
        return t, b, None
    return None, None, f"{loc}: expected string or {{'t', 'b'}} object"


def check_bundle(
    data: dict,
    lang: str,
    min_counts: dict[str, int] | None = None,
    min_bases_per_mood: int | None = None,
    rules: dict | None = None,
    min_total: int | None = None,
    min_bases_per_tier: dict[str, int] | None = None,
) -> list[str]:
    errors: list[str] = []
    if lang not in LENGTH_BOUNDS:
        return [f"unsupported language: {lang}"]
    counts = DEFAULT_MIN_COUNTS if min_counts is None else min_counts
    req_bases = (
        DEFAULT_MIN_BASES_PER_MOOD
        if min_bases_per_mood is None and min_counts is None
        else (min_bases_per_mood or 0)
    )
    req_total = (
        DEFAULT_MIN_TOTAL
        if min_total is None and min_counts is None
        else (min_total or 0)
    )
    active_rules = load_rules() if rules is None else rules
    global_rules = active_rules.get("global", {})
    global_banned = global_rules.get("banned_words", {}).get(lang, [])
    if min_bases_per_tier is not None:
        tier_base_mins = min_bases_per_tier
        tier_base_moods = set(MOODS)
    elif min_counts is None:
        tier_base_mins = global_rules.get("min_bases_per_tier", {})
        tier_base_moods = set(global_rules.get("min_bases_tier_moods", []))
    else:
        tier_base_mins = {}
        tier_base_moods = set()
    en_global_re = _compile_en_ban_regex(global_banned) if lang == "en" else None
    mood_rules = active_rules.get("moods", {})
    min_len, max_len = LENGTH_BOUNDS[lang]

    if data.get("version") != 1:
        errors.append(f"{lang}: version must be 1")
    moods = data.get("moods")
    if not isinstance(moods, dict):
        return errors + [f"{lang}: missing moods object"]

    seen_exact: dict[str, str] = {}
    seen_norm: dict[str, tuple[str, str | None]] = {}
    base_mood: dict[str, str] = {}
    total_items = 0

    for mood in MOODS:
        mood_obj = moods.get(mood)
        if not isinstance(mood_obj, dict):
            errors.append(f"{lang}.{mood}: missing mood object")
            continue
        rule = mood_rules.get(mood, {})
        if "max_exclamation" in rule:
            max_excl = int(rule["max_exclamation"])
        elif rule.get("allow_exclamation", True) is False:
            max_excl = 0
        else:
            max_excl = None
        allow_kaomoji = rule.get("allow_kaomoji", True)
        allow_laughter = rule.get("allow_laughter", True)
        allowed_emojis = rule.get("allowed_emojis")
        allowed_emoji_set = (
            {e.replace("\uFE0F", "") for e in allowed_emojis} | set(allowed_emojis)
            if isinstance(allowed_emojis, list)
            else None
        )
        max_emojis = rule.get("max_emojis")
        allow_excl_with_emoji = rule.get("allow_exclamation_with_emoji", True)
        mood_banned = rule.get("banned_words", {}).get(lang, [])
        en_mood_re = _compile_en_ban_regex(mood_banned) if lang == "en" else None

        base_group_counts: dict[str, int] = {}
        standalone_bases = 0

        for tier in TIERS:
            arr = mood_obj.get(tier)
            if not isinstance(arr, list):
                errors.append(f"{lang}.{mood}.{tier}: missing list")
                continue
            total_items += len(arr)
            req = counts.get(tier, 0)
            if len(arr) < req:
                errors.append(
                    f"{lang}.{mood}.{tier}: expected >= {req}, got {len(arr)}"
                )
            tier_bases: set[str] = set()
            for idx, raw in enumerate(arr):
                loc = f"{lang}.{mood}.{tier}[{idx}]"
                item, base_id, parse_err = _parse_item(raw, loc)
                if parse_err is not None or item is None:
                    errors.append(parse_err or f"{loc}: invalid item")
                    continue

                if base_id is not None:
                    prev_mood = base_mood.get(base_id)
                    if prev_mood is not None and prev_mood != mood:
                        errors.append(
                            f"{loc}: base {base_id!r} already used in mood {prev_mood!r}"
                        )
                    else:
                        base_mood[base_id] = mood
                    base_group_counts[base_id] = base_group_counts.get(base_id, 0) + 1
                    if base_group_counts[base_id] > MAX_GROUP_SIZE:
                        errors.append(
                            f"{loc}: base {base_id!r} exceeds max {MAX_GROUP_SIZE} items (1 base + 3 variations)"
                        )
                else:
                    standalone_bases += 1

                clusters = split_graphemes(item)
                g_len = len(clusters)
                if not (min_len <= g_len <= max_len):
                    errors.append(
                        f"{loc}: length {g_len} outside {min_len}..{max_len} ({item!r})"
                    )

                excl_count = item.count("!") + item.count("\uff01")
                if max_excl is not None and excl_count > max_excl:
                    errors.append(
                        f"{loc}: exclamation count {excl_count} exceeds max {max_excl} in {mood} ({item!r})"
                    )
                if not allow_kaomoji and KAOMOJI_RE.search(item):
                    errors.append(f"{loc}: kaomoji not allowed in {mood} ({item!r})")
                if not allow_laughter and (
                    KO_LAUGH_RE.search(item)
                    or EN_LAUGH_RE.search(item)
                    or (lang == "ja" and JA_LAUGH_RE.search(item))
                ):
                    errors.append(f"{loc}: laughter not allowed in {mood} ({item!r})")
                if allowed_emoji_set is not None or max_emojis is not None or not allow_excl_with_emoji:
                    emoji_count = 0
                    for cl in clusters:
                        if _is_emoji_cluster(cl):
                            emoji_count += 1
                            if (
                                allowed_emoji_set is not None
                                and cl not in allowed_emoji_set
                                and cl.replace("\uFE0F", "") not in allowed_emoji_set
                            ):
                                errors.append(
                                    f"{loc}: disallowed emoji {cl!r} in {mood} ({item!r})"
                                )
                                break
                    if max_emojis is not None and emoji_count > int(max_emojis):
                        errors.append(
                            f"{loc}: emoji count {emoji_count} exceeds max {max_emojis} in {mood} ({item!r})"
                        )
                    if not allow_excl_with_emoji and excl_count > 0 and emoji_count > 0:
                        errors.append(
                            f"{loc}: exclamation and emoji cannot be used together in {mood} ({item!r})"
                        )
                if _has_truncated_ending(item, lang):
                    errors.append(f"{loc}: truncated ending ({item!r})")
                if DASH_RE.search(item):
                    errors.append(f"{loc}: contains dash ({item!r})")
                if CURLY_RE.search(item):
                    errors.append(f"{loc}: contains curly quote ({item!r})")
                if _has_unnegated_self_harm(item, lang):
                    errors.append(f"{loc}: unnegated self-harm phrase ({item!r})")

                clean_text = _strip_punct_spaces(item)
                if lang in ("ko", "ja"):
                    if lang == "ko" and any(bad in item or bad in clean_text for bad in KO_BANNED):
                        errors.append(f"{loc}: contains forbidden word ({item!r})")
                    if any(bad in item or bad in clean_text for bad in global_banned):
                        errors.append(f"{loc}: contains global-banned word ({item!r})")
                    if any(bad in item or bad in clean_text for bad in mood_banned):
                        errors.append(f"{loc}: contains mood-banned word ({item!r})")
                elif lang == "en":
                    if EN_BANNED_RE.search(item):
                        errors.append(f"{loc}: contains forbidden word ({item!r})")
                    if en_global_re is not None and (
                        en_global_re.search(item) or en_global_re.search(clean_text)
                    ):
                        errors.append(f"{loc}: contains global-banned word ({item!r})")
                    if en_mood_re is not None and (
                        en_mood_re.search(item) or en_mood_re.search(clean_text)
                    ):
                        errors.append(f"{loc}: contains mood-banned word ({item!r})")

                if item in seen_exact:
                    errors.append(
                        f"{loc}: exact duplicate of {seen_exact[item]} ({item!r})"
                    )
                else:
                    seen_exact[item] = loc

                norm = normalize_phrase(item)
                if norm and norm in seen_norm:
                    prev_loc, prev_base = seen_norm[norm]
                    same_base = base_id is not None and base_id == prev_base
                    if not same_base and seen_exact.get(item) == loc:
                        errors.append(
                            f"{loc}: normalized duplicate of {prev_loc} ({item!r})"
                        )
                elif norm:
                    seen_norm[norm] = (loc, base_id)
                if base_id is not None:
                    tier_bases.add(f"b:{base_id}")
                elif norm:
                    tier_bases.add(f"n:{norm}")

            if mood in tier_base_moods:
                req_tier_bases = int(tier_base_mins.get(tier, 0))
                if len(tier_bases) < req_tier_bases:
                    short = req_tier_bases - len(tier_bases)
                    errors.append(
                        f"{lang}.{mood}.{tier}: expected >= {req_tier_bases} unique bases, "
                        f"got {len(tier_bases)} (short by {short})"
                    )

        total_bases = len(base_group_counts) + standalone_bases
        if total_bases < req_bases:
            errors.append(
                f"{lang}.{mood}: expected >= {req_bases} unique bases, got {total_bases}"
            )
    if total_items < req_total:
        errors.append(f"{lang}: expected >= {req_total} total items, got {total_items}")
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
        default=["ko", "en", "ja"],
        help="Languages to validate",
    )
    parser.add_argument(
        "--rules",
        default=str(DEFAULT_RULES_PATH),
        help="Path to per-mood rules JSON",
    )
    args = parser.parse_args(argv)
    root = Path(args.root)
    rules = load_rules(Path(args.rules))
    all_errors: list[str] = []
    for lang in args.langs:
        path = root / "assets" / "cheers" / f"{lang}.json"
        if not path.is_file():
            all_errors.append(f"missing file: {path}")
            continue
        with path.open(encoding="utf-8") as fh:
            data = json.load(fh)
        all_errors.extend(check_bundle(data, lang, rules=rules))

    if all_errors:
        for err in all_errors[:40]:
            print(err, file=sys.stderr)
        if len(all_errors) > 40:
            print(f"... and {len(all_errors) - 40} more errors", file=sys.stderr)
        return 1
    print(f"cheers_check OK ({', '.join(args.langs)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
