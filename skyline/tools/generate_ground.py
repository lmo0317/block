"""Draws the ground tiles as real pixel art (96x96 = a 48x48 map tile at 2x detail) into assets/sprites/px/.

Every pixel is computed from its position on the tile (gx, gy in 0..1, left to right and top to
bottom), so roads, fences and shores line up exactly from tile to tile.
Neighbor masks: N (y-1) = 1, E (x+1) = 2, S (y+1) = 4, W (x-1) = 8.

  grass0..2                 lawn variants
  water<m>_<f>              water with a sand rim toward land on the mask sides, frames f = 0, 1
  road<m>, bridge<m>        road / wooden bridge pieces by neighbor mask
  lot_r, lot_c, lot_i       empty zoned plots: fenced lawn, paved plaza, gravel yard
Also: car_h0..3 / car_down0..3 / car_up0..3 color versions of the red car, and the app icon.

Usage: python tools/generate_ground.py   (after tools/codex_art.py for the cars and the icon)
"""
import colorsys
import os
import random

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PX = os.path.join(ROOT, "assets", "sprites", "px")
TW, TH = 96, 96

GRASS = [(118, 196, 74), (104, 182, 64), (138, 210, 88)]
WATER = [(70, 150, 226), (56, 128, 204), (150, 210, 250)]
SAND = (234, 214, 150)
SAND_D = (210, 186, 124)
ASPHALT = [(104, 106, 118), (96, 98, 110), (112, 114, 126)]
WALK = (206, 200, 186)
WALK_D = (176, 168, 152)
LINE = (250, 224, 110)
WHITE = (250, 250, 244)
WOOD = (184, 130, 78)
WOOD_D = (128, 86, 52)


def grid():
    """Per-pixel tile coordinates (0..1) and an inside mask (the whole square)."""
    ys, xs = np.mgrid[0:TH, 0:TW]
    gx = (xs + 0.5) / TW
    gy = (ys + 0.5) / TH
    return gx, gy, np.ones((TH, TW), bool)


GX, GY, INSIDE = grid()


def blank():
    return np.zeros((TH, TW, 4), np.uint8)


def paint(a, mask, color):
    m = mask & INSIDE
    a[m, :3] = color
    a[m, 3] = 255


def noise(seed, p):
    return np.random.default_rng(seed).random((TH, TW)) < p


def grass_tile(k):
    a = blank()
    paint(a, INSIDE, GRASS[0])
    paint(a, noise(10 + k, 0.10), GRASS[1])
    paint(a, noise(20 + k, 0.05), GRASS[2])
    if k == 2:
        rnd = random.Random(k)
        for _ in range(8):
            x, y = rnd.randrange(8, 88), rnd.randrange(8, 88)
            if INSIDE[y, x]:
                a[y, x, :3] = rnd.choice([(255, 236, 110), (250, 250, 250), (250, 150, 190)])
    return a


def water_tile(mask, frame):
    a = blank()
    paint(a, INSIDE, WATER[0])
    paint(a, noise(30 + frame, 0.06), WATER[1])
    # short light ripples along the screen x axis
    rnd = random.Random(40 + frame)
    for _ in range(10):
        x, y = rnd.randrange(8, 84), rnd.randrange(8, 88)
        for dx in range(5):
            if INSIDE[y, x + dx]:
                a[y, x + dx, :3] = WATER[2]
    rim = 0.13
    sides = [(mask & 1, GY < rim), (mask & 2, GX > 1 - rim), (mask & 4, GY > 1 - rim), (mask & 8, GX < rim)]
    for on, m in sides:
        if on:
            paint(a, m, SAND)
            paint(a, m & noise(50, 0.15), SAND_D)
    return a


def road_body(mask, lo=0.27, hi=0.73):
    body = (GX >= lo) & (GX < hi) & (GY >= lo) & (GY < hi)
    if mask & 1:
        body |= (GX >= lo) & (GX < hi) & (GY < lo)
    if mask & 4:
        body |= (GX >= lo) & (GX < hi) & (GY >= hi)
    if mask & 8:
        body |= (GY >= lo) & (GY < hi) & (GX < lo)
    if mask & 2:
        body |= (GY >= lo) & (GY < hi) & (GX >= hi)
    return body


def road_tile(mask):
    a = blank()
    walk = road_body(mask, 0.17, 0.83)
    paint(a, walk, WALK)
    paint(a, walk & ~road_body(mask, 0.2, 0.8), WALK_D)
    body = road_body(mask)
    paint(a, body, ASPHALT[0])
    paint(a, body & noise(60 + mask, 0.08), ASPHALT[1])
    paint(a, body & noise(70 + mask, 0.05), ASPHALT[2])
    if mask == 10:   # straight W-E: dashed line along gx
        paint(a, (np.abs(GY - 0.5) < 0.035) & ((GX * 4) % 1 < 0.5), LINE)
    if mask == 5:    # straight N-S: dashed line along gy
        paint(a, (np.abs(GX - 0.5) < 0.035) & ((GY * 4) % 1 < 0.5), LINE)
    return a


