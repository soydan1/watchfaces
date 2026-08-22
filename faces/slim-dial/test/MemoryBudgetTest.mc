import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Watch-face heap on d2mach2 is 128 KB. A 454x454 16bpp buffer is ~403 KB.
module MemoryBudgetTest {

    const WATCH_FACE_HEAP_BYTES = 131072;
    const FULLSCREEN_BUFFER_BYTES = 454 * 454 * 2;
    const MODULE_BUDGET_BYTES = 16 * 1024;

    (:test)
    function testGeometryAndNumeralsStayTiny(logger as Test.Logger) as Boolean {
        var before = System.getSystemStats().usedMemory;

        var shift = AnalogGeometry.burnInShift(3);
        if (shift.size() != 2) {
            logger.error("burnInShift must return [x, y]");
            return false;
        }

        var hour = AnalogGeometry.hourAngle(3, 30);
        var minute = AnalogGeometry.minuteAngle(30);
        var second = AnalogGeometry.secondAngle(15);
        var label = AnalogGeometry.hourLabelAngle(12);
        var poly = AnalogGeometry.handPolygon(227, 227, hour, 80, 10, 6);
        if (poly.size() != 4) {
            logger.error("handPolygon must return 4 points");
            return false;
        }

        var after = System.getSystemStats().usedMemory;
        var delta = after - before;
        logger.debug("geometry usedMemory delta=" + delta.toString()
            + " hour=" + hour.toString()
            + " minute=" + minute.toString()
            + " second=" + second.toString()
            + " label=" + label.toString());

        if (delta >= MODULE_BUDGET_BYTES) {
            logger.error("geometry helpers grew the heap by " + delta.toString()
                + " bytes; budget is " + MODULE_BUDGET_BYTES.toString());
            return false;
        }
        if (after >= WATCH_FACE_HEAP_BYTES) {
            logger.error("usedMemory " + after.toString()
                + " already at or over the 128 KB watch-face heap");
            return false;
        }
        if (FULLSCREEN_BUFFER_BYTES >= WATCH_FACE_HEAP_BYTES) {
            // Documents the invariant: never allocate a fullscreen bitmap.
            return true;
        }
        return true;
    }
}
