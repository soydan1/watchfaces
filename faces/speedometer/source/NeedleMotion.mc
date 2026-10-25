import Toybox.Lang;

// Pure state/timing logic. Only the view may start an SDK Timer.
module NeedleMotion {
    const WAKE_MS = 500;
    const RETURN_MS = 350;
    const FRAME_MS = 50;
    const FOLLOW_MS = 80;

    // Suppress small phase corrections without making a step in needle angle.
    function follow(startAngle as Float, target as Float, elapsed as Number) as Float {
        if (elapsed <= 0) { return startAngle; }
        var gain = elapsed / (FOLLOW_MS + elapsed).toFloat();
        return startAngle + (target - startAngle) * gain;
    }

    function interpolate(startAngle as Float, target as Float, elapsed as Number,
                         duration as Number) as Float {
        if (elapsed <= 0) { return startAngle; }
        if (elapsed >= duration) { return target; }
        var t = elapsed / duration.toFloat();
        var eased = t * t * (3.0f - 2.0f * t);
        return startAngle + (target - startAngle) * eased;
    }
}

// ClockTime exposes whole seconds only. Estimate the fraction from observed
// second edges and the monotonic timer; do not anticipate a minute rollover.
// Initial fractional phase is unknown until the first observed clock edge.
class SecondPhase {
    private var _second as Number = -1;
    private var _edgeAt as Number = 0;

    function initialize() {}
    function reset() as Void { _second = -1; }

    function sample(now as Number, second as Number) as Float {
        if (second != _second) {
            _second = second;
            _edgeAt = now;
        }
        var fraction = (now - _edgeAt) / 1000.0f;
        if (fraction < 0.0f) { fraction = 0.0f; }
        if (fraction > 0.999f) { fraction = 0.999f; }
        return second.toFloat() + fraction;
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
    private var _lastSampleAt as Number = 0;
    private var _phase as SecondPhase;

    function initialize() {
        _phase = new SecondPhase();
    }

    function park() as Void {
        // Keep the last rendered angle, including an interrupted animation.
        _pending = false;
        _moving = false;
        _phase.reset();
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
        _phase.reset();
        return samplePosition(now, second.toFloat(), lowPower, false);
    }

    function sampleSmooth(now as Number, second as Number, lowPower as Boolean) as Float {
        var position = second.toFloat();
        if (lowPower) {
            _phase.reset();
        } else {
            position = _phase.sample(now, second);
        }
        return samplePosition(now, position, lowPower, true);
    }

    private function samplePosition(now as Number, position as Float,
                                    lowPower as Boolean, smooth as Boolean) as Float {
        var second = position.toNumber();
        var target = SpeedometerGeometry.sweepNeedleAngle(position);
        var delta = now - _lastSampleAt;
        _lastSampleAt = now;
        if (!_initialized) {
            // No parked position exists on cold start, including first launch
            // directly into AOD. Seed once without an artificial rev from zero.
            _initialized = true;
            _angle = target;
            _lastSecond = second;
            _pending = false;
            _moving = false;
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
            _angle = smooth ? NeedleMotion.follow(_angle, target, delta) : target;
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
