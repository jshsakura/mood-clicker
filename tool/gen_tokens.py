#!/usr/bin/env python3
"""Generate lib/design/tokens.g.dart from design/tokens.json.

  python3 tool/gen_tokens.py           generate the files
  python3 tool/gen_tokens.py --check   only verify that the files match the tokens (hook, CI)

Generated files: lib/design/tokens.g.dart and the native colors: the splash color (the Android colors.xml,
the iOS color set, and the fallback color in LaunchScreen.storyboard) and the home screen widget colors
(widget_ground, widget_ink and widget_line in the same colors.xml, ios/MoodWidget/WidgetColors.g.swift). The splash is always light,
because the app starts in light even when the OS is dark, so it follows light.ground only.
--check also verifies that the Android styles and the iOS storyboard really use those colors.

The tokens use the Tokens Studio single-file format. The top-level key core holds the shared values
and every other set is one theme. Top-level keys that start with $ ($themes, $metadata) are
skipped, and $metadata.tokenSetOrder sets the order of the sets when it is present.
Designers edit only this file. A new color must be added to every theme under the same name.

Accepted value forms (W3C DTCG 2025.10):
  color  "#RRGGBB", "#RRGGBBAA", {colorSpace: "srgb", components: [r, g, b], alpha?, hex?}
  size   "16px", 16, {value, unit: "px"}
  time   "120ms", {value, unit: "ms" or "s"}  (must come out as a whole number of ms, 0 or more)
Each group has a fixed $type (TYPE_OF). An explicit $type that differs is refused. A missing $type
follows the group's slot.
"""
import json
import math
import re
import sys
from pathlib import Path
from xml.etree import ElementTree
from xml.parsers import expat
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "tokens.json"
OUT = ROOT / "lib" / "design" / "tokens.g.dart"

# Native splash. The platform files are written directly, without a package. They follow light.ground.
SPLASH_FILES = {
    "android_light": Path("android/app/src/main/res/values/colors.xml"),
    "ios_colorset": Path("ios/Runner/Assets.xcassets/SplashBackground.colorset/Contents.json"),
    "ios_storyboard": Path("ios/Runner/Base.lproj/LaunchScreen.storyboard"),
    # Colors of the home screen widgets (white tone: light.ground, light.ink and light.line).
    "ios_widget_colors": Path("ios/MoodWidget/WidgetColors.g.swift"),
}

HEX = re.compile(r"#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})")
HEX6 = re.compile(r"#[0-9A-Fa-f]{6}")
IDENT = re.compile(r"[a-z][A-Za-z0-9]*")
DURATION = re.compile(r"(\d+)ms", re.ASCII)
NUMBER = re.compile(r"\d+(?:\.\d+)?", re.ASCII)
SIZE = re.compile(r"(\d+(?:\.\d+)?)(?:px)?", re.ASCII)
SIGNED_SIZE = re.compile(r"(-?\d+(?:\.\d+)?)(?:px)?", re.ASCII)
PERCENT = re.compile(r"(\d+(?:\.\d+)?)%", re.ASCII)
WEIGHTS = {100, 200, 300, 400, 500, 600, 700, 800, 900}

# The $type each group expects. An explicit $type that differs is refused.
TYPE_OF = {
    "color": "color",
    "space": "dimension",
    "radius": "dimension",
    "motion": "duration",
    "type": "typography",
    "font": "fontFamily",
}

# Reserved words of the Dart language. They cannot be identifiers.
DART_WORDS = frozenset(
    """assert break case catch class const continue default do else enum extends false final
    finally for if in is new null rethrow return super switch this throw true try var void while
    with""".split()
)

# Dart rejects a static member that has the same name as an instance member of Object.
OBJECT_MEMBERS = frozenset({"hashCode", "toString", "runtimeType", "noSuchMethod"})

# Space, radius, motion and type names are static members, so only these two sets matter for them.
STATIC_RESERVED = DART_WORDS | OBJECT_MEMBERS

# Color names are fields of AppPalette and parameters of copyWith and lerp, so more names collide.
PALETTE_RESERVED = DART_WORDS | OBJECT_MEMBERS | frozenset(
    """abstract as covariant deferred dynamic export extension external factory function get hide
    implements import interface late library mixin on operator part required set show static
    sync typedef async await yield base sealed
    name brightness type other t copyWith lerp debugFillProperties toDiagnosticsNode""".split()
)

