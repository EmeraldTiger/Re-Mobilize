
// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void(entity attacker, float damage) player_pain;
void() player_stand1;
//void (vector org) spawn_tfog; //moved to items.qc -- dumptruck_ds
void (vector org, entity death_owner) spawn_tdeath;


float	modelindex_eyes, modelindex_player;
void() SUB_CheckWaiting; // in triggers.qc

void() SetChangeParms =
{
	if (self.health <= 0)
	{
		SetNewParms ();
		return;
	}

// remove items
	self.items = self.items - (self.items &
	(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );

// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;
	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;
	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;
	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
	parm10 = self.visitflag;
};

void() SetNewParms =
{
	parm2 = 100;  // self.health
	parm3 = 0;    // self.armorvalue
	parm5 = 0;    // self.ammo_nails
	parm6 = 0;    // self.ammo_rockets
	parm7 = 0;    // self.ammo_cells
	parm9 = 0;    // self.armortype * 100

// "reset_items 2" makes the player start with only the axe -- iw
	if (world.reset_items == 2)
	{
		parm1 = IT_AXE;  // self.items
		parm4 = 0;       // self.ammo_shells
		parm8 = IT_AXE;  // self.weapon
	}
	else
	{
		parm1 = IT_AXE | IT_SHOTGUN;  // self.items
		parm4 = 25;                   // self.ammo_shells
		parm8 = IT_SHOTGUN;           // self.weapon
	}
};

void() DecodeLevelParms =
{
// Reset the player's inventory if they returned to the start map with
// a rune, or if the mapper set the "reset_items" field of worldspawn to
// a non-zero value.  (The old "reset_items" check, which this replaces,
// had a comment from dumptruck_ds thanking Spike.)  -- iw
//
	if ((serverflags != 0 && world.model == "maps/start.bsp") ||
			world.reset_items != 0)
	{
		SetNewParms ();
	}

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;
	self.visitflag = parm10;
	
	//Inky 20221029 Handling visited maps
	if (world.model == "maps/start.bsp")
	{
		//Identify all the trigger_changelevel entities and give them a unique visitflag id.
		float num, fv;
		entity portal;
		
		entity oself = self;
		
		//Start the loop
		num = 1;
		portal = find (world, classname, "trigger_changelevel");
		
		while (portal != world && num <= 24) //24 is the maximum number of flag values a float can hold
		{
			fv = flag_value(num);
			if (parm10 & fv)
			{
				//The destination map was visited already, let's fire its targets
				self = portal;
				SUB_UseTargets();
			}
			else
			{
				//The destination map was not visited yet. Let's give it a visitflag value so that it can notify the server when it's visited.
				portal.visitflag = num;
			}
			
			//Next one
			num++;
			portal = find (portal, classname, "trigger_changelevel");
		}
		
		self = oself;
	}
};

void(entity client, string savename) autosave =
{
	//autosavename = savename;
	stuffcmd(client, "echo Autosaving...; wait; save ");
	stuffcmd(client, savename);
	stuffcmd(client, "\n");
}

/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =

{
	// 1998-07-27 Suicide during intermission fix by Zhenga  start
	if ((intermission_running)&&((coop)||(deathmatch)))  // not allowed during intermission
		return;
// 1998-07-27 Suicide during intermission fix by Zhenga  end
	bprint (self.netname);
	bprint (" suicides\n");
	set_suicide_frame ();
	self.modelindex = modelindex_player;
	self.frags = self.frags - 2;	// extra penalty
	respawn ();
};

float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local	entity spot;
	local	entity thing;
	local	float  pcount;

// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}

	if (serverflags || (world.model == "maps/start.bsp" && parm10 > 0))
	{	// return with a rune to start or after having visited a map
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}

	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");

	return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;
void() monster_touch;		// 1998-09-16 Sliding/not-jumping on monsters/boxes/players fix by Maddes/Kryten

void() PutClientInServer =
{
	local	entity spot;

	spot = SelectSpawnPoint ();

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	self.deathtype = "";
	self.gravity = 0;
	self.wantedgravity = 0;
	self.onladder = 0;
	self.onWiremesh = 0;
	self.wiremesh = world;
	self.customkeys = 0;  // support for item_key_custom -- iw

	// Setup cutscene stuff.  Legacy code from Zerstorer. --dumptruck_ds
	    self.script_count = 2;
	    self.script_delay = 1;
	    self.script_time  = 0;


	DecodeLevelParms ();

	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;
	self.touch = monster_touch;	// 1998-09-16 Sliding/not-jumping on monsters/boxes/players fix by Maddes/Kryten
	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;

//	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	// fog control.
	// Looks if there's any fog values set at the current spawn point. If not, looks for those in worldspawn instead
	if (spot.fog_density)
		fog_save(self, spot.fog_density, spot.fog_color);
	else if (world.fog_density)
		fog_save(self, world.fog_density, world.fog_color);

	if (spot.skyfog_density)
		skyfog_save(self, spot.skyfog_density);
	else if (world.skyfog_density)
		skyfog_save(self, world.skyfog_density);

	cleanUpClientStuff = 2; // decreased on subsequent frames, used to startup some fog-related stuff

// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/s_null.spr");     // Drake -- dumptruck_ds
	// setmodel (self, "progs/null_256.spr");     // Drake -- dumptruck_ds
	mindex_inviso = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';
// Mod - Xian (May.20.97)
// Bug where player would have velocity from their last kill
	self.velocity = '0 0 0';	// 1998-07-21 Player moves after respawn fix by Xian

	player_stand1 ();

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
	}

	spawn_tdeath (self.origin, self);
	
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24) X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
{
model ("progs/player.mdl");
}
The normal starting point for a level.
*/
void() info_player_start =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24) X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
{
model ("progs/player.mdl");
}
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24) X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
{
model ("progs/player.mdl");
}
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24) X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
{
model ("progs/player.mdl");
}
potential spawning position for coop games
*/
void() info_player_coop =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
};

