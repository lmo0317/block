"""Draws every pixel-art sprite of the game into one atlas.

  assets/sprites/atlas.png   all sprites, packed in rows
  assets/sprites/atlas.json  name -> [x, y, w, h]

Tiles are 16x16. Buildings are 16 wide and 24 or 32 tall: the bottom 16 rows sit on the cell and the
rest pokes up over the cell above, which gives the slightly tilted top-down look.

Usage: python tools/generate_sprites.py [--sheet preview.png]
"""
import json
import os
import random
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_PNG = os.path.join(ROOT, "assets", "sprites", "atlas.png")
OUT_JSON = os.path.join(ROOT, "assets", "sprites", "atlas.json")

T = (0, 0, 0, 0)
INK = (44, 36, 54, 255)


def c(r, g, b, a=255):
    return (r, g, b, a)


def shade(col, k):
    """k < 1 darker, k > 1 lighter."""
    if k < 1:
        return c(int(col[0] * k), int(col[1] * k), int(col[2] * k))
    return c(min(255, int(col[0] + (255 - col[0]) * (k - 1))), min(255, int(col[1] + (255 - col[1]) * (k - 1))),
             min(255, int(col[2] + (255 - col[2]) * (k - 1))))


GRASS = c(112, 192, 76)
GRASS_D = c(92, 170, 64)
GRASS_L = c(146, 214, 96)
WATER = c(66, 146, 224)
WATER_D = c(52, 118, 196)
WATER_L = c(140, 200, 246)
ASPHALT = c(112, 112, 124)
ASPHALT_D = c(94, 94, 106)
CURB = c(206, 200, 188)
LINE = c(246, 226, 140)
WOOD = c(176, 124, 72)
WOOD_D = c(126, 84, 50)
GLASS = c(132, 206, 244)
GLASS_L = c(214, 242, 255)
DOOR = c(122, 80, 52)
SKIN = c(250, 210, 170)

ROOFS = {
    "red": c(216, 74, 64), "blue": c(70, 112, 204), "green": c(72, 162, 92), "orange": c(232, 142, 58),
    "purple": c(150, 92, 184), "brown": c(156, 98, 62), "teal": c(48, 160, 160), "gray": c(124, 128, 140),
}
WALLS = {
    "cream": c(248, 236, 204), "white": c(240, 240, 236), "beige": c(228, 204, 164), "gray": c(190, 190, 200),
    "brick": c(194, 104, 80), "mint": c(196, 232, 212), "pink": c(248, 206, 212),
}

sprites = {}


def new(w, h):
    return Image.new("RGBA", (w, h), T)


def px(img, x, y, col):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), col)


