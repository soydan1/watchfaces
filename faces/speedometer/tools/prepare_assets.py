#!/usr/bin/env python3
"""Resize personal reference art; requires Pillow. Never compile reference/.

Run from any directory. --preview also renders static composition checks, not
simulator screenshots. Source crop coordinates are in the original PNG pixels.
"""
from pathlib import Path
import argparse
import math
from PIL import Image, ImageChops, ImageDraw

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


def seven_segment_digits():
    # Bevel-ended dashboard segments; all shading is baked into the PNGs.
    # No extra runtime layers, installed font, dots, or outer glow.
    segments = {
        'a': [(5, 1), (23, 1), (26, 4), (23, 7), (5, 7), (2, 4)],
        'g': [(5, 19), (23, 19), (26, 22), (23, 25), (5, 25), (2, 22)],
        'd': [(5, 37), (23, 37), (26, 40), (23, 43), (5, 43), (2, 40)],
        # Full-height vertical tips keep 1/4/7 optically as tall as 0/5/8.
        'f': [(1, 5), (4, 1), (7, 5), (7, 17), (4, 21), (1, 17)],
        'b': [(21, 5), (24, 1), (27, 5), (27, 17), (24, 21), (21, 17)],
        'e': [(1, 27), (4, 23), (7, 27), (7, 39), (4, 43), (1, 39)],
        'c': [(21, 27), (24, 23), (27, 27), (27, 39), (24, 43), (21, 39)],
    }
    patterns = ['abcdef', 'bc', 'abged', 'abgcd', 'fgbc',
                'afgcd', 'afgecd', 'abc', 'abcdefg', 'abfgcd']
    glyphs = []
    for pattern in patterns:
        mask = Image.new('L', (28 * 4, 44 * 4))
        draw = ImageDraw.Draw(mask)
        for segment in pattern:
            draw.polygon([(x * 4, y * 4) for x, y in segments[segment]], fill=255)
        # Inset top-left highlight and bottom-right shadow, both inside the
        # original silhouette so digit heights and spacing remain unchanged.
        highlight = ImageChops.subtract(mask, ImageChops.offset(mask, 3, 3))
        shadow = ImageChops.subtract(mask, ImageChops.offset(mask, -3, -3))
        glyph = Image.new('RGBA', mask.size, (255, 64, 32, 255))
        glyph = Image.composite(Image.new('RGBA', mask.size, (190, 38, 12, 255)),
                                glyph, shadow)
        glyph = Image.composite(Image.new('RGBA', mask.size, (255, 150, 88, 255)),
                                glyph, highlight)
        glyph.putalpha(mask)
        clean = Image.new('RGBA', mask.size)
        clean.alpha_composite(glyph)
        glyphs.append(resize(clean, (28, 44)))
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
    glyphs = seven_segment_digits()
    for i, glyph in enumerate(glyphs):
        glyph.save(OUT / f'digit-{i}.png')
    return backgrounds, overlays, needle, glyphs


def date_ink_bounds(glyphs):
    return [resize(g, (24, 42)).getchannel('A').point(
        lambda a: 255 if a > 128 else 0).getbbox() for g in glyphs]


def date_start_x(glyphs, day, month):
    bounds = date_ink_bounds(glyphs)
    # First and last visible strokes, not the 124px monospaced container.
    return 322 - (bounds[day // 10][0] + 100 + bounds[month % 10][2]) // 2


def render(assets, hour, dark=False, minute=54, day=10, month=8, with_needle=True):
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
    for digit, xx in [(minute // 10, 196), (minute % 10, 230)]:
        canvas.alpha_composite(glyphs[digit], (xx, 108))
    # Almost minute-size date digits, optically centred in the lower screen.
    date_x = date_start_x(glyphs, day, month)
    for digit, xx in [(day // 10, date_x), (day % 10, date_x + 28),
                      (month // 10, date_x + 72), (month % 10, date_x + 100)]:
        canvas.alpha_composite(resize(glyphs[digit], (24, 42)), (xx, 326))
    ImageDraw.Draw(canvas).rectangle((date_x + 58, 346, date_x + 65, 349), fill='#ff4020')
    # The needle is intentionally above the bezel AND digits, including AOD.
    if with_needle:
        canvas.alpha_composite(layer)
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
    render(assets, 7).save(dest / 'needle-over-minutes-preview.png')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', action='store_true')
    args = parser.parse_args()
    assets = prepare()
    if args.preview:
        preview(assets)
