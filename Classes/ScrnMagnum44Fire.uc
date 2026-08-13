class ScrnMagnum44Fire extends ScrnFire;

defaultproperties
{
    // vanilla stats
    FireAimedAnim="Iron_Fire"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=1200
    maxHorizontalRecoilAngle=200
    FireSoundRef="KF_RevolverSnd.Revolver_Fire_M"
    StereoFireSoundRef="KF_RevolverSnd.Revolver_Fire_S"
    NoAmmoSoundRef="KF_HandcannonSnd.50AE_DryFire"
    Momentum=15000.000000
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireLoopAnim=
    FireEndAnim=
    TweenTime=0.025000
    FireRate=0.150000
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=400.000000)
    ShakeRotRate=(X=12500.000000,Y=12500.000000,Z=10000.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(X=6.000000,Y=1.000000,Z=8.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.500000
    BotRefireRate=0.650000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
    aimerror=40.000000
    Spread=0.009000
    SpreadStyle=SS_Random

    // ScrN changes
    PenDmgReduction=0.50
    MaxPenetrations=3
    PenDmgReductionByHealth=0
    DamageMin=10
    DamageMax=90
    DamageType=class'ScrnDamTypeMagnum44Pistol'
    AmmoClass=class'ScrnMagnum44Ammo'
}
