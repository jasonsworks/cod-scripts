#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm;
#include maps\mp\zm_prison_sq_final;
#include maps\mp\zombies\_zm_net;
#include maps\mp\_visionset_mgr;

init()
{
    level thread onplayerconnect();
    precacheshader("waypoint_kill_red");
    replaceFunc(maps\mp\zm_prison_sq_final::final_showdown_create_icon, ::newCreateIcon);
}

newCreateIcon(player, enemy)
{
    height_offset = 30;
    hud_elem = newclienthudelem( player );
    hud_elem.x = enemy.origin[0];
    hud_elem.y = enemy.origin[1];
    hud_elem.z = enemy.origin[2] + height_offset;
    hud_elem.alpha = 1;
    hud_elem.archived = 1;
    hud_elem setshader( "waypoint_kill_red", 8, 8 );
    hud_elem setwaypoint( 1 );
    hud_elem.foreground = 1;
    hud_elem.hidewheninmenu = 1;
    hud_elem thread final_showdown_update_icon( enemy );

    // Original function doesn't return hud_elem for some reason
    // Needed to edit alpha for toggling visibility
    return hud_elem;
}

onplayerconnect()
{
    for(;;) 
    {
        level waittill ("connecting", player);
        player thread onplayerspawned();
        player thread toggleIcons();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    level endon("end_game");
    self.icons = [];
    self.iconsEnabled = false;
    counter = 0;
    for (;;) 
    {
        level waittill("initial_blackscreen_passed");
        iprintln("[^5Craftable Help^7] - Press ^32^7 to toggle craftable positions");
        foreach (uts_craftable in level.a_uts_craftables) 
        {
            if (uts_craftable.craftablestub.name == "alcatraz_shield_zm" || uts_craftable.craftablestub.name == "packasplat") 
            {
                foreach (piecespawn in uts_craftable.craftablespawn.a_piecespawns) 
                {
                    self.icons[counter] = self thread final_showdown_create_icon(self, piecespawn.model);
                    self.icons[counter].alpha = 0;
                    counter++;
                }
            }
        }
    }
}

toggleIcons()
{
    self endon("disconnect");
    for (;;)
    {
        wait(0.05);
        if(self actionslottwobuttonpressed())
        {
            if (!self.iconsEnabled)
            {
                self.iconsEnabled = true;
                foreach (icon in self.icons)
                {
                    icon.alpha = 1;
                }
            } else {
                self.iconsEnabled = false;
                foreach (icon in self.icons)
                {
                    icon.alpha = 0;
                }
            }
        }
    }
}