// Re:Mobilize Lighthook code
// Adapted from Rogue's grapple code from Dissolution of Eternity

// New entity fields
.entity hook; // this is my hook
.float on_hook; // we're on it
.float hook_out; // it's out

.entity currenthook;

// prototypes for WEAPONS.QC functions
float() crandom;
void(vector org, vector vel, float damage) SpawnBlood;

void() ChainReset =
{
	remove(self);
}

void(entity h, entity player) GrappleTrail =
{
	
	// draw a line to the hook
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	
	
	if (player.hookstyle==1) {
		WriteByte (MSG_BROADCAST, TE_LIGHTNING3);
	}
	else if (player.hookstyle==2){
		WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	}
	else {
		WriteByte (MSG_BROADCAST, TE_BEAM);
	}
	
	
	
	WriteEntity (MSG_BROADCAST, h);
	WriteCoord (MSG_BROADCAST, h.origin_x);
	WriteCoord (MSG_BROADCAST, h.origin_y);
	WriteCoord (MSG_BROADCAST, h.origin_z);
	WriteCoord (MSG_BROADCAST, player.origin_x);
	WriteCoord (MSG_BROADCAST, player.origin_y);
	WriteCoord (MSG_BROADCAST, player.origin_z + 16);
	
};

void() GrappleReset =
{

	if (self.enemy) {
		self.enemy.anchored = 0;
		if (self.enemy.nexthook) {
			self.enemy.nexthook.prepared = 0;
		}
		if (self.enemy.locked_on) {
			self.enemy.locked_on = 0;
		}
	}
	self.owner.on_hook = FALSE;
	self.owner.hook_out = FALSE;
	self.owner.weaponframe = 0;
	self.owner.attack_finished = time +0.25;
	
	if (self.owner.hooknoise2 != "") {
		sound (self, CHAN_WEAPON, self.owner.hooknoise2, 1, ATTN_NORM);
	}
	else {
		if (self.owner.hooksounds == 1) {
			sound (self, CHAN_WEAPON, "grapple/mhookdetach.wav", 1, ATTN_NORM);
			}
			else {
			sound (self, CHAN_WEAPON, "grapple/grdetach1.wav", 1, ATTN_NORM);
			}
	}
	
	remove(self);
};

void() GrappleTrack =
{
	local   vector  spray;

	// Release dead targets
	if (self.enemy.classname == "player" && self.enemy.health <= 0)
		self.owner.on_hook = FALSE;

	// drop the hook if owner is dead or has released the button
	if (!self.owner.on_hook || self.owner.health <= 0) {
		GrappleReset();
		return;
	}

	if (self.enemy.classname == "player")
	{
		if (self.enemy.teleport_time > time)
		{
			GrappleReset();
			return;
		}
		
		// move the hook along with the player.  It's invisible, but
		// we need this to make the sound come from the right spot
		setorigin(self, self.enemy.origin);
		
//		sound (self, CHAN_WEAPON, "blob/land1.wav", 1, ATTN_NORM);
		sound (self, CHAN_WEAPON, "pendulum/hit.wav", 1, ATTN_NORM);
		T_Damage (self.enemy, self, self.owner, 1);
		makevectors (self.v_angle);
		spray_x = 100 * crandom();
		spray_y = 100 * crandom();
		spray_z = 100 * crandom() + 50;
		SpawnBlood(self.origin, spray, 20);
	}
	if (self.enemy.solid == SOLID_SLIDEBOX) {
		self.velocity = '0 0 0';
		setorigin(self, self.enemy.origin + self.enemy.mins +
			self.enemy.size * 0.5);
	} else
		self.velocity = self.enemy.velocity;

	self.nextthink = time + 0.1;
};

