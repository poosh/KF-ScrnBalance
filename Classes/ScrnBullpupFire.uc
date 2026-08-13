class ScrnBullpupFire extends ScrnFire;


defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=200
    maxHorizontalRecoilAngle=75
    ShellEjectClass=Class'ROEffects.KFShellEjectBullpup'
    ShellEjectBoneName="Bullpup"
    bAccuracyBonusForSemiAuto=True
    StereoFireSoundRef="KF_BullpupSnd.Bullpup_FireST"
    Momentum=8500.000000
    bPawnRapidFireAnim=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireSound=SoundGroup'KF_BullpupSnd.Bullpup_Fire'
    NoAmmoSound=Sound'KF_9MMSnd.9mm_DryFire'
    FireForce="AssaultRifleFire"
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=250.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=0.500000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=10.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.000000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.008500
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeBullpup'
    AmmoClass=class'ScrnBullpupAmmo'
    DamageMax=28
    FireRate=0.09
}
