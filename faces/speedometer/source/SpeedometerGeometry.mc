import Toybox.Lang;

// Angles measured from the supplied artwork, not a conventional clock scale.
// The sprite points down at 0 radians; positive rotation is clockwise.
module SpeedometerGeometry {
    const PIVOT_X = 227;
    const PIVOT_Y = 230;
    const NEEDLE_PIVOT = 34;
    const DISPLAY_COLOR = 0xFFE291;
    const DATE_CENTER_X = 322;
    const DATE_X_NORMAL = 260;
    const DATE_X_LEADING_ONE = 252;

    // Ink bounds of the 24px-wide date glyphs: leading 1 starts at x=18,
    // others at x=1/2; every trailing glyph ends at x=23 (exclusive).
    // Centre visible strokes rather than the fixed-width digit container.
    function dateStartX(day as Number) as Number {
        return day >= 10 && day < 20 ? DATE_X_LEADING_ONE : DATE_X_NORMAL;
    }

    function dialHour(hour as Number) as Number {
        var h = hour % 12;
        return h == 0 ? 12 : h;
    }

    function labelForHour(hour as Number) as Number {
        var h = dialHour(hour);
        return h > 10 ? h - 10 : h;
    }

    function redLabel(hour as Number) as Number {
        var h = dialHour(hour);
        return h > 10 ? h - 10 : 0;
    }

    // Keep aligned with tools/prepare_assets.py LABELS and PIVOT. Allocate
    // once, rather than building a new array during every screen update.
    var _angles as Array<Float> = [
        0.2719006f, 0.7756082f, 1.2333894f, 1.6727458f,
        2.1110892f, 2.5940046f, -3.1415927f, -2.6322000f,
        -2.0914738f, -1.7043858f
    ];

    function needleAngle(hour as Number) as Float {
        return _angles[labelForHour(hour) - 1];
    }

    // Date gauge: the upper window supplies tens, the image needle supplies
    // ones. 10/20/30 point to the printed 0, never the printed 10.
    const DATE_ZERO_ANGLE = 0.0130452f;

    function dateTens(day as Number) as Number {
        return (day / 10).toNumber();
    }

    function dateOnes(day as Number) as Number {
        return day % 10;
    }

    function dateNeedleAngle(day as Number) as Float {
        var ones = dateOnes(day);
        return ones == 0 ? DATE_ZERO_ANGLE : _angles[ones - 1];
    }

    // Unwrapped dial arc: increasing seconds travel clockwise from 0 to 10,
    // not through the unused gap. Each printed division represents 6 seconds.
    function gaugeAngle(label as Number) as Float {
        var angle = label == 0 ? DATE_ZERO_ANGLE : _angles[label - 1];
        return angle < 0 ? angle + 6.2831853f : angle;
    }

    function secondsNeedleAngle(second as Number) as Float {
        if (second <= 0) { return gaugeAngle(0); }
        if (second >= 60) { return gaugeAngle(10); }
        var label = (second / 6).toNumber();
        var fraction = (second % 6) / 6.0f;
        var start = gaugeAngle(label);
        return start + (gaugeAngle(label + 1) - start) * fraction;
    }

    function fullDayStartX(day as Number) as Number {
        return day >= 10 && day < 20 ? 196 : 203;
    }

    // Digital time is always 24-hour, regardless of the device preference.
    function displayHour(hour as Number) as Number {
        return hour;
    }

    function timeStartX(hour as Number) as Number {
        // Same 24px glyph widths as the legacy date; only the height changes.
        return dateStartX(displayHour(hour));
    }

    // Sleep always uses the supplied dark plate; wake restores the preference.
    function useDarkTheme(lowPower as Boolean, darkSetting as Boolean) as Boolean {
        return lowPower || darkSetting;
    }
}
