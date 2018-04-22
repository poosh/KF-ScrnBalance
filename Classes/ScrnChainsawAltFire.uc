class ScrnChainsawAltFire extends ChainsawAltFire;

var() int       MaxChargeAmmo;

var float LastClickTime;


simulated function bool AllowFire()
{
    if(KFWeapon(Weapon).bIsReloading)
        return false;
    if(KFPawn(Instigator).SecondaryItem!=none)
        return false;
    if(KFPawn(Instigator).bThrowingNade)
        return false;

    if(KFWeapon(Weapon).MagAmmoRemaining < MaxChargeAmmo)
    {
        if( Level.TimeSeconds - LastClickTime>FireRate )
        {
            LastClickTime = Level.TimeSeconds;
        }

        if( AIController(Instigator.Controller)!=None )
            KFWeapon(Weapon).ReloadMeNow();
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
