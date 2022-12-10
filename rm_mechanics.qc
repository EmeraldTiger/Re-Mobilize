/*
===============================================================================
trigger_trampoline
===============================================================================
*/

/*QUAKED trigger_trampoline (.5 .5 .5) ? X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
Invisible trampoline entity. Reflects the player's velocity when touched.

Keys:

"elasticity" How much velocity is boosted after a bounce (ignoring gravity); default of 1 is perfectly elastic, values less than 1 will result in lower bounces, and values higher than 1 will provide 
a higher boost that is not physically possible. Small changes in elasticity greatly affect velocity; values between 0.9 and 1.1 are recommended, and the default of 1 should be used in almost all cases

"maxbounce" The maximum vertical velocity that a player can achieve using the trampoline. Use of this is highly recommended if elasticity > 1, as otherwise the player will continue to gain upwards 
speed indefinitely. Default of 0 means no limit.

*/

void() trampoline_touch =
{
	// Enforce a minimum velocity the player must fall so they won't just bounce endlessly
	float minSpeed = -fabs(self.speed);

	// from Copper -- dumptruck_ds
	if (!((other.flags & FL_MONSTER || (other.movetype == MOVETYPE_BOUNCE && other.solid == SOLID_BBOX))	
	|| (CheckValidTouch()))) return;
	
    vector surfNorm = trace_plane_normal;
	vector up = '0 0 1';
	
	// Player doesn't take any fall damage when landing on a trampoline
	other.cushion = self;
	
	other.cushionnoise = self.noise2;
	
	other.cushionsounds = self.sounds;
	
	if(self.speed == -1) return; //Cushion only (no bounce)
	
	if (other.button2 || other.flags & FL_MONSTER || (other.movetype == MOVETYPE_BOUNCE && other.solid == SOLID_BBOX)) {
	
		if (other.velocity[2] < minSpeed) {
			vector playervel = other.velocity;
			// reflection equation
			playervel = playervel - 2 * playervel * up * up * (self.elasticity);
			
			// if maxbounce is set, cap vertical movement speed at maxbounce
			if (self.maxbounce > 0 && playervel[2] > self.maxbounce)
				playervel[2] = self.maxbounce;
			
			other.velocity = playervel;
			if (self.noise != "")
				sound (self, CHAN_AUTO, self.noise, 1, ATTN_NORM);
			else if (self.sounds == 1)
				sound (self, CHAN_AUTO, "misc/bounce2.wav", 1, ATTN_NORM);
			else if (self.sounds == 2)
				sound (self, CHAN_AUTO, "misc/bounce3.wav", 1, ATTN_NORM);
			else if (self.sounds == 3)
				sound (self, CHAN_AUTO, "misc/bounce4.wav", 1, ATTN_NORM);
			else if (self.sounds == 4)
				sound (self, CHAN_AUTO, "misc/bounce5.wav", 1, ATTN_NORM);
			else if (self.sounds == 5)
				sound (self, CHAN_AUTO, "misc/bounce6.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_AUTO, "misc/bounce1.wav", 1, ATTN_NORM);
				
			//Fire trampoline targets on bounce
			entity bouncee = other;
			float ostate = bouncee.state;
			bouncee.maxbounce++;
			bouncee.state = ostate | STATE_RM_BOUNCING;
			activator = other;
			SUB_UseTargets();
			bouncee.state = ostate;
		}
	}
	
}

void() trigger_trampoline =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	precache_sound ("misc/bounce1.wav");
	precache_sound ("misc/bounce2.wav");
	precache_sound ("misc/bounce3.wav");
	precache_sound ("misc/bounce4.wav");
	precache_sound ("misc/bounce5.wav");
	precache_sound ("misc/bounce6.wav");
	
	if (self.noise != "")
		precache_sound(self.noise);
		
	if (self.noise2 != "")
		precache_sound(self.noise2);
		
	self.touch = trampoline_touch;
	if (!self.speed)
		self.speed = 200;
	if (!self.elasticity)
		self.elasticity = 1;
	if (!self.sounds)
		self.sounds = 0;
	if (!self.maxbounce)
		self.maxbounce = 0;
};

/*
===============================================================================
trigger_wiremesh
===============================================================================
*/

/*QUAKED trigger_wiremesh (.5 .5 .5) ? X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
invisible wiremesh entity. Very similar functionally to a ladder, but can be climbed "sideways" and "upside down" as if hanging from the ceiling, making it more versatile.

Keys:

"speed" the speed at which the player can travel across the mesh
*/

