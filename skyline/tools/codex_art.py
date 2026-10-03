"""Generates the game's isometric pixel-art sprites (Kairosoft-like town view) with the Codex CLI image tool.

Codex paints a big "pixel art" picture; tools/pixelize.py turns it into real low-resolution pixel art
(few colors, hard edges, 1 px outline) at the size the game draws 1:1 and scales by whole numbers.

  raw (big, not in git)   art/raw/<name>.png
  game sprites            assets/sprites/px/<name>.png
      at twice the map's resolution (the game draws them at half size, so at the normal 2x zoom
      every sprite pixel is one screen pixel): buildings 100 px wide (on a 64x32 map tile, drawn
      at 128x64, leaving a yard around them), people and cars 32 px tall, tool icons 52 px

Every image is generated with art/style_ref.png attached so the set stays consistent. The ground
(grass, water, roads, lots) is drawn in code: tools/generate_ground.py.

Usage:
  python tools/codex_art.py --gen house_a cafe          # generate (missing ones only unless --force)
  python tools/codex_art.py --gen all --jobs 6
  python tools/codex_art.py --fit all                   # re-run pixelize on the raw images
"""
import argparse
import concurrent.futures as cf
import os
import subprocess
import sys
import time

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from pixelize import pixelize  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW = os.path.join(ROOT, "art", "raw")
OUT = os.path.join(ROOT, "assets", "sprites", "px")
REF = os.path.join(ROOT, "art", "style_ref.png")

STYLE = ("retro Japanese pocket management sim pixel art (like Kairosoft games): chunky pixel art, every "
         "pixel a clearly visible square, limited palette of bright cheerful colors, bold 1-pixel dark "
         "outline, simple flat shading with light from the top-left")
VIEW = ("View: 2:1 isometric (dimetric) pixel art exactly like Kairosoft town-building games: the object "
        "stands on a square lot seen as a diamond, its left wall and right wall are both visible. Keep it LOW "
        "and compact like those games: one or two stories, flat or gently sloped roof, total height about "
        "the same as its width (only towers and ferris wheels may be taller); the base is a clean diamond")
RULES = ("One object, centered, filling the image width. Fully TRANSPARENT background with a real alpha "
         "channel; no ground tile, no grass base, no cast shadow, no text, no letters, no words on signs "
         "(use small pictures), no logos")

