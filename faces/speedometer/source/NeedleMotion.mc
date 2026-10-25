import Toybox.Lang;

// Pure state/timing logic. Only the view may start an SDK Timer.
module NeedleMotion {
    const WAKE_MS = 500;
    const RETURN_MS = 350;
    const FRAME_MS = 50;

    function interpolate(startAngle as Float, target as Float, elapsed as Number,
                         duration as Number) as Float {
        if (elapsed <= 0) { return startAngle; }
        if (elapsed >= duration) { return target; }
        var t = elapsed / duration.toFloat();
        var eased = t * t * (3.0f - 2.0f * t);
        return startAngle + (target - startAngle) * eased;
    }
}

class NeedleMotor {
    private var _angle as Float = 0.0f;
    private var _from as Float = 0.0f;
    private var _target as Float = 0.0f;
    private var _startedAt as Number = 0;
    private var _duration as Number = 0;
    private var _lastSecond as Number = 0;
    private var _initialized as Boolean = false;
    private var _pending as Boolean = false;
    private var _moving as Boolean = false;

    function initialize() {}

    function park() as Void {
        // Keep the last rendered angle, including an interrupted animation.
        _pending = false;
        _moving = false;
    }

    function wake() as Void {
        park();
        _pending = true;
    }

    function isMoving() as Boolean { return _moving; }
    function angle() as Float { return _angle; }

    private function begin(now as Number, target as Float, duration as Number) as Void {
        _from = _angle;
        _target = target;
        _startedAt = now;
        _duration = duration;
        _moving = _from != _target;
    }

    function sample(now as Number, second as Number, lowPower as Boolean) as Float {
        var target = SpeedometerGeometry.secondsNeedleAngle(second);
        if (!_initialized) {
            // No parked position exists on cold start, including first launch
            // directly into AOD. Seed once without an artificial rev from zero.
            _initialized = true;
            _angle = target;
            _lastSecond = second;
            park();
            return _angle;
        }
        if (lowPower) {
            // Freeze even if native display mode lags onExitSleep. Keep a
            // queued wake for the first confirmed high-power draw; explicit
            // sleep/hide park() calls still cancel it immediately.
            _moving = false;
            return _angle;
        }
        if (_pending) {
            _pending = false;
            begin(now, target, NeedleMotion.WAKE_MS);
        } else if (second < _lastSecond) {
            // Return across the gauge arc, never spin through the unused gap.
            // Also handles a rollover occurring during the wake animation.
            begin(now, target, NeedleMotion.RETURN_MS);
        } else if (!_moving) {
            _angle = target;
        } else {
            // Catch the live second even if a second ticks over mid-animation.
            _target = target;
        }
        _lastSecond = second;
        if (_moving) {
            var elapsed = now - _startedAt;
            _angle = NeedleMotion.interpolate(_from, _target, elapsed, _duration);
            if (elapsed >= _duration) { _moving = false; }
        }
        return _angle;
    }
}
