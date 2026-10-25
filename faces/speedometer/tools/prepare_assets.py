#!/usr/bin/env python3
"""Resize personal reference art; requires Pillow. Never compile reference/.

Run from any directory. --preview also renders static composition checks, not
simulator screenshots. Source crop coordinates are in the original PNG pixels.
"""
from pathlib import Path
from functools import lru_cache
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
DATE_ZERO_LABEL = (625, 1010)
TIME_WINDOW_BOX = (250, 294, 395, 410)
DISPLAY_COLOR = (255, 226, 145, 255)


def resize(im, size):
    return im.resize(size, Image.Resampling.LANCZOS)


def dashboard_glyph(character):
    # Original segmented/stencil design inspired by the F430 neutral "N".
    # Split centre bars and chamfered strokes, not an exact extracted font.
    segments = {
        'a': [(5, 1), (23, 1), (26, 3), (23, 5), (5, 5), (2, 3)],
        'g1': [(5, 20), (12, 20), (13, 22), (12, 24), (5, 24), (2, 22)],
        'g2': [(16, 20), (23, 20), (26, 22), (23, 24), (16, 24), (15, 22)],
        'd': [(5, 39), (23, 39), (26, 41), (23, 43), (5, 43), (2, 41)],
        # Full-height tips keep 1/4/7 optically as tall as 0/5/8.
        'f': [(1, 5), (3, 1), (5, 5), (5, 17), (3, 19), (1, 17)],
        'b': [(21, 5), (24, 1), (27, 5), (27, 17), (24, 19), (21, 17)],
        'e': [(1, 27), (3, 25), (5, 27), (5, 39), (3, 43), (1, 39)],
        'c': [(21, 27), (24, 25), (27, 27), (27, 39), (24, 43), (21, 39)],
        'h': [(7, 5), (11, 8), (14, 18), (13, 20), (10, 17)],
        'm': [(15, 24), (18, 27), (22, 38), (20, 40), (17, 35)],
    }
    patterns = {
        '0': ('a', 'b', 'c', 'd', 'e', 'f'), '1': ('b', 'c'),
        '2': ('a', 'b', 'g1', 'g2', 'e', 'd'),
        '3': ('a', 'b', 'g1', 'g2', 'c', 'd'),
        '4': ('f', 'g1', 'g2', 'b', 'c'),
        '5': ('a', 'f', 'g1', 'g2', 'c', 'd'),
        '6': ('a', 'f', 'g1', 'g2', 'e', 'c', 'd'),
        '7': ('a', 'b', 'c'),
        '8': ('a', 'b', 'c', 'd', 'e', 'f', 'g1', 'g2'),
        '9': ('a', 'b', 'f', 'g1', 'g2', 'c', 'd'),
        'N': ('f', 'e', 'h', 'm', 'b', 'c'),
    }
    mask = Image.new('L', (28 * 4, 44 * 4))
    draw = ImageDraw.Draw(mask)
    for segment in patterns[character]:
        draw.polygon([(x * 4, y * 4) for x, y in segments[segment]], fill=255)
    # Baked bevel: no added runtime layers or glow, and unchanged silhouette.
    highlight = ImageChops.subtract(mask, ImageChops.offset(mask, 2, 2))
    shadow = ImageChops.subtract(mask, ImageChops.offset(mask, -2, -2))
    glyph = Image.new('RGBA', mask.size, DISPLAY_COLOR)
    glyph = Image.composite(Image.new('RGBA', mask.size, (177, 113, 36, 255)), glyph, shadow)
    glyph = Image.composite(Image.new('RGBA', mask.size, (255, 247, 207, 255)), glyph, highlight)
    glyph.putalpha(mask)
    clean = Image.new('RGBA', mask.size)
    clean.alpha_composite(glyph)
    return resize(clean, (28, 44))


@lru_cache(maxsize=1)
def dashboard_digits():
    return [dashboard_glyph(str(value)) for value in range(10)]


@lru_cache(maxsize=1)
def date_tens_digits():
    # Same stencil face as the clock, tightly cropped for visual centring.
    digits = []
    for glyph in dashboard_digits()[:4]:
        glyph = glyph.crop(glyph.getbbox())
        digits.append(resize(glyph, (round(glyph.width * 58 / glyph.height), 58)))
    return digits


