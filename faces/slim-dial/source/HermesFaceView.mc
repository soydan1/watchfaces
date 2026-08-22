import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class HermesFaceView extends WatchUi.WatchFace {

    private var _isAwake as Boolean;
    private var _partialUpdatesAllowed as Boolean;

    function initialize() {
        WatchFace.initialize();
        _isAwake = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _isAwake = true;
    }

    function onEnterSleep() as Void {
        _isAwake = false;
    }

    function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
    }

    // AMOLED AOD is a full low-power redraw, not a clipped seconds tick.
    // Keep this hook so a future MIP port can opt in without a new type.
    function onPartialUpdate(dc as Dc) as Void {
        if (!_partialUpdatesAllowed) {
            return;
        }
    }

    function onUpdate(dc as Dc) as Void {
        var lowPower = isLowPower();
        if (lowPower) {
            drawLowPower(dc);
        } else {
            drawHighPower(dc);
        }
    }

    private function isLowPower() as Boolean {
        if (System has :getDisplayMode) {
            if (System.getDisplayMode() == System.DISPLAY_MODE_LOW_POWER) {
                return true;
            }
        }
        return !_isAwake;
    }

    private function drawHighPower(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;
        var half = ((width < height) ? width : height) / 2;
        var clockTime = System.getClockTime();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
        dc.clear();

        dc.setColor(0xF4F1EA, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, half - 2);

        var innerR = (half * HermesGeometry.INNER_DISC).toNumber();
        dc.setColor(0xE4E0D8, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, innerR);

        var ringR = (half * HermesGeometry.CHAPTER_RING).toNumber();
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, ringR);
        drawMinuteTicks(dc, cx, cy, half, 0x222222);

        var subCy = cy + (half * HermesGeometry.SUBDIAL_CENTER_Y).toNumber();
        var subR = (half * HermesGeometry.SUBDIAL_RADIUS).toNumber();
        dc.setColor(0xDCD8D0, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, subCy, subR);
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, subCy, subR);
        drawSubdialTicks(dc, cx, subCy, half, 0x222222);

        var numeralR = (half * HermesGeometry.NUMERAL_RING).toNumber();
        HermesNumerals.drawAllHours(dc, cx, cy, numeralR, 0x111111);

        drawHands(dc, cx, cy, subCy, half, clockTime, 0x111111, true);

        dc.setColor(0x111111, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR).toNumber());
        dc.fillCircle(cx, subCy, (half * HermesGeometry.SUB_ARBOR).toNumber());
    }

    private function drawLowPower(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var clockTime = System.getClockTime();
        var shift = AnalogGeometry.burnInShift(clockTime.min);
        var cx = width / 2 + shift[0];
        var cy = height / 2 + shift[1];
        var half = ((width < height) ? width : height) / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cream = 0xE8E0D0;
        dc.setColor(cream, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, (half * HermesGeometry.CHAPTER_RING).toNumber());

        // AOD: 12 / 3 / 9 only, 1 px outline. Skip 6 — a fourth label
        // blows the 10% pixel budget.
        var numeralR = (half * HermesGeometry.NUMERAL_RING).toNumber();
        var aodPen = HermesNumerals.AOD_PEN;
        HermesNumerals.drawHourLabel(dc, 12, cx, cy - numeralR, cream, aodPen);
        HermesNumerals.drawHourLabel(dc, 3, cx + numeralR, cy, cream, aodPen);
        HermesNumerals.drawHourLabel(dc, 9, cx - numeralR, cy, cream, aodPen);

        drawHands(dc, cx, cy, cy, half, clockTime, cream, false);

        dc.setColor(cream, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR).toNumber());
    }

    private function drawMinuteTicks(dc as Dc, cx as Number, cy as Number, half as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var inner = half * HermesGeometry.MINUTE_TICK_INNER;
        var outer = half * HermesGeometry.MINUTE_TICK_OUTER;
        var hourInner = half * HermesGeometry.HOUR_TICK_INNER;
        var hourOuter = half * HermesGeometry.HOUR_TICK_OUTER;
        var i = 0;
        for (i = 0; i < 60; i++) {
            if (i % 5 == 0) {
                continue;
            }
            var angle = (i / 60.0) * Math.PI * 2.0 - Math.PI / 2.0;
            var cos = Math.cos(angle);
            var sin = Math.sin(angle);
            dc.drawLine(
                cx + (cos * inner).toNumber(),
                cy + (sin * inner).toNumber(),
                cx + (cos * outer).toNumber(),
                cy + (sin * outer).toNumber()
            );
        }
        for (i = 0; i < 12; i++) {
            var hourAngle = (i / 12.0) * Math.PI * 2.0 - Math.PI / 2.0;
            var hcos = Math.cos(hourAngle);
            var hsin = Math.sin(hourAngle);
            dc.drawLine(
                cx + (hcos * hourInner).toNumber(),
                cy + (hsin * hourInner).toNumber(),
                cx + (hcos * hourOuter).toNumber(),
                cy + (hsin * hourOuter).toNumber()
            );
        }
    }

    private function drawSubdialTicks(dc as Dc, cx as Number, cy as Number, half as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var inner = half * HermesGeometry.SUBDIAL_TICK_INNER;
        var outer = half * HermesGeometry.SUBDIAL_TICK_OUTER;
        var cardInner = half * HermesGeometry.SUBDIAL_CARDINAL_INNER;
        var i = 0;
        for (i = 0; i < 12; i++) {
            var angle = (i / 12.0) * Math.PI * 2.0 - Math.PI / 2.0;
            var cos = Math.cos(angle);
            var sin = Math.sin(angle);
            var from = (i % 3 == 0) ? cardInner : inner;
            dc.drawLine(
                cx + (cos * from).toNumber(),
                cy + (sin * from).toNumber(),
                cx + (cos * outer).toNumber(),
                cy + (sin * outer).toNumber()
            );
        }
    }

    private function drawHands(
        dc as Dc,
        cx as Number,
        cy as Number,
        subCy as Number,
        half as Number,
        clockTime as ClockTime,
        color as Number,
        drawSeconds as Boolean
    ) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var hourPoly = AnalogGeometry.handPolygon(
            cx,
            cy,
            AnalogGeometry.hourAngle(clockTime.hour, clockTime.min),
            (half * HermesGeometry.HOUR_HAND_LEN).toNumber(),
            (half * HermesGeometry.HAND_TAIL).toNumber(),
            (half * HermesGeometry.HOUR_HAND_WIDTH).toNumber()
        );
        var minutePoly = AnalogGeometry.handPolygon(
            cx,
            cy,
            AnalogGeometry.minuteAngle(clockTime.min),
            (half * HermesGeometry.MINUTE_HAND_LEN).toNumber(),
            (half * HermesGeometry.HAND_TAIL).toNumber(),
            (half * HermesGeometry.MINUTE_HAND_WIDTH).toNumber()
        );
        dc.fillPolygon(hourPoly);
        dc.fillPolygon(minutePoly);

        if (drawSeconds) {
            var secondPoly = AnalogGeometry.handPolygon(
                cx,
                subCy,
                AnalogGeometry.secondAngle(clockTime.sec),
                (half * HermesGeometry.SECOND_HAND_LEN).toNumber(),
                (half * HermesGeometry.HAND_TAIL / 2).toNumber(),
                (half * HermesGeometry.SECOND_HAND_WIDTH).toNumber()
            );
            dc.fillPolygon(secondPoly);
        }
    }
}
