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
        loadTheme(Application.Properties.getValue("DarkTheme") == true);
    }

    private function loadTheme(dark as Boolean) as Void {
        _dark = dark;
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
        // Use the supplied dark artwork for AOD, without dimming or replacing
        // it, so its actual burn-in/coverage can be evaluated in the simulator.
        var dark = SpeedometerGeometry.useDarkTheme(lowPower,
            Application.Properties.getValue("DarkTheme") == true);
        if (_dark != dark) {
            loadTheme(dark);
        }
        if (_background != null) {
            dc.drawBitmap(0, 0, _background);
        }
        var red = SpeedometerGeometry.redLabel(clock.hour);
        if (red == 1 && _redOne != null) {
            dc.drawBitmap(168, 368, _redOne);
        } else if (red == 2 && _redTwo != null) {
            dc.drawBitmap(87, 326, _redTwo);
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
            dc.drawBitmap(180, 81, _window);
        }
        drawPair(dc, clock.min, 202, 117, 20, 29, 4);
        drawPair(dc, date.day, 266, 336, 14, 21, 3);
        drawPair(dc, date.month, 315, 336, 14, 21, 3);
        dc.setColor(0xFF3010, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(305, 347, 6, 2);
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

}
