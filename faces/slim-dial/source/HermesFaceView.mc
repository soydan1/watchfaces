import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class HermesFaceView extends WatchUi.WatchFace {

    private var _isAwake as Boolean;
    private var _partialUpdatesAllowed as Boolean;
    private var _background as BitmapResource?;
    private var _hourHand as BitmapResource?;
    private var _minuteHand as BitmapResource?;
    private var _secondHand as BitmapResource?;
    private var _xf as AffineTransform;

    function initialize() {
        WatchFace.initialize();
        _isAwake = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _background = null;
        _hourHand = null;
        _minuteHand = null;
        _secondHand = null;
        _xf = new AffineTransform();
    }

    function onLayout(dc as Dc) as Void {
        _background = WatchUi.loadResource(Rez.Drawables.Background) as BitmapResource;
        _hourHand = WatchUi.loadResource(Rez.Drawables.HourHand) as BitmapResource;
        _minuteHand = WatchUi.loadResource(Rez.Drawables.MinuteHand) as BitmapResource;
        _secondHand = WatchUi.loadResource(Rez.Drawables.SecondHand) as BitmapResource;
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
        }

        drawSprite(dc, _hourHand, cx, cy, AnalogGeometry.hourAngle(clockTime.hour, clockTime.min));
        drawSprite(dc, _minuteHand, cx, cy, AnalogGeometry.minuteAngle(clockTime.min));
        drawSprite(dc, _secondHand, cx, subCy, AnalogGeometry.secondAngle(clockTime.sec));
    }

    private function drawLowPower(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var clockTime = System.getClockTime();
        var shift = AnalogGeometry.burnInShift(clockTime.min);
        var cx = width / 2 + shift[0];
        var cy = height / 2 + shift[1];

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cream = 0xE8E0D0;
        var half = ((width < height) ? width : height) / 2;
        var numeralR = (half * HermesGeometry.NUMERAL_RING).toNumber();
        HermesNumerals.drawAodHours(dc, cx, cy, numeralR, cream);

        drawSprite(dc, _hourHand, cx, cy, AnalogGeometry.hourAngle(clockTime.hour, clockTime.min));
        drawSprite(dc, _minuteHand, cx, cy, AnalogGeometry.minuteAngle(clockTime.min));
    }

    // Pivot is the center of the hub circle at the bottom of the sprite.
    private function drawSprite(
        dc as Dc,
        bmp as BitmapResource?,
        cx as Number,
        cy as Number,
        angle as Float
    ) as Void {
        if (bmp == null) {
            return;
        }
        var pw = bmp.getWidth().toFloat();
        var ph = bmp.getHeight().toFloat();
        var pivotX = pw / 2.0;
        var pivotY = ph - (pw / 2.0);
        _xf.setToTranslation(cx.toFloat(), cy.toFloat());
        _xf.rotate(angle);
        _xf.translate(-pivotX, -pivotY);
        dc.drawBitmap2(0, 0, bmp, {
            :transform => _xf,
            :filterMode => Graphics.FILTER_MODE_BILINEAR
        });
    }
}
