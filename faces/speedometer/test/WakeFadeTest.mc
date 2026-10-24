import Toybox.Lang;
import Toybox.Test;

// Pure state tests: deliberately never start an SDK Timer from the test runner.
module WakeFadeTest {
    (:test)
    function testWakeEligibility(logger as Test.Logger) as Boolean {
        for (var flags = 0; flags < 16; flags++) {
            var allowed = WakeFade.allowed((flags & 1) != 0, (flags & 2) != 0,
                                           (flags & 4) != 0, (flags & 8) != 0);
            if (allowed != (flags == 6)) { return false; }
        }
        return true;
    }

    (:test)
    function testWakeTiming(logger as Test.Logger) as Boolean {
        var previous = 0;
        for (var elapsed = -50; elapsed <= 400; elapsed++) {
            var frame = WakeFade.frameAt(elapsed);
            if (frame < previous || frame < 0 || frame > WakeFade.LAST_FRAME) {
                return false;
            }
            previous = frame;
        }
        return WakeFade.frameAt(0) == 0 && WakeFade.frameAt(50) == 1 &&
               WakeFade.frameAt(150) == 3 && WakeFade.frameAt(300) == 6;
    }

    (:test)
    function testWakeStateAndSkippedFrames(logger as Test.Logger) as Boolean {
        var state = new WakeFadeState();
        if (state.advance(500, true) != 6 || state.isActive()) { return false; }
        state.queue();
        if (state.advance(1000, true) != 0 || !state.isActive()) { return false; }
        if (state.advance(1050, true) != 1) { return false; }
        // Slow rendering skips ahead rather than extending a callback counter.
        if (state.advance(1265, true) != 5) { return false; }
        if (state.advance(1400, true) != 6 || state.isActive()) { return false; }
        return state.advance(2000, true) == 6 && !state.isActive();
    }

    (:test)
    function testWakeCancellationAndRestart(logger as Test.Logger) as Boolean {
        var state = new WakeFadeState();
        state.queue();
        state.cancel();
        if (state.advance(1000, true) != 6 || state.isActive()) { return false; }
        state.queue();
        state.advance(1100, true);
        state.advance(1200, true);
        // Sleep, hide, disabling, or dark preference all deny eligibility.
        if (state.advance(1220, false) != 6 || state.isActive()) { return false; }
        if (state.advance(1250, true) != 6 || state.isActive()) { return false; }
        state.queue();
        if (state.advance(2000, true) != 0 || !state.isActive()) { return false; }
        state.cancel();
        return state.advance(2050, true) == 6 && !state.isActive();
    }
}
