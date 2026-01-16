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

void() snow0 =
{
	vector vel;
	vel_x = self.angles_x*random();
	vel_y = self.angles_y*random();
	vel_z = -1*self.speed;

	if(self.skin == /*Rain*/ 1)
		te_particlerain(self.mins, self.maxs, vel, self.count, self.color);
	else /*Snow*/
		te_particlesnow(self.mins, self.maxs, vel, self.count, self.color);
};

void() snow1 =
{
	vector pos;
	
	vector vel;
	vel_x = self.angles_x*random();
	vel_y = self.angles_y*random();
	vel_z = -1*self.speed;

	for (float i = 0; i < self.count; i++)
	{
		pos_x = self.mins_x + (fabs(self.maxs_x-self.mins_x))*random();
		pos_y = self.mins_y + (fabs(self.maxs_y-self.mins_y))*random();
		pos_z = self.mins_z + (fabs(self.maxs_z-self.mins_z))*random();
		
		particle(pos, vel, self.color, 1);
	}
};

void() weather_think =
{
	if (self.estate != STATE_ACTIVE)
	{
		self.nextthink = -1;
		return;
	}
	
	if(self.style == 1) snow1(); else snow0();
	
	self.nextthink = time + self.delay;
};

void() func_weather =
{
	//style 0: using te_particle builtin functions (extended engines only: FTE, DP, QSS...)
	//style 1: using custom QuakeC implementation above based on the particle() builtin function
	
	self.style = 0;
	if (self.spawnflags & /*QC*/ 1)
		self.style = 1;
	else if (!cvar("pr_checkextension"))
		self.style = 1;
	else if(self.skin == /*Rain*/ 1 && !checkextension("DP_TE_PARTICLERAIN"))
		self.style = 1;
	else if(!checkextension("DP_TE_PARTICLESNOW"))
		self.style = 1; /* using a housemade workaround */

	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if(!self.delay) self.delay = 0.05;
	if(!self.count) self.count = 50;
	if(!self.color) self.color = 13;
	if(!self.speed) self.speed = 2;
	if(!self.angles) self.angles = '0 0 0';
	
	SUB_CheckWaiting();
	
	self.think = weather_think;
	
	if(self.estate == STATE_ACTIVE)
		self.nextthink = time + self.delay;
	else
		self.use = weather_think;
};