using Toybox.Application;
using Toybox.System;
using Toybox.Time;
using Toybox.Background;
using Toybox.WatchUi;

using Toybox.Position;

var myreturns = 0;
var aqiData = null;

class AQI_DataFieldApp extends Application.AppBase {

	var myKey = "aqidata";
	const intervalKey = "refreshInterval";
	const bgIntervalDefault = 5 * 60;
	var bgInterval;
	var viewCreated = false;
	
    function initialize() {
        AppBase.initialize();
        //read what's in storage
        aqiData = Application.Storage.getValue(myKey);
        bgInterval = Application.Properties.getValue(intervalKey);
        if (bgInterval == null) {
        	bgInterval = bgIntervalDefault;
    	}        
    	System.println("interval is " + bgInterval);
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
		Application.Properties.setValue(intervalKey, bgInterval);
		//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		Background.registerForTemporalEvent(new Time.Duration(bgInterval));
    	} else {
    		System.println("****background not available on this device****");
    	}
    	viewCreated = true;
        return [ new AQI_DataFieldView() ];
    }
    
    function getServiceDelegate(){
    	//only called in the background	
        return [new AQIServiceDelgate()];
    }
    
    function onBackgroundData(data) {
    	myreturns++;
    	var now=System.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        System.println("onBackgroundData="+data+" at "+ts);
        aqiData = data;
        Application.Storage.setValue(myKey, aqiData);
        if (viewCreated) {
        	WatchUi.requestUpdate();
    	}
    }     

}