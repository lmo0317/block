import math
import os
from PIL import Image, ImageDraw, ImageFilter

os.makedirs('assets/avatars', exist_ok=True)
os.makedirs('assets/sprites', exist_ok=True)

def create_circular_avatar(bg_gradient_start, bg_gradient_end, border_color, draw_fn, output_path):
    size = 256
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Draw gradient circle
    cx, cy = size / 2, size / 2
    radius = 116

    # Draw gradient by concentric or linear interpolated bands
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= radius:
                # Vertical interpolation factor
                t = (y - (cy - radius)) / (2 * radius)
                t = max(0.0, min(1.0, t))
                r = int(bg_gradient_start[0] * (1 - t) + bg_gradient_end[0] * t)
                g = int(bg_gradient_start[1] * (1 - t) + bg_gradient_end[1] * t)
                b = int(bg_gradient_start[2] * (1 - t) + bg_gradient_end[2] * t)
                # Outer antialiasing edge
                alpha = 255
                if dist > radius - 1.5:
                    alpha = int(255 * (radius - dist) / 1.5)
                    alpha = max(0, min(255, alpha))
                img.putpixel((x, y), (r, g, b, alpha))

    # Redraw draw object
    draw = ImageDraw.Draw(img)

    # 2. Draw avatar content
    draw_fn(draw, size, cx, cy)

    # 3. Outer border ring
    border_width = 8
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=border_color, width=border_width)

    # Downscale for super crisp antialiasing
    final_img = img.resize((128, 128), Image.Resampling.LANCZOS)
    final_img.save(output_path, 'PNG')
    print(f'Generated: {output_path}')

# 1. Bear (Amber / Warm Brown)
def draw_bear(draw, size, cx, cy):
    # Ears
    draw.ellipse([cx - 75, cy - 85, cx - 35, cy - 45], fill=(139, 85, 42))
    draw.ellipse([cx - 65, cy - 75, cx - 45, cy - 55], fill=(225, 175, 130))
    draw.ellipse([cx + 35, cy - 85, cx + 75, cy - 45], fill=(139, 85, 42))
    draw.ellipse([cx + 45, cy - 75, cx + 65, cy - 55], fill=(225, 175, 130))
    # Head
    draw.ellipse([cx - 65, cy - 55, cx + 65, cy + 65], fill=(170, 105, 55))
    # Muzzle
    draw.ellipse([cx - 35, cy, cx + 35, cy + 55], fill=(235, 195, 155))
    # Nose
    draw.ellipse([cx - 15, cy + 12, cx + 15, cy + 32], fill=(45, 30, 20))
    # Mouth
    draw.line([cx, cy + 32, cx, cy + 42], fill=(45, 30, 20), width=4)
    draw.arc([cx - 18, cy + 30, cx, cy + 48], 0, 180, fill=(45, 30, 20), width=4)
    draw.arc([cx, cy + 30, cx + 18, cy + 48], 0, 180, fill=(45, 30, 20), width=4)
    # Eyes
    draw.ellipse([cx - 35, cy - 18, cx - 21, cy - 4], fill=(30, 20, 15))
    draw.ellipse([cx - 32, cy - 16, cx - 26, cy - 10], fill=(255, 255, 255))
    draw.ellipse([cx + 21, cy - 18, cx + 35, cy - 4], fill=(30, 20, 15))
    draw.ellipse([cx + 24, cy - 16, cx + 30, cy - 10], fill=(255, 255, 255))
    # Cute Cheeks
    draw.ellipse([cx - 52, cy + 10, cx - 36, cy + 24], fill=(240, 130, 130, 180))
    draw.ellipse([cx + 36, cy + 10, cx + 52, cy + 24], fill=(240, 130, 130, 180))

