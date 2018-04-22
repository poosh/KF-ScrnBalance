class ScrnChainsawFire extends ChainsawFire;

var float LastClickTime;

simulated function bool AllowFire()
{
    if(KFWeapon(Weapon).bIsReloading)
        return false;
    if(KFPawn(Instigator).SecondaryItem!=none)
        return false;
    if(KFPawn(Instigator).bThrowingNade)
        return false;

    if(KFWeapon(Weapon).MagAmmoRemaining < 1)
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
