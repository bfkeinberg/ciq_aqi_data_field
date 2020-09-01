using Toybox.System;
using Toybox.WatchUi;
using Toybox.Background;
using Toybox.Time;
using Toybox.Time.Gregorian;

class TouchDelegate extends WatchUi.BehaviorDelegate {

    const FIVE_MINUTES = new Time.Duration(5 * 60);
    
	  function initialize() {
	  	BehaviorDelegate.initialize();
	  }
    
    function onTap(clickEvent) {
        if (clickEvent.getType() == CLICK_TYPE_TAP) {
        	// immediately update the air quality value
        	var gregorian;
			var lastTime = Background.getLastTemporalEventTime();
			if (lastTime != null) {
				gregorian = Gregorian.info(lastTime, Time.FORMAT_MEDIUM);
				System.println("last time was " +  Lang.format(
				    "$4$, $6$ $5$ $7$ $1$:$2$:$3$",
				    [
				        gregorian.hour,
				        gregorian.min,
				        gregorian.sec,
				        gregorian.day_of_week,
				        gregorian.day,
				        gregorian.month,
				        gregorian.year
				    ]
				));
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