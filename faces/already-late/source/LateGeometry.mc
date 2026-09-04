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

    // Top-left of dateN.png on the 454 plate (2 px pad around the alpha bbox).
    const DATE_GLYPH_X as Array<Number> = [72, 189, 292, 186, 256, 113, 372, 250, 334, 123, 233, 305] as Array<Number>;
    const DATE_GLYPH_Y as Array<Number> = [322, 375, 230, 318, 381, 284, 272, 334, 255, 355, 278, 326] as Array<Number>;

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

    const MARK_NONE = 0;
    const MARK_DATE = 1;
    const MARK_STEPS = 2;
    const MARK_BOTH = 3;

    // Each of 1-12 is used at most once; 30 is 11+10+9 so 12+11+7 is never drawn.
    function dateNumerals(day as Number) as Array<Number> {
        return markNumerals(day);
    }

    function stepThousandsNumerals(thousands as Number) as Array<Number> {
        return markNumerals(thousands);
    }

    function markNumerals(value as Number) as Array<Number> {
        if (value < 1) {
            return [] as Array<Number>;
        }
        if (value > 78) {
            value = 78;
        }
        if (value == 30) {
            return [11, 10, 9] as Array<Number>;
        }
        if (value <= 12) {
            return [value] as Array<Number>;
        }
        if (value <= 23) {
            return [12, value - 12] as Array<Number>;
        }
        if (value <= 29) {
            return [12, 11, value - 23] as Array<Number>;
        }
        if (value == 31) {
            return [12, 11, 8] as Array<Number>;
        }
        var remaining = value;
        var used = [false, false, false, false, false, false, false, false, false, false, false, false] as Array<Boolean>;
        var count = 0;
        for (var n = 12; n >= 1; n--) {
            if (n <= remaining) {
                used[n - 1] = true;
                remaining -= n;
                count++;
            }
        }
        var out = new [count] as Array<Number>;
        var i = 0;
        for (var n = 12; n >= 1; n--) {
            if (used[n - 1]) {
                out[i] = n;
                i++;
            }
        }
        return out;
    }

    function containsNumeral(nums as Array<Number>, n as Number) as Boolean {
        for (var i = 0; i < nums.size(); i++) {
            if (nums[i] == n) {
                return true;
            }
        }
        return false;
    }

    function numeralRole(n as Number, dateNums as Array<Number>, stepNums as Array<Number>) as Number {
        var inDate = containsNumeral(dateNums, n);
        var inSteps = containsNumeral(stepNums, n);
        if (inDate && inSteps) {
            return MARK_BOTH;
        }
        if (inDate) {
            return MARK_DATE;
        }
        if (inSteps) {
            return MARK_STEPS;
        }
        return MARK_NONE;
    }

    function dateGlyphX(numeral as Number) as Number {
        if ((numeral < 1) || (numeral > 12)) {
            return 0;
        }
        return DATE_GLYPH_X[numeral - 1];
    }

    function dateGlyphY(numeral as Number) as Number {
        if ((numeral < 1) || (numeral > 12)) {
            return 0;
        }
        return DATE_GLYPH_Y[numeral - 1];
    }
}
