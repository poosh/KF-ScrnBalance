class ScrnChainsawFire extends ChainsawFire;

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

    if ( KFWeap.MagAmmoRemaining < 1 ) {
        if( Level.TimeSeconds - LastClickTime > FireRate )
            LastClickTime = Level.TimeSeconds;

        if( AIController(Instigator.Controller) != none )
            KFWeap.ReloadMeNow();
        return false;
    }

    return Super.AllowFire();
}

function PlayDefaultAmbientSound()
{
    local WeaponAttachment WA;

    WA = WeaponAttachment(Weapon.ThirdPersonActor);

    if ( KFWeapon(Weapon) == none || (WA == none))
        return;

    WA.SoundVolume = WA.default.SoundVolume;
    WA.SoundRadius = WA.default.SoundRadius;
    if ( KFWeapon(Weapon).MagAmmoRemaining > 0 )
        WA.AmbientSound = WA.default.AmbientSound;
    else
        WA.AmbientSound = none;
}

defaultproperties
{
     MeleeDamage=22
     weaponRange=80.000000
     hitDamageClass=Class'ScrnBalanceSrv.ScrnDamTypeChainsawAlt'
     AmmoClass=Class'ScrnBalanceSrv.ScrnChainsawAmmo'
     AmmoPerFire=1
}
