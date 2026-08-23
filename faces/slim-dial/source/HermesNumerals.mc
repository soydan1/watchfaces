import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Slim d'Hermès-inspired hour numerals. All glyphs stay upright.
// Construction from reference/hermes.png and reference/hermes-dark.png.
// The 8 is two stacked circles and locks stroke + size for the set.
module HermesNumerals {

    const SIZE_RATIO = 0.22;
    const AOD_SIZE_RATIO = 0.32;
    const HIGH_PEN = 2;
    const AOD_PEN = 1;

    function glyphSize(dc as Dc) as Number {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var half = ((w < h) ? w : h) / 2;
        var size = (half * SIZE_RATIO).toNumber();
        if (size < 16) {
            size = 16;
        }
        return size;
    }

    function drawHourLabel(
        dc as Dc,
        hour as Number,
        cx as Number,
        cy as Number,
        color as Number,
        pen as Number
    ) as Void {
        var size = glyphSize(dc);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(pen);
        if (hour >= 10) {
            drawPair(dc, hour, cx, cy, size);
        } else {
            drawDigit(dc, hour, cx, cy, size);
        }
    }

    function drawAllHours(
        dc as Dc,
        cx as Number,
        cy as Number,
        radius as Number,
        color as Number
    ) as Void {
        var size = glyphSize(dc);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(HIGH_PEN);
        var hour = 1;
        for (hour = 1; hour <= 12; hour++) {
            var angle = AnalogGeometry.hourLabelAngle(hour);
            var x = cx + (Math.cos(angle) * radius).toNumber();
            var y = cy + (Math.sin(angle) * radius).toNumber();
            if (hour >= 10) {
                drawPair(dc, hour, x, y, size);
            } else {
                drawDigit(dc, hour, x, y, size);
            }
        }
    }

    function aodGlyphSize(dc as Dc) as Number {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var half = ((w < h) ? w : h) / 2;
        var size = (half * AOD_SIZE_RATIO).toNumber();
        if (size < 22) {
            size = 22;
        }
        return size;
    }

    // AOD 12 / 3 / 9 only. Letterforms match hermesbg.png (n-cap 2, round 3, loop 9).
    function drawAodHours(
        dc as Dc,
        cx as Number,
        cy as Number,
        radius as Number,
        color as Number
    ) as Void {
        var size = aodGlyphSize(dc);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(AOD_PEN);
        var a12 = AnalogGeometry.hourLabelAngle(12);
        var a3 = AnalogGeometry.hourLabelAngle(3);
        var a9 = AnalogGeometry.hourLabelAngle(9);
        drawAodTwelve(dc, cx + (Math.cos(a12) * radius).toNumber(), cy + (Math.sin(a12) * radius).toNumber(), size);
        drawAodThree(dc, cx + (Math.cos(a3) * radius).toNumber(), cy + (Math.sin(a3) * radius).toNumber(), size);
        drawAodNine(dc, cx + (Math.cos(a9) * radius).toNumber(), cy + (Math.sin(a9) * radius).toNumber(), size);
    }

    function drawAodTwelve(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var w1 = size * 0.10;
        var w2 = size * 0.52;
        var gap = size * 0.16;
        var total = w1 + gap + w2;
        var lx = cx - (total / 2.0 - w1 / 2.0).toNumber();
        var rx = cx + (total / 2.0 - w2 / 2.0).toNumber();
        drawAodOne(dc, lx, cy, size);
        drawAodTwo(dc, rx, cy, size);
    }

    function drawAodOne(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var h = (size * 0.92).toNumber();
        dc.drawLine(cx, cy - h / 2, cx, cy + h / 2);
    }

