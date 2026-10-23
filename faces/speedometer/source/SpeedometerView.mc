import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class SpeedometerView extends WatchUi.WatchFace {
    private var _awake as Boolean = true;
    private var _dark as Boolean = false;
    private var _background as BitmapResource?;
    private var _window as BitmapResource?;
    private var _needle as BitmapResource?;
    private var _redOne as BitmapResource?;
    private var _redTwo as BitmapResource?;
    private var _digits as Array<BitmapResource>;
    private var _xf as AffineTransform;

    function initialize() {
        WatchFace.initialize();
        _background = null;
        _window = null;
        _needle = null;
        _redOne = null;
        _redTwo = null;
        _digits = [];
        _xf = new AffineTransform();
    }

    function onLayout(dc as Dc) as Void {
        _needle = WatchUi.loadResource(Rez.Drawables.Needle) as BitmapResource;
        _redOne = WatchUi.loadResource(Rez.Drawables.RedOne) as BitmapResource;
        _redTwo = WatchUi.loadResource(Rez.Drawables.RedTwo) as BitmapResource;
        var ids = [Rez.Drawables.Digit0, Rez.Drawables.Digit1,
                   Rez.Drawables.Digit2, Rez.Drawables.Digit3,
                   Rez.Drawables.Digit4, Rez.Drawables.Digit5,
                   Rez.Drawables.Digit6, Rez.Drawables.Digit7,
                   Rez.Drawables.Digit8, Rez.Drawables.Digit9];
        _digits = [];
        for (var i = 0; i < ids.size(); i++) {
            _digits.add(WatchUi.loadResource(ids[i]) as BitmapResource);
        }
        loadTheme();
    }

    private function loadTheme() as Void {
        _dark = Application.Properties.getValue("DarkTheme") == true;
        // Only retain one plate at a time. No full-screen offscreen buffers.
        _background = null;
        _window = null;
        _background = WatchUi.loadResource(_dark ? Rez.Drawables.BackgroundDark : Rez.Drawables.Background) as BitmapResource;
        _window = WatchUi.loadResource(_dark ? Rez.Drawables.WindowDark : Rez.Drawables.Window) as BitmapResource;
    }

    function onEnterSleep() as Void {
        _awake = false;
    }

    function onExitSleep() as Void {
        _awake = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var clock = System.getClockTime();
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var lowPower = !_awake;
        if (System has :getDisplayMode) {
            lowPower = lowPower || System.getDisplayMode() == System.DISPLAY_MODE_LOW_POWER;
        }
        if (lowPower) {
            drawAlwaysOn(dc, clock.hour, clock.min, date.day, date.month);
            return;
        }
        if (_dark != (Application.Properties.getValue("DarkTheme") == true)) {
            loadTheme();
        }
        if (_background != null) {
            dc.drawBitmap(0, 0, _background);
        }
        var red = SpeedometerGeometry.redLabel(clock.hour);
        if (red == 1 && _redOne != null) {
            dc.drawBitmap(173, 355, _redOne);
        } else if (red == 2 && _redTwo != null) {
            dc.drawBitmap(100, 317, _redTwo);
        }
        if (_needle != null) {
            _xf.setToTranslation(SpeedometerGeometry.PIVOT_X.toFloat(), SpeedometerGeometry.PIVOT_Y.toFloat());
            _xf.rotate(SpeedometerGeometry.needleAngle(clock.hour));
            _xf.translate(-34.0f, -34.0f);
            dc.drawBitmap2(0, 0, _needle, {
                :transform => _xf,
                :filterMode => Graphics.FILTER_MODE_BILINEAR
            });
        }
        // Screen/bezel sits in front of the needle at hours 6–8. Restore it
        // before drawing minutes so the pointer cannot obscure the display.
        if (_window != null) {
            dc.drawBitmap(184, 94, _window);
        }
        drawPair(dc, clock.min, 204, 127, 20, 29, 4);
        drawPair(dc, date.day, 262, 326, 14, 21, 3);
        drawPair(dc, date.month, 307, 326, 14, 21, 3);
        dc.setColor(0xFF3010, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(298, 336, 6, 2);
    }

    private function drawPair(dc as Dc, value as Number, x as Number, y as Number,
                              width as Number, height as Number, gap as Number) as Void {
        drawDigit(dc, (value / 10).toNumber(), x, y, width, height);
        drawDigit(dc, value % 10, x + width + gap, y, width, height);
    }

    private function drawDigit(dc as Dc, value as Number, x as Number, y as Number,
                               width as Number, height as Number) as Void {
        _xf.setToTranslation(x.toFloat(), y.toFloat());
        _xf.scale(width / 20.0f, height / 29.0f);
        dc.drawBitmap2(0, 0, _digits[value], {
            :transform => _xf,
            :filterMode => Graphics.FILTER_MODE_BILINEAR
        });
    }

    private function drawAlwaysOn(dc as Dc, hour as Number, minute as Number,
                                 day as Number, month as Number) as Void {
        var y = SpeedometerGeometry.aodY(minute);
        var text = SpeedometerGeometry.dialHour(hour).format("%02d") + ":" + minute.format("%02d");
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(227, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        var date = day.format("%02d") + "-" + month.format("%02d");
        dc.drawText(227, y + 32, Graphics.FONT_XTINY, date, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
