#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm;
#include maps\mp\zm_prison_sq_final;
#include maps\mp\zombies\_zm_net;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_weap_tomahawk;
#include maps\mp\zombies\zm_prison_sq_bg;
#include maps\mp\zm_alcatraz_craftables;


init()
{
    level thread onplayerconnect();
    level.player_out_of_playable_area_monitor = false;
    precacheshader("waypoint_kill_red");
    precacheshader("waypoint_revive_afterlife");
}

onplayerconnect()
{
    for(;;) 
    {
        level waittill ("connecting", player);
        player thread onplayerspawned();
        player thread toggleCraftIcons();
        player thread toggleMacguffinIcons();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    level endon("end_game");
    self.craftIcons = [];
    self.macguffinsIcons = [];
    self.craftIconsEnabled = false;
    self.macguffinsIconsEnabled = false;
    for (;;) 
    {
        level waittill("initial_blackscreen_passed");
        level notify( "bouncing_tomahawk_zm_aquired" );
        iprintln("[^5Map Helper^7] - Press ^32^7 to toggle craftable positions");
        iprintln("[^5Map Helper^7] - Press ^35^7 to toggle skull positions");
        wait(5);
        self thread checkSkulls();
        self thread checkPieces();
        self.score = 100000;
    }
}

checkPieces()
{
    self endon("disconnect");
    level endon("end_game");
    counter = 0;
    foreach (uts_craftable in level.a_uts_craftables) 
    {
        println(uts_craftable.craftablestub.name);
        if (uts_craftable.craftablestub.name == "alcatraz_shield_zm" || uts_craftable.craftablestub.name == "packasplat") 
        {
            foreach (piecespawn in uts_craftable.craftablespawn.a_piecespawns) 
            {
                self.craftIcons[counter] = self thread createIcon(self, piecespawn.model, "waypoint_kill_red");
                self.craftIcons[counter].alpha = 0;
                counter++;
            }
        }
    }
    keyLocation = "";
    if ( level.is_master_key_west )
    {
        keyLocation = "west";

    } else {
        keyLocation = "east";
    }
    t_pulley_hurt_trigger = getent( "pulley_hurt_trigger_" + keyLocation, "targetname" );
    self.craftIcons[counter+1] = self thread createIcon(self, t_pulley_hurt_trigger, "waypoint_kill_red");
}

checkSkulls()
{
    self endon("disconnect");
    level endon("end_game");
    counter = 0;
    foreach (macguffin in level.sq_bg_macguffins)
    {
        self.macguffinsIcons[counter] = self thread createIcon(self, macguffin, "waypoint_revive_afterlife");
        self.macguffinsIcons[counter].alpha = 0;
        counter++;
    }
}

//maps/mp/zm_prison_sq_final.gsc
//final_showdown_create_icon
createIcon(player, model, shader)
{
    height_offset = 15;
    hud_elem = newclienthudelem(player);
    hud_elem.x = model.origin[0];
    hud_elem.y = model.origin[1];
    hud_elem.z = model.origin[2] + height_offset;
    hud_elem.alpha = 1;
    hud_elem.archived = 1;
    hud_elem setshader(shader, 8, 8);
    hud_elem setwaypoint(1);
    hud_elem.foreground = 1;
    hud_elem.hidewheninmenu = 1;

    return hud_elem;
}

toggleCraftIcons()
{
    self endon("disconnect");
    for (;;)
    {
        wait(0.05);
        if(self actionslottwobuttonpressed())
        {
            if (!self.craftIconsEnabled)
            {
                self.craftIconsEnabled = true;
                foreach (icon in self.craftIcons)
                {
                    icon.alpha = 1;
                }
            } else {
                self.craftIconsEnabled = false;
                foreach (icon in self.craftIcons)
                {
                    icon.alpha = 0;
                }
            }
        }
    }
}

toggleMacguffinIcons()
{
    self endon("disconnect");
    for (;;)
    {
        wait(0.05);
        if(self actionslotthreebuttonpressed())
        {
            if (!self.macguffinsIconsEnabled)
            {
                self.macguffinsIconsEnabled = true;
                foreach (icon in self.macguffinsIcons)
                {
                    icon.alpha = 1;
                }
            } else {
                self.macguffinsIconsEnabled = false;
                foreach (icon in self.macguffinsIcons)
                {
                    icon.alpha = 0;
                }
            }
        }
    }
}