/*QUAKED info_monster_spawnpoint (1 0 1) (-16 -16 -24) (16 16 24) X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
{
model ("progs/teleport.mdl");
}
 spawning position for func_monster_spawner
*/
void() info_monster_spawnpoint =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
	local entity o;

	if (mapname == "start")
	{
		if (!cvar("registered"))
		{
			mapname = "e1m1";
		}
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
			serverflags = serverflags | 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
			serverflags = serverflags | 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
			serverflags = serverflags | 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
			serverflags = serverflags - 7;
		}

		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;
	gameover = TRUE;

	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local	float		timelimit;
	local	float		fraglimit;

	if (gameover)	// someone else quit the game already
		return;

	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");

if (deathmatch && timelimit && time >= timelimit)	// 1998-07-27 Timelimit/Fraglimit fix by Maddes
	{
		NextLevel ();
		return;
	}

if (deathmatch && fraglimit && self.frags >= fraglimit)	// 1998-07-27 Timelimit/Fraglimit fix by Maddes
	{
		NextLevel ();
		return;
	}
};

//============================================================================

void() PlayerDeathThink =
{
	local float 	forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};

/*
===========
PlayerClimb
============
*/
void() PlayerClimb = //johnfitz
{
	self.velocity = '0 0 160';
}


void() PlayerJump =
{

	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

// play swiming sound
		if (self.swim_flag < time)
		{
			self.swim_flag = time + 1;
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}

		return;
	}

	// refactoring from Copper -- dumptruck_ds
	if (self.movetype != MOVETYPE_NOCLIP)
	{
		if (!(self.flags & FL_ONGROUND)) return;
		if ( !(self.flags & FL_JUMPRELEASED) ) return;		// don't pogo stick
		// player jumping sound
		sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);	// h00rt
	}

	// if (!(self.flags & FL_ONGROUND))
	// 	return;
	//
	// if ( !(self.flags & FL_JUMPRELEASED) )
	// 	return;		// don't pogo stick
	// refactoring from Copper -- dumptruck_ds
	// self.flags = not(self.flags, FL_JUMPRELEASED | FL_ONGROUND);	// don't stairwalk

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk

	self.button2 = 0;
	// sound (self, CHAN_AUTO, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};