def bridge_tile(mask):
    a = blank()
    deck = road_body(mask, 0.2, 0.8)
    paint(a, deck, WOOD)
    along_x = (mask & 10) and not (mask & 5)
    planks = ((GX if along_x else GY) * 10) % 1 < 0.18
    paint(a, deck & planks, WOOD_D)
    paint(a, deck & ~road_body(mask, 0.25, 0.75), WOOD_D)
    return a


def lot_tile(kind):
    a = blank()
    edge = (GX < 0.07) | (GX > 0.93) | (GY < 0.07) | (GY > 0.93)
    if kind == "r":     # lawn with a white picket fence
        paint(a, INSIDE, (146, 214, 104))
        paint(a, noise(80, 0.08), (128, 198, 90))
        paint(a, edge & ((((GX + GY) * 12) % 1) < 0.5), WHITE)
    elif kind == "c":   # paved plaza
        paint(a, INSIDE, (214, 220, 232))
        paint(a, ((np.floor(GX * 4) + np.floor(GY * 4)) % 2) == 0, (194, 202, 222))
        paint(a, edge, (150, 160, 190))
    else:               # gravel yard with hazard stripes
        paint(a, INSIDE, (204, 178, 128))
        paint(a, noise(90, 0.18), (176, 150, 104))
        paint(a, noise(91, 0.06), (226, 206, 160))
        paint(a, edge, (60, 52, 46))
        paint(a, edge & ((((GX + GY) * 8) % 1) < 0.5), (250, 200, 50))
    return a


def save(a, name):
    Image.fromarray(a).save(os.path.join(PX, name + ".png"))


def hue_shift(img, shift):
    a = np.array(img.convert("RGBA")).astype(float) / 255.0
    flat = a.reshape(-1, 4)
    for i in range(len(flat)):
        r, g, b, al = flat[i]
        if al == 0:
            continue
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        if s >= 0.35 and (h < 0.08 or h > 0.92):     # only the red paint
            flat[i, :3] = colorsys.hls_to_rgb((h + shift) % 1.0, l, s)
    return Image.fromarray((a * 255).astype(np.uint8))


def white_car(img):
    a = np.array(img.convert("RGBA")).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    red = (r > g * 1.4) & (r > b * 1.4) & (a[..., 3] > 0)
    light = np.clip(r * 0.35 + 165, 0, 245)
    for c in range(3):
        a[..., c] = np.where(red, light, a[..., c])
    return Image.fromarray(a.astype(np.uint8))


def app_icon():
    """256x256 icon: the red-roof house on grass under a blue sky, scaled up 2x with hard pixels."""
    scene = Image.new("RGBA", (128, 128), (126, 196, 244, 255))
    grass = Image.open(os.path.join(PX, "grass2.png")).convert("RGBA")
    scene.alpha_composite(grass, (-32, 80))
    scene.alpha_composite(grass, (64, 80))
    house = Image.open(os.path.join(PX, "house_a.png")).convert("RGBA")
    scene.alpha_composite(house, ((128 - house.width) // 2, max(0, 120 - house.height)))
    scene.resize((256, 256), Image.NEAREST).save(os.path.join(ROOT, "assets", "sprites", "icon.png"))


def main():
    os.makedirs(PX, exist_ok=True)
    for k in range(3):
        save(grass_tile(k), "grass%d" % k)
    for m in range(16):
        save(road_tile(m), "road%d" % m)
        save(bridge_tile(m), "bridge%d" % m)
        for f in range(2):
            save(water_tile(m, f), "water%d_%d" % (m, f))
    for k in ("r", "c", "i"):
        save(lot_tile(k), "lot_" + k)
    for view in ("h", "down", "up"):
        src = os.path.join(PX, "car_%s.png" % view)
        if os.path.exists(src):
            car = Image.open(src)
            car.save(os.path.join(PX, "car_%s0.png" % view))
            hue_shift(car, 0.62).save(os.path.join(PX, "car_%s1.png" % view))
            hue_shift(car, 0.14).save(os.path.join(PX, "car_%s2.png" % view))
            white_car(car).save(os.path.join(PX, "car_%s3.png" % view))
    if os.path.exists(os.path.join(PX, "house_a.png")):
        app_icon()
    print("ground tiles written to", PX)


if __name__ == "__main__":
    main()
