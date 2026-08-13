class ScrnMP7MFire extends ScrnFire_HighROF;


defaultproperties
{
    // Vanilla
    FireEndSoundRef="KF_MP7Snd.MP7_tail"
    FireEndStereoSoundRef="KF_MP7Snd.MP7_tailST"
    AmbientFireSoundRef="KF_MP7Snd.MP7_FireLoop"
    RecoilRate=0.060000
    maxVerticalRecoilAngle=100
    maxHorizontalRecoilAngle=75
    RecoilVelocityScale=0.000000
    ShellEjectClass=Class'ROEffects.KFShellEjectMP'
    ShellEjectBoneName="Shell_eject"
    NoAmmoSoundRef="KF_MP7Snd.MP7_DryFire"
    Momentum=5500.000000
    FireRate=0.063000
    ShakeRotMag=(X=25.000000,Y=25.000000,Z=125.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=3.000000
    ShakeOffsetMag=(X=4.000000,Y=2.500000,Z=5.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stMP'
    Spread=0.012000
    SpreadStyle=SS_Random

    // ScrN
    MaxPenetrations=1
    PenDmgReduction=0.50
    PenDmgReductionByHealth=0
    DamageMin=10
    DamageMax=25
    AmmoClass=class'ScrnMP7MAmmo'
    DamageType=class'ScrnDamTypeMP7M'
}
