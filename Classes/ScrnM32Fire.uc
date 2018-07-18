class ScrnM32Fire extends M32Fire;

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

defaultproperties
{
    FireAnimRate=1.10; //Speed up cylinder rotate animation so it doesn't break when firing at max rate
    ProjectileClass=Class'ScrnBalanceSrv.ScrnM32GrenadeProjectile'
    ProjSpawnOffset=(X=5,Y=10.000000)
}
