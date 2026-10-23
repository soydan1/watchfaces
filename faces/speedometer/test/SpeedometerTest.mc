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
    function testNeedleDirections(logger as Test.Logger) as Boolean {
        // 1/2 point down-left; 7 points up; 10 points right and slightly up.
        var one = SpeedometerGeometry.needleAngle(1);
        var seven = SpeedometerGeometry.needleAngle(7);
        var ten = SpeedometerGeometry.needleAngle(10);
        return Math.sin(one) > 0 && Math.cos(one) > 0 &&
               Math.cos(seven) < -0.99 && Math.sin(ten) < -0.9;
    }

    (:test)
    function testAodPositions(logger as Test.Logger) as Boolean {
        for (var minute = 0; minute < 60; minute++) {
            var y = SpeedometerGeometry.aodY(minute);
            if (y < 60 || y > 320) { return false; }
            // A time/date group must leave this row for at least 3 minutes.
            for (var offset = 1; offset <= 3; offset++) {
                if (SpeedometerGeometry.aodY(minute + offset) == y) { return false; }
            }
        }
        return true;
    }

    (:test)
    function testResourcesAndHeap(logger as Test.Logger) as Boolean {
        // Match the view's retained resources, then exercise the actual draw
        // path in the simulator separately to catch decode/transform peaks.
        var resources = [Rez.Drawables.Background, Rez.Drawables.Window,
            Rez.Drawables.Needle, Rez.Drawables.RedOne, Rez.Drawables.RedTwo,
            Rez.Drawables.Digit0, Rez.Drawables.Digit1, Rez.Drawables.Digit2,
            Rez.Drawables.Digit3, Rez.Drawables.Digit4, Rez.Drawables.Digit5,
            Rez.Drawables.Digit6, Rez.Drawables.Digit7, Rez.Drawables.Digit8,
            Rez.Drawables.Digit9];
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
        loaded.add(WatchUi.loadResource(Rez.Drawables.WindowDark));
        used = System.getSystemStats().usedMemory;
        logger.debug("Speedometer theme-switch heap=" + used);
        return used < 131072;
    }
}