void() wiremesh_touch =
{
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	other.onWiremesh = 1;
	other.wiremesh = self;
	
	//Fire wiremesh targets on climbing mode change
	if(!(other.state & STATE_RM_CLIMBING) && !(other.flags & FL_ONGROUND))
	{
		other.state |= STATE_RM_CLIMBING;
		activator = other;
		SUB_UseTargets();
	}
	
	other.meshspeed = self.speed;
	other.meshsounds = self.sounds;
	
	if (self.noise != "") {
		other.meshnoise = self.noise;
	}
	else {
		other.meshnoise = "";
	}
	
	if (self.noise2 != "") {
		other.meshnoise2 = self.noise2;
	}
	else {
		other.meshnoise2 = "";
	}
	
	if (self.noise3 != "") {
		other.meshnoise3 = self.noise3;
	}
	else {
		other.meshnoise3 = "";
	}
	
	if (self.noise4 != "") {
		other.meshnoise4 = self.noise4;
	}
	else {
		other.meshnoise4 = "";
	}
}

void() trigger_wiremesh =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if (self.noise != "") {
		precache_sound(self.noise);
	}
	
	if (self.noise2 != "") {
		precache_sound(self.noise2);
	}
	
	if (self.noise3 != "") {
		precache_sound(self.noise3);
	}
	
	if (self.noise4 != "") {
		precache_sound(self.noise4);
	}
	
	self.touch = wiremesh_touch;
	if (!self.speed)
		self.speed = 300;
	if (!self.sounds)
		self.sounds = 0;
};

/*
===============================================================================
func_hook
===============================================================================
*/

/*QUAKED func_hook (.5 .5 .5) ? X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
A lightpanel surface that the player can latch onto via the lighthook. Hooking is instantaneous, but pull speed is still finite.

Keys:

"speed" Speed at which the lighthook pulls the player (not the hook itself, which is infinitely fast); default 500.

"targetname" By default, lightpanels are enabled and ready-to-use on map startup. If a targetname is specified, the lightpanel will be disabled on map start, and must be activated by an external trigger.

"style" Determines the color of the lighthook beam. Default is 0.

0. Yellow (default)
1. Blue
2. Orange

*/

void() func_hook_use = {
	// change to alternate textures
	self.frame = 1 - self.frame;
	if (self.estate == STATE_INACTIVE) {
		self.estate = STATE_ACTIVE;
		if (self.noise4 != "")
		{
			sound (self, CHAN_ITEM, self.noise4, 1, ATTN_NORM);
		}
		else {
			sound (self, CHAN_ITEM, "misc/laser_on.wav", 1, ATTN_NORM);
		}
		activator.disable_event = 0;
		
	}
	else {
		self.estate = STATE_INACTIVE;
		if (self.noise5 != "")
		{
			sound (self, CHAN_ITEM, self.noise5, 1, ATTN_NORM);
		}
		else {
			sound (self, CHAN_ITEM, "misc/laseroff.wav", 1, ATTN_NORM);
		}
		activator.disable_event = 1;
	}
};

void() func_hook =
{
	
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
		
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	if (self.targetname) {
		self.estate = STATE_INACTIVE;
		self.frame = 0;
	}
	else {
		self.estate = STATE_ACTIVE;
		self.frame = 1;
	}
	
	// Dummy spawn for nonsolid hookpanels
	if (self.volume) {
		dummy = spawn();
		dummy.solid = SOLID_NOT;
	}
	
	// medieval sounds
	if (self.sounds == 1) 
	{
		precache_sound("grapple/mhookactive.wav");
		precache_sound("grapple/mhookattach.wav");
		precache_sound("grapple/mhookdetach.wav");
	}
	
	// enable noise
	if (self.noise4 != "") {
		precache_sound(self.noise4);
	}
		
	// disable noise
	if (self.noise5 != "") {
		precache_sound(self.noise5);
	}
	
	precache_sound ("misc/laser_on.wav");
	precache_sound ("misc/laseroff.wav");
	self.use = func_hook_use;
	
	if (!self.speed) {
		self.speed = 500;
	}
	
	if (!self.style) {
		self.style = 0;
	}
	
	// attach noise
	if (self.noise != "") {
		precache_sound(self.noise);
	}
	
	// detach noise
	if (self.noise2 != "") {
		precache_sound(self.noise2);
	}
	
	// active noise
	if (self.noise3 != "") {
		precache_sound(self.noise3);
	}
		
	setmodel (self, self.model);
	self.classname = "func_hook";
	
};