def rect(img, x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(img, x, y, col)


def box(img, x0, y0, x1, y1, fill, ink=INK):
    rect(img, x0, y0, x1, y1, ink)
    rect(img, x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)


def hline(img, x0, x1, y, col):
    rect(img, x0, y, x1, y, col)


def shadow(img, x0, x1, y):
    hline(img, x0, x1, y, c(40, 70, 40, 90))


def window(img, x, y, w=2, h=2, lit=False):
    rect(img, x, y, x + w - 1, y + h - 1, c(255, 224, 120) if lit else GLASS)
    px(img, x, y, GLASS_L if not lit else c(255, 248, 200))


def gable_roof(img, x0, x1, top, bottom, col):
    """Roof seen from the front and a bit from above: rows widen toward the eaves."""
    rows = bottom - top + 1
    for i in range(rows):
        inset = max(0, (rows - 1 - i) // 2 - 0)
        inset = min(inset, (x1 - x0) // 2 - 1)
        y = top + i
        hline(img, x0 + inset, x1 - inset, y, INK)
        hline(img, x0 + inset + 1, x1 - inset - 1, y, col if i % 2 == 0 else shade(col, 0.9))
    hline(img, x0, x1, bottom, shade(col, 0.7))
    hline(img, x0 + 1, x1 - 1, top + 1, shade(col, 1.25))


def flat_roof(img, x0, x1, y, col):
    hline(img, x0, x1, y, INK)
    hline(img, x0, x1, y + 1, col)
    hline(img, x0, x1, y + 2, shade(col, 0.8))


def add(name, img):
    sprites[name] = img


# ---------------------------------------------------------------- terrain
def grass_tile(seed):
    rnd = random.Random(seed)
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, GRASS)
    for _ in range(10):
        x, y = rnd.randrange(16), rnd.randrange(16)
        px(img, x, y, GRASS_D)
        if rnd.random() < 0.4:
            px(img, x, y - 1, GRASS_L)
    if seed == 2:
        for (x, y, col) in [(4, 5, c(255, 240, 120)), (11, 10, c(255, 255, 255)), (12, 3, c(250, 160, 200))]:
            px(img, x, y, col)
    return img


for i in range(3):
    add("grass%d" % i, grass_tile(i))


def water_tile(frame):
    img = new(16, 16)
    rect(img, 0, 0, 15, 15, WATER)
    rnd = random.Random(10 + frame)
    for _ in range(5):
        x, y = rnd.randrange(14), rnd.randrange(16)
        hline(img, x, x + 2, y, WATER_L if frame == 0 else WATER_D)
    for _ in range(4):
        x, y = rnd.randrange(15), rnd.randrange(16)
        hline(img, x, x + 1, y, WATER_D)
    return img


add("water0", water_tile(0))
add("water1", water_tile(1))


def tree_cluster(seed, n=3):
    rnd = random.Random(seed)
    img = new(16, 24)
    spots = [(4, 13), (11, 12), (8, 18)][:n]
    for (cx, cy) in spots:
        cx += rnd.randint(-1, 1)
        shadow(img, cx - 3, cx + 3, cy + 5)
        rect(img, cx, cy + 2, cx, cy + 4, c(110, 72, 44))
        for dy in range(-5, 3):
            half = [1, 2, 3, 3, 4, 4, 3, 2][dy + 5]
            hline(img, cx - half, cx + half, cy + dy, INK)
        for dy in range(-4, 2):
            half = [1, 2, 2, 3, 3, 2][dy + 4]
            hline(img, cx - half, cx + half, cy + dy, c(56, 140, 70))
        px(img, cx - 1, cy - 3, c(110, 190, 100))
        px(img, cx - 2, cy - 2, c(110, 190, 100))
        px(img, cx + 1, cy, c(40, 112, 56))
    return img


add("forest", tree_cluster(1))
add("tree", tree_cluster(2, 2))


# ---------------------------------------------------------------- roads: mask N=1 E=2 S=4 W=8
def road_tile(mask, bridge=False):
    img = new(16, 16)
    if bridge:
        rect(img, 0, 0, 15, 15, T)
    base, dark, edge = (WOOD, WOOD_D, WOOD_D) if bridge else (ASPHALT, ASPHALT_D, CURB)
    lo, hi = 3, 12  # road body spans 3..12
    rect(img, lo, lo, hi, hi, base)
    if mask & 1:
        rect(img, lo, 0, hi, lo, base)
    if mask & 4:
        rect(img, lo, hi, hi, 15, base)
    if mask & 8:
        rect(img, 0, lo, lo, hi, base)
    if mask & 2:
        rect(img, hi, lo, 15, hi, base)
    if mask == 0:
        rect(img, lo, lo, hi, hi, base)
    # curb / rails on the open sides
    if not (mask & 1):
        hline(img, lo, hi, lo - 1, edge)
    if not (mask & 4):
        hline(img, lo, hi, hi + 1, edge)
    if not (mask & 8):
        rect(img, lo - 1, lo, lo - 1, hi, edge)
    if not (mask & 2):
        rect(img, hi + 1, lo, hi + 1, hi, edge)
    if mask & 1:
        rect(img, lo - 1, 0, lo - 1, lo - 1, edge)
        rect(img, hi + 1, 0, hi + 1, lo - 1, edge)
    if mask & 4:
        rect(img, lo - 1, hi + 1, lo - 1, 15, edge)
        rect(img, hi + 1, hi + 1, hi + 1, 15, edge)
    if mask & 8:
        hline(img, 0, lo - 1, lo - 1, edge)
        hline(img, 0, lo - 1, hi + 1, edge)
    if mask & 2:
        hline(img, hi + 1, 15, lo - 1, edge)
        hline(img, hi + 1, 15, hi + 1, edge)
    if bridge:
        for y in range(0, 16, 3):
            for x in range(16):
                if img.getpixel((x, y))[:3] == base[:3]:
                    px(img, x, y, dark)
        return img
    # dashed center line on straight pieces
    if mask in (5,):
        for y in (1, 2, 6, 7, 11, 12):
            px(img, 7, y, LINE)
            px(img, 8, y, LINE)
    if mask in (10,):
        for x in (1, 2, 6, 7, 11, 12):
            px(img, x, 7, LINE)
            px(img, x, 8, LINE)
    for (x, y) in [(5, 9), (10, 5), (6, 4)]:
        if img.getpixel((x, y))[:3] == base[:3]:
            px(img, x, y, dark)
    return img


for m in range(16):
    add("road%d" % m, road_tile(m))
    add("bridge%d" % m, road_tile(m, True))


# ---------------------------------------------------------------- residential
def house(roof, wall, chimney=True):
    img = new(16, 24)
    shadow(img, 1, 14, 23)
    box(img, 2, 14, 13, 22, wall)
    gable_roof(img, 1, 14, 7, 14, roof)
    if chimney:
        box(img, 10, 6, 12, 9, c(170, 90, 70))
    rect(img, 7, 18, 8, 21, DOOR)
    px(img, 8, 20, c(240, 200, 90))
    window(img, 3, 16, 3, 2)
    window(img, 10, 16, 3, 2)
    hline(img, 3, 12, 22, shade(wall, 0.8))
    return img


add("house_a", house(ROOFS["red"], WALLS["cream"]))
add("house_b", house(ROOFS["blue"], WALLS["white"]))
add("house_c", house(ROOFS["green"], WALLS["beige"], False))


def rowhouse():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 1, 9, 14, 22, WALLS["pink"])
    flat_roof(img, 1, 14, 7, ROOFS["orange"])
    for x in (3, 7, 11):
        window(img, x, 11, 2, 2)
        window(img, x, 15, 2, 2)
    rect(img, 7, 19, 8, 21, DOOR)
    hline(img, 2, 13, 14, shade(WALLS["pink"], 0.85))
    return img


add("rowhouse", rowhouse())


def apartment():
    img = new(16, 32)
    shadow(img, 0, 15, 31)
    box(img, 2, 4, 13, 30, WALLS["gray"])
    flat_roof(img, 2, 13, 2, ROOFS["teal"])
    for row in range(6):
        y = 7 + row * 4
        for x in (4, 7, 10):
            window(img, x, y, 2, 2, lit=(row * 3 + x) % 7 == 0)
        hline(img, 3, 12, y + 3, shade(WALLS["gray"], 0.88))
    rect(img, 6, 27, 9, 29, DOOR)
    rect(img, 7, 27, 8, 29, GLASS)
    return img


add("apartment", apartment())


# ---------------------------------------------------------------- commercial
SHOPS = {
    # name: (wall, awning, sign, icon pixels drawn in the sign)
    "bakery": (WALLS["cream"], c(226, 120, 60), c(250, 230, 180), [(0, 1, c(200, 140, 70)), (1, 0, c(220, 160, 80)), (2, 1, c(200, 140, 70))]),
    "cafe": (WALLS["beige"], c(120, 80, 60), c(240, 236, 220), [(0, 0, c(110, 70, 40)), (1, 0, c(110, 70, 40)), (0, 1, c(110, 70, 40)), (1, 1, c(110, 70, 40)), (2, 0, c(110, 70, 40))]),
    "restaurant": (WALLS["white"], c(220, 60, 60), c(255, 236, 120), [(0, 0, c(200, 60, 40)), (2, 0, c(200, 60, 40)), (1, 1, c(200, 60, 40))]),
    "clothes": (WALLS["pink"], c(200, 80, 160), c(255, 255, 255), [(0, 0, c(200, 80, 160)), (2, 0, c(200, 80, 160)), (1, 1, c(200, 80, 160)), (1, 0, c(200, 80, 160))]),
    "books": (WALLS["mint"], c(60, 120, 200), c(255, 250, 230), [(0, 0, c(60, 120, 200)), (1, 0, c(220, 80, 60)), (2, 0, c(70, 160, 90)), (0, 1, c(60, 120, 200)), (1, 1, c(220, 80, 60)), (2, 1, c(70, 160, 90))]),
    "flowers": (WALLS["white"], c(80, 170, 90), c(255, 240, 246), [(1, 0, c(240, 90, 140)), (0, 1, c(240, 200, 60)), (2, 1, c(240, 90, 140))]),
}


def shop(name, floors):
    wall, awning, sign, icon = SHOPS[name]
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    top = 11 if floors == 1 else 5
    box(img, 1, top, 14, 22, wall)
    flat_roof(img, 1, 14, top - 2, shade(wall, 0.75))
    if floors == 2:
        for x in (3, 7, 11):
            window(img, x, top + 2, 2, 2)
        hline(img, 2, 13, top + 5, shade(wall, 0.85))
    # sign board
    sy = 12 if floors == 1 else 12
    box(img, 4, sy - 1, 11, sy + 2, sign)
    for (dx, dy, col) in icon:
        px(img, 6 + dx, sy + dy, col)
    # awning stripes
    for x in range(1, 15):
        px(img, x, sy + 3, awning if x % 2 else c(255, 255, 255))
        px(img, x, sy + 4, shade(awning, 0.8) if x % 2 else c(230, 230, 230))
    # big window and door
    rect(img, 2, sy + 5, 7, sy + 8, GLASS)
    px(img, 2, sy + 5, GLASS_L)
    rect(img, 9, sy + 5, 11, 21, DOOR)
    rect(img, 10, sy + 6, 10, sy + 7, GLASS)
    rect(img, 12, sy + 5, 13, sy + 8, GLASS)
    return img


for s in SHOPS:
    add(s, shop(s, 1))
    add(s + "_2", shop(s, 2))


def dept():
    img = new(16, 32)
    shadow(img, 0, 15, 31)
    box(img, 0, 6, 15, 30, c(236, 222, 200))
    flat_roof(img, 0, 15, 4, c(200, 70, 80))
    box(img, 3, 7, 12, 10, c(200, 70, 80))
    for x in (5, 7, 9):
        px(img, x, 8, c(255, 230, 120))
        px(img, x + 1, 9, c(255, 230, 120))
    for row in range(3):
        y = 12 + row * 4
        rect(img, 2, y, 13, y + 2, GLASS)
        for x in (5, 9):
            rect(img, x, y, x, y + 2, c(236, 222, 200))
    for x in range(1, 15):
        px(img, x, 24, c(200, 70, 80) if x % 2 else c(255, 255, 255))
    rect(img, 5, 26, 10, 29, GLASS)
    rect(img, 7, 26, 8, 29, DOOR)
    return img


add("dept", dept())


# ---------------------------------------------------------------- industrial
def smoke(img, x, y):
    for (dx, dy) in [(0, 0), (1, -1), (0, -2), (2, -3), (1, -4)]:
        px(img, x + dx, y + dy, c(230, 230, 234, 210))


def workshop():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 1, 13, 14, 22, c(214, 196, 150))
    gable_roof(img, 0, 15, 9, 13, ROOFS["brown"])
    rect(img, 3, 16, 8, 21, c(150, 150, 160))
    for y in range(16, 22, 2):
        hline(img, 3, 8, y, c(120, 120, 130))
    window(img, 10, 16, 3, 2)
    box(img, 12, 5, 13, 10, c(150, 90, 70))
    smoke(img, 12, 4)
    return img


