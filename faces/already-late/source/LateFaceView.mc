import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class LateFaceView extends WatchUi.WatchFace {

    private var _isAwake as Boolean;
    private var _partialUpdatesAllowed as Boolean;
    private var _dial as BitmapType?;
    private var _aodDial as BitmapType?;
    private var _hourHand as BitmapType?;
    private var _minuteHand as BitmapType?;
    private var _secondHand as BitmapType?;
    private var _arbor as BitmapType?;
    private var _dateGlyphs as Array<BitmapType?>;
    private var _handXform as AffineTransform;
    private var _handOpts as { :transform as AffineTransform, :filterMode as FilterMode };

    function initialize() {
        WatchFace.initialize();
        _isAwake = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _dateGlyphs = new [12] as Array<BitmapType?>;
        _handXform = new AffineTransform();
        _handOpts = {
            :transform => _handXform,
            :filterMode => Graphics.FILTER_MODE_POINT
        };
    }

    function onLayout(dc as Dc) as Void {
        _dial = WatchUi.loadResource($.Rez.Drawables.Dial) as BitmapType;
        _aodDial = WatchUi.loadResource($.Rez.Drawables.AodDial) as BitmapType;
        _hourHand = WatchUi.loadResource($.Rez.Drawables.HourHand) as BitmapType;
        _minuteHand = WatchUi.loadResource($.Rez.Drawables.MinuteHand) as BitmapType;
        _secondHand = WatchUi.loadResource($.Rez.Drawables.SecondHand) as BitmapType;
        _arbor = WatchUi.loadResource($.Rez.Drawables.Arbor) as BitmapType;
        _dateGlyphs[0] = WatchUi.loadResource($.Rez.Drawables.Date1) as BitmapType;
        _dateGlyphs[1] = WatchUi.loadResource($.Rez.Drawables.Date2) as BitmapType;
        _dateGlyphs[2] = WatchUi.loadResource($.Rez.Drawables.Date3) as BitmapType;
        _dateGlyphs[3] = WatchUi.loadResource($.Rez.Drawables.Date4) as BitmapType;
        _dateGlyphs[4] = WatchUi.loadResource($.Rez.Drawables.Date5) as BitmapType;
        _dateGlyphs[5] = WatchUi.loadResource($.Rez.Drawables.Date6) as BitmapType;
        _dateGlyphs[6] = WatchUi.loadResource($.Rez.Drawables.Date7) as BitmapType;
        _dateGlyphs[7] = WatchUi.loadResource($.Rez.Drawables.Date8) as BitmapType;
        _dateGlyphs[8] = WatchUi.loadResource($.Rez.Drawables.Date9) as BitmapType;
        _dateGlyphs[9] = WatchUi.loadResource($.Rez.Drawables.Date10) as BitmapType;
        _dateGlyphs[10] = WatchUi.loadResource($.Rez.Drawables.Date11) as BitmapType;
        _dateGlyphs[11] = WatchUi.loadResource($.Rez.Drawables.Date12) as BitmapType;
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
        var lowPower = isLowPower();
        if (lowPower) {
            drawFace(dc, false);
        } else {
            drawFace(dc, true);
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

    // High power: numberless plate + red date. AOD: numbered plate, no date.
    private function drawFace(dc as Dc, drawSeconds as Boolean) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var clockTime = System.getClockTime();
        var cx = width / 2;
        var cy = height / 2;
        // Same 1 px orbit in high power and AOD so the crown/text do not jump.
        var shift = LateGeometry.burnInShift(clockTime.min);
        cx += shift[0];
        cy += shift[1];

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var dialBmp = drawSeconds ? _aodDial : _dial;
        if (dialBmp == null) {
            dialBmp = _dial;
        }
        if (dialBmp != null) {
            dc.drawBitmap(
                cx - LateGeometry.DIAL_RADIUS,
                cy - LateGeometry.DIAL_RADIUS,
                dialBmp
            );
        }

        if (drawSeconds) {
            drawDate(dc, cx, cy);
        }

        var hourBmp = _hourHand;
        if (hourBmp != null) {
            drawHand(
                dc,
                hourBmp,
                cx,
                cy,
                LateGeometry.hourAngle(clockTime.hour, clockTime.min),
                LateGeometry.HOUR_PIVOT_X,
                LateGeometry.HOUR_PIVOT_Y
            );
        }
        var minuteBmp = _minuteHand;
        if (minuteBmp != null) {
            drawHand(
                dc,
                minuteBmp,
                cx,
                cy,
                LateGeometry.minuteAngle(clockTime.min),
                LateGeometry.MINUTE_PIVOT_X,
                LateGeometry.MINUTE_PIVOT_Y
            );
        }
        if (drawSeconds) {
            var secondBmp = _secondHand;
            if (secondBmp != null) {
                drawHand(
                    dc,
                    secondBmp,
                    cx,
                    cy,
                    LateGeometry.secondAngle(clockTime.sec),
                    LateGeometry.SECOND_PIVOT_X,
                    LateGeometry.SECOND_PIVOT_Y
                );
            }
        }

        // Center cap last, unrotated, so it covers the hand intersection.
        var arborBmp = _arbor;
        if (arborBmp != null) {
            dc.drawBitmap(
                cx - LateGeometry.ARBOR_PIVOT_X,
                cy - LateGeometry.ARBOR_PIVOT_Y,
                arborBmp
            );
        }
    }

    private function drawDate(dc as Dc, cx as Number, cy as Number) as Void {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var numerals = LateGeometry.dateNumerals(info.day);
        var left = cx - LateGeometry.DIAL_RADIUS;
        var top = cy - LateGeometry.DIAL_RADIUS;
        var glyphs = _dateGlyphs;
        for (var i = 0; i < numerals.size(); i++) {
            var n = numerals[i];
            if ((n < 1) || (n > 12)) {
                continue;
            }
            var bmp = glyphs[n - 1];
            if (bmp != null) {
                dc.drawBitmap(
                    left + LateGeometry.DATE_GLYPH_X[n - 1],
                    top + LateGeometry.DATE_GLYPH_Y[n - 1],
                    bmp
                );
            }
        }
    }

    private function drawHand(
        dc as Dc,
        bitmap as BitmapType,
        cx as Number,
        cy as Number,
        angle as Float,
        pivotX as Number,
        pivotY as Number
    ) as Void {
        var t = _handXform;
        t.setToTranslation(cx.toFloat(), cy.toFloat());
        t.rotate(angle);
        t.translate(0 - pivotX.toFloat(), 0 - pivotY.toFloat());
        dc.drawBitmap2(0, 0, bitmap, _handOpts);
    }
}
