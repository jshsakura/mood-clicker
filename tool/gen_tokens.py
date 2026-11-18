#!/usr/bin/env python3
"""design/tokens.json 에서 lib/design/tokens.g.dart 를 만든다.

  python3 tool/gen_tokens.py           만든다
  python3 tool/gen_tokens.py --check   만든 파일이 토큰과 맞는지만 본다 (훅, CI)

토큰은 Tokens Studio 의 단일 파일 형식을 따른다. 최상위 키 core 는 공통 값, 나머지 세트 하나가 테마 하나다.
$themes, $metadata 처럼 $ 로 시작하는 최상위 키는 건너뛰고, $metadata.tokenSetOrder 가 있으면 그 순서를 따른다.
디자이너는 이 파일만 고친다. 색을 새로 넣으면 모든 테마에 같은 이름으로 넣어야 한다.

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
SRC = ROOT / "design" / "tokens.json"
OUT = ROOT / "lib" / "design" / "tokens.g.dart"

HEX = re.compile(r"#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})")
HEX6 = re.compile(r"#[0-9A-Fa-f]{6}")
IDENT = re.compile(r"[a-z][A-Za-z0-9]*")
DURATION = re.compile(r"(\d+)ms", re.ASCII)
NUMBER = re.compile(r"\d+(?:\.\d+)?", re.ASCII)
SIZE = re.compile(r"(\d+(?:\.\d+)?)(?:px)?", re.ASCII)
SIGNED_SIZE = re.compile(r"(-?\d+(?:\.\d+)?)(?:px)?", re.ASCII)
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

# 다트 언어의 예약어. 식별자로 쓸 수 없다.
DART_WORDS = frozenset(
    """assert break case catch class const continue default do else enum extends false final
    finally for if in is new null rethrow return super switch this throw true try var void while
    with""".split()
)

# 클래스의 static 멤버가 Object 의 인스턴스 멤버와 이름이 같으면 다트가 거절한다.
OBJECT_MEMBERS = frozenset({"hashCode", "toString", "runtimeType", "noSuchMethod"})

# 간격, 둥글기, 움직임, 글자 이름은 static 멤버라 이 둘만 피하면 된다.
STATIC_RESERVED = DART_WORDS | OBJECT_MEMBERS

# 색 이름은 AppPalette 의 필드이자 copyWith, lerp 의 매개변수라 더 많은 이름과 겹친다.
PALETTE_RESERVED = DART_WORDS | OBJECT_MEMBERS | frozenset(
    """abstract as covariant deferred dynamic export extension external factory function get hide
    implements import interface late library mixin on operator part required set show static
    sync typedef async await yield base sealed
    name brightness type other t copyWith lerp debugFillProperties toDiagnosticsNode""".split()
)

# 앱 코드(lib, test)가 쓰는 이름. 빠지면 앱이 컴파일되지 않으므로 생성 전에 거절한다.
# tool/test_gen_tokens.py 가 lib 의 실제 참조가 여기 들어 있는지 지킨다.
REQUIRED_CORE = {
    "space": ("sm", "md", "lg", "xl", "xxl", "xxxl"),
    "radius": ("card", "button", "pill"),
    "type": ("display", "title", "body", "label", "count"),
    "motion": ("fillRise",),
    "font": ("family",),
}
REQUIRED_COLORS = (
    "accent", "error", "fill", "ground", "happy", "ink", "inkMuted",
    "line", "mapLine", "onAccent", "onError", "onFill", "sad", "surface",
)

# 글자 토큰이 받는 필드. Tokens Studio 가 덧붙이는 것은 알지만 쓰지 않으므로 건너뛴다.
TYPOGRAPHY_FIELDS = frozenset({"fontFamily", "fontSize", "fontWeight", "lineHeight", "letterSpacing"})
TOKENS_STUDIO_EXTRAS = frozenset({"paragraphSpacing", "paragraphIndent", "textCase", "textDecoration"})

MAX_MS = 3_600_000  # 한 시간


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
    if isinstance(tok, dict) and "$type" in tok and tok["$type"] != expected:
        raise TokenError(f"{where}: $type 은 '{expected}' 여야 합니다 (지금 {tok['$type']!r})")


def group_items(parent, name, where, required=()):
    """묶음 안의 토큰만 돌려준다. 묶음에 붙은 $type, $description 같은 $ 키는 토큰이 아니라 뺀다.

    묶음이 없거나 null 이거나 객체가 아니거나 비었으면, 앱이 쓰는 이름이 빠졌으면 거절한다.
    묶음의 $type 은 그 자리의 기대값과 같아야 하고, 그 아래 토큰이 이를 물려받는다.
    """
    g = parent.get(name) if isinstance(parent, dict) else None
    if not isinstance(g, dict):
        raise TokenError(f"{where}: {name} 묶음이 없거나 객체가 아닙니다")
    if "$type" in g and g["$type"] != TYPE_OF[name]:
        raise TokenError(f"{where}.{name}: 묶음의 $type 은 '{TYPE_OF[name]}' 여야 합니다 (지금 {g['$type']!r})")
    items = {k: v for k, v in g.items() if not k.startswith("$")}
    if not items:
        raise TokenError(f"{where}: {name} 묶음이 비어 있습니다")
    missing = [k for k in required if k not in items]
    if missing:
        raise TokenError(f"{where}.{name}: 앱이 쓰는 이름이 빠졌습니다 {missing}")
    return items


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


def ident(name, where, banned=STATIC_RESERVED):
    if not IDENT.fullmatch(name):
        raise TokenError(f"{where}: 이름 '{name}' 은 소문자로 시작하는 영문, 숫자만 씁니다")
    if name in banned:
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


def size(v, where, positive=False, signed=False):
    """'16px', 16, {value, unit: px}. 0 이상(positive 면 0 초과, signed 면 음수도)의 유한한 수."""
    if isinstance(v, dict):
        n, _ = unit_object(v, where, ("px",))
    elif isinstance(v, str):
        m = (SIGNED_SIZE if signed else SIZE).fullmatch(v)
        if not m:
            raise TokenError(f"{where}: 크기는 '16px' 처럼 {'' if signed else '0 이상의 '}수와 px 로 씁니다")
        n = real(float(m.group(1)), where)
    else:
        n = real(v, where)
    if (n < 0 and not signed) or (positive and n == 0):
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
    if any(c in "\\$" or ord(c) < 32 or ord(c) == 127 for c in v):
        raise TokenError(f"{where}: 글꼴 이름에 역슬래시, $, 줄바꿈 같은 제어 문자는 쓸 수 없습니다")
    return v


def dart_quote_safe(text):
    """작은따옴표 문자열 안에 그대로 넣을 수 있게 작은따옴표만 \\x27 로 바꾼다. 나머지 위험 문자는 앞에서 거절했다."""
    return text.replace("'", "\\x27")


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


def color_argb(tok, where):
    """색 토큰의 AARRGGBB (대문자 16진수 여덟 글자)."""
    check_type(tok, "color", where)
    v = value(tok, where)
    if isinstance(v, dict):
        return color_object(v, where)
    if not isinstance(v, str) or not HEX.fullmatch(v):
        raise TokenError(f"{where}: 색은 #RRGGBB, #RRGGBBAA 나 srgb 객체로 씁니다")
    h = v[1:].upper()
    return h[6:] + h[:6] if len(h) == 8 else "FF" + h


def luminance(argb):
    """WCAG 상대 휘도 0~1. 알파는 보지 않는다."""
    def lin(byte_hex):
        c = int(byte_hex, 16) / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(argb[2:4]) + 0.7152 * lin(argb[4:6]) + 0.0722 * lin(argb[6:8])


def brightness_of(doc, argbs, theme):
    """$extensions.app.brightness 를 따른다. 없으면 ground 의 상대 휘도가 0.5 를 넘는지로 추정한다."""
    ext = doc.get("$extensions")
    app = ext.get("app") if isinstance(ext, dict) else None
    b = app.get("brightness") if isinstance(app, dict) else None
    if b is None:
        return "light" if luminance(argbs["ground"]) > 0.5 else "dark"
    if b not in ("light", "dark"):
        raise TokenError(f"{theme}: $extensions.app.brightness 는 light 나 dark 여야 합니다")
    return b


def number(tok, group, where):
    check_type(tok, group, where)
    return size(value(tok, where), where)


def millis(tok, where):
    check_type(tok, "motion", where)
    v = value(tok, where)
    out_of_range = f"{where}: 시간은 0 이상 {MAX_MS}ms(한 시간) 이하입니다"
    if isinstance(v, str):
        m = DURATION.fullmatch(v)
        if not m:
            raise TokenError(f"{where}: 시간은 '120ms' 나 {{value, unit: ms 또는 s}} 로 씁니다")
        ms = int(m.group(1))
        if ms > MAX_MS:
            raise TokenError(out_of_range)
        return ms
    if not isinstance(v, dict):
        raise TokenError(f"{where}: 시간은 '120ms' 나 {{value, unit: ms 또는 s}} 로 씁니다")
    n, unit = unit_object(v, where, ("ms", "s"))
    ms = n * 1000 if unit == "s" else n
    if not math.isfinite(ms) or not 0 <= ms <= MAX_MS:
        raise TokenError(out_of_range)
    if abs(ms - round(ms)) >= 1e-6 or (ms > 0 and round(ms) == 0):
        raise TokenError(f"{where}: 시간은 정수 ms 여야 합니다. 1ms 보다 작은 값은 쓸 수 없습니다")
    return int(round(ms))


def num(x):
    return str(int(x)) if float(x).is_integer() else repr(float(x))


def palettes(theme_docs):
    if not theme_docs:
        raise TokenError("테마 세트가 하나도 없습니다")
    themes, bright = {}, {}
    for theme, doc in theme_docs.items():
        ident(theme, f"{theme} 세트", banned=frozenset())
        if not isinstance(doc, dict):
            raise TokenError(f"{theme}: 세트는 객체여야 합니다")
        argbs = {
            ident(k, f"{theme}.color.{k}", PALETTE_RESERVED): color_argb(v, f"{theme}.color.{k}")
            for k, v in group_items(doc, "color", theme, REQUIRED_COLORS).items()
        }
        bright[theme] = brightness_of(doc, argbs, theme)
        themes[theme] = {k: f"Color(0x{a})" for k, a in argbs.items()}
    first, *rest = themes
    keys = list(themes[first])
    for t in rest:
        missing, extra = set(keys) - set(themes[t]), set(themes[t]) - set(keys)
        if missing or extra:
            raise TokenError(
                f"{t}: 테마마다 색 이름이 같아야 합니다. "
                f"빠진 것 {sorted(missing) or '없음'}, 남는 것 {sorted(extra) or '없음'}"
            )
    return keys, themes, bright


def token_sets(doc):
    """최상위에서 $ 로 시작하는 키를 건너뛰고, $metadata.tokenSetOrder 가 있으면 그 순서로 세트를 돌려준다."""
    if not isinstance(doc, dict):
        raise TokenError("토큰 파일의 최상위는 객체여야 합니다")
    sets = {k: v for k, v in doc.items() if not k.startswith("$")}
    meta = doc.get("$metadata")
    order = meta.get("tokenSetOrder") if isinstance(meta, dict) else None
    if order is None:
        return sets
    if not isinstance(order, list) or not all(isinstance(n, str) for n in order) or len(set(order)) != len(order):
        raise TokenError("$metadata.tokenSetOrder 는 겹치지 않는 세트 이름의 목록이어야 합니다")
    for n in order:
        if n not in sets:
            raise TokenError(f"$metadata.tokenSetOrder 에 있는 세트 '{n}' 가 파일에 없습니다")
    return {**{n: sets[n] for n in order}, **{k: v for k, v in sets.items() if k not in order}}


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
    unknown = sorted(set(spec) - TYPOGRAPHY_FIELDS - TOKENS_STUDIO_EXTRAS)
    if unknown:
        raise TokenError(f"{where}: 알 수 없는 필드 {unknown}. 쓸 수 있는 것: {sorted(TYPOGRAPHY_FIELDS)}")
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
    spacing = ""
    if "letterSpacing" in spec:
        spacing = f", letterSpacing: {num(size(spec['letterSpacing'], f'{where}.letterSpacing', signed=True))}"
    return (
        f"  static const TextStyle {ident(k, where)} = TextStyle(fontFamily: '{dart_quote_safe(family)}', "
        f"fontSize: {num(font_size)}, fontWeight: FontWeight.w{weight}, "
        f"height: {num(height)}{spacing});"
    )


def render(tokens):
    """tokens = {"core": {...}, "dark": {...}, ...}. core 외의 키가 테마다."""
    tokens = token_sets(tokens)
    core = tokens.get("core")
    if not isinstance(core, dict):
        raise TokenError("core 세트가 없습니다")
    keys, themes, bright = palettes({k: v for k, v in tokens.items() if k != "core"})
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
        items = group_items(core, group, "core", REQUIRED_CORE[group])
        lines = "\n".join(
            f"  static const double {ident(k, f'{group}.{k}')} = {num(number(v, group, f'{group}.{k}'))};"
            for k, v in items.items()
        )
        out.append(f"abstract final class {cls} {{\n{lines}\n}}\n")

    for k, v in group_items(core, "font", "core", REQUIRED_CORE["font"]).items():
        check_type(v, "font", f"font.{k}")
        font_family(value(v, f"font.{k}"), f"font.{k}")

    styles = [
        type_style(k, v, core) for k, v in group_items(core, "type", "core", REQUIRED_CORE["type"]).items()
    ]
    out.append("abstract final class TypeScale {\n" + "\n".join(styles) + "\n}\n")

    motion = "\n".join(
        f"  static const Duration {ident(k, f'motion.{k}')} = Duration(milliseconds: {millis(v, f'motion.{k}')});"
        for k, v in group_items(core, "motion", "core", REQUIRED_CORE["motion"]).items()
    )
    out.append(f"abstract final class Motion {{\n{motion}\n}}\n")
    return "\n".join(out)


def load(path=SRC):
    if not path.is_file():
        raise TokenError(f"{path.name} 이 없습니다")
    return token_sets(parse_json(path.read_text(encoding="utf-8"), path.name))


def main(argv):
    try:
        text = render(load())
    except (TokenError, KeyError) as e:
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
