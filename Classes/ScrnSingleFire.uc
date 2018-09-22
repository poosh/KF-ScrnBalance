class ScrnSingleFire extends SingleFire;

//lock slide back if fired last round
simulated function bool AllowFire()
{
    if( (Level.TimeSeconds - LastFireTime > FireRate) && KFWeapon(Weapon).MagAmmoRemaining <= 1 && !KFWeapon(Weapon).bIsReloading )
    {
            ScrnSingle(Weapon).LockSlideBack(); //lock slide back
    }
    if( (Level.TimeSeconds - LastFireTime > FireRate) && KFWeapon(Weapon).MagAmmoRemaining >= 1 && !KFWeapon(Weapon).bIsReloading )
    {
        if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnSingle(Weapon).DoHammerDrop( GetFireSpeed() ); //drop hammer
    }
    return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSingle'
}
