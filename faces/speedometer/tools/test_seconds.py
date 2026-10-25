"""Offline seconds-layout/geometry/wiring tests, not Monkey C execution."""
import math
import re
import unittest
import xml.etree.ElementTree as ET
from PIL import ImageChops
import prepare_assets as art
import preview_depth


class SecondsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets = preview_depth.load_assets()
        cls.assets[0][0] = preview_depth.depth_background(cls.assets[0][1])
        cls.assets[0][1] = preview_depth.depth_background(cls.assets[0][1], .22)

    def test_seconds_follow_calibrated_monotonic_arc(self):
        source = (art.ROOT / 'source/SpeedometerGeometry.mc').read_text()
        values = re.search(r'_angles as Array<Float> = \[(.*?)\];', source, re.S).group(1)
        angles = [float(value.strip().rstrip('f')) for value in values.split(',')]
        zero = float(re.search(r'DATE_ZERO_ANGLE = ([\d.]+)f', source).group(1))
        native = [zero] + [angle + 6.2831853 if angle < 0 else angle for angle in angles]
        previous = -math.inf
        for second in range(61):
            label = min(second // 6, 9)
            fraction = (second - label * 6) / 6
            expected = native[label] + (native[label + 1] - native[label]) * fraction
            actual = art.seconds_angle(second)
            self.assertAlmostEqual(actual, expected, places=6)
            self.assertGreater(actual, previous)
            previous = actual
        for label in range(11):
            self.assertAlmostEqual(art.seconds_angle(label * 6), native[label], places=6)

    def test_full_day_is_centered_inside_upper_window(self):
        glyphs = art.dashboard_digits()
        bounds = [art.resize(g, (22, 44)).getchannel('A').point(
            lambda value: 255 if value > 128 else 0).getbbox() for g in glyphs]
        for day in range(1, 32):
            x = art.full_day_start_x(day)
            left = x + bounds[day // 10][0]
            right = x + 26 + bounds[day % 10][2]
            self.assertLessEqual(abs((left + right) / 2 - 227), .5)
            self.assertGreaterEqual(left, 194)
            self.assertLessEqual(right, 259)

    def test_both_modes_and_foreground_needle(self):
        for dark in [False, True]:
            for second in range(60):
                image = art.render(self.assets, 13, day=15, second=second, dark=dark)
                self.assertEqual(image.size, (454, 454))
            image = art.render(self.assets, 13, day=15, second=42, dark=dark)
            baseline = art.render(self.assets, 13, day=15, second=42, dark=dark,
                                  with_needle=False)
            self.assertIsNotNone(ImageChops.difference(image, baseline).convert('RGB').crop(
                (194, 95, 260, 174)).getbbox())

    def test_motion_preview_is_bounded_and_reverses_without_spin(self):
        for start, target, duration in [(8, 47, 500), (59, 0, 350)]:
            first, last = art.seconds_angle(start), art.seconds_angle(target)
            samples = [art.motion_angle(first, last, ms, duration)
                       for ms in range(0, duration + 1, 50)]
            self.assertEqual(samples[0], first)
            self.assertAlmostEqual(samples[-1], last)
            self.assertEqual(samples, sorted(samples, reverse=first > last))
            self.assertTrue(all(min(first, last) <= angle <= max(first, last) for angle in samples))

    def test_timer_and_park_lifecycle_wiring(self):
        source = (art.ROOT / 'source/SpeedometerView.mc').read_text()
        for begin, end in [('onHide()', 'onEnterSleep()'), ('onEnterSleep()', 'onExitSleep()')]:
            body = source.split('function ' + begin)[1].split('function ' + end)[0]
            self.assertIn('stopMotionTimer();', body)
            self.assertIn('_motor.park();', body)
        timer = source.split('private function updateMotionTimer(')[1].split('function onUpdate(')[0]
        self.assertLess(timer.index('lowPower || isLowPower() || !_visible'), timer.index('timer.start('))
        self.assertLess(timer.index('!secondsMode || !_motor.isMoving()'), timer.index('timer.start('))
        self.assertEqual(source.count('timer.start('), 1)
        wake = source.split('function onExitSleep()')[1].split('private function isLowPower()')[0]
        self.assertNotIn('timer.start(', wake)
        self.assertIn('_motor.wake();', wake)
        self.assertIn('clock.sec, lowPower || !_visible', source)
        self.assertIn('!= System.DISPLAY_MODE_HIGH_POWER', source)

    def test_new_defaults_and_existing_layouts_retained(self):
        props = ET.parse(art.ROOT / 'resources/settings/properties.xml').getroot()
        for name in ['SecondsNeedle', 'InstrumentLighting', 'DateGauge']:
            self.assertEqual(props.find(f"property[@id='{name}']").text, 'true')
        source = (art.ROOT / 'source/SpeedometerView.mc').read_text()
        self.assertIn('else if (dateGauge)', source)
        self.assertIn('drawLegacyLayout(dc, clock.hour', source)
        self.assertIn('lowPower ? 3 : 2', source)


if __name__ == '__main__':
    unittest.main()
