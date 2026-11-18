#!/usr/bin/env python3
"""design/tokens/*.json 에서 lib/design/tokens.g.dart 를 만든다.

  python3 tool/gen_tokens.py           만든다
  python3 tool/gen_tokens.py --check   만든 파일이 토큰과 맞는지만 본다 (훅, CI)

토큰은 Tokens Studio 의 세트 구성을 따른다. core.json 은 공통 값, 나머지 파일 하나가 테마 하나다.
디자이너는 이 파일들만 고친다. 색을 새로 넣으면 모든 테마에 같은 이름으로 넣어야 한다.

받는 값 형식 (W3C DTCG 2025.10):
  색     "#RRGGBB", "#RRGGBBAA", {colorSpace: "srgb", components: [r, g, b], alpha?, hex?}
  크기   "16px", 16, {value, unit: "px"}
  시간   "120ms", {value, unit: "ms" 또는 "s"}  (결과가 0 이상의 정수 ms 여야 한다)
묶음마다 $type 이 정해져 있고(TYPE_OF) 적혀 있는데 다르면 거절한다. $type 을 생략하면 묶음 자리를 따른다.
"""
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "tokens"
OUT = ROOT / "lib" / "design" / "tokens.g.dart"

HEX = re.compile(r"#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})")
HEX6 = re.compile(r"#[0-9A-Fa-f]{6}")
IDENT = re.compile(r"[a-z][A-Za-z0-9]*")
DURATION = re.compile(r"(\d+)ms", re.ASCII)
NUMBER = re.compile(r"\d+(?:\.\d+)?", re.ASCII)
SIZE = re.compile(r"(\d+(?:\.\d+)?)(?:px)?", re.ASCII)
PERCENT = re.compile(r"(\d+(?:\.\d+)?)%", re.ASCII)
WEIGHTS = {100, 200, 300, 400, 500, 600, 700, 800, 900}

# 묶음마다 기대하는 $type. $type 이 적혀 있는데 다르면 거절한다.
TYPE_OF = {
    "color": "color",
    "space": "dimension",
    "radius": "dimension",
    "motion": "duration",
    "type": "typography",
    "font": "fontFamily",
}

# 다트 예약어와, 생성하는 클래스의 멤버나 매개변수와 겹쳐 코드가 깨지는 이름.
RESERVED = frozenset(
    """assert break case catch class const continue default do else enum extends false final
    finally for if in is new null rethrow return super switch this throw true try var void while
    with
    abstract as covariant deferred dynamic export extension external factory function get hide
    implements import interface late library mixin on operator part required set show static
    sync typedef async await yield base sealed
    name brightness type other t copyWith lerp hashCode runtimeType toString noSuchMethod
    debugFillProperties toDiagnosticsNode""".split()
)


class TokenError(ValueError):
    pass


REF = re.compile(r"\{([A-Za-z0-9_.]+)\}")


def _no_duplicates(pairs):
    out = {}
    for k, v in pairs:
        if k in out:
            raise TokenError(f"같은 키 '{k}' 가 두 번 나옵니다")
        out[k] = v
    return out


def _no_constant(name):
    raise TokenError(f"JSON 에 {name} 은 쓸 수 없습니다")


def parse_json(text, where="JSON"):
    """같은 키가 두 번 나오거나 NaN, Infinity 가 있으면 거절한다."""
    try:
        return json.loads(text, object_pairs_hook=_no_duplicates, parse_constant=_no_constant)
    except TokenError as e:
        raise TokenError(f"{where}: {e}") from None
    except json.JSONDecodeError as e:
        raise TokenError(f"{where}: JSON 형식이 아닙니다 ({e})") from None


def value(tok, where):
    if not isinstance(tok, dict) or "$value" not in tok:
        raise TokenError(f"{where}: $value 가 없습니다")
    return tok["$value"]


def check_type(tok, group, where):
    expected = TYPE_OF[group]
    got = tok.get("$type") if isinstance(tok, dict) else None
    if got is not None and got != expected:
        raise TokenError(f"{where}: $type 은 '{expected}' 여야 합니다 (지금 '{got}')")


def group_of(doc, name, where):
    g = doc.get(name, {})
    g = {} if g is None else g
    if not isinstance(g, dict):
        raise TokenError(f"{where}: {name} 는 객체여야 합니다")
    return g


def resolve(v, core, where):
    """'{font.family}' 같은 참조를 core 의 값으로 바꾼다."""
    m = REF.fullmatch(v) if isinstance(v, str) else None
    if not m:
        return v
    node = core
    for part in m.group(1).split("."):
        if not isinstance(node, dict) or part not in node:
            raise TokenError(f"{where}: 참조 {v} 를 찾지 못했습니다")
        node = node[part]
    check_type(node, "font", f"{where} 가 가리키는 {v}")
    return value(node, where)


