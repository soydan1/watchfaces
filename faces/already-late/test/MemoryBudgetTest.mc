import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Watch-face heap on d2mach2 is 128 KB. A 454x454 16bpp buffer is ~403 KB.
module MemoryBudgetTest {

    const WATCH_FACE_HEAP_BYTES = 131072;
    const FULLSCREEN_BUFFER_BYTES = 454 * 454 * 2;
    const MODULE_BUDGET_BYTES = 16 * 1024;

    (:test)
    function testGeometryStaysTiny(logger as Test.Logger) as Boolean {
        var before = System.getSystemStats().usedMemory;

        var shift = LateGeometry.burnInShift(3);
        if (shift.size() != 2) {
            logger.error("burnInShift must return [x, y]");
            return false;
        }

        var hour = LateGeometry.hourAngle(3, 30);
        var minute = LateGeometry.minuteAngle(30);
        var second = LateGeometry.secondAngle(15);
        var date30 = LateGeometry.dateNumerals(30);
        if (date30.size() != 3) {
            logger.error("dateNumerals(30) must return three hour-marks");
            return false;
        }
        if (LateGeometry.dateGlyphX(5) != 256) {
            logger.error("dateGlyphX(5) must be the crop origin x");
            return false;
        }

        if (LateGeometry.HOUR_PIVOT_Y != LateGeometry.HOUR_HEIGHT - 29) {
            logger.error("hour pivot must sit 29 px from the bottom of hour.png");
            return false;
        }
        if (LateGeometry.MINUTE_PIVOT_Y != LateGeometry.MINUTE_HEIGHT - 29) {
            logger.error("minute pivot must sit 29 px from the bottom of minute.png");
            return false;
        }
        if (LateGeometry.SECOND_PIVOT_Y != LateGeometry.SECOND_HEIGHT - 56) {
            logger.error("second pivot must sit 56 px from the bottom of second.png");
            return false;
        }
        if (LateGeometry.ARBOR_PIVOT_X != LateGeometry.ARBOR_WIDTH / 2) {
            logger.error("arbor must be centered on the image");
            return false;
        }
        if (LateGeometry.ARBOR_PIVOT_Y != LateGeometry.ARBOR_HEIGHT / 2) {
            logger.error("arbor must be centered on the image");
            return false;
        }

        var after = System.getSystemStats().usedMemory;
        var delta = after - before;
        logger.debug("geometry usedMemory delta=" + delta.toString()
            + " hour=" + hour.toString()
            + " minute=" + minute.toString()
            + " second=" + second.toString()
            + " hourPivotY=" + LateGeometry.HOUR_PIVOT_Y.toString()
            + " secondPivotY=" + LateGeometry.SECOND_PIVOT_Y.toString());

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
            // Documents the invariant: never allocate a fullscreen bitmap on heap.
            return true;
        }
        return true;
    }
}