# Names the app code (lib, test) uses. The app does not compile without them, so refuse before generating.
# tool/test_gen_tokens.py checks that every reference found in lib is listed here.
REQUIRED_CORE = {
    "space": ("xs", "sm", "md", "lg", "xl", "xxl", "xxxl", "snug", "row", "inset", "gutter"),
    "radius": ("card", "button", "pill", "panel", "field", "chip"),
    "type": ("display", "title", "body", "label", "count", "wordmark", "caption", "small", "cell"),
    "motion": ("fillRise", "tap", "page"),
    "font": ("family",),
}
REQUIRED_COLORS = (
    "accent", "dawnMint", "dawnPeach", "dawnYellow", "error", "faint", "fill", "fillEdge", "ground", "happy", "ink", "ink2", "inkMuted",
    "line", "mapLine", "moodAnxious", "moodAngry", "moodExcited", "moodHappy", "moodSad", "onAccent", "onError", "onFill", "sad", "stamp", "surface",
)

# Fields a typography token accepts. Tokens Studio adds a few more that are known but unused, so they are skipped.
TYPOGRAPHY_FIELDS = frozenset({"fontFamily", "fontSize", "fontWeight", "lineHeight", "letterSpacing"})
TOKENS_STUDIO_EXTRAS = frozenset({"paragraphSpacing", "paragraphIndent", "textCase", "textDecoration"})

MAX_MS = 3_600_000  # one hour


class TokenError(ValueError):
    pass


REF = re.compile(r"\{([A-Za-z0-9_.]+)\}")


def _no_duplicates(pairs):
    out = {}
    for k, v in pairs:
        if k in out:
            raise TokenError(f"duplicate key '{k}'")
        out[k] = v
    return out


def _no_constant(name):
    raise TokenError(f"{name} is not allowed in JSON")


def parse_json(text, where="JSON"):
    """Refuse duplicate keys and the NaN and Infinity literals."""
    try:
        return json.loads(text, object_pairs_hook=_no_duplicates, parse_constant=_no_constant)
    except TokenError as e:
        raise TokenError(f"{where}: {e}") from None
    except json.JSONDecodeError as e:
        raise TokenError(f"{where}: not valid JSON ({e})") from None


def value(tok, where):
    if not isinstance(tok, dict) or "$value" not in tok:
        raise TokenError(f"{where}: missing $value")
    return tok["$value"]


def check_type(tok, group, where):
    expected = TYPE_OF[group]
    if isinstance(tok, dict) and "$type" in tok and tok["$type"] != expected:
        raise TokenError(f"{where}: $type must be '{expected}' (got {tok['$type']!r})")


def group_items(parent, name, where, required=()):
    """Return only the tokens of a group. Group-level keys that start with $ ($type, $description) are not tokens.

    Refuse a group that is missing, null, not an object or empty, and one that lacks a name the app uses.
    The group's $type must equal the slot's expected type, and the tokens below inherit it.
    """
    g = parent.get(name) if isinstance(parent, dict) else None
    if not isinstance(g, dict):
        raise TokenError(f"{where}: group {name} is missing or not an object")
    if "$type" in g and g["$type"] != TYPE_OF[name]:
        raise TokenError(f"{where}.{name}: the group's $type must be '{TYPE_OF[name]}' (got {g['$type']!r})")
    items = {k: v for k, v in g.items() if not k.startswith("$")}
    if not items:
        raise TokenError(f"{where}: group {name} is empty")
    missing = [k for k in required if k not in items]
    if missing:
        raise TokenError(f"{where}.{name}: names the app uses are missing {missing}")
    return items


def resolve(v, core, where):
    """Replace a reference such as '{font.family}' with the value from core."""
    m = REF.fullmatch(v) if isinstance(v, str) else None
    if not m:
        return v
    node = core
    for part in m.group(1).split("."):
        if not isinstance(node, dict) or part not in node:
            raise TokenError(f"{where}: reference {v} not found")
        node = node[part]
    check_type(node, "font", f"{where} (reference {v})")
    return value(node, where)


def ident(name, where, banned=STATIC_RESERVED):
    if not IDENT.fullmatch(name):
        raise TokenError(f"{where}: name '{name}' must start with a lowercase letter and use only ASCII letters and digits")
    if name in banned:
        raise TokenError(f"{where}: name '{name}' is a Dart reserved word or collides with generated code")
    return name