def ident(name, where, reserved=True):
    if not IDENT.fullmatch(name):
        raise TokenError(f"{where}: 이름 '{name}' 은 소문자로 시작하는 영문, 숫자만 씁니다")
    if reserved and name in RESERVED:
        raise TokenError(f"{where}: 이름 '{name}' 은 다트 예약어이거나 생성 코드와 겹쳐 쓸 수 없습니다")
    return name


def real(v, where, what="숫자"):
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise TokenError(f"{where}: {what}는 유한한 숫자여야 합니다")
    try:
        n = float(v)
    except OverflowError:
        n = math.inf
    if not math.isfinite(n):
        raise TokenError(f"{where}: {what}는 유한한 숫자여야 합니다")
    return n


def unit_object(v, where, units):
    if not isinstance(v, dict) or set(v) != {"value", "unit"}:
        raise TokenError(f"{where}: 객체 형식은 value 와 unit 두 키만 씁니다")
    if v["unit"] not in units:
        raise TokenError(f"{where}: unit 은 {' 나 '.join(units)} 만 쓸 수 있습니다")
    return real(v["value"], where), v["unit"]


def size(v, where, positive=False):
    """'16px', 16, {value, unit: px}. 0 이상(positive 면 0 초과)의 유한한 수."""
    if isinstance(v, dict):
        n, _ = unit_object(v, where, ("px",))
    elif isinstance(v, str):
        m = SIZE.fullmatch(v)
        if not m:
            raise TokenError(f"{where}: 크기는 '16px' 처럼 0 이상의 수와 px 로 씁니다")
        n = real(float(m.group(1)), where)
    else:
        n = real(v, where)
    if n < 0 or (positive and n == 0):
        raise TokenError(f"{where}: 크기는 {'0 보다 큰' if positive else '0 이상의'} 수여야 합니다")
    return n


def line_height(v, where):
    """1.2, '1.2', '150%'. 0 보다 큰 유한한 수."""
    if isinstance(v, str):
        m = PERCENT.fullmatch(v)
        if m:
            n = real(float(m.group(1)) / 100, where)
        elif NUMBER.fullmatch(v):
            n = real(float(v), where)
        else:
            raise TokenError(f"{where}: 줄 높이는 1.2 나 '150%' 처럼 씁니다")
    else:
        n = real(v, where)
    if n <= 0:
        raise TokenError(f"{where}: 줄 높이는 0 보다 큰 수여야 합니다")
    return n


def font_family(v, where):
    if not isinstance(v, str) or not v.strip():
        raise TokenError(f"{where}: 글꼴 이름은 비어 있지 않은 문자열입니다")
    if any(c in "'\\$" or ord(c) < 32 or ord(c) == 127 for c in v):
        raise TokenError(f"{where}: 글꼴 이름에 작은따옴표, 역슬래시, $, 줄바꿈 같은 제어 문자는 쓸 수 없습니다")
    return v


def byte(x):
    return int(x * 255 + 0.5)


def color_object(v, where):
    if not isinstance(v, dict) or not {"colorSpace", "components"} <= set(v) <= {
        "colorSpace", "components", "alpha", "hex"
    }:
        raise TokenError(f"{where}: 색 객체는 colorSpace, components 를 쓰고 alpha, hex 는 고를 수 있습니다")
    if v["colorSpace"] != "srgb":
        raise TokenError(f"{where}: 색 공간은 srgb 만 지원합니다")
    comps = v["components"]
    if not isinstance(comps, list) or len(comps) != 3:
        raise TokenError(f"{where}: components 는 [r, g, b] 세 개입니다")
    chans = [real(c, where, "색 성분") for c in comps]
    alpha = real(v["alpha"], where, "alpha") if "alpha" in v else 1.0
    if not all(0 <= c <= 1 for c in [*chans, alpha]):
        raise TokenError(f"{where}: 색 성분과 alpha 는 0 이상 1 이하입니다")
    r, g, b = (byte(c) for c in chans)
    if "hex" in v and not (
        isinstance(v["hex"], str)
        and HEX6.fullmatch(v["hex"])
        and v["hex"][1:].upper() == f"{r:02X}{g:02X}{b:02X}"
    ):
        raise TokenError(f"{where}: hex 가 components 와 맞지 않습니다")
    return f"{byte(alpha):02X}{r:02X}{g:02X}{b:02X}"


