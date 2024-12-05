# F-15 Canvas MPCD (Multi-Purpose-Colour-Display)
# ---------------------------
# MPCD has many pages; the classes here support multiple pages, menu
# operation and the update loop.
# 2016-05-17: Refactor to use Nasal/canvas/MFD_Generic.nas 
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com
# ---------------------------

#for debug: setprop ("/sim/startup/terminal-ansi-colors",0);

# SIT scaling for legibility is based on the work Fox-Three who
# provided a prototype with values of 3.5 for the lines and 1.5 for the fonts.
# I've adjusted the code so that we setup the scaling at the start
# and also specify the font to match the other displays 

                           # original value 
var HSDblepFontSize  = 24; # 15;
var HSDlargeFontSize = 36; # 25;
var HSDfontSize      = 24; # 16;
var HSDlineWidth     =  6; # 1.5;
var HSDfontFace      = "notosansmono-black.ttf";        

#
# Menu Id's:
# The event that comes back from the animations will be 0 for off and 1..20 for the 
# button ID. The PFD menu item code will adjust the event.
#
#    10  11  12  13 14 
#
#  0                     5            
#
#  1                     6            
#
#  2                     7            
#
#  3                     8            
#
#  4                     9            
#
#    15  16  17  18 19
#
#------------------------
#
# TO-1F-15C has different numbering scheme the numbers are assigned anti-clockwise
# starting from LEFT (top->bottom), BOTTOM (left->right), RIGHT(bottom->top), TOP (right->left)
# PB  1..5   LEFT
# PB  6..10  BOTTOM
# PB 11..15  RIGHT (bot->top) 
# PB 16..20 is TOP (right->left)
# 
#    20  19  18  17  16 
#  1                     15
# 
#  2                     14
# 
#  3                     13
# 
#  4                     12
# 
#  5                     11
#     6   7   8   9  10
#     
var PB1 = 0;
var PB2 = 1;
var PB3 = 2;
var PB4 = 3;
var PB5 = 4;

var PB6  = 15;
var PB7  = 16;
var PB8  = 17;
var PB9  = 18;
var PB10 = 19;

var PB15 = 5;
var PB14 = 6;
var PB13 = 7;
var PB12 = 8;
var PB11 = 9;

var PB20 = 10;
var PB19 = 11;
var PB18 = 12;
var PB17 = 13;
var PB16 = 14;

