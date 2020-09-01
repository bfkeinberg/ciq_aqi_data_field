using Toybox.System;
using Toybox.Background;
using Toybox.Communications;
using Toybox.Position;

using Toybox.Time;

(:background)
class AQIServiceDelgate extends Toybox.System.ServiceDelegate {
	var bgInterval;
	
	  function initialize(interval) {
	  	ServiceDelegate.initialize();
	  	bgInterval = interval;
	  }

	function onTemporalEvent() {
    	var now=Toybox.System.getClockTime();	
		var ts=now.hour+":"+now.min.format("%02d");    
    	System.println("onTemporalEvent: "+ts);
    	requestCurrentAqi();	
	}
	
	function requestCurrentAqi() {
		var position = Position.getInfo();
		if (position != null) {
			var coords = position.position;
			if (coords != null) {
				var positionInDegrees = coords.toDegrees();
				if (positionInDegrees != null) {
					System.println("Latitude " + positionInDegrees[0] + " longitude " + positionInDegrees[1]);
					makeRequest(positionInDegrees[0], positionInDegrees[1]);
				}
			}
		}
	}
	
   // set up the response callback function
   function onReceive(responseCode, data) {
   		var aqi = null;
       if (responseCode == 200) {
           System.println("Request Successful " + data);           // print success
           aqi = data;
       }
       else {
           System.println("Response: " + responseCode + " data " + data);            // print response code
           aqi = { "error" => responseCode };
       }
	   Background.registerForTemporalEvent(new Time.Duration(bgInterval));       
       Background.exit(aqi);
   }

	function makeRequest(latitude, longitude) {
       var url = "https://aqi-gateway.wl.r.appspot.com/aqi";      // set the url

       var params = {                                              // set the parameters
              "lat" => latitude,
              "lon" => longitude
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
