import Toybox.Lang;

// Pure timing/state logic; no SDK Timer is ever started in this module.
module WakeFade {
    const DURATION_MS = 300;
    const INTERVAL_MS = 50;
    const LAST_FRAME = 6;

    function allowed(lowPower as Boolean, visible as Boolean,
                     enabled as Boolean, darkTheme as Boolean) as Boolean {
        return !lowPower && visible && enabled && !darkTheme;
    }

    function frameAt(elapsed as Number) as Number {
        if (elapsed <= 0) { return 0; }
        if (elapsed >= DURATION_MS) { return LAST_FRAME; }
        return (elapsed * LAST_FRAME / DURATION_MS).toNumber();
    }
}

class WakeFadeState {
    private var _pending as Boolean;
    private var _active as Boolean;
    private var _startedAt as Number;
    private var _frame as Number;

    function initialize() {
        _pending = false;
        _active = false;
        _startedAt = 0;
        _frame = WakeFade.LAST_FRAME;
    }

    function queue() as Void {
        cancel();
        _pending = true;
    }

    function cancel() as Void {
        _pending = false;
        _active = false;
        _frame = WakeFade.LAST_FRAME;
    }

    function isActive() as Boolean {
        return _active;
    }

    // Start only on the first confirmed high-power draw. Elapsed wall time,
    // not callback count, chooses the frame so slow draws skip ahead.
    function advance(now as Number, canAnimate as Boolean) as Number {
        if (!canAnimate) {
            cancel();
            return _frame;
        }
        if (_pending) {
            _pending = false;
            _active = true;
            _startedAt = now;
        }
        if (_active) {
            _frame = WakeFade.frameAt(now - _startedAt);
            if (_frame == WakeFade.LAST_FRAME) {
                _active = false;
            }
        }
        return _frame;
    }
}
