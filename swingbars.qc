void() swingbar_touch =
{
	
	if (!CheckValidTouch()) return;
	
	if (other.flags & FL_ONGROUND) return;
	
	if (other.swinging) return;
	
	if (other.currentbar == self.owner) return;
	
	other.swinging = 1;
	other.alignment = 0;
	other.primed = 0;
	other.flags &~= FL_ONGROUND;
	other.think = BarCooldown;
	other.nextthink = time + 0.1;
	other.jumpdelay = 1;
	other.currentbar = self.owner;
	local vector bar_bounds = 0.5*(self.maxs - self.mins);
	other.bar_origin = self.mins + bar_bounds;
	other.bar_angles = self.owner.mangle;
};

void() func_swingbar =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
		
	if (!self.speed)
	{
		self.speed = 5;
	}
	
	if (!self.spread)
	{
		self.spread = 55;
	}
	
	if (!self.height)
	{
		self.height = 2;
	}
	
	if (!self.impulse)
	{
		self.impulse = 150;
	}
	
	if (!self.style)
	{	
		self.style = 0;
	}


	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setorigin (self, self.origin);
	setmodel (self, self.model);
	local entity trigger;
	local vector t1, t2;
	
	trigger = spawn();
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = swingbar_touch;
	
	t1 = self.mins;
	t2 = self.maxs;
	
	setsize(trigger, self.mins - '30 30 30', self.maxs + '30 30 30');
};