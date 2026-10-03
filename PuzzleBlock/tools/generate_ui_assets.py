"""Generate crisp navigation and state icons used by the game UI.

All icons are drawn at 4x and downsampled to transparent 64px PNGs. Keep these
files shape-based: the bundled font does not contain dependable icon glyphs.

Usage: python tools/generate_ui_assets.py
"""
import math
import os

from PIL import Image, ImageDraw


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
SIZE = 64
SS = 4
S = SIZE * SS

TEXT = (237, 242, 252, 255)
MUTED = (153, 171, 199, 255)
CYAN = (33, 212, 237, 255)
GOLD = (252, 209, 77, 255)
INK = (28, 37, 59, 255)


def sc(value):
    return int(round(value * SS))


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def finish(img, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    img.resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(path, "PNG")
    print(f"Generated: {path}")


def line(draw, points, fill=TEXT, width=6):
    draw.line([(sc(x), sc(y)) for x, y in points], fill=fill, width=sc(width), joint="curve")


def home_icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(sc(8), sc(31)), (sc(32), sc(10)), (sc(56), sc(31))], fill=CYAN)
    d.rounded_rectangle([sc(14), sc(28), sc(50), sc(55)], radius=sc(5), fill=CYAN)
    d.rounded_rectangle([sc(27), sc(39), sc(37), sc(55)], radius=sc(2), fill=INK)
    return img


def settings_icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    cx = cy = sc(32)
    outer = sc(24)
    inner = sc(17)
    points = []
    for i in range(32):
        angle = -math.pi / 2 + i * math.pi / 16
        radius = outer if i % 4 in (0, 1) else inner
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    d.polygon(points, fill=TEXT)
    d.ellipse([sc(19), sc(19), sc(45), sc(45)], fill=TEXT)
    d.ellipse([sc(27), sc(27), sc(37), sc(37)], fill=INK)
    return img


def crown_icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([
        (sc(10), sc(19)), (sc(21), sc(31)), (sc(32), sc(13)),
        (sc(43), sc(31)), (sc(54), sc(19)), (sc(49), sc(47)), (sc(15), sc(47)),
    ], fill=GOLD)
    d.rounded_rectangle([sc(14), sc(44), sc(50), sc(53)], radius=sc(3), fill=GOLD)
    d.line([(sc(17), sc(41)), (sc(47), sc(41))], fill=(212, 157, 31, 255), width=sc(3))
    return img


def sound_icon(muted=False):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([sc(9), sc(25), sc(20), sc(39)], radius=sc(3), fill=TEXT)
    d.polygon([(sc(18), sc(25)), (sc(32), sc(14)), (sc(32), sc(50)), (sc(18), sc(39))], fill=TEXT)
    if muted:
        line(d, [(39, 25), (53, 39)], fill=(237, 92, 92, 255), width=5)
        line(d, [(53, 25), (39, 39)], fill=(237, 92, 92, 255), width=5)
    else:
        d.arc([sc(31), sc(20), sc(48), sc(44)], -55, 55, fill=MUTED, width=sc(4))
        d.arc([sc(33), sc(13), sc(58), sc(51)], -55, 55, fill=TEXT, width=sc(4))
    return img


def close_icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    line(d, [(13, 13), (51, 51)], fill=TEXT, width=7)
    line(d, [(51, 13), (13, 51)], fill=TEXT, width=7)
    return img


def lock_icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    lock_color = (174, 193, 220, 255)
    d.arc([sc(16), sc(5), sc(48), sc(39)], 180, 360, fill=lock_color, width=sc(7))
    line(d, [(16, 21), (16, 34)], fill=lock_color, width=7)
    line(d, [(48, 21), (48, 34)], fill=lock_color, width=7)
    d.rounded_rectangle([sc(8), sc(27), sc(56), sc(59)], radius=sc(8), fill=lock_color)
    d.ellipse([sc(29), sc(37), sc(35), sc(43)], fill=INK)
    d.rounded_rectangle([sc(30), sc(41), sc(34), sc(49)], radius=sc(2), fill=INK)
    return img


if __name__ == "__main__":
    finish(home_icon(), "home_icon.png")
    finish(settings_icon(), "settings_icon.png")
    finish(crown_icon(), "crown_icon.png")
    finish(sound_icon(False), "sound_on.png")
    finish(sound_icon(True), "sound_off.png")
    finish(close_icon(), "close_icon.png")
    finish(lock_icon(), "lock_icon.png")