# 2. Cat (Teal / Cyan theme)
def draw_cat(draw, size, cx, cy):
    # Pointed Ears
    draw.polygon([(cx - 65, cy - 25), (cx - 55, cy - 85), (cx - 15, cy - 45)], fill=(240, 240, 245))
    draw.polygon([(cx - 58, cy - 32), (cx - 52, cy - 75), (cx - 24, cy - 48)], fill=(255, 170, 190))
    draw.polygon([(cx + 15, cy - 45), (cx + 55, cy - 85), (cx + 65, cy - 25)], fill=(240, 240, 245))
    draw.polygon([(cx + 24, cy - 48), (cx + 52, cy - 75), (cx + 58, cy - 32)], fill=(255, 170, 190))
    # Head
    draw.ellipse([cx - 62, cy - 50, cx + 62, cy + 60], fill=(248, 248, 255))
    # Eyes (Big anime/cat eyes)
    draw.ellipse([cx - 40, cy - 15, cx - 16, cy + 12], fill=(40, 160, 220))
    draw.ellipse([cx - 32, cy - 12, cx - 22, cy - 2], fill=(255, 255, 255))
    draw.ellipse([cx + 16, cy - 15, cx + 40, cy + 12], fill=(40, 160, 220))
    draw.ellipse([cx + 22, cy - 12, cx + 32, cy - 2], fill=(255, 255, 255))
    # Nose
    draw.polygon([(cx - 8, cy + 14), (cx + 8, cy + 14), (cx, cy + 22)], fill=(255, 130, 160))
    # Mouth
    draw.arc([cx - 14, cy + 18, cx, cy + 32], 0, 180, fill=(100, 110, 130), width=3)
    draw.arc([cx, cy + 18, cx + 14, cy + 32], 0, 180, fill=(100, 110, 130), width=3)
    # Whiskers
    draw.line([cx - 70, cy + 16, cx - 45, cy + 20], fill=(180, 190, 210), width=3)
    draw.line([cx - 68, cy + 28, cx - 45, cy + 26], fill=(180, 190, 210), width=3)
    draw.line([cx + 45, cy + 20, cx + 70, cy + 16], fill=(180, 190, 210), width=3)
    draw.line([cx + 45, cy + 26, cx + 68, cy + 28], fill=(180, 190, 210), width=3)

# 3. Fox (Clever Orange)
def draw_fox(draw, size, cx, cy):
    # Big Ears
    draw.polygon([(cx - 70, cy - 20), (cx - 60, cy - 90), (cx - 10, cy - 40)], fill=(230, 95, 30))
    draw.polygon([(cx - 58, cy - 28), (cx - 52, cy - 78), (cx - 20, cy - 42)], fill=(255, 240, 230))
    draw.polygon([(cx + 10, cy - 40), (cx + 60, cy - 90), (cx + 70, cy - 20)], fill=(230, 95, 30))
    draw.polygon([(cx + 20, cy - 42), (cx + 52, cy - 78), (cx + 58, cy - 28)], fill=(255, 240, 230))
    # Head base
    draw.ellipse([cx - 60, cy - 45, cx + 60, cy + 55], fill=(230, 95, 30))
    # White face cheeks
    draw.polygon([(cx - 60, cy - 5), (cx - 55, cy + 50), (cx, cy + 60), (cx - 10, cy + 10)], fill=(255, 250, 245))
    draw.polygon([(cx + 60, cy - 5), (cx + 55, cy + 50), (cx, cy + 60), (cx + 10, cy + 10)], fill=(255, 250, 245))
    # Nose
    draw.ellipse([cx - 10, cy + 46, cx + 10, cy + 62], fill=(30, 25, 25))
    # Eyes (Sleek clever eyes)
    draw.polygon([(cx - 45, cy + 6), (cx - 20, cy + 2), (cx - 30, cy + 12)], fill=(40, 30, 25))
    draw.polygon([(cx + 20, cy + 2), (cx + 45, cy + 6), (cx + 30, cy + 12)], fill=(40, 30, 25))

# 4. Robot (Cyber Blue/Purple)
def draw_robot(draw, size, cx, cy):
    # Antenna
    draw.line([cx, cy - 55, cx, cy - 85], fill=(160, 180, 220), width=6)
    draw.ellipse([cx - 14, cy - 98, cx + 14, cy - 74], fill=(0, 240, 255))
    # Head
    draw.rounded_rectangle([cx - 62, cy - 55, cx + 62, cy + 55], radius=20, fill=(45, 60, 95), outline=(120, 160, 230), width=4)
    # Ear bolts
    draw.rounded_rectangle([cx - 72, cy - 18, cx - 60, cy + 18], radius=6, fill=(100, 130, 180))
    draw.rounded_rectangle([cx + 60, cy - 18, cx + 72, cy + 18], radius=6, fill=(100, 130, 180))
    # Visor screen
    draw.rounded_rectangle([cx - 48, cy - 35, cx + 48, cy + 15], radius=12, fill=(15, 25, 45))
    # Glowing digital eyes
    draw.ellipse([cx - 35, cy - 20, cx - 15, cy], fill=(0, 255, 200))
    draw.ellipse([cx + 15, cy - 20, cx + 35, cy], fill=(0, 255, 200))
    # Speaker grill / mouth
    for i in range(-3, 4):
        draw.line([cx + i * 8, cy + 28, cx + i * 8, cy + 42], fill=(120, 160, 230), width=3)