// Tries to anchor the grapple to whatever it touches
void () GrappleAnchor =
{
	if (other == self.owner) // don't hook the guy that fired it
	{
		return;
	}

	if (pointcontents(self.origin) == CONTENT_SKY) {
		GrappleReset();
		return;
	}
	
	if (other.flags & FL_MONSTER) {
		return;
	}
	
	if (other.classname != "func_hook" || !other.hookable ) {
			if (self.currenthook) {
				self.locked_on = 0;
			}
			GrappleReset();
			return;
	}
	
	if (other.classname == "player") 
	{
		if (self.owner.hooknoise1 != "") {
			sound (self, CHAN_WEAPON, self.owner.hooknoise1, 1, ATTN_NORM);
		}
		else {
			if (self.owner.hooksounds == 1) {
			sound (self, CHAN_WEAPON, "grapple/mhookattach.wav", 1, ATTN_NORM);
			}
			else {
			sound (self, CHAN_WEAPON, "grapple/grhit2.wav", 1, ATTN_NORM);
			}
		}
		T_Damage (other, self, self.owner, 10);
	} else {
		if (self.owner.hooknoise1 != "") {
			sound (self, CHAN_WEAPON, self.owner.hooknoise1, 1, ATTN_NORM);
		}
		else {
			if (self.owner.hooksounds == 1) {
			sound (self, CHAN_WEAPON, "grapple/mhookattach.wav", 1, ATTN_NORM);
			}
			else {
			sound (self, CHAN_WEAPON, "grapple/grhit2.wav", 1, ATTN_NORM);
			}
		}

		// One point of damage inflicted upon impact. Subsequent
		// damage will only be done to PLAYERS... this way secret
		// doors and triggers will only be damaged once.
		if (other.takedamage)
			T_Damage (other, self, self.owner, 1);

		self.velocity = '0 0 0';
		self.avelocity = '0 0 0';
	}
	
	// user currently is hooked to something
	other.anchored = 1;

	self.frame = 2; // anchored
	
	if (self.owner.hooknoise1 != "") {
		sound (self.owner, CHAN_WEAPON, self.owner.hooknoise1, 1, ATTN_NORM);
	}
	else {
		if (self.owner.hooksounds == 1) {
			sound (self, CHAN_WEAPON, "grapple/mhookattach.wav", 1, ATTN_NORM);
			}
			else {
			sound (self, CHAN_WEAPON, "grapple/grhit2.wav", 1, ATTN_NORM);
			}
	}

	self.owner.on_hook = TRUE;
	if (self.owner.flags & FL_ONGROUND)
		self.owner.flags = self.owner.flags - FL_ONGROUND;

	// CHAIN2 is a looping sample. Use LEFTY as a flag so that client.qc
	// will know to only play the tink sound ONCE to clear the weapons
	// sound channel. (Lefty is a leftover from AI.QC, so I reused it to
	// avoid adding a field)
	self.owner.lefty = TRUE;

	self.enemy = other;// remember this guy!
	self.think = GrappleTrack;
	self.nextthink = time;
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
};

