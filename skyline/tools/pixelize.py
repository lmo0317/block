"""Turns a big painted "pixel art" image into real low-resolution pixel art.

Steps: crop to the object (alpha), cut the palette down to a few colors on the big image, then pick the
most common color in each block (no blending, so every output pixel is a clean color), make the alpha
hard, and add a 1 px dark outline around the silhouette like hand-made game sprites.

  python tools/pixelize.py in.png out.png --width 48 [--colors 24] [--outline]
"""
import argparse

import numpy as np
from PIL import Image

OUTLINE = (40, 30, 46, 255)


def pixelize(im, width=0, colors=24, outline=True, alpha_cut=110, height=0):
    """Give width, or height (then the width follows the object's shape)."""
    im = im.convert("RGBA")
    a = np.array(im)
    alpha = a[..., 3]
    ys, xs = np.nonzero(alpha >= alpha_cut)
    if len(xs) == 0:
        return im.resize((width, width))
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    w, h = im.size
    if height and not width:
        width = max(1, round(w * height / h))
    height = max(1, round(h * width / w))
    # palette from the opaque pixels of the big image
    rgb = im.convert("RGB")
    pal_img = rgb.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
    idx = np.array(pal_img)
    palette = np.array(pal_img.getpalette()[: colors * 3]).reshape(-1, 3)
    alpha = np.array(im)[..., 3]
    out = np.zeros((height, width, 4), np.uint8)
    for ty in range(height):
        y0, y1 = int(ty * h / height), max(int(ty * h / height) + 1, int((ty + 1) * h / height))
        for tx in range(width):
            x0, x1 = int(tx * w / width), max(int(tx * w / width) + 1, int((tx + 1) * w / width))
            # shrink the block a little so edges of neighbour pixels do not vote
            my, mx = (y1 - y0) // 5, (x1 - x0) // 5
            blk_a = alpha[y0 + my:y1 - my or y1, x0 + mx:x1 - mx or x1]
            if blk_a.size == 0 or (blk_a >= alpha_cut).mean() < 0.5:
                continue
            blk = idx[y0 + my:y1 - my or y1, x0 + mx:x1 - mx or x1][blk_a >= alpha_cut]
            c = np.bincount(blk.ravel(), minlength=len(palette)).argmax()
            out[ty, tx, :3] = palette[c]
            out[ty, tx, 3] = 255
    if outline:
        # pad by one pixel so the outline also goes around the image border, then ring the silhouette
        padded = np.zeros((height + 2, width + 2, 4), np.uint8)
        padded[1:-1, 1:-1] = out
        s = padded[..., 3] > 0
        g = s.copy()
        g[1:, :] |= s[:-1, :]
        g[:-1, :] |= s[1:, :]
        g[:, 1:] |= s[:, :-1]
        g[:, :-1] |= s[:, 1:]
        padded[g & ~s] = OUTLINE
        out = padded
    return Image.fromarray(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--width", type=int, default=0)
    ap.add_argument("--height", type=int, default=0)
    ap.add_argument("--colors", type=int, default=24)
    ap.add_argument("--no-outline", action="store_true")
    a = ap.parse_args()
    pixelize(Image.open(a.src), a.width or (0 if a.height else 48), a.colors, not a.no_outline, height=a.height).save(a.out)


if __name__ == "__main__":
    main()