/*
===========
PlayerMesh
============
*/
void() PlayerMesh =
{
   local vector start, end;

   makevectors (self.v_angle);
   
   self.velocity = v_forward * self.meshspeed;
   
   makevectors (self.angles);
	start = self.origin;
	normalize(v_forward);
	end = start + v_forward*100;
	traceline (start, end, TRUE, self);
}


/*
===========
WaterMove

============
*/
.float	dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
	// if (self.movetype == MOVETYPE_NOCLIP)
	// 	return;
	//from Copper -- dumptruck_ds
	if (self.movetype == MOVETYPE_NOCLIP)
	{
		self.air_finished = time + 120;
		return;
	}

	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			self.deathtype = "drowning";
			T_Damage (self, world, world, self.dmg);
			self.deathtype = "";
			self.pain_finished = time + 1;
		}
	}

	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			self.deathtype = "lava";
			T_Damage (self, world, world, 10*self.waterlevel);
			self.deathtype = "";
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			self.deathtype = "slime";
			T_Damage (self, world, world, 4*self.waterlevel);
			self.deathtype = "";
		}
	}

	if ( !(self.flags & FL_INWATER) )
	{

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}

	if (! (self.flags & FL_WATERJUMP) )
		self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
};

void() CheckWaterJump =
{
	if (self.movetype == MOVETYPE_NOCLIP) // from Copper -- dumptruck_ds
		return;
		
	if (self.state & STATE_RM_AIMING) {
		return;
	}

	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};

void(entity player, float show) toggle_inventory;
void(entity player) NotifyUnhook;

void() CheckGrapple =
{
	
	local vector player_offset;
	player_offset = self.origin + self.view_ofs;
	
	// (Credit to Inky for this)
	self.solid = SOLID_NOT;
	traceline(player_offset, (player_offset + (v_forward * 10000)), FALSE, aimIgnore);
	self.solid = SOLID_SLIDEBOX;
	
	local	entity new, oself;
	local	float dist;
	local	vector panel_origin;
	local	vector player_aim;
	
	if ((trace_ent.classname=="func_hook") && trace_ent.estate == STATE_ACTIVE && !trace_ent.locked_on) {
		new = spawn();
		new.origin_x = trace_endpos[0];
		new.origin_y = trace_endpos[1];
		new.origin_z = trace_endpos[2];
		panel_origin = new.origin;
		dist = vlen(trace_endpos - self.origin);
		new.angles = vectoangles(self.origin - trace_endpos);
		
		if (trace_ent.volume) {
			self.volume = 1;
		}
		else {
			self.volume = 0;
		}
		
		player_aim = player_offset + (v_forward * 200);
		new.origin = player_aim;
		
		if(!(trace_ent.spawnflags & /*Non rotating tracer*/4))
			new.angles[2] = (time * 100) % 360;
		new.alpha = (dist / 300) - (0.5);
		setmodel (new, trace_ent.mdl);

		setsize (new, '0 0 0', '0 0 0');
		new.think = SUB_Remove;
		new.ltime = time;
		new.nextthink = time + 0.02;
		
		//Fire lightpanel targets on entering aiming mode
		if(!(self.state & STATE_RM_AIMING))
		{
			self.state |= STATE_RM_AIMING;
			self.rotatecontroller = trace_ent; //The .rotatecontroller property is reused in the lightpanel context to keep trace of what lightpanel was aimed at upon exiting aiming state (see if case below)
			activator = self;
			oself = self;
			self = trace_ent;
			SUB_UseTargets();
			self = oself;
		}
	}
	else if(self.state & STATE_RM_AIMING && self.rotatecontroller) //Fire lightpanel targets on exiting aiming mode
	{
		self.state = self.state - (self.state & STATE_RM_AIMING);
		self.state |= STATE_RM_UNAIMING;
		activator = self;
		oself = self;
		self = self.rotatecontroller;
		SUB_UseTargets();
		self = oself;
		self.rotatecontroller = world;
		self.state = self.state - (self.state & STATE_RM_UNAIMING);
	}
	
	if (trace_ent.volume) {
		trace_ent.owner = self;
	}
	
	if (self.impulse==24 && !self.hook_out && trace_ent.classname=="func_hook")
	{
		if (!(trace_ent.spawnflags & /*Aim only*/1)) {
			W_FireGrapple();
		}
		
		//Fire lightpanel targets on hooking
		if((self.state & STATE_RM_AIMING) && !(self.state & STATE_RM_HOOKING))
		{
			self.state = self.state - (self.state & STATE_RM_AIMING);
			self.state |= STATE_RM_HOOKING;
			activator = self;
			oself = self;
			self = trace_ent;
			SUB_UseTargets();
			self = oself;
		}
	}
	else if(self.impulse==24 && trace_ent.classname!="func_hook" && vlen(trace_endpos-player_offset)>250)
	{
		toggle_inventory(self, TRUE);
	}

}

