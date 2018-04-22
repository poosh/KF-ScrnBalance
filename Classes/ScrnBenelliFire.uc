class ScrnBenelliFire extends BenelliFire;

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
     maxVerticalRecoilAngle=1250
     maxHorizontalRecoilAngle=700
     ProjectileClass=Class'ScrnBalanceSrv.ScrnBenelliBullet'
     AmmoClass=Class'ScrnBalanceSrv.ScrnBenelliAmmo'
     Spread=1075.000000
}
