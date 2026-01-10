void() slippery_touch =
{
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	if (!(other.flags & FL_ONGROUND)) return;
	
	other.onSlippery = 1;
	other.slicksounds = self.sounds;
	other.slicknoise  = self.noise;
	other.slicknoise2 = self.noise2;
	other.slicknoise3 = self.noise3;
	other.slicknoise4 = self.noise4;
	
	vector dir = normalize(other.velocity);
	float vel = vlen(other.velocity);
	
	other.velocity += (dir * vel * self.speed) / 17 * (frametime*72);
	dprint2(ftos(frametime*72), "\n");
};

void() trigger_slippery =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if (!self.speed)
		self.speed = 1;
	
	if (self.sounds==/*Custom*/2)
	{
		if (self.noise=="")
			self.sounds=/*Oil*/0;
		else
		{
			if (self.noise2=="") self.noise2=self.noise;
			if (self.noise3=="") self.noise3=self.noise;
			if (self.noise4=="") self.noise4=self.noise2;
		}
	}
	if (self.sounds==/*Ice*/1)
	{
		self.noise  = "slippery/ice1.wav";
		self.noise2 = "slippery/ice2.wav";
		self.noise3 = "slippery/ice3.wav";
		self.noise4 = "slippery/ice4.wav";
	}
	else /*Oil*/
	{
		self.noise  = "slippery/oil1.wav";
		self.noise2 = "slippery/oil2.wav";
		self.noise3 = "slippery/oil3.wav";
		self.noise4 = "slippery/oil4.wav";
	}

	precache_sound(self.noise);
	precache_sound(self.noise2);
	precache_sound(self.noise3);
	precache_sound(self.noise4);
	
	self.touch = slippery_touch;
	
	SUB_CheckWaiting();
};