void(string target_class) MakeClassSolid =
{
    entity e;
    e = world;
    while( (e = find(e, classname, target_class)) )
    {
        e.solid = SOLID_BSP;
        e.movetype = MOVETYPE_PUSH;
    }
};
 
void(string target_class) MakeClassNonSolid =
{
    entity e;
    e = world;
    while( (e = find(e, classname, target_class)) )
    {
        e.solid = SOLID_NOT;
        e.movetype = MOVETYPE_NONE;
    }
};

/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	local float do_ladder_physics;
	local float do_wiremesh_physics = FALSE;
	
	local float playedsound;
	
	// Re:Mobilize: Need to reset cushion state, otherwise cushion sounds will continue on normal surfaces
	self.cushion = world;

	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		{
			Cutscene_Think ();      // Check for cutscene stuff.
			return;        // intermission or finale
	}

	if (!self.onWiremesh)
	{
		//Fire wiremesh targets on climbing mode change
		if(self.state & STATE_RM_CLIMBING)
		{
			self.state = self.state - (self.state & STATE_RM_CLIMBING);
			activator = self;
			entity oself = self;
			self = self.wiremesh;
			SUB_UseTargets();
			self = oself;
		}
	}

	// note that this code block is here, before the tests which check
	// whether the player is dead, so that the player's gravity will be
	// correctly updated even if they e.g. fell off a ladder because
	// they died -- iw
	if (self.onladder)
	{
		do_ladder_physics = TRUE;
		self.gravity = 0.0000001;	// not zero, because zero means "default"
		self.onladder = 0;
	}
	else if (self.onWiremesh) // Re:Mobilize
	{
		do_wiremesh_physics = TRUE;
		self.gravity = 0.0000001;	// not zero, because zero means "default"
		self.onWiremesh = 0;
	}
	else
	{
		do_ladder_physics = FALSE;
		do_wiremesh_physics = FALSE;
		self.gravity = self.wantedgravity;
	}
	
	// If just spawned in, try to recover previous fog values from own client entity, if any
	if (cleanUpClientStuff)
		fog_setFromEnt(self, self);

	MakeClassSolid("func_playerclip");
	
	makevectors (self.v_angle);		// is this still used

	CheckRules ();
	WaterMove ();

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}

	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

