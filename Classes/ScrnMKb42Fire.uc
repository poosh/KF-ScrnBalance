class ScrnMKb42Fire extends MKb42Fire;

//close bolt if attempted to fire when empty
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).MagAmmoRemaining == 0 && !KFWeapon(Weapon).bIsReloading )
	{
    	if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnMKb42AssaultRifle(Weapon).MoveBoltForward(); //close bolt on empty chamber
	}
	return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMKb42AssaultRifle'
}
