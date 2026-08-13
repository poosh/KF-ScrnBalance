class ScrnThompsonIncFire extends ScrnFire_Inc;


function WeaponCloseBolt()
{
    ScrnThompsonInc(KFWeap).CloseBolt();
}

function bool IsBoltClosed()
{
    return ScrnThompsonInc(KFWeap).bBoltClosed;
}


defaultproperties
{
    // vanilla
    FireEndSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop_End_M"
    FireEndStereoSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop_End_S"
    AmbientFireSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop"
    RecoilRate=0.080000
    maxVerticalRecoilAngle=150
    maxHorizontalRecoilAngle=100
    ShellEjectClass=Class'KFMod.IJCShellEjectThompson'
    ShellEjectBoneName="Shell_eject"
    bRandomPitchFireSound=False
    FireSoundRef="KF_IJC_HalloweenSnd.Thompson_Fire_Single_M"
    StereoFireSoundRef="KF_IJC_HalloweenSnd.Thompson_Fire_Single_S"
    NoAmmoSoundRef="KF_AK47Snd.AK47_DryFire"
    Momentum=12500.000000
    FireRate=0.085700
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=350.000000)
    ShakeRotRate=(X=5000.000000,Y=5000.000000,Z=5000.000000)
    ShakeRotTime=0.750000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    BotRefireRate=0.150000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.012000
    SpreadStyle=SS_Random

    // ScrN
    AmmoClass=class'ScrnThompsonIncAmmo'
    DamageMax=40
}