def real(v, where, what="number"):
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise TokenError(f"{where}: {what} must be a finite number")
    try:
        n = float(v)
    except OverflowError:
        n = math.inf
    if not math.isfinite(n):
        raise TokenError(f"{where}: {what} must be a finite number")
    return n


def unit_object(v, where, units):
    if not isinstance(v, dict) or set(v) != {"value", "unit"}:
        raise TokenError(f"{where}: the object form takes exactly the keys value and unit")
    if v["unit"] not in units:
        raise TokenError(f"{where}: unit must be {' or '.join(units)}")
    return real(v["value"], where), v["unit"]


def size(v, where, positive=False, signed=False):
    """'16px', 16 or {value, unit: px}. A finite number: 0 or more (more than 0 when positive, negatives allowed when signed)."""
    if isinstance(v, dict):
        n, _ = unit_object(v, where, ("px",))
    elif isinstance(v, str):
        m = (SIGNED_SIZE if signed else SIZE).fullmatch(v)
        if not m:
            raise TokenError(f"{where}: a size looks like '16px' ({'a number' if signed else 'a number of 0 or more'}, px optional)")
        n = real(float(m.group(1)), where)
    else:
        n = real(v, where)
    if (n < 0 and not signed) or (positive and n == 0):
        raise TokenError(f"{where}: a size must be {'greater than 0' if positive else '0 or more'}")
    return n


def line_height(v, where):
    """1.2, '1.2' or '150%'. A finite number greater than 0."""
    if isinstance(v, str):
        m = PERCENT.fullmatch(v)
        if m:
            n = real(float(m.group(1)) / 100, where)
        elif NUMBER.fullmatch(v):
            n = real(float(v), where)
        else:
            raise TokenError(f"{where}: a line height looks like 1.2 or '150%'")
    else:
        n = real(v, where)
    if n <= 0:
        raise TokenError(f"{where}: a line height must be greater than 0")
    return n


def font_family(v, where):
    if not isinstance(v, str) or not v.strip():
        raise TokenError(f"{where}: a font name must be a non-empty string")
    if any(c in "\\$" or ord(c) < 32 or ord(c) == 127 for c in v):
        raise TokenError(f"{where}: a font name cannot contain a backslash, $ or a control character such as a newline")
    return v


def dart_quote_safe(text):
    """Make text safe inside a single-quoted Dart string. Only the single quote is rewritten (as \\x27); the other dangerous characters were refused earlier."""
    return text.replace("'", "\\x27")


def byte(x):
    return int(x * 255 + 0.5)


def color_object(v, where):
    if not isinstance(v, dict) or not {"colorSpace", "components"} <= set(v) <= {
        "colorSpace", "components", "alpha", "hex"
    }:
        raise TokenError(f"{where}: a color object takes colorSpace and components, plus optional alpha and hex")
    if v["colorSpace"] != "srgb":
        raise TokenError(f"{where}: only the srgb color space is supported")
    comps = v["components"]
    if not isinstance(comps, list) or len(comps) != 3:
        raise TokenError(f"{where}: components must be [r, g, b]")
    chans = [real(c, where, "color component") for c in comps]
    alpha = real(v["alpha"], where, "alpha") if "alpha" in v else 1.0
    if not all(0 <= c <= 1 for c in [*chans, alpha]):
        raise TokenError(f"{where}: color components and alpha must be between 0 and 1")
    r, g, b = (byte(c) for c in chans)
    if "hex" in v and not (
        isinstance(v["hex"], str)
        and HEX6.fullmatch(v["hex"])
        and v["hex"][1:].upper() == f"{r:02X}{g:02X}{b:02X}"
    ):
        raise TokenError(f"{where}: hex does not match components")
    return f"{byte(alpha):02X}{r:02X}{g:02X}{b:02X}"


def color_argb(tok, where):
    """AARRGGBB of a color token (eight uppercase hex digits)."""
    check_type(tok, "color", where)
    v = value(tok, where)
    if isinstance(v, dict):
        return color_object(v, where)
    if not isinstance(v, str) or not HEX.fullmatch(v):
        raise TokenError(f"{where}: a color is #RRGGBB, #RRGGBBAA or an srgb object")
    h = v[1:].upper()
    return h[6:] + h[:6] if len(h) == 8 else "FF" + h


