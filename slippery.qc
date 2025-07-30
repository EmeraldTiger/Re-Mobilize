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
	
	vector dir = normalize(other.velocity);
	float speed = vlen(other.velocity);

	other.velocity += dir * speed / 17;
	
	/*
	vector down = '0 0 -50';
	vector slope_check = other.origin + down;
	
	traceline(other.origin, slope_check, 0, 0);
	
	float dot = trace_plane_normal * (down/-50);
	*/

};

void() trigger_slippery =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if (!self.speed)
	{
		self.speed = 2;
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