def black_time_window_mask(dark_background):
    # Flood only the dark art's inner LCD panel; keep the rounded bezel intact.
    candidate = dark_background.crop(TIME_WINDOW_BOX).convert('L').point(
        lambda value: 255 if value < 12 else 0)
    ImageDraw.floodfill(candidate, (322 - TIME_WINDOW_BOX[0], 350 - TIME_WINDOW_BOX[1]),
                       128, thresh=0)
    return candidate.point(lambda value: 255 if value == 128 else 0)


def instrument_background(original, strength=1.0):
    from instrument_art import depth_background
    centers = [((x - CROP[0]) * SCALE, (y - CROP[1]) * SCALE)
               for x, y in [*LABELS, DATE_ZERO_LABEL]]
    return depth_background(original, centers, strength)


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
        backgrounds.append(bg)
    # Match the AOD's black lower panel in high power. This is baked into the
    # background rather than covering the rounded frame with a runtime box.
    backgrounds[0].paste((0, 0, 0, 255), TIME_WINDOW_BOX,
                         black_time_window_mask(backgrounds[1]))
    for bg, dest in zip(backgrounds, ['background.png', 'background-dark.png']):
        bg.save(OUT / dest)
        window_name = 'window-dark.png' if 'dark' in dest else 'window.png'
        bg.crop((180, 81, 273, 185)).save(OUT / window_name)
    instrument_background(backgrounds[1]).save(OUT / 'instrument-active.png')
    instrument_background(backgrounds[1], .22).save(OUT / 'instrument-aod.png')
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
    glyphs = dashboard_digits()
    for i, glyph in enumerate(glyphs):
        glyph.save(OUT / f'digit-{i}.png')
    for i, glyph in enumerate(date_tens_digits()):
        glyph.save(OUT / f'date-tens-{i}.png')
    return backgrounds, overlays, needle, glyphs


def date_ink_bounds(glyphs):
    return [resize(g, (24, 42)).getchannel('A').point(
        lambda a: 255 if a > 128 else 0).getbbox() for g in glyphs]