def luminance(argb):
    """WCAG relative luminance, 0 to 1. Alpha is ignored."""
    def lin(byte_hex):
        c = int(byte_hex, 16) / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(argb[2:4]) + 0.7152 * lin(argb[4:6]) + 0.0722 * lin(argb[6:8])


def brightness_of(doc, argbs, theme):
    """Follow $extensions.app.brightness. When it is missing, guess from whether the relative luminance of ground is above 0.5."""
    ext = doc.get("$extensions")
    app = ext.get("app") if isinstance(ext, dict) else None
    b = app.get("brightness") if isinstance(app, dict) else None
    if b is None:
        return "light" if luminance(argbs["ground"]) > 0.5 else "dark"
    if b not in ("light", "dark"):
        raise TokenError(f"{theme}: $extensions.app.brightness must be light or dark")
    return b


def number(tok, group, where):
    check_type(tok, group, where)
    return size(value(tok, where), where)


def millis(tok, where):
    check_type(tok, "motion", where)
    v = value(tok, where)
    out_of_range = f"{where}: a duration must be between 0 and {MAX_MS}ms (one hour)"
    if isinstance(v, str):
        m = DURATION.fullmatch(v)
        if not m:
            raise TokenError(f"{where}: a duration looks like '120ms' or {{value, unit: ms or s}}")
        ms = int(m.group(1))
        if ms > MAX_MS:
            raise TokenError(out_of_range)
        return ms
    if not isinstance(v, dict):
        raise TokenError(f"{where}: a duration looks like '120ms' or {{value, unit: ms or s}}")
    n, unit = unit_object(v, where, ("ms", "s"))
    ms = n * 1000 if unit == "s" else n
    if not math.isfinite(ms) or not 0 <= ms <= MAX_MS:
        raise TokenError(out_of_range)
    if abs(ms - round(ms)) >= 1e-6 or (ms > 0 and round(ms) == 0):
        raise TokenError(f"{where}: a duration must be a whole number of ms; values below 1ms are not allowed")
    return int(round(ms))


def num(x):
    return str(int(x)) if float(x).is_integer() else repr(float(x))


def palettes(theme_docs):
    if not theme_docs:
        raise TokenError("no theme sets found")
    themes, bright = {}, {}
    for theme, doc in theme_docs.items():
        ident(theme, f"{theme} set", banned=frozenset())
        if not isinstance(doc, dict):
            raise TokenError(f"{theme}: a set must be an object")
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
                f"{t}: every theme must have the same color names. "
                f"missing {sorted(missing) or 'none'}, extra {sorted(extra) or 'none'}"
            )
    return keys, themes, bright


