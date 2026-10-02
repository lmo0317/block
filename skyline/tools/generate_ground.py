"""Builds the painted ground pieces that must line up exactly, from the Codex textures.

Needs assets/sprites/hd/tex_grass.png, tex_asphalt.png (tools/codex_art.py) and writes, at 64x64:
  road0..road15      asphalt with sidewalks; mask N=1 E=2 S=4 W=8 (transparent outside the road)
  bridge0..bridge15  wooden deck with rails (transparent, drawn over water)
  lot_r, lot_c, lot_i  empty zoned lots: fenced lawn, paved plaza, gravel yard with stripes
                       (the game draws a faint house/shop/factory picture on top)
Also:
  car_h0..3, car_v0..3  color versions of the painted red car (hue shift)
  assets/sprites/icon.png  app icon from the painted sprites

Usage: python tools/generate_ground.py
"""
import colorsys
import os
import random

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
HD = os.path.join(ROOT, "assets", "sprites", "hd")
S = 64
LO, HI = 12, 52          # road body spans LO..HI-1 (same proportions as the 16 px tiles)
SIDE = 5                 # sidewalk width

INK = (44, 36, 54, 255)
CURB = (214, 206, 190, 255)
CURB_D = (170, 160, 146, 255)
LINE = (250, 222, 120, 255)
WOOD = (176, 124, 72, 255)
WOOD_D = (118, 80, 48, 255)


def load(name):
    return Image.open(os.path.join(HD, name + ".png")).convert("RGBA")


def save(img, name):
    img.save(os.path.join(HD, name + ".png"))


def road(mask, asphalt):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    body = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(body)
    d.rectangle([LO, LO, HI - 1, HI - 1], fill=255)
    if mask & 1:
        d.rectangle([LO, 0, HI - 1, LO], fill=255)
    if mask & 4:
        d.rectangle([LO, HI - 1, HI - 1, S - 1], fill=255)
    if mask & 8:
        d.rectangle([0, LO, LO, HI - 1], fill=255)
    if mask & 2:
        d.rectangle([HI - 1, LO, S - 1, HI - 1], fill=255)
    # sidewalk = body grown by SIDE, asphalt = body. Work on a padded copy (edges repeated) so a road
    # that runs off the tile keeps its sidewalks to the edge and nothing wraps around.
    grown = np.array(body) > 0
    pad = SIDE + 2
    g = np.pad(grown, pad, mode="edge")
    sd = g.copy()
    for _ in range(SIDE):
        sd = sd | np.roll(sd, 1, 0) | np.roll(sd, -1, 0) | np.roll(sd, 1, 1) | np.roll(sd, -1, 1)
    inner = sd & np.roll(sd, 1, 0) & np.roll(sd, -1, 0) & np.roll(sd, 1, 1) & np.roll(sd, -1, 1)
    side = sd[pad:-pad, pad:-pad]
    ring = (sd & ~inner)[pad:-pad, pad:-pad]
    a = np.zeros((S, S, 4), np.uint8)
    rnd = np.random.default_rng(mask)
    curb = np.array(CURB, np.uint8)
    a[side] = curb
    a[side, :3] = np.clip(curb[:3].astype(int) + rnd.integers(-8, 9, (side.sum(), 1)), 0, 255)
    a[ring] = CURB_D
    asp = np.array(asphalt.resize((S, S)))
    a[grown] = asp[grown]
    img = Image.fromarray(a)
    d = ImageDraw.Draw(img)
    mid = S // 2
    if mask in (5,):
        for y in range(2, S, 16):
            d.rectangle([mid - 2, y, mid + 1, y + 7], fill=LINE)
    if mask in (10,):
        for x in range(2, S, 16):
            d.rectangle([x, mid - 2, x + 7, mid + 1], fill=LINE)
    return img


def bridge(mask):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, x1, y0, y1 = LO - 3, HI + 2, LO - 3, HI + 2
    rects = [(LO - 3, LO - 3, HI + 2, HI + 2)]
    if mask & 1:
        rects.append((LO - 3, 0, HI + 2, LO))
    if mask & 4:
        rects.append((LO - 3, HI, HI + 2, S - 1))
    if mask & 8:
        rects.append((0, LO - 3, LO, HI + 2))
    if mask & 2:
        rects.append((HI, LO - 3, S - 1, HI + 2))
    for r in rects:
        d.rectangle(r, fill=WOOD)
    vertical = (mask & 5) and not (mask & 10)
    for k in range(0, S, 6):  # plank gaps across the direction of travel
        if vertical:
            d.line([(0, k), (S, k)], fill=WOOD_D, width=1)
        else:
            d.line([(k, 0), (k, S)], fill=WOOD_D, width=1)
    a = np.array(img)
    keep = np.zeros((S, S), bool)
    for r in rects:
        keep[r[1]:r[3] + 1, r[0]:r[2] + 1] = True
    a[~keep] = 0
    img = Image.fromarray(a)
    d = ImageDraw.Draw(img)
    rail = (96, 62, 36, 255)
    if not mask & 1:
        d.rectangle([LO - 3, LO - 3, HI + 2, LO - 1], fill=rail)
    if not mask & 4:
        d.rectangle([LO - 3, HI, HI + 2, HI + 2], fill=rail)
    if not mask & 8:
        d.rectangle([LO - 3, LO - 3, LO - 1, HI + 2], fill=rail)
    if not mask & 2:
        d.rectangle([HI, LO - 3, HI + 2, HI + 2], fill=rail)
    if mask & 5 and not mask & 10:
        d.rectangle([LO - 3, 0, LO - 1, S - 1], fill=rail)
        d.rectangle([HI, 0, HI + 2, S - 1], fill=rail)
    if mask & 10 and not mask & 5:
        d.rectangle([0, LO - 3, S - 1, LO - 1], fill=rail)
        d.rectangle([0, HI, S - 1, HI + 2], fill=rail)
    return img


