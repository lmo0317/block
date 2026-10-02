import os
import math
import struct
import wave
from PIL import Image, ImageDraw, ImageFilter

ASSETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
SFX_DIR = os.path.join(ASSETS_DIR, "sfx")

os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(SFX_DIR, exist_ok=True)

print("Generating sprites...")

def create_block_texture(color_top, color_bottom, size=74, radius=12):
    # High resolution render (2x supersampling)
    scale = 2
    s = size * scale
    r = radius * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Outer border / drop shadow
    shadow_offset = 3 * scale
    draw.rounded_rectangle([0, shadow_offset, s, s], radius=r, fill=(0, 0, 0, 90))

    # Main block body with subtle gradient
    # We draw vertical slices or rounded rect
    base = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(base)
    bdraw.rounded_rectangle([0, 0, s, s - shadow_offset], radius=r, fill=color_bottom)

    # Top gradient
    top_overlay = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(top_overlay)
    tdraw.rounded_rectangle([0, 0, s, s - shadow_offset], radius=r, fill=color_top)

    # Mask for gradient
    mask = Image.new("L", (s, s), 0)
    m_data = []
    for y in range(s):
        alpha = int(255 * (1.0 - (y / float(s - shadow_offset))))
        alpha = max(0, min(255, alpha))
        m_data.extend([alpha] * s)
    mask.putdata(m_data)

    base.paste(top_overlay, (0, 0), mask)
    img.paste(base, (0, 0), base)

    # Glossy top-inner highlight (gives jewel/glass 3D feel like Block Blast)
    highlight = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    inner_margin = 3 * scale
    hdraw.rounded_rectangle(
        [inner_margin, inner_margin, s - inner_margin, (s - shadow_offset) // 2],
        radius=r - 2 * scale,
        fill=(255, 255, 255, 80)
    )
    img.paste(highlight, (0, 0), highlight)

    # Inner bright rim stroke
    rim = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    rdraw = ImageDraw.Draw(rim)
    rdraw.rounded_rectangle(
        [1 * scale, 1 * scale, s - 1 * scale, s - shadow_offset - 1 * scale],
        radius=r,
        outline=(255, 255, 255, 120),
        width=1 * scale
    )
    img.paste(rim, (0, 0), rim)

    # Downsample with Lanczos
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

# Palette definition
PALETTE = {
    "blue": ((56, 189, 248), (2, 132, 199)),      # Cyan / Sky
    "orange": ((251, 146, 60), (234, 88, 12)),    # Orange
    "green": ((52, 211, 153), (5, 150, 105)),     # Emerald
    "purple": ((192, 132, 252), (147, 51, 234)),  # Purple
    "yellow": ((253, 224, 71), (234, 179, 8)),    # Gold
    "red": ((248, 113, 113), (220, 38, 38)),      # Crimson
    "cyan": ((34, 211, 238), (8, 145, 178)),      # Aqua
    "pink": ((244, 114, 182), (219, 39, 119)),    # Pink
}

for name, (col_top, col_bottom) in PALETTE.items():
    tex = create_block_texture(col_top, col_bottom)
    tex.save(os.path.join(SPRITES_DIR, f"block_{name}.png"))

print(f"Generated {len(PALETTE)} block textures.")

# 1. Cell slot texture (empty board slot)
def create_cell_slot(size=74, radius=10):
    scale = 2
    s = size * scale
    r = radius * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Base dark tile
    draw.rounded_rectangle([0, 0, s, s], radius=r, fill=(20, 27, 43, 230))
    # Subtle inner bevel outline
    draw.rounded_rectangle([2, 2, s-2, s-2], radius=r, outline=(34, 46, 74, 255), width=2)
    # Inner dark shadow for inset depth
    draw.rounded_rectangle([4, 4, s-4, s-4], radius=r-2, fill=(15, 20, 32, 200))

    return img.resize((size, size), Image.Resampling.LANCZOS)

create_cell_slot().save(os.path.join(SPRITES_DIR, "cell_slot.png"))

# 2. Ghost preview texture (when dragging block over slot)
def create_cell_ghost(size=74, radius=10):
    scale = 2
    s = size * scale
    r = radius * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.rounded_rectangle([2, 2, s-2, s-2], radius=r, fill=(255, 255, 255, 75))
    draw.rounded_rectangle([2, 2, s-2, s-2], radius=r, outline=(255, 255, 255, 210), width=4)

    return img.resize((size, size), Image.Resampling.LANCZOS)

create_cell_ghost().save(os.path.join(SPRITES_DIR, "cell_ghost.png"))

# 3. Sparkle / Star particle
def create_sparkle(size=48):
    scale = 2
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = s // 2, s // 2

    # Draw 4-point diamond star
    points = [
        (cx, 4),
        (cx + 8*scale, cy - 8*scale),
        (s - 4, cy),
        (cx + 8*scale, cy + 8*scale),
        (cx, s - 4),
        (cx - 8*scale, cy + 8*scale),
        (4, cy),
        (cx - 8*scale, cy - 8*scale),
    ]
    draw.polygon(points, fill=(255, 255, 255, 255))
    # Inner glow
    draw.ellipse([cx - 10*scale, cy - 10*scale, cx + 10*scale, cy + 10*scale], fill=(255, 255, 200, 220))

    return img.resize((size, size), Image.Resampling.LANCZOS)

create_sparkle().save(os.path.join(SPRITES_DIR, "sparkle.png"))

# 4. App Icon (256x256)
def create_app_icon():
    s = 256
    img = Image.new("RGBA", (s, s), (11, 15, 25, 255))
    draw = ImageDraw.Draw(img)

    # Glowing rounded background container
    draw.rounded_rectangle([12, 12, s-12, s-12], radius=44, fill=(18, 25, 41, 255), outline=(59, 130, 246, 120), width=3)

    # 4 colorful mini blocks in 2x2 grid
    bsize = 80
    gap = 12
    start_x = (s - (bsize * 2 + gap)) // 2
    start_y = (s - (bsize * 2 + gap)) // 2

    colors = [
        PALETTE["blue"],
        PALETTE["orange"],
        PALETTE["green"],
        PALETTE["yellow"],
    ]

    for idx, (ct, cb) in enumerate(colors):
        r = idx // 2
        c = idx % 2
        bx = start_x + c * (bsize + gap)
        by = start_y + r * (bsize + gap)
        btex = create_block_texture(ct, cb, size=bsize, radius=14)
        img.paste(btex, (bx, by), btex)

    # Sparkle in corner
    sp = create_sparkle(size=44)
    img.paste(sp, (s - 60, 20), sp)

    return img

create_app_icon().save(os.path.join(SPRITES_DIR, "icon.png"))
create_app_icon().save(os.path.join(ASSETS_DIR, "icon.png"))
print("Sprites generation complete.")

# ----------------- AUDIO GENERATION -----------------
print("Generating audio SFX...")

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    filepath = os.path.join(SFX_DIR, filename)
    with wave.open(filepath, "w") as wav:
        wav.setnchannels(1)  # Mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(SAMPLE_RATE)
        # Pack samples
        packed = bytearray()
        for s in samples:
            s = max(-1.0, min(1.0, s))
            val = int(s * 32767.0)
            packed.extend(struct.pack("<h", val))
        wav.writeframes(packed)
    print(f"Created {filename}")

# Pickup sound: swift rising tone
def gen_pickup():
    dur = 0.08
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        p = t / dur
        freq = 380.0 + 320.0 * (p ** 0.8)
        env = (math.sin(p * math.pi) ** 0.8) * 0.4
        val = math.sin(2 * math.pi * freq * t) * env
        samples.append(val)
    return samples

# Place sound: punchy pop/click
def gen_place():
    dur = 0.09
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        p = t / dur
        # Bass thud + high click
        bass_freq = 180.0 * (1.0 - 0.7 * p)
        high_freq = 820.0 * (1.0 - 0.8 * p)
        env = math.exp(-35.0 * t) * 0.7
        val = (math.sin(2 * math.pi * bass_freq * t) * 0.7 +
               math.sin(2 * math.pi * high_freq * t) * 0.4) * env
        samples.append(val)
    return samples

# Invalid return sound: dull boing
def gen_invalid():
    dur = 0.14
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        freq = 240.0 * (1.0 - 0.5 * (t / dur))
        env = math.exp(-18.0 * t) * 0.45
        val = (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 1.5 * t)) * env
        samples.append(val)
    return samples

