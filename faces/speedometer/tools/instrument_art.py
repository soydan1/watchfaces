"""Offline baked instrument lighting. No runtime buffers or animation assets."""
import math
from PIL import Image, ImageChops, ImageDraw, ImageFilter


def panel_mask():
    mask = Image.new('L', (454, 454))
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((194, 95, 259, 173), radius=4, fill=255)
    draw.rounded_rectangle((255, 299, 389, 404), radius=28, fill=255)
    return mask


def marking_mask(original, centers):
    regions = Image.new('L', original.size)
    draw = ImageDraw.Draw(regions)
    for x, y in centers:
        draw.rectangle((x - 30, y - 26, x + 30, y + 26), fill=255)
    draw.ellipse((0, 0, 453, 453), outline=255, width=17)
    ink = original.convert('L').point(lambda value: max(0, min(255, (value - 80) * 5)))
    return ImageChops.multiply(regions, ink)


def tint(canvas, mask, color, opacity=1.0):
    light = Image.new('RGBA', canvas.size, (*color, 255))
    light.putalpha(mask.point(lambda value: round(value * opacity)))
    canvas.alpha_composite(light)


def depth_background(original, centers, strength=1.0):
    if not 0 <= strength <= 1:
        raise ValueError('Lighting strength must be between zero and one')
    if original.size != (454, 454):
        raise ValueError('Instrument artwork requires the 454px prepared plate')
    canvas = original.copy()
    panels = panel_mask()
    pixels = canvas.load()
    panel_pixels = panels.load()
    ink = marking_mask(original, centers)
    warm_ink = Image.new('RGBA', canvas.size)
    ink_pixels = warm_ink.load()
    for y in range(454):
        for x in range(454):
            r, g, b, _ = pixels[x, y]
            radius = math.hypot(x - 227, y - 227)
            highlight = math.exp(-((x - 130) / 175) ** 2 - ((y - 75) / 145) ** 2)
            if radius < 213 and not panel_pixels[x, y] and max(r, g, b) < 65:
                ambient = (2 + 5 * (1 - radius / 225) + 7 * highlight) * (1 - max(r, g, b) / 65)
                pixels[x, y] = (round(r + ambient * .85), round(g + ambient * .9),
                                round(b + ambient), 255)
            ink_pixels[x, y] = (round(169 + 36 * highlight), round(154 + 36 * highlight),
                                round(121 + 28 * highlight), 255)
    tint(canvas, ink.filter(ImageFilter.GaussianBlur(2.2)), (222, 155, 62), .10)
    warm_ink.putalpha(ink)
    canvas.alpha_composite(warm_ink)
    tint(canvas, ImageChops.subtract(ink, ImageChops.offset(ink, 1, 1)),
         (255, 233, 185), .45)
    tint(canvas, ImageChops.subtract(ink, ImageChops.offset(ink, -1, -1)),
         (42, 30, 17), .55)
    tint(canvas, panels.filter(ImageFilter.GaussianBlur(5)), (199, 122, 36), .09)
    # Diffuse illumination, independent of the digits shown on the LCD.
    backlight = Image.new('RGBA', canvas.size, (0, 0, 0, 255))
    pixels = backlight.load()
    for y in range(95, 405):
        for x in range(194, 390):
            if panel_pixels[x, y]:
                cx, cy, rx, ry = (227, 136, 39, 52) if y < 200 else (322, 348, 80, 66)
                light = max(0, 1 - ((x - cx) / rx) ** 2 - ((y - cy) / ry) ** 2)
                pixels[x, y] = (round(3 + 16 * light), round(2 + 9 * light),
                                round(1 + 2 * light), 255)
    canvas.paste(backlight, (0, 0), panels)
    glass = Image.new('RGBA', canvas.size)
    draw = ImageDraw.Draw(glass)
    draw.polygon([(195, 96), (258, 96), (258, 108), (195, 132)], fill=(255, 222, 154, 5))
    draw.polygon([(260, 301), (378, 301), (354, 313), (257, 336)], fill=(255, 222, 154, 4))
    glass.putalpha(ImageChops.multiply(glass.getchannel('A'), panels))
    canvas.alpha_composite(glass)
    edges = Image.new('RGBA', canvas.size)
    draw = ImageDraw.Draw(edges)
    draw.rounded_rectangle((192, 93, 261, 175), radius=5, outline=(0, 0, 0, 210), width=2)
    draw.line([(195, 94), (257, 94), (260, 97)], fill=(232, 193, 119, 65), width=1)
    draw.rounded_rectangle((253, 297, 391, 406), radius=29, outline=(0, 0, 0, 180), width=2)
    draw.arc((254, 298, 312, 356), 180, 270, fill=(225, 181, 105, 65), width=1)
    draw.line((283, 298, 361, 298), fill=(225, 181, 105, 40), width=1)
    canvas.alpha_composite(edges)
    circle = Image.new('L', canvas.size)
    ImageDraw.Draw(circle).ellipse((0, 0, 453, 453), fill=255)
    canvas = Image.composite(canvas, Image.new('RGBA', canvas.size, (0, 0, 0, 255)), circle)
    return Image.blend(original, canvas, strength)
