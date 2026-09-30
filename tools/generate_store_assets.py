"""Logo, app icon and store listing images.

- assets/sprites/logo.png            512x512 logo on transparent background (home screen)
- assets/sprites/icon.png            256x256 app icon (Android launcher, web favicon)
- assets/sprites/icon_foreground.png / icon_background.png  432x432 Android adaptive icon layers
- store/onestore/icon_512.png        512x512 store icon
- store/onestore/feature_1024x578.png top banner image
- store/onestore/screenshot_*.png    copied from 720x1280 captures passed on the command line

- store/toss/                        Apps in Toss: logo 600, thumbnail 1932x828, screenshots 636x1048

Usage: python tools/generate_store_assets.py [capture.png ...]
       python tools/generate_store_assets.py --toss <folder with toss_<screen>.png captures>
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "store", "onestore")
FONT = os.path.join(ROOT, "assets", "fonts", "font.ttf")
BG = (16, 22, 36, 255)

# Reuse the block renderer and palette without running that script's sprite generation
_src = open(os.path.join(ROOT, "tools", "generate_faceted_assets.py"), encoding="utf-8").read()
_ns = {"__file__": os.path.join(ROOT, "tools", "generate_faceted_assets.py")}
exec(_src[:_src.index("for name, cols in PALETTE.items():")], _ns)
render_block = _ns["render_faceted_block_clean"]
PALETTE = _ns["PALETTE"]


def block(color, size):
    c = PALETTE[color]
    return render_block(c["base"], c["top"], c["left"], c["right"], c["bottom"], c["outline"], size=size)


def logo(size=512):
    """A 3x3 board with a corner-shaped hole and the matching piece about to drop into it.
    Dropping it in would clear the top row and the right column at once."""
    s = size * 2
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    cell, gap = int(s * 0.225), int(s * 0.018)
    lift = int(cell * 0.62)
    x0 = (s - (cell * 3 + gap * 2)) // 2
    y0 = (s - (cell * 3 + gap * 2) + lift) // 2
    pos = lambda cx, cy: (x0 + cx * (cell + gap), y0 + cy * (cell + gap))
    filled = {(0, 0): "blue", (0, 1): "purple", (1, 1): "purple", (0, 2): "green", (1, 2): "green", (2, 2): "cyan"}
    hole = [(1, 0), (2, 0), (2, 1)]
    r = int(cell * 0.08)
    d = ImageDraw.Draw(img)
    for c in hole:
        x, y = pos(*c)
        d.rounded_rectangle([x, y, x + cell, y + cell], radius=r, fill=(30, 38, 62, 255), outline=(62, 76, 112, 255), width=max(2, s // 150))
    for c, color in filled.items():
        b = block(color, cell)
        img.paste(b, pos(*c), b)
    # Warm glow around the hovering piece
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for c in hole:
        x, y = pos(*c)
        gd.rounded_rectangle([x - 6, y - lift - 6, x + cell + 6, y - lift + cell + 6], radius=r, fill=(255, 150, 30, 150))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(s * 0.025)))
    for c in hole:
        x, y = pos(*c)
        b = block("orange", cell)
        img.paste(b, (x, y - lift), b)
    return img.resize((size, size), Image.Resampling.LANCZOS)


def icon(size=512):
    img = Image.new("RGBA", (size, size), BG)
    lg = logo(int(size * 0.86))
    off = (size - lg.width) // 2
    img.paste(lg, (off, off + int(size * 0.03)), lg)
    return img


def feature(screenshot_path):
    w, h = 1024, 578
    img = Image.new("RGBA", (w, h), BG)
    d = ImageDraw.Draw(img)
    # Soft glow behind the title side
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(260, 0, -20):
        a = int(26 * (1 - r / 260))
        gd.ellipse([250 - r, 290 - r, 250 + r, 290 + r], fill=(59, 130, 246, a))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)

    lg = logo(170)
    img.paste(lg, (70, 62), lg)
    title = ImageFont.truetype(FONT, 92)
    sub = ImageFont.truetype(FONT, 30)
    small = ImageFont.truetype(FONT, 24)
    d.text((86, 250), "퍼즐블록", font=title, fill=(240, 244, 255))
    d.text((90, 370), "빈자리에 딱 맞게 넣고", font=sub, fill=(200, 210, 230))
    d.text((90, 412), "두 줄을 한 번에 터뜨려요!", font=sub, fill=(255, 196, 0))
    d.text((90, 480), "8×8 블록 퍼즐 · 콤보 피버 · 어드벤처 20단계", font=small, fill=(140, 150, 175))

    # Game screen on the right, framed like a phone
    shot = Image.open(screenshot_path).convert("RGBA")
    sh = 520
    sw = int(shot.width * sh / shot.height)
    shot = shot.resize((sw, sh), Image.Resampling.LANCZOS)
    x0, y0 = w - sw - 90, (h - sh) // 2
    frame = Image.new("RGBA", (sw + 16, sh + 16), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, sw + 15, sh + 15], radius=26, fill=(44, 52, 78, 255))
    img.paste(frame, (x0 - 8, y0 - 8), frame)
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=20, fill=255)
    img.paste(shot, (x0, y0), mask)
    return img.convert("RGB")


def phone(shot_path, height):
    """A screen capture in a rounded frame, scaled to the given height."""
    shot = Image.open(shot_path).convert("RGBA")
    sw = int(shot.width * height / shot.height)
    shot = shot.resize((sw, height), Image.Resampling.LANCZOS)
    pad = max(8, height // 60)
    img = Image.new("RGBA", (sw + pad * 2, height + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, sw + pad * 2 - 1, height + pad * 2 - 1], radius=pad * 3, fill=(44, 52, 78, 255))
    mask = Image.new("L", (sw, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, height - 1], radius=pad * 2, fill=255)
    img.paste(shot, (pad, pad), mask)
    return img


# Apps in Toss store screenshots: (capture, caption)
TOSS_SHOTS = [
    ("play", "블록 3개를 놓아 줄을 채워요"),
    ("combo", "딱 맞으면 줄이 한 번에 펑!"),
    ("combo2", "5콤보부터 피버, 점수 1.5배"),
    ("stage", "목표가 있는 어드벤처 20단계"),
    ("home", "오늘의 챌린지와 토스 랭킹"),
]


def toss_assets(capture_dir):
    out = os.path.join(ROOT, "store", "toss")
    os.makedirs(out, exist_ok=True)
    # Logo: square, solid background, no rounded corners (Toss rule); the dark icon suits both themes
    logo_img = icon(600).convert("RGB")
    logo_img.save(os.path.join(out, "logo_600.png"))
    logo_img.save(os.path.join(out, "logo_dark_600.png"))

    shot = lambda name: os.path.join(capture_dir, f"toss_{name}.png")
    # Thumbnail: title on the left, two real play screens on the right
    w, h = 1932, 828
    img = Image.new("RGBA", (w, h), BG)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(520, 0, -30):
        gd.ellipse([430 - r, 414 - r, 430 + r, 414 + r], fill=(59, 130, 246, int(22 * (1 - r / 520))))
    img = Image.alpha_composite(img, glow)
    lg = logo(300)
    img.paste(lg, (130, 60), lg)
    d = ImageDraw.Draw(img)
    d.text((126, 380), "퍼즐블록", font=ImageFont.truetype(FONT, 150), fill=(240, 244, 255))
    d.text((134, 580), "빈자리에 딱 맞게 넣고", font=ImageFont.truetype(FONT, 50), fill=(200, 210, 230))
    d.text((134, 650), "두 줄을 한 번에 터뜨려요!", font=ImageFont.truetype(FONT, 50), fill=(255, 196, 0))
    for i, name in enumerate(["combo", "combo2"]):
        ph = phone(shot(name), 700)
        img.paste(ph, (1010 + i * (ph.width + 50), (h - ph.height) // 2), ph)
    img.convert("RGB").save(os.path.join(out, "thumbnail_1932x828.png"), optimize=True)

    # Screenshots: caption on top, the screen below
    sw, sh = 636, 1048
    cap_font = ImageFont.truetype(FONT, 40)
    for i, (name, caption) in enumerate(TOSS_SHOTS, 1):
        page = Image.new("RGBA", (sw, sh), BG)
        dd = ImageDraw.Draw(page)
        tw = dd.textlength(caption, font=cap_font)
        dd.text(((sw - tw) / 2, 44), caption, font=cap_font, fill=(240, 244, 255))
        ph = phone(shot(name), sh - 150)
        page.paste(ph, ((sw - ph.width) // 2, 128), ph)
        page.convert("RGB").save(os.path.join(out, f"screenshot_{i}.png"), optimize=True)
    for f in sorted(os.listdir(out)):
        print(f, Image.open(os.path.join(out, f)).size)


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--toss":
        toss_assets(sys.argv[2])
        return
    os.makedirs(OUT, exist_ok=True)
    sprites = os.path.join(ROOT, "assets", "sprites")
    logo(512).save(os.path.join(sprites, "logo.png"))
    icon(256).save(os.path.join(sprites, "icon.png"))
    # Adaptive icons are masked to the middle ~66%, so the logo sits inside that safe zone
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    lg = logo(232)
    fg.paste(lg, (100, 100), lg)
    fg.save(os.path.join(sprites, "icon_foreground.png"))
    Image.new("RGBA", (432, 432), BG).save(os.path.join(sprites, "icon_background.png"))
    icon().convert("RGB").save(os.path.join(OUT, "icon_512.png"))
    shots = sys.argv[1:]
    for i, path in enumerate(shots, 1):
        Image.open(path).convert("RGB").save(os.path.join(OUT, f"screenshot_{i}.png"), optimize=True)
    fever = next((p for p in shots if "fever" in os.path.basename(p)), shots[0] if shots else None)
    if fever:
        feature(fever).save(os.path.join(OUT, "feature_1024x578.png"), optimize=True)
    for f in sorted(os.listdir(OUT)):
        p = os.path.join(OUT, f)
        if f.endswith(".png"):
            print(f, Image.open(p).size, f"{os.path.getsize(p) // 1024} KB")


if __name__ == "__main__":
    main()