def factory():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 0, 11, 15, 22, c(200, 196, 186))
    for i in range(4):  # sawtooth roof
        x = i * 4
        for k in range(4):
            px(img, x + k, 10 - (3 - k), INK)
            rect(img, x + k, 11 - (3 - k), x + k, 10, c(150, 158, 170))
        rect(img, x + 3, 7, x + 3, 10, GLASS)
    box(img, 12, 1, 14, 9, c(190, 80, 70))
    hline(img, 12, 14, 3, c(240, 240, 240))
    smoke(img, 13, 0)
    rect(img, 2, 15, 7, 21, c(140, 140, 150))
    for y in range(15, 22, 2):
        hline(img, 2, 7, y, c(112, 112, 124))
    window(img, 9, 15, 2, 2)
    window(img, 12, 15, 2, 2)
    return img


def hightech():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 1, 7, 14, 22, c(226, 236, 244))
    flat_roof(img, 1, 14, 5, c(120, 180, 220))
    rect(img, 2, 9, 13, 12, c(90, 170, 230))
    hline(img, 2, 13, 9, c(170, 220, 250))
    rect(img, 2, 14, 13, 16, c(90, 170, 230))
    rect(img, 6, 18, 9, 21, GLASS)
    box(img, 10, 1, 13, 5, c(200, 210, 220))
    px(img, 11, 2, c(80, 220, 120))
    px(img, 12, 3, c(80, 220, 120))
    return img


