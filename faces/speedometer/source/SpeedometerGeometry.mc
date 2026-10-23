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
        var angles = [0.2723732f, 0.7768275f, 1.2349509f, 1.6743483f,
                      2.1124845f, 2.5948604f, 3.1415927f, -2.6330173f,
                      -2.0928389f, -1.7060713f];
        return angles[labelForHour(hour) - 1];
    }

    // Five non-overlapping time/date rows: avoid relying on a 1px shift of
    // large filled glyphs for AMOLED protection. Validate with device heat map.
    function aodY(minute as Number) as Number {
        return 60 + (minute % 5) * 65;
    }
}
