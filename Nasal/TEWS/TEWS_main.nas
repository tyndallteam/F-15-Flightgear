# F-15 TEWS; Canvas
# ---------------------------
# This bears only a cosmetic relation to the real device mainly because 
# all of the document for TEWS appears to be classified and/or 
# generally unavailable. 
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com
# ---------------------------

var TEWSSymbol = {
	new : func (id, svg, base){
		var obj = {parents : [TEWSSymbol] };
        var svg_idx = id+1;
        var name = base~"_"~svg_idx;
        var label_name = base~"_label_"~svg_idx;
        obj.name = base~"_"~svg_idx;
        obj.valid = 0;
        obj.labelSize = 0;
        var sym = svg.getElementById(name);

        if (sym != nil)
        {
            obj.symbol = sym;
            var sym = svg.getElementById(label_name);
            if (sym != nil)
            {
                obj.label = sym;
                obj.label.setFont(aircraft.TEWSFont).setFontSize(10, 1.0);
                obj.valid = 1;
                obj.setVisible(0);
            }
            else
                logprint(3, "Cannot find "~label_name);
        }
        else
            logprint(3, "Cannot find "~name);
        obj.id = id;
		return obj;
	},
    setVisible : func(vis){
        if(me.symbol != nil)
            me.symbol.setVisible(vis);
        if(me.label != nil)
            me.label.setVisible(vis);
    },
    setTranslation : func(xc,yc){
        if(me.symbol != nil)
            me.symbol.setTranslation(xc,yc);
        if(me.label != nil)
            me.label.setTranslation(xc,yc);
    },
    setRotation : func(r){
        if(me.symbol != nil)
            me.symbol.setRotation(r);
        if(me.label != nil)
            me.label.setRotation(r);
    },
    setCenter : func(xc,yc){
        if(me.symbol != nil)
            me.symbol.setCenter(xc,yc);
        if(me.label != nil)
            me.label.setCenter(xc,yc);
    },
    setCallsign : func(t){
        if (size (t) > 3)
            me.setText(substr(t,0,2)~substr(t,size(t)-2,2));
        else
            me.setText(t);
    },
    setGeoPosition : func (lat, lon){
        if(me.symbol != nil)
            me.symbol.setGeoPosition(lat, lon);
        if(me.label != nil)
            me.label.setGeoPosition(lat, lon);
    },
    setText : func(t){
        if(me.label != nil){
            me.label.setText(t);
            me.labelSize = size(t);
        }
    },
};


var TEWSDisplay = {
	new : func (svgname, canvas_item, sx, sy, tran_x,tran_y){
		var obj = {parents : [TEWSDisplay] };

        obj.canvas= canvas.new({
                                "name": "F-15 TEWS",
                                "size": [1024,1024], 
                                "view": [sx,sy],
                                "mipmapping": 0
                               });                          
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.0039215686274509803921568627451,0.17647058823529411764705882352941,0, 0.00);

        # Create a group for the parsed elements
        obj.TEWSsvg = obj.canvas.createGroup();
 
        # Parse an SVG file and add the parsed elements to the given group
        canvas.parsesvg(obj.TEWSsvg, svgname,  {'font-mapper': aircraft.tews_font_mapper});
        #obj.TEWSsvg.setTranslation (-20.0, 37.0);
        #logprint(3, "TEWS INIT");
        obj.tews_on = 1;
        setlistener("sim/model/f15/controls/TEWS/brightness", func(v)
            {
                if (v != nil)
                {
                    obj.tews_on = v.getValue();
                    #logprint(3, "TEWS On ",tews_on);
                }
            });

        obj.max_symbols = 10;
        obj.tews_alignment_offset = -90;
        obj.symbol_list = [];
        obj.locked_symbol = TEWSSymbol.new(0, obj.TEWSsvg, "hat_locked");
        obj.process_targets = frame_utils.PartitionProcessor.new("TEWS-display", 20, nil);

        for (var i = 0; i < obj.max_symbols; i += 1)
          {
              var ts = append(obj.symbol_list, TEWSSymbol.new(i, obj.TEWSsvg, "hat"));
              #    printf("TEWS Sym load: %d: %s %s",i,ts.id, ts.valid);
          }
        return obj;
    },
    update : func (notification){  
        if(!me.tews_on)
            return;

        var scale = 220/2; # horizontal / vertical scale (half resolution)

        me.process_targets.process(me, awg_9.tgts_list, 
                                func(pp, obj, data){
                                    obj.target_idx=1;
                                    obj.is_active = 0;
                                },
                                func(pp, obj, u){
                                    var callsign = "XX";
                                    if (u.get_range() < notification.radar2_range and u.get_RWR_visible())
                                    {
                                        if (u.Callsign != nil)
                                            callsign = u.Callsign.getValue();

                                        var model = "XX";

                                        if (u.Model != nil)
                                            model = u.Model.getValue();

                                        if (obj.target_idx < me.max_symbols)
                                        {
                                            var tgt = nil;

                                            if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue()){
                                                tgt = me.locked_symbol;
                                                obj.is_active = 1;
                                            }
                                            else{
                                                tgt = me.symbol_list[obj.target_idx];
                                                obj.target_idx = obj.target_idx+1;
                                            }

                                            if (tgt != nil)
                                            {

                                    # We have a valid target - so display it. Not quite sure why we need to adjust this but we do.
                                    #                    var bearing = u.get_deviation(notification.OrientationHeadingDeg);
                                                    var bearing = geo.normdeg(u.get_deviation(notification.OrientationHeadingDeg) + me.tews_alignment_offset);

                                                    tgt.setVisible(1);#u.get_display());#Leto: is is only display true when in radar field, so we ignore that.
                                                    tgt.setCallsign(callsign);
                                                    var r = (u.get_range()*scale) / notification.radar2_range;
                                                    var xc  = r * math.cos(bearing/57.29577950560105);
                                                    var yc = r * math.sin(bearing/57.29577950560105);

                                                    tgt.setVisible(1);

                                    #                    printf("TEWS: %d(%d,%d): %s %s: :R %f B %f %f", obj.target_idx,xc,yc,
                                    #                           callsign, model, 
                                    #                           u.get_altitude(), u.get_range(), u.get_bearing());

                                                    tgt.setTranslation (xc, yc);
                                                    tgt.setRotation(geo.normdeg(u.get_heading()-notification.OrientationHeadingDeg)/57.29577950560105);
                                                }
                                        }
                                    }
                                    if (obj.target_idx >= me.max_symbols){ 
                                        return 0;
                                    }
                                    return 1;
                                },
                                func(pp, obj, data){
                                    if (!obj.is_active)
                                        me.locked_symbol.setVisible(0);

                                    for(var nv = obj.target_idx; nv < me.max_symbols;nv += 1)
                                    {
                                        var tgt = me.symbol_list[nv];
                                        if (tgt != nil)
                                        {
                                            tgt.setVisible(0);
                                        }
                                    }
                                });
    },
};
input = {
            OrientationHeadingDeg  : "orientation/heading-deg",
            radar2_range           : "instrumentation/radar/radar2-range",
            };

emexec.ExecModule.register("F15-TEWS",input, TEWSDisplay.new("Nasal/TEWS/TEWS.svg","TEWSImage", 326,256, 0,0), 4);

