class ScrnTrenchgunFire extends TrenchgunFire;

simulated function bool AllowFire()
{
                                                                             //changed to 1 -- PooSH
    if( KFWeapon(Weapon).bIsReloading && KFWeapon(Weapon).MagAmmoRemaining < 1)
        return false;

    if(KFPawn(Instigator).SecondaryItem!=none)
        return false;
    if( KFPawn(Instigator).bThrowingNade )
        return false;

    if( Level.TimeSeconds - LastClickTime>FireRate )
    {
        LastClickTime = Level.TimeSeconds;
    }

    if( KFWeaponShotgun(Weapon).MagAmmoRemaining<1 )
    {
            return false;
    }

    return super(WeaponFire).AllowFire();
}

event ModeDoFire()
{
    if( KFWeapon(Weapon).MagAmmoRemaining <= 1 && !KFWeapon(Weapon).bIsReloading )
    {
        ScrnTrenchgun(Weapon).HideBullet(); //hide bullet
    }
    Super.ModeDoFire();
}


defaultproperties
{
     ProjectileClass=class'ScrnTrenchgunBullet'
}
