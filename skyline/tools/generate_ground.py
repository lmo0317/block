"""Draws the isometric ground tiles as real pixel art into assets/sprites/px/, in a Kairosoft-like town
look: bright lawns with tufts, sandy town roads, blue water with an earth bank.

Tiles are 128x64 diamonds: a 64x32 map tile at 2x detail (the game draws them at half size).
Every pixel is computed from its position on the tile in grid space (gx, gy in 0..1; gx grows toward
the lower right, gy toward the lower left), so roads, fences and banks line up exactly from tile to
tile. Neighbor masks: N (y-1) = 1, E (x+1) = 2, S (y+1) = 4, W (x-1) = 8.

  grass0..2                 lawn variants
  water<m>_<f>              water with an earth bank toward land on the mask sides, frames f = 0, 1
  road<m>, bridge<m>        sandy road / wooden bridge pieces by neighbor mask
  lot_r, lot_c, lot_i       zoned plots (also the yard under buildings): fenced lawn, stone paving,
                            concrete yard with hazard stripes
Also: car_front0..3 / car_back0..3 color versions of the red car, and the app icon.

Usage: python tools/generate_ground.py   (after tools/codex_art.py for the cars and the icon)
"""
import colorsys
import os
import random

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PX = os.path.join(ROOT, "assets", "sprites", "px")
TW, TH = 128, 64

GRASS = [(124, 190, 70), (100, 162, 56), (152, 210, 92)]
WATER = [(76, 150, 224), (62, 130, 204), (156, 212, 250)]
BANK = (150, 104, 66)
BANK_L = (182, 134, 88)
ROAD = [(226, 196, 138), (210, 178, 120), (238, 214, 162)]
ROAD_EDGE = (176, 136, 90)
WHITE = (250, 250, 244)
FENCE = (140, 92, 54)
WOOD = (184, 130, 78)
WOOD_D = (128, 86, 52)


def grid():
    """Per-pixel grid coordinates of the diamond and an inside mask."""
    ys, xs = np.mgrid[0:TH, 0:TW]
    u = (xs + 0.5 - TW / 2) / (TW / 2)
    v = (ys + 0.5 - TH / 2) / (TH / 2)
    gx = (u + v) / 2 + 0.5
    gy = (v - u) / 2 + 0.5
    inside = (gx >= 0) & (gx < 1) & (gy >= 0) & (gy < 1)
    return gx, gy, inside


GX, GY, INSIDE = grid()


def blank():
    return np.zeros((TH, TW, 4), np.uint8)


def paint(a, mask, color):
    m = mask & INSIDE
    a[m, :3] = color
    a[m, 3] = 255


def noise(seed, p):
    return np.random.default_rng(seed).random((TH, TW)) < p


def tufts(a, seed, count, dark, light):
    """Little grass tufts: a dark 'v' with a light tip, like hand-drawn town games."""
    rnd = random.Random(seed)
    for _ in range(count):
        x, y = rnd.randrange(8, TW - 8), rnd.randrange(6, TH - 4)
        for (dx, dy, col) in [(-1, 0, dark), (1, 0, dark), (0, 1, dark), (-1, -1, light), (1, -1, light)]:
            if INSIDE[y + dy, x + dx]:
                a[y + dy, x + dx, :3] = col
                a[y + dy, x + dx, 3] = 255


def grass_tile(k):
    a = blank()
    paint(a, INSIDE, GRASS[0])
    paint(a, noise(10 + k, 0.06), GRASS[1])
    paint(a, noise(20 + k, 0.03), GRASS[2])
    tufts(a, 30 + k, 6, GRASS[1], GRASS[2])
    if k == 2:
        rnd = random.Random(k)
        for _ in range(5):
            x, y = rnd.randrange(30, 98), rnd.randrange(14, 50)
            if INSIDE[y, x]:
                col = rnd.choice([(255, 236, 110), (250, 250, 250), (250, 150, 190)])
                a[y, x, :3] = col
                a[y, x + 1, :3] = col
    return a


def water_tile(mask, frame):
    a = blank()
    paint(a, INSIDE, WATER[0])
    paint(a, noise(30 + frame, 0.05), WATER[1])
    rnd = random.Random(40 + frame)
    for _ in range(8):
        x, y = rnd.randrange(20, 104), rnd.randrange(12, 52)
        for dx in range(6):
            if INSIDE[y, x + dx]:
                a[y, x + dx, :3] = WATER[2]
    rim, edge = 0.12, 0.06
    sides = [(mask & 1, GY < rim, GY < edge), (mask & 2, GX > 1 - rim, GX > 1 - edge),
             (mask & 4, GY > 1 - rim, GY > 1 - edge), (mask & 8, GX < rim, GX < edge)]
    for on, m, top in sides:
        if on:
            paint(a, m, BANK)
            paint(a, top, BANK_L)
    return a


def road_body(mask, lo, hi):
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
    outer = road_body(mask, 0.14, 0.86)
    paint(a, outer, ROAD_EDGE)
    body = road_body(mask, 0.18, 0.82)
    paint(a, body, ROAD[0])
    paint(a, body & noise(60 + mask, 0.07), ROAD[1])
    paint(a, body & noise(70 + mask, 0.04), ROAD[2])
    # a few pebbles
    rnd = random.Random(80 + mask)
    for _ in range(5):
        x, y = rnd.randrange(20, 108), rnd.randrange(10, 54)
        if body[y, x] and INSIDE[y, x]:
            a[y, x, :3] = ROAD_EDGE
            a[y, x + 1, :3] = ROAD[2]
    return a


def bridge_tile(mask):
    a = blank()
    deck = road_body(mask, 0.16, 0.84)
    paint(a, deck, WOOD)
    along_x = (mask & 10) and not (mask & 5)
    planks = ((GX if along_x else GY) * 12) % 1 < 0.16
    paint(a, deck & planks, WOOD_D)
    paint(a, deck & ~road_body(mask, 0.22, 0.78), WOOD_D)
    return a


def lot_tile(kind):
    a = blank()
    edge = (GX < 0.05) | (GX > 0.95) | (GY < 0.05) | (GY > 0.95)
    if kind == "r":     # lawn with a low white picket fence
        paint(a, INSIDE, (150, 212, 98))
        paint(a, noise(80, 0.05), (128, 192, 84))
        tufts(a, 81, 4, (118, 178, 76), (176, 226, 120))
        paint(a, edge & ((((GX + GY) * 16) % 1) < 0.55), WHITE)
    elif kind == "c":   # stone paving
        paint(a, INSIDE, (222, 214, 196))
        paint(a, ((np.floor(GX * 6) + np.floor(GY * 6)) % 2) == 0, (204, 194, 174))
        paint(a, edge, (170, 156, 132))
    else:               # concrete yard with hazard stripes
        paint(a, INSIDE, (190, 186, 176))
        paint(a, noise(90, 0.10), (172, 168, 158))
        paint(a, edge, (60, 52, 46))
        paint(a, edge & ((((GX + GY) * 10) % 1) < 0.5), (250, 200, 50))
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
    """256x256 icon: the red-roof house on a lawn tile under a blue sky, scaled 2x with hard pixels."""
    scene = Image.new("RGBA", (128, 128), (126, 196, 244, 255))
    scene.alpha_composite(Image.open(os.path.join(PX, "lot_r.png")).convert("RGBA"), (0, 60))
    house = Image.open(os.path.join(PX, "house_a.png")).convert("RGBA")
    scene.alpha_composite(house, ((128 - house.width) // 2, max(0, 112 - house.height)))
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
    for view in ("front", "back"):
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
