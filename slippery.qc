void() slippery_touch =
{
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	// How much "dampening" is applied to the increase in velocity over time
	// 17 (the default) is the lowest value in which the player cannot achieve max speed simply by going in a straight line
	float slipconstant = self.wait;
	
	// Maximum speed the player can attain
	float maxspeed = self.speed;

	if (vlen(other.velocity) > maxspeed)
	{
		other.velocity[0] -= slipconstant;
		other.velocity[1] -= slipconstant;
	}
	else
	{
		other.velocity[0] += other.velocity[0] / slipconstant;
		other.velocity[1] += other.velocity[1] / slipconstant;
	}

};

void() trigger_slippery =
{
	if (SUB_Inhibit ())  // new spawnflags for all entities -- iw
		return;

	InitTrigger ();
	
	if (!self.speed)
	{
		self.speed = 800;
	}
	
	if (!self.wait)
	{
		self.wait = 17;
	}
	
	self.touch = slippery_touch;
};