add("workshop", workshop())
add("factory", factory())
add("hightech", hightech())


# ---------------------------------------------------------------- facilities
def power_plant():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 0, 13, 15, 22, c(200, 190, 170))
    flat_roof(img, 0, 15, 11, c(120, 120, 130))
    for x in (2, 8):  # cooling towers
        box(img, x, 4, x + 5, 12, c(220, 220, 226))
        hline(img, x + 1, x + 4, 5, c(250, 250, 250))
        hline(img, x + 1, x + 4, 9, c(190, 190, 200))
    smoke(img, 4, 3)
    smoke(img, 10, 2)
    box(img, 6, 16, 9, 19, c(255, 220, 60))
    px(img, 8, 17, INK)
    px(img, 7, 18, INK)
    rect(img, 2, 18, 4, 21, DOOR)
    return img


def water_tower():
    img = new(16, 24)
    shadow(img, 3, 12, 23)
    for x in (4, 11):
        rect(img, x, 12, x, 22, c(120, 120, 130))
    hline(img, 4, 11, 17, c(120, 120, 130))
    box(img, 2, 3, 13, 12, c(90, 160, 230))
    hline(img, 3, 12, 4, c(170, 210, 250))
    hline(img, 3, 12, 11, c(60, 120, 190))
    gable_roof(img, 2, 13, 0, 3, c(80, 100, 140))
    px(img, 7, 7, c(255, 255, 255))
    px(img, 8, 8, c(255, 255, 255))
    px(img, 7, 9, c(255, 255, 255))
    return img


def park():
    img = new(16, 24)
    rect(img, 1, 9, 14, 22, c(126, 206, 96))
    for x in range(1, 15, 2):  # little fence
        px(img, x, 9, c(160, 120, 80))
        px(img, x, 22, c(160, 120, 80))
    # flower beds instead of paths (paths read as roads at this size)
    for (x, y, col) in [(3, 11, c(240, 90, 120)), (4, 12, c(250, 220, 70)), (2, 13, c(250, 250, 250)),
                        (12, 18, c(240, 90, 120)), (13, 19, c(250, 220, 70)), (11, 20, c(250, 250, 250)),
                        (6, 20, c(240, 90, 120)), (8, 14, c(250, 220, 70))]:
        px(img, x, y, col)
    # small pond
    rect(img, 8, 17, 11, 19, WATER)
    hline(img, 9, 10, 16, WATER)
    px(img, 9, 17, WATER_L)
    # one round tree
    for dy in range(-3, 2):
        half = [1, 2, 2, 2, 1][dy + 3]
        hline(img, 11 - half, 11 + half, 6 + dy, c(56, 140, 70))
    hline(img, 10, 12, 3, INK)
    rect(img, 11, 8, 11, 10, c(110, 72, 44))
    # bench
    hline(img, 2, 5, 18, WOOD)
    px(img, 2, 19, WOOD_D)
    px(img, 5, 19, WOOD_D)
    return img


