import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class HermesFaceDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as HermesFaceView;

    function initialize(view as HermesFaceView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        System.println("partial-update budget exceeded avg=" + powerInfo.executionTimeAverage.toString());
        _view.turnPartialUpdatesOff();
    }
}