def token_sets(doc):
    """Skip top-level keys that start with $ and return the sets in $metadata.tokenSetOrder order when it is present."""
    if not isinstance(doc, dict):
        raise TokenError("the top level of the token file must be an object")
    sets = {k: v for k, v in doc.items() if not k.startswith("$")}
    meta = doc.get("$metadata")
    order = meta.get("tokenSetOrder") if isinstance(meta, dict) else None
    if order is None:
        return sets
    if not isinstance(order, list) or not all(isinstance(n, str) for n in order) or len(set(order)) != len(order):
        raise TokenError("$metadata.tokenSetOrder must be a list of distinct set names")
    for n in order:
        if n not in sets:
            raise TokenError(f"$metadata.tokenSetOrder lists set '{n}' which is not in the file")
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
        raise TokenError(f"{where}: $value must be an object with keys such as fontFamily and fontSize")
    unknown = sorted(set(spec) - TYPOGRAPHY_FIELDS - TOKENS_STUDIO_EXTRAS)
    if unknown:
        raise TokenError(f"{where}: unknown fields {unknown}. Allowed: {sorted(TYPOGRAPHY_FIELDS)}")
    family = font_family(
        resolve(spec.get("fontFamily", "{font.family}"), core, f"{where}.fontFamily"),
        f"{where}.fontFamily",
    )
    weight = spec.get("fontWeight", "400")
    weight = weight if isinstance(weight, int) and not isinstance(weight, bool) else (
        int(weight) if isinstance(weight, str) and weight.isascii() and weight.isdecimal() else -1
    )
    if weight not in WEIGHTS:
        raise TokenError(f"{where}.fontWeight: must be 100 to 900 in steps of 100")
    if "fontSize" not in spec:
        raise TokenError(f"{where}.fontSize: missing")
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
    """tokens = {"core": {...}, "dark": {...}, ...}. Every key except core is a theme."""
    tokens = token_sets(tokens)
    core = tokens.get("core")
    if not isinstance(core, dict):
        raise TokenError("the core set is missing")
    keys, themes, bright = palettes({k: v for k, v in tokens.items() if k != "core"})
    out = [
        "// Generated file. Do not edit.",
        "// Edit design/tokens.json, then run python3 tool/gen_tokens.py.",
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


def opaque_rgb(tokens, theme, name):
    """RRGGBB of theme.color.<name> for native files. Native splash and widget colors must be opaque."""
    sets = token_sets(tokens)
    doc = sets.get(theme)
    token = doc.get("color", {}).get(name) if isinstance(doc, dict) else None
    if token is None:
        raise TokenError(f"{theme}.color.{name} is missing, so there is no native color")
    argb = color_argb(token, f"{theme}.color.{name}")
    if argb[:2] != "FF":
        raise TokenError(f"{theme}.color.{name}: native splash and widget colors must be opaque")
    return argb[2:]


def splash_ground(tokens, theme):
    """RRGGBB of theme.ground for the splash. The splash background must be opaque."""
    return opaque_rgb(tokens, theme, "ground")


def android_colors_xml(theme, rgb, ink_rgb, line_rgb):
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f"    <!-- Generated file. Do not edit. tool/gen_tokens.py writes it from {theme}.color.ground and "
        f"{theme}.color.ink in design/tokens.json. -->\n"
        f'    <color name="splash_background">#{rgb}</color>\n'
        f'    <color name="widget_ground">#{rgb}</color>\n'
        f'    <color name="widget_ink">#{ink_rgb}</color>\n'
        f'    <color name="widget_line">#{line_rgb}</color>\n</resources>\n'
    )


def swift_widget_colors(ground_rgb, ink_rgb, line_rgb):
    def color(rgb):
        r, g, b = (int(rgb[i:i + 2], 16) for i in (0, 2, 4))
        return f"Color(red: {r}.0 / 255, green: {g}.0 / 255, blue: {b}.0 / 255)"

    return (
        "// Generated file. Do not edit.\n"
        "// Edit design/tokens.json, then run python3 tool/gen_tokens.py.\n"
        "import SwiftUI\n\n"
        "enum WidgetColors {\n"
        f"    static let ground = {color(ground_rgb)}\n"
        f"    static let ink = {color(ink_rgb)}\n"
        f"    static let line = {color(line_rgb)}\n"
        "}\n"
    )


def ios_color_set(light_rgb):
    r, g, b = (f"0x{light_rgb[i:i + 2]}" for i in (0, 2, 4))
    return f"""{{
  "colors" : [
    {{
      "idiom" : "universal",
      "color" : {{
        "color-space" : "srgb",
        "components" : {{ "red" : "{r}", "green" : "{g}", "blue" : "{b}", "alpha" : "1.000" }}
      }}
    }}
  ],
  "info" : {{ "version" : 1, "author" : "xcode" }}
}}
"""


SPLASH_COLOR_NAME = "SplashBackground"


def storyboard_fallback_tag(data):
    """Locate the <color> inside <namedColor name="SplashBackground"> in storyboard bytes.

    Returns (start, end, attributes): the byte span of the start tag and its attributes in file order.
    The XML parser finds the element, so the attribute order and spacing never matter.
    """
    parser = expat.ParserCreate()
    parser.ordered_attributes = True
    stack, named, found = [], [], []

    def start(name, attrs):
        pairs = list(zip(attrs[::2], attrs[1::2]))
        if name == "namedColor" and dict(pairs).get("name") == SPLASH_COLOR_NAME:
            named.append(1)
        if name == "color" and stack and stack[-1][0] == "namedColor" and dict(stack[-1][1]).get("name") == SPLASH_COLOR_NAME:
            found.append((parser.CurrentByteIndex, pairs))
        stack.append((name, pairs))

    parser.StartElementHandler = start
    parser.EndElementHandler = lambda name: stack.pop()
    try:
        parser.Parse(data, True)
    except expat.ExpatError as e:
        raise TokenError(f"LaunchScreen.storyboard is not valid XML ({e})")
    if len(named) != 1 or len(found) != 1:
        raise TokenError(f"exactly one {SPLASH_COLOR_NAME} color with a <color> value is expected in LaunchScreen.storyboard")
    begin, pairs = found[0]
    quote, i = None, begin
    while True:
        c = data[i:i + 1]
        if quote:
            quote = None if c == quote else quote
        elif c in (b'"', b"'"):
            quote = c
        elif c == b">":
            return begin, i + 1, pairs
        i += 1