var MPCD_Station =
{
    new : func (svg, ident)
    {
		var obj = {parents : [MPCD_Station] };

        obj.status = svg.getElementById("PACS_L_"~ident);
        if (obj.status == nil)
            logprint(3, "Failed to load PACS_L_"~ident);

        obj.label = svg.getElementById("PACS_V_"~ident);
        if (obj.label == nil)
            logprint(3, "Failed to load PACS_V_"~ident);

        obj.selected = svg.getElementById("PACS_R_"~ident);
        if (obj.selected == nil)
            logprint(3, "Failed to load PACS_R_"~ident);

        obj.selected1 = svg.getElementById("PACS_R1_"~ident);
        if (obj.selected1 == nil)
            logprint(3, "Failed to load PACS_R1_"~ident);

        obj.prop = "payload/weight["~ident~"]";
        obj.ident = ident;

        setlistener(obj.prop~"/selected", func(v)
                    {
                        obj.update();
                    });
        setlistener("sim/model/f15/controls/armament/weapons-updated", func
                    {
                        obj.update();
                    });

        obj.update();
        return obj;
    },

    update: func
    {
        var weapon_mode = getprop("sim/model/f15/controls/armament/weapon-selector");
        var na = pylons.pylons[me.ident+1].getWeapons(); #getprop(me.prop~"/selected");
        var sel = 0;
        var mode = "STBY";
        var sel_node = "sim/model/f15/systems/external-loads/station["~me.ident~"]/selected";
        var master_arm=getprop("sim/model/f15/controls/armament/master-arm-switch");

        if (na != nil and size(na) and na[0] != nil)
        {
            if (na[0].type == "AIM-9")
            {
                na = "9L";
                if (weapon_mode == 1)
                {
                    #sel = getprop(sel_node);
                    sel = me.ident+1 == pylons.fcs.getSelectedPylonNumber();
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "SRM";
            }
            elsif (na[0].type == "AIM-120") 
            {
                na = "120B";
                if (weapon_mode == 2)
                {
                    #sel = getprop(sel_node);
                    sel = me.ident+1 == pylons.fcs.getSelectedPylonNumber();
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            elsif (na[0].type == "MK-84" or na[0].type == "GBU-10") {
                na = "";
                mode = "";
            }
            elsif (na[0].type == "AIM-7") 
            {
                na = "7F";
                if (weapon_mode == 2)
                {
                    #sel = getprop(sel_node);
                    sel = me.ident+1 == pylons.fcs.getSelectedPylonNumber();
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            else
            {
                mode = "";
                na = "";
            }
            me.status.setText(mode);
            me.label.setText(na);

            me.selected1.setVisible(sel);
            if (mode == "RDY")
            {
                me.selected.setVisible(sel);
                me.status.setColor(0,1,0);
            }
            else
            {
                me.selected.setVisible(0);
                me.status.setColor(1,1,1);
            }
        }
        else
        {
            me.status.setText("");
            me.label.setText("");
            me.selected.setVisible(0);
            me.selected1.setVisible(0);
        }
    },
};

var MPCD_GroundStation =
{
	new : func (svg, ident)
    {
		var obj = {parents : [MPCD_GroundStation] };

        obj.status = svg.getElementById("PACS_L_"~ident~"-g");
        if (obj.status == nil)
            logprint(3, "Failed to load PACS_L_"~ident~"-g");

        obj.label = svg.getElementById("PACS_V_"~ident~"-g");
        if (obj.label == nil)
            logprint(3, "Failed to load PACS_V_"~ident~"-g");

        obj.selected = svg.getElementById("PACS_R_"~ident~"-g");
        if (obj.selected == nil)
            logprint(3, "Failed to load PACS_R_"~ident~"-g");

        obj.selected1 = svg.getElementById("PACS_R1_"~ident~"-g");
        if (obj.selected1 == nil)
            logprint(3, "Failed to load PACS_R1_"~ident~"-g");

        obj.prop = "payload/weight["~ident~"]";
        obj.ident = ident;

        setlistener(obj.prop~"/selected", func(v)
                    {
                        obj.update();
                    });
        setlistener("sim/model/f15/controls/armament/weapons-updated", func
                    {
                        obj.update();
                    });

        obj.update();
        return obj;
    },

    update: func
    {
        var weapon_mode = getprop("sim/model/f15/controls/armament/weapon-selector");
        var na = getprop(me.prop~"/selected");
        var sel = 0;
        var mode = "STBY";
        var sel_node = "sim/model/f15/systems/external-loads/station["~me.ident~"]/selected";
        var master_arm=getprop("sim/model/f15/controls/armament/master-arm-switch");

        if (na != nil and na != "none")
        {
            if (na == "MK-84")
            {
                na = "84";
                if (weapon_mode == 5)
                {
                    #sel = getprop(sel_node);
                    sel = me.ident+1 == pylons.fcs.getSelectedPylonNumber();
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "AG";
            }
             elsif (na == "GBU-10")
            {
                na = "10";
                if (weapon_mode == 5)
                {
                    #sel = getprop(sel_node);
                    sel = me.ident+1 == pylons.fcs.getSelectedPylonNumber();
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "AG";
            } else {
                mode = "";
                na = "";
            }
            me.status.setText(mode);
            me.label.setText(na);

            me.selected1.setVisible(sel);
            if (mode == "RDY")
            {
                me.selected.setVisible(sel);
                me.status.setColor(0,1,0);
            }
            else
            {
                me.selected.setVisible(0);
                me.status.setColor(1,1,1);
            }
        }
        else
        {
            me.status.setText("");
            me.label.setText("");
            me.selected.setVisible(0);
            me.selected1.setVisible(0);
        }
    },
};

var MPCD_Device =
{
#
# create new MFD device. This is the main interface (from our code) to the MFD device
# Each MFD device will contain the underlying PFD device object, the SVG, and the canvas
# Parameters
# - designation - Flightdeck Legend for this
# - model_element - name of the 3d model element that is to be used for drawing
# - model_index - index of the device
    new : func(designation, model_element, model_index=0)
    {
        var obj = {parents : [MPCD_Device] };
        obj.designation = designation;
        obj.model_element = model_element;
        var dev_canvas= canvas.new({
                "name": designation,
                           "size": [1024,1024], 
                           "view": [1024,1024],                       
                    "mipmapping": 1
                    });                          

        dev_canvas.addPlacement({"node": model_element});
        dev_canvas.setColorBackground(0.003921,0.1764,0, 0);
# Create a group for the parsed elements
        obj.PFDsvg = dev_canvas.createGroup();
        var pres = canvas.parsesvg(obj.PFDsvg, "Nasal/MPCD/MPCD_0_0.svg", {'font-mapper': aircraft.mpcd_font_mapper});
# Parse an SVG file and add the parsed elements to the given group
        obj.PFDsvg.setTranslation (0.0, 0.0);
#
# create the object that will control all of this
        obj.num_menu_buttons = 20;
        obj.PFD = PFD_Device.new(obj.PFDsvg, obj.num_menu_buttons, "MI_", dev_canvas);
        obj.PFD._canvas = dev_canvas;
        obj.PFD.designation = designation;
        obj.mfd_device_status = 1;
        obj.model_index = model_index; # numeric index (1 to 9, left to right) used to connect the buttons in the cockpit to the display

#
# Mode switch is day/night/off. we just do on/off
        setlistener("sim/model/f15/controls/MPCD/mode", 
                    func(v)
                    {
                        if (v != nil)
                          {
                              obj.mpcd_mode = v.getValue();
                              #    if (!mpcd_mode)
                              #        MPCDcanvas.setVisible(0);
                              #    else
                              #        MPCDcanvas.setVisible(1);
                          }
                    });

        setlistener("instrumentation/radar/radar2-range", 
                    func(v)
                    {
                        setprop("instrumentation/mpcd-sit/inputs/range-nm", v.getValue());
                    });


        obj.addPages();
        return obj;
    },
    
    setupHSD: func (svg) {
        var uv_x = 0;#0.408274;#UV map starts at these coords and goes to 1,1
        var uv_y = 0;#1-0.712342;
        var canvas_x = 1024;#740;
        var canvas_y = 1024;#680;
        
        svg.origin_y = canvas_y*uv_y;
        svg.origin_x = canvas_x*uv_x;
        
        svg.centrum_y= canvas_y*(uv_y+(1-uv_y)*0.5);
        svg.centrum_x= (uv_x+(1-uv_x)*0.5)*canvas_x;
        
        svg.width  = canvas_x*(1-uv_x);
        svg.height = canvas_y*(1-uv_y);
        
        svg.holeTop_y          = svg.origin_y+svg.height*0.15;
        svg.holeBottom_y       = svg.origin_y+svg.height*0.85;
        svg.holeHeight         = svg.holeBottom_y-svg.holeTop_y;
        svg.holeRadius         = svg.holeHeight*0.5;
        svg.myPos_y            = svg.holeTop_y+svg.holeHeight*0.75;
        svg.myPos_x            = svg.centrum_x;
        #svg.holeTopFromMyPos_y = svg.myPos_y-svg.holeTop_y;
        
        svg.p_HSD = me.PFD._canvas.createGroup();
        #logprint(3, "h "~svg.holeHeight);#339
        svg.hole = svg.p_HSD.createChild("path")
            .moveTo(svg.holeRadius,0)
            .arcSmallCW(svg.holeRadius,svg.holeRadius, 0, -svg.holeRadius*2, 0)
            .arcSmallCW(svg.holeRadius,svg.holeRadius, 0,  svg.holeRadius*2, 0)
            .setColor(0,1,0)# segmented green
            .setTranslation(svg.centrum_x,svg.centrum_y)
            .set("z-index",10001)
            .setStrokeLineWidth(HSDlineWidth)
            .setStrokeDashArray([10, 10]);
        svg.holeMask = svg.p_HSD.createChild("image")
                .setTranslation(uv_x*canvas_x,uv_y*canvas_y)
                .set("z-index",10000)
                .set("blend-source","zero")
                .set("blend-destination-rgb","one")
                .set("blend-destination-alpha","one-minus-src-alpha")
                .set("src", "Aircraft/F-15/Nasal/MPCD/sit-mask.png");
        #printf("leftc %d,%d  size %d,%d",svg.width*0.5-svg.holeRadius,svg.height/svg.width*(svg.height*0.5-svg.holeRadius),svg.holeRadius*2,svg.height/svg.width*(svg.holeRadius*2));
        #printf("%d, %d",svg.width,svg.height);
        
        svg.p_HSDcompass = svg.p_HSD.createChild("group")
            .setTranslation(svg.myPos_x,svg.myPos_y).set("z-index",10002);
        
        svg.compassRadius = svg.holeRadius*0.5;
        svg.compassL = 10;
        svg.c0 = svg.p_HSDcompass.createChild("text")
                .setText("N")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(-90*D2R), svg.compassRadius*math.sin(-90*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c3 = svg.p_HSDcompass.createChild("text")
                .setText("3")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(-60*D2R), svg.compassRadius*math.sin(-60*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c6 = svg.p_HSDcompass.createChild("text")
                .setText("6")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(-30*D2R), svg.compassRadius*math.sin(-30*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c9 = svg.p_HSDcompass.createChild("text")
                .setText("E")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(0*D2R), svg.compassRadius*math.sin(0*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c12 = svg.p_HSDcompass.createChild("text")
                .setText("12")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(30*D2R), svg.compassRadius*math.sin(30*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c15 = svg.p_HSDcompass.createChild("text")
                .setText("15")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(60*D2R), svg.compassRadius*math.sin(60*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c18 = svg.p_HSDcompass.createChild("text")
                .setText("S")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(90*D2R), svg.compassRadius*math.sin(90*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c21 = svg.p_HSDcompass.createChild("text")
                .setText("21")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(120*D2R), svg.compassRadius*math.sin(120*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c24 = svg.p_HSDcompass.createChild("text")
                .setText("24")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(150*D2R), svg.compassRadius*math.sin(150*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c27 = svg.p_HSDcompass.createChild("text")
                .setText("W")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(180*D2R), svg.compassRadius*math.sin(180*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c30 = svg.p_HSDcompass.createChild("text")
                .setText("30")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(210*D2R), svg.compassRadius*math.sin(210*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.c33 = svg.p_HSDcompass.createChild("text")
                .setText("33")
                .setAlignment("center-center")
                .setColor(0,1,0)
                .setTranslation(svg.compassRadius*math.cos(240*D2R), svg.compassRadius*math.sin(240*D2R))
                .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0);
        svg.compassLines = svg.p_HSDcompass.createChild("path")
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(10*D2R), (svg.compassRadius-svg.compassL)*math.sin(10*D2R))
                .lineTo(svg.compassRadius*math.cos(10*D2R), svg.compassRadius*math.sin(10*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(20*D2R), (svg.compassRadius-svg.compassL)*math.sin(20*D2R))
                .lineTo(svg.compassRadius*math.cos(20*D2R), svg.compassRadius*math.sin(20*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(40*D2R), (svg.compassRadius-svg.compassL)*math.sin(40*D2R))
                .lineTo(svg.compassRadius*math.cos(40*D2R), svg.compassRadius*math.sin(40*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(50*D2R), (svg.compassRadius-svg.compassL)*math.sin(50*D2R))
                .lineTo(svg.compassRadius*math.cos(50*D2R), svg.compassRadius*math.sin(50*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(70*D2R), (svg.compassRadius-svg.compassL)*math.sin(70*D2R))
                .lineTo(svg.compassRadius*math.cos(70*D2R), svg.compassRadius*math.sin(70*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(80*D2R), (svg.compassRadius-svg.compassL)*math.sin(80*D2R))
                .lineTo(svg.compassRadius*math.cos(80*D2R), svg.compassRadius*math.sin(80*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(100*D2R), (svg.compassRadius-svg.compassL)*math.sin(100*D2R))
                .lineTo(svg.compassRadius*math.cos(100*D2R), svg.compassRadius*math.sin(100*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(110*D2R), (svg.compassRadius-svg.compassL)*math.sin(110*D2R))
                .lineTo(svg.compassRadius*math.cos(110*D2R), svg.compassRadius*math.sin(110*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(130*D2R), (svg.compassRadius-svg.compassL)*math.sin(130*D2R))
                .lineTo(svg.compassRadius*math.cos(130*D2R), svg.compassRadius*math.sin(130*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(140*D2R), (svg.compassRadius-svg.compassL)*math.sin(140*D2R))
                .lineTo(svg.compassRadius*math.cos(140*D2R), svg.compassRadius*math.sin(140*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(160*D2R), (svg.compassRadius-svg.compassL)*math.sin(160*D2R))
                .lineTo(svg.compassRadius*math.cos(160*D2R), svg.compassRadius*math.sin(160*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(170*D2R), (svg.compassRadius-svg.compassL)*math.sin(170*D2R))
                .lineTo(svg.compassRadius*math.cos(170*D2R), svg.compassRadius*math.sin(170*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(190*D2R), (svg.compassRadius-svg.compassL)*math.sin(190*D2R))
                .lineTo(svg.compassRadius*math.cos(190*D2R), svg.compassRadius*math.sin(190*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(200*D2R), (svg.compassRadius-svg.compassL)*math.sin(200*D2R))
                .lineTo(svg.compassRadius*math.cos(200*D2R), svg.compassRadius*math.sin(200*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(220*D2R), (svg.compassRadius-svg.compassL)*math.sin(220*D2R))
                .lineTo(svg.compassRadius*math.cos(220*D2R), svg.compassRadius*math.sin(220*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(230*D2R), (svg.compassRadius-svg.compassL)*math.sin(230*D2R))
                .lineTo(svg.compassRadius*math.cos(230*D2R), svg.compassRadius*math.sin(230*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(250*D2R), (svg.compassRadius-svg.compassL)*math.sin(250*D2R))
                .lineTo(svg.compassRadius*math.cos(250*D2R), svg.compassRadius*math.sin(250*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(260*D2R), (svg.compassRadius-svg.compassL)*math.sin(260*D2R))
                .lineTo(svg.compassRadius*math.cos(260*D2R), svg.compassRadius*math.sin(260*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(280*D2R), (svg.compassRadius-svg.compassL)*math.sin(280*D2R))
                .lineTo(svg.compassRadius*math.cos(280*D2R), svg.compassRadius*math.sin(280*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(290*D2R), (svg.compassRadius-svg.compassL)*math.sin(290*D2R))
                .lineTo(svg.compassRadius*math.cos(290*D2R), svg.compassRadius*math.sin(290*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(310*D2R), (svg.compassRadius-svg.compassL)*math.sin(310*D2R))
                .lineTo(svg.compassRadius*math.cos(310*D2R), svg.compassRadius*math.sin(310*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(320*D2R), (svg.compassRadius-svg.compassL)*math.sin(320*D2R))
                .lineTo(svg.compassRadius*math.cos(320*D2R), svg.compassRadius*math.sin(320*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(340*D2R), (svg.compassRadius-svg.compassL)*math.sin(340*D2R))
                .lineTo(svg.compassRadius*math.cos(340*D2R), svg.compassRadius*math.sin(340*D2R))
                .moveTo((svg.compassRadius-svg.compassL)*math.cos(350*D2R), (svg.compassRadius-svg.compassL)*math.sin(350*D2R))
                .lineTo(svg.compassRadius*math.cos(350*D2R), svg.compassRadius*math.sin(350*D2R))
                .setColor(0,1,0)
                .setStrokeLineWidth(HSDlineWidth);
        
            
        
        
#        svg.buttonView = svg.p_HSD.createChild("group")
#            .setTranslation(276*0.795,482);
        svg.p_HSDmyPos = svg.p_HSD.createChild("group")
            .setTranslation(svg.myPos_x,svg.myPos_y).set("z-index",2);
        svg.cone = svg.p_HSDmyPos.createChild("group")
            .set("z-index",5);#radar cone
        svg.legs = svg.p_HSDmyPos.createChild("group")
            .set("z-index",3);
        

        svg.maxB = 21;#taken from VSD
        svg.blep = setsize([],svg.maxB);
        svg.ship = setsize([],svg.maxB);
        svg.blepText = setsize([],svg.maxB);
        for (var i = 0;i<svg.maxB;i+=1) {
            svg.blep[i] = svg.p_HSDmyPos.createChild("path")
                    .moveTo(8,12)
                    .lineTo(0,0)
                    .lineTo(-8,12)
                    .lineTo(8,12)
                    .moveTo(0,0)
                    .vert(-12)
                    .setColor(1,1,0) #yellow for now. Some are green (friendly), red (hostile), blue (fighter-link).
                    .setStrokeLineWidth(HSDlineWidth)#on the image some are segmented, I guess thats for not detected by own radar, so making them full drawn.
                    .set("z-index",10)
                    .hide();
            svg.ship[i] = svg.p_HSDmyPos.createChild("path")
                    .moveTo(-5,5)
                    .horiz(10)
                    .lineTo(7,0)
                    .horiz(-14)
                    .lineTo(-5,5)
                    .moveTo(-4,0)
                    .vert(-4)
                    .horiz(8)
                    .vert(4)
                    .setColor(1,1,0) #yellow for now. Some are green (friendly), red (hostile), blue (fighter-link).
                    .setStrokeLineWidth(HSDlineWidth)
                    .set("z-index",10)
                    .hide();
            svg.blepText[i] = svg.p_HSDmyPos.createChild("text")
                .setText("2F/23")
                .setAlignment("center-top")
                .setColor(1,1,0) #yellow for now. Some are green (friendly), red (hostile), blue (fighter-link).
                .set("z-index",9)
                .setFont(HSDfontFace).setFontSize(HSDblepFontSize, 1.0);
        }
        svg.steerpointsMaxUsed = -1;
        svg.steerpoints = [];
        svg.steerpointsText = [];

        svg.lock = svg.p_HSDmyPos.createChild("path")
                .moveTo(-12,-12)
                .vert(24)
                .moveTo(12,-12)
                .vert(24)
                .setColor(1,1,1)
                .setStrokeLineWidth(HSDlineWidth)# essentially the cursor. Full drawn as does not have fighter-link yet.
                .set("z-index",100)
                .hide();

        svg.myself = svg.p_HSDmyPos.createChild("path")#own ship
           .moveTo(0, -20)
           .vert(60)
           .moveTo(-20, 0)
           .horiz(40)
           .moveTo(-10, 20)
           .horiz(20)
           .setColor(0.5,0.5,1)# always light-blue
           .set("z-index",1)
           .setStrokeLineWidth(HSDlineWidth);

        svg.infoTgt = svg.p_HSD.createChild("text")
                .setText("2F/MIG29")
                .setAlignment("right-center")
                .setTranslation(1024*0.92,1024*0.8)
                .setColor(1,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoBer = svg.p_HSD.createChild("text")
                .setText("TN 00357")
                .setAlignment("right-center")
                .setTranslation(1024*0.92,1024*0.8+30)
                .setColor(1,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoPos = svg.p_HSD.createChild("text")
                .setText("23K G435")
                .setAlignment("right-center")
                .setTranslation(1024*0.92,1024*0.8+60)
                .setColor(1,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoArm = svg.p_HSD.createChild("text")
                .setText("A4A")
                .setAlignment("left-center")
                .setTranslation(1024*0.08,1024*0.8+30)
                .setColor(0,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoTime = svg.p_HSD.createChild("text")
                .setText("14:25:04Z")
                .setAlignment("left-center")
                .setTranslation(1024*0.08,1024*0.05)
                .setColor(1,1,1)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoPq = svg.p_HSD.createChild("text")
                .setText("RPQ 15")
                .setAlignment("left-center")
                .setTranslation(1024*0.08,1024*0.05+30)
                .setColor(0,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        svg.infoRange = svg.p_HSD.createChild("text")
                .setText("20")
                .setAlignment("right-center")
                .setTranslation(1024*0.92,1024*0.1)
                .setColor(0,1,0)
                .set("z-index",10020)
                .setFont(HSDfontFace).setFontSize(HSDlargeFontSize, 1.0);
        # TODO: these tables needs to be expanded:
        svg.shipLookup = {  
                "missile_frigate":          "",
                "frigate":                  "",
                "fleet":                    "",
                "USS-LakeChamplain":        "",
                "USS-NORMANDY":             "",
                "USS-OliverPerry":          "",
                "USS-SanAntonio":           "",
        };
        svg.samLookup = {
                "buk-m2":                   "11",
                "S-75":                     "02",
                "MIM104D":                  " P",
                "s300":                     "20",
        };     
        svg.typeLookup = {
                "f-14b":                    "F",     #fighter
                "F-14D":                    "F",    
                "F-15C":                    "F",     
                "F-15D":                    "F",    
                "F-16":                     "FB",#fighter bomber
                "YF-16":                    "F",      
                "JA37-Viggen":              "F",     
                "AJ37-Viggen":              "FB",     
                "AJS37-Viggen":             "FB",     
                "JA37Di-Viggen":            "F",      
                "m2000-5":                  "FB",
                "m2000-5B":                 "FB",
                "MiG-21bis":                "FB",
                "KC-137R":                  "TNKR",
                "KC-137R-RT":               "TNKR",#TNKR = Boom TDRG=drouge
                "707-TT":                   "TNKR",
                "KC-30A":                   "TNKR",
                "Voyager-KC":               "TNKR",
                "KC-10A":                   "TNKR",
                "KC-10A-GE":                "TNKR",
                "EC-137R":                  "AEW&C",#awacs airborne and groundborne
                "RC-137R":                  "AEW&C",
                "E-8R":                     "AEW&C",
                "EC-137D":                  "AEW&C",
                "gci":                      "AEW&C",
                "MiG-29":                   "F",
                "SU-27":                    "F",
                "ch53e":                    "HELO",#heli
                "MQ-9":                     "MC",#missile carrier
                "QF-4E":                    "F",
                "B1-B":                     "B",#bomber
                "A-10":                     "FB",
                "A-10-model":               "FB",
                "Typhoon":                  "FB",
                "f16":                      "F",
                "Tu-95MR":                  "B",
                "Tu-160-Blackjack":         "B",
                "AN-225-Mrija":             "C",#transport
                "Su-15":                    "F",
        };
    },

    addHSD: func {
        # almost the same if I do with empty svg or the other way:
        var svg = {getElementById: func (id) {return me[id]},};
        #var svg = canvas.parsesvg(obj.PFDsvg, "Nasal/MPCD/empty.svg");
        me.setupHSD(svg);
        me.PFD.addHSDPage = func(svg, title, layer_id) {   
            var np = PFD_Page.new(svg, title, layer_id, me);
            append(me.pages, np);
            me.page_index[layer_id] = np;
            np.setVisible(0);
            return np;
        };
        me.p_HSD = me.PFD.addHSDPage(svg, "HSD", "p_HSD");
        me.p_HSD.root = svg;
        me.p_HSD.wdt = svg.width;
        me.p_HSD.fwd = 0;
        me.p_HSD.plc = 0;
        me.p_HSD.ppp = me.PFD;
        me.p_HSD.my = me;
        
        me.p_HSD.root.showDAT = 1;
        me.p_HSD.root.showTGT = 1;
        me.p_HSD.root.showSAM = 1;
        me.p_HSD.root.showSHP = 1;
        me.p_HSD.root.showRTE = 1;
        me.p_HSD.root.showDIR = 1;

        me.p_HSD.update = func (noti) {
            
            me.root.holeRange          = awg_9.range_radar2*1.75;
            me.root.NM2PIXEL           = svg.holeHeight/me.root.holeRange;       
            me.i=0;
            me.root.lock.hide();
            me.rdrRangePixels = awg_9.range_radar2*me.root.NM2PIXEL;
            
            me.root.infoTime.setText(getprop("sim/time/gmt-string")~"Z");
            me.root.infoPq.setText("RPQ 15");
            me.root.infoRange.setText(""~awg_9.range_radar2);
            
            me.myHeading = getprop("orientation/heading-deg");
            
            if (me.root.showDIR) {
                me.magn = getprop("orientation/heading-magnetic-deg")*D2R;
                me.root.p_HSDcompass.setRotation(-me.magn);
                me.root.c0.setRotation(me.magn);
                me.root.c3.setRotation(me.magn);
                me.root.c6.setRotation(me.magn);
                me.root.c9.setRotation(me.magn);
                me.root.c12.setRotation(me.magn);
                me.root.c15.setRotation(me.magn);
                me.root.c18.setRotation(me.magn);
                me.root.c21.setRotation(me.magn);
                me.root.c24.setRotation(me.magn);
                me.root.c27.setRotation(me.magn);
                me.root.c30.setRotation(me.magn);
                me.root.c33.setRotation(me.magn);
                me.root.p_HSDcompass.show();
            } else {
                me.root.p_HSDcompass.hide();
            }
            
            me.w_s = getprop("sim/model/f15/controls/armament/weapon-selector");
            if (me.w_s == 0) {
                me.root.infoArm.setText(sprintf("G%3dP",getprop("sim/model/f15/systems/gun/rounds")));
            } else if (me.w_s == 1) {
                me.root.infoArm.setText(sprintf("S%dL", getprop("sim/model/f15/systems/armament/aim9/count")));
            } else if (me.w_s == 2) {
                me.root.infoArm.setText(sprintf("A%dB\nM%dF", getprop("sim/model/f15/systems/armament/aim120/count"), getprop("sim/model/f15/systems/armament/aim7/count")));
            } else if (me.w_s == 5) {
                me.root.infoArm.setText(sprintf("G%d", getprop("sim/model/f15/systems/armament/agm/count")));
            }
            me.root.cone.removeAllChildren();
            if (getprop("sim/multiplay/generic/int[2]") != 1) {
                me.radarX = me.rdrRangePixels*math.cos((90-120*0.5)*D2R);
                me.radarY = -me.rdrRangePixels*math.sin((90-120*0.5)*D2R);#radar hardcoded to 120 deg scanwidth
                me.cone = me.root.cone.createChild("path")
                    .moveTo(0,0)
                    .lineTo(me.radarX,me.radarY)
                    .moveTo(0,0)
                    .lineTo(-me.radarX,me.radarY)
                    #.arcSmallCW(me.rdrRangePixels,me.rdrRangePixels, 0, me.radarX*2, 0)
                    .setStrokeLineWidth(HSDlineWidth)
                    .set("z-index",5)
                    .setColor(0,1,0)# green
                    .update();
            }
            me.root.cone.update();
            me.j = 0;
            me.root.legs.removeAllChildren();
            if (getprop("autopilot/route-manager/active") and me.root.showRTE) {
                me.plan = flightplan();
                me.planSize = me.plan.getPlanSize();
                me.prevX = nil;
                me.prevY = nil;
                for (me.j = 0; me.j < me.planSize;me.j+=1) {
                    me.wp = me.plan.getWP(me.j);
                    me.wpC = geo.Coord.new();
                    me.wpC.set_latlon(me.wp.lat,me.wp.lon);
                    me.legBearing = geo.aircraft_position().course_to(me.wpC)-me.myHeading;#relative
                    me.legDistance = geo.aircraft_position().distance_to(me.wpC)*M2NM;
                    me.legRangePixels = me.legDistance*me.root.NM2PIXEL;
                    
                    me.legX = me.legRangePixels*math.sin(me.legBearing*D2R);
                    me.legY = -me.legRangePixels*math.cos(me.legBearing*D2R);
                    if (me.j > me.root.steerpointsMaxUsed) {
                        me.root.steerpointsMaxUsed += 1;
                        append(me.root.steerpoints, me.root.p_HSDmyPos.createChild("group").set("z-index",4));
                        me.root.steerpoints[me.j].createChild("path")
                            .moveTo(20,10)
                            .horiz(-40)
                            .lineTo(0,-20)
                            .setStrokeLineWidth(HSDlineWidth)
                            .set("z-index",4)
                            .setColor(1,0.75,0)#orange
                            .setColorFill(0,0,0);
                        append(me.root.steerpointsText, me.root.steerpoints[me.j].createChild("text")
                            .setText(""~me.j)
                            .setAlignment("left-center")
                            .setColor(1,0.75,0)
                            #.setFont(??)
                            .set("z-index",5)
                            .setTranslation(-4,0)
                            .setFont(HSDfontFace).setFontSize(HSDfontSize, 1.0));
                    }
                    me.root.steerpoints[me.j].setTranslation(me.legX,me.legY);
                    me.root.steerpointsText[me.j].setVisible(me.plan.current != me.j);

                    if (me.prevX != nil) {
                        me.root.legs.createChild("path")
                            .moveTo(me.legX,me.legY)
                            .lineTo(me.prevX,me.prevY)
                            .setStrokeLineWidth(HSDlineWidth)
                            .setColor(1,0.75,0)#orange
                            .update();
                    }
                    me.prevX = me.legX;
                    me.prevY = me.legY;
                }
            }
            for (;me.j<=me.root.steerpointsMaxUsed; me.j += 1) {
                me.root.steerpoints[me.j].hide();
            }

            me.foundLock = 0;
            
            foreach(contact; awg_9.tgts_list) {
                if (contact.get_display() == 0) {
                    continue;
                }
                me.distPixels = contact.get_range()*me.root.NM2PIXEL;
                
                me.relBearing = contact.get_deviation(me.myHeading);
                
                me.rot = contact.get_heading();
                me.rot -= me.myHeading;                
                
                
                if (contact.get_model()!=nil and me.root.samLookup[contact.get_model()] != nil) {
                    me.root.blep[me.i].hide();
                    me.root.ship[me.i].hide();
                    if (me.root.showSAM) {
                        me.root.blepText[me.i].setTranslation(me.distPixels*math.sin(me.relBearing*D2R),-me.distPixels*math.cos(me.relBearing*D2R));
                        me.root.blepText[me.i].setText(sprintf("%s", me.root.samLookup[contact.get_model()]));
                        me.root.blepText[me.i].show();
                    } else {
                        me.root.blepText[me.i].hide();
                    }
                } else {
                    if (contact.get_model()!=nil and me.root.shipLookup[contact.get_model()] != nil) {
                        me.root.blep[me.i].hide();
                        me.root.blepText[me.i].hide();
                        me.root.blep[me.i].hide();
                        if (me.root.showSHP) {
                            me.root.ship[me.i].setTranslation(me.distPixels*math.sin(me.relBearing*D2R),-me.distPixels*math.cos(me.relBearing*D2R));
                            me.root.ship[me.i].show();
                        } else {
                            me.root.ship[me.i].hide();
                        }
                    } else {
                        if (me.root.showTGT) {
                            me.root.ship[me.i].hide();
                            me.root.blep[me.i].setTranslation(me.distPixels*math.sin(me.relBearing*D2R),-me.distPixels*math.cos(me.relBearing*D2R));
                            me.root.blep[me.i].setRotation(me.rot*D2R);
                            me.root.blep[me.i].show();
                            me.root.blep[me.i].update();
                            if (me.root.showDAT) {
                                me.datType = "";
                                if (contact.get_model()!=nil and me.root.typeLookup[contact.get_model()] != nil) {
                                    me.datType = me.root.typeLookup[contact.get_model()]~"/";
                                }
                                me.root.blepText[me.i].setTranslation(me.distPixels*math.sin(me.relBearing*D2R),-me.distPixels*math.cos(me.relBearing*D2R)+12);
                                me.root.blepText[me.i].setText(sprintf("%s%02d", me.datType,contact.get_altitude()*0.001));
                                me.root.blepText[me.i].show();
                            } else {
                                me.root.blepText[me.i].hide();
                            }
                        } else {
                            me.root.ship[me.i].hide();
                            me.root.blepText[me.i].hide();
                            me.root.blep[me.i].hide();
                        }
                    }
                }
                if (contact==awg_9.active_u or (awg_9.active_u != nil and contact.get_Callsign() == awg_9.active_u.get_Callsign() and contact.ModelType==awg_9.active_u.ModelType)) {
                    me.foundLock = 1;
                    #can happen in transition between TWS to RWS
                    #me.root.lock.hide();
                    #me.root.lockAlt = me.lockAlt;
                    #me.lockInfo = sprintf("%4d   %+4d", contact.get_Speed(), contact.get_closure_rate());
                    me.root.lock.setTranslation(me.distPixels*math.sin(me.relBearing*D2R),-me.distPixels*math.cos(me.relBearing*D2R));
                    #me.cs = contact.get_Callsign();
                    me.root.lock.show();
                    me.root.lock.update();
                    me.datType = "";
                    if (contact.get_model()!=nil and me.root.typeLookup[contact.get_model()] != nil) {
                        me.datType = me.root.typeLookup[contact.get_model()]~"/";
                    }
                    me.modelType = "";
                    if (contact.get_model()!=nil) {
                        me.modelType = contact.get_model();
                    }
                    me.root.infoTgt.setText(me.datType~me.modelType);
                    me.root.infoPos.setText(sprintf("%dK G%d",contact.get_altitude()*0.001,contact.get_Speed()));
                    me.root.infoBer.setText(sprintf("TN 00%03d",geo.normdeg(me.relBearing)));
                    me.root.infoTgt.show();
                    me.root.infoPos.show();
                    me.root.infoBer.show();
                }
                me.i += 1;
                if (me.i > (me.root.maxB-1)) {
                    break;
                }
            }
            
            for (;me.i<me.root.maxB;me.i+=1) {
                me.root.ship[me.i].hide();
                me.root.blep[me.i].hide();
                me.root.blepText[me.i].hide();
            }
            if (!me.foundLock) {
                me.root.lock.hide();
                me.root.infoTgt.hide();
                me.root.infoPos.hide();
                me.root.infoBer.hide();
            }
        };
        me.p_HSD.notifyButton = func (eventi) {
            if (eventi != nil) {
                if (eventi == 0) {
                    me.root.showDAT = !me.root.showDAT;
                } elsif (eventi == 2) {
                    me.root.showTGT = !me.root.showTGT;
                } elsif (eventi == 3) {
                    me.root.showSAM = !me.root.showSAM;
                } elsif (eventi == 4) {
                    me.root.showSHP = !me.root.showSHP;
                } elsif (eventi == 6) {
                    me.root.showDIR = !me.root.showDIR;
                } elsif (eventi == 7) {
                    me.root.showRTE = !me.root.showRTE;
                } elsif (eventi == 9) {
                    me.ppp.selectPage(me.my.p1_1);
                }
            }
        };
    },
    # pushbutton rectangles: 1DAT(text under TGTs), 3TGT, 5SHP, 4SAM, 8RTE, 7DIR (compass)
    # TODO: bases shown differently

    addPages : func
    {
        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");
        me.addHSD();

        me.p1_1.update = func
        {
            var sec = getprop("instrumentation/clock/indicated-sec");
            me.page1_1.time.setText(getprop("sim/time/gmt-string")~"Z");
            var cdt = getprop("sim/time/gmt");

            if (cdt != nil)
                me.page1_1.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");
        me.p1_2 = me.PFD.addPage("Top Level PACS Menu", "p1_2");

        me.p1_3 = me.PFD.addPage("PACS Menu", "p1_3");
        me.p1_3.S0 = MPCD_Station.new(me.PFDsvg, 0);
        #1 droptank
        me.p1_3.S2 = MPCD_Station.new(me.PFDsvg, 2);
        me.p1_3.S3 = MPCD_Station.new(me.PFDsvg, 3);
        me.p1_3.S4 = MPCD_Station.new(me.PFDsvg, 4);
        #5 droptank
        me.p1_3.S6 = MPCD_Station.new(me.PFDsvg, 6);
        me.p1_3.S7 = MPCD_Station.new(me.PFDsvg, 7);
        me.p1_3.S8 = MPCD_Station.new(me.PFDsvg, 8);
        #9 droptank
        me.p1_3.S10 = MPCD_Station.new(me.PFDsvg, 10);

        me.p1_3.LBL_CHAFF = me.PFDsvg.getElementById("LBL_CHAFF");
        me.p1_3.LBL_FLARE = me.PFDsvg.getElementById("LBL_FLARE");
        me.p1_3.LBL_NONAVY = me.PFDsvg.getElementById("LBL_NONAVY");
        me.p1_3.LBL_CMD_MSS = me.PFDsvg.getElementById("LBL_CMD_MSS");
        me.p1_3.LBL_CBT_1 = me.PFDsvg.getElementById("p1_3_CBT_1");
        me.p1_3.LBL_CBT_2 = me.PFDsvg.getElementById("p1_3_CBT_2");

## AG page
        me.p1_4 = me.PFD.addPage("PACS Menu", "p1_4");
        me.p1_4.S0 = MPCD_GroundStation.new(me.PFDsvg, 0);
        me.p1_4.S1 = MPCD_GroundStation.new(me.PFDsvg, 1);
        me.p1_4.S2 = MPCD_GroundStation.new(me.PFDsvg, 2);
        me.p1_4.S3 = MPCD_GroundStation.new(me.PFDsvg, 3);
        me.p1_4.S4 = MPCD_GroundStation.new(me.PFDsvg, 4);
        me.p1_4.S5 = MPCD_GroundStation.new(me.PFDsvg, 5);
        me.p1_4.S6 = MPCD_GroundStation.new(me.PFDsvg, 6);
        me.p1_4.S7 = MPCD_GroundStation.new(me.PFDsvg, 7);
        me.p1_4.S8 = MPCD_GroundStation.new(me.PFDsvg, 8);
        me.p1_4.S9 = MPCD_GroundStation.new(me.PFDsvg, 9);
        me.p1_4.S10 = MPCD_GroundStation.new(me.PFDsvg, 10);

        me.p1_4.LBL_CHAFF = me.PFDsvg.getElementById("LBL_CHAFF-g");
        me.p1_4.LBL_FLARE = me.PFDsvg.getElementById("LBL_FLARE-g");
        me.p1_4.LBL_NONAVY = me.PFDsvg.getElementById("LBL_NONAVY-g");
        me.p1_4.LBL_CMD_MSS = me.PFDsvg.getElementById("LBL_CMD_MSS-g");
        me.p1_4.LBL_CBT_g = me.PFDsvg.getElementById("LBL_CBT_g1");
        me.p1_4.LBL_CBT2_g = me.PFDsvg.getElementById("LBL_CBT_g2");

## CBT JETT page
        me.p1_5 = me.PFD.addPage("Combat Jettison Page", "p1_5");
        me.p1_5.LM2_RACK_RECT = me.PFDsvg.getElementById("LM2_RACK_RECT");
        me.p1_5.LM3_STORE_RECT = me.PFDsvg.getElementById("LM3_STORE_RECT");
        me.p1_5.LM4_PYLON_RECT = me.PFDsvg.getElementById("LM4_PYLON_RECT");
        me.p1_5.BM_1_CBT_1_RECT = me.PFDsvg.getElementById("BM_1_CBT_1_RECT");
        me.p1_5.BM_2_CBT_2_RECT = me.PFDsvg.getElementById("BM_2_CBT_2_RECT");
        me.p1_5.TM10_L_RECT = me.PFDsvg.getElementById("TM10_L_RECT");
        me.p1_5.TM11_LC_RECT = me.PFDsvg.getElementById("TM11_LC_RECT");
        me.p1_5.TM12_C_RECT = me.PFDsvg.getElementById("TM12_C_RECT");
        me.p1_5.TM13_RC_RECT = me.PFDsvg.getElementById("TM13_RC_RECT");
        me.p1_5.TM14_R_RECT = me.PFDsvg.getElementById("TM14_R_RECT");
        me.p1_5.LBL_CBT_1 = me.PFDsvg.getElementById("p1_5_CBT_1");
        me.p1_5.LBL_CBT_2 = me.PFDsvg.getElementById("p1_5_CBT_2");

# These should be set when the button pushed...
        me.p1_5.BM_2_CBT_2_RECT.setVisible(0);
        me.p1_5.LM2_RACK_RECT.setVisible(0);
        me.p1_5.LM3_STORE_RECT.setVisible(1);
        me.p1_5.LM4_PYLON_RECT.setVisible(0);

        me.p1_5.TM10_L_RECT  .setVisible(0);
        me.p1_5.TM11_LC_RECT .setVisible(0);
        me.p1_5.TM12_C_RECT  .setVisible(1);
        me.p1_5.TM13_RC_RECT .setVisible(0);
        me.p1_5.TM14_R_RECT  .setVisible(0);

#
#PROGRAMMING COMBAT JETTISON
#
# Combat jettison is a two-push capability. With COMBAT selected on
# the SELECT JETT knob, the first push jettisons whatever is assigned to
# the CBT 1 program and the second jettisons whatever is assigned to the
# CBT 2 program.  Programming combat jettison is accomplished by
# selecting the ARMT display, then selecting the CBT JETT display
# (figure 1-13). The SELECT JETT knob may be in either OFF or
# COMBAT. Select the desired station(s) from PB’s 16 thru 20; 1 and 2
# are then displayed at PB 6 and PB 7 respectively. Select the CBT 1
# program by pressing PB 6; then select STORE, RACK or PYLON at PB 2, 3,
# or 4, respec- tively; STORE is automatically boxed when the dis- play
# is selected. Press ENTER (PB 10) to complete programming for CBT
# 1. Repeat these steps for CBT 2, with 2 selected on the display. If
# the SELECT JETT knob is in COMBAT, CBT 1 and CBT 2 are boxed on the
# display.
# 
# 1. ARMT main menu
# 2. CBT JETT from ARMT
# 3. SELJET Knob COMBAT or OFF
# 4. Select stations for CBT 1; (selected station is boxed) (LM)
# 5. TOP button to select store; store on LEFT menu is boxed
# 6. Select store, rack, pylon for selected station. selection is boxed
# on LM. (RH guess top menu changes to display STORE (e.g. FUEL)), RACK,
# PYLON

# 

# As one, two or all stations can be selected for each program, there may be different 
# variations seen in column 2, for instance: 
# CBT 1 LLCRC STORE means that for program 1 left + left conformal tank + right conformal tank stations were selected and stores will be jettisoned. 
# CBT 2 LLCCRCR RACK means that for program 2 all stations were selected and racks will be jettisoned etc.  
# Setting up combat jettison program 
# 1. Enter the CBT JETT page. 
# 2. Select the desired program (1 by default) pressing PB 5 or 6.  
# 3. Select the stations you want to program to jettison by pressing PBs 16 thru 20. 
# Mark stations will become boxed.  
# 4. When happy, select rack / store or pylon option using PBs 2 thru 4.  
# 5. Validate the selection by pressing ENTER (PB 10).   

#Each combat program will be displayed in the centre of the display, two lines each
#with 3 parts as follows:
#
#Part 1                        Part2                         Part3
#------------------------------------------------------------------
#CBT 1                         L (left)                       RACK
#CBT 2                         C (center)                    STORE
#                              R (right)                     PYLON
#                     
#                              LC (left conformal tank)     
#                              RC (right conformal tank)     
#e.g. CBT 1 LRC PYLON means that for program 1 left + right conformal tank stations were  selected and pylon will be jettisoned.  
# properties:
# cbtjett[0]/left
# cbtjett[0]/center
# cbtjett[0]/right
# cbtjett[0]/left-conformal
# cbtjett[0]/right-conformal
# cbtjett[0]/type
		me.p1_5.notifyButtonBase = me.p1_5.notifyButton;
        me.p1_5.notifyButton = func (eventi) {
            me.notifyButtonBase (eventi);
        };
        var oo = me;
        var update_flares = func(o) {
            v = getprop("/ai/submodels/submodel[5]/count");
            logprint(3, "submodel [5]",v);
            
            o.p1_3.LBL_CHAFF.setText(sprintf("CHF %3d",v));
            o.p1_3.LBL_FLARE.setText(sprintf(" FLR %2d",v));
            o.p1_3.LBL_NONAVY.setText("GLOBAL");
            o.p1_4.LBL_CHAFF.setText(sprintf("CHF %3d",v));
            o.p1_4.LBL_FLARE.setText(sprintf(" FLR %2d",v));
            o.p1_4.LBL_NONAVY.setText("GLOBAL");
        };
        update_flares(oo);
        setlistener("ai/submodels/submodel[5]/flare-release", func {
            update_flares(oo);
        });

        me.p_spin_recovery = me.PFD.addPage("Spin recovery", "p_spin_recovery");
        me.p_spin_recovery.cur_page = nil;

        me.p1_1.date = me.PFDsvg.getElementById("p1_1_date");
        me.p1_1.time = me.PFDsvg.getElementById("p1_1_time");

        me.p_spin_recovery.p_spin_cas = me.PFDsvg.getElementById("p_spin_cas");
        me.p_spin_recovery.p_spin_alt = me.PFDsvg.getElementById("p_spin_alt");
        me.p_spin_recovery.p_spin_alpha = me.PFDsvg.getElementById("p_spin_alpha");
        me.p_spin_recovery.p_spin_stick_left  = me.PFDsvg.getElementById("p_spin_stick_left");
        me.p_spin_recovery.p_spin_stick_right  = me.PFDsvg.getElementById("p_spin_stick_right");
        me.p_spin_recovery.update = func
        {
            me.p_spin_alpha.setText(sprintf("%d", getprop ("orientation/alpha-indicated-deg")));
            me.p_spin_alt.setText(sprintf("%5d", getprop ("instrumentation/altimeter/indicated-altitude-ft")));
            me.p_spin_cas.setText(sprintf("%3d", getprop ("instrumentation/airspeed-indicator/indicated-speed-kt")));

            if (math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368 
                or math.abs(getprop("fdm/jsbsim/velocities/p-rad_sec")) > 0.022)
            {
                me.p_spin_stick_left.setVisible(1);
                me.p_spin_stick_right.setVisible(0);
            }
            else
            {
                me.p_spin_stick_left.setVisible(0);
                me.p_spin_stick_right.setVisible(1);
            }
        };

        #
        # Page 1 is the time display
        me.p1_1.update = func
        {
            var sec = getprop("instrumentation/clock/indicated-sec");
            me.time.setText(getprop("sim/time/gmt-string")~"Z");
            var cdt = getprop("sim/time/gmt");

            if (cdt != nil)
                me.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        #
        # armament page gun rounds is implemented a little differently as the menu item (1) changes to show
        # the contents of the magazine.
        me.p1_3.gun_rounds = me.p1_3.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f15/systems/gun/rounds")), me.p1_3);

        setlistener("sim/model/f15/systems/gun/rounds", func(v)
                    {
                        if (v != nil) {
                            me.p1_3.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                            me.PFD.updateMenus();
                        }
                    }
            );
        me.p1_4.gun_rounds = me.p1_4.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f15/systems/gun/rounds")), me.p1_4);
        setlistener("sim/model/f15/systems/gun/rounds", func(v)
                    {
                        if (v != nil) {
                            me.p1_4.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                            me.PFD.updateMenus();
                        }
                    }
            );

        me.PFD.selectPage(me.p1_1);
        me.mpcd_button_pushed = 0;
        # Connect the buttons - using the provided model index to get the right ones from the model binding
        setlistener("sim/model/f15/controls/MPCD/button-pressed", func(v)
                    {
                        if (v != nil) {
                            if (v.getValue())
                                me.mpcd_button_pushed = v.getValue();
                            else {
                                me.PFD.notifyButton(me.mpcd_button_pushed);
                                me.mpcd_button_pushed = 0;
                            }
                        }
                    }
            );

        # Set listener on the PFD mode button; this could be an on off switch or by convention
        # it will also act as brightness; so 0 is off and anything greater is brightness.
        # ranges are not pre-defined; it is probably sensible to use 0..10 as an brightness rather
        # than 0..1 as a floating value; but that's just my view.
        setlistener("sim/model/f15/controls/PFD/mode"~me.model_index, func(v)
                    {
                        if (v != nil) {
                            me.mfd_device_status = v.getValue();
                            logprint(3, "MFD Mode ",me.designation," ",me.mfd_device_status);
                            if (!me.mfd_device_status)
                                me.PFDsvg.setVisible(0);
                            else
                                me.PFDsvg.setVisible(1);
                        }
                    }
            );
        # gets the description of what is loaded onto the stations
        # L,C,R. 
        # does not support CFT
        me.p1_5.get_loadout_desc = func (station,mode=0){
            # use 2 as this will have all the stores
            var str = "";
            foreach(var idx; aircraft.lcr_station_map[mode][station]){
                var v = getprop("payload/weight["~idx~"]/selected") or "";
                if (v == "Droptank")
                v = "FUEL";
                if (v != "" and v != "Empty" and v != "none"){
                    if (str != "")
                        str = str ~"\n";
                    str = str ~ string.truncateAt(v," ");
                }
            }
            return str;
        };
        # called whenever the menus related to CBT jettison are changed.
        # probably also will be used for the A/A and A/G Jettison page
        # which will likely reuse p1_5 or some of the logic.
        # the listener sets the property which is then picked up in the update
        # loop to save this being called too many times.
        me.reload_cbt_menus = func{
            me.reload_cbt_menus_required = 0;
            me.p1_5.menu10.title = me.p1_5.get_loadout_desc(0,0);
            me.p1_5.menu12.title = me.p1_5.get_loadout_desc(1,0);
            me.p1_5.menu14.title  = me.p1_5.get_loadout_desc(2,0);
            me.PFD.updateMenus();
            
            
            var j1 = aircraft.describe_selective_jettison(0);
            var j2 = aircraft.describe_selective_jettison(1);
            if (getprop("controls/armament/combat-jettison-count") > 0)
                j1 = "CBT 1: PERFORMED";
            if (getprop("controls/armament/combat-jettison-count") > 1)
                j2 = "CBT 2: PERFORMED";

            me.p1_3.LBL_CBT_1.setText(j1);
            me.p1_4.LBL_CBT_g.setText(j1);
            me.p1_5.LBL_CBT_1.setText(j1);
            me.p1_4.LBL_CBT2_g.setText(j2);
            me.p1_3.LBL_CBT_2.setText(j2);
            me.p1_5.LBL_CBT_2.setText(j2);

        };
        ## Droptank or Empty pylon
        setlistener("payload/weight[0]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[1]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[2]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[5]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[8]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[9]/selected", func {me.reload_cbt_menus_required = 1;});
        setlistener("payload/weight[10]/selected", func {me.reload_cbt_menus_required = 1;});

        me.reload_cbt_menus_required = 0;
        me.mpcd_button_pushed = 0;
        me.setupMenus();
        me.PFD.selectPage(me.p1_1);
    },

    # Add the menus to each page. 
    setupMenus : func
    {

        me.mpcd_spin_reset_time = 0;

        me.p1_1.addMenuItem(0, "ARMT", me.p1_2);
        me.p1_1.addMenuItem(1, "BIT", me.p1_2);
        me.p1_1.addMenuItem(2, "SIT", me.p_HSD);
        me.p1_1.addMenuItem(3, "WPN", me.p1_2);
        me.p1_1.addMenuItem(4, "DTM", me.p1_2);
        #//me.p1_1.addMenuItem(8, "SIT2", me.p_HSD);#added by niko
        
        me.p_HSD.addMenuItem(9, "M", me.p1_1);#added by niko
        me.p_HSD.addMenuItem(0, "DAT", me.p_HSD);#added by niko
        me.p_HSD.addMenuItem(2, "TGT", me.p_HSD);#added by niko
        me.p_HSD.addMenuItem(3, "SAM", me.p_HSD);#added by niko
        me.p_HSD.addMenuItem(4, "SHP", me.p_HSD);#added by niko
        me.p_HSD.addMenuItem(6, "DIR", me.p_HSD);#added by niko
        me.p_HSD.addMenuItem(7, "RTE", me.p_HSD);#added by niko

        me.p1_2.addMenuItem(1, "A/A", me.p1_3);
        me.p1_2.addMenuItem(2, "A/G", me.p1_4);
        me.p1_2.addMenuItem(3, "CBT\nJETT", me.p1_5);
        me.p1_2.addMenuItem(4, "WPN LOAD", me.p1_3);
        me.p1_2.addMenuItem(9, "M", me.p1_1);

        me.p1_3.addMenuItem(2, "SIT", me.p_HSD);
        me.p1_3.addMenuItem(3, "A/G", me.p1_4);
        me.p1_3.addMenuItem(4, "2/2", me.p1_3);
        me.p1_3.addMenuItem(8, "TM\nPWR", me.p1_3);
        me.p1_3.addMenuItem(9, "M", me.p1_1);
        me.p1_3.addMenuItem(15, "MODE S", me.p1_3);

        me.p1_4.addMenuItem(2, "SIT", me.p_HSD);
        me.p1_4.addMenuItem(3, "A/A", me.p1_3);
#        me.p1_4.addMenuItem(4, "2/2", me.p1_3);
#        me.p1_4.addMenuItem(8, "TM\nPWR", me.p1_3);
        me.p1_4.addMenuItem(9, "M", me.p1_1);
#        me.p1_4.addMenuItem(10, "PYLON", me.p1_4);
#        me.p1_4.addMenuItem(12, "FUEL", me.p1_4);
#        me.p1_4.addMenuItem(14, "PYLON", me.p1_4);
#        me.p1_4.addMenuItem(15, "MODE S", me.p1_3);

        me.p1_5.menu10 = me.p1_5.addMenuItem(10, "x", me.p1_5);
        me.p1_5.menu12 = me.p1_5.addMenuItem(12, "x", me.p1_5);
        me.p1_5.menu14 = me.p1_5.addMenuItem(14, "x", me.p1_5);
        me.p1_5.addMenuItem(1, "RACK", me.p1_5);
        me.p1_5.addMenuItem(2, "STORE", me.p1_5);
        me.p1_5.addMenuItem(3, "PYLON", me.p1_5);
        me.p1_5.addMenuItem(9, "MENU", me.p1_1);
        me.p1_5.menu15 = me.p1_5.addMenuItem(15, "1", me.p1_5);
        me.p1_5.menu16 = me.p1_5.addMenuItem(16, "2", me.p1_5);
        me.p1_5.addMenuItem(19, "ENTER", me.p1_3);

    },

    update : func(notification)
    {
    # see if spin recovery page needs to be displayed.
    # it is displayed automatically and will remain for 5 seconds.
    # this page provides (sort of) guidance on how to recover from a spin
    # which is identified by the yar rate.
        if (!(notification.wowN or notification.wowL or notification.wowR)  # not when any wow
            and math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368)
        {
            if (me.PFD.current_page != me.p_spin_recovery)
            {
                me.p_spin_recovery.cur_page = me.PFD.current_page;
                me.PFD.selectPage(me.p_spin_recovery);
            }
            me.mpcd_spin_reset_time = getprop("instrumentation/clock/indicated-sec") + 5;
        } 
        else
        {
            if (me.mpcd_spin_reset_time > 0 and getprop("instrumentation/clock/indicated-sec") > me.mpcd_spin_reset_time)
            {
                me.mpcd_spin_reset_time = 0;
                if (me.p_spin_recovery.cur_page != nil)
                {
                    me.PFD.selectPage(me.p_spin_recovery.cur_page);
                    me.p_spin_recovery.cur_page = nil;
                }
            }
        }
        if (me.reload_cbt_menus_required)
            me.reload_cbt_menus();
        if (me.mfd_device_status)
            me.PFD.update();
    },
};

#
# Connect the radar range to the nav display range. 
setprop("instrumentation/mpcd-sit/inputs/range-nm", getprop("instrumentation/radar/radar2-range"));
input = {
        wowN          : "gear/gear[0]/wow",
        wowL          : "gear/gear[1]/wow",
        wowR          : "gear/gear[2]/wow",
};

emexec.ExecModule.register("F-15 MPCD", input, MPCD_Device.new("F15-MPCD", "MPCDImage",0),1);

