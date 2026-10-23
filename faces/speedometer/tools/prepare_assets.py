#!/usr/bin/env python3
"""Resize personal reference art; requires Pillow. Never compile reference/.

Run from any directory. --preview also renders static composition checks, not
simulator screenshots. Source crop coordinates are in the original PNG pixels.
"""
from pathlib import Path
import argparse
import math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'resources/drawables'
REF = ROOT / 'reference'
SIZE = 454
# Stop inside the black dial boundary: no outer aluminium rim.
CROP = (120, 110, 1140, 1130)
SCALE = SIZE / (CROP[2] - CROP[0])
PIVOT = (227, 230)
# Original label centres; rotation follows this deliberately non-clock dial.
LABELS = [(529, 989), (364, 898), (253, 759), (222, 585),
          (282, 418), (421, 284), (630, 229), (822, 283),
          (994, 418), (1015, 575)]
LABEL_BOXES = [(498, 936, 557, 1038), (316, 843, 413, 948)]


def resize(im, size):
    return im.resize(size, Image.Resampling.LANCZOS)


def clean_leds(im):
    # Rebuild the regular LED lattice with sampled circles from the source.
    # This retains its shaded dot style, discarding stray red background specks.
    glyphs = []
    patterns = ['11111/10001/10001/10001/10001/10001/11111',
                '00100/01100/00100/00100/00100/00100/11111',
                '11111/00001/00001/11111/10000/10000/11111',
                '11111/00001/00001/11111/00001/00001/11111',
                '10001/10001/10001/11111/00001/00001/00001',
                '11111/10000/10000/11111/00001/00001/11111',
                '11111/10000/10000/11111/10001/10001/11111',
                '11111/00001/00001/00001/00001/00001/00001',
                '11111/10001/10001/11111/10001/10001/11111',
                '11111/10001/10001/11111/00001/00001/11111']
    # One clean dot, from the uppermost dot of the source '1'.
    dot = im.crop((178, 40, 216, 78))
    mask = Image.new('L', dot.size)
    ImageDraw.Draw(mask).ellipse((1, 1, 36, 36), fill=255)
    dot.putalpha(mask)
    for pattern in patterns:
        glyph = Image.new('RGBA', (190, 270))
        for row, line in enumerate(pattern.split('/')):
            for col, bit in enumerate(line):
                if bit == '1':
                    glyph.alpha_composite(dot, (col * 38, row * 38))
        glyphs.append(resize(glyph, (20, 29)))
    return glyphs


