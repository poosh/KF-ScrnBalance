class ScrnM7A3MFire extends ScrnFire;

defaultproperties
{
    // Vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.085000
    maxVerticalRecoilAngle=500
    maxHorizontalRecoilAngle=250
    ShellEjectClass=Class'ROEffects.KFShellEjectSCAR'
    ShellEjectBoneName="Shell_eject"
    bAccuracyBonusForSemiAuto=True
    FireSoundRef="KF_M7A3Snd.M7A3_Fire_M"
    StereoFireSoundRef="KF_M7A3Snd.M7A3_Fire_S"
    NoAmmoSoundRef="KF_SCARSnd.SCAR_DryFire"
    Momentum=7000.000000
    bPawnRapidFireAnim=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    AmmoPerFire=1
    ShakeRotMag=(X=30.000000,Y=30.000000,Z=240.000000)
    ShakeRotRate=(X=8500.000000,Y=8500.000000,Z=8500.000000)
    ShakeRotTime=2.500000
    ShakeOffsetMag=(X=6.000000,Y=2.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.500000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.010000
    SpreadStyle=SS_Random

    // ScrN
    FireRate=0.15 //0.166000
    DamageMax=80
    DamageType=class'ScrnDamTypeM7A3M'
    AmmoClass=class'ScrnM7A3MAmmo'
}