//johnfitz ladder conditions //added from Rubicon2 client.qc -- dumptruck_ds
if (do_ladder_physics)
{
	if (self.button2)
	{
		PlayerClimb ();

		/* no ladder footsteps for now
		if (time > self.ladder_step_finished) {
			r = random();
			if (r > 0.66)
				sound (self, CHAN_BODY, "ladder/metal1.wav", 0.5, ATTN_NORM);
			else if (r > 0.33)
				sound (self, CHAN_BODY, "ladder/metal2.wav", 0.5, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "ladder/metal3.wav", 0.5, ATTN_NORM);
			self.ladder_step_finished = time + 0.3;
		}
		*/
	}
	else
	{
		self.flags = self.flags | FL_JUMPRELEASED;
		self.velocity = 0.9 * self.velocity;
		self.velocity_z = 0;
	}
}
else if (do_wiremesh_physics)
{

	if (self.button2)
	{
		PlayerMesh ();
		
		playedsound = 0;
		
		if (self.meshnoise != "" || self.meshnoise2 != "" || self.meshnoise3 != "" || self.meshnoise4 != "") {
			if (time > self.ladder_step_finished) {
				if (random() > 0.5) {
					if (random() > 0.5 && self.meshnoise != "") {
						sound (self, CHAN_AUTO, self.meshnoise, 1, ATTN_NORM);
						playedsound = 1;
					}
					else if (self.meshnoise2 != "") {
						sound (self, CHAN_AUTO, self.meshnoise2, 1, ATTN_NORM);
						playedsound = 1;
					}
				}
				else {
					if (random() > 0.5 && self.meshnoise3 != "") {
						sound (self, CHAN_AUTO, self.meshnoise3, 1, ATTN_NORM);
						playedsound = 1;
					}
					else if (self.meshnoise4 != "") {
						sound (self, CHAN_AUTO, self.meshnoise4, 1, ATTN_NORM);
						playedsound = 1;
					}
			}
			if (playedsound) {
				self.ladder_step_finished = time + 0.5;
			}
			}
		}
		else if (self.meshsounds==1) {
			
			if (time > self.ladder_step_finished) {
				if (random() > 0.5)
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/vines1.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/vines2.wav", 1, ATTN_NORM);
				else
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/vines3.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/vines4.wav", 1, ATTN_NORM);
				self.ladder_step_finished = time + 0.5;
			}
			
		}
		else if (self.meshsounds==2) {
			
			if (time > self.ladder_step_finished) {
				if (random() > 0.5)
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/sticky1.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/sticky2.wav", 1, ATTN_NORM);
				else
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/sticky3.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/sticky4.wav", 1, ATTN_NORM);
				self.ladder_step_finished = time + 0.5;
			}
			
		}
		else if (self.meshsounds==3) {
			
			if (time > self.ladder_step_finished) {
				sound (self, CHAN_AUTO, "misc/retro1.wav", 1, ATTN_NORM);
				self.ladder_step_finished = time + 0.3;
			}
			
		}
		else if (self.meshsounds==4) {
			
			if (time > self.ladder_step_finished) {
				if (random() > 0.5)
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/wood1.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/wood2.wav", 1, ATTN_NORM);
				else
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/wood3.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/wood4.wav", 1, ATTN_NORM);
				self.ladder_step_finished = time + 0.5;
			}
			
		}
		else {
			
			if (time > self.ladder_step_finished) {
				if (random() > 0.5)
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/mesh1.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/mesh2.wav", 1, ATTN_NORM);
				else
					if (random() > 0.5)
						sound (self, CHAN_AUTO, "misc/mesh3.wav", 1, ATTN_NORM);
					else
						sound (self, CHAN_AUTO, "misc/mesh4.wav", 1, ATTN_NORM);
				self.ladder_step_finished = time + 0.5;
			}
			
		}
			
		
	}
	else
	{
		self.flags = self.flags | FL_JUMPRELEASED;
		self.velocity = 0.9 * self.velocity;
		self.velocity_z = 0;
	}
}
else
{
	if (self.button2)
		PlayerJump ();
	else
		self.flags = self.flags | FL_JUMPRELEASED;
} //johnfitz

