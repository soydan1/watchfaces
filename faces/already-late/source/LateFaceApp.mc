import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class LateFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new LateFaceView();
        if (WatchUi has :WatchFaceDelegate) {
            return [view, new LateFaceDelegate(view)];
        }
        return [view];
    }
}

function getApp() as LateFaceApp {
    return Application.getApp() as LateFaceApp;
}
