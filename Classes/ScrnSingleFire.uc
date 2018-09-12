class ScrnSingleFire extends SingleFire;

//lock slide back if fired last round
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).MagAmmoRemaining <= 1 && !KFWeapon(Weapon).bIsReloading )
	{
    	if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnSingle(Weapon).LockSlideBack(); //lock slide back
	}
	return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSingle'
}
