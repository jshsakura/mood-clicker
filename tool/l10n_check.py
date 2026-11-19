#!/usr/bin/env python3
"""Keep localization sources consistent.

Checks:
  1. Every ARB file under lib/l10n carries the same message keys as the
     template (app_ko.arb), and every message uses the same placeholders as
     the template.
  2. Every cheers file under assets/cheers matches the agreed shape:
     version 1, the five mood ids, and non-empty low/high/full phrase lists.
     Phrase counts may differ per language. Phrase length is not judged here: the layout shrinks
     any phrase to fit the screen, and tool/cheers_check.py owns the per-language length bounds.

  3. An en or ja file carries no Korean text (Hangul) in its values or phrases. A real exception,
     such as the name of a Korean institution, goes in tool/l10n_allow.json with a reason, one entry
     per ARB key (or per phrase text for a cheers file). An entry that is no longer needed is an error.

Run: python3 tool/l10n_check.py    (pre-commit and CI run the same command)
     --verbose lists every warning; by default warnings are one line per kind. Errors always
     print in full.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"
CHEERS_DIR = ROOT / "assets" / "cheers"
TEMPLATE = "app_ko.arb"
MOOD_IDS = ("happy", "excited", "angry", "sad", "anxious")
STAGES = ("low", "high", "full")

ALLOW_FILE = ROOT / "tool" / "l10n_allow.json"
# Languages whose files must not contain Korean text.
HANGUL_FREE = ("en", "ja")
HANGUL = re.compile(r"[\u1100-\u11ff\u3130-\u318f\uac00-\ud7a3]")

# "{name}" is a placeholder; "{count, plural, ...}" opens an ICU clause, so
# only single-word braces match.
PLACEHOLDER = re.compile(r"{\s*([A-Za-z_][A-Za-z0-9_]*)\s*}")


def placeholders(message):
    """Placeholder names used by one message, or None for non-strings."""
    if not isinstance(message, str):
        return None
    return frozenset(PLACEHOLDER.findall(message))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def language_of(name):
    """The language code of app_<code>.arb or <code>.json."""
    match = re.fullmatch(r"app_([A-Za-z_]+)\.arb|([A-Za-z_]+)\.json", name)
    return (match.group(1) or match.group(2)) if match else None


def check_value_language(name, values, allowed):
    """Errors for Hangul in the values of an en or ja file.

    values: {id: text}, where id is an ARB key or a phrase text. allowed: {id: reason}, the exceptions.
    Every allow entry must carry a reason and must still be needed.
    """
    errors, used = [], set()
    checked = language_of(name) in HANGUL_FREE
    for key, text in values.items():
        if checked and HANGUL.search(text):
            if key in (allowed or {}):
                used.add(key)
            else:
                errors.append(f"{name}: {key} has Korean text, but {name} is not Korean")
    for key, reason in (allowed or {}).items():
        if not isinstance(reason, str) or not reason.strip():
            errors.append(f"{name}: allow list entry {key} needs a reason")
        if key not in used:
            errors.append(f"{name}: allow list entry {key} is not needed")
    return errors


def check_arb_pair(template, locale_file, allowed=None):
    """Errors of one locale ARB against the parsed template messages."""
    name = locale_file.name
    try:
        other = load_json(locale_file)
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{name}: cannot read ({exc})"]
    errors = []
    for key, value in template.items():
        if key.startswith("@"):
            continue
        if key not in other:
            errors.append(f"{name}: missing key {key}")
        elif placeholders(value) != placeholders(other[key]):
            errors.append(f"{name}: placeholders of {key} differ from the template")
    for key in other:
        if not key.startswith("@") and key not in template:
            errors.append(f"{name}: extra key {key}")
    texts = {k: v for k, v in other.items() if not k.startswith("@") and isinstance(v, str)}
    return errors + check_value_language(name, texts, allowed)


def check_cheers_file(path, allowed=None):
    """Hard errors and soft warnings of one cheers JSON file."""
    name = path.name
    errors, warnings, texts = [], [], {}
    try:
        data = load_json(path)
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{name}: cannot read ({exc})"], []
    if not isinstance(data, dict) or data.get("version") != 1:
        return [f"{name}: expected a JSON object with version 1"], []
    moods = data.get("moods")
    if not isinstance(moods, dict):
        return [f"{name}: expected a moods object"], []
    for mood_id in MOOD_IDS:
        if mood_id not in moods:
            errors.append(f"{name}: missing mood {mood_id}")
            continue
        stages = moods[mood_id]
        for stage in STAGES:
            phrases = stages.get(stage) if isinstance(stages, dict) else None
            if not isinstance(phrases, list) or not phrases:
                errors.append(f"{name}: mood {mood_id} stage {stage} needs a non-empty list")
                continue
            for phrase in phrases:
                if isinstance(phrase, dict):
                    text = phrase.get("t")
                    base = phrase.get("b")
                    if not isinstance(text, str) or not text or not isinstance(base, str) or not base:
                        errors.append(f"{name}: mood {mood_id} stage {stage} has an invalid phrase object")
                        continue
                elif isinstance(phrase, str) and phrase:
                    text = phrase
                else:
                    errors.append(f"{name}: mood {mood_id} stage {stage} has a non-string phrase")
                    continue
                texts[text] = text
    for mood_id in moods:
        if mood_id not in MOOD_IDS:
            errors.append(f"{name}: unknown mood {mood_id}")
    return errors + check_value_language(name, texts, allowed), warnings


def load_allow(path=ALLOW_FILE):
    """{file name: {id: reason}} from tool/l10n_allow.json. Empty when the file does not exist."""
    return load_json(path) if path.is_file() else {}


def check_allow_files(allow, known=()):
    """Errors for allow entries that name a file the check does not know."""
    return [f"l10n_allow.json: {name} is not an ARB or cheers file of this repository"
            for name in allow if name not in known]


def check_tree():
    """Errors and warnings of the whole repository tree."""
    errors, warnings = [], []
    try:
        allow = load_allow()
    except (OSError, json.JSONDecodeError) as exc:
        allow = {}
        errors.append(f"l10n_allow.json: cannot read ({exc})")
    arb_files = sorted(ARB_DIR.glob("app_*.arb")) if ARB_DIR.is_dir() else []
    if not arb_files:
        errors.append(f"no ARB files under {ARB_DIR.relative_to(ROOT)}")
    else:
        try:
            template = load_json(ARB_DIR / TEMPLATE)
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{TEMPLATE}: cannot read ({exc})")
            template = {}
        for path in arb_files:
            if path.name != TEMPLATE:
                errors += check_arb_pair(template, path, allow.get(path.name))
    if CHEERS_DIR.is_dir():
        for path in sorted(CHEERS_DIR.glob("*.json")):
            file_errors, file_warnings = check_cheers_file(path, allow.get(path.name))
            errors += file_errors
            warnings += file_warnings
    known = {p.name for p in arb_files if p.name != TEMPLATE}
    known |= {p.name for p in CHEERS_DIR.glob("*.json")} if CHEERS_DIR.is_dir() else set()
    errors += check_allow_files(allow, known)
    return errors, warnings


def summarize_warnings(warnings, verbose):
    """Lines to print for warnings given as (kind, detail): every one, or one line per kind."""
    if verbose:
        return [f"warning: {kind}: {detail}" for kind, detail in warnings]
    counts = {}
    for kind, _detail in warnings:
        counts[kind] = counts.get(kind, 0) + 1
    return [f"warning: {count} x {kind} (--verbose lists them)" for kind, count in counts.items()]


def main(argv=None):
    verbose = "--verbose" in (sys.argv[1:] if argv is None else argv)
    errors, warnings = check_tree()
    for line in summarize_warnings(warnings, verbose):
        print(line, file=sys.stderr)
    if errors:
        print("Localization sources are inconsistent.", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
