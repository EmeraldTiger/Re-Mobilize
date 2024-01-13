// How do they work?
// EXPERIMENTAL

float LINEAR = 1;

void() magnet_touch =
{
	if (!(CheckValidTouch() || !(other.flags & FL_MONSTER) || !(other.movetype == MOVETYPE_BOUNCE) || !(other.movetype == MOVETYPE_FLYMISSILE) || !(other.movetype == MOVETYPE_FLY) ))
		return;
		
	local vector disp;
	local float dist, inv_dist_squared, force;
	
	disp = other.origin - self.singularity;
	
	if (self.mangle) {
		makevectors(self.mangle);
		// Create an invisible plane that the mangle is normal to.
		// Instead of using distance from the point entity in 3D space, use distance from the plane.
		disp[0] *= v_forward[0];
		disp[1] *= v_forward[1];
		disp[2] *= v_forward[2];
	}
	dist = vlen(disp);
	// Can add a constant (with the wait key) to remove singularities.
	// Should be used for attractors, as well as planar magnets since the force is at full strength across the plane.
	if (self.spawnflags & LINEAR)
	{
		inv_dist_squared = 1 / ((dist) + (self.wait * self.wait));
	}
	else
	{
		inv_dist_squared = 1 / ((dist * dist) + (self.wait * self.wait));
	}
	force = self.impulse * self.impulse;
	
	force *= inv_dist_squared;
	
	// squaring removes the negative, so give it back if we gave a negative impulse
	if (self.impulse < 0) 
	{
		force *= -1;
	}
	

	if (self.mangle) 
	{
		makevectors(self.mangle);
		other.velocity += normalize(v_forward) * force;
	}
	else
	{
		other.velocity += normalize(disp) * force;
	}
	
	if (other.flags & FL_MONSTER)
	{
		other.velocity += normalize(disp) * force * 500;
	}

	if (other.movetype == MOVETYPE_FLYMISSILE || other.movetype == MOVETYPE_FLY || other.movetype == MOVETYPE_TOSS)
	{
		other.angles = vectoangles(other.velocity);
	}
}

void() magnet_think =
{
	local entity m;
	
	m = find(world, targetname, self.target);
	
	self.singularity = m.origin;
}

void() trigger_magnet =
{
	
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;
		
	InitTrigger();
	
	if (!self.impulse)
	{
		self.impulse = 500;
	}
	
	if (!self.wait)
	{
		self.wait = 0;
	}
	
	// If there's no target or angle, then there's no reference point for the magnet's force
	if (!self.target && !self.mangle)
	{
		objerror("trigger_magnet has neither a target nor mangle");
	}
	
	self.touch = magnet_touch;
	
	self.nextthink = time + 0.01;
	self.think = magnet_think;

}