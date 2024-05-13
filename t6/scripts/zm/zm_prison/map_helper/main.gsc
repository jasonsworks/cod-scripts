#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zm_alcatraz_utility;

main()
{
    replaceFunc(maps\mp\zm_alcatraz_craftables::onpickup_common, ::newPickup);
    replaceFunc(maps\mp\zm_prison_sq_bg::tomahawk_the_macguffin, ::skullTracker);
    replaceFunc(maps\mp\zm_alcatraz_craftables::onpickup_key, ::newPickupKey);
    replaceFunc(maps\mp\zm_alcatraz_amb::sndmusicegg_wait, ::newEggWait);
}

init()
{
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
        player thread skullTracker();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    level endon("end_game");
    self.bottlesIcons = [];
    self.bottlesOrigins = [];
    self.bottlesIconsEnabled = 0;
    self.craftIcons = [];
    self.craftIconsEnabled = 0;
    self.macguffinsIcons = [];
    self.macguffinsOrigins = [];
    self.macguffinsIconsEnabled = 0;
    for (;;) 
    {
        level notify( "bouncing_tomahawk_zm_aquired" );
        level waittill("afterlife_start_over");
        iprintln("[^5Map Helper^7] - Press ^3[{+actionslot 2}]^7 to toggle craftable positions");
        iprintln("[^5Map Helper^7] - Press ^3[{+actionslot 4}]^7 to toggle easter egg bottle positions");
        iprintln("[^5Map Helper^7] - Press ^3[{+actionslot 3}]^7 to toggle skull positions");
        self thread checkSkulls();
        self thread checkPieces();
        self thread checkBottles();
        self thread iconsController();
    }
}

checkBottles()
{
    self.bottlesOrigins[0] = (338, 10673, 1378);
    self.bottlesOrigins[1] = (2897, 9475, 1564);
    self.bottlesOrigins[2] = (-1157, 5217, -72 );
    counter = 0;

    foreach (bottle in self.bottlesOrigins)
    {
        self.bottlesIcons[counter] = self thread createIcon(self, self.bottlesOrigins[counter], "waypoint_kill_red");
        self.bottlesIcons[counter].alpha = 0;
        counter++;
    }
}

newEggWait(bottle_origin)
{
    temp_ent = spawn( "script_origin", bottle_origin );
    temp_ent playloopsound( "zmb_meteor_loop" );
    temp_ent thread maps\mp\zombies\_zm_sidequests::fake_use( "main_music_egg_hit", ::sndmusicegg_override );
    temp_ent waittill( "main_music_egg_hit", player );
    temp_ent stoploopsound( 1 );
    player playsound( "zmb_meteor_activate" );
    counter = 0;
    foreach (bottlesOrigin in player.bottlesOrigins)
    {
        if (temp_ent.origin == player.bottlesOrigins[counter])
        {
            player.bottlesIcons[counter] destroy();
        }
        counter++;
    }
    level.meteor_counter = level.meteor_counter + 1;

    if ( level.meteor_counter == 3 )
    {
        level thread sndmuseggplay( temp_ent, "mus_zmb_secret_song", 170 );
        level thread easter_egg_song_vo( player );
    }
    else
    {
        wait 1.5;
        temp_ent delete();
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
                self.craftIcons[counter] = self thread createIcon(self, piecespawn.model.origin, "waypoint_kill_red");
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
    self.craftIcons[counter+1] = self thread createIcon(self, t_pulley_hurt_trigger.origin, "waypoint_kill_red");
    self.craftIcons[counter+1].alpha = 0;
    self.craftIcons[counter+1].name = "quest_key1";
}

checkSkulls()
{
    counter = 0;
    foreach (macguffin in level.sq_bg_macguffins)
    {
        self.macguffinsIcons[counter] = self thread createIcon(self, macguffin.origin, "waypoint_revive_afterlife");
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

createIcon(player, origin, shader)
{
    height_offset = 15;
    icon = newclienthudelem(player);
    icon.x = origin[0];
    icon.y = origin[1];
    icon.z = origin[2] + height_offset;
    icon.alpha = 1;
    icon.archived = 1;
    icon setshader(shader, 8, 8);
    icon setwaypoint(1);
    icon.foreground = 1;
    icon.hidewheninmenu = 1;

    return icon;
}

iconsController()
{
  self endon("disconnect");
  level endon("end_game");
  level endon("game_ended");

  for(;;)
  {
    if(self actionslottwobuttonpressed())
    {
      self.craftIconsEnabled = !self.craftIconsEnabled;

      foreach(icon in self.craftIcons)
        icon.alpha = self.craftIconsEnabled;
    }

    if(self actionslotthreebuttonpressed())
    {
      self.macguffinsIconsEnabled = !self.macguffinsIconsEnabled;

      foreach(icon in self.macguffinsIcons)
        icon.alpha = self.macguffinsIconsEnabled;
    }

    if(self actionslotfourbuttonpressed())
    {
      self.bottlesIconsEnabled = !self.bottlesIconsEnabled;

      foreach(icon in self.bottlesIcons)
        icon.alpha = self.bottlesIconsEnabled;
    }

    wait 0.05;
  }
}