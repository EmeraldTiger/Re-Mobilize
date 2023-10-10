// How do they work?
// EXPERIMENTAL

float LINEAR = 1;
float PLANAR = 2;

void() magnet_touch =
{
	if (!(CheckValidTouch() || (other.flags & FL_MONSTER) || (other.movetype == MOVETYPE_BOUNCE) || (other.movetype == MOVETYPE_FLYMISSILE) ))
		return;
		
	local vector disp;
	local vector center;
	local float dist, inv_dist_squared, force;
	
	center = (self.mins + self.maxs) * 0.5;
	
	disp = other.origin - center;
	if (self.owner.mangle && self.owner.spawnflags & PLANAR) {
		makevectors(self.owner.mangle);
		// Create an invisible plane that the mangle is normal to.
		// Instead of using distance from the point entity in 3D space, use distance from the plane.
		disp[0] *= v_forward[0];
		disp[1] *= v_forward[1];
		disp[2] *= v_forward[2];
	}
	dist = vlen(disp);
	// Can add a constant (with the wait key) to remove singularities.
	// Should be used for attractors, as well as planar magnets since the force is at full strength across the plane.
	if (self.owner.spawnflags & LINEAR)
	{
		inv_dist_squared = 1 / ((dist) + (self.owner.wait * self.owner.wait));
	}
	else
	{
		inv_dist_squared = 1 / ((dist * dist) + (self.owner.wait * self.owner.wait));
	}
	force = self.owner.impulse * self.owner.impulse;
	
	force *= inv_dist_squared;
	
	// squaring removes the negative, so give it back if we gave a negative impulse
	if (self.owner.impulse < 0) 
	{
		force *= -1;
	}
	

	if (self.owner.mangle) 
	{
		makevectors(self.owner.mangle);
		other.velocity += normalize(v_forward) * force;
	}
	else
	{
		other.velocity += normalize(disp) * force;
	}

	if (other.movetype == MOVETYPE_FLYMISSILE)
	{
		other.angles = vectoangles(other.velocity);
	}
}

entity(vector fmins, vector fmaxs) magnet_field =
{
	local entity	trigger;

	trigger = spawn();
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = magnet_touch;

	setsize (trigger, fmins, fmaxs);
	
	return (trigger);
};

void() misc_magnet =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
	
	if (!self.volume)
	{
		self.volume = 128;
	}
	
	self.volume /= 2;
	
	if (!self.impulse)
	{
		self.impulse = 500;
	}
	
	if (!self.wait)
	{
		self.wait = 50;
	}
	
	self.mins += self.origin;
	self.maxs += self.origin;
	
	self.mins[0] -= self.volume;
	self.mins[1] -= self.volume;
	self.mins[2] -= self.volume;
	
	self.maxs[0] += self.volume;
	self.maxs[1] += self.volume;
	self.maxs[2] += self.volume;
	
	self.origin = ((self.absmin + self.absmax) * 0.5);
	
	self.trigger_field = magnet_field(self.mins, self.maxs);
}