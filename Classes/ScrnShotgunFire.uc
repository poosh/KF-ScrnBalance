class ScrnShotgunFire extends ShotgunFire;

simulated function bool AllowFire()
{
    local KFPawn KFP;

    KFP = KFPawn(Instigator);

    if( KFWeap.bIsReloading || KFWeap.MagAmmoRemaining < AmmoPerFire)
        return false;

    if ( KFP.SecondaryItem != none || KFP.bThrowingNade )
        return false;

    if ( Level.TimeSeconds - LastClickTime > FireRate )
        LastClickTime = Level.TimeSeconds;

    return super(WeaponFire).AllowFire();
}

defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnShotgunBullet'
}