def prepare():
    OUT.mkdir(parents=True, exist_ok=True)
    backgrounds = []
    overlays = []
    for source, dest in [('speedometer.PNG', 'background.png'),
                         ('dark-speedometer.png', 'background-dark.png')]:
        original = Image.open(REF / source).convert('RGBA')
        bg = resize(original.crop(CROP), (SIZE, SIZE))
        # The display is round: trim at the circular inner-rim boundary.
        mask = Image.new('L', (SIZE, SIZE))
        ImageDraw.Draw(mask).ellipse((0, 0, SIZE - 1, SIZE - 1), fill=255)
        bg.putalpha(mask)
        # Discard hidden rim RGB outside the circle, rather than relying on
        # PNG alpha handling in every viewer/resource decoder.
        plate = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 255))
        plate.alpha_composite(bg)
        bg = plate
        bg.save(OUT / dest)
        window_name = 'window-dark.png' if 'dark' in dest else 'window.png'
        bg.crop((180, 81, 273, 185)).save(OUT / window_name)
        backgrounds.append(bg)
    original = Image.open(REF / 'speedometer.PNG').convert('RGBA')
    for i, box in enumerate(LABEL_BOXES, 1):
        label = original.crop(box)
        pixels = label.load()
        for y in range(label.height):
            for x in range(label.width):
                r, g, b, a = pixels[x, y]
                # Preserve the light outline, replace only the black digit body.
                if max(r, g, b) < 115 and a > 0:
                    pixels[x, y] = (255, 28, 15, a)
                elif min(r, g, b) > 170:
                    pixels[x, y] = (255, 235, 210, a)
                else:
                    pixels[x, y] = (0, 0, 0, 0)
        w = round(label.width * SCALE)
        h = round(label.height * SCALE)
        label = resize(label, (w, h))
        label.save(OUT / f'red-{i}.png')
        overlays.append((label, (round((box[0] - CROP[0]) * SCALE),
                                  round((box[1] - CROP[1]) * SCALE))))
    src = Image.open(REF / 'needlee.PNG').convert('RGBA')
    needle = Image.new('RGBA', (68, 160))
    # Source points down; retain that orientation and rotate about (34,34).
    blade = src.crop((596, 342, 653, 1214))
    needle.alpha_composite(resize(blade, (12, 130)), (28, 28))
    hub = src.crop((455, 41, 798, 377))
    hub = resize(hub, (68, 68))
    hub_mask = Image.new('L', (68, 68))
    ImageDraw.Draw(hub_mask).ellipse((1, 1, 66, 66), fill=255)
    hub.putalpha(hub_mask)
    needle.alpha_composite(hub)
    needle.save(OUT / 'needle.png')
    glyphs = clean_leds(Image.open(REF / 'digits.PNG').convert('RGBA'))
    for i, glyph in enumerate(glyphs):
        glyph.save(OUT / f'digit-{i}.png')
    return backgrounds, overlays, needle, glyphs


def render(assets, hour, dark=False):
    backgrounds, overlays, needle, glyphs = assets
    canvas = backgrounds[int(dark)].copy()
    idx = hour if hour <= 10 else hour - 10
    if hour > 10:
        label, xy = overlays[idx - 1]
        canvas.alpha_composite(label, xy)
    x, y = LABELS[idx - 1]
    dx = (x - CROP[0]) * SCALE - PIVOT[0]
    dy = (y - CROP[1]) * SCALE - PIVOT[1]
    # Pillow's positive rotation is counter-clockwise; align down to target.
    angle = math.degrees(math.atan2(dx, dy))
    layer = Image.new('RGBA', (SIZE, SIZE))
    layer.alpha_composite(needle, (PIVOT[0] - 34, PIVOT[1] - 34))
    layer = layer.rotate(angle, Image.Resampling.BICUBIC, center=PIVOT)
    canvas.alpha_composite(layer)
    canvas.alpha_composite(backgrounds[int(dark)].crop((180, 81, 273, 185)), (180, 81))
    for digit, xx in [(5, 202), (4, 226)]:
        canvas.alpha_composite(glyphs[digit], (xx, 117))
    # Date glyphs are resized for the lower window.
    for digit, xx in [(1, 266), (0, 283), (0, 315), (8, 332)]:
        canvas.alpha_composite(resize(glyphs[digit], (14, 21)), (xx, 336))
    ImageDraw.Draw(canvas).line((305, 347, 310, 347), fill='#ff3010', width=2)
    return canvas


def preview(assets):
    sheet = Image.new('RGB', (SIZE * 4, SIZE * 3), '#222222')
    for hour in range(1, 13):
        canvas = render(assets, hour)
        ImageDraw.Draw(canvas).text((190, 425), f'{hour:02}:54', fill='white')
        sheet.paste(canvas, (((hour - 1) % 4) * SIZE, ((hour - 1) // 4) * SIZE), canvas)
    dest = ROOT / 'bin'
    dest.mkdir(exist_ok=True)
    sheet.save(dest / 'hours-preview.png')
    render(assets, 11).save(dest / 'light-preview.png')
    render(assets, 12, dark=True).save(dest / 'dark-preview.png')
    render(assets, 12, dark=True).save(dest / 'aod-preview.png')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', action='store_true')
    args = parser.parse_args()
    assets = prepare()
    if args.preview:
        preview(assets)
