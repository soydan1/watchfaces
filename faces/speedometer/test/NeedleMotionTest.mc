import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

// Pure tests: no SDK Timer, drawing, or low-power animation is invoked.
module NeedleMotionTest {
    (:test)
    function testFractionalArc(logger as Test.Logger) as Boolean {
        var previous = -1.0f;
        for (var tenth = 0; tenth <= 600; tenth++) {
            var angle = SpeedometerGeometry.sweepNeedleAngle(tenth / 10.0f);
            if (angle <= previous) { return false; }
            previous = angle;
        }
        return Math.abs(SpeedometerGeometry.sweepNeedleAngle(6.0f) -
                        SpeedometerGeometry.secondsNeedleAngle(6)) < 0.00001f;
    }

    (:test)
    function testPhaseEdges(logger as Test.Logger) as Boolean {
        var phase = new SecondPhase();
        if (phase.sample(1000, 20) != 20.0f) { return false; }
        if (Math.abs(phase.sample(1500, 20) - 20.5f) > 0.00001f) { return false; }
        if (phase.sample(2000, 21) != 21.0f) { return false; }
        if (phase.sample(3500, 21) >= 22.0f) { return false; }
        phase.reset();
        if (phase.sample(9000, 59) != 59.0f) { return false; }
        if (phase.sample(9500, 59) != 59.5f) { return false; }
        return phase.sample(10000, 0) == 0.0f;
    }

    (:test)
    function testSmoothSteadyParkAndWake(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        var first = motor.sampleSmooth(1000, 10, false);
        var next = motor.sampleSmooth(1050, 10, false);
        var third = motor.sampleSmooth(1100, 10, false);
        if (next <= first || third <= next || motor.isMoving()) { return false; }
        motor.park();
        if (motor.sampleSmooth(5000, 47, true) != third) { return false; }
        if (motor.sampleSmooth(15000, 0, true) != third) { return false; }
        motor.wake();
        if (motor.sampleSmooth(16000, 20, false) != third || !motor.isMoving()) { return false; }
        var target = SpeedometerGeometry.sweepNeedleAngle(20.5f);
        return motor.sampleSmooth(16500, 20, false) == target && !motor.isMoving();
    }

    (:test)
    function testSmoothReturnAndModeSwitch(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        motor.sampleSmooth(0, 59, false);
        var high = motor.sampleSmooth(900, 59, false);
        if (motor.sampleSmooth(1000, 0, false) != high || !motor.isMoving()) { return false; }
        var low = motor.sampleSmooth(1350, 0, false);
        if (low >= high || motor.isMoving()) { return false; }
        if (Math.abs(low - SpeedometerGeometry.sweepNeedleAngle(0.35f)) > 0.00001f) { return false; }
        // Disabling smooth mode restores the exact whole-second position.
        if (motor.sample(1400, 0, false) != SpeedometerGeometry.secondsNeedleAngle(0)) { return false; }
        motor.sampleSmooth(1450, 0, false);
        return motor.sampleSmooth(1500, 0, false) > SpeedometerGeometry.secondsNeedleAngle(0);
    }

    (:test)
    function testSecondsArc(logger as Test.Logger) as Boolean {
        var previous = SpeedometerGeometry.secondsNeedleAngle(0);
        for (var second = 1; second <= 60; second++) {
            var angle = SpeedometerGeometry.secondsNeedleAngle(second);
            if (angle <= previous || angle > SpeedometerGeometry.gaugeAngle(10)) { return false; }
            previous = angle;
        }
        for (var label = 0; label <= 10; label++) {
            if (Math.abs(SpeedometerGeometry.secondsNeedleAngle(label * 6) -
                         SpeedometerGeometry.gaugeAngle(label)) > 0.00001f) { return false; }
        }
        return true;
    }

    (:test)
    function testParkAndWake(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        motor.wake();
        var parked = motor.sample(0, 8, false);
        if (motor.isMoving()) { return false; }
        motor.park();
        if (motor.sample(10000, 30, true) != parked || motor.isMoving()) { return false; }
        if (motor.sample(20000, 50, true) != parked) { return false; }
        motor.wake();
        if (motor.sample(21000, 47, false) != parked || !motor.isMoving()) { return false; }
        var halfway = motor.sample(21250, 47, false);
        var target = SpeedometerGeometry.secondsNeedleAngle(47);
        if (halfway <= parked || halfway >= target) { return false; }
        return motor.sample(21500, 47, false) == target && !motor.isMoving();
    }

    (:test)
    function testReturnAndInterruptedMotion(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        var high = motor.sample(0, 59, false);
        if (motor.sample(1000, 0, false) != high || !motor.isMoving()) { return false; }
        var halfway = motor.sample(1175, 0, false);
        var zero = SpeedometerGeometry.secondsNeedleAngle(0);
        if (halfway >= high || halfway <= zero) { return false; }
        motor.park();
        if (motor.sample(5000, 35, true) != halfway || motor.isMoving()) { return false; }
        motor.wake();
        if (motor.sample(6000, 10, false) != halfway) { return false; }
        return motor.sample(6500, 10, false) == SpeedometerGeometry.secondsNeedleAngle(10)
            && !motor.isMoving();
    }

    (:test)
    function testLiveTargetAndWakeRollover(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        motor.sample(0, 5, false);
        motor.wake();
        motor.sample(1000, 58, false);
        motor.sample(1250, 59, false);
        var beforeReturn = motor.angle();
        if (motor.sample(1300, 0, false) != beforeReturn) { return false; }
        if (motor.sample(1650, 0, false) != SpeedometerGeometry.secondsNeedleAngle(0)
            || motor.isMoving()) { return false; }
        motor.wake();
        motor.sample(2000, 10, false);
        return motor.sample(2500, 11, false) == SpeedometerGeometry.secondsNeedleAngle(11)
            && !motor.isMoving();
    }

    (:test)
    function testDeferredWakeAndPendingCancellation(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        var parked = motor.sample(0, 8, false);
        motor.wake();
        if (motor.sample(1000, 47, true) != parked || motor.isMoving()) { return false; }
        if (motor.sample(1100, 47, false) != parked || !motor.isMoving()) { return false; }
        motor.park();
        motor.wake();
        motor.park();
        return motor.sample(2000, 50, false) == SpeedometerGeometry.secondsNeedleAngle(50)
            && !motor.isMoving();
    }

    (:test)
    function testColdAodAndNoopWake(logger as Test.Logger) as Boolean {
        var motor = new NeedleMotor();
        var parked = motor.sample(0, 20, true);
        if (motor.sample(10000, 59, true) != parked || motor.isMoving()) { return false; }
        motor.wake();
        return motor.sample(11000, 20, false) == parked && !motor.isMoving();
    }
}
