using Toybox.Application;
using Toybox.System;
using Toybox.Time;
using Toybox.Background;
using Toybox.WatchUi;
using Toybox.FitContributor;

using Toybox.Position;

var aqiData = null;
var aqiField = null;
const intervalKey = "refreshInterval";

class AQI_DataFieldApp extends Application.AppBase {

	const myKey = "aqidata";
	const enableNotificationsKey = "enableNotifications";
	var enableNotifications = false;
	var inBackground = false;
	var aqiProvider = 1;
	var fieldIsDirty = true;
	
    function initialize() {
        AppBase.initialize();
        // read what's in storage
        if (Application has :Storage) {
	        aqiData = Application.Storage.getValue(myKey);
	        if (Application has :Properties) {
	        	try {
		        	enableNotifications = Application.Properties.getValue("enableNotifications");
	        	} catch (ex) {
	        		System.println("Error getting notifications setting " + ex);
	        	}
		        aqiProvider = Application.Properties.getValue("aqiProvider");
	        }
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
    	
		//register for temporal events if they are supported
    	if(Toybox.System has :ServiceDelegate) {
    		Background.registerForTemporalEvent(new Time.Duration(Application.Properties.getValue(intervalKey)));
    	} else {
    		System.println("****background not available on this device****");
    	}
    	view = new AQI_DataFieldView(enableNotifications);
        return [ view, new TouchDelegate(view) ];
    }
    
    function getServiceDelegate(){
    	//only called in the background	
    	inBackground = true;
        return [new AQIServiceDelgate()];
    }
    
    function onBackgroundData(data) {
    	var now=System.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        System.println("onBackgroundData=" + data + " at " + ts);
        if (data != null) {
        	if (data.hasKey("PM2.5")) {
        		if (aqiField != null) {
	        		if (fieldIsDirty || aqiData.get("PM2.5") != data.get("PM2.5")) {
	    				System.println("About to set field to " + data.get("PM2.5"));
						aqiField.setData(data.get("PM2.5"));
						fieldIsDirty = false;
					}
        		}
        		aqiData = data;
    		} else if (data.hasKey("error")) {
    			if (Application.Properties.getValue("zerosForNoData") && aqiField != null) {
    				aqiField.setData(0);
    				fieldIsDirty = true;
    				System.println("Recording zero for error fetching AQI");
    			}
    			if (aqiData == null) {
    				aqiData = { "error" => data.get("error") };
    			} else {
    				aqiData.put("error", data.get("error"));
				}
			} else {
    			if (Application.Properties.getValue("zerosForNoData") && aqiField != null) {
    				aqiField.setData(0);
    				fieldIsDirty = true;
    				System.println("Recording zero for missing AQI");
    			}
    			if (aqiData == null) {
    				aqiData = { "error" => "No data available" };
				} else {			
					aqiData.put("error", "No data available");
				}
			}
			if (Application has :Storage) {
        		Application.Storage.setValue(myKey, aqiData);
    		}
    	}
    }     

}