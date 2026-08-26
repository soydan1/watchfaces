import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class LateFaceView extends WatchUi.WatchFace {

    private var _isAwake as Boolean;
    private var _partialUpdatesAllowed as Boolean;
    private var _dial as BitmapType?;
    private var _hourHand as BitmapType?;
    private var _minuteHand as BitmapType?;
    private var _secondHand as BitmapType?;
    private var _arbor as BitmapType?;
    private var _handXform as AffineTransform;
    private var _handOpts as { :transform as AffineTransform, :filterMode as FilterMode };

    function initialize() {
        WatchFace.initialize();
        _isAwake = true;
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _handXform = new AffineTransform();
        _handOpts = {
            :transform => _handXform,
            :filterMode => Graphics.FILTER_MODE_POINT
        };
    }

    function onLayout(dc as Dc) as Void {
        _dial = WatchUi.loadResource($.Rez.Drawables.Dial) as BitmapType;
        _hourHand = WatchUi.loadResource($.Rez.Drawables.HourHand) as BitmapType;
        _minuteHand = WatchUi.loadResource($.Rez.Drawables.MinuteHand) as BitmapType;
        _secondHand = WatchUi.loadResource($.Rez.Drawables.SecondHand) as BitmapType;
        _arbor = WatchUi.loadResource($.Rez.Drawables.Arbor) as BitmapType;
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

    // High power and AOD share the same black/orange drawing.
    // AOD drops the seconds hand and applies the burn-in orbit.
    private function drawFace(dc as Dc, drawSeconds as Boolean) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var clockTime = System.getClockTime();
        var cx = width / 2;
        var cy = height / 2;
        if (!drawSeconds) {
            var shift = LateGeometry.burnInShift(clockTime.min);
            cx += shift[0];
            cy += shift[1];
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var dialBmp = _dial;
        if (dialBmp != null) {
            dc.drawBitmap(
                cx - LateGeometry.DIAL_RADIUS,
                cy - LateGeometry.DIAL_RADIUS,
                dialBmp
            );
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
