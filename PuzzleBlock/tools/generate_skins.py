"""Generate alternate block skins into assets/sprites/skins/<skin>/block_<color>.png.

The default "classic" skin stays at assets/sprites/block_<color>.png (tools/generate_original_blocks.py).
Colors come from that script's PALETTE so every skin keeps the same hue per shape.

Usage: python tools/generate_skins.py
"""
import ast
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SKINS_DIR = os.path.join(ROOT, "assets", "sprites", "skins")
SIZE = 76
SCALE = 4


def load_palette():
    src = open(os.path.join(os.path.dirname(__file__), "generate_original_blocks.py"), encoding="utf-8").read()
    for node in ast.parse(src).body:
        if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "PALETTE":
            return ast.literal_eval(node.value)
    raise RuntimeError("PALETTE not found")


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def finish(img):
    return img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)


def candy(c):
    """Rounded, glossy jelly block with a big highlight."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    pad = 2 * SCALE
    radius = 18 * SCALE
    # vertical gradient body
    body = Image.new("RGBA", (s, s))
    bd = ImageDraw.Draw(body)
    top = mix(c["base"], (255, 255, 255), 0.35)
    bottom = mix(c["base"], (0, 0, 0), 0.25)
    for y in range(s):
        bd.line([(0, y), (s, y)], fill=mix(top, bottom, y / s) + (255,))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([pad, pad, s - pad, s - pad], radius=radius, fill=255)
    img.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([pad, pad, s - pad, s - pad], radius=radius, outline=mix(c["base"], (0, 0, 0), 0.45) + (255,), width=3 * SCALE)
    # gloss highlight
    gloss = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse([s * 0.16, s * 0.1, s * 0.84, s * 0.46], fill=(255, 255, 255, 120))
    gloss = gloss.filter(ImageFilter.GaussianBlur(2 * SCALE))
    img.alpha_composite(gloss)
    ImageDraw.Draw(img).ellipse([s * 0.22, s * 0.16, s * 0.36, s * 0.28], fill=(255, 255, 255, 210))
    return finish(img)


def neon(c):
    """Dark tile with a glowing outline in the shape color."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    pad = 5 * SCALE
    glow_col = mix(c["base"], (255, 255, 255), 0.2)
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle([pad, pad, s - pad, s - pad], radius=10 * SCALE, outline=glow_col + (230,), width=7 * SCALE)
    glow = glow.filter(ImageFilter.GaussianBlur(4 * SCALE))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([pad, pad, s - pad, s - pad], radius=10 * SCALE, fill=mix(c["base"], (8, 12, 28), 0.82) + (245,))
    d.rounded_rectangle([pad, pad, s - pad, s - pad], radius=10 * SCALE, outline=glow_col + (255,), width=4 * SCALE)
    inner = 19 * SCALE
    d.rounded_rectangle([inner, inner, s - inner, s - inner], radius=4 * SCALE, outline=c["top"] + (200,), width=2 * SCALE)
    return finish(img)


def jewel(c):
    """Cut gemstone: beveled frame with a faceted diamond in the middle."""
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b = int(s * 0.12)
    d.polygon([(0, 0), (s, 0), (s - b, b), (b, b)], fill=c["top"])
    d.polygon([(0, s), (s, s), (s - b, s - b), (b, s - b)], fill=c["bottom"])
    d.polygon([(0, 0), (b, b), (b, s - b), (0, s)], fill=c["left"])
    d.polygon([(s, 0), (s - b, b), (s - b, s - b), (s, s)], fill=c["right"])
    d.rectangle([b, b, s - b, s - b], fill=mix(c["base"], (0, 0, 0), 0.15))
    cx = cy = s / 2
    r = s / 2 - b - 2 * SCALE
    top, right, bottom, left = (cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)
    center = (cx, cy)
    d.polygon([top, right, center], fill=mix(c["base"], (255, 255, 255), 0.45))
    d.polygon([right, bottom, center], fill=c["right"])
    d.polygon([bottom, left, center], fill=mix(c["base"], (0, 0, 0), 0.2))
    d.polygon([left, top, center], fill=mix(c["base"], (255, 255, 255), 0.7))
    d.line([top, right, bottom, left, top], fill=mix(c["base"], (255, 255, 255), 0.8), width=2 * SCALE)
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=4 * SCALE, fill=255)
    img.putalpha(mask)
    return finish(img)


SKINS = {"candy": candy, "neon": neon, "jewel": jewel}


def main():
    palette = load_palette()
    for skin, render in SKINS.items():
        out_dir = os.path.join(SKINS_DIR, skin)
        os.makedirs(out_dir, exist_ok=True)
        for color, cols in palette.items():
            render(cols).save(os.path.join(out_dir, f"block_{color}.png"))
        print(f"{skin}: {len(palette)} blocks -> {out_dir}")


if __name__ == "__main__":
    main()
