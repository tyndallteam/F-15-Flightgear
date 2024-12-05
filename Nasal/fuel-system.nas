# F-15 Fuel system 
# ---------------------------
# The main fuel computations are performed in JSBSim; these are support routines
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory

fuel.update = func{}; # disable the generic fuel updater

# Initialize internal values
# --------------------------
var fuel_system_initialized = 0; # Used to avoid spawning a bunch of new tanks each time we reset FG.
var PPG = nil;
var LBS_HOUR2GALS_SEC    = nil;
var LBS_HOUR2GALS_PERIOD = nil;

var TankRightSide = 1;
var TankLeftSide = 0;
var TankBothSide = -1;

var ai_enabled = nil;
var refuelingN = nil;
var refuel_serviceable = nil;
var aimodelsN = nil;
var types = {};
var qty_refuelled_gals = nil;

var Tank1       = nil;
var Left_Feed      = nil;
var WingInternal_L          = nil;
var Right_Feed     = nil;
var WingInternal_R         = nil;
var WingExternal_L          = nil;
var WingExternal_R         = nil;
var Centre_External      = nil;
var Conformal_L = nil;
var Conformal_R = nil;


var total_gals = 0;
var total_lbs  = 0;
var total_fuel_l = 0;
var total_fuel_r = 0;
var qty_sel_switch = nil;
var g_fuel_total   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/total", 1);
var g_fuel_WL      = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/left-wing-display", 1);
var g_fuel_WR      = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/right-wing-display", 1);
var g_fus_feed_L   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/left-fus-feed-display", 1);
var g_fus_feed_R   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/right-fus-feed-display", 1);
var Qty_Sel_Switch = props.globals.getNode("sim/model/f15/controls/fuel/qty-sel-switch",1);
var cft            = props.globals.getNode("sim/model/f15/cft", 1);
var fwd = nil;
var aft = nil;
var Lg  = nil;
var Rg  = nil;
var Lw  = nil;
var Rw  = nil;
var Le  = nil;
var Re  = nil;

var fuel_time = 0;
var fuel_dt = 0;
var fuel_last_time = 0.0;

var total = 0;
var refuel_rate_gpm = 450; # max refuel rate in gallons per minute at 50 psi pressure


var left_shut_off = 0; # TODO: Engine fuel shutoff emergency handles
var right_shut_off = 0;


var LeftEngine		= props.globals.getNode("engines").getChild("engine", 0);
var RightEngine	    = props.globals.getNode("engines").getChild("engine", 1);
var LeftFuel		= LeftEngine.getNode("fuel-consumed-lbs", 1);
var RightFuel		= RightEngine.getNode("fuel-consumed-lbs", 1);

LeftFuel.setDoubleValue(0);
RightFuel.setDoubleValue(0);

var JSBLeftEngine		= props.globals.getNode("/fdm/jsbsim/propulsion/").getChild("engine", 0);
var JSBRightEngine	    = props.globals.getNode("/fdm/jsbsim/propulsion/").getChild("engine", 1);
LeftFuel		= JSBLeftEngine.getNode("fuel-used-lbs", 1);
RightFuel		= JSBRightEngine.getNode("fuel-used-lbs", 1);

var LeftEngineRunning		= LeftEngine.getNode("running", 1);
var RightEngineRunning		= RightEngine.getNode("running", 1);
LeftEngine.getNode("out-of-fuel", 1);
RightEngine.getNode("out-of-fuel", 1);

var RprobeSw = props.globals.getNode("sim/model/f15/controls/fuel/refuel-probe-switch");
var TotalFuelLbs  = props.globals.getNode("consumables/fuel/total-fuel-lbs", 1);
var TotalFuelGals = props.globals.getNode("consumables/fuel/total-fuel-gals", 1);

# ensure feed lines are not selected as this breaks AAR.
setprop("/consumables/fuel/tank[10]/selected",0);
setprop("/consumables/fuel/tank[11]/selected",0);


