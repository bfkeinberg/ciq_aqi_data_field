using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Attention;

class AQI_DataFieldView extends WatchUi.DataField {

    hidden var aqiValue;
    const particulateValue = "PM2.5";
    const ozoneValue = "O3";
	var enableNotifications = false;
	var notified = false;

    function initialize(notifications) {
        DataField.initialize();
        aqiValue = null;
        enableNotifications = notifications;
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

        View.findDrawableById("label").setText(Rez.Strings.label);
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
        var label = View.findDrawableById("label");
    
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        var currentAqi = null;
        if (aqiValue != null && aqiValue.hasKey(particulateValue)) {
        	currentAqi = aqiValue.get(particulateValue);
        	value.setText(currentAqi.toString());
    	} else {
    		value.setText("N/A");
		}
		if (currentAqi != null && getBackgroundColor() == Graphics.COLOR_WHITE) {
			if (aqiValue != null && aqiValue.hasKey("error")) {
				value.setColor(Graphics.COLOR_LT_GRAY);
				notified = false;
			}
			else if (currentAqi < 51) {
				value.setColor(Graphics.COLOR_GREEN);
				notified = false;
			}
			else if (currentAqi < 101) {
				value.setColor(Graphics.COLOR_YELLOW);
				notified = false;
			}
			else {
				value.setColor(Graphics.COLOR_DK_RED);
				// potentially alert here
				if (Attention has :playTone && enableNotifications && !notified) {
					Attention.playTone(Attention.TONE_CANARY);
					notified = true;
				} 
			}
            label.setColor(Graphics.COLOR_BLACK);
		}
        else if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);        	
			if (aqiValue != null && aqiValue.hasKey("error")) {
				value.setColor(Graphics.COLOR_LT_GRAY);
				notified = false;
			}
			else if (currentAqi < 51) {
				value.setColor(Graphics.COLOR_GREEN);
				notified = false;
			}
			else if (currentAqi < 101) {
				value.setColor(Graphics.COLOR_YELLOW);
				notified = false;
			}
			else {
				value.setColor(Graphics.COLOR_RED);
				// potentially alert here
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

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }    

}
