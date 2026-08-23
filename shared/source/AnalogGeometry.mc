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

    function rotate(
        cx as Number,
        cy as Number,
        angle as Float,
        x as Numeric,
        y as Numeric
    ) as [Numeric, Numeric] {
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        return [cx + (x * cos) - (y * sin), cy + (x * sin) + (y * cos)];
    }

    function handPolygon(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        return transformPoly(
            cx,
            cy,
            angle,
            [
                [-(width / 2), tail],
                [-(width / 2), -length],
                [width / 2, -length],
                [width / 2, tail]
            ] as Array<Array<Numeric>>
        );
    }

    // Kite / dauphine: pointed tip, widest ~halfway, small counterweight.
    function dauphinePolygon(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        return transformPoly(
            cx,
            cy,
            angle,
            [
                [0, -length],
                [-(width / 2), -length * 0.52],
                [0, tail],
                [width / 2, -length * 0.52]
            ] as Array<Array<Numeric>>
        );
    }

    function dauphineLeft(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        return transformPoly(
            cx,
            cy,
            angle,
            [
                [0, -length],
                [-(width / 2), -length * 0.52],
                [0, tail]
            ] as Array<Array<Numeric>>
        );
    }

    function dauphineRight(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        return transformPoly(
            cx,
            cy,
            angle,
            [
                [0, -length],
                [width / 2, -length * 0.52],
                [0, tail]
            ] as Array<Array<Numeric>>
        );
    }

    function needlePolygon(
        cx as Number,
        cy as Number,
        angle as Float,
        length as Number,
        tail as Number,
        width as Number
    ) as Array<[Numeric, Numeric]> {
        var halfW = width / 2.0;
        if (halfW < 0.6) {
            halfW = 0.6;
        }
        return transformPoly(
            cx,
            cy,
            angle,
            [
                [0, -length],
                [-halfW, -length + width + 2],
                [-halfW, tail],
                [halfW, tail],
                [halfW, -length + width + 2]
            ] as Array<Array<Numeric>>
        );
    }

    function transformPoly(
        cx as Number,
        cy as Number,
        angle as Float,
        coords as Array<Array<Numeric>>
    ) as Array<[Numeric, Numeric]> {
        var n = coords.size();
        var result = new Array<[Numeric, Numeric]>[n];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var i = 0;
        for (i = 0; i < n; i++) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [cx + x, cy + y];
        }
        return result;
    }
}
