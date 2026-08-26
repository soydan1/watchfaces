import Toybox.Lang;
import Toybox.Math;

// Hand sprites are device pixels on 454x454. Pivot is measured from the
// bottom of each PNG: 29 px for hour/minute, 56 px for seconds.
module LateGeometry {

    const ORANGE = 0xF08018;

    const HOUR_WIDTH = 18;
    const HOUR_HEIGHT = 158;
    const HOUR_PIVOT_FROM_BOTTOM = 29;
    const HOUR_PIVOT_X = 9;
    const HOUR_PIVOT_Y = HOUR_HEIGHT - HOUR_PIVOT_FROM_BOTTOM;

    const MINUTE_WIDTH = 10;
    const MINUTE_HEIGHT = 187;
    const MINUTE_PIVOT_FROM_BOTTOM = 29;
    const MINUTE_PIVOT_X = 5;
    const MINUTE_PIVOT_Y = MINUTE_HEIGHT - MINUTE_PIVOT_FROM_BOTTOM;

    const SECOND_WIDTH = 36;
    const SECOND_HEIGHT = 241;
    const SECOND_PIVOT_FROM_BOTTOM = 56;
    // Shaft at the pivot row is x=7..11, not the 36 px canvas center.
    const SECOND_PIVOT_X = 9;
    const SECOND_PIVOT_Y = SECOND_HEIGHT - SECOND_PIVOT_FROM_BOTTOM;

    // arbor.png disc sits in the top of the 36x36; draw last, unrotated.
    const ARBOR_WIDTH = 36;
    const ARBOR_HEIGHT = 36;
    const ARBOR_PIVOT_X = 18;
    const ARBOR_PIVOT_Y = 18;

    const DIAL_SIZE = 454;
    const DIAL_RADIUS = 227;

    // AMOLED always-on: shift 1px each minute so no pixel stays on > 3 min.
    function burnInShift(minute as Number) as Array<Number> {
        var phase = minute % 5;
        if (phase == 0) {
            return [0, 0] as Array<Number>;
        }
        if (phase == 1) {
            return [1, 0] as Array<Number>;
        }
        if (phase == 2) {
            return [1, 1] as Array<Number>;
        }
        if (phase == 3) {
            return [0, 1] as Array<Number>;
        }
        return [-1, 0] as Array<Number>;
    }

    function hourAngle(hour as Number, minute as Number) as Float {
        var hours12 = hour % 12;
        var turns = ((hours12 * 60) + minute) / (12.0 * 60.0);
        return (turns * Math.PI * 2.0) as Float;
    }

    function minuteAngle(minute as Number) as Float {
        return ((minute / 60.0) * Math.PI * 2.0) as Float;
    }

    function secondAngle(second as Number) as Float {
        return ((second / 60.0) * Math.PI * 2.0) as Float;
    }
}
