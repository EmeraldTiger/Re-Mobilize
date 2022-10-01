/*
===============================================================================
trigger_trampoline
===============================================================================
*/

/*QUAKED trigger_trampoline (.5 .5 .5) ? X X X X X X X X NOT_ON_EASY NOT_ON_NORMAL NOT_ON_HARD_OR_NIGHTMARE NOT_IN_DEATHMATCH NOT_IN_COOP NOT_IN_SINGLEPLAYER X NOT_ON_HARD_ONLY NOT_ON_NIGHTMARE_ONLY
Invisible trampoline entity. Reflects the player's velocity when touched.

Keys:

*/

void() trampoline_touch =
{
	// Enforce a minimum velocity the player must fall so they won't just bounce endlessly
	float minSpeed = -200;

	// from Copper -- dumptruck_ds
	if (!((other.flags & FL_MONSTER) || (other.classname=="grenade") 
	|| (other.classname=="MultiGrenade")
	|| (other.classname=="MiniGrenade")
	|| (CheckValidTouch()))) return;
	
        vector surfNorm = trace_plane_normal;
	
	vector up = '0 0 1';
	
	other.cushion=1;
	
	other.cushionnoise = self.noise2;
	
	other.cushionsounds = self.sounds;
	
	if (other.button2 || other.flags & FL_MONSTER 
	|| (other.classname=="grenade")
	|| (other.classname=="MultiGrenade")
	|| (other.classname=="MiniGrenade") ) {
	
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
	if (!self.elasticity)
		self.elasticity = 1;
	if (!self.sounds)
		self.sounds = 0;
	if (!self.maxbounce)
		self.maxbounce = 0;
};