class ScrnAA12Fire extends AA12Fire;

//close bolt if attempted to fire when empty
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).MagAmmoRemaining == 0 && !KFWeapon(Weapon).bIsReloading )
	{
    	if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnAA12AutoShotgun(Weapon).bBoltClosed = true; //set flag
	}
	return Super.AllowFire();
}

defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnAA12Bullet'
     Spread=1125.000000
}