def ios_storyboard(storyboard, light_rgb):
    """Change only the SplashBackground fallback in LaunchScreen.storyboard to light.ground, fully opaque."""
    data = storyboard.encode("utf-8")
    begin, end, pairs = storyboard_fallback_tag(data)
    wanted = {f"{c}": f"{int(light_rgb[i:i + 2], 16) / 255:.17g}" for c, i in (("red", 0), ("green", 2), ("blue", 4))}
    wanted["alpha"] = "1"
    values = dict(pairs)
    values.update(wanted)
    order = [k for k, _ in pairs] + [k for k in wanted if k not in dict(pairs)]
    attrs = " ".join(f'{k}="{escape(values[k], {chr(34): "&quot;"})}"' for k in order)
    tag = f"<color {attrs}{'/' if data[end - 2:end - 1] == b'/' else ''}>"
    return (data[:begin] + tag.encode("utf-8") + data[end:]).decode("utf-8")


def splash_outputs(tokens, storyboard):
    """{repo-relative path: content}. The splash color comes from light.ground."""
    light, ink, line = (opaque_rgb(tokens, "light", n) for n in ("ground", "ink", "line"))
    return {
        SPLASH_FILES["android_light"]: android_colors_xml("light", light, ink, line),
        SPLASH_FILES["ios_widget_colors"]: swift_widget_colors(light, ink, line),
        SPLASH_FILES["ios_colorset"]: ios_color_set(light),
        SPLASH_FILES["ios_storyboard"]: ios_storyboard(storyboard, light),
    }


ANDROID_RES = Path("android/app/src/main/res")
SPLASH_COLOR_REF = "@color/splash_background"
LAUNCH_DRAWABLE_REF = "@drawable/launch_background"
# (styles file, style name, item name, accepted values)
ANDROID_STYLE_ITEMS = (
    ("values/styles.xml", "LaunchTheme", "android:windowBackground", {LAUNCH_DRAWABLE_REF}),
    ("values/styles.xml", "NormalTheme", "android:windowBackground", {SPLASH_COLOR_REF}),
    ("values-v31/styles.xml", "LaunchTheme", "android:windowSplashScreenBackground", {SPLASH_COLOR_REF}),
)


def parse_xml_file(path, problems, label):
    try:
        return ElementTree.parse(path).getroot()
    except (ElementTree.ParseError, OSError) as e:
        problems.append(f"{label}: cannot read ({e})")
        return None


def android_wiring_problems(root):
    problems = []
    res = root / ANDROID_RES
    for rel, style, item, accepted in ANDROID_STYLE_ITEMS:
        label = f"{ANDROID_RES / rel}"
        tree = parse_xml_file(res / rel, problems, label) if (res / rel).is_file() else None
        if tree is None:
            if not (res / rel).is_file():
                problems.append(f"{label}: missing, so {style} does not use {SPLASH_COLOR_REF}")
            continue
        values = [i.text.strip() for st in tree.iter("style") if st.get("name") == style
                  for i in st.iter("item") if i.get("name") == item and i.text]
        if not any(v in accepted for v in values):
            problems.append(f"{label}: {style} {item} must be {' or '.join(sorted(accepted))} (got {values or 'nothing'})")
    for drawable in sorted(res.glob("drawable*/launch_background.xml")):
        label = f"{ANDROID_RES / drawable.relative_to(res)}"
        tree = parse_xml_file(drawable, problems, label)
        if tree is not None and not any(
            e.get("{http://schemas.android.com/apk/res/android}drawable") == SPLASH_COLOR_REF for e in tree.iter()
        ):
            problems.append(f"{label}: no item uses {SPLASH_COLOR_REF}")
    if not (res / "drawable/launch_background.xml").is_file():
        problems.append(f"{ANDROID_RES}/drawable/launch_background.xml: missing, so {LAUNCH_DRAWABLE_REF} has nothing to draw")
    for night in sorted(p for p in res.glob("values-night*") if p.is_dir()):
        for f in sorted(night.rglob("*.xml")):
            text = f.read_text(encoding="utf-8", errors="ignore")
            if any(w in text for w in ("splash_background", "launch_background", "windowSplashScreenBackground")):
                problems.append(f"{ANDROID_RES / f.relative_to(res)}: dark splash resources are not used (the splash is light only), delete it")
    return problems