def lot(kind, grass):
    rnd = random.Random(kind)
    if kind == "r":
        base = Image.eval(grass.resize((S, S)), lambda v: min(255, int(v * 1.12)))
        img = base.convert("RGBA")
        d = ImageDraw.Draw(img)
        for k in range(3, S - 3, 6):    # picket fence
            for (x, y) in [(k, 3), (k, S - 6), (3, k), (S - 6, k)]:
                d.rectangle([x, y, x + 2, y + 2], fill=(250, 248, 236, 255))
        d.rectangle([3, 4, S - 4, 4], fill=(230, 226, 210, 255))
        d.rectangle([3, S - 5, S - 4, S - 5], fill=(230, 226, 210, 255))
    elif kind == "c":
        img = Image.new("RGBA", (S, S), (214, 220, 232, 255))
        d = ImageDraw.Draw(img)
        for y in range(0, S, 8):
            for x in range(0, S, 8):
                v = rnd.randint(-10, 6)
                col = (196 + v, 204 + v, 222 + v, 255) if (x // 8 + y // 8) % 2 else (216 + v, 222 + v, 234 + v, 255)
                d.rectangle([x, y, x + 7, y + 7], fill=col, outline=(180, 186, 200, 255))
    else:
        img = Image.new("RGBA", (S, S), (200, 176, 128, 255))
        d = ImageDraw.Draw(img)
        for _ in range(260):
            x, y = rnd.randrange(S), rnd.randrange(S)
            v = rnd.choice([(170, 146, 100), (220, 200, 156), (150, 130, 96)])
            d.rectangle([x, y, x + 1, y + 1], fill=v + (255,))
        for x in range(0, S, 8):     # hazard stripes top and bottom
            d.polygon([(x, 0), (x + 4, 0), (x + 8, 5), (x + 4, 5)], fill=(250, 200, 50, 255))
            d.polygon([(x, S - 6), (x + 4, S - 6), (x + 8, S - 1), (x + 4, S - 1)], fill=(250, 200, 50, 255))
        d.rectangle([0, 5, S, 6], fill=(60, 52, 46, 255))
        d.rectangle([0, S - 7, S, S - 6], fill=(60, 52, 46, 255))
    return img


def hue_shift(img, shift, min_sat=0.35):
    a = np.array(img).astype(float) / 255.0
    out = a.copy()
    flat = a.reshape(-1, 4)
    res = out.reshape(-1, 4)
    for i, (r, g, b, al) in enumerate(flat):
        if al == 0:
            continue
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        if s >= min_sat and (h < 0.08 or h > 0.92):     # only the red paint
            nr, ng, nb = colorsys.hls_to_rgb((h + shift) % 1.0, l, s)
            res[i, :3] = (nr, ng, nb)
    return Image.fromarray((out * 255).astype(np.uint8))


def desaturate_white(img):
    """Red paint -> white/silver car."""
    a = np.array(img).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = (r > g * 1.4) & (r > b * 1.4) & (a[..., 3] > 0)
    l = r * 0.35 + 170
    for c in range(3):
        a[..., c] = np.where(red, np.clip(l, 0, 245), a[..., c])
    return Image.fromarray(a.astype(np.uint8))


def app_icon():
    grass = load("tex_grass").resize((256, 256))
    icon = Image.new("RGBA", (256, 256), (126, 196, 244, 255))
    icon.paste(grass.crop((0, 0, 256, 96)), (0, 160))
    for name, x, w in [("house_a", 8, 128), ("cafe", 124, 124)]:
        s = load(name)
        s = s.resize((w, round(s.height * w / s.width)), Image.LANCZOS)
        icon.alpha_composite(s, (x, 236 - s.height))
    t = load("tree")
    t = t.resize((70, round(t.height * 70 / t.width)), Image.LANCZOS)
    icon.alpha_composite(t, (186, 250 - t.height))
    icon.save(os.path.join(ROOT, "assets", "sprites", "icon.png"))


def main():
    grass = load("tex_grass")
    asphalt = load("tex_asphalt")
    for m in range(16):
        save(road(m, asphalt), "road%d" % m)
        save(bridge(m), "bridge%d" % m)
    for k in ("r", "c", "i"):
        save(lot(k, grass), "lot_" + k)
    for view in ("h", "v"):
        if os.path.exists(os.path.join(HD, "car_%s.png" % view)):
            car = load("car_" + view)
            save(car, "car_%s0" % view)
            save(hue_shift(car, 0.62), "car_%s1" % view)
            save(hue_shift(car, 0.14), "car_%s2" % view)
            save(desaturate_white(car), "car_%s3" % view)
    if all(os.path.exists(os.path.join(HD, n + ".png")) for n in ("house_a", "cafe", "tree")):
        app_icon()
    print("ground pieces written to", HD)


if __name__ == "__main__":
    main()
