import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class HermesFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new HermesFaceView();
        if (WatchUi has :WatchFaceDelegate) {
            return [view, new HermesFaceDelegate(view)];
        }
        return [view];
    }
}

function getApp() as HermesFaceApp {
    return Application.getApp() as HermesFaceApp;
}
