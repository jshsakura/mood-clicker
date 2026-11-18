#!/usr/bin/env python3
"""design/tokens.json 에서 lib/design/tokens.g.dart 를 만든다.

  python3 tool/gen_tokens.py           만든다
  python3 tool/gen_tokens.py --check   만든 파일이 tokens.json 과 맞는지만 본다 (훅, CI)

디자이너는 tokens.json 만 고친다. 색을 새로 넣으면 모든 테마에 같은 이름으로 넣어야 한다.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "tokens.json"
OUT = ROOT / "lib" / "design" / "tokens.g.dart"

HEX = re.compile(r"^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$")
IDENT = re.compile(r"^[a-z][A-Za-z0-9]*$")
DURATION = re.compile(r"^(\d+)ms$")
WEIGHTS = {100, 200, 300, 400, 500, 600, 700, 800, 900}


class TokenError(ValueError):
    pass


def value(tok, where):
    if not isinstance(tok, dict) or "$value" not in tok:
        raise TokenError(f"{where}: $value 가 없습니다")
    return tok["$value"]


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
    v = value(tok, where)
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


def palettes(colors):
    if not isinstance(colors, dict) or not colors:
        raise TokenError("color: 테마가 하나도 없습니다")
    themes = {}
    for theme, body in colors.items():
        ident(theme, f"color.{theme}")
        if body.get("brightness") not in ("light", "dark"):
            raise TokenError(f"color.{theme}.brightness: light 나 dark 여야 합니다")
        themes[theme] = {
            ident(k, f"color.{theme}.{k}"): color(v, f"color.{theme}.{k}")
            for k, v in body.items() if k != "brightness"
        }
    first, *rest = themes
    keys = list(themes[first])
    for t in rest:
        missing, extra = set(keys) - set(themes[t]), set(themes[t]) - set(keys)
        if missing or extra:
            raise TokenError(
                f"color.{t}: 테마마다 색 이름이 같아야 합니다. "
                f"빠진 것 {sorted(missing) or '없음'}, 남는 것 {sorted(extra) or '없음'}"
            )
    return keys, themes, {t: colors[t]["brightness"] for t in themes}


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
    keys, themes, bright = palettes(tokens.get("color"))
    out = [
        "// 생성 파일이다. 손대지 않는다.",
        "// design/tokens.json 을 고친 뒤 python3 tool/gen_tokens.py 를 돌린다.",
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
        items = tokens.get(group) or {}
        lines = "\n".join(
            f"  static const double {ident(k, f'{group}.{k}')} = {num(number(v, f'{group}.{k}'))};"
            for k, v in items.items()
        )
        out.append(f"abstract final class {cls} {{\n{lines}\n}}\n")

    family = value((tokens.get("font") or {}).get("family"), "font.family")
    styles = []
    for k, v in (tokens.get("type") or {}).items():
        where = f"type.{k}"
        spec = value(v, where)
        weight = int(spec.get("fontWeight", 400))
        if weight not in WEIGHTS:
            raise TokenError(f"{where}.fontWeight: 100 단위로 100~900 입니다")
        styles.append(
            f"  static const TextStyle {ident(k, where)} = TextStyle(fontFamily: '{family}', "
            f"fontSize: {num(spec['fontSize'])}, fontWeight: FontWeight.w{weight}, "
            f"height: {num(spec.get('lineHeight', 1.2))});"
        )
    out.append("abstract final class TypeScale {\n" + "\n".join(styles) + "\n}\n")

    motion = "\n".join(
        f"  static const Duration {ident(k, f'motion.{k}')} = Duration(milliseconds: {millis(v, f'motion.{k}')});"
        for k, v in (tokens.get("motion") or {}).items()
    )
    out.append(f"abstract final class Motion {{\n{motion}\n}}\n")
    return "\n".join(out)


def main(argv):
    try:
        text = render(json.loads(SRC.read_text(encoding="utf-8")))
    except (TokenError, json.JSONDecodeError, KeyError) as e:
        print(f"design/tokens.json 오류: {e}", file=sys.stderr)
        return 1
    if argv == ["--check"]:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("lib/design/tokens.g.dart 가 design/tokens.json 과 다릅니다. "
                  "python3 tool/gen_tokens.py 를 돌린 뒤 둘 다 커밋합니다.", file=sys.stderr)
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print(f"만들었습니다: {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
