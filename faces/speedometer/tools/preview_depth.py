#!/usr/bin/env python3
"""Static design comparisons, not simulator captures or AOD certification.

Reads existing resources; does not modify them. No live data is shown.
"""
from PIL import Image, ImageDraw, ImageFont
import prepare_assets as art

# Keep the preview/test interface while sharing the production asset generator.
depth_background = art.instrument_background


def load_assets():
    def image(name):
        with Image.open(art.OUT / name) as source:
            return source.convert('RGBA')

    backgrounds = [image('background.png'), image('background-dark.png')]
    overlays = [(image(f'red-{i}.png'),
                 (round((box[0] - art.CROP[0]) * art.SCALE),
                  round((box[1] - art.CROP[1]) * art.SCALE)))
                for i, box in enumerate(art.LABEL_BOXES, 1)]
    return backgrounds, overlays, image('needle.png'), [image(f'digit-{i}.png') for i in range(10)]


def render_background(assets, background):
    proposal = ([assets[0][0], background], *assets[1:])
    return art.render(proposal, 13, dark=True, minute=54, day=15, date_gauge=True)


def main():
    assets = load_assets()
    original = assets[0][1]
    backgrounds = [original, depth_background(original), depth_background(original, .22)]
    names = ['current', 'active', 'aod']
    labels = ['Current dark face', 'Proposed active: depth + amber light',
              'Proposed AOD: restrained light (unverified)']
    dest = art.ROOT / 'bin'
    dest.mkdir(exist_ok=True)
    sheet = Image.new('RGB', (art.SIZE * 3, art.SIZE + 42), '#111111')
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=15)
    for i, (background, name, label) in enumerate(zip(backgrounds, names, labels)):
        face = render_background(assets, background)
        face.save(dest / f'depth-{name}-preview.png')
        sheet.paste(face.convert('RGB'), (i * art.SIZE, 42))
        draw.text((i * art.SIZE + 12, 12), label, font=font, fill='#dfd1af')
    sheet.save(dest / 'depth-comparison.png')
    print(f'Design preview: {dest / "depth-comparison.png"}')
    print('Runtime resources and reference artwork were not changed.')


if __name__ == '__main__':
    main()
