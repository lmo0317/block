"""Generates the game's painted pixel-art sprites with the Codex CLI image tool, then fits them for the game.

  raw (big, not in git)   art/raw/<name>.png
  game sprites            assets/sprites/hd/<name>.png   (sprites: 96 px wide, alpha-cropped;
                                                          textures: 64x64 seamless; small: own size)

Every sprite after the first style pass is generated with art/style_ref.png attached so the set stays
consistent. Prompts live in ASSETS below; the art guide (docs/ART_GUIDE.md) lists them too.

Usage:
  python tools/codex_art.py --gen house_a cafe          # generate (missing ones only unless --force)
  python tools/codex_art.py --gen all --jobs 5
  python tools/codex_art.py --fit all                   # re-fit raw images into assets/sprites/hd
"""
import argparse
import concurrent.futures as cf
import os
import subprocess
import sys
import time

from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW = os.path.join(ROOT, "art", "raw")
OUT = os.path.join(ROOT, "assets", "sprites", "hd")
REF = os.path.join(ROOT, "art", "style_ref.png")

STYLE = ("detailed cozy pixel art for a mobile city-builder management game (like Japanese pocket "
         "management sims), crisp visible pixels, 1-pixel dark outline, warm cheerful colors, soft light "
         "from the top-left")
VIEW = ("View: straight front elevation seen from slightly above (about 30 degrees down), the front wall "
        "faces the viewer squarely and the roof top is visible; NOT isometric, NOT rotated, no side wall "
        "visible, symmetric framing")
SPRITE_RULES = ("The object fills the image width, centered, standing on the bottom edge. Fully TRANSPARENT "
                "background with a real alpha channel; no ground, no grass base, no cast shadow, no text, no "
                "letters, no words on signs (use small pictures instead), no logos")

