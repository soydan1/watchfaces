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
            self.assertEqual(background.getpixel((0, 0))[3], 0)
            self.assertEqual(background.getpixel(art.PIVOT)[3], 255)
        self.assertEqual(self.assets[2].size, (68, 160))
        for digit in self.assets[3]:
            self.assertEqual(digit.size, (20, 29))
            self.assertIsNotNone(digit.getbbox())
        self.assertEqual(len({g.tobytes() for g in self.assets[3]}), 10)

    def test_window_patch_exactly_matches_background(self):
        for background, filename in zip(self.assets[0], ['window.png', 'window-dark.png']):
            patch = Image.open(art.OUT / filename).convert('RGBA')
            self.assertIsNone(ImageChops.difference(
                patch, background.crop((184, 94, 269, 189))).getbbox())

    def test_artwork_angles_match_monkeyc_constants(self):
        source = (art.ROOT / 'source/SpeedometerGeometry.mc').read_text()
        angles = re.search(r'var angles = \[(.*?)\];', source, re.S).group(1)
        angles = [float(v.strip().rstrip('f')) for v in angles.split(',')]
        self.assertEqual(len(angles), 10)
        for (x, y), actual in zip(art.LABELS, angles):
            dx = (x - art.CROP[0]) * art.SCALE - art.PIVOT[0]
            dy = (y - art.CROP[1]) * art.SCALE - art.PIVOT[1]
            expected = math.atan2(-dx, dy)
            delta = math.atan2(math.sin(actual - expected), math.cos(actual - expected))
            self.assertAlmostEqual(delta, 0, places=6)

    def test_red_overlay_registration(self):
        expected = [(173, 355), (100, 317)]
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
                # The entire minute window is identical at every hour:
                # needle rotation must never obscure its bezel or digits.
                baseline = art.render(self.assets, 1, dark)
                self.assertIsNone(ImageChops.difference(
                    im.crop((184, 94, 269, 189)),
                    baseline.crop((184, 94, 269, 189))).getbbox())

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
