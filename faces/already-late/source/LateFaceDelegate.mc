import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class LateFaceDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as LateFaceView;

    function initialize(view as LateFaceView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        System.println("partial-update budget exceeded avg=" + powerInfo.executionTimeAverage.toString());
        _view.turnPartialUpdatesOff();
    }
}