# name: (kind, subject). kind: sprite | texture | small
ASSETS = {
    # residential
    "house_a": ("sprite", "a small cozy one-story family house with a red tiled gable roof, cream walls, a wooden door, two windows with flower boxes and a chimney"),
    "house_b": ("sprite", "a small cozy one-story family house with a blue tiled gable roof, white walls, a round window above the door and a small porch"),
    "house_c": ("sprite", "a small cozy one-story cottage with a green roof, beige walls, a wooden door and a small window box garden"),
    "rowhouse": ("sprite", "a two-story townhouse row (three narrow attached homes side by side) with an orange roof, pink walls and balconies"),
    "rowhouse_b": ("sprite", "a two-story townhouse row (three narrow attached homes side by side) with a dark blue roof, mint green walls and small balconies"),
    "apartment": ("sprite", "a tall modern six-story apartment block, gray and white facade, many windows, small balconies, rooftop water tank; the building is about twice as tall as it is wide"),
    "apartment_b": ("sprite", "a tall six-story apartment block with warm beige brick facade, red roof edge, many windows with plants; the building is about twice as tall as it is wide"),
    # commercial, level 1 (small shop) and level 2 (two-story shop)
    "bakery": ("sprite", "a small one-story bakery shop with an orange and white striped awning, big display window with bread loaves, a bread picture on the sign"),
    "bakery_2": ("sprite", "a two-story bakery with living rooms upstairs, orange and white striped awning, display window full of bread and cakes, a bread picture on the sign"),
    "cafe": ("sprite", "a small one-story coffee shop with a brown awning, outdoor table with two chairs, big window, a coffee cup picture on the sign"),
    "cafe_2": ("sprite", "a two-story cafe with a terrace on the second floor, brown and cream colors, big windows, a coffee cup picture on the sign"),
    "restaurant": ("sprite", "a small one-story family restaurant with a red awning and lanterns, warm lit windows, a bowl picture on the sign"),
    "restaurant_2": ("sprite", "a two-story restaurant with a red roof, lanterns, warm lit windows on both floors, a bowl picture on the sign"),
    "clothes": ("sprite", "a small one-story clothing boutique with a pink awning, mannequins in the window, a dress picture on the sign"),
    "clothes_2": ("sprite", "a two-story fashion store with pink and white facade, mannequins in big windows, a dress picture on the sign"),
    "books": ("sprite", "a small one-story bookstore with a blue awning, shelves of colorful books in the window, a book picture on the sign"),
    "books_2": ("sprite", "a two-story bookstore with a reading room upstairs, blue and mint facade, book shelves in the windows, a book picture on the sign"),
    "flowers": ("sprite", "a small one-story flower shop with a green awning and many flower pots and buckets in front, a flower picture on the sign"),
    "flowers_2": ("sprite", "a two-story flower shop with a greenhouse-like glass upper floor, flower pots everywhere, a flower picture on the sign"),
    "dept": ("sprite", "a big four-story department store with a red roof sign band, large glass windows on every floor, entrance with a red and white awning; taller than wide"),
    "dept_b": ("sprite", "a big four-story shopping mall building with a blue roof band, glass facade, entrance canopy; taller than wide"),
    # industrial
    "workshop": ("sprite", "an industrial craft workshop, NOT a house: gray concrete block walls, a flat corrugated metal roof (no tiles), a wide yellow roller shutter door, stacked wooden crates and a forklift pallet in front, a thin metal chimney with smoke"),
    "factory": ("sprite", "an industrial factory, NOT a house: long gray concrete hall with a blue sawtooth corrugated metal roof with skylights (no roof tiles), a tall red-and-white striped smokestack with smoke, big loading dock door, pipes on the wall"),
    "hightech": ("sprite", "a modern high-tech factory and lab with blue glass panels, white walls, solar panels on the roof and a small antenna"),
    # facilities
    "power": ("sprite", "a small power plant with two white cooling towers with steam, a brick turbine hall and a yellow lightning bolt picture on the wall"),
    "water_tower": ("sprite", "a blue water tower tank on four steel legs with a small ladder and a water drop picture on the tank; taller than wide"),
    "park": ("sprite", "a small square park seen from above at an angle: lawn, one round tree, flower beds, a wooden bench and a small pond, low hedge border"),
    "tree": ("sprite", "two round leafy green trees standing together"),
    "forest": ("sprite", "a cluster of three dense dark green forest trees, pines and round trees mixed"),
    "fountain": ("sprite", "a small town plaza fountain with a stone basin and water spraying up, paving stones around it"),
    "police": ("sprite", "a modern police station, NOT a cottage: two-story white and navy blue building with a FLAT roof, a big blue star badge emblem above the glass entrance, a blue and red light on the roof, a small police car parked in front"),
    "fire": ("sprite", "a fire station, NOT a cottage: red brick two-story building with a FLAT roof and a square hose-drying tower, two large open garage doors with red fire trucks inside, a flame emblem above the doors"),
    "hospital": ("sprite", "a modern hospital, NOT a cottage: white three-story building with a FLAT roof, big red cross emblem on the facade, green-tinted windows, a glass entrance canopy and a small ambulance in front"),
    "school": ("sprite", "an elementary school, NOT a cottage: long two-story cream building with a FLAT roof edge, a central clock tower with a bell, rows of big windows, a flag pole and a small playground slide in front"),
    "clock": ("sprite", "a tall brick clock tower landmark with a big round white clock face and a pointed blue roof; about twice as tall as wide"),
    "wheel": ("sprite", "a colorful amusement park ferris wheel landmark with small cabins in rainbow colors on a white frame and a ticket booth at the bottom; taller than wide"),
    "stadium": ("sprite", "a small sports stadium landmark with stands, red and blue seats, floodlight towers at the corners and green field inside"),
    # construction sites
    "scaffold_r": ("sprite", "a house under construction: wooden timber frame of a small house, half-built roof rafters, a stack of red roof tiles and bricks, orange traffic cones"),
    "scaffold_c": ("sprite", "a shop under construction: steel frame with some glass panels installed, scaffolding, a blank blue banner board, orange traffic cones"),
    "scaffold_i": ("sprite", "a factory under construction: gray steel beams, a small yellow tower crane lifting a beam, gravel, orange traffic cones"),
    # people and cars (small)
    "cit0": ("small", "one tiny chibi townsperson standing, front view, red shirt, brown hair"),
    "cit1": ("small", "one tiny chibi townsperson standing, front view, blue shirt, black hair"),
    "cit2": ("small", "one tiny chibi townsperson standing, front view, yellow dress, blond hair"),
    "cit3": ("small", "one tiny chibi townsperson standing, front view, green hoodie, short black hair"),
    "cit4": ("small", "one tiny chibi townsperson standing, front view, purple shirt, gray hair, elderly"),
    "cit5": ("small", "one tiny chibi child standing, front view, white t-shirt, orange cap"),
    "car_h": ("small", "one small cute red compact car seen exactly from the side, facing right"),
    "car_v": ("small", "one small cute red compact car seen from behind and slightly above, facing away from the viewer"),
    # tool bar icons
    "ui_road": ("small", "a game UI icon: a square tile of gray asphalt road seen from above with a dashed yellow center line and light sidewalks on both sides, filling the square"),
    "ui_res": ("small", "a game UI icon: a cute small house with a green roof"),
    "ui_com": ("small", "a game UI icon: a cute small shop with a blue striped awning"),
    "ui_ind": ("small", "a game UI icon: a cute small yellow factory with a chimney"),
    "ui_fac": ("small", "a game UI icon: a golden star badge"),
    "ui_bulldoze": ("small", "a game UI icon: a cute small yellow bulldozer, side view"),
    "ui_hand": ("small", "a game UI icon: a cartoon pointing hand cursor"),
    "coin": ("small", "a game UI icon: a shiny gold coin, front view"),
    # warning bubbles shown over lots and buildings
    "warn_road": ("small", "a game UI alert marker: a round white speech bubble with a thick dark outline and a small tail pointing down; inside it a short gray road piece broken in the middle with a bold red X over the gap"),
    "warn_power": ("small", "a game UI alert marker: a round white speech bubble with a thick dark outline and a small tail pointing down; inside it a bold yellow lightning bolt with a red slash through it"),
    "warn_water": ("small", "a game UI alert marker: a round white speech bubble with a thick dark outline and a small tail pointing down; inside it a bold blue water drop with a red slash through it"),
    # ground textures (opaque, seamless)
    "tex_grass": ("texture", "short green grass lawn with a few tiny flowers"),
    "tex_water": ("texture", "calm blue water with small light ripples"),
    "tex_asphalt": ("texture", "dark gray asphalt road surface with fine grain"),
}