configure_cft = func(v) {
    logprint(3, "CFT changed ",cft.getValue(), " ", v.getValue());
    if (Conformal_R == nil or Conformal_L == nil){
        logprint(5, "No tanks defined ***************************************************************************\n\n");
      return;
    }
    if (cft.getValue()){
        Conformal_R.set_capacity(728);
        Conformal_L.set_capacity(728);
        Conformal_R.set_selected(1);
        Conformal_L.set_selected(1);
		setprop("fdm/jsbsim/inertia/pointmass-weight-lbs[11]",1000);
		setprop("fdm/jsbsim/inertia/pointmass-weight-lbs[12]",1000);
    } else {
        Conformal_R.set_level(0);
        Conformal_L.set_level(0);
        Conformal_R.set_capacity(0);
        Conformal_L.set_capacity(0);
        Conformal_R.set_selected(0);
        Conformal_L.set_selected(0);
		setprop("fdm/jsbsim/inertia/pointmass-weight-lbs[11]",0);
        setprop("fdm/jsbsim/inertia/pointmass-weight-lbs[12]",0);
    }
    payload_dialog_reload("CFT change");
}
setlistener("sim/model/f15/cft", func(v)
{
    configure_cft(v);
});

do_tank_selected = func(is_sel, tank_num, capacity_usgal){
    node = props.getNode("consumables/fuel/tank["~tank_num~"]");
    if (is_sel) {
        node.getNode("capacity-gal_us",1).setDoubleValue(0);
        node.getNode("level-lbs",1).setDoubleValue(0);
        node.getNode("selected",1).setValue(0);
    } else {
        node.getNode("capacity-gal_us",1).setDoubleValue(capacity_usgal);
#        node.getNode("level-gal_us",1).setDoubleValue(capacity_usgal);
        node.getNode("selected",1).setValue(1);
    }
}

#left w=1 tank=5
setlistener("payload/weight[1]/selected", func(v)
{
do_tank_selected(v != nil and v.getValue() != "Droptank", 5, 598.48);
});

#centre w=5, t=7
setlistener("payload/weight[5]/selected", func(v)
{
do_tank_selected(v != nil and v.getValue() != "Droptank", 7, 598.48);
});

#right w=9 t=6
setlistener("payload/weight[9]/selected", func(v)
{
do_tank_selected(v != nil and v.getValue() != "Droptank", 6, 598.48);
});

var init_fuel_system = func {

	logprint(3, "Initializing F-15 fuel system");


	if ( ! fuel_system_initialized ) {
		build_new_tanks();
		fuel_system_initialized = 1;
        configure_cft(cft);
	}

	setlistener("sim/ai/enabled", func(n) { ai_enabled = n.getBoolValue() }, 1);
	refuelingN = props.globals.initNode("/systems/refuel/contact", 0, "BOOL");
	aimodelsN = props.globals.getNode("ai/models", 1);
	foreach (var t; props.globals.getNode("systems/refuel", 1).getChildren("type"))
		types[t.getValue()] = 1;
	setlistener("systems/refuel/serviceable", func(n) refuel_serviceable = n.getBoolValue(), 1);

	PPG = Tank1.ppg.getValue();
	LBS_HOUR2GALS_SEC = (1 / PPG) / 3600;

}

var build_new_tanks = func {
	#tanks ("name", number, initial connection status)
    # the order of these is significant for the set_fuel operation
	Tank1     = Tank.new("Tank 1", 2, 1, TankBothSide);
	WingInternal_L   = Tank.new("Internal Wing L", 3, 1, TankLeftSide);
	WingInternal_R   = Tank.new("Internal Wing R", 4, 1, TankRightSide);
	Left_Feed      = Tank.new("L Feed", 0, 1, TankLeftSide); 
	Right_Feed      = Tank.new("R Feed", 1, 1, TankRightSide);
	WingExternal_L   = Tank.newExternal("External Wing L", 5, 1, TankLeftSide);
	WingExternal_R   = Tank.newExternal("External Wing R", 6, 1, TankRightSide);
	Centre_External  = Tank.newExternal("Centre External", 7, 1, TankBothSide); 
    Conformal_L  = Tank.newExternal("Conformal Left", 8, 1, TankLeftSide); 
    Conformal_L.external = 0;
	Conformal_R  = Tank.newExternal("Conformal Right", 9, 1, TankRightSide); 
    Conformal_R.external = 0;
}


