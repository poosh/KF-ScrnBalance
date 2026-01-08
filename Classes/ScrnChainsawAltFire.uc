class ScrnChainsawAltFire extends ScrnMeleeFire;

var float LastClickTime;

var sound FireEndSound;
var string FireEndSoundRef;

static function PreloadAssets(optional KFMeleeFire Spawned)
{
    super.PreloadAssets(Spawned);

    default.FireEndSound = sound(DynamicLoadObject(default.FireEndSoundRef, class'sound', true));

    if (ScrnChainsawAltFire(Spawned) != none) {
        ChainsawAltFire(Spawned).FireEndSound = default.FireEndSound;
    }
}

static function bool UnloadAssets()
{
    super.UnloadAssets();

    default.FireEndSound = none;

    return true;
}

simulated Function Timer()
{
    super.Timer();

    Weapon.PlayOwnedSound(FireEndSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,,false);
}

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

    if (KFWeap.MagAmmoRemaining < AmmoPerFire) {
        if( Level.TimeSeconds - LastClickTime > FireRate )
            LastClickTime = Level.TimeSeconds;

        if( AIController(Instigator.Controller) != none )
            KFWeap.ReloadMeNow();
        return false;
    }

    return Super.AllowFire();
}


defaultproperties
{
    AmmoPerFire=10
    WideDamageMinHitAngle=0.80
    MeleeDamage=330
    weaponRange=100
    hitDamageClass=class'ScrnDamTypeChainsawAlt'
    AmmoClass=class'ScrnChainsawAmmo'
    bWaitForRelease=True

    FireAnims(0)="Fire2"
    FireAnims(1)="fire3"
    FireEndSoundRef="KF_ChainsawSnd.Chainsaw_RevLong_End"
    DamagedelayMin=0.65
    DamagedelayMax=0.65
    HitEffectClass=Class'KFMod.ChainsawHitEffect'
    FireSoundRef="KF_ChainsawSnd.Chainsaw_RevLong_Start"
    TransientSoundVolume=1.8
    FireAnim="Fire2"
    FireRate=1.1
    BotRefireRate=0.80
}
