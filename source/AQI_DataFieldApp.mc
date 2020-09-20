using Toybox.Application;
using Toybox.System;
using Toybox.Time;
using Toybox.Background;
using Toybox.WatchUi;
using Toybox.FitContributor;

using Toybox.Position;

var aqiData = null;
var aqiField = null;

class AQI_DataFieldApp extends Application.AppBase {

	const myKey = "aqidata";
	const intervalKey = "refreshInterval";
	const enableNotificationsKey = "enableNotifications";
	const bgIntervalDefault = 5 * 60;
	var bgInterval;
	var enableNotifications = false;
	var inBackground = false;
	var aqiProvider = 1;
	
    function initialize() {
        AppBase.initialize();
        // read what's in storage
        if (Application has :Storage) {
	        aqiData = Application.Storage.getValue(myKey);
	        bgInterval = Application.Properties.getValue(intervalKey);
	        enableNotifications = Application.Properties.getValue(enableNotificationsKey);
	        aqiProvider = Application.Properties.getValue("aqiProvider");
        }
        if (bgInterval == null) {
        	bgInterval = bgIntervalDefault;
    	}        
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	if(!inBackground) {
    		Background.deleteTemporalEvent();
    	}
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	var view;
    	
		Application.Properties.setValue(intervalKey, bgInterval);
		//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		Background.registerForTemporalEvent(new Time.Duration(bgInterval));
    	} else {
    		System.println("****background not available on this device****");
    	}
    	view = new AQI_DataFieldView(enableNotifications);
        return [ view, new TouchDelegate(view) ];
    }
    
    function getServiceDelegate(){
    	//only called in the background	
    	inBackground = true;
        return [new AQIServiceDelgate(bgInterval, aqiProvider)];
    }
    
    function onBackgroundData(data) {
    	var now=System.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        System.println("onBackgroundData=" + data + " at " + ts);
        if (data != null) {
        	if (data.hasKey("PM2.5")) {
        		if (aqiData == null || aqiData.get("PM2.5") != data.get("PM2.5")) {
					aqiField.setData(data["PM2.5"]);
        		}
        		aqiData = data;
    		} else if (data.hasKey("error")) {
    			aqiData.put("error", data.get("error"));
			} else {
				aqiData.put("error", "No data available");
			}
			if (Application has :Storage) {
        		Application.Storage.setValue(myKey, aqiData);
    		}
    	}
    }     

}