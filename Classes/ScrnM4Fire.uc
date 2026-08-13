class ScrnM4Fire extends ScrnFire_HighROF;


defaultproperties
{
    // Vanilla
    FireEndSoundRef="KF_M4RifleSnd.M4Rifle_Fire_Loop_End_M"
    FireEndStereoSoundRef="KF_M4RifleSnd.M4Rifle_Fire_Loop_End_S"
    AmbientFireSoundRef="KF_M4RifleSnd.M4Rifle_Fire_Loop"
    RecoilRate=0.065000
    maxVerticalRecoilAngle=250
    maxHorizontalRecoilAngle=100
    ShellEjectClass=Class'ROEffects.KFShellEjectM4Rifle'
    ShellEjectBoneName="Shell_eject"
    FireSoundRef="KF_M4RifleSnd.M4Rifle_Fire_Single_M"
    StereoFireSoundRef="KF_M4RifleSnd.M4Rifle_Fire_Single_S"
    NoAmmoSoundRef="KF_AK47Snd.AK47_DryFire"
    Momentum=8500.000000
    FireRate=0.075000
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=350.000000)
    ShakeRotRate=(X=5000.000000,Y=5000.000000,Z=5000.000000)
    ShakeRotTime=0.750000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.008000
    SpreadStyle=SS_Random

    // ScrN
    DamageMax=32
    PenDmgReduction=0.75
    MaxPenetrations=1
    FireLoopAnimRate=1.59
    DamageType=class'ScrnDamTypeM4AssaultRifle'
    AmmoClass=class'ScrnM4Ammo'
}
