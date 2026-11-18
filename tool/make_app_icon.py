#!/usr/bin/env python3
"""Draw the app icon: the happy line face of the approved screens, black on white.

Writes assets/app_icon/icon.svg, icon.png (1024) and foreground.png (1024, transparent, smaller
face for the Android adaptive icon safe zone). Run it from the repository root, then
`tool/fl pub run flutter_launcher_icons` makes the platform icons.
"""
import os

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersampling for smooth edges
OUT = os.path.join("assets", "app_icon")

# The happy face of design/canvas/MoodPicker.dc.html on its 24 grid.
CENTER = (12.0, 12.0)
RADIUS = 10.0
EYES = [(9.0, 10.0), (15.0, 10.0)]
# Two cubic curves: M8 14 c1.2 1.6 2.6 2.4 4 2.4 s2.8 -.8 4 -2.4
CURVES = [
    ((8.0, 14.0), (9.2, 15.6), (10.6, 16.4), (12.0, 16.4)),
    ((12.0, 16.4), (13.4, 16.4), (14.8, 15.6), (16.0, 14.0)),
]
STROKE = 3.2
EYE_STROKE = 4.2


def bezier(p0, p1, p2, p3, steps=40):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t**2
        d = t**3
        pts.append(
            (
                a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0],
                a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1],
            )
        )
    return pts


def draw(scale, background):
    size = SIZE * SS
    img = Image.new("RGBA", (size, size), background)
    d = ImageDraw.Draw(img)
    k = scale * SS
    ox = size / 2 - CENTER[0] * k
    oy = size / 2 - CENTER[1] * k

    def px(p):
        return (ox + p[0] * k, oy + p[1] * k)

    def dot(p, r):
        x, y = px(p)
        d.ellipse((x - r * k, y - r * k, x + r * k, y + r * k), fill="black")

    cx, cy = px(CENTER)
    r = RADIUS * k
    w = STROKE * k
    d.ellipse((cx - r - w / 2, cy - r - w / 2, cx + r + w / 2, cy + r + w / 2), fill="black")
    r_in = r - w / 2
    d.ellipse((cx - r_in, cy - r_in, cx + r_in, cy + r_in), fill=background if background[3] else (0, 0, 0, 0))
    if not background[3]:
        # Punch the inside through to transparent, which ellipse fill alone cannot do on RGBA.
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).ellipse((cx - r_in, cy - r_in, cx + r_in, cy + r_in), fill=255)
        clear = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        img = Image.composite(clear, img, mask)
        d = ImageDraw.Draw(img)
    for eye in EYES:
        dot(eye, EYE_STROKE / 2)
    for curve in CURVES:
        # Stamp round dots densely along the curve: an even stroke with round caps.
        for p in bezier(*curve, steps=400):
            dot(p, STROKE / 2)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def svg(scale):
    ox = 512 - CENTER[0] * scale
    oy = 512 - CENTER[1] * scale
    curve = "M8 14c1.2 1.6 2.6 2.4 4 2.4s2.8-.8 4-2.4"
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">\n'
        f'  <rect width="{SIZE}" height="{SIZE}" fill="#FFFFFF"/>\n'
        f'  <g transform="translate({ox:g} {oy:g}) scale({scale:g})" fill="none" stroke="#000000" '
        f'stroke-width="{STROKE}" stroke-linecap="round" stroke-linejoin="round">\n'
        f'    <circle cx="12" cy="12" r="{RADIUS:g}"/>\n'
        f'    <path d="M9 10h.01M15 10h.01" stroke-width="{EYE_STROKE}"/>\n'
        f'    <path d="{curve}"/>\n'
        f"  </g>\n</svg>\n"
    )


def main():
    os.makedirs(OUT, exist_ok=True)
    full = 32.0
    safe = 26.0
    with open(os.path.join(OUT, "icon.svg"), "w") as f:
        f.write(svg(full))
    draw(full, (255, 255, 255, 255)).convert("RGB").save(os.path.join(OUT, "icon.png"))
    draw(safe, (0, 0, 0, 0)).save(os.path.join(OUT, "foreground.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
