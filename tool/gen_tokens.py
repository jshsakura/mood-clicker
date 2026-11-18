#!/usr/bin/env python3
"""design/tokens/*.json 에서 lib/design/tokens.g.dart 를 만든다.

  python3 tool/gen_tokens.py           만든다
  python3 tool/gen_tokens.py --check   만든 파일이 토큰과 맞는지만 본다 (훅, CI)

토큰은 Tokens Studio 의 세트 구성을 따른다. core.json 은 공통 값, 나머지 파일 하나가 테마 하나다.
디자이너는 이 파일들만 고친다. 색을 새로 넣으면 모든 테마에 같은 이름으로 넣어야 한다.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "tokens"
OUT = ROOT / "lib" / "design" / "tokens.g.dart"

HEX = re.compile(r"^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$")
IDENT = re.compile(r"^[a-z][A-Za-z0-9]*$")
DURATION = re.compile(r"^(\d+)ms$")
WEIGHTS = {100, 200, 300, 400, 500, 600, 700, 800, 900}


class TokenError(ValueError):
    pass


REF = re.compile(r"^\{([A-Za-z0-9_.]+)\}$")


def value(tok, where):
    if not isinstance(tok, dict) or "$value" not in tok:
        raise TokenError(f"{where}: $value 가 없습니다")
    return tok["$value"]


def resolve(v, core, where):
    """'{font.family}' 같은 참조를 core 의 값으로 바꾼다."""
    m = REF.match(v) if isinstance(v, str) else None
    if not m:
        return v
    node = core
    for part in m.group(1).split("."):
        if not isinstance(node, dict) or part not in node:
            raise TokenError(f"{where}: 참조 {v} 를 찾지 못했습니다")
        node = node[part]
    return value(node, where)


def ident(name, where):
    if not IDENT.match(name):
        raise TokenError(f"{where}: 이름 '{name}' 은 소문자로 시작하는 영문, 숫자만 씁니다")
    return name


def color(tok, where):
    v = value(tok, where)
    if not isinstance(v, str) or not HEX.match(v):
        raise TokenError(f"{where}: 색은 #RRGGBB 나 #RRGGBBAA 로 씁니다")
    h = v[1:].upper()
    argb = h[6:] + h[:6] if len(h) == 8 else "FF" + h
    return f"Color(0x{argb})"


def number(tok, where):
    return plain_number(value(tok, where), where)


def plain_number(v, where):
    if isinstance(v, str) and v.endswith("px"):
        v = v[:-2]
    try:
        return float(v)
    except (TypeError, ValueError):
        raise TokenError(f"{where}: 숫자여야 합니다") from None


def millis(tok, where):
    m = DURATION.match(str(value(tok, where)))
    if not m:
        raise TokenError(f"{where}: 시간은 '120ms' 처럼 씁니다")
    return int(m.group(1))


def num(x):
    return str(int(x)) if float(x).is_integer() else repr(float(x))


def palettes(theme_docs):
    if not theme_docs:
        raise TokenError("테마 파일이 하나도 없습니다")
    themes, bright = {}, {}
    for theme, doc in theme_docs.items():
        ident(theme, f"{theme}.json")
        b = (((doc.get("$extensions") or {}).get("app")) or {}).get("brightness")
        if b not in ("light", "dark"):
            raise TokenError(f"{theme}.json: $extensions.app.brightness 는 light 나 dark 여야 합니다")
        bright[theme] = b
        body = doc.get("color") or {}
        themes[theme] = {
            ident(k, f"{theme}.color.{k}"): color(v, f"{theme}.color.{k}")
            for k, v in body.items()
        }
    first, *rest = themes
    keys = list(themes[first])
    for t in rest:
        missing, extra = set(keys) - set(themes[t]), set(themes[t]) - set(keys)
        if missing or extra:
            raise TokenError(
                f"{t}.json: 테마마다 색 이름이 같아야 합니다. "
                f"빠진 것 {sorted(missing) or '없음'}, 남는 것 {sorted(extra) or '없음'}"
            )
    return keys, themes, bright


def palette_class(keys):
    fields = "\n".join(f"  final Color {k};" for k in keys)
    ctor = "\n".join(f"    required this.{k}," for k in keys)
    cw_args = "\n".join(f"    Color? {k}," for k in keys)
    cw_body = "\n".join(f"      {k}: {k} ?? this.{k}," for k in keys)
    lerp = "\n".join(f"      {k}: Color.lerp({k}, other.{k}, t)!," for k in keys)
    return f"""@immutable
