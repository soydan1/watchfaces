import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SpeedometerApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] {
        return [new SpeedometerView()];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
