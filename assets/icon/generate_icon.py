#!/usr/bin/env python3
from PIL import Image, ImageDraw

size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Background gradient approximation with layered ellipses
for i in range(16):
    alpha = 235 - i * 8
    color = (30 + i * 6, 120 + i * 3, 235 - i * 4, max(alpha, 20))
    inset = i * 10
    d.rounded_rectangle([inset, inset, size - inset, size - inset], radius=220 - i * 5, fill=color)

# Orbital rings
d.ellipse([170, 240, 860, 830], outline=(255, 255, 255, 180), width=26)
d.ellipse([240, 170, 830, 860], outline=(255, 255, 255, 130), width=20)

# Core glyph
d.rounded_rectangle([390, 390, 634, 634], radius=64, fill=(255, 255, 255, 238))
d.rectangle([300, 470, 724, 554], fill=(255, 255, 255, 220))

img.save('assets/icon/AppIcon-1024.png')
print('Wrote assets/icon/AppIcon-1024.png')