# 5. Lion / Crown King (Royal Gold)
def draw_lion(draw, size, cx, cy):
    # Mane
    draw.ellipse([cx - 82, cy - 65, cx + 82, cy + 75], fill=(220, 140, 30))
    # Ears
    draw.ellipse([cx - 65, cy - 70, cx - 35, cy - 40], fill=(245, 185, 70))
    draw.ellipse([cx + 35, cy - 70, cx + 75, cy - 40], fill=(245, 185, 70))
    # Head
    draw.ellipse([cx - 52, cy - 40, cx + 52, cy + 55], fill=(255, 205, 90))
    # Crown on head
    crown_pts = [(cx - 38, cy - 40), (cx - 44, cy - 75), (cx - 18, cy - 55), (cx, cy - 82), (cx + 18, cy - 55), (cx + 44, cy - 75), (cx + 38, cy - 40)]
    draw.polygon(crown_pts, fill=(255, 220, 40), outline=(210, 150, 10), width=3)
    draw.ellipse([cx - 4, cy - 86, cx + 4, cy - 78], fill=(255, 70, 70)) # Red gem
    # Muzzle
    draw.ellipse([cx - 30, cy + 8, cx + 30, cy + 48], fill=(255, 240, 200))
    draw.polygon([(cx - 12, cy + 12), (cx + 12, cy + 12), (cx, cy + 24)], fill=(120, 60, 20))
    draw.arc([cx - 16, cy + 22, cx, cy + 38], 0, 180, fill=(100, 50, 20), width=3)
    draw.arc([cx, cy + 22, cx + 16, cy + 38], 0, 180, fill=(100, 50, 20), width=3)
    # Eyes
    draw.ellipse([cx - 30, cy - 14, cx - 16, cy], fill=(50, 35, 20))
    draw.ellipse([cx + 16, cy - 14, cx + 30, cy], fill=(50, 35, 20))

# 6. Penguin (Frost Teal)
def draw_penguin(draw, size, cx, cy):
    # Head body
    draw.ellipse([cx - 65, cy - 55, cx + 65, cy + 65], fill=(30, 45, 65))
    # White belly & face
    draw.ellipse([cx - 45, cy - 40, cx + 45, cy + 58], fill=(250, 252, 255))
    # Black eye patches
    draw.ellipse([cx - 35, cy - 22, cx - 15, cy + 2], fill=(30, 45, 65))
    draw.ellipse([cx - 28, cy - 18, cx - 20, cy - 8], fill=(255, 255, 255))
    draw.ellipse([cx + 15, cy - 22, cx + 35, cy + 2], fill=(30, 45, 65))
    draw.ellipse([cx + 20, cy - 18, cx + 28, cy - 8], fill=(255, 255, 255))
    # Yellow Beak
    draw.polygon([(cx - 18, cy + 6), (cx + 18, cy + 6), (cx, cy + 28)], fill=(255, 185, 30))
    # Rosy Cheeks
    draw.ellipse([cx - 48, cy + 10, cx - 32, cy + 24], fill=(255, 140, 160, 180))
    draw.ellipse([cx + 32, cy + 10, cx + 48, cy + 24], fill=(255, 140, 160, 180))

# 7. Wizard / Owl (Mystic Purple)
def draw_owl(draw, size, cx, cy):
    # Feather horns / ears
    draw.polygon([(cx - 65, cy - 20), (cx - 55, cy - 75), (cx - 25, cy - 40)], fill=(90, 50, 140))
    draw.polygon([(cx + 25, cy - 40), (cx + 55, cy - 75), (cx + 65, cy - 20)], fill=(90, 50, 140))
    # Body/Head
    draw.ellipse([cx - 60, cy - 45, cx + 60, cy + 62], fill=(120, 75, 180))
    # Big Owl Eyeglasses / Rings
    draw.ellipse([cx - 48, cy - 26, cx - 4, cy + 18], fill=(255, 220, 60), outline=(60, 30, 100), width=4)
    draw.ellipse([cx + 4, cy - 26, cx + 48, cy + 18], fill=(255, 220, 60), outline=(60, 30, 100), width=4)
    # Pupils
    draw.ellipse([cx - 34, cy - 14, cx - 18, cy + 6], fill=(30, 20, 45))
    draw.ellipse([cx - 30, cy - 12, cx - 24, cy - 4], fill=(255, 255, 255))
    draw.ellipse([cx + 18, cy - 14, cx + 34, cy + 6], fill=(30, 20, 45))
    draw.ellipse([cx + 24, cy - 12, cx + 30, cy - 4], fill=(255, 255, 255))
    # Beak
    draw.polygon([(cx - 10, cy + 4), (cx + 10, cy + 4), (cx, cy + 26)], fill=(245, 150, 30))

# 8. Astronaut / Cosmic (Neon Rose / Pink)
def draw_astronaut(draw, size, cx, cy):
    # Helmet base
    draw.ellipse([cx - 65, cy - 55, cx + 65, cy + 65], fill=(235, 240, 250), outline=(180, 190, 215), width=5)
    # Side filters
    draw.rounded_rectangle([cx - 75, cy - 12, cx - 62, cy + 22], radius=6, fill=(150, 165, 195))
    draw.rounded_rectangle([cx + 62, cy - 12, cx + 75, cy + 22], radius=6, fill=(150, 165, 195))
    # Shiny Visor
    draw.rounded_rectangle([cx - 48, cy - 35, cx + 48, cy + 35], radius=24, fill=(25, 30, 60))
    # Visor gradient reflection arc
    draw.arc([cx - 42, cy - 30, cx + 42, cy + 30], 200, 330, fill=(0, 220, 255), width=6)
    draw.ellipse([cx - 30, cy - 22, cx - 14, cy - 8], fill=(255, 255, 255, 200))

# Generate Settings Gear Icon
def create_settings_icon(output_path):
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2
    r_outer = 48
    r_inner = 36
    r_hole = 16
    teeth = 8

    # Draw gear teeth
    for i in range(teeth):
        angle = (i * 2 * math.pi) / teeth
        ang1 = angle - 0.22
        ang2 = angle + 0.22
        x1 = cx + (r_outer + 8) * math.cos(ang1)
        y1 = cy + (r_outer + 8) * math.sin(ang1)
        x2 = cx + (r_outer + 8) * math.cos(ang2)
        y2 = cy + (r_outer + 8) * math.sin(ang2)
        x3 = cx + r_inner * math.cos(ang2 + 0.15)
        y3 = cy + r_inner * math.sin(ang2 + 0.15)
        x4 = cx + r_inner * math.cos(ang1 - 0.15)
        y4 = cy + r_inner * math.sin(ang1 - 0.15)
        draw.polygon([(x1, y1), (x2, y2), (x3, y3), (x4, y4)], fill=(230, 238, 252))

    # Outer circle
    draw.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner], fill=(215, 228, 248))
    # Inner hole
    draw.ellipse([cx - r_hole, cy - r_hole, cx + r_hole, cy + r_hole], fill=(0, 0, 0, 0))

    final = img.resize((64, 64), Image.Resampling.LANCZOS)
    final.save(output_path, 'PNG')
    print(f'Generated gear icon: {output_path}')

# Generate all 8 avatars
avatars = [
    ((230, 160, 45), (160, 90, 20), (255, 215, 90), draw_bear, 'assets/avatars/avatar_1.png'),
    ((40, 160, 220), (20, 80, 140), (120, 220, 255), draw_cat, 'assets/avatars/avatar_2.png'),
    ((240, 100, 30), (180, 50, 15), (255, 170, 90), draw_fox, 'assets/avatars/avatar_3.png'),
    ((70, 80, 170), (35, 40, 100), (130, 160, 255), draw_robot, 'assets/avatars/avatar_4.png'),
    ((245, 185, 30), (180, 120, 15), (255, 230, 110), draw_lion, 'assets/avatars/avatar_5.png'),
    ((25, 160, 160), (15, 80, 95), (100, 230, 230), draw_penguin, 'assets/avatars/avatar_6.png'),
    ((135, 70, 205), (75, 30, 130), (200, 150, 255), draw_owl, 'assets/avatars/avatar_7.png'),
    ((225, 60, 135), (145, 25, 80), (255, 150, 210), draw_astronaut, 'assets/avatars/avatar_8.png')
]

for start_c, end_c, border_c, fn, out in avatars:
    create_circular_avatar(start_c, end_c, border_c, fn, out)

create_settings_icon('assets/sprites/settings_icon.png')
print('All avatars and icons generated successfully!')