void () W_FireGrapple =
{
	if (self.hook_out) {// reject subsequent calls from player.qc
		return;
	}
		
	local vector player_offset;
	player_offset = self.origin + self.view_ofs;

	makevectors(self.v_angle);

	traceline(player_offset, (player_offset + (v_forward * 100000)), FALSE, self);
		
	//traceline(self.origin, (self.origin + (v_forward * 100000)), FALSE, self);
	
	if (!(trace_ent.classname=="func_hook") || !trace_ent.hookable) {
		return;
	}
	
	self.pullspeed = trace_ent.speed;
	self.hookstyle = trace_ent.style;
	
	if (trace_ent.sounds) {
		self.hooksounds = trace_ent.sounds;
	}
	else {
		self.hooksounds = 0;
	}
	
	if (trace_ent.noise) {
		self.hooknoise1 = trace_ent.noise;
	}
	else {
		self.hooknoise1 = "";
	}
	
	if (trace_ent.noise2) {
		self.hooknoise2 = trace_ent.noise2;
	}
	else {
		self.hooknoise2 = "";
	}
	
	if (trace_ent.noise3) {
		self.hooknoise3 = trace_ent.noise3;
	}
	else {
		self.hooknoise3 = "";
	}
	
	trace_ent.locked_on = 1;
	self.currenthook = trace_ent;
	self.hookpoint = trace_endpos;
	
	//string targethook = trace_ent.target;

	self.punchangle_x = -2; // bump him
	
	self.launchtime = time + 1;

	// chain out sound (loops)
	//sound (self, CHAN_WEAPON, "weapons/chain1.wav", 1, ATTN_NORM);

	newmis = spawn();
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.owner = self;		// newmis belongs to me
	self.hook = newmis;			// This is my newmis
	newmis.classname = "hook";
	

	makevectors (self.v_angle);
	newmis.velocity = trace_plane_normal * -5;
	setorigin (newmis, trace_endpos);
	newmis.angles = vectoangles(v_forward);

	newmis.touch = GrappleAnchor;
	newmis.think = GrappleReset;
	// grapple only lives for two seconds, this gives max range on it
	newmis.nextthink = time + 2;
	newmis.frame = 1; // hook spread

	//setmodel (newmis,"progs/hook.mdl");
	//setorigin (newmis, self.origin + v_forward * 16 + '0 0 16');
	setsize(newmis, '0 0 0' , '0 0 0 ');

	self.hook_out = TRUE;
};

// called each frame by CLIENT.QC if client has hook_out
void() GrappleService =
{
	local   vector  o, dist, vel;
	local	float	v;

	if (!self.on_hook) {
		// just draw a line to the hook
		if (vlen(self.hook.origin - self.origin) > 50)
			GrappleTrail(self.hook, self);
		return;
	}

	// drop the hook if player lets go of button
	if (
									self.teleport_time > time) 
	{ // release when we get 'ported
		self = self.hook;
		GrappleReset();
		return;
	}
	
	if (time > self.hook_finished) {
			if (self.hooknoise3 != "") {
				sound (self, CHAN_WEAPON, self.hooknoise3, 1, ATTN_NORM);
			}
			else {
				if (self.hooksounds == 1) {
				sound (self, CHAN_WEAPON, "grapple/mhookactive.wav", 1, ATTN_NORM);
				}
				else {
				sound (self, CHAN_WEAPON, "grapple/gractive.wav", 1, ATTN_NORM);
				}
			}
			self.hook_finished = time + 0.55;
	}
	
	if (self.disable_event) {
		self.disable_event = 0;
		self = self.hook;
		GrappleReset();
	}
	
	traceline(self.origin, self.hook.origin, FALSE, self.owner);
	
	dprint(trace_ent.classname);
	
	// check for this in case the lighthook is severed by a moving brush
	if (trace_ent.classname != "worldspawn")
	{
		self = self.hook;
		GrappleReset();
	}

	if (self.impulse==25)
	{
		self = self.hook;
		
		GrappleReset();	
	
		
		return;
	}
	
	makevectors (self.angles);
	dist = self.hook.origin - self.origin;
	vel = self.hook.origin - ( self.origin + (v_forward * 16));

	v = vlen (vel);

	if (v <= 100)
		vel = normalize(vel) * v * 10;  
	else
		vel = normalize(vel) * self.pullspeed;
		//vel = normalize(vel) * 1000;

	self.velocity = vel;

	if ( vlen(dist) <= 50) {
		if (self.lefty) { // cancel chain sound
			// If there is a chain, ditch it now. We're
			// close enough. Having extra entities lying around
			// is never a good idea.
//			if (self.hook.goalentity) { 
//					self.hook.goalentity.think = GrappleRemoveChain;
//					self.hook.goalentity.nextthink = time;
//			}

			self.lefty = FALSE;// we've reset the sound channel.
		}
	} else
		GrappleTrail(self.hook, self);
};