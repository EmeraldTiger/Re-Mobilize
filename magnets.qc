// How do they work?

float LINEAR = 2;
float NO_MONSTERS = 4;

void() magnet_touch =
{
	if (self.estate != STATE_ACTIVE)
		return;
	
	if (!(CheckValidTouch() || !(other.flags & FL_MONSTER) || !(other.movetype == MOVETYPE_BOUNCE) || !(other.movetype == MOVETYPE_FLYMISSILE) || !(other.movetype == MOVETYPE_FLY) ))
		return;
		
	if (other.flags & FL_MONSTER && self.spawnflags & NO_MONSTERS)
	{
		return;
	}
	
	
	if (other.flags & FL_ITEM && self.spawnflags & /*No items*/ 8)
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
	
	if (other.movetype == MOVETYPE_FLYMISSILE || other.movetype == MOVETYPE_FLY)
	{
		vector oldvel = other.velocity;
		other.angles = vectoangles(other.velocity);
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
		other.flags &~= FL_ONGROUND;
		other.velocity += normalize(disp) * force;
	}

	if (other.movetype == MOVETYPE_FLYMISSILE || other.movetype == MOVETYPE_FLY)
	{
		other.velocity = normalize(other.velocity);
		other.velocity *= vlen(oldvel);
	}
	
	// Black holes, for example
	if ((self.killradius > 0) && !self.mangle && (vlen(other.origin - self.singularity) < self.killradius))
	{
		if (CanDamage(other, self))
		{
			T_Damage(other, self, self, 1000);
		}
		
		if (other.classname != "player")
		{
			remove(other);
		}
	}
}

void() magnet_use =
{
	if (self.estate == STATE_INACTIVE)
		self.estate = STATE_ACTIVE;
	else
		self.estate = STATE_INACTIVE;
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
	
	// If there's no target, then there's no reference point for the magnet's force
	// Even planar magnets need a target to define the location of the plane
	if (!self.target)
	{
		objerror("trigger_magnet has no target");
	}
	
	self.touch = magnet_touch;
	
	if (self.spawnflags & START_OFF)
		self.estate = STATE_INACTIVE;
	else
		self.estate = STATE_ACTIVE;
	
	self.use = magnet_use;
	self.nextthink = time + 0.01;
	self.think = magnet_think;

}