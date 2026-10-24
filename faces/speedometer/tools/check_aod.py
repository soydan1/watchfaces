#!/usr/bin/env python3
"""Offline AOD screening, NOT a Garmin simulator or compliance test.

Samples all 31 dates at four times, plus four consecutive minute frames.
Reports gamma-encoded RGB-weighted luma and linear-sRGB luminance estimates;
neither formula is asserted to match Garmin's firmware calculation. Nonblack
coverage is a separate old-device metric, not the modern luminance budget.
Pillow rendering/colour conversion can differ from the real SDK framebuffer.
"""
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
    assets = art.prepare()
    mask = screen_mask()
    samples = []
    for day in range(1, 32):
        for hour, minute in [(0, 0), (8, 8), (18, 58), (23, 59)]:
            image = art.render(assets, hour, minute=minute, day=day, dark=True,
                               date_gauge=True, is24_hour=True)
            samples.append({'day': day, 'hour': hour, 'minute': minute,
                            **metrics(image, mask)})
    persistent = mask.copy()
    for minute in range(54, 58):
        image = art.render(assets, 13, minute=minute, day=15, dark=True,
                           date_gauge=True, is24_hour=True)
        persistent = ImageChops.darker(persistent, nonblack(image))
    persistent_count = persistent.histogram()[255]
    report = {
        'scope': 'Pillow image screening only; not SDK framebuffer or runtime measurements',
        'physical_screen_pixels_in_mask': mask.histogram()[255],
        'sample_count': len(samples),
        'clock_format': '24h',
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
    destination = art.ROOT / 'bin/aod-screening.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(report, indent=2) + '\n')
    persistent.save(art.ROOT / 'bin/aod-persistent-pixels.png')
    summary = {key: value for key, value in report.items() if key != 'samples'}
    print(json.dumps(summary, indent=2))
    print('Full report:', destination)


if __name__ == '__main__':
    main()