def ios_wiring_problems(root):
    problems = []
    colorset = root / SPLASH_FILES["ios_colorset"]
    story_rel = SPLASH_FILES["ios_storyboard"]
    if not colorset.is_file():
        problems.append(f"{SPLASH_FILES['ios_colorset']}: missing, so the {SPLASH_COLOR_NAME} colorset does not exist")
    else:
        try:
            entries = json.loads(colorset.read_text(encoding="utf-8")).get("colors", [])
        except ValueError as e:
            entries = []
            problems.append(f"{SPLASH_FILES['ios_colorset']}: not valid JSON ({e})")
        if any(isinstance(c, dict) and "appearances" in c for c in entries):
            problems.append(f"{SPLASH_FILES['ios_colorset']}: has a dark variant, but the splash is light only")
    storyboard = root / story_rel
    if not storyboard.is_file():
        return problems + [f"{story_rel}: missing"]
    tree = parse_xml_file(storyboard, problems, str(story_rel))
    if tree is None:
        return problems
    if not any(c.get("key") == "backgroundColor" and c.get("name") == SPLASH_COLOR_NAME for c in tree.iter("color")):
        problems.append(f"{story_rel}: no view uses the named color {SPLASH_COLOR_NAME}")
    fallbacks = [c for n in tree.iter("namedColor") if n.get("name") == SPLASH_COLOR_NAME for c in n.iter("color")]
    if len(fallbacks) != 1:
        problems.append(f"{story_rel}: expected one {SPLASH_COLOR_NAME} fallback color, found {len(fallbacks)}")
    else:
        alpha = fallbacks[0].get("alpha")
        try:
            opaque = alpha is not None and float(alpha) == 1.0
        except ValueError:
            opaque = False
        if not opaque:
            problems.append(f"{story_rel}: the {SPLASH_COLOR_NAME} fallback alpha must be 1 (got {alpha})")
    return problems


def splash_wiring_problems(root=ROOT):
    """What is wrong with how the native projects use the generated splash colors. Empty when all is connected."""
    return android_wiring_problems(root) + ios_wiring_problems(root)


def outputs(tokens, root=ROOT):
    """Every file to generate, as {repo-relative path: content}."""
    storyboard_path = root / SPLASH_FILES["ios_storyboard"]
    if not storyboard_path.is_file():
        raise TokenError(f"{SPLASH_FILES['ios_storyboard']} is missing")
    out = {OUT.relative_to(ROOT): render(tokens)}
    out.update(splash_outputs(tokens, storyboard_path.read_text(encoding="utf-8")))
    return out


def stale(outs, root=ROOT):
    """Files whose content on disk is missing or different."""
    return [
        rel
        for rel, text in outs.items()
        if not (root / rel).is_file() or (root / rel).read_text(encoding="utf-8") != text
    ]


def load(path=SRC):
    if not path.is_file():
        raise TokenError(f"{path.name} is missing")
    return token_sets(parse_json(path.read_text(encoding="utf-8"), path.name))


def main(argv):
    try:
        outs = outputs(load())
    except (TokenError, KeyError) as e:
        print(f"design/tokens.json error: {e}", file=sys.stderr)
        return 1
    old = stale(outs)
    if argv == ["--check"]:
        if old:
            print("files generated from design/tokens.json are out of date: "
                  + ", ".join(str(p) for p in old)
                  + ". Run python3 tool/gen_tokens.py and commit the result.", file=sys.stderr)
            return 1
        broken = splash_wiring_problems()
        if broken:
            print("the native splash does not use the generated colors:\n  " + "\n  ".join(broken), file=sys.stderr)
            return 1
        return 0
    for rel in old:
        (ROOT / rel).parent.mkdir(parents=True, exist_ok=True)
        (ROOT / rel).write_text(outs[rel], encoding="utf-8")
        print(f"wrote {rel}")
    if not old:
        print("nothing changed")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