# Line blast clear sound: rich crystalline bell + whoosh
def gen_clear():
    dur = 0.35
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        # Dual bell ringing
        f1 = 587.33  # D5
        f2 = 880.00  # A5
        f3 = 1174.66 # D6
        env = math.exp(-10.0 * t) * 0.5
        val = (0.5 * math.sin(2 * math.pi * f1 * t) +
               0.3 * math.sin(2 * math.pi * f2 * t) +
               0.2 * math.sin(2 * math.pi * f3 * t)) * env
        samples.append(val)
    return samples

# Musical combo chimes: Pentatonic scale
# C5, D5, E5, G5, A5, C6, E6
COMBO_FREQS = [
    523.25,  # C5
    587.33,  # D5
    659.25,  # E5
    783.99,  # G5
    880.00,  # A5
    1046.50, # C6
    1318.51, # E6
]

def gen_combo(freq, dur=0.28):
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        env = math.exp(-11.0 * t) * 0.55
        # Fundamental + harmonic overtone
        val = (0.7 * math.sin(2 * math.pi * freq * t) +
               0.3 * math.sin(2 * math.pi * (freq * 2.0) * t) +
               0.1 * math.sin(2 * math.pi * (freq * 3.0) * t)) * env
        samples.append(val)
    return samples

# Game over sound: gentle descending melody
def gen_gameover():
    notes = [440.0, 392.0, 349.23, 293.66] # A4, G4, F4, D4
    note_dur = 0.16
    samples = []
    for freq in notes:
        n_samples = int(note_dur * SAMPLE_RATE)
        for i in range(n_samples):
            t = i / float(SAMPLE_RATE)
            env = math.exp(-9.0 * t) * 0.45
            val = (0.7 * math.sin(2 * math.pi * freq * t) +
                   0.25 * math.sin(2 * math.pi * (freq * 2) * t)) * env
            samples.append(val)
    return samples

