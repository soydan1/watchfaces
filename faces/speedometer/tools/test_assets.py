"""Offline asset/layout checks; these do not replace Connect IQ runtime tests."""
import math
import re
import unittest
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops, ImageDraw
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
        self.assertLess(source.index('drawDateGauge(dc, clock.hour'), needle)
        self.assertLess(source.index('drawLegacyLayout(dc, clock.hour'), needle)
        self.assertNotIn('dc.drawBitmap(180, 81', source)

    def test_solid_segments_and_larger_layout(self):
        eight = self.assets[3][8]
        # An uninterrupted top bar, not a series of dots.
        for x in range(7, 22):
            self.assertGreater(eight.getpixel((x, 3))[3], 240)
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
        self.assertTrue(any(g > 235 for r, g, b, a in colors))  # lit edge
        self.assertTrue(any(r < 220 for r, g, b, a in colors))  # shadow edge
        self.assertTrue(any(r > 245 and 210 < g < 235 and b > 120 for r, g, b, a in colors))

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

    def test_date_tens_use_the_same_stencil_font_as_time(self):
        glyphs = art.date_tens_digits()
        self.assertEqual(len(glyphs), 4)
        for glyph in glyphs:
            self.assertEqual(glyph.height, 58)
            self.assertIsNotNone(glyph.getbbox())
            x = 227 - glyph.width // 2
            self.assertGreaterEqual(x, 193)
            self.assertLessEqual(x + glyph.width, 261)
        self.assertEqual(len({g.tobytes() for g in glyphs}), 4)
        for actual, source in zip(glyphs, self.assets[3]):
            source = source.crop(source.getbbox())
            expected = art.resize(source, actual.size)
            self.assertIsNone(ImageChops.difference(actual, expected).getbbox())

    def test_zero_date_angle_points_to_printed_zero(self):
        source = (art.ROOT / 'source/SpeedometerGeometry.mc').read_text()
        actual = float(re.search(r'const DATE_ZERO_ANGLE = ([\d.]+)f;', source).group(1))
        x, y = art.DATE_ZERO_LABEL
        dx = (x - art.CROP[0]) * art.SCALE - art.PIVOT[0]
        dy = (y - art.CROP[1]) * art.SCALE - art.PIVOT[1]
        self.assertAlmostEqual(actual, math.atan2(-dx, dy), places=6)

    def test_every_date_on_both_themes(self):
        for dark in [False, True]:
            baseline = art.render(self.assets, 13, day=1, dark=dark, date_gauge=True)
            for day in range(1, 32):
                image = art.render(self.assets, 13, day=day, dark=dark, date_gauge=True)
                self.assertEqual(image.size, (454, 454))
                # Date changes must not alter the digital time or its alignment.
                self.assertIsNone(ImageChops.difference(
                    image.crop((250, 300, 390, 400)),
                    baseline.crop((250, 300, 390, 400))).convert('RGB').getbbox())
                # No legacy red 1/2 hour highlights in date-gauge mode.
                for box in [(168, 368, 195, 413), (87, 326, 131, 373)]:
                    clean = art.render(self.assets, 13, day=day, dark=dark,
                                       date_gauge=True, with_needle=False)
                    self.assertIsNone(ImageChops.difference(
                        clean.crop(box), self.assets[0][int(dark)].crop(box)
                    ).convert('RGB').getbbox())
        properties = ET.parse(art.ROOT / 'resources/settings/properties.xml').getroot()
        self.assertEqual(properties.find("property[@id='DateGauge']").text, 'true')

    def test_digital_time_is_fixed_24_hour_and_centered(self):
        bounds = [art.resize(g, (24, 48)).getchannel('A').point(
            lambda a: 255 if a > 128 else 0).getbbox() for g in self.assets[3]]
        for hour in range(24):
            display = art.time_display_hour(hour)
            self.assertEqual(display, hour)
            x = art.time_start_x(self.assets[3], hour)
            self.assertEqual(x, 252 if 10 <= display < 20 else 260)
            for minute in [0, 1, 9, 10, 59]:
                left = x + bounds[display // 10][0]
                right = x + 100 + bounds[minute % 10][2]
                self.assertLessEqual(abs((left + right) / 2 - 322), 0.5)
                self.assertGreaterEqual(left, 257)
                self.assertLessEqual(right, 389)
        source = (art.ROOT / 'source/SpeedometerView.mc').read_text()
        self.assertNotIn('is24Hour', source)

    def test_black_lower_window_preserves_the_rounded_frame(self):
        mask = art.black_time_window_mask(self.assets[0][1])
        self.assertGreater(mask.histogram()[255], 10000)
        self.assertEqual(mask.getpixel((0, 0)), 0)
        box = mask.getbbox()
        self.assertGreater(box[0], 0)
        self.assertGreater(box[1], 0)
        self.assertLess(box[2], mask.width)
        self.assertLess(box[3], mask.height)
        light = self.assets[0][0].crop(art.TIME_WINDOW_BOX).convert('RGB')
        selected = Image.composite(light, Image.new('RGB', light.size), mask)
        self.assertIsNone(selected.getbbox())

    def test_stencil_font_has_split_strokes_like_the_N_reference(self):
        eight = self.assets[3][8]
        self.assertLess(eight.getpixel((14, 22))[3], 30)
        self.assertGreater(eight.getpixel((8, 22))[3], 240)
        self.assertGreater(eight.getpixel((20, 22))[3], 240)
        neutral = art.dashboard_glyph('N')
        self.assertEqual(neutral.size, eight.size)
        self.assertNotEqual(neutral.tobytes(), eight.tobytes())

    def test_wake_timing_and_eligibility_match_runtime_constants(self):
        source = (art.ROOT / 'source/WakeFade.mc').read_text()
        constants = {key: int(value) for key, value in re.findall(
            r'const (\w+) = (\d+);', source)}
        self.assertEqual(constants['DURATION_MS'], art.WAKE_DURATION_MS)
        self.assertEqual(constants['INTERVAL_MS'], art.WAKE_INTERVAL_MS)
        self.assertEqual(constants['LAST_FRAME'], art.WAKE_LAST_FRAME)
        phases = [art.wake_frame_index(ms) for ms in range(-50, 401)]
        self.assertEqual(phases, sorted(phases))
        self.assertEqual(set(phases), set(range(7)))
        self.assertEqual([art.wake_frame_index(ms) for ms in range(0, 301, 50)],
                         list(range(7)))
        for flags in range(16):
            self.assertEqual(art.wake_allowed(bool(flags & 1), bool(flags & 2),
                                             bool(flags & 4), bool(flags & 8)), flags == 6)

    def test_wake_background_frames_and_endpoints(self):
        light, dark = self.assets[0]
        self.assertEqual(art.wake_background(dark, light, 0).tobytes(), dark.tobytes())
        self.assertEqual(art.wake_background(dark, light, 6).tobytes(), light.tobytes())
        lower = ImageChops.darker(light.convert('RGB'), dark.convert('RGB'))
        upper = ImageChops.lighter(light.convert('RGB'), dark.convert('RGB'))
        for frame in range(1, 6):
            actual = Image.open(art.OUT / f'wake-{frame}.png').convert('RGBA')
            expected = art.wake_background(dark, light, frame)
            self.assertEqual(actual.tobytes(), expected.tobytes())
            self.assertEqual(actual.size, (454, 454))
            self.assertIsNone(ImageChops.subtract(lower, actual.convert('RGB')).getbbox())
            self.assertIsNone(ImageChops.subtract(actual.convert('RGB'), upper).getbbox())

    def test_wake_keeps_time_and_needle_stationary(self):
        baseline = art.render(self.assets, 13, day=15, date_gauge=True, wake_frame=0)
        # Compare opaque foreground ink, not the bezel or anti-aliased edges
        # whose underlying background is intentionally changing during a fade.
        ink = Image.new('L', (454, 454))
        x = art.time_start_x(self.assets[3], 13)
        for digit, offset in [(1, 0), (3, 28), (5, 72), (4, 100)]:
            alpha = art.resize(self.assets[3][digit], (24, 48)).getchannel('A').point(
                lambda a: 255 if a == 255 else 0)
            ink.paste(alpha, (x + offset, 323))
        draw = ImageDraw.Draw(ink)
        for y in [336, 354]:
            draw.rectangle((x + 60, y, x + 63, y + 4), fill=255)
        self.assertGreater(ink.histogram()[255], 0)
        for frame in range(1, 7):
            actual = art.render(self.assets, 13, day=15, date_gauge=True, wake_frame=frame)
            diff = ImageChops.difference(actual.convert('RGB'), baseline.convert('RGB'))
            self.assertIsNone(ImageChops.multiply(diff, ink.convert('RGB')).getbbox())
            self.assertEqual(actual.getpixel(art.PIVOT), baseline.getpixel(art.PIVOT))

    def test_wake_lifecycle_guards_and_cancellation_wiring(self):
        source = (art.ROOT / 'source/SpeedometerView.mc').read_text()
        sleep = source.split('function onEnterSleep()')[1].split('function onExitSleep()')[0]
        hide = source.split('function onHide()')[1].split('function onEnterSleep()')[0]
        wake = source.split('function onExitSleep()')[1].split('private function isLowPower()')[0]
        tick = source.split('function onWakeFadeTick()')[1].split('private function drawBackground(')[0]
        draw = source.split('private function drawBackground(')[1].split('function onUpdate(')[0]
        stop = source.split('private function stopWakeFade()')[1].split('function onWakeFadeTick()')[0]
        self.assertIn('stopWakeFade();', sleep)
        self.assertIn('stopWakeFade();', hide)
        self.assertIn('_fade.queue();', wake)
        self.assertNotIn('timer.start(', wake)
        self.assertNotIn('timer.start(', tick)
        self.assertIn('canAnimateWake(lowPower)', tick)
        self.assertIn('stopWakeFade();', tick)
        self.assertIn('_wakeTimer.stop();', stop)
        self.assertIn('_fade.cancel();', stop)
        self.assertIn('_wakeFrame = null;', stop)
        self.assertEqual(source.count('timer.start('), 1)
        self.assertLess(draw.index('_fade.advance('), draw.index('timer.start('))
        self.assertLess(draw.index('if (_fade.isActive())'), draw.index('timer.start('))
        self.assertIn('System.getDisplayMode() != System.DISPLAY_MODE_HIGH_POWER', source)
        properties = ET.parse(art.ROOT / 'resources/settings/properties.xml').getroot()
        self.assertEqual(properties.find("property[@id='WakeFade']").text, 'true')

    def test_aod_screening_metrics_on_known_colors(self):
        from check_aod import metrics, screen_mask
        mask = screen_mask()
        for color, expected in [('black', 0), ('white', 100), ('red', 21.26)]:
            result = metrics(Image.new('RGB', (454, 454), color), mask)
            self.assertAlmostEqual(result['encoded_rgb_luma_percent_estimate'], expected)
            self.assertAlmostEqual(result['linear_srgb_luminance_percent_estimate'], expected)
            self.assertEqual(result['nonblack_pixels_percent'], 0 if color == 'black' else 100)
        gray = metrics(Image.new('RGB', (454, 454), (128, 128, 128)), mask)
        self.assertAlmostEqual(gray['encoded_rgb_luma_percent_estimate'], 128 / 255 * 100)
        self.assertAlmostEqual(gray['linear_srgb_luminance_percent_estimate'], 21.586050011389926)

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
