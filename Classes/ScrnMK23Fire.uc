class ScrnMK23Fire extends ScrnFire;

var ScrnMK23Pistol ScrnWeap; // avoid typecasting

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnMK23Pistol(Weapon);
}

function PlayFiring()
{
    super.PlayFiring();

    // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
    // and we cannon be sure if the replication happened at this moment or not yet
    if( ScrnWeap.MagAmmoRemaining == 0 || ScrnWeap.bFiringLastRound ) {
        //lock slide back if fired last round
        ScrnWeap.LockSlideBack();
    }
}


defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=500
    maxHorizontalRecoilAngle=100
    ShellEjectClass=Class'ROEffects.KFShellEject9mm'
    ShellEjectBoneName="Shell_eject"
    FireSoundRef="KF_MK23Snd.MK23_Fire_M"
    StereoFireSoundRef="KF_MK23Snd.MK23_Fire_S"
    NoAmmoSoundRef="KF_HandcannonSnd.50AE_DryFire"
    Momentum=18000.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireLoopAnim=
    FireEndAnim=
    TweenTime=0.025000
    FireRate=0.180000
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=290.000000)
    ShakeRotRate=(X=10080.000000,Y=10080.000000,Z=10000.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(X=6.000000,Y=1.000000,Z=8.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.500000
    BotRefireRate=0.650000
    FlashEmitterClass=Class'KFMod.MuzzleFlashMK'
    aimerror=30.000000
    Spread=0.010000
    SpreadStyle=SS_Random

    // ScrN
    DamageMax=82
    DamageType=class'ScrnDamTypeMK23Pistol'
    AmmoClass=class'ScrnMK23Ammo'
}
