using Toybox.Application;
using Toybox.System;
using Toybox.Time;
using Toybox.Background;
using Toybox.WatchUi;
using Toybox.FitContributor;
import Toybox.Lang;
using Toybox.Position;

var aqiData = null;
var aqiField = null;
var temperatureField = null;
var temperatureValue = null;
const intervalKey = "refreshInterval";

(:background)
class AQI_DataFieldApp extends Application.AppBase {

	const myKey = "aqidata";
	const pm2_5 = "PM2.5";
	const enableNotificationsKey = "enableNotifications";
	var enableNotifications = false;
	var inBackground = false;
	var aqiProvider = 1;
	var fieldIsDirty = true;
			
	function readKeyBool(myApp,key,thisDefault) {
	    var value = myApp.getProperty(key);
	    if(value == null || !(value instanceof Boolean)) {
	        if(value != null) {
	            value = value == "true";
	        } else {
	            value = thisDefault;
	        }
	    }
	    return value;
	}
	
	function readKeyInt(myApp,key,thisDefault) {
	    var value = myApp.getProperty(key);
		if (value == null) {
			return thisDefault;
		}
	    if (!(value instanceof Number)) {
			return value.toNumber();
	    }
	    return value;
	}
					
    function initialize() {
        AppBase.initialize();
        // read what's in storage
        if (Application has :Storage) {
	        aqiData = Application.Storage.getValue(myKey);
	        if (Application has :Properties) {
	        	enableNotifications = readKeyBool(getApp(), enableNotificationsKey, false);
		        aqiProvider = readKeyInt(getApp(), "aqiProvider", 1);
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
    
    function onBackgroundData(data_raw as Application.PersistableType) {
    	var now=System.getClockTime();
    	var ts=now.hour+":"+now.min.format("%02d");
        System.println("onBackgroundData=" + data_raw + " at " + ts);
        if (data_raw != null) {
			var data = data_raw as Lang.Dictionary;
			if (data.hasKey("Temperature")) {
				temperatureValue = data.get("Temperature");
			}
        	if (data.hasKey("PM2.5")) {
        		if (aqiField != null) {
	        		if (fieldIsDirty || aqiData.get(pm2_5) != data.get(pm2_5)) {
						var pm_2_5_value = data.get(pm2_5);
						var pm_2_5_is_number = false;
						if (pm_2_5_value instanceof Toybox.Lang.Number) {
							pm_2_5_is_number = true;
						}
	        			if (pm_2_5_value == null || !pm_2_5_is_number) {
	        				aqiField.setData(0);
	        			} else {
		    				//System.println("About to set field to " + data.get(pm2_5));
							aqiField.setData(data.get(pm2_5));
						}
						fieldIsDirty = false;
					}
        		}
        		aqiData = data;
				if (temperatureField != null && temperatureValue != null && temperatureValue instanceof Toybox.Lang.Number) {
					temperatureField.setData(temperatureValue);
				}
    		} else if (data.hasKey("error")) {
    			if (Application.Properties.getValue("zerosForNoData") && aqiField != null) {
    				aqiField.setData(0);
    				fieldIsDirty = true;
    				System.println("Recording zero for error fetching AQI");
    			}
    			if (aqiData == null) {
    				aqiData = { "error" => data.get("error"), "hideError" => data.get("hideError") };
    			} else {
    				aqiData.put("error", data.get("error"));
    				aqiData.put("hideError", data.get("hideError"));
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
				if (aqiData instanceof Dictionary) {
					Application.Storage.setValue("aqidata", aqiData);
				}
    		}
    	}
    }     

}