    // Plate 2: n-cap, diagonal, long baseline. Not a round-top 2.
    function drawAodTwo(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var top = cy - (size * 0.48).toNumber();
        var capH = (size * 0.28).toNumber();
        var left = cx - (size * 0.24).toNumber();
        var right = cx + (size * 0.26).toNumber();
        var base = cy + (size * 0.46).toNumber();
        dc.drawLine(left, top, right, top);
        dc.drawLine(left, top, left, top + capH);
        dc.drawLine(right, top, right, top + capH);
        dc.drawLine(right, top + capH, left, base);
        dc.drawLine(left, base, right, base);
    }

    function drawAodThree(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.22).toNumber();
        if (r < 4) {
            r = 4;
        }
        var ox = cx + (size * 0.04).toNumber();
        dc.drawArc(ox, cy - (size * 0.22).toNumber(), r, Graphics.ARC_CLOCKWISE, 155, 270);
        dc.drawArc(ox, cy + (size * 0.22).toNumber(), r, Graphics.ARC_CLOCKWISE, 90, 205);
    }

    function drawAodNine(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.24).toNumber();
        if (r < 4) {
            r = 4;
        }
        var bx = cx;
        var by = cy - (size * 0.10).toNumber();
        dc.drawCircle(bx, by, r);
        var right = bx + r;
        dc.drawLine(right, by, right - (size * 0.04).toNumber(), cy + (size * 0.48).toNumber());
    }

    function drawDigit(dc as Dc, digit as Number, cx as Number, cy as Number, size as Number) as Void {
        if (digit == 0) {
            drawZero(dc, cx, cy, size);
        } else if (digit == 1) {
            drawOne(dc, cx, cy, size);
        } else if (digit == 2) {
            drawTwo(dc, cx, cy, size);
        } else if (digit == 3) {
            drawThree(dc, cx, cy, size);
        } else if (digit == 4) {
            drawFour(dc, cx, cy, size);
        } else if (digit == 5) {
            drawFive(dc, cx, cy, size);
        } else if (digit == 6) {
            drawSix(dc, cx, cy, size);
        } else if (digit == 7) {
            drawSeven(dc, cx, cy, size);
        } else if (digit == 8) {
            drawEight(dc, cx, cy, size);
        } else if (digit == 9) {
            drawNine(dc, cx, cy, size);
        }
    }

    // Two-glyph hours centered on the hour point, not on the leading 1.
    function drawPair(dc as Dc, hour as Number, cx as Number, cy as Number, size as Number) as Void {
        var left = hour / 10;
        var right = hour % 10;
        var gap = size * 0.12;
        var wL = digitWidth(left, size);
        var wR = digitWidth(right, size);
        var total = wL + gap + wR;
        var lx = cx - (total / 2.0 - wL / 2.0).toNumber();
        var rx = cx + (total / 2.0 - wR / 2.0).toNumber();
        drawDigit(dc, left, lx, cy, size);
        drawDigit(dc, right, rx, cy, size);
    }

    function digitWidth(digit as Number, size as Number) as Float {
        if (digit == 1) {
            return (size * 0.18) as Float;
        }
        if (digit == 0) {
            return (size * 0.52) as Float;
        }
        return (size * 0.55) as Float;
    }

    // Slightly shorter than 8 so a 12 pair does not dwarf neighbors.
    function drawOne(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var h = (size * 0.78).toNumber();
        dc.drawLine(cx, cy - h / 2, cx, cy + h / 2);
    }

    // Same circle language as one lobe of the 8, slightly taller.
    function drawZero(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.26).toNumber();
        if (r < 3) {
            r = 3;
        }
        dc.drawCircle(cx, cy, r);
    }

    function drawSeven(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var top = cy - (size * 0.38).toNumber();
        var bot = cy + (size * 0.40).toNumber();
        var left = cx - (size * 0.16).toNumber();
        var right = cx + (size * 0.18).toNumber();
        dc.drawLine(left, top, right, top);
        dc.drawLine(right, top, cx - (size * 0.12).toNumber(), bot);
    }

    // Two stacked circles, same radius, touching at the glyph center.
    function drawEight(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.22).toNumber();
        if (r < 3) {
            r = 3;
        }
        dc.drawCircle(cx, cy - r, r);
        dc.drawCircle(cx, cy + r, r);
    }

    // Signature angular 2: n-cap (almost a 7), diagonal, open baseline.
    function drawTwo(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.20).toNumber();
        var acx = cx + (size * 0.00).toNumber();
        var acy = cy - (size * 0.22).toNumber();
        dc.drawArc(acx, acy, r, Graphics.ARC_CLOCKWISE, 180, 0);
        var hx = acx + r;
        var hy = acy;
        var baseL = cx - (size * 0.22).toNumber();
        var baseR = cx + (size * 0.20).toNumber();
        var baseY = cy + (size * 0.38).toNumber();
        dc.drawLine(hx, hy, baseL, baseY);
        dc.drawLine(baseL, baseY, baseR, baseY);
    }

    // Two stacked open curves, cusp at mid-height, not a continuous S.
    function drawThree(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.20).toNumber();
        var ox = cx + (size * 0.05).toNumber();
        dc.drawArc(ox, cy - (size * 0.20).toNumber(), r, Graphics.ARC_CLOCKWISE, 145, 265);
        dc.drawArc(ox, cy + (size * 0.20).toNumber(), r, Graphics.ARC_CLOCKWISE, 95, 215);
    }

    // Open 4: left diagonal and right stem meet at the top. Crossbar
    // does not close a triangle on the left.
    function drawFour(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var stemX = cx + (size * 0.10).toNumber();
        var topY = cy - (size * 0.42).toNumber();
        var botY = cy + (size * 0.42).toNumber();
        dc.drawLine(stemX, topY, stemX, botY);
        dc.drawLine(cx - (size * 0.24).toNumber(), cy + (size * 0.04).toNumber(), stemX, topY);
        var barY = cy + (size * 0.04).toNumber();
        dc.drawLine(cx - (size * 0.04).toNumber(), barY, stemX + (size * 0.20).toNumber(), barY);
    }

    // Angular top bar, then a curve into an open lower bowl.
    function drawFive(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var topY = cy - (size * 0.40).toNumber();
        var barL = cx - (size * 0.22).toNumber();
        var barR = cx + (size * 0.18).toNumber();
        dc.drawLine(barL, topY, barR, topY);
        var br = (size * 0.26).toNumber();
        var bx = cx + (size * 0.02).toNumber();
        var by = cy + (size * 0.14).toNumber();
        dc.drawArc(bx, by, br, Graphics.ARC_CLOCKWISE, 155, 20);
        var start = polar(bx, by, br, 155);
        dc.drawLine(barL, topY, start[0], start[1]);
    }

    // Open loop: oval bowl with a short rising spine that does not close.
    function drawSix(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var br = (size * 0.26).toNumber();
        var bx = cx;
        var by = cy + (size * 0.06).toNumber();
        dc.drawArc(bx, by, br, Graphics.ARC_CLOCKWISE, 40, 105);
        var start = polar(bx, by, br, 105);
        dc.drawLine(start[0], start[1], start[0] - (size * 0.02).toNumber(), cy - (size * 0.38).toNumber());
    }

    // 6 inverted: same open loop, spine downward.
    function drawNine(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var br = (size * 0.26).toNumber();
        var bx = cx;
        var by = cy - (size * 0.06).toNumber();
        dc.drawArc(bx, by, br, Graphics.ARC_CLOCKWISE, 220, 285);
        var start = polar(bx, by, br, 285);
        dc.drawLine(start[0], start[1], start[0] + (size * 0.02).toNumber(), cy + (size * 0.38).toNumber());
    }

    // Garmin degrees: 0 = 3 o'clock, counter-clockwise.
    function polar(cx as Number, cy as Number, r as Number, deg as Number) as Array<Number> {
        var rad = Math.toRadians(deg);
        return [
            (cx + r * Math.cos(rad)).toNumber(),
            (cy - r * Math.sin(rad)).toNumber()
        ];
    }
}