def date_start_x(glyphs, day, month):
    bounds = date_ink_bounds(glyphs)
    # First and last visible strokes, not the 124px monospaced container.
    return 322 - (bounds[day // 10][0] + 100 + bounds[month % 10][2]) // 2


def time_display_hour(hour):
    return hour


def time_start_x(glyphs, hour):
    bounds = [resize(g, (24, 48)).getchannel('A').point(
        lambda a: 255 if a > 128 else 0).getbbox() for g in glyphs]
    return 322 - (bounds[hour // 10][0] + 100 + bounds[0][2]) // 2


def seconds_angle(second):
    def gauge(label):
        x, y = DATE_ZERO_LABEL if label == 0 else LABELS[label - 1]
        dx = (x - CROP[0]) * SCALE - PIVOT[0]
        dy = (y - CROP[1]) * SCALE - PIVOT[1]
        return math.atan2(-dx, dy) % math.tau
    second = min(60, max(0, second))
    if second == 60:
        return gauge(10)
    label = int(second // 6)
    return gauge(label) + (gauge(label + 1) - gauge(label)) * (second % 6) / 6


def full_day_start_x(day):
    return 196 if 10 <= day < 20 else 203


def motion_angle(start, target, elapsed, duration):
    t = min(1, max(0, elapsed / duration))
    return start + (target - start) * t * t * (3 - 2 * t)


def render(assets, hour, dark=False, minute=54, day=10, month=8, with_needle=True,
           date_gauge=False, second=None, needle_angle=None):
    backgrounds, overlays, needle, glyphs = assets
    canvas = backgrounds[int(dark)].copy()
    if date_gauge or second is not None:
        ones = day % 10
        x, y = DATE_ZERO_LABEL if ones == 0 else LABELS[ones - 1]
    else:
        dial_hour = hour % 12 or 12
        idx = dial_hour if dial_hour <= 10 else dial_hour - 10
        if dial_hour > 10:
            label, xy = overlays[idx - 1]
            canvas.alpha_composite(label, xy)
        x, y = LABELS[idx - 1]
    dx = (x - CROP[0]) * SCALE - PIVOT[0]
    dy = (y - CROP[1]) * SCALE - PIVOT[1]
    # Pillow's positive rotation is counter-clockwise; align down to target.
    angle = math.degrees(math.atan2(dx, dy))
    if second is not None:
        angle = -math.degrees(seconds_angle(second))
    if needle_angle is not None:
        angle = -math.degrees(needle_angle)
    layer = Image.new('RGBA', (SIZE, SIZE))
    layer.alpha_composite(needle, (PIVOT[0] - 34, PIVOT[1] - 34))
    layer = layer.rotate(angle, Image.Resampling.BICUBIC, center=PIVOT)
    if date_gauge or second is not None:
        if second is None:
            tens = date_tens_digits()[day // 10]
            canvas.alpha_composite(tens, (227 - tens.width // 2, 105))
        else:
            for digit, offset in [(day // 10, 0), (day % 10, 26)]:
                canvas.alpha_composite(resize(glyphs[digit], (22, 44)),
                                       (full_day_start_x(day) + offset, 112))
        display_hour = time_display_hour(hour)
        time_x = time_start_x(glyphs, hour)
        for digit, xx in [(display_hour // 10, time_x), (display_hour % 10, time_x + 28),
                          (minute // 10, time_x + 72), (minute % 10, time_x + 100)]:
            canvas.alpha_composite(resize(glyphs[digit], (24, 48)), (xx, 323))
        draw = ImageDraw.Draw(canvas)
        for y in (336, 354):
            draw.rectangle((time_x + 60, y, time_x + 63, y + 4), fill=DISPLAY_COLOR)
    else:
        for digit, xx in [(minute // 10, 196), (minute % 10, 230)]:
            canvas.alpha_composite(glyphs[digit], (xx, 108))
        # Legacy layout: minutes above, large DD-MM below.
        date_x = date_start_x(glyphs, day, month)
        for digit, xx in [(day // 10, date_x), (day % 10, date_x + 28),
                          (month // 10, date_x + 72), (month % 10, date_x + 100)]:
            canvas.alpha_composite(resize(glyphs[digit], (24, 42)), (xx, 326))
        ImageDraw.Draw(canvas).rectangle((date_x + 58, 346, date_x + 65, 349), fill=DISPLAY_COLOR)
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
    render(assets, 11).save(dest / 'legacy-light-preview.png')
    render(assets, 13, day=15, date_gauge=True).save(dest / 'light-preview.png')
    render(assets, 23, day=31, dark=True, date_gauge=True).save(dest / 'dark-preview.png')
    render(assets, 23, day=31, dark=True, date_gauge=True).save(dest / 'aod-preview.png')
    render(assets, 7, day=17, date_gauge=True).save(dest / 'needle-over-minutes-preview.png')
    render(assets, 0, minute=0, day=20, date_gauge=True).save(dest / 'date-zero-preview.png')
    dates = [1, 5, 7, 9, 10, 11, 15, 17, 20, 21, 27, 31]
    sheet = Image.new('RGB', (SIZE * 4, SIZE * 3), '#222222')
    for i, day in enumerate(dates):
        canvas = render(assets, 13, day=day, date_gauge=True)
        ImageDraw.Draw(canvas).text((190, 425), f'Date {day:02}', fill='white')
        sheet.paste(canvas, ((i % 4) * SIZE, (i // 4) * SIZE), canvas)
    sheet.save(dest / 'dates-preview.png')
    strip = Image.new('RGBA', (48 * 11, 72), (0, 0, 0, 255))
    for i, character in enumerate('N0123456789'):
        glyph = dashboard_glyph(character)
        strip.alpha_composite(resize(glyph, (38, 60)), (i * 48 + 5, 6))
    strip.save(dest / 'font-preview.png')
    instrument = ([Image.open(OUT / name).convert('RGBA')
                   for name in ['instrument-active.png', 'instrument-aod.png']], *assets[1:])
    render(instrument, 13, day=15, second=47).save(dest / 'seconds-active-preview.png')
    render(instrument, 13, day=15, second=47, dark=True).save(dest / 'seconds-aod-preview.png')
    # Design mockups only, not evidence of SDK frame rate or motor state.
    for name, start_second, target_second, duration in [
            ('rev', 8, 47, 500), ('return', 59, 0, 350)]:
        frames = [render(instrument, 13, day=15, second=target_second,
                         needle_angle=motion_angle(seconds_angle(start_second),
                                                   seconds_angle(target_second), ms, duration))
                  for ms in range(0, duration + 1, 50)]
        frames[0].save(dest / f'needle-{name}-preview.gif', save_all=True,
                       append_images=frames[1:], duration=[50] * (len(frames) - 1) + [1000],
                       loop=0, disposal=2)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', action='store_true')
    args = parser.parse_args()
    assets = prepare()
    if args.preview:
        preview(assets)
