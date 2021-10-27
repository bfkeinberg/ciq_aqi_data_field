using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Attention;
using Toybox.System;
using Toybox.FitContributor;
using Toybox.Application;
using Toybox.Time;

class AQI_DataFieldView extends WatchUi.DataField {

    hidden var aqiValue;
    const particulateValue = "PM2.5";
    const ozoneValue = "O3";
	var enableNotifications = false;
	var notified = false;
	var displayPm2_5 = true;
	const AQI_FIELD_ID = 0;
	var displayVersion = true;
	const secondsToDisplayVersion = 14;
	var initialTime;
	
    function initialize(notifications) {
        DataField.initialize();
        aqiValue = null;
        enableNotifications = notifications;
        try {
		  	aqiField = createField("AQI", AQI_FIELD_ID, FitContributor.DATA_TYPE_UINT32,
		  		{:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"PM2.5"});
  		} catch (ex) {
  			System.println("could not create aqiField " + ex);
  		}
  		initialTime = Time.now();
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        View.findDrawableById("label").setText(displayPm2_5 ? Rez.Strings.label : Rez.Strings.ozoneLabel);
        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	aqiValue = aqiData;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
    	dc.clear();
        var label = View.findDrawableById("label");
    
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        var currentAqi = null;
        // if the user has toggled to display ozone but we don't have a value for it in the results
        // switch back to displaying PM 2.5
        if (aqiValue != null) {
        	if (!displayPm2_5) {
		        if (!aqiValue.hasKey(ozoneValue) || aqiValue.get(ozoneValue) == null) {
		        	displayPm2_5 = true;
		    	}
	    	}
    	}
        label.setText(displayPm2_5 ? Rez.Strings.label : Rez.Strings.ozoneLabel);
		var selectedValue = displayPm2_5 ? particulateValue : ozoneValue;
        if (aqiValue != null && aqiValue.hasKey(selectedValue) && aqiValue.get(selectedValue) != null) {
        	currentAqi = aqiValue.get(selectedValue);
        	value.setText(currentAqi.toString());
    	} else {
			if (aqiValue != null && aqiValue.get("error") != null) {
				View.findDrawableById("Background").setColor(Graphics.COLOR_RED);
				value.setColor(Graphics.COLOR_WHITE);
				value.setText(aqiValue.get("error").toString());
			} else {
	    		value.setText("N/A");
			}
		}
		if (currentAqi != null && getBackgroundColor() == Graphics.COLOR_WHITE) {
			if (aqiValue != null && aqiValue.hasKey("error")) {
				View.findDrawableById("Background").setColor(Graphics.COLOR_RED);
				value.setColor(Graphics.COLOR_WHITE);
				value.setText(aqiValue.get("error").toString());
				notified = false;
			}
			else if (currentAqi < 51) {
				value.setColor(Graphics.COLOR_DK_GREEN);
				notified = false;
			}
			else if (currentAqi < 101) {
				value.setColor(Graphics.COLOR_YELLOW);
				notified = false;
			}
			else if (currentAqi < 151) {
				value.setColor(Graphics.COLOR_ORANGE);
				notified = false;
			}
			else if (currentAqi < 201) {
				value.setColor(Graphics.COLOR_DK_RED);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				} 
			}
			else {
				value.setColor(Graphics.COLOR_PURPLE);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				} 
			}
            label.setColor(Graphics.COLOR_BLACK);
		}
        else if (currentAqi != null && getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);        	
			if (aqiValue != null && aqiValue.hasKey("error")) {
//				value.setColor(Graphics.COLOR_LT_GRAY);
				View.findDrawableById("Background").setColor(Graphics.COLOR_RED);
				value.setColor(Graphics.COLOR_WHITE);
				value.setText(aqiValue.get("error").toString());
				notified = false;
			}
			else if (currentAqi < 51) {
				value.setColor(0x00FD00/*Graphics.COLOR_GREEN*/);
				notified = false;
			}
			else if (currentAqi < 101) {
				value.setColor(0xFFFF00);
				notified = false;
			}
			else if (currentAqi < 151) {
				value.setColor(Graphics.COLOR_ORANGE);
				notified = false;
			}
			else if (currentAqi < 201) {
				value.setColor(Graphics.COLOR_RED);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				} 
			}
			else {
				value.setColor(Graphics.COLOR_PURPLE);
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				} 
			}
            label.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
            label.setColor(Graphics.COLOR_BLACK);
        }
		if (aqiValue != null && aqiValue.hasKey("provider")) {
			var indicator = View.findDrawableById("indicator");
			switch(aqiValue.get("provider")) {
			case 1:
				indicator.setText("AirNow");
				indicator.setColor(Graphics.COLOR_DK_GRAY);
				break;
			case 2:			
				indicator.setText("Purple");
				indicator.setColor(Graphics.COLOR_PURPLE);
				break;
			case 3:
				indicator.setColor(Graphics.COLOR_DK_GRAY);
				indicator.setText("IQAir");
				break;
			}
		}
        if (me.displayVersion) {
        	var now = Time.now();
        	View.findDrawableById("version").setText(Rez.Strings.Version);
        	me.displayVersion = now.subtract(initialTime).value() < secondsToDisplayVersion;
    	} else {
    		var version = View.findDrawableById("version");
        	version.setBackgroundColor(Graphics.COLOR_TRANSPARENT);
        	version.setText("");
		}    	
		
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }    

}
