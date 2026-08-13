class ScrnMKb42Fire extends ScrnFire_OpenBolt;

function WeaponCloseBolt()
{
    ScrnMKb42AssaultRifle(KFWeap).CloseBolt();
}

function bool IsBoltClosed()
{
    return ScrnMKb42AssaultRifle(KFWeap).bBoltClosed;
}

defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=425
    maxHorizontalRecoilAngle=225
    ShellEjectClass=Class'ROEffects.KFShellEjectMkb'
    ShellEjectBoneName="Shell_eject"
    bAccuracyBonusForSemiAuto=True
    FireSoundRef="KF_mkb42Snd.mkb42_Fire_Single_M"
    StereoFireSoundRef="KF_mkb42Snd.mkb42_Fire_Single_S"
    NoAmmoSoundRef="KF_AK47Snd.AK47_DryFire"
    DamageMax=45
    Momentum=8500.000000
    bPawnRapidFireAnim=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    FireRate=0.100000
    AmmoPerFire=1
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=350.000000)
    ShakeRotRate=(X=5000.000000,Y=5000.000000,Z=5000.000000)
    ShakeRotTime=0.750000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    Spread=0.009000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeMKb42AssaultRifle'
    AmmoClass=class'ScrnMKb42Ammo'
    bHasFireLoop=false
}