def fountain():
    img = new(16, 24)
    rect(img, 1, 11, 14, 22, c(226, 214, 186))
    box(img, 2, 14, 13, 21, c(190, 190, 200))
    rect(img, 3, 15, 12, 20, WATER)
    hline(img, 4, 8, 16, WATER_L)
    box(img, 6, 9, 9, 17, c(210, 210, 220))
    for (x, y) in [(7, 5), (8, 5), (6, 6), (9, 6), (5, 8), (10, 8), (7, 7), (8, 7)]:
        px(img, x, y, WATER_L)
    return img


def civic(wall, roof, mark, mark_col, flag=None):
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 1, 11, 14, 22, wall)
    flat_roof(img, 1, 14, 9, roof)
    box(img, 5, 5, 10, 10, c(255, 255, 255))
    for (dx, dy) in mark:
        px(img, 6 + dx, 6 + dy, mark_col)
    window(img, 3, 13, 2, 2)
    window(img, 11, 13, 2, 2)
    window(img, 3, 17, 2, 2)
    window(img, 11, 17, 2, 2)
    rect(img, 6, 16, 9, 21, DOOR if flag is None else flag)
    rect(img, 7, 17, 8, 21, GLASS)
    return img


CROSS = [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2)]
STAR = [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1), (0, 3), (3, 3), (1, 2), (2, 2)]
FLAME = [(1, 0), (2, 1), (1, 1), (0, 2), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3)]
BOOK = [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (3, 1), (0, 2), (1, 2), (2, 2), (3, 2)]


def school():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 0, 11, 15, 22, c(244, 226, 190))
    gable_roof(img, 0, 15, 7, 11, c(70, 120, 200))
    box(img, 6, 2, 9, 8, c(244, 226, 190))
    px(img, 7, 4, INK)
    px(img, 8, 4, INK)
    px(img, 8, 5, INK)
    for x in (2, 5, 10, 13):
        window(img, x, 13, 1, 2)
        window(img, x, 17, 1, 2)
    rect(img, 7, 17, 8, 21, DOOR)
    return img


def clock_tower():
    img = new(16, 32)
    shadow(img, 1, 14, 31)
    box(img, 1, 22, 14, 30, c(200, 120, 90))
    box(img, 4, 6, 11, 22, c(214, 136, 100))
    gable_roof(img, 3, 12, 0, 6, c(70, 90, 150))
    box(img, 5, 8, 10, 13, c(255, 252, 236))
    px(img, 7, 9, INK)
    px(img, 7, 10, INK)
    px(img, 8, 11, INK)
    px(img, 9, 11, INK)
    window(img, 6, 16, 3, 3)
    rect(img, 6, 26, 9, 29, DOOR)
    return img