# New record celebration fanfare
def gen_record():
    notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
    note_dur = 0.12
    samples = []
    for freq in notes:
        n_samples = int(note_dur * SAMPLE_RATE)
        for i in range(n_samples):
            t = i / float(SAMPLE_RATE)
            env = math.exp(-7.0 * t) * 0.5
            val = (0.75 * math.sin(2 * math.pi * freq * t) +
                   0.25 * math.sin(2 * math.pi * freq * 2.0 * t)) * env
            samples.append(val)
    return samples

# UI Click
def gen_click():
    dur = 0.04
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        freq = 1100.0 * (1.0 - 0.7 * (t / dur))
        env = math.exp(-40.0 * t) * 0.4
        val = math.sin(2 * math.pi * freq * t) * env
        samples.append(val)
    return samples

# New round deal swoosh
def gen_deal():
    dur = 0.18
    num_samples = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / float(SAMPLE_RATE)
        p = t / dur
        freq = 300.0 + 400.0 * (1.0 - abs(p - 0.5) * 2.0)
        env = math.sin(p * math.pi) * 0.35
        val = math.sin(2 * math.pi * freq * t) * env
        samples.append(val)
    return samples

write_wav("pickup.wav", gen_pickup())
write_wav("place.wav", gen_place())
write_wav("invalid.wav", gen_invalid())
write_wav("gameover.wav", gen_gameover())
write_wav("record.wav", gen_record())
write_wav("click.wav", gen_click())
write_wav("deal.wav", gen_deal())

# Clear, combo, fever and perfect sounds are made by tools/generate_sfx.py

print("Asset generation finished successfully!")