SIZE = {"sprite": 96, "small": 40, "texture": 64}


def prompt_for(name):
    kind, subject = ASSETS[name]
    ref = (" Match the art style, pixel size, outline, palette and level of detail of the attached reference "
           "image exactly." if os.path.exists(REF) else "")
    target = os.path.join(RAW, name + ".png")
    if kind == "texture":
        body = (f"Create ONE square image: a seamless tileable texture of {subject}, seen straight from above, "
                f"{STYLE}. It must fill the whole square edge to edge and tile without visible seams; no objects, "
                f"no border, no text.{ref}")
    else:
        body = f"Create ONE image. Subject: {subject}. Style: {STYLE}. "
        if kind == "sprite":
            body += VIEW + ". "
        body += SPRITE_RULES + "." + ref
    return (f"Use your built-in image generation tool. {body} Then copy the generated PNG file to {target} "
            f"(overwrite). Do not change any other file. Reply with only the saved path.")


def generate(name):
    os.makedirs(RAW, exist_ok=True)
    work = os.path.join(RAW, "_work")
    os.makedirs(work, exist_ok=True)
    cmd = ["codex", "exec", "--skip-git-repo-check", "-s", "workspace-write", "-C", RAW]
    if os.path.exists(REF) and ASSETS[name][0] != "texture":
        cmd += ["-i", REF]
    cmd += ["--", prompt_for(name)]   # "--" ends the multi-value -i list
    target = os.path.join(RAW, name + ".png")
    before = os.path.getmtime(target) if os.path.exists(target) else 0
    t0 = time.time()
    res = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, encoding="utf-8",
                         errors="replace", timeout=900, shell=(os.name == "nt"))
    ok = os.path.exists(target) and os.path.getmtime(target) > before
    return name, ok, int(time.time() - t0), (res.stdout or "")[-300:] + (res.stderr or "")[-300:]


def fit(name):
    """Raw generation -> game sprite."""
    kind = ASSETS[name][0]
    src = os.path.join(RAW, name + ".png")
    if not os.path.exists(src):
        return False
    im = Image.open(src).convert("RGBA")
    os.makedirs(OUT, exist_ok=True)
    if kind == "texture":
        side = min(im.size)
        im = im.crop(((im.width - side) // 2, (im.height - side) // 2, (im.width + side) // 2, (im.height + side) // 2))
        im = im.resize((SIZE[kind], SIZE[kind]), Image.LANCZOS).convert("RGB")
        im = make_seamless(im)
        im.save(os.path.join(OUT, name + ".png"))
        return True
    # remove faint halo pixels, crop to the object
    alpha = im.getchannel("A").point(lambda a: 0 if a < 24 else a)
    im.putalpha(alpha)
    box = alpha.getbbox()
    if box:
        im = im.crop(box)
    w = SIZE[kind]
    h = max(1, round(im.height * w / im.width))
    if kind == "small":   # small things: fit inside a square
        k = w / max(im.width, im.height)
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    else:
        im = im.resize((w, h), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.6, percent=60, threshold=2))
    im.save(os.path.join(OUT, name + ".png"))
    return True


def make_seamless(im):
    """Blend each edge with the opposite one so the texture tiles."""
    import numpy as np
    w, h = im.size
    shifted = Image.fromarray(np.roll(np.array(im), (h // 2, w // 2), (0, 1)))
    mask = Image.new("L", im.size, 0)
    px = mask.load()
    for y in range(h):
        for x in range(w):
            d = min(x, w - 1 - x, y, h - 1 - y)
            px[x, y] = max(0, 255 - d * 255 // (w // 4))
    return Image.composite(shifted, im, mask)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gen", nargs="*", default=None)
    ap.add_argument("--fit", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--jobs", type=int, default=4)
    a = ap.parse_args()

    if a.gen is not None:
        names = list(ASSETS) if a.gen in ([], ["all"]) else a.gen
        if not a.force:
            names = [n for n in names if not os.path.exists(os.path.join(RAW, n + ".png"))]
        print(f"generating {len(names)}: {' '.join(names)}", flush=True)
        failed = []
        with cf.ThreadPoolExecutor(max_workers=a.jobs) as ex:
            for name, ok, secs, tail in ex.map(generate, names):
                print(f"{'ok  ' if ok else 'FAIL'} {name} {secs}s" + ("" if ok else "\n" + tail), flush=True)
                if ok:
                    fit(name)
                else:
                    failed.append(name)
        if failed:
            print("failed:", " ".join(failed))
    if a.fit is not None:
        names = list(ASSETS) if a.fit in ([], ["all"]) else a.fit
        for n in names:
            print(("fit " if fit(n) else "no raw ") + n)


if __name__ == "__main__":
    sys.exit(main())