def ferris_wheel():
    img = new(16, 32)
    shadow(img, 1, 14, 31)
    cx, cy, r = 8, 13, 6
    import math
    for a in range(0, 360, 8):
        x = round(cx + r * math.cos(math.radians(a)))
        y = round(cy + r * math.sin(math.radians(a)))
        px(img, x, y, c(120, 120, 140))
    for a in range(0, 360, 45):
        for k in range(1, r):
            px(img, round(cx + k * math.cos(math.radians(a))), round(cy + k * math.sin(math.radians(a))), c(170, 170, 190))
    cols = [c(240, 80, 80), c(250, 200, 60), c(80, 180, 240), c(120, 210, 110), c(230, 120, 220), c(250, 150, 60), c(240, 80, 80), c(80, 180, 240)]
    for i, a in enumerate(range(0, 360, 45)):
        x = round(cx + r * math.cos(math.radians(a)))
        y = round(cy + r * math.sin(math.radians(a)))
        rect(img, x - 1, y, x + 1, y + 1, cols[i])
    for k in range(0, 10):
        px(img, cx - 1 - k // 3, cy + 1 + k, c(110, 110, 130))
        px(img, cx + 1 + k // 3, cy + 1 + k, c(110, 110, 130))
    box(img, 2, 25, 13, 30, c(250, 230, 200))
    hline(img, 3, 12, 26, c(240, 80, 80))
    return img


def stadium():
    img = new(16, 24)
    shadow(img, 0, 15, 23)
    box(img, 0, 8, 15, 22, c(210, 210, 220))
    rect(img, 2, 10, 13, 20, c(90, 180, 80))
    hline(img, 2, 13, 15, c(250, 250, 250))
    rect(img, 7, 10, 8, 20, c(90, 180, 80))
    px(img, 7, 15, c(250, 250, 250))
    for x in range(1, 15, 2):
        px(img, x, 9, c(240, 80, 80))
        px(img, x + 1, 9, c(80, 140, 240))
    for x in (0, 15):
        rect(img, x, 3, x, 8, c(140, 140, 150))
        px(img, x, 2, c(255, 250, 200))
    return img


def scaffold():
    img = new(16, 24)
    shadow(img, 1, 14, 23)
    rect(img, 2, 16, 13, 22, c(200, 180, 150))
    for x in (2, 7, 13):
        rect(img, x, 9, x, 22, c(230, 170, 60))
    for y in (9, 13, 17):
        hline(img, 2, 13, y, c(230, 170, 60))
    for k in range(5):
        px(img, 3 + k, 10 + k, c(200, 140, 40))
    hline(img, 1, 14, 22, c(160, 140, 110))
    return img


def fire_frame(f):
    img = new(16, 24)
    rnd = random.Random(f)
    for _ in range(30):
        x = rnd.randint(3, 12)
        y = rnd.randint(8 + abs(x - 8), 22)
        px(img, x, y, rnd.choice([c(255, 220, 80), c(250, 140, 40), c(230, 70, 40)]))
    return img


add("power", power_plant())
add("water_tower", water_tower())
add("park", park())
add("fountain", fountain())
add("police", civic(c(220, 228, 244), c(60, 90, 170), STAR, c(60, 90, 170)))
add("fire", civic(c(244, 220, 210), c(210, 60, 50), FLAME, c(220, 70, 40), c(200, 60, 50)))
add("hospital", civic(c(250, 250, 250), c(120, 200, 200), CROSS, c(230, 60, 60)))
add("school", school())
add("clock", clock_tower())
add("wheel", ferris_wheel())
add("stadium", stadium())
add("scaffold", scaffold())
add("fire0", fire_frame(1))
add("fire1", fire_frame(2))


# ---------------------------------------------------------------- people, cars, small icons
SHIRTS = [c(230, 80, 80), c(70, 130, 220), c(250, 200, 60), c(110, 190, 100), c(220, 120, 210), c(250, 250, 250)]
HAIR = [c(60, 40, 30), c(30, 30, 40), c(150, 90, 40), c(230, 190, 90)]


def citizen(i, frame):
    img = new(5, 8)
    hair = HAIR[i % len(HAIR)]
    shirt = SHIRTS[i % len(SHIRTS)]
    rect(img, 1, 0, 3, 0, hair)
    rect(img, 1, 1, 3, 2, SKIN)
    px(img, 1, 1, hair)
    rect(img, 0, 3, 4, 5, shirt)
    px(img, 0, 5, SKIN)
    px(img, 4, 5, SKIN)
    legs = c(60, 60, 90)
    if frame == 0:
        px(img, 1, 6, legs)
        px(img, 3, 6, legs)
        px(img, 1, 7, c(40, 30, 30))
        px(img, 3, 7, c(40, 30, 30))
    else:
        px(img, 2, 6, legs)
        px(img, 2, 7, c(40, 30, 30))
    return img


for i in range(6):
    for f in range(2):
        add("cit%d_%d" % (i, f), citizen(i, f))

CARS = [c(230, 70, 70), c(70, 120, 220), c(250, 210, 60), c(250, 250, 250)]


def car(col, vertical):
    img = new(9, 6) if not vertical else new(6, 9)
    if not vertical:
        box(img, 0, 1, 8, 5, col)
        rect(img, 2, 2, 6, 2, GLASS)
        px(img, 1, 5, INK)
        px(img, 7, 5, INK)
        rect(img, 2, 0, 6, 0, INK)
    else:
        box(img, 0, 0, 5, 8, col)
        rect(img, 1, 2, 4, 2, GLASS)
        rect(img, 1, 6, 4, 6, shade(GLASS, 0.85))
    return img


for i, col in enumerate(CARS):
    add("car_h%d" % i, car(col, False))
    add("car_v%d" % i, car(col, True))


def icon(pixels, palette, w=7, h=7):
    img = new(w, h)
    for y, row in enumerate(pixels):
        for x, ch in enumerate(row):
            if ch != ".":
                px(img, x, y, palette[ch])
    return img


add("coin", icon([
    ".kkkkk.",
    "kyyyyyk",
    "kywwyyk",
    "kywyyyk",
    "kyyyyok",
    "kyyyook",
    ".kkkkk."], {"k": c(150, 100, 20), "y": c(255, 210, 60), "w": c(255, 250, 200), "o": c(230, 160, 40)}))
add("icon_power", icon([
    "...kk..",
    "..kyk..",
    ".kyyk..",
    "kyyyyyk",
    "..kyyk.",
    "..kyk..",
    "..kk..."], {"k": INK, "y": c(255, 220, 50)}))
add("icon_water", icon([
    "...k...",
    "..kbk..",
    ".kbbbk.",
    "kbbwbbk",
    "kbbbwbk",
    ".kbbbk.",
    "..kkk.."], {"k": INK, "b": c(80, 160, 240), "w": c(220, 240, 255)}))
add("icon_road", icon([
    ".kkkkk.",
    "krrrrrk",
    "krwwwrk",
    "krrrrrk",
    "krwwwrk",
    "krrrrrk",
    ".kkkkk."], {"k": INK, "r": c(220, 70, 60), "w": c(255, 255, 255)}))
add("lock", icon([
    "..kkk..",
    ".k...k.",
    ".k...k.",
    "kyyyyyk",
    "kyykyyk",
    "kyykyyk",
    "kkkkkkk"], {"k": INK, "y": c(240, 200, 80)}))
add("heart", icon([
    ".kk.kk.",
    "krrkrrk",
    "krrrrrk",
    "krrrrrk",
    ".krrrk.",
    "..krk..",
    "...k..."], {"k": INK, "r": c(240, 80, 110)}))


# 16x16 UI icons for the tool bar
def ui_icon(pixels, palette):
    return icon(pixels, palette, 16, 16)


UIP = {"k": INK, "g": c(120, 200, 90), "G": c(70, 150, 70), "b": c(80, 140, 230), "B": c(50, 100, 190),
       "y": c(250, 200, 60), "Y": c(210, 150, 30), "r": c(220, 70, 60), "w": c(255, 255, 255), "a": ASPHALT,
       "l": LINE, "s": SKIN, "o": c(150, 100, 60), "p": c(200, 120, 220), "c": GLASS, "d": c(160, 160, 170)}
add("ui_road", ui_icon([
    "................",
    "...kaaaaaaaak...",
    "...kaaaaaaaak...",
    "...kaaallaaak...",
    "...kaaallaaak...",
    "...kaaaaaaaak...",
    "...kaaaaaaaak...",
    "...kaaallaaak...",
    "...kaaallaaak...",
    "...kaaaaaaaak...",
    "...kaaaaaaaak...",
    "...kaaallaaak...",
    "...kaaallaaak...",
    "...kaaaaaaaak...",
    "...kaaaaaaaak...",
    "................"], UIP))
add("ui_res", ui_icon([
    "................",
    "......kkkk......",
    ".....kggggk.....",
    "....kggggggk....",
    "...kggggggggk...",
    "..kggggggggggk..",
    ".kkkkkkkkkkkkkk.",
    "..kwwwwwwwwwwk..",
    "..kwccwwwwccwk..",
    "..kwccwwwwccwk..",
    "..kwwwwoowwwwk..",
    "..kwwwwoowwwwk..",
    "..kwwwwoowwwwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "................"], UIP))
add("ui_com", ui_icon([
    "................",
    "..kkkkkkkkkkkk..",
    "..kwwwwwwwwwwk..",
    "..kwbbwbbwbbwk..",
    "..kkkkkkkkkkkk..",
    ".kbwbwbwbwbwbwk.",
    ".kBkBkBkBkBkBkk.",
    "..kwwwwwwwwwwk..",
    "..kccccwwookwk..",
    "..kccccwwookwk..",
    "..kccccwwookwk..",
    "..kwwwwwwookwk..",
    "..kwwwwwwookwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "................"], UIP))
add("ui_ind", ui_icon([
    "............kk..",
    "...........kddk.",
    "............kk..",
    "...........krrk.",
    "...........krrk.",
    ".k...k...k.krrk.",
    ".kk..kk..kkkrrk.",
    ".kyk.kyk.kykrrk.",
    ".kyyykyyykyyyyk.",
    ".kyyyyyyyyyyyyk.",
    ".kyccyyccyyccyk.",
    ".kyccyyccyyccyk.",
    ".kyyyyyyyyyyyyk.",
    ".kyyyyyooyyyyyk.",
    ".kkkkkkkkkkkkkk.",
    "................"], UIP))
add("ui_fac", ui_icon([
    "................",
    ".......kk.......",
    "......kyyk......",
    "......kyyk......",
    "..kkkkkyykkkkk..",
    "..kyyyyyyyyyyk..",
    "...kyyyyyyyyk...",
    "....kyyyyyyk....",
    "....kyyyyyyk....",
    "...kyyykkyyyk...",
    "...kyyk..kyyk...",
    "..kyyk....kyyk..",
    "..kkk......kkk..",
    "................",
    "................",
    "................"], UIP))
add("ui_bulldoze", ui_icon([
    "................",
    "................",
    "....kkkkkk......",
    "....kccccyk.....",
    "....kccccyyk....",
    "..kkkkkkkkkkkk..",
    "..kyyyyyyyyyyk.k",
    "..kyyyyyyyyyyykk",
    "..kkkkkkkkkkkkdk",
    ".kddddddddddkkdk",
    "kdkdkdkdkdkdkdk.",
    ".kddddddddddk...",
    "..kkkkkkkkkk....",
    "................",
    "................",
    "................"], UIP))
add("ui_hand", ui_icon([
    "......kk........",
    ".....ksskkk.....",
    ".....ksskssk....",
    ".....ksskssk.k..",
    ".....ksskssskk..",
    "..kk.ksskssksk..",
    ".kssk.sssssssk..",
    ".kssksssssssssk.",
    "..kssssssssssk..",
    "...ksssssssssk..",
    "...ksssssssssk..",
    "....ksssssssk...",
    ".....kssssssk...",
    ".....kssssssk...",
    "......kkkkkk....",
    "................"], UIP))
add("ui_undo", ui_icon([
    "................",
    "................",
    ".....k..........",
    "....kk..........",
    "...kwkkkkkkk....",
    "..kwwwwwwwwwkk..",
    "...kwkkkkkkkwwk.",
    "....kk......kwk.",
    ".....k.......kwk",
    ".............kwk",
    ".............kwk",
    "............kwk.",
    "......kkkkkkwwk.",
    "......kwwwwwwk..",
    "......kkkkkkk...",
    "................"], UIP))
add("ui_book", ui_icon([
    "................",
    "..kkkkkkkkkkk...",
    "..krrrrrrrrrrk..",
    "..krrwwwwwrrrk..",
    "..krrrrrrrrrrk..",
    "..krrwwwwrrrrk..",
    "..krrrrrrrrrrk..",
    "..krrrrrrrrrrk..",
    "..krrrrryrrrrk..",
    "..krrrryyyrrrk..",
    "..krrrrryrrrrk..",
    "..krrrrrrrrrrk..",
    "..kwwwwwwwwwwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "................"], UIP))
add("ui_menu", ui_icon([
    "................",
    "................",
    "................",
    "..kkkkkkkkkkkk..",
    "..kwwwwwwwwwwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "..kkkkkkkkkkkk..",
    "..kwwwwwwwwwwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "..kkkkkkkkkkkk..",
    "..kwwwwwwwwwwk..",
    "..kkkkkkkkkkkk..",
    "................",
    "................"], UIP))
add("ui_pause", ui_icon([
    "................",
    "................",
    "...kkkk..kkkk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kwwk..kwwk...",
    "...kkkk..kkkk...",
    "................",
    "................"], UIP))


def arrows(n):
    """n white triangles pointing right (pause / play / fast / faster)."""
    img = new(16, 16)
    w = {1: 9, 2: 6, 3: 5}[n]
    x_start = (16 - w * n) // 2
    for i in range(n):
        x0 = x_start + i * w
        for y in range(3, 13):
            span = round((w - 1) * (1 - abs(y - 7.5) / 5.0))
            for x in range(x0, x0 + span + 1):
                px(img, x, y, c(255, 255, 255))
    return img


add("ui_play1", arrows(1))
add("ui_play2", arrows(2))
add("ui_play3", arrows(3))


# ---------------------------------------------------------------- pack
def pack():
    names = sorted(sprites, key=lambda n: (-sprites[n].height, n))
    width = 512
    pad = 2
    x = y = 0
    row_h = 0
    rects = {}
    for n in names:
        im = sprites[n]
        if x + im.width + pad > width:
            x = 0
            y += row_h + pad
            row_h = 0
        rects[n] = [x, y, im.width, im.height]
        x += im.width + pad
        row_h = max(row_h, im.height)
    height = y + row_h
    atlas = Image.new("RGBA", (width, height), T)
    for n, (x, y, w, h) in rects.items():
        atlas.paste(sprites[n], (x, y))
    return atlas, rects


def app_icon():
    """256x256 launcher icon: two buildings and a tree on grass under a blue sky."""
    img = Image.new("RGBA", (32, 32), c(120, 190, 240))
    rect(img, 0, 22, 31, 31, GRASS)
    for x in range(0, 32, 3):
        px(img, x, 23, GRASS_L)
    img.alpha_composite(sprites["apartment"], (1, -2))
    img.alpha_composite(sprites["cafe_2"], (15, 6))
    img.alpha_composite(sprites["tree"], (19, 9))
    for (x, y) in [(5, 3), (6, 3), (7, 2), (8, 3), (26, 4), (27, 3), (28, 4)]:
        px(img, x, y, c(255, 255, 255))
    return img.resize((256, 256), Image.NEAREST)


def main():
    app_icon().save(os.path.join(ROOT, "assets", "sprites", "icon.png"))
    atlas, rects = pack()
    os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
    atlas.save(OUT_PNG)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(rects, f, indent=0, sort_keys=True)
    print("atlas %dx%d, %d sprites" % (atlas.width, atlas.height, len(rects)))
    if "--sheet" in sys.argv:
        out = sys.argv[sys.argv.index("--sheet") + 1]
        big = atlas.resize((atlas.width * 3, atlas.height * 3), Image.NEAREST)
        bg = Image.new("RGBA", big.size, (60, 70, 80, 255))
        bg.alpha_composite(big)
        bg.save(out)


if __name__ == "__main__":
    main()
