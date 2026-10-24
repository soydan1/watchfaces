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
    private var _needle as BitmapResource?;
    private var _redOne as BitmapResource?;
    private var _redTwo as BitmapResource?;
    private var _digits as Array<BitmapResource>;
    private var _dateTens as Array<BitmapResource>;
    private var _xf as AffineTransform;
    private var _maxDrawMs as Number = 0;
    private var _maxObservedHeap as Number = 0;

    function initialize() {
        WatchFace.initialize();
        _background = null;
        _needle = null;
        _redOne = null;
        _redTwo = null;
        _digits = [];
        _dateTens = [];
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
        var dateIds = [Rez.Drawables.DateTens0, Rez.Drawables.DateTens1,
                       Rez.Drawables.DateTens2, Rez.Drawables.DateTens3];
        _dateTens = [];
        for (var j = 0; j < dateIds.size(); j++) {
            _dateTens.add(WatchUi.loadResource(dateIds[j]) as BitmapResource);
        }
        loadTheme(Application.Properties.getValue("DarkTheme") == true);
    }

    private function loadTheme(dark as Boolean) as Void {
        _dark = dark;
        // Only retain one plate at a time. No full-screen offscreen buffers.
        _background = null;
        _background = WatchUi.loadResource(_dark ? Rez.Drawables.BackgroundDark : Rez.Drawables.Background) as BitmapResource;
    }

    function onEnterSleep() as Void {
        _awake = false;
    }

    function onExitSleep() as Void {
        _awake = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var diagnostics = Application.Properties.getValue("Diagnostics") == true;
        var startedAt = diagnostics ? System.getTimer() : 0;
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
        var dateGauge = Application.Properties.getValue("DateGauge") != false;
        if (dateGauge) {
            drawDateGauge(dc, clock.hour, clock.min, date.day);
        } else {
            drawLegacyLayout(dc, clock.hour, clock.min, date.day, date.month);
        }
        var angle = dateGauge ? SpeedometerGeometry.dateNeedleAngle(date.day)
                              : SpeedometerGeometry.needleAngle(clock.hour);
        // Draw last: the needle must sit over the screen/bezel AND digits.
        if (_needle != null) {
            _xf.setToTranslation(SpeedometerGeometry.PIVOT_X.toFloat(), SpeedometerGeometry.PIVOT_Y.toFloat());
            _xf.rotate(angle);
            _xf.translate(-34.0f, -34.0f);
            dc.drawBitmap2(0, 0, _needle, {
                :transform => _xf,
                :filterMode => Graphics.FILTER_MODE_BILINEAR
            });
        }
        if (diagnostics) {
            logRenderStats(startedAt, lowPower, dateGauge);
        }
    }

    private function drawDateGauge(dc as Dc, hour as Number, minute as Number,
                                   day as Number) as Void {
        var tens = _dateTens[SpeedometerGeometry.dateTens(day)];
        dc.drawBitmap(227 - (tens.getWidth() / 2).toNumber(), 105, tens);
        var displayHour = SpeedometerGeometry.displayHour(hour);
        var x = SpeedometerGeometry.timeStartX(hour);
        drawPair(dc, displayHour, x, 323, 24, 48, 4);
        drawPair(dc, minute, x + 72, 323, 24, 48, 4);
        dc.setColor(SpeedometerGeometry.DISPLAY_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 60, 336, 4, 5);
        dc.fillRectangle(x + 60, 354, 4, 5);
    }

    private function drawLegacyLayout(dc as Dc, hour as Number, minute as Number,
                                      day as Number, month as Number) as Void {
        var red = SpeedometerGeometry.redLabel(hour);
        if (red == 1 && _redOne != null) {
            dc.drawBitmap(168, 368, _redOne);
        } else if (red == 2 && _redTwo != null) {
            dc.drawBitmap(87, 326, _redTwo);
        }
        drawPair(dc, minute, 196, 108, 28, 44, 6);
        var x = SpeedometerGeometry.dateStartX(day);
        drawPair(dc, day, x, 326, 24, 42, 4);
        drawPair(dc, month, x + 72, 326, 24, 42, 4);
        dc.setColor(SpeedometerGeometry.DISPLAY_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 58, 346, 8, 4);
    }

    private function drawPair(dc as Dc, value as Number, x as Number, y as Number,
                              width as Number, height as Number, gap as Number) as Void {
        drawDigit(dc, (value / 10).toNumber(), x, y, width, height);
        drawDigit(dc, value % 10, x + width + gap, y, width, height);
    }

    private function drawDigit(dc as Dc, value as Number, x as Number, y as Number,
                               width as Number, height as Number) as Void {
        // Minutes use native-size bitmaps: no resampling/transform required.
        if (width == 28 && height == 44) {
            dc.drawBitmap(x, y, _digits[value]);
            return;
        }
        _xf.setToTranslation(x.toFloat(), y.toFloat());
        _xf.scale(width / 28.0f, height / 44.0f);
        dc.drawBitmap2(0, 0, _digits[value], {
            :transform => _xf,
            :filterMode => Graphics.FILTER_MODE_BILINEAR
        });
    }

    private function logRenderStats(startedAt as Number, lowPower as Boolean,
                                    dateGauge as Boolean) as Void {
        var elapsed = System.getTimer() - startedAt;
        var used = System.getSystemStats().usedMemory;
        if (elapsed > _maxDrawMs) { _maxDrawMs = elapsed; }
        if (used > _maxObservedHeap) { _maxObservedHeap = used; }
        // Observed heap, not allocator peak; compare with simulator Memory view.
        System.println("Speedometer mode=" + (lowPower ? "aod" : "active")
            + " layout=" + (dateGauge ? "date" : "hour")
            + " dark=" + (_dark ? "true" : "false") + " drawMs=" + elapsed + " maxDrawMs=" + _maxDrawMs
            + " heap=" + used + " maxObservedHeap=" + _maxObservedHeap
            + " free=" + System.getSystemStats().freeMemory);
    }
}
