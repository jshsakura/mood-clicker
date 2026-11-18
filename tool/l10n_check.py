#!/usr/bin/env python3
"""Keep localization sources consistent.

Checks:
  1. Every ARB file under lib/l10n carries the same message keys as the
     template (app_ko.arb), and every message uses the same placeholders as
     the template.
  2. Every cheers file under assets/cheers matches the agreed shape:
     version 1, the five mood ids, and non-empty low/high/full phrase lists.
     Phrase counts may differ per language; phrases longer than 12
     characters only warn.

Run: python3 tool/l10n_check.py    (pre-commit and CI run the same command)
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
PHRASE_LIMIT = 12

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


def check_arb_pair(template, locale_file):
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
    return errors


def check_cheers_file(path):
    """Hard errors and soft warnings of one cheers JSON file."""
    name = path.name
    errors, warnings = [], []
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
                if not isinstance(phrase, str) or not phrase:
                    errors.append(f"{name}: mood {mood_id} stage {stage} has a non-string phrase")
                elif len(phrase) > PHRASE_LIMIT:
                    warnings.append(
                        f"{name}: mood {mood_id} stage {stage} phrase longer than {PHRASE_LIMIT} characters"
                    )
    for mood_id in moods:
        if mood_id not in MOOD_IDS:
            errors.append(f"{name}: unknown mood {mood_id}")
    return errors, warnings


def check_tree():
    """Errors and warnings of the whole repository tree."""
    errors, warnings = [], []
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
                errors += check_arb_pair(template, path)
    if CHEERS_DIR.is_dir():
        for path in sorted(CHEERS_DIR.glob("*.json")):
            file_errors, file_warnings = check_cheers_file(path)
            errors += file_errors
            warnings += file_warnings
    return errors, warnings


def main():
    errors, warnings = check_tree()
    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)
    if errors:
        print("Localization sources are inconsistent.", file=sys.stderr)
        for error in errors:
            print(f"  {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
