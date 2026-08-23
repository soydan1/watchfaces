import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class HermesFaceView extends WatchUi.WatchFace {

    private var _isAwake as Boolean;
    private var _partialUpdatesAllowed as Boolean;
    private var _background as BitmapResource?;

    function initialize() {
        WatchFace.initialize();
        _isAwake = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _background = null;
    }

    function onLayout(dc as Dc) as Void {
        _background = WatchUi.loadResource(Rez.Drawables.Background) as BitmapResource;
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
    function onPartialUpdate(dc as Dc) as Void {
        if (!_partialUpdatesAllowed) {
            return;
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (isLowPower()) {
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
        var subCy = cy + (half * HermesGeometry.SUBDIAL_CENTER_Y).toNumber();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_background != null) {
            dc.drawBitmap(0, 0, _background);
        } else {
            dc.setColor(0xF4F1EA, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, half - 2);
        }

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

        // Never blit the light plate in AOD — it would light every pixel.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cream = 0xE8E0D0;
        dc.setColor(cream, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, (half * HermesGeometry.CHAPTER_RING).toNumber());

        // 12 / 3 / 9 only, 1 px outline. Skip 6 for the 10% budget.
        var numeralR = (half * HermesGeometry.NUMERAL_RING).toNumber();
        var aodPen = HermesNumerals.AOD_PEN;
        HermesNumerals.drawHourLabel(dc, 12, cx, cy - numeralR, cream, aodPen);
        HermesNumerals.drawHourLabel(dc, 3, cx + numeralR, cy, cream, aodPen);
        HermesNumerals.drawHourLabel(dc, 9, cx - numeralR, cy, cream, aodPen);

        drawHands(dc, cx, cy, cy, half, clockTime, cream, false);

        dc.setColor(cream, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR).toNumber());
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
