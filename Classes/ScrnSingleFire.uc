class ScrnSingleFire extends SingleFire;

//lock slide back if fired last round
simulated function bool AllowFire()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if( (Level.TimeSeconds - LastFireTime > FireRate) && !KFWeapon(Weapon).bIsReloading )
        {
            if (KFWeapon(Weapon).MagAmmoRemaining >= 1)
            {
                ScrnSingle(Weapon).DoHammerDrop( GetFireSpeed() ); //drop hammer
            }
            if (KFWeapon(Weapon).MagAmmoRemaining <= 1) 
            {
                ScrnSingle(Weapon).LockSlideBack(); //lock slide back
            }
    }
	return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSingle'
}
