using Toybox.System;
using Toybox.Background;
using Toybox.Communications;
using Toybox.Position;
using Toybox.Application;

using Toybox.Time;

(:background)
class AQIServiceDelgate extends Toybox.System.ServiceDelegate {

		const minimumInterval = 5 * 60;
			
		function initialize() {
	  		ServiceDelegate.initialize();
	  	}

	function onTemporalEvent() {
    	var now=Toybox.System.getClockTime();	
		var ts=now.hour+":"+now.min.format("%02d");    
//    	System.println("onTemporalEvent: "+ts);
    	requestCurrentAqi();	
	}
	
	function requestCurrentAqi() {
		var position = Position.getInfo();
		if (position != null) {
			var coords = position.position;
			if (coords != null && position.accuracy > Position.QUALITY_POOR) {
//				System.println("Coordinates: " + coords.toGeoString(Position.GEO_DM) + " Accuracy: " + position.accuracy);
				var positionInDegrees = coords.toDegrees();
				if (positionInDegrees != null) {
//					System.println("Latitude " + positionInDegrees[0] + " longitude " + positionInDegrees[1]);
					makeRequest(positionInDegrees[0], positionInDegrees[1]);
				}
			} else {
				System.println("Null position field or poor accuracy; accuracy is " + position.accuracy);
			}
		} else {
			System.println("Null position at " + Toybox.System.getClockTime());
		}
	}
	
   // set up the response callback function
   function onReceive(responseCode, data) {
       var aqi = null;
       var interval = Application.Properties.getValue(intervalKey);
       if (responseCode == 200) {
           System.println("Request Successful " + data);           // print success
           if (data.isEmpty()) {
        	   interval = minimumInterval;
    	   }	           	
           aqi = data;
       }
       else if (responseCode == 429) {
	       System.println("Rate limited, wait forty minutes");
           aqi = { "error" => responseCode, "hideError" => true };
           if (data != null && !data.isEmpty()) {  
           	 System.println(data.keys());
           }
       	   interval = 60 * 40;
       }
       else {
           System.println("Response: " + responseCode + " data " + data);
           aqi = { "error" => responseCode };
           interval = minimumInterval;
       }
       aqi.put( "provider", Application.Properties.getValue("aqiProvider"));
	   Background.registerForTemporalEvent(new Time.Duration(interval));       
       Background.exit(aqi);
   }

	function makeRequest(latitude, longitude) {
       var urlBase = "https://aqi-gateway.herokuapp.com/";
       var url;
       var email = Application.Properties.getValue("email");
       var provider = Application.Properties.getValue("aqiProvider");
       if (provider == 1) {
       	   url = urlBase + "aqi";
       } else if (provider == 2) {
       	   url = urlBase + "purpleair";
   	   } else {
   	   	   url = urlBase + "iqair";
   	   }
   	   if (email == null || email == "--") {
            email = "";
   	   }
       var params = {                                              // set the parameters
              "lat" => latitude,
              "lon" => longitude,
              "device" => System.getDeviceSettings().partNumber,
              "sysId" => System.getDeviceSettings().uniqueIdentifier,
              "email" => email
       };
       var options = {                                             // set the options
           :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
           :headers => {                                           // set headers
                   "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON},
                                                                   // set response type
           :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
       };

       var responseCallback = method(:onReceive);                  // set responseCallback to
                                                                   // onReceive() method
       // Make the Communications.makeWebRequest() call
       Communications.makeWebRequest(url, params, options, method(:onReceive));
  }      
  
}
