import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;

module SpeedometerTest {
    (:test)
    function testAllHours(logger as Test.Logger) as Boolean {
        for (var hour = 0; hour < 24; hour++) {
            var h = hour % 12;
            if (h == 0) { h = 12; }
            var label = h > 10 ? h - 10 : h;
            var red = h > 10 ? h - 10 : 0;
            if (SpeedometerGeometry.dialHour(hour) != h ||
                SpeedometerGeometry.labelForHour(hour) != label ||
                SpeedometerGeometry.redLabel(hour) != red) {
                logger.error("Wrong mapping for hour " + hour);
                return false;
            }
        }
        if (SpeedometerGeometry.needleAngle(11) != SpeedometerGeometry.needleAngle(1) ||
            SpeedometerGeometry.needleAngle(0) != SpeedometerGeometry.needleAngle(2) ||
            SpeedometerGeometry.redLabel(13) != 0) {
            return false;
        }
        return true;
    }

    (:test)
    function testEveryDate(logger as Test.Logger) as Boolean {
        for (var day = 1; day <= 31; day++) {
            var tens = SpeedometerGeometry.dateTens(day);
            var ones = SpeedometerGeometry.dateOnes(day);
            if (tens < 0 || tens > 3 || ones < 0 || ones > 9 ||
                tens * 10 + ones != day) {
                return false;
            }
            var expected = ones == 0 ? SpeedometerGeometry.DATE_ZERO_ANGLE
                                     : SpeedometerGeometry.needleAngle(ones);
            if (SpeedometerGeometry.dateNeedleAngle(day) != expected) {
                return false;
            }
        }
        return SpeedometerGeometry.dateNeedleAngle(10) == SpeedometerGeometry.dateNeedleAngle(20)
            && SpeedometerGeometry.dateNeedleAngle(20) == SpeedometerGeometry.dateNeedleAngle(30)
            && SpeedometerGeometry.dateNeedleAngle(10) != SpeedometerGeometry.needleAngle(10)
            && SpeedometerGeometry.dateNeedleAngle(31) == SpeedometerGeometry.needleAngle(1);
    }

    (:test)
    function testDigitalHours(logger as Test.Logger) as Boolean {
        for (var hour = 0; hour < 24; hour++) {
            if (SpeedometerGeometry.displayHour(hour) != hour) {
                return false;
            }
            var expected24X = hour >= 10 && hour < 20 ? 252 : 260;
            if (SpeedometerGeometry.timeStartX(hour) != expected24X) {
                return false;
            }
        }
        return true;
    }

    (:test)
    function testNeedleDirections(logger as Test.Logger) as Boolean {
        // 1/2 point down-left; 7 points up; 10 points right and slightly up.
        var one = SpeedometerGeometry.needleAngle(1);
        var seven = SpeedometerGeometry.needleAngle(7);
        var ten = SpeedometerGeometry.needleAngle(10);
        return Math.sin(one) > 0 && Math.cos(one) > 0 &&
               Math.cos(seven) < -0.99 && Math.sin(ten) < -0.9;
    }

    (:test)
    function testDateOpticalCenter(logger as Test.Logger) as Boolean {
        for (var day = 1; day <= 31; day++) {
            var expected = day >= 10 && day < 20 ? 252 : 260;
            if (SpeedometerGeometry.dateStartX(day) != expected) {
                return false;
            }
        }
        return true;
    }

    (:test)
    function testAodUsesDarkArtwork(logger as Test.Logger) as Boolean {
        return SpeedometerGeometry.useDarkTheme(true, false) &&
               SpeedometerGeometry.useDarkTheme(true, true) &&
               !SpeedometerGeometry.useDarkTheme(false, false) &&
               SpeedometerGeometry.useDarkTheme(false, true);
    }

    (:test)
    function testGeometryBenchmark(logger as Test.Logger) as Boolean {
        var before = System.getSystemStats().usedMemory;
        var startedAt = System.getTimer();
        for (var round = 0; round < 100; round++) {
            for (var hour = 0; hour < 24; hour++) {
                if (SpeedometerGeometry.needleAngle(hour) !=
                    SpeedometerGeometry.needleAngle(hour + 12)) {
                    return false;
                }
            }
        }
        var elapsed = System.getTimer() - startedAt;
        var used = System.getSystemStats().usedMemory;
        logger.debug("Speedometer 4800 angle lookups ms=" + elapsed
            + " heapDelta=" + (used - before));
        return used < 131072;
    }

    (:test)
    function testResourcesAndHeap(logger as Test.Logger) as Boolean {
        // Match the view's retained resources, then exercise the actual draw
        // path in the simulator separately to catch decode/transform peaks.
        var resources = [Rez.Drawables.Background,
            Rez.Drawables.Needle, Rez.Drawables.RedOne, Rez.Drawables.RedTwo,
            Rez.Drawables.Digit0, Rez.Drawables.Digit1, Rez.Drawables.Digit2,
            Rez.Drawables.Digit3, Rez.Drawables.Digit4, Rez.Drawables.Digit5,
            Rez.Drawables.Digit6, Rez.Drawables.Digit7, Rez.Drawables.Digit8,
            Rez.Drawables.Digit9, Rez.Drawables.DateTens0, Rez.Drawables.DateTens1,
            Rez.Drawables.DateTens2, Rez.Drawables.DateTens3];
        var loaded = [];
        for (var i = 0; i < resources.size(); i++) {
            loaded.add(WatchUi.loadResource(resources[i]));
        }
        var used = System.getSystemStats().usedMemory;
        logger.debug("Speedometer retained-resource heap=" + used);
        if (used >= 131072) { return false; }
        // Also load the alternate plate without dropping the light one: a
        // conservative check of switching themes before garbage collection.
        loaded.add(WatchUi.loadResource(Rez.Drawables.BackgroundDark));
        used = System.getSystemStats().usedMemory;
        logger.debug("Speedometer theme-switch heap=" + used);
        if (used >= 131072) { return false; }
        var wakeIds = [Rez.Drawables.Wake1, Rez.Drawables.Wake2, Rez.Drawables.Wake3,
                       Rez.Drawables.Wake4, Rez.Drawables.Wake5];
        var wake as BitmapResource? = null;
        for (var j = 0; j < wakeIds.size(); j++) {
            wake = null;
            wake = WatchUi.loadResource(wakeIds[j]) as BitmapResource;
            if (wake.getWidth() != 454 || wake.getHeight() != 454) { return false; }
            used = System.getSystemStats().usedMemory;
            logger.debug("Speedometer wake frame=" + j + " retained heap=" + used);
            if (used >= 131072) { return false; }
        }
        return true;
    }
}
