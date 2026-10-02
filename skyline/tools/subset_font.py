"""Cuts the game font down to the characters the game actually uses.

The full Korean font is about 12 MB; the game only shows the text written in its scripts plus
numbers, so the web build loads much faster with a subset.

  source  tools/fonts/font_full.ttf
  output  assets/fonts/font.ttf

Characters kept: printable ASCII and every non-ASCII character found in scripts/*.gd.
Run again after adding new text (tools/build_web.sh does it on every build).

Usage: python tools/subset_font.py
"""
import glob
import os

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "tools", "fonts", "font_full.ttf")
OUT = os.path.join(ROOT, "assets", "fonts", "font.ttf")


def main():
    chars = set(chr(c) for c in range(0x20, 0x7F))
    for path in glob.glob(os.path.join(ROOT, "scripts", "*.gd")):
        with open(path, encoding="utf-8") as f:
            chars.update(ch for ch in f.read() if ord(ch) > 0x7E)
    chars.discard("﻿")
    font = TTFont(SRC)
    cmap = font.getBestCmap()
    missing = sorted(ch for ch in chars if ord(ch) not in cmap and not ch.isspace())
    if missing:
        print("not in the font (shown as boxes):", " ".join(missing))
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    sub = subset.Subsetter(options)
    sub.populate(text="".join(chars))
    sub.subset(font)
    font.save(OUT)
    print("font subset: %d characters, %d KB" % (len(chars), os.path.getsize(OUT) // 1024))


if __name__ == "__main__":
    main()