# name: (kind, subject). kinds and their pixel size are in SIZE.
ASSETS = {
    # residential
    "house_a": ("building", "a small cozy family house with a red roof, cream walls, a door and windows with flower boxes"),
    "house_b": ("building", "a small cozy family house with a blue roof, white walls and a little porch"),
    "house_c": ("building", "a small cozy cottage with a green roof, beige walls and a tiny garden fence"),
    "rowhouse": ("building", "a two-story townhouse with an orange roof, pink walls and small balconies"),
    "rowhouse_b": ("building", "a two-story townhouse with a navy blue roof, mint green walls and small balconies"),
    "apartment": ("building", "a tall six-story modern apartment block, gray and white walls, many windows and balconies, rooftop water tank; much taller than wide"),
    "apartment_b": ("building", "a tall six-story apartment block with warm beige brick walls, many windows with plants, red roof edge; much taller than wide"),
    # commercial
    "bakery": ("building", "a small bakery shop with an orange and white striped awning, display window with bread, a bread picture sign"),
    "bakery_2": ("building", "a two-story bakery with an orange and white awning and a cake picture sign on the roof edge"),
    "cafe": ("building", "a small cafe with a brown striped awning, big windows and a tiny outdoor table"),
    "cafe_2": ("building", "a two-story cafe with a rooftop terrace with umbrellas and a coffee cup picture sign"),
    "restaurant": ("building", "a small family restaurant with a red awning and red paper lanterns"),
    "restaurant_2": ("building", "a two-story restaurant with a red roof, lanterns and warm lit windows"),
    "clothes": ("building", "a small clothing boutique with a pink awning and mannequins in the window"),
    "clothes_2": ("building", "a two-story fashion store with a pink and white facade and big windows with mannequins"),
    "books": ("building", "a small bookstore with a blue awning and colorful books in the window"),
    "books_2": ("building", "a two-story bookstore with a blue and mint facade and a reading room upstairs"),
    "flowers": ("building", "a small flower shop with a green awning and many flower pots in front"),
    "flowers_2": ("building", "a two-story flower shop with a glass greenhouse upper floor full of plants"),
    "dept": ("building", "a big four-story department store with a red sign band on top and large glass windows; taller than wide"),
    "dept_b": ("building", "a big four-story shopping mall with a blue roof band and a glass facade; taller than wide"),
    # industrial
    "workshop": ("building", "a small industrial workshop: gray concrete walls, flat corrugated metal roof, a yellow roller shutter door, wooden crates"),
    "factory": ("building", "a factory: gray concrete hall with a blue sawtooth metal roof and a red-and-white striped smokestack with smoke"),
    "hightech": ("building", "a modern high-tech lab factory with blue glass panels, white walls and solar panels on the roof"),
    # facilities
    "power": ("building", "a small power plant with two white cooling towers with steam and a brick hall"),
    "water_tower": ("building", "a LOW water facility: a wide round blue water tank sitting on a short concrete base next to a small pump house with pipes and a water drop picture; no tall legs, as low as a one-story house"),
    "park": ("building", "a small square park plot: lawn, one round tree, flower beds, a bench and a tiny pond, low hedge around"),
    "tree": ("building", "two round leafy green trees"),
    "forest": ("building", "a cluster of three dense dark green trees, pines and round trees mixed"),
    "fountain": ("building", "a small plaza with a round stone fountain spraying water and paving stones"),
    "police": ("building", "a small police station: white and navy walls, flat roof, a blue star badge over the door, a police car in front"),
    "fire": ("building", "a small fire station: red brick, flat roof, a hose tower, a garage with a red fire truck"),
    "hospital": ("building", "a small hospital: white three-story building, flat roof, a big red cross on the front"),
    "school": ("building", "a small elementary school: cream two-story building with a clock tower in the middle and a flag pole"),
    "clock": ("building", "a tall brick clock tower landmark with a big white clock face and a pointed blue roof; much taller than wide"),
    "wheel": ("building", "a colorful ferris wheel landmark with rainbow cabins on a white frame and a ticket booth; taller than wide"),
    "stadium": ("building", "a small sports stadium landmark with red and blue stands, a green field and floodlight towers"),
    # construction sites
    "scaffold_r": ("building", "a house under construction: wooden timber frame, roof rafters, stacked roof tiles and orange traffic cones"),
    "scaffold_c": ("building", "a shop under construction: steel frame with a few glass panels, scaffolding and orange traffic cones"),
    "scaffold_i": ("building", "a factory under construction: gray steel beams, a small yellow crane and orange traffic cones"),
    # people and cars
    "cit0": ("person", "one tiny chibi townsperson standing, red shirt, brown hair"),
    "cit1": ("person", "one tiny chibi townsperson standing, blue shirt, black hair"),
    "cit2": ("person", "one tiny chibi townsperson standing, yellow dress, blond hair"),
    "cit3": ("person", "one tiny chibi townsperson standing, green hoodie, short black hair"),
    "cit4": ("person", "one tiny chibi elderly townsperson standing, purple cardigan, gray hair"),
    "cit5": ("person", "one tiny chibi child standing, white t-shirt, orange cap"),
    "car_front": ("car", "one small cute red compact car driving toward the viewer and to the right (front and right side visible)"),
    "car_back": ("car", "one small cute red compact car driving away from the viewer and to the left (back and left side visible)"),
    # tool bar icons and markers
    "ui_road": ("icon", "a game icon: a short piece of gray asphalt road with a dashed yellow line, isometric"),
    "ui_res": ("icon", "a game icon: a cute small house with a green roof"),
    "ui_com": ("icon", "a game icon: a cute small shop with a blue striped awning"),
    "ui_ind": ("icon", "a game icon: a cute small yellow factory with a chimney"),
    "ui_fac": ("icon", "a game icon: a golden star"),
    "ui_bulldoze": ("icon", "a game icon: a cute small yellow bulldozer"),
    "ui_hand": ("icon", "a game icon: a cartoon pointing hand cursor"),
    "coin": ("tiny", "a game icon: a shiny gold coin"),
    "advisor": ("portrait", "a bust portrait of a cheerful chibi town secretary girl with brown hair and a green ribbon, smiling, facing the viewer, inside a small square frame"),
    "ui_menu": ("icon", "a game icon: a small notebook with a pencil"),
    "ui_speed": ("icon", "a game icon: a small round clock"),
    "warn_road": ("marker", "a game alert marker: a round white speech bubble with a thick dark outline and a tail pointing down; inside it a gray road piece broken in the middle with a bold red X"),
    "warn_power": ("marker", "a game alert marker: a round white speech bubble with a thick dark outline and a tail pointing down; inside it a bold yellow lightning bolt with a red slash"),
    "warn_water": ("marker", "a game alert marker: a round white speech bubble with a thick dark outline and a tail pointing down; inside it a bold blue water drop with a red slash"),
}

# kind -> (width, height) in game pixels; one of them 0 = keep the object's shape
SIZE = {"building": (100, 0), "person": (0, 32), "car": (44, 0), "icon": (52, 0), "tiny": (24, 0), "marker": (32, 0), "portrait": (64, 0)}
COLORS = {"building": 40, "person": 20, "car": 20, "icon": 28, "tiny": 12, "marker": 16, "portrait": 28}


def prompt_for(name):
    kind, subject = ASSETS[name]
    ref = (" Match the art style, pixel size, outline, palette and level of detail of the attached reference "
           "image exactly." if os.path.exists(REF) else "")
    target = os.path.join(RAW, name + ".png")
    view = VIEW + ". " if kind in ("building", "car") else ""
    body = f"Create ONE image. Subject: {subject}. Style: {STYLE}. {view}{RULES}.{ref}"
    return (f"Use your built-in image generation tool. {body} Then copy the generated PNG file to {target} "
            f"(overwrite). Do not change any other file. Reply with only the saved path.")


def generate(name):
    os.makedirs(RAW, exist_ok=True)
    cmd = ["codex", "exec", "--skip-git-repo-check", "-s", "workspace-write", "-C", RAW]
    if os.path.exists(REF):
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
    src = os.path.join(RAW, name + ".png")
    if not os.path.exists(src):
        return False
    kind = ASSETS[name][0]
    w, h = SIZE[kind]
    os.makedirs(OUT, exist_ok=True)
    pixelize(Image.open(src), width=w, colors=COLORS[kind], height=h).save(os.path.join(OUT, name + ".png"))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gen", nargs="*", default=None)
    ap.add_argument("--fit", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--jobs", type=int, default=5)
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
