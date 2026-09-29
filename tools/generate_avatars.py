"""Generate profile avatars and the settings gear icon.

Avatars are "block buddies": one beveled block in each game color (same bevel as the board blocks,
colors from generate_original_blocks.py PALETTE) with a distinct face, so they match the game and
stay readable at 36px in the ranking list.

Usage: python tools/generate_avatars.py
"""
import ast
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "avatars")
SIZE = 256          # output size
SS = 4              # supersampling factor
S = SIZE * SS       # working canvas
INK = (28, 32, 58)
WHITE = (255, 255, 255)


def load_palette():
    src = open(os.path.join(os.path.dirname(__file__), "generate_original_blocks.py"), encoding="utf-8").read()
    for node in ast.parse(src).body:
        if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "PALETTE":
            return ast.literal_eval(node.value)
    raise RuntimeError("PALETTE not found")


def u(v):
    """Design units (0..100) -> working pixels."""
    return v * S / 100.0


def box(x0, y0, x1, y1):
    return [u(x0), u(y0), u(x1), u(y1)]


def block_body(c):
    """Beveled rounded block, same construction as the board blocks."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b = u(12)
    d.polygon([(0, 0), (S, 0), (S - b, b), (b, b)], fill=c["top"])
    d.polygon([(0, S), (S, S), (S - b, S - b), (b, S - b)], fill=c["bottom"])
    d.polygon([(0, 0), (b, b), (b, S - b), (0, S)], fill=c["left"])
    d.polygon([(S, 0), (S - b, b), (S - b, S - b), (S, S)], fill=c["right"])
    d.rectangle([b, b, S - b, S - b], fill=c["base"])
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=u(14), fill=255)
    img.putalpha(mask)
    return img


def eye(d, cx, cy, w=9, h=12):
    d.rounded_rectangle(box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), radius=u(w / 2), fill=INK)
    d.ellipse(box(cx - w / 2 + 1.6, cy - h / 2 + 1.8, cx - w / 2 + 4.6, cy - h / 2 + 4.8), fill=WHITE)


def smile(d, cx, cy, w=20, h=12, width=3.2):
    d.arc(box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), 20, 160, fill=INK, width=int(u(width)))


def happy_eye(d, cx, cy, w=10):
    d.arc(box(cx - w / 2, cy - w / 2, cx + w / 2, cy + w / 2), 200, 340, fill=INK, width=int(u(3.2)))


def open_mouth(d, cx, cy, w=18, h=14, tongue=True):
    d.chord(box(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), 0, 180, fill=INK)
    if tongue:
        d.chord(box(cx - w / 4, cy, cx + w / 4, cy + h / 2 - 0.5), 180, 360, fill=(240, 110, 130))


def cheeks(d, y=61, dx=22, color=(255, 120, 150, 110)):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box(50 - dx - 6, y - 3.5, 50 - dx + 6, y + 3.5), fill=color)
    ImageDraw.Draw(layer).ellipse(box(50 + dx - 6, y - 3.5, 50 + dx + 6, y + 3.5), fill=color)
    return layer


def star(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((u(cx + rr * math.cos(a)), u(cy + rr * math.sin(a))))
    d.polygon(pts, fill=fill)


def heart(d, cx, cy, r, fill):
    d.ellipse(box(cx - r, cy - r * 0.9, cx, cy + r * 0.1), fill=fill)
    d.ellipse(box(cx, cy - r * 0.9, cx + r, cy + r * 0.1), fill=fill)
    d.polygon([(u(cx - r * 0.97), u(cy - 0.2 * r)), (u(cx + r * 0.97), u(cy - 0.2 * r)), (u(cx), u(cy + r * 1.05))], fill=fill)


# ---- faces (design units: 0..100 across the block) ----

def face_smile(img):
    d = ImageDraw.Draw(img)
    eye(d, 36, 46); eye(d, 64, 46)
    smile(d, 50, 58)
    img.alpha_composite(cheeks(d))


def face_cool(img):
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box(26, 38, 74, 43), radius=u(2), fill=INK)
    d.rounded_rectangle(box(27, 38, 48, 53), radius=u(6), fill=INK)
    d.rounded_rectangle(box(52, 38, 73, 53), radius=u(6), fill=INK)
    d.line([(u(31), u(47)), (u(36), u(42))], fill=(120, 150, 255), width=int(u(2.4)))
    d.line([(u(56), u(47)), (u(61), u(42))], fill=(120, 150, 255), width=int(u(2.4)))
    d.arc(box(46, 56, 64, 68), 20, 120, fill=INK, width=int(u(3.2)))


def face_fired_up(img):
    d = ImageDraw.Draw(img)
    eye(d, 36, 48, 9, 10); eye(d, 64, 48, 9, 10)
    d.line([(u(27), u(37)), (u(42), u(41))], fill=INK, width=int(u(3.4)))
    d.line([(u(73), u(37)), (u(58), u(41))], fill=INK, width=int(u(3.4)))
    d.chord(box(36, 54, 64, 72), 0, 180, fill=INK)
    d.rectangle(box(40, 63, 60, 66), fill=WHITE)


def face_wink(img):
    d = ImageDraw.Draw(img)
    eye(d, 36, 46)
    happy_eye(d, 64, 48)
    smile(d, 50, 58)
    d.chord(box(50, 62, 58, 70), 180, 360, fill=(240, 110, 130))
    img.alpha_composite(cheeks(d))


def face_star_eyes(img):
    d = ImageDraw.Draw(img)
    star(d, 35, 46, 9, (255, 214, 60))
    star(d, 65, 46, 9, (255, 214, 60))
    d.ellipse(box(44, 58, 56, 70), fill=INK)


def face_happy(img):
    d = ImageDraw.Draw(img)
    happy_eye(d, 36, 47); happy_eye(d, 64, 47)
    open_mouth(d, 50, 60, 22, 18)
    img.alpha_composite(cheeks(d))


def face_glasses(img):
    d = ImageDraw.Draw(img)
    w = int(u(3))
    d.ellipse(box(24, 36, 46, 58), outline=INK, width=w)
    d.ellipse(box(54, 36, 76, 58), outline=INK, width=w)
    d.line([(u(46), u(46)), (u(54), u(46))], fill=INK, width=w)
    eye(d, 35, 47, 7, 9); eye(d, 65, 47, 7, 9)
    smile(d, 50, 64, 14, 8, 3)


def face_love(img):
    d = ImageDraw.Draw(img)
    heart(d, 36, 47, 8, (230, 40, 90))
    heart(d, 64, 47, 8, (230, 40, 90))
    smile(d, 50, 60, 18, 10)
    img.alpha_composite(cheeks(d, color=(255, 90, 140, 130)))


AVATARS = [
    ("yellow", face_smile),
    ("blue", face_cool),
    ("red", face_fired_up),
    ("green", face_wink),
    ("purple", face_star_eyes),
    ("orange", face_happy),
    ("cyan", face_glasses),
    ("pink", face_love),
]


FACE_SCALE = 1.3    # faces are drawn in design units, then enlarged so they read at 36px


def create_avatar(color, face, path):
    img = block_body(color)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    face(layer)
    big = int(S * FACE_SCALE)
    layer = layer.resize((big, big), Image.Resampling.LANCZOS)
    off = (big - S) // 2
    img.alpha_composite(layer.crop((off, off + int(u(2) * FACE_SCALE), off + S, off + S + int(u(2) * FACE_SCALE))))
    img.resize((SIZE, SIZE), Image.Resampling.LANCZOS).save(path, "PNG")
    print(f"Generated: {path}")


def create_settings_icon(output_path):
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r_outer = 48
    r_inner = 36
    r_hole = 16
    teeth = 8

    # Draw gear teeth
    for i in range(teeth):
        angle = (i * 2 * math.pi) / teeth
        ang1 = angle - 0.22
        ang2 = angle + 0.22
        x1 = cx + (r_outer + 8) * math.cos(ang1)
        y1 = cy + (r_outer + 8) * math.sin(ang1)
        x2 = cx + (r_outer + 8) * math.cos(ang2)
        y2 = cy + (r_outer + 8) * math.sin(ang2)
        x3 = cx + r_inner * math.cos(ang2 + 0.15)
        y3 = cy + r_inner * math.sin(ang2 + 0.15)
        x4 = cx + r_inner * math.cos(ang1 - 0.15)
        y4 = cy + r_inner * math.sin(ang1 - 0.15)
        draw.polygon([(x1, y1), (x2, y2), (x3, y3), (x4, y4)], fill=(230, 238, 252))

    # Outer circle
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=(215, 228, 248))
    # Inner hole
    draw.ellipse([cx - r_hole, cy - r_hole, cx + r_hole, cy + r_hole], fill=(0, 0, 0, 0))

    final = img.resize((64, 64), Image.Resampling.LANCZOS)
    final.save(output_path, 'PNG')
    print(f'Generated gear icon: {output_path}')


if __name__ == "__main__":
    palette = load_palette()
    os.makedirs(OUT_DIR, exist_ok=True)
    for i, (color, face) in enumerate(AVATARS, start=1):
        create_avatar(palette[color], face, os.path.join(OUT_DIR, f"avatar_{i}.png"))
    create_settings_icon(os.path.join(ROOT, "assets", "sprites", "settings_icon.png"))
