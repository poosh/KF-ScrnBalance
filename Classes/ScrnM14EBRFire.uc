class ScrnM14EBRFire extends ScrnFire;

defaultproperties
{
    // Vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.085000
    maxVerticalRecoilAngle=2000
    maxHorizontalRecoilAngle=500
    ShellEjectClass=Class'ROEffects.KFShellEjectEBR'
    ShellEjectBoneName="Shell_eject"
    FireSoundRef="KF_M14EBRSnd.M14EBR_Fire"
    StereoFireSoundRef="KF_M14EBRSnd.M14EBR_FireST"
    NoAmmoSoundRef="KF_M14EBRSnd.M14EBR_DryFire"
    DamageMax=80
    Momentum=9500.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    FireRate=0.250000
    AmmoClass=Class'KFMod.M14EBRAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=300.000000)
    ShakeRotRate=(X=7500.000000,Y=7500.000000,Z=7500.000000)
    ShakeRotTime=0.650000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.150000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.005000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeM14EBR'
}
