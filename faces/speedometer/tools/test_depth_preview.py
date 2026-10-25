"""Offline proposal checks, not Garmin rendering or AOD certification."""
import unittest
from PIL import Image, ImageChops, ImageDraw, ImageStat
import prepare_assets as art
import preview_depth as concept


class DepthPreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets = concept.load_assets()
        cls.original = cls.assets[0][1]
        cls.original_bytes = cls.original.tobytes()
        cls.active = concept.depth_background(cls.original)
        cls.aod = concept.depth_background(cls.original, .22)

    def test_strength_and_original_preserved(self):
        self.assertEqual(self.original.tobytes(), self.original_bytes)
        self.assertEqual(concept.depth_background(self.original, 0).tobytes(),
                         self.original_bytes)
        for filename, expected in [('instrument-active.png', self.active),
                                   ('instrument-aod.png', self.aod)]:
            with Image.open(art.OUT / filename) as actual:
                self.assertEqual(actual.convert('RGBA').tobytes(), expected.tobytes())
        for strength in [-.1, 1.1]:
            with self.assertRaises(ValueError):
                concept.depth_background(self.original, strength)

    def test_round_black_exterior_and_opacity(self):
        circle = Image.new('L', self.original.size)
        ImageDraw.Draw(circle).ellipse((0, 0, 453, 453), fill=255)
        outside = ImageChops.invert(circle).convert('RGB')
        for background in [self.active, self.aod]:
            self.assertEqual(background.size, (454, 454))
            self.assertEqual(background.getchannel('A').getextrema(), (255, 255))
            self.assertIsNone(ImageChops.multiply(background.convert('RGB'), outside).getbbox())

    def test_foreground_ink_and_needle_unchanged(self):
        transparent = Image.new('RGBA', self.original.size)
        foreground = concept.render_background(self.assets, transparent)
        opaque = foreground.getchannel('A').point(lambda value: 255 if value == 255 else 0)
        self.assertGreater(opaque.histogram()[255], 0)
        original = concept.render_background(self.assets, self.original).convert('RGB')
        for background in [self.active, self.aod]:
            proposed = concept.render_background(self.assets, background).convert('RGB')
            difference = ImageChops.difference(original, proposed)
            self.assertIsNone(ImageChops.multiply(difference, opaque.convert('RGB')).getbbox())

    def test_aod_proposal_is_more_restrained(self):
        # Relative image brightness only; not a device power-budget test.
        levels = [ImageStat.Stat(image.convert('L')).mean[0]
                  for image in [self.original, self.aod, self.active]]
        self.assertLess(levels[0], levels[1])
        self.assertLess(levels[1], levels[2])


if __name__ == '__main__':
    unittest.main()