// teleporters can force a non-moving pause time
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}
	// from copper -- dumptruck_ds
	if (self.movetype == MOVETYPE_NOCLIP)
	{
		self.flags = self.flags | FL_FLY;
	}
	
	// Re:Mobilize: Lighthook
	
	if (self.impulse==25)
	{
		toggle_inventory(self, FALSE);
		
		if(self.rotatecontroller==world || (self.rotatecontroller!=world && self.rotatecontroller.spawnflags & /*Aim only*/1))
			NotifyUnhook(self);		
	}
	
	CheckGrapple();
	
	if (self.hook_out)
		GrappleService();
		
	if (self.waterlevel == 2)
		CheckWaterJump ();
	
	//Display custom keys inventory
	if(invPanel) invPanel.origin = self.origin + v_forward*(250) + v_up*(100);
	if(self.skip_id1_overrides > 0)
	{
		float dist = world.distance;
		if(dist==0) dist = 70;
		
		float hoffset = -0.5*dist*(self.skip_id1_overrides - 1);
		
		makevectors(self.v_angle);
		if(invItem1) invItem1.origin = self.origin + v_forward*(200 + invItem1.view_ofs_x) + v_right*(hoffset + invItem1.view_ofs_y         ) + v_up*(40 + invItem1.view_ofs_z);
		if(invItem2) invItem2.origin = self.origin + v_forward*(200 + invItem2.view_ofs_x) + v_right*(hoffset + invItem2.view_ofs_y +   dist) + v_up*(40 + invItem2.view_ofs_z);
		if(invItem3) invItem3.origin = self.origin + v_forward*(200 + invItem3.view_ofs_x) + v_right*(hoffset + invItem3.view_ofs_y + 2*dist) + v_up*(40 + invItem3.view_ofs_z);
		if(invItem4) invItem4.origin = self.origin + v_forward*(200 + invItem4.view_ofs_x) + v_right*(hoffset + invItem4.view_ofs_y + 3*dist) + v_up*(40 + invItem4.view_ofs_z);
		if(invItem5) invItem5.origin = self.origin + v_forward*(200 + invItem5.view_ofs_x) + v_right*(hoffset + invItem5.view_ofs_y + 4*dist) + v_up*(40 + invItem5.view_ofs_z);
		if(invLabel1) invLabel1.origin = self.origin + v_forward*(200) + v_right*(hoffset         ) + 2*v_up;
		if(invLabel2) invLabel2.origin = self.origin + v_forward*(200) + v_right*(hoffset +   dist) + 2*v_up;
		if(invLabel3) invLabel3.origin = self.origin + v_forward*(200) + v_right*(hoffset + 2*dist) + 2*v_up;
		if(invLabel4) invLabel4.origin = self.origin + v_forward*(200) + v_right*(hoffset + 3*dist) + 2*v_up;
		if(invLabel5) invLabel5.origin = self.origin + v_forward*(200) + v_right*(hoffset + 4*dist) + 2*v_up;
	}
		
	for (entity e = world; (e = find(e, face_always, "1")); )
		e.angles = vectoangles(self.origin - e.origin);
	for (entity e = world; (e = find(e, face_always, "2")); )
	{
		e.angles = vectoangles(self.origin - e.origin);
		e.angles_x = 0;
	}
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
	else
		self.modelindex = modelindex_player;	// don't use eyes

// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}

			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

// suit
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}

			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}
};

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (self.deadflag)
		return;

	MakeClassNonSolid("func_playerclip");
	
// do weapon stuff

	W_WeaponFrame ();
	
// Re:Mobilize: Cushion sounds for trampolines (landing on them without pressing jump)

if ((self.jump_flag < -100) && (self.flags & FL_ONGROUND) && (self.health > 0)) 
{
		if (self.cushion) 
		{
			if (self.cushionnoise!="") {
				sound (self, CHAN_AUTO, self.cushionnoise, 1, ATTN_NORM);
			}
			else if (self.cushionsounds==1)
			{
				sound (self, CHAN_AUTO, "misc/cushion2.wav", 1, ATTN_NORM);
			}
			else if (self.cushionsounds==2)
			{
				sound (self, CHAN_AUTO, "misc/cushion3.wav", 1, ATTN_NORM);
			}
			else if (self.cushionsounds==3)
			{
				sound (self, CHAN_AUTO, "misc/cushion4.wav", 1, ATTN_NORM);
			}
			else if (self.cushionsounds==4)
			{
				sound (self, CHAN_AUTO, "misc/cushion5.wav", 1, ATTN_NORM);
			}
			else if (self.cushionsounds==5)
			{
				sound (self, CHAN_AUTO, "misc/cushion6.wav", 1, ATTN_NORM);
			}
			else
			{
				sound (self, CHAN_AUTO, "misc/cushion1.wav", 1, ATTN_NORM);
			}
			
			self.jump_flag = 0;
			
			//Fire trampoline targets on cushion landing
			float ostate = self.state;
			self.state = ostate | STATE_RM_CUSHIONED;
			entity oactivator = activator;
			activator = self;
			entity oself = self;
			self = self.cushion;
			SUB_UseTargets();
			self = oself;
			activator = oactivator;
			self.state = ostate;
		}
}

// check to see if player landed and play landing sound
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			self.deathtype = "falling";
			// Can't die from fall damage anymore
			if (self.health <= 5) {
				T_Damage (self, world, world, self.health - 1);
			}
			else {
				T_Damage (self, world, world, 5);
			}
			self.deathtype = "";
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
		}
		else {
			if (!self.cushion) {
				sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
			}
		}

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	if (self.health > self.max_health) //dumptruck_ds --  this replaces item_megahealth_rot in items.qc

	{
		if (self.megahealth_rottime < time)
			{
					self.megahealth_rottime = time + 1;
					self.health = self.health - 1;
			}

		else if (self.health <= 100)   //thanks ydrol!!!
		self.items = self.items - (self.items & IT_SUPERHEALTH);
}

CheckPowerups ();
// from Copper -- dumptruck_ds
if (self.movetype != MOVETYPE_NOCLIP)
{
	self.flags = not(self.flags, FL_FLY);
}

};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	bprint (self.netname);
	bprint (" entered the game\n");

// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

	// let everyone else know
	bprint (self.netname);
	bprint (" left the game with ");
	bprint (ftos(self.frags));
	bprint (" frags\n");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity inflictor, entity attacker) ClientObituary =
{
	local	float rnum;
	local	string deathstring, deathstring2;
	rnum = random();

	if (targ.classname == "player")
	{
		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("Satan's power deflects ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");

			targ.frags = targ.frags - 1;
			return;
		}
// 1998-07-26 Pentagram telefrag fix by Zoid/Maddes  start
		// double 666 telefrag
		// (can happen often in deathmatch 4 and levels with more than one pentagram)
		if (attacker.classname == "teledeath3")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("'s Satan's power\n");
// 1998-07-26 only telefrag player on spot by Maddes  start
//			targ.frags = targ.frags - 1;
			attacker.owner.frags = attacker.owner.frags + 1;
// 1998-07-26 only telefrag player on spot by Maddes  end
			return;
		}