def color(tok, where):
    check_type(tok, "color", where)
    v = value(tok, where)
    if isinstance(v, dict):
        return f"Color(0x{color_object(v, where)})"
    if not isinstance(v, str) or not HEX.fullmatch(v):
        raise TokenError(f"{where}: 색은 #RRGGBB, #RRGGBBAA 나 srgb 객체로 씁니다")
    h = v[1:].upper()
    argb = h[6:] + h[:6] if len(h) == 8 else "FF" + h
    return f"Color(0x{argb})"


def number(tok, group, where):
    check_type(tok, group, where)
    return size(value(tok, where), where)


def millis(tok, where):
    check_type(tok, "motion", where)
    v = value(tok, where)
    if isinstance(v, str):
        m = DURATION.fullmatch(v)
        if m:
            return int(m.group(1))
    elif isinstance(v, dict):
        n, unit = unit_object(v, where, ("ms", "s"))
        ms = n * 1000 if unit == "s" else n
        if ms >= 0 and abs(ms - round(ms)) < 1e-6:
            return int(round(ms))
        raise TokenError(f"{where}: 시간은 0 이상의 정수 ms 여야 합니다")
    raise TokenError(f"{where}: 시간은 '120ms' 나 {{value, unit: ms 또는 s}} 로 씁니다")


def num(x):
    return str(int(x)) if float(x).is_integer() else repr(float(x))


def palettes(theme_docs):
    if not theme_docs:
        raise TokenError("테마 파일이 하나도 없습니다")
    themes, bright = {}, {}
    for theme, doc in theme_docs.items():
        ident(theme, f"{theme}.json", reserved=False)
        if not isinstance(doc, dict):
            raise TokenError(f"{theme}.json: 최상위는 객체여야 합니다")
        b = (((doc.get("$extensions") or {}).get("app")) or {}).get("brightness")
        if b not in ("light", "dark"):
            raise TokenError(f"{theme}.json: $extensions.app.brightness 는 light 나 dark 여야 합니다")
        bright[theme] = b
        body = group_of(doc, "color", f"{theme}.json")
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


def type_style(k, v, core):
    where = f"core.type.{k}"
    check_type(v, "type", where)
    spec = value(v, where)
    if not isinstance(spec, dict):
        raise TokenError(f"{where}: $value 는 fontFamily, fontSize 같은 키를 가진 객체여야 합니다")
    family = font_family(
        resolve(spec.get("fontFamily", "{font.family}"), core, f"{where}.fontFamily"),
        f"{where}.fontFamily",
    )
    weight = spec.get("fontWeight", "400")
    weight = weight if isinstance(weight, int) and not isinstance(weight, bool) else (
        int(weight) if isinstance(weight, str) and weight.isascii() and weight.isdecimal() else -1
    )
    if weight not in WEIGHTS:
        raise TokenError(f"{where}.fontWeight: 100 단위로 100~900 입니다")
    if "fontSize" not in spec:
        raise TokenError(f"{where}.fontSize: 글자 크기가 없습니다")
    font_size = size(spec["fontSize"], f"{where}.fontSize", positive=True)
    height = line_height(spec.get("lineHeight", "1.2"), f"{where}.lineHeight")
    return (
        f"  static const TextStyle {ident(k, where)} = TextStyle(fontFamily: '{family}', "
        f"fontSize: {num(font_size)}, fontWeight: FontWeight.w{weight}, "
        f"height: {num(height)});"
    )


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
        items = group_of(core, group, "core")
        lines = "\n".join(
            f"  static const double {ident(k, f'{group}.{k}')} = {num(number(v, group, f'{group}.{k}'))};"
            for k, v in items.items()
        )
        out.append(f"abstract final class {cls} {{\n{lines}\n}}\n")

    for k, v in group_of(core, "font", "core").items():
        check_type(v, "font", f"font.{k}")
        font_family(value(v, f"font.{k}"), f"font.{k}")

    styles = [type_style(k, v, core) for k, v in group_of(core, "type", "core").items()]
    out.append("abstract final class TypeScale {\n" + "\n".join(styles) + "\n}\n")

    motion = "\n".join(
        f"  static const Duration {ident(k, f'motion.{k}')} = Duration(milliseconds: {millis(v, f'motion.{k}')});"
        for k, v in group_of(core, "motion", "core").items()
    )
    out.append(f"abstract final class Motion {{\n{motion}\n}}\n")
    return "\n".join(out)


def load(src=SRC):
    files = sorted(src.glob("*.json"))
    return {f.stem: parse_json(f.read_text(encoding="utf-8"), f.name) for f in files}


def main(argv):
    try:
        text = render(load())
    except (TokenError, KeyError) as e:
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
