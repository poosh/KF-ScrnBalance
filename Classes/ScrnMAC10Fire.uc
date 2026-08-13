//=============================================================================
// MAC Fire
//=============================================================================
class ScrnMAC10Fire extends ScrnFire_Inc;

function WeaponCloseBolt()
{
    ScrnMAC10MP(KFWeap).CloseBolt();
}

function bool IsBoltClosed()
{
    return ScrnMAC10MP(KFWeap).bBoltClosed;
}


defaultproperties
{
    // vanilla
    FireEndSoundRef="KF_MAC10MPSnd.MAC10_Fire_Loop_End_M"
    FireEndStereoSoundRef="KF_MAC10MPSnd.MAC10_Fire_Loop_End_S"
    AmbientFireSoundRef="KF_MAC10MPSnd.MAC10_Fire_Loop"
    maxVerticalRecoilAngle=150
    maxHorizontalRecoilAngle=100
    ShellEjectClass=Class'ROEffects.KFShellEjectMac'
    ShellEjectBoneName="Mac11_Ejector"
    bRandomPitchFireSound=False
    FireSoundRef="KF_MAC10MPSnd.MAC10_Silenced_Fire"
    StereoFireSoundRef="KF_MAC10MPSnd.MAC10_Silenced_FireST"
    NoAmmoSoundRef="KF_AK47Snd.AK47_DryFire"
    Momentum=6500.000000
    FireRate=0.052000
    AmmoClass=Class'KFMod.MAC10Ammo'
    ShakeRotMag=(X=35.000000,Y=35.000000,Z=200.000000)
    ShakeRotRate=(X=8000.000000,Y=8000.000000,Z=8000.000000)
    ShakeRotTime=3.000000
    ShakeOffsetMag=(X=4.500000,Y=2.800000,Z=5.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=35.000000
    Spread=0.013000
    SpreadStyle=SS_Random

    // ScrN
    FireAnim=Fire_Iron //fix annoying hipfire messing up aiming after firing
    FireEndAnim=Fire_Iron_End //fix annoying hipfire messing up aiming after firing
    RecoilRate=0.03
    RecoilVelocityScale=0
}
