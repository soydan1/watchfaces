import Toybox.Lang;
import Toybox.Math;

// Analog helpers shared by every face in this repo.
// Face-specific radii, tick lengths, and colors stay in the face module.
module AnalogGeometry {

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

    // 0 rad = 12 o'clock, clockwise. Used to place upright hour numerals.
    function hourLabelAngle(hour as Number) as Float {
        return ((hour / 12.0) * Math.PI * 2.0 - Math.PI / 2.0) as Float;
    }

    function handPolygon(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        var coords = [
            [-(width / 2), tail],
            [-(width / 2), -length],
            [width / 2, -length],
            [width / 2, tail]
        ] as Array<Array<Numeric>>;
        var result = new Array<[Numeric, Numeric]>[4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var i = 0;
        for (i = 0; i < 4; i++) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [cx + x, cy + y];
        }
        return result;
    }
}