class AppPalette extends ThemeExtension<AppPalette> {{
  const AppPalette({{
    required this.name,
    required this.brightness,
{ctor}
  }});

  final String name;
  final Brightness brightness;
{fields}

  @override
  AppPalette copyWith({{
    String? name,
    Brightness? brightness,
{cw_args}
  }}) {{
    return AppPalette(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
{cw_body}
    );
  }}

  @override
  AppPalette lerp(AppPalette? other, double t) {{
    if (other == null) return this;
    return AppPalette(
      name: t < 0.5 ? name : other.name,
      brightness: t < 0.5 ? brightness : other.brightness,
{lerp}
    );
  }}
}}
"""


def render(tokens):
    """tokens = {"core": {...}, "dark": {...}, ...}. core 외의 키가 테마다."""
    core = tokens.get("core")
    if not isinstance(core, dict):
        raise TokenError("core.json 이 없습니다")
    keys, themes, bright = palettes({k: v for k, v in tokens.items() if k != "core"})
    out = [
        "// 생성 파일이다. 손대지 않는다.",
        "// design/tokens/*.json 을 고친 뒤 python3 tool/gen_tokens.py 를 돌린다.",
        "// ignore_for_file: lines_longer_than_80_chars",
        "import 'package:flutter/material.dart';",
        "",
        palette_class(keys),
    ]
    for t, cols in themes.items():
        body = "\n".join(f"  {k}: {v}," for k, v in cols.items())
        out.append(
            f"const AppPalette {t}Palette = AppPalette(\n  name: '{t}',\n"
            f"  brightness: Brightness.{bright[t]},\n{body}\n);\n"
        )
    out.append("const List<AppPalette> allPalettes = [" + ", ".join(f"{t}Palette" for t in themes) + "];\n")

    for group, cls in (("space", "Space"), ("radius", "Radii")):
        items = core.get(group) or {}
        lines = "\n".join(
            f"  static const double {ident(k, f'{group}.{k}')} = {num(number(v, f'{group}.{k}'))};"
            for k, v in items.items()
        )
        out.append(f"abstract final class {cls} {{\n{lines}\n}}\n")

    styles = []
    for k, v in (core.get("type") or {}).items():
        where = f"core.type.{k}"
        spec = value(v, where)
        family = resolve(spec.get("fontFamily", "{font.family}"), core, f"{where}.fontFamily")
        try:
            weight = int(str(spec.get("fontWeight", "400")))
        except ValueError:
            weight = -1
        if weight not in WEIGHTS:
            raise TokenError(f"{where}.fontWeight: 100 단위로 100~900 입니다")
        size = plain_number(spec.get("fontSize"), f"{where}.fontSize")
        lh = str(spec.get("lineHeight", "1.2"))
        height = plain_number(lh[:-1], f"{where}.lineHeight") / 100 if lh.endswith("%") else plain_number(lh, f"{where}.lineHeight")
        styles.append(
            f"  static const TextStyle {ident(k, where)} = TextStyle(fontFamily: '{family}', "
            f"fontSize: {num(size)}, fontWeight: FontWeight.w{weight}, "
            f"height: {num(height)});"
        )
    out.append("abstract final class TypeScale {\n" + "\n".join(styles) + "\n}\n")

    motion = "\n".join(
        f"  static const Duration {ident(k, f'motion.{k}')} = Duration(milliseconds: {millis(v, f'motion.{k}')});"
        for k, v in (core.get("motion") or {}).items()
    )
    out.append(f"abstract final class Motion {{\n{motion}\n}}\n")
    return "\n".join(out)


def load(src=SRC):
    files = sorted(src.glob("*.json"))
    return {f.stem: json.loads(f.read_text(encoding="utf-8")) for f in files}


def main(argv):
    try:
        text = render(load())
    except (TokenError, json.JSONDecodeError, KeyError) as e:
        print(f"design/tokens 오류: {e}", file=sys.stderr)
        return 1
    if argv == ["--check"]:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("lib/design/tokens.g.dart 가 design/tokens 와 다릅니다. "
                  "python3 tool/gen_tokens.py 를 돌린 뒤 둘 다 커밋합니다.", file=sys.stderr)
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"만들었습니다: {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
