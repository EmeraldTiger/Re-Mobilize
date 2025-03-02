void() slippery_touch =
{
	
	// from Copper -- dumptruck_ds
	if (!CheckValidTouch()) return;
	
	if (!(other.flags & FL_ONGROUND)) return;
	
	other.onSlippery = 1;
	
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
	
	self.touch = slippery_touch;
};