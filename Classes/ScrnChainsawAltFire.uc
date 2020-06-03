class ScrnChainsawAltFire extends ChainsawAltFire;

var() int       MaxChargeAmmo;

var float LastClickTime;


simulated function bool AllowFire()
{
    local KFWeapon KFWeap;
    local KFPawn KFP;

    KFWeap = KFWeapon(Weapon);
    KFP = KFPawn(Instigator);

    if ( KFWeap.bIsReloading )
        return false;

    if ( KFP.SecondaryItem != none || KFP.bThrowingNade )
        return false;

    if ( KFWeap.MagAmmoRemaining < MaxChargeAmmo ) {
        if( Level.TimeSeconds - LastClickTime > FireRate )
            LastClickTime = Level.TimeSeconds;

        if( AIController(Instigator.Controller) != none )
            KFWeap.ReloadMeNow();
        return false;
    }

    return Super.AllowFire();
}

function ModeDoFire()
{
    if (!AllowFire())
        return;

    super.ModeDoFire();
    Weapon.ConsumeAmmo(ThisModeNum, MaxChargeAmmo);
}

defaultproperties
{
    MaxChargeAmmo=10
    MeleeDamage=330
    weaponRange=100.000000
    hitDamageClass=Class'ScrnBalanceSrv.ScrnDamTypeChainsawAlt'
    AmmoClass=Class'ScrnBalanceSrv.ScrnChainsawAmmo'
    bWaitForRelease=True
}
