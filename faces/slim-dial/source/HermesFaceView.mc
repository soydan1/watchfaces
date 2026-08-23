import Toybox.Graphics;
import Toybox.Lang;
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

        drawHands(dc, cx, cy, subCy, half, clockTime, 0x1A1A1A, 0x6A6A6A, true);
        drawHub(dc, cx, cy, half, 0x111111, 0xE8E4DC, true);
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
        var numeralR = (half * HermesGeometry.NUMERAL_RING).toNumber();
        HermesNumerals.drawAodHours(dc, cx, cy, numeralR, cream);

        drawHands(dc, cx, cy, cy, half, clockTime, cream, 0xC4B8A0, false);
        drawHub(dc, cx, cy, half, cream, cream, false);
    }

    private function drawHands(
        dc as Dc,
        cx as Number,
        cy as Number,
        subCy as Number,
        half as Number,
        clockTime as ClockTime,
        dark as Number,
        light as Number,
        drawSeconds as Boolean
    ) as Void {
        var hourLen = (half * HermesGeometry.HOUR_HAND_LEN).toNumber();
        var hourTail = (half * HermesGeometry.HAND_TAIL).toNumber();
        var hourW = (half * HermesGeometry.HOUR_HAND_WIDTH).toNumber();
        var hourAng = AnalogGeometry.hourAngle(clockTime.hour, clockTime.min);

        var minLen = (half * HermesGeometry.MINUTE_HAND_LEN).toNumber();
        var minW = (half * HermesGeometry.MINUTE_HAND_WIDTH).toNumber();
        var minAng = AnalogGeometry.minuteAngle(clockTime.min);

        dc.setColor(light, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(AnalogGeometry.dauphineLeft(cx, cy, hourAng, hourLen, hourTail, hourW));
        dc.fillPolygon(AnalogGeometry.dauphineLeft(cx, cy, minAng, minLen, hourTail, minW));
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(AnalogGeometry.dauphineRight(cx, cy, hourAng, hourLen, hourTail, hourW));
        dc.fillPolygon(AnalogGeometry.dauphineRight(cx, cy, minAng, minLen, hourTail, minW));

        if (drawSeconds) {
            var secAng = AnalogGeometry.secondAngle(clockTime.sec);
            var secLen = (half * HermesGeometry.SECOND_HAND_LEN).toNumber();
            var secTail = (half * HermesGeometry.SECOND_TAIL).toNumber();
            var secW = (half * HermesGeometry.SECOND_HAND_WIDTH).toNumber();
            dc.setColor(0x8A1A1A, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(AnalogGeometry.needlePolygon(cx, subCy, secAng, secLen, secTail, secW));
            var cw = AnalogGeometry.rotate(cx, subCy, secAng, 0, (secTail * 0.62) as Numeric);
            dc.fillCircle(cw[0].toNumber(), cw[1].toNumber(), (half * HermesGeometry.SECOND_COUNTERWEIGHT).toNumber());
            var tip = AnalogGeometry.rotate(cx, subCy, secAng, 0, (-secLen) as Numeric);
            dc.fillCircle(tip[0].toNumber(), tip[1].toNumber(), 1);
        }
    }

    private function drawHub(
        dc as Dc,
        cx as Number,
        cy as Number,
        half as Number,
        ring as Number,
        pip as Number,
        highPower as Boolean
    ) as Void {
        dc.setColor(ring, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR).toNumber());
        dc.setColor(pip, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR_PIP).toNumber());
        dc.setColor(ring, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, (half * HermesGeometry.MAIN_ARBOR_PIN).toNumber());
        if (highPower) {
            var subCy = cy + (half * HermesGeometry.SUBDIAL_CENTER_Y).toNumber();
            dc.setColor(0x111111, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, subCy, (half * HermesGeometry.SUB_ARBOR).toNumber());
            dc.setColor(0xE8E4DC, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, subCy, (half * HermesGeometry.SUB_ARBOR_PIN).toNumber());
        }
    }
}
