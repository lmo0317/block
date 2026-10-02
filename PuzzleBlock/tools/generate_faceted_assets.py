import os
from PIL import Image, ImageDraw

ASSETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
os.makedirs(SPRITES_DIR, exist_ok=True)

def render_faceted_block_clean(
    base_color,
    top_color,
    left_color,
    right_color,
    bottom_color,
    outline_color,
    size=74,
    bevel_ratio=0.17,
    scale=4
):
    s = int(size * scale)
    b = int(s * bevel_ratio)
    corner_r = int(3.5 * scale)
    pad = int(1.0 * scale)

    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Dark outer border rim
    draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=corner_r, fill=outline_color)

    # 2. Bevel facet coordinates
    ol, ot = pad, pad
    or_, ob = s - 1 - pad, s - 1 - pad
    il, it = b, b
    ir, ib = s - 1 - b, s - 1 - b

    # Trapezoid polygons - pure flat planes (NO GRADIENT, NO ROUNDED GLOSS)
    draw.polygon([(ol, ot), (or_, ot), (ir, it), (il, it)], fill=top_color)
    draw.polygon([(ol, ob), (or_, ob), (ir, ib), (il, ib)], fill=bottom_color)
    draw.polygon([(ol, ot), (il, it), (il, ib), (ol, ob)], fill=left_color)
    draw.polygon([(or_, ot), (ir, it), (ir, ib), (or_, ob)], fill=right_color)

    # 3. Center square - pure solid flat plane
    draw.rectangle([il, it, ir, ib], fill=base_color)

    # Downsample with Lanczos
    return img.resize((size, size), Image.Resampling.LANCZOS)

PALETTE = {
    "yellow": {
        "base": (255, 195, 0),
        "top": (255, 240, 130),
        "left": (255, 215, 20),
        "right": (240, 150, 0),
        "bottom": (205, 115, 0),
        "outline": (95, 48, 0)
    },
    "blue": {
        "base": (0, 126, 255),
        "top": (125, 206, 255),
        "left": (0, 142, 255),
        "right": (0, 80, 240),
        "bottom": (0, 45, 215),
        "outline": (8, 20, 100)
    },
    "orange": {
        "base": (255, 76, 0),
        "top": (255, 185, 145),
        "left": (255, 105, 15),
        "right": (230, 50, 0),
        "bottom": (190, 30, 0),
        "outline": (90, 15, 0)
    },
    "green": {
        "base": (0, 195, 20),
        "top": (65, 250, 130),
        "left": (0, 215, 40),
        "right": (0, 155, 15),
        "bottom": (0, 95, 8),
        "outline": (0, 48, 5)
    },
    "red": {
        "base": (235, 25, 45),
        "top": (255, 150, 160),
        "left": (250, 55, 75),
        "right": (190, 15, 30),
        "bottom": (145, 10, 20),
        "outline": (75, 5, 10)
    },
    "purple": {
        "base": (160, 45, 235),
        "top": (225, 160, 255),
        "left": (180, 65, 250),
        "right": (130, 30, 200),
        "bottom": (95, 15, 155),
        "outline": (45, 5, 80)
    },
    "cyan": {
        "base": (0, 200, 230),
        "top": (160, 245, 255),
        "left": (50, 220, 245),
        "right": (0, 160, 190),
        "bottom": (0, 115, 145),
        "outline": (0, 55, 75)
    },
    "pink": {
        "base": (245, 50, 150),
        "top": (255, 175, 220),
        "left": (255, 85, 175),
        "right": (205, 30, 120),
        "bottom": (150, 15, 85),
        "outline": (75, 5, 40)
    }
}

for name, cols in PALETTE.items():
    tex = render_faceted_block_clean(
        base_color=cols["base"],
        top_color=cols["top"],
        left_color=cols["left"],
        right_color=cols["right"],
        bottom_color=cols["bottom"],
        outline_color=cols["outline"]
    )
    dest = os.path.join(SPRITES_DIR, f"block_{name}.png")
    tex.save(dest)
    print(f"Generated {dest}")

# 2. Render cell_slot.png (empty board slot matching the dark navy board)
def render_cell_slot(size=74, scale=4):
    s = int(size * scale)
    corner_r = int(3.5 * scale)
    pad = int(1.0 * scale)
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Outer border: dark seam line
    draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=corner_r, fill=(16, 22, 38, 255))
    # Inset tile body
    draw.rounded_rectangle([pad, pad, s - 1 - pad, s - 1 - pad], radius=corner_r - 1, fill=(26, 33, 54, 255))
    # Subtle inner border for recessed depth
    draw.rectangle([pad + 3*scale, pad + 3*scale, s - 1 - pad - 3*scale, s - 1 - pad - 3*scale], fill=(22, 28, 46, 255), outline=(34, 44, 72, 255), width=int(1.0*scale))

    return img.resize((size, size), Image.Resampling.LANCZOS)

slot_img = render_cell_slot()
slot_path = os.path.join(SPRITES_DIR, "cell_slot.png")
slot_img.save(slot_path)
print(f"Generated {slot_path}")

# 3. Render cell_ghost.png (ghost preview matching block shape)
def render_cell_ghost(size=74, scale=4):
    s = int(size * scale)
    corner_r = int(3.5 * scale)
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=corner_r, fill=(255, 255, 255, 60), outline=(255, 255, 255, 220), width=int(2.0*scale))
    return img.resize((size, size), Image.Resampling.LANCZOS)

ghost_img = render_cell_ghost()
ghost_path = os.path.join(SPRITES_DIR, "cell_ghost.png")
ghost_img.save(ghost_path)
print(f"Generated {ghost_path}")

# 4. Generate app icon (block cluster with new faceted style)
def render_app_icon(size=256):
    img = Image.new("RGBA", (size, size), (16, 22, 36, 255))
    bsize = 100
    gap = 8
    start = (size - (bsize * 2 + gap)) // 2

    blocks = [
        ("yellow", (start, start)),
        ("blue", (start + bsize + gap, start)),
        ("orange", (start, start + bsize + gap)),
        ("green", (start + bsize + gap, start + bsize + gap))
    ]

    for cname, pos in blocks:
        cols = PALETTE[cname]
        btex = render_faceted_block_clean(
            base_color=cols["base"],
            top_color=cols["top"],
            left_color=cols["left"],
            right_color=cols["right"],
            bottom_color=cols["bottom"],
            outline_color=cols["outline"],
            size=bsize
        )
        img.paste(btex, pos, btex)

    icon_path = os.path.join(SPRITES_DIR, "icon.png")
    img.save(icon_path)
    print(f"Generated {icon_path}")

render_app_icon()
print("All clean faceted block assets generated successfully!")