var fuel_update = func {
	fuel_time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
	fuel_dt = fuel_time - fuel_last_time;
	fuel_last_time = fuel_time;
	calc_levels();

	if ( getprop("/sim/freeze/fuel") or getprop("/sim/replay/time") > 0 ) { return }

	LBS_HOUR2GALS_PERIOD = LBS_HOUR2GALS_SEC * fuel_dt;
	refuel_rate_gpm = 450; # max rate in gallons per minute at 50 psi pressure
}





var calc_levels = func() {
	# Calculate total fuel in tanks (not including small amount in proportioners) for use
	# in the various gauges displays.
	total_gals = total_lbs = 0;
	foreach (var t; Tank.list) {
		total_gals = total_gals + t.get_level();
		total_lbs = total_lbs + t.get_level_lbs();
	}
	fwd = Tank1.get_level_lbs();
	Lg  = Left_Feed.get_level_lbs() + WingInternal_L.get_level_lbs();
	Rg  = Right_Feed.get_level_lbs() + WingInternal_R.get_level_lbs();
	Lw  = WingExternal_L.get_level_lbs();
	Rw  = WingExternal_R.get_level_lbs();
	Le  = Centre_External.get_level_lbs();
	g_fuel_total.setDoubleValue( total_lbs );
	TotalFuelLbs.setValue(total_lbs);

    total_fuel_l = Lg + Lw;
    total_fuel_r = Rg + Rw;

    var sel_display = getprop("sim/model/f15/controls/fuel/display-selector");

# FUEL QUANTITY SELECTOR KNOB
    if (sel_display == 1)
    {
#FEED The fuel remaining in the respective engine feed tanks will be displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Left_Feed.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",Right_Feed.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 2)
    {
#INT WING The fuel remaining in the respective internal wing tanks is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", WingInternal_L.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",WingInternal_R.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 3)
    {
#TANK 1 The fuel remaining in tank 1 is displayed in the LEFT counter (RIGHT indicates zero).
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Tank1.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 4)
    {
#EXT WING The fuel remaining in the respective external wing tanks is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", WingExternal_L.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",WingExternal_R.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 5)
    {
#EXT CTR The fuel remaining in the external centerline tank is displayed in the LEFT counter (RIGHT indicates zero).
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Centre_External.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 6)
    {
#CONF TANK The fuel remaining in the respective conformal tank is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display",Conformal_L.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",Conformal_R.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else
    {
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", 6000);
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",600); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",6000);
    }
}


# Controls
# --------

setlistener("sim/model/f15/controls/fuel/dump-switch", func(v) {
    if (v != nil)
    {
        if (v.getValue())
        {
            setprop("sim/multiplay/generic/int[0]", 1);
            setprop("fdm/jsbsim/propulsion/fuel_dump",1);
        }
        else
        { 
            setprop("sim/multiplay/generic/int[0]", 0);
            setprop("fdm/jsbsim/propulsion/fuel_dump",0);
        } 
    }
    else 
    { 
        setprop("sim/multiplay/generic/int[0]", 0);
        setprop("fdm/jsbsim/propulsion/fuel_dump",0);
    }
});


var r_probe = aircraft.door.new("sim/model/f15/refuel/", 1);
var RprobePos        = props.globals.getNode("sim/model/f15/refuel/position-norm", 1);


setlistener("sim/model/f15/controls/fuel/refuel-probe-switch", func {
    var v = getprop("sim/model/f15/controls/fuel/refuel-probe-switch");
    if (v != nil)
    {
        if (v == 0)
        {
            r_probe.close();
            setprop("fdm/jsbsim/propulsion/refuel",0);
            setprop("fdm/jsbsim/propulsion/ground-refuel",0);
        }
        else
        {
            r_probe.open();
            if (wow)
            {
                setprop("fdm/jsbsim/propulsion/refuel",1);
                setprop("fdm/jsbsim/propulsion/ground-refuel",1);
            }
        }
    }
});

var refuel_probe_switch_up = func() {
	var sw = RprobeSw.getValue();
	if ( sw < 2 ) {
		sw += 1;
		RprobeSw.setValue(sw);
	}
	r_probe.open();
}
var refuel_probe_switch_down = func() {
	var sw = RprobeSw.getValue();
	if ( sw > 0 ) {
		sw -= 1;
		RprobeSw.setValue(sw);
	}
	if ( sw == 0 ) { r_probe.close(); }
}
var refuel_probe_switch_cycle = func() {
	var sw = RprobeSw.getValue();
	if ( sw < 2 ) { refuel_probe_switch_up() }
	if ( sw == 2 ) {
		sw = 0;
		RprobeSw.setValue(sw);
		r_probe.close();	
	}
}


# Internaly save levels at reinit. This is a workaround:
# reinit shouldn't try to reload the levels from the -set file.
var level_list = [];

var internal_save_fuel = func() {
	logprint(2, "Saving F-15 fuel levels");
	level_list = [];
	foreach (var t; Tank.list) {
	    logprint(2, " -- ",t.name," = ",t.level_lbs.getValue());
		append(level_list, t.get_level());
	}
}
var internal_restore_fuel = func() {
	logprint(2, "Restoring F-15 fuel levels");
	var i = 0;
	foreach (var t; Tank.list) {
        logprint(2, " -- ",t.name," = ",t.level_lbs.getValue());
        if (i < size(level_list))
          t.set_level(level_list[i]);
	    else
          logprint(3, "ERROR: Fuel restore level not saved -- ",t.name," = ",t.level_lbs.getValue());
		i += 1;
	}
}


# Classes
# -------

# Tank
Tank = {
	new : func (name, number, connect, side) {
		var obj = { parents : [Tank]};
        obj.external = 0;
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
#		obj.prop = props.globals.getNode("fdm/jsbsim/propulsion/tank").getChild ("tank", number , 1);
#		obj.name = obj.prop.getNode("name", 1);
        obj.side = side; # 1 is right; 0 is left.
		obj.name = name;
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_gal_us.setValue(0);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.level_lbs.setValue(0);
		obj.transfering = obj.prop.getNode("transfering", 1);
		obj.transfering.setBoolValue(0);
		obj.selected = obj.prop.getNode("selected", 1);
		obj.selected.setBoolValue(connect);
		obj.ppg.setDoubleValue(6.3);
		append(Tank.list, obj);
		logprint(2, "Tank.new[",number,"], ",obj.name," lbs=", obj.level_lbs.getValue());
		return obj;
	},
	newExternal : func (name, number, connect, side) {
		var obj = { parents : [Tank]};
        obj.external = 1;
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
#		obj.prop = props.globals.getNode("fdm/jsbsim/propulsion/tank").getChild ("tank", number , 1);
#		obj.name = obj.prop.getNode("name", 1);
        obj.side = side; # 1 is right; 0 is left.
		obj.name = name;
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_gal_us.setValue(0);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.level_lbs.setValue(0);
		obj.transfering = obj.prop.getNode("transfering", 1);
		obj.transfering.setBoolValue(0);
		obj.selected = obj.prop.getNode("selected", 1);
		obj.selected.setBoolValue(connect);
		obj.ppg.setDoubleValue(6.3);

		append(Tank.list, obj);
		logprint(2, "Tank.new[",number,"], ",obj.name," lbs=", obj.level_lbs.getValue());
		return obj;
	},
    #
    # the side of this tank (or the engine that this tank feeds) (0 = left, 1 = right) 
    get_side : func {
        return me.side;
    },
    is_external : func {
        return me.external;
    },
    is_side : func(s) {
        return me.side == s;
    },
    is_fitted : func {
        if (!me.external) return 1;
        if (me.prop.getNode("selected").getValue())
            return 1;
        return 0;
    },

	get_capacity : func {
		return me.capacity.getValue(); 
	},
	set_capacity : func(v) {
		return me.capacity.setValue(v); 
	},
	get_capacity_lbs : func {
		return me.capacity.getValue() * me.ppg.getValue(); 
	},
	get_level : func {
		return me.level_gal_us.getValue();
	},
	get_level_lbs : func {
		return me.level_lbs.getValue();
	},
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
	set_level_lbs : func (lbs){
		if(lbs < 0) lbs = 0;
		me.level_gal_us.setDoubleValue(lbs / me.ppg.getValue());
		me.level_lbs.setDoubleValue(lbs);
	},
	set_transfering : func (transfering){
		me.transfering.setBoolValue(transfering);
	},
	set_selected : func (sel){
		me.selected.setBoolValue(sel);
	},
	get_amount : func (fuel_dt, ullage) {
		var amount = (flowrate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * fuel_dt;
		if(amount > me.level_gal_us.getValue()) {
			amount = me.level_gal_us.getValue();
		} 
		if(amount > ullage) {
			amount = ullage;
		} 
		var flowrate_lbs = ((amount/fuel_dt) * 60 * 60) * me.ppg.getValue();
		return amount
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level()
	},
	get_ullage_lbs : func () {
		return (me.get_capacity() - me.get_level()) * me.ppg.getValue();
	},
	get_name : func () {
		return me.name;
	},
	set_transfer_tank : func (fuel_dt, tank) {
		foreach (var t; Tank.list) {
			if(t.get_name() == tank)  {
				transfer = me.get_amount(fuel_dt, t.get_ullage());
				me.set_level(me.get_level() - transfer);
				t.set_level(t.get_level() + transfer);
			} 
		}
	},

    adjust_level_by_delta : func(side, delta)
    {
        var t = me;
        logprint(2, "Processing ",t.name," is fitted ",t.is_fitted()," delta ",delta);
        if (t.is_fitted()) # true for internal; only true when external connected
        {
            if (t.is_side(side))
            {
                if (delta < 0)
                {
                    var tdelta = t.get_level_lbs() + delta;
                    if (tdelta < 0)
                    {
                        delta = delta + t.get_level_lbs();
                        logprint(2, "Tank ",t.name," empty : new_delta ", delta);
                        t.set_level_lbs(0);
                    }
                    else
                    {
                        if (tdelta > t.get_capacity_lbs()) tdelta = t.get_capacity_lbs();
                        t.set_level_lbs(tdelta);
                        logprint(2, "Tank(finished) ",t.name," set to  ", tdelta, " now ", t.get_level_lbs());
                        delta = delta - tdelta;
                    }
                }
                else
                {
                    var tdelta = t.get_ullage_lbs();
                    if (tdelta > delta) tdelta = delta;
#            if (tdelta > t.get_capacity_lbs()) tdelta = t.get_capacity_lbs();

                    delta = delta - tdelta;
                    t.set_level_lbs(t.get_level_lbs() + tdelta);
                    logprint(2, "Tank ",t.name," increase by ", tdelta, " now ", t.get_level_lbs());
                }
            }
            else
                logprint(23, "-- not adjusting ",t.name," not matched on side ",side);
        }
        return delta;
    },
	list : [],
};




var toggle_fuel_freeze = func() {
    setprop("sim/freeze/fuel", 1-getprop("sim/freeze/fuel"));
}

var set_fuel = func(total) {
    var total_delta = (total - getprop("consumables/fuel/total-fuel-lbs"));

    var start = 0; 
    var end = size(Tank.list)-1;
    var inc = 1;
    if (total_delta < 0)
    {
        start = size(Tank.list)-1;
        end = -1;
        inc = -1;
    }

    logprint(2, "\n set_fuel to ",total," delta ",total_delta);
    if (total_delta > 0)
    {
        total_delta = Tank1.adjust_level_by_delta(TankBothSide, total_delta);
        total_delta = Centre_External.adjust_level_by_delta(TankBothSide, total_delta);
    }

    for (var side=0; side < 2; side = side+1)
    {
        var delta = total_delta / 2;
#        print ("\nDoing side ",side, " adjust by ",delta);
#	foreach (var t; Tank.list)
        for (var tank_idx=start; tank_idx != end+1; tank_idx = tank_idx + inc)
        {
            var t = Tank.list[tank_idx];
            #
# only consider non external tanks; or external tanks when connected.
delta = t.adjust_level_by_delta(side, delta);
        }
    }
    total_delta = (total - getprop("consumables/fuel/total-fuel-lbs"));
    if (total_delta < 0)
    {
        total_delta = Tank1.adjust_level_by_delta(TankBothSide, total_delta);
        total_delta = Centre_External.adjust_level_by_delta(TankBothSide, total_delta);
    }
}
