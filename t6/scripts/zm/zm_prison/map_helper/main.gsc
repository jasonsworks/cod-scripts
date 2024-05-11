#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\zm_prison_sq_bg;
#include maps\mp\zm_alcatraz_craftables;

init()
{
    replaceFunc(maps\mp\zm_alcatraz_craftables::onpickup_common, ::newPickup);
    replaceFunc(maps\mp\zm_prison_sq_bg::tomahawk_the_macguffin, ::skullTracker);
    replaceFunc(maps\mp\zm_alcatraz_craftables::onpickup_key, ::newPickupKey);
    precacheshader("waypoint_kill_red");
    precacheshader("waypoint_revive_afterlife");
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    for (;;) 
    {
        level waittill ("connecting", player);
        player thread onPlayerSpawned();
        player thread toggleCraftIcons();
        player thread toggleMacguffinIcons();
        player thread skullTracker();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("end_game");
    self.craftIcons = [];
    self.macguffinsIcons = [];
    self.macguffinsOrigins = [];
    self.craftIconsEnabled = false;
    self.macguffinsIconsEnabled = false;
    for (;;) 
    {
        level notify( "bouncing_tomahawk_zm_aquired" );
        level waittill("afterlife_start_over");
        iprintln("[^5Map Helper^7] - Press ^32^7 to toggle craftable positions");
        iprintln("[^5Map Helper^7] - Press ^35^7 to toggle skull positions");
        self thread checkSkulls();
        self thread checkPieces();
    }
}

checkPieces()
{
    counter = 0;
    foreach (uts_craftable in level.a_uts_craftables) 
    {
        if (uts_craftable.craftablestub.name == "alcatraz_shield_zm" || uts_craftable.craftablestub.name == "packasplat") 
        {
            foreach (piecespawn in uts_craftable.craftablespawn.a_piecespawns) 
            {
                self.craftIcons[counter] = self thread createIcon(self, piecespawn.model, "waypoint_kill_red");
                self.craftIcons[counter].alpha = 0;
                self.craftIcons[counter].name = piecespawn.piecename;
                counter++;
            }
        }
    }
    keyLocation = "";
    if (level.is_master_key_west)
    {
        keyLocation = "west";

    } else {
        keyLocation = "east";
    }
    t_pulley_hurt_trigger = getent( "pulley_hurt_trigger_" + keyLocation, "targetname" );
    self.craftIcons[counter+1] = self thread createIcon(self, t_pulley_hurt_trigger, "waypoint_kill_red");
    self.craftIcons[counter+1].alpha = 0;
    self.craftIcons[counter+1].name = "quest_key1";
}

checkSkulls()
{
    counter = 0;
    foreach (macguffin in level.sq_bg_macguffins)
    {
        self.macguffinsIcons[counter] = self thread createIcon(self, macguffin, "waypoint_revive_afterlife");
        self.macguffinsIcons[counter].alpha = 0;
        self.macguffinsOrigins[counter] = macguffin.origin;
        self.macguffinsIcons[counter].name = counter;
        counter++;
    }
}

skullTracker(grenade, n_grenade_charge_power)
{
    counter = 0;
    if (!isdefined(level.sq_bg_macguffins) || level.sq_bg_macguffins.size <= 0)
        return false;

    foreach (macguffin in level.sq_bg_macguffins)
    {
        if (distancesquared(macguffin.origin, grenade.origin) < 10000)
        {
            foreach (macguffinOrigin in self.macguffinsOrigins)
            {
                
                if (macguffin.origin == self.macguffinsOrigins[counter])
                {
                    self.macguffinsIcons[counter] destroy();
                }
                counter++;
            }
            m_tomahawk = maps\mp\zombies\_zm_weap_tomahawk::tomahawk_spawn( grenade.origin );
            m_tomahawk.n_grenade_charge_power = n_grenade_charge_power;
            macguffin notify("caught_by_tomahawk");
            macguffin.origin = grenade.origin;
            macguffin linkto(m_tomahawk);
            macguffin thread maps\mp\zombies\_zm_afterlife::disable_afterlife_prop();
            self thread maps\mp\zombies\_zm_weap_tomahawk::tomahawk_return_player(m_tomahawk);
            self thread give_player_macguffin_upon_receipt(m_tomahawk, macguffin);
            return true;
        }
    }

    return false;
    
}

newPickup(player)
{
    player playsound("zmb_craftable_pickup");
    self pickupfrommover();
    self.piece_owner = player;
    foreach (icon in player.craftIcons)
    {
        if (icon.name == self.piecename)
        {
            icon destroy();
        }
    }
    
}

newPickupKey(player)
{
    flag_set("key_found");

    foreach (icon in player.craftIcons)
    {
        if (icon.name == "quest_key1")
        {
            icon destroy();
        }
    }

    if (level.is_master_key_west)
        level clientnotify("fxanim_west_pulley_up_start");
    else
        level clientnotify("fxanim_east_pulley_up_start");

    a_m_checklist = getentarray("plane_checklist", "targetname");

    foreach (m_checklist in a_m_checklist)
    {
        m_checklist showpart("j_check_key");
        m_checklist showpart("j_strike_key");
    }

    a_door_structs = getstructarray("quest_trigger", "script_noteworthy");

    foreach (struct in a_door_structs)
    {
        if (isdefined(struct.unitrigger_stub))
        {
            struct.unitrigger_stub maps\mp\zombies\_zm_unitrigger::run_visibility_function_for_all_triggers();
        }
    }

    player playsound("evt_key_pickup");
    player thread do_player_general_vox("quest", "sidequest_key_response", undefined, 100);
    level setclientfield("piece_key_warden", 1);
}

createIcon(player, model, shader)
{
    height_offset = 15;
    icon = newclienthudelem(player);
    icon.x = model.origin[0];
    icon.y = model.origin[1];
    icon.z = model.origin[2] + height_offset;
    icon.alpha = 1;
    icon.archived = 1;
    icon setshader(shader, 8, 8);
    icon setwaypoint(1);
    icon.foreground = 1;
    icon.hidewheninmenu = 1;

    return icon;
}

toggleCraftIcons()
{
    self endon("disconnect");
    for (;;)
    {
        wait(0.05);
        if (self actionslottwobuttonpressed())
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
        if (self actionslotthreebuttonpressed())
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