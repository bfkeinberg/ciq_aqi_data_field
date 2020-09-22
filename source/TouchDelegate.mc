using Toybox.System;
using Toybox.WatchUi;
using Toybox.Background;
using Toybox.Time;
using Toybox.Time.Gregorian;

class TouchDelegate extends WatchUi.BehaviorDelegate {

    const FIVE_MINUTES = new Time.Duration(5 * 60);
    var view;
    
	  function initialize(parentView) {
		  	BehaviorDelegate.initialize();
		  	view = parentView;
	  }
    
    function onTap(clickEvent) {
    	var gregorian;
    	
        if (clickEvent.getType() == CLICK_TYPE_TAP) {
        	// toggle ozone vs pm2.5 display
        	if (view.displayPm2_5 == true) {
        		view.displayPm2_5 = false;
    		} else {
    			view.displayPm2_5 = true;
			}
        	// and immediately update the air quality value
			var lastTime = Background.getLastTemporalEventTime();
			if (lastTime != null) {
				gregorian = Gregorian.info(lastTime, Time.FORMAT_MEDIUM);
				System.println("last time was " + gregorian.hour + ":" + gregorian.min.format("%02d"));
			    // Events scheduled for a time in the past trigger immediately
			    var nextTime = lastTime.add(FIVE_MINUTES);
			    Background.registerForTemporalEvent(nextTime);
			} else {
			    Background.registerForTemporalEvent(Time.now());
			}
		}
        return true;
    }
    
}