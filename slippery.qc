void() slippery_touch =
{
	
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	if (!(other.flags & FL_ONGROUND)) return;
	
	other.onSlippery = 1;
	other.slicksounds = self.slicksounds;
	
	if (self.noise != "") {
		other.slicknoise = self.noise;
	}
	else {
		other.slicknoise = "";
	}
	
	if (self.noise2 != "") {
		other.slicknoise2 = self.noise2;
	}
	else {
		other.slicknoise2 = "";
	}
	
	if (self.noise3 != "") {
		other.slicknoise3 = self.noise3;
	}
	else {
		other.slicknoise3 = "";
	}
	
	if (self.noise4 != "") {
		other.slicknoise4 = self.noise4;
	}
	else {
		other.slicknoise4 = "";
	}
	
	// How much "dampening" is applied to the increase in velocity over time
	// 17 (the default) is the lowest value in which the player cannot achieve max speed simply by going in a straight line
	float slipconstant = self.wait;
	
	// Maximum speed the player can attain
	float maxspeed = self.speed;
	
	vector dir = normalize(other.velocity);
	float speed = vlen(other.velocity);

	if (vlen(other.velocity) > maxspeed)
	{
		other.velocity -= dir * slipconstant;
	}
	else
	{
		other.velocity += dir * speed / slipconstant;
	}
	

};

void() trigger_slippery =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if (!self.speed)
	{
		self.speed = 1200;
	}
	
	if (!self.wait)
	{
		self.wait = 17;
	}
	
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
	
	
	self.slicksounds = self.sounds;
	self.slicknoise = self.noise;
	
	self.touch = slippery_touch;
};