// 1998-07-26 Pentagram telefrag fix by Zoid/Maddes  end
		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{
				// killed self
				attacker.frags = attacker.frags - 1;
				bprint (targ.netname);

				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					bprint (" discharges into the water.\n");
					return;
				}
				if (targ.weapon == IT_GRENADE_LAUNCHER)
					bprint (" tries to put the pin back in\n");
				else
					bprint (" becomes bored with life\n");
				return;
			}
			else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				attacker.frags = attacker.frags - 1;
				return;
			}
			else
			{
				attacker.frags = attacker.frags + 1;

				rnum = attacker.weapon;
				if (rnum == IT_AXE)
				{
					deathstring = " was ax-murdered by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SHOTGUN)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}
				if (rnum == IT_SUPER_SHOTGUN)
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				if (rnum == IT_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was punctured by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				if (rnum == IT_ROCKET_LAUNCHER)
				{
					deathstring = " rides ";
					deathstring2 = "'s rocket\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s rocket\n" ;
					}
				}
				if (rnum == IT_LIGHTNING)
				{
					deathstring = " accepts ";
					if (attacker.waterlevel > 1)
						deathstring2 = "'s discharge\n";
					else
						deathstring2 = "'s shaft\n";
				}
				bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);
			}
			return;
		}
		else
		{
			targ.frags = targ.frags - 1;
			bprint (targ.netname);

			// custom obituary messages
			if (inflictor.deathtype != "")
			{
				bprint (" ");
				bprint (inflictor.deathtype);
				bprint ("\n");
				return;
			}
			if (attacker.deathtype != "")
			{
				bprint (" ");
				bprint (attacker.deathtype);
				bprint ("\n");
				return;
			}

			// killed by a montser?
			// if (attacker.flags & FL_MONSTER)
			if ((attacker.flags & FL_MONSTER) && (attacker.obit_name == ""))
			{
				if (attacker.classname == "monster_army")
					bprint (" was shot by a Grunt\n");
				if (attacker.classname == "monster_demon1")
					bprint (" was eviscerated by a Fiend\n");
				if (attacker.classname == "monster_dog")
					bprint (" was mauled by a Rottweiler\n");
				if (attacker.classname == "monster_dragon")
					bprint (" was fried by a Dragon\n");
				if (attacker.classname == "monster_enforcer")
					bprint (" was blasted by an Enforcer\n");
				if (attacker.classname == "monster_fish")
					bprint (" was fed to the Rotfish\n");
				if (attacker.classname == "monster_hell_knight")
					bprint (" was slain by a Death Knight\n");
				if (attacker.classname == "monster_knight")
					bprint (" was slashed by a Knight\n");
				if (attacker.classname == "monster_ogre")
					bprint (" was destroyed by an Ogre\n");
				if (attacker.classname == "monster_ogre_marksman")
					bprint (" was felled by a Marksman\n"); // dumptruck_ds
				if (attacker.classname == "monster_oldone")
					bprint (" became one with Shub-Niggurath\n");
				if (attacker.classname == "monster_oldone2")// dumptruck_ds
					bprint (" became one with Shub-Niggurath\n");
				if (attacker.classname == "monster_boss2")// dumptruck_ds
					bprint (" was exploded by Chthon\n");
				if (attacker.classname == "monster_boss")// dumptruck_ds
					bprint (" was exploded by Chthon\n");
				if (attacker.classname == "monster_shalrath")
					bprint (" was exploded by a Vore\n");
				if (attacker.classname == "monster_shambler")
					bprint (" was smashed by a Shambler\n");
				if (attacker.classname == "monster_tarbaby")
					bprint (" was slimed by a Spawn\n");
				if (attacker.classname == "monster_vomit")
					bprint (" was vomited on by a Vomitus\n");
				if (attacker.classname == "monster_wizard")
					bprint (" was scragged by a Scrag\n");
				if (attacker.classname == "monster_zombie")
					bprint (" joins the Zombies\n");

				return;
			}
			// obits for custom monsters -- progs_dump -- dumptruck_ds
			if (attacker.obit_name != "")
			{
				bprint (" was ");
				if !(attacker.obit_method)
				bprint ("killed");
				else
				bprint (attacker.obit_method); // e.g. ripped apart
				bprint (" by ");
				bprint (attacker.obit_name); // a bad monster
				bprint ("\n");
				return;
			}

			// tricks and traps
			if (attacker.classname == "explo_box" ||
					attacker.classname == "play_explosion" ||
					attacker.classname == "play_tbabyexplode")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.classname == "func_laser")
			{
				bprint (" discovered that lasers are hot\n");
				return;
			}
			if ((attacker.solid == SOLID_BSP &&
					attacker != world &&
					attacker.classname != "togglewall") ||
					(inflictor.classname == "func_movewall" &&
					!(inflictor.spawnflags & MOVEWALL_TOUCH)))
			{
				bprint (" was squished\n");
				return;
			}
			if (attacker.classname == "trap_shooter" ||
					attacker.classname == "trap_spikeshooter" ||
					attacker.classname == "trap_switched_shooter")
			{
				// bprint (" was spiked\n");
				bprint (" was unlucky\n"); //changed for custom shooters --dumptruck_ds
				return;
			}
			if (attacker.classname == "ltrail_start" ||
					attacker.classname == "ltrail_relay")
			{
				bprint (" had an electrifying experience\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}

			// in-liquid deaths
			if (targ.deathtype == "drowning")
			{
				if (random() < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			if (targ.deathtype == "slime")
			{
				if (random() < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			if (targ.deathtype == "lava")
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			// fell to their death?
			if (targ.deathtype == "falling")
			{
				bprint (" fell to his death\n");
				return;
			}

			// hell if I know; he's just dead!!!
			bprint (" died\n");
		}
	}
};
