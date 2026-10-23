"""Offline asset/layout checks; these do not replace Connect IQ runtime tests."""
import math
import re
import unittest
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops
import prepare_assets as art


class AssetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets = art.prepare()

    def test_bitmap_resources_exist_and_are_packed(self):
        root = ET.parse(art.OUT / 'drawables.xml').getroot()
        for bitmap in root:
            file = art.OUT / bitmap.attrib['filename']
            self.assertTrue(file.is_file(), str(file))
            if file.suffix == '.png':
                self.assertEqual(bitmap.attrib['packingFormat'], 'png')
                with Image.open(file) as im:
                    im.verify()
            self.assertNotIn('reference', str(file))

    def test_dimensions_and_round_crop(self):
        for background in self.assets[0]:
            self.assertEqual(background.size, (454, 454))
            self.assertEqual(background.getpixel((0, 0)), (0, 0, 0, 255))
            self.assertEqual(background.getpixel(art.PIVOT)[3], 255)
        self.assertEqual(self.assets[2].size, (68, 160))
        for digit in self.assets[3]:
            self.assertEqual(digit.size, (28, 44))
            self.assertIsNotNone(digit.getbbox())
        self.assertEqual(len({g.tobytes() for g in self.assets[3]}), 10)

    def test_window_patch_exactly_matches_background(self):
        for background, filename in zip(self.assets[0], ['window.png', 'window-dark.png']):
            patch = Image.open(art.OUT / filename).convert('RGBA')
            self.assertIsNone(ImageChops.difference(
                patch, background.crop((180, 81, 273, 185))).convert('RGB').getbbox())

    def test_artwork_angles_match_monkeyc_constants(self):
        source = (art.ROOT / 'source/SpeedometerGeometry.mc').read_text()
        angles = re.search(r'_angles as Array<Float> = \[(.*?)\];', source, re.S).group(1)
        angles = [float(v.strip().rstrip('f')) for v in angles.split(',')]
        self.assertEqual(len(angles), 10)
        for (x, y), actual in zip(art.LABELS, angles):
            dx = (x - art.CROP[0]) * art.SCALE - art.PIVOT[0]
            dy = (y - art.CROP[1]) * art.SCALE - art.PIVOT[1]
            expected = math.atan2(-dx, dy)
            delta = math.atan2(math.sin(actual - expected), math.cos(actual - expected))
            self.assertAlmostEqual(delta, 0, places=6)

    def test_red_overlay_registration(self):
        expected = [(168, 368), (87, 326)]
        for (overlay, xy), position in zip(self.assets[1], expected):
            self.assertEqual(xy, position)
            self.assertTrue(any(overlay.getpixel((x, y))[0] > 200
                                and overlay.getpixel((x, y))[1] < 80
                                and overlay.getpixel((x, y))[3] > 128
                                for y in range(overlay.height)
                                for x in range(overlay.width)))

    def test_all_hour_theme_compositions(self):
        for dark in [False, True]:
            for hour in range(1, 13):
                im = art.render(self.assets, hour, dark)
                self.assertEqual(im.size, (454, 454))
            # At seven, the pointer MUST obscure part of the minute display.
            im = art.render(self.assets, 7, dark)
            baseline = art.render(self.assets, 7, dark, with_needle=False)
            self.assertIsNotNone(ImageChops.difference(
                im.crop((196, 108, 258, 152)),
                baseline.crop((196, 108, 258, 152))).convert('RGB').getbbox())
        source = (art.ROOT / 'source/SpeedometerView.mc').read_text()
        needle = source.index('if (_needle != null)')
        self.assertLess(source.index('drawPair(dc, clock.min'), needle)
        self.assertLess(source.index('drawPair(dc, date.month'), needle)
        self.assertNotIn('dc.drawBitmap(180, 81', source)

    def test_solid_segments_and_larger_layout(self):
        eight = self.assets[3][8]
        # An uninterrupted top bar, not a series of dots.
        for x in range(7, 22):
            self.assertGreater(eight.getpixel((x, 4))[3], 240)
        # 4 must be as tall as 5, despite lacking top and bottom bars.
        heights = [g.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox()
                   for g in self.assets[3]]
        self.assertEqual(len({box[3] - box[1] for box in heights}), 1)
        # All month/day pairs fit a 124x42 date band within the lower window.
        for day, month in [(1, 1), (9, 8), (10, 10), (28, 2), (31, 12)]:
            image = art.render(self.assets, 1, day=day, month=month)
            reference = self.assets[0][0]
            region = ImageChops.difference(image, reference).convert('RGB')
            box = region.crop((250, 300, 390, 400)).getbbox()
            self.assertIsNotNone(box)
            self.assertGreaterEqual(box[0] + 250, 260)
            self.assertLessEqual(box[2] + 250, 384)
            self.assertGreaterEqual(box[1] + 300, 326)
            self.assertLessEqual(box[3] + 300, 368)
            self.assertGreaterEqual(box[3] - box[1], 41)

    def test_bevel_is_baked_into_digit_assets(self):
        eight = self.assets[3][8]
        colors = [eight.getpixel((x, y)) for y in range(44) for x in range(28)
                  if eight.getpixel((x, y))[3] > 240]
        self.assertTrue(any(g > 110 for r, g, b, a in colors))  # lit edge
        self.assertTrue(any(r < 220 for r, g, b, a in colors))  # shadow edge
        self.assertTrue(any(r > 245 and 50 < g < 90 for r, g, b, a in colors))

    def test_date_visible_strokes_are_centered(self):
        bounds = art.date_ink_bounds(self.assets[3])
        source = (art.ROOT / 'source/SpeedometerGeometry.mc').read_text()
        constants = {key: int(value) for key, value in re.findall(
            r'const (DATE_\w+) = (\d+);', source)}
        for day in range(1, 32):
            for month in range(1, 13):
                x = art.date_start_x(self.assets[3], day, month)
                expected = constants['DATE_X_LEADING_ONE'] if 10 <= day < 20 else constants['DATE_X_NORMAL']
                self.assertEqual(x, expected)
                left = x + bounds[day // 10][0]
                right = x + 100 + bounds[month % 10][2]
                self.assertLessEqual(abs((left + right) / 2 - constants['DATE_CENTER_X']), 0.5)

    def test_manifest_is_separate_d2mach2_app(self):
        ns = {'iq': 'http://www.garmin.com/xml/connectiq'}
        new = ET.parse(art.ROOT / 'manifest.xml').find('iq:application', ns)
        old = ET.parse(art.ROOT.parent / 'slim-dial/manifest.xml').find('iq:application', ns)
        self.assertNotEqual(new.attrib['id'], old.attrib['id'])
        self.assertEqual(new.find('iq:products/iq:product', ns).attrib['id'], 'd2mach2')
        for file in (art.ROOT / 'resources').rglob('*.xml'):
            ET.parse(file)


if __name__ == '__main__':
    unittest.main()
