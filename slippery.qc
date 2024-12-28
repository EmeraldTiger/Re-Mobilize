void() slippery_touch =
{
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	// will be modifiable later, good default values for now
	float slipconstant = 17;
	float maxspeed = 800;

	if (vlen(other.velocity) > maxspeed)
	{
		other.velocity[0] -= other.velocity[0] / slipconstant;
		other.velocity[1] -= other.velocity[1] / slipconstant;
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
	
	self.touch = slippery_touch;
};