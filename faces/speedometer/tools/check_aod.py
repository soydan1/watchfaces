#!/usr/bin/env python3
"""Offline AOD screening, NOT a Garmin simulator or compliance test.

Samples all 31 dates at four time/parked-position pairs, a 60-position sweep
on day 28, and four consecutive minute frames with one frozen needle.
--legacy screens the older date-gauge layout and original dark artwork.
Reports gamma-encoded RGB-weighted luma and linear-sRGB luminance estimates;
neither formula is asserted to match Garmin's firmware calculation. Nonblack
coverage is a separate old-device metric, not the modern luminance budget.
Pillow rendering/colour conversion can differ from the real SDK framebuffer.
"""
import argparse
import json
from PIL import Image, ImageChops, ImageDraw
import prepare_assets as art


def screen_mask():
    mask = Image.new('L', (art.SIZE, art.SIZE))
    ImageDraw.Draw(mask).ellipse((0, 0, art.SIZE - 1, art.SIZE - 1), fill=255)
    return mask


def nonblack(image):
    r, g, b = image.convert('RGB').split()
    return ImageChops.lighter(ImageChops.lighter(r, g), b).point(
        lambda value: 255 if value else 0)


def srgb_to_linear(value):
    value /= 255
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def metrics(image, mask):
    pixels = mask.histogram()[255]
    histogram = image.convert('RGB').histogram(mask)
    encoded = linear = 0.0
    for channel, weight in enumerate((0.2126, 0.7152, 0.0722)):
        bins = histogram[channel * 256:(channel + 1) * 256]
        encoded += weight * sum(count * value / 255 for value, count in enumerate(bins)) / pixels
        linear += weight * sum(count * srgb_to_linear(value) for value, count in enumerate(bins)) / pixels
    return {
        'encoded_rgb_luma_percent_estimate': encoded * 100,
        'linear_srgb_luminance_percent_estimate': linear * 100,
        'nonblack_pixels_percent': nonblack(image).histogram(mask)[255] / pixels * 100,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--legacy', action='store_true')
    args = parser.parse_args()
    assets = art.prepare()
    if not args.legacy:
        assets[0][1] = Image.open(art.OUT / 'instrument-aod.png').convert('RGBA')

    def frame(hour, minute, day, parked):
        return art.render(assets, hour, minute=minute, day=day, dark=True,
                          date_gauge=True, second=None if args.legacy else parked)

    mask = screen_mask()
    samples = []
    for day in range(1, 32):
        for hour, minute, parked in [(0, 0, 0), (8, 8, 20), (18, 58, 40), (23, 59, 59)]:
            image = frame(hour, minute, day, parked)
            samples.append({'day': day, 'hour': hour, 'minute': minute,
                            'parked_second': None if args.legacy else parked,
                            **metrics(image, mask)})
    if not args.legacy:
        for parked in range(60):
            image = frame(23, 59, 28, parked)
            samples.append({'day': 28, 'hour': 23, 'minute': 59,
                            'parked_second': parked, **metrics(image, mask)})
    persistent = mask.copy()
    for minute in range(54, 58):
        image = frame(13, minute, 15, 47)
        persistent = ImageChops.darker(persistent, nonblack(image))
    persistent_count = persistent.histogram()[255]
    report = {
        'scope': 'Pillow image screening only; not SDK framebuffer or runtime measurements',
        'physical_screen_pixels_in_mask': mask.histogram()[255],
        'sample_count': len(samples),
        'clock_format': '24h',
        'layout': 'legacy date gauge' if args.legacy else 'full day / parked seconds needle',
        'background': 'original dark' if args.legacy else 'instrument AOD',
        'four_minute_parked_second': None if args.legacy else 47,
        'sampling': 'Not exhaustive across all date/time/parked-angle combinations',
        'minimum_estimates': {key: min(row[key] for row in samples)
                              for key in metrics(image, mask)},
        'maximum_estimates': {key: max(row[key] for row in samples)
                              for key in metrics(image, mask)},
        'highest_encoded_luma_sample': max(samples, key=lambda row: row['encoded_rgb_luma_percent_estimate']),
        'four_minute_samples': ['13:54 day 15', '13:55 day 15', '13:56 day 15', '13:57 day 15'],
        'pixels_nonblack_in_all_four_samples': persistent_count,
        'persistent_screen_percent': persistent_count / mask.histogram()[255] * 100,
        'compliance': 'NOT ESTABLISHED: requires signed PRG, device-specific simulator metrics, and runtime tests',
        'samples': samples,
    }
    stem = 'aod-legacy' if args.legacy else 'aod'
    destination = art.ROOT / f'bin/{stem}-screening.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(report, indent=2) + '\n')
    persistent.save(art.ROOT / f'bin/{stem}-persistent-pixels.png')
    summary = {key: value for key, value in report.items() if key != 'samples'}
    print(json.dumps(summary, indent=2))
    print('Full report:', destination)


if __name__ == '__main__':
    main()
