import Toybox.Lang;

// Angles measured from the supplied artwork, not a conventional clock scale.
// The sprite points down at 0 radians; positive rotation is clockwise.
module SpeedometerGeometry {
    const PIVOT_X = 227;
    const PIVOT_Y = 230;
    const NEEDLE_PIVOT = 34;

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

    function needleAngle(hour as Number) as Float {
        // Keep these aligned with tools/prepare_assets.py LABELS and PIVOT.
        var angles = [0.2719006f, 0.7756082f, 1.2333894f, 1.6727458f,
                      2.1110892f, 2.5940046f, -3.1415927f, -2.6322000f,
                      -2.0914738f, -1.7043858f];
        return angles[labelForHour(hour) - 1];
    }

    // Sleep always uses the supplied dark plate; wake restores the preference.
    function useDarkTheme(lowPower as Boolean, darkSetting as Boolean) as Boolean {
        return lowPower || darkSetting;
    }
}
