class ScrnSPSniperFire extends ScrnFire;

defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.120000
    maxVerticalRecoilAngle=500
    maxHorizontalRecoilAngle=350
    ShellEjectBoneName="Shell_eject"
    FireSoundRef="KF_SP_LongmusketSnd.KFO_Sniper_Fire_M"
    StereoFireSoundRef="KF_SP_LongmusketSnd.KFO_Sniper_Fire_S"
    NoAmmoSoundRef="KF_M14EBRSnd.M14EBR_DryFire"
    Momentum=13000.000000
    bWaitForRelease=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    FireRate=0.940000
    AmmoClass=Class'KFMod.SPSniperAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=100.000000,Y=100.000000,Z=500.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=2.000000
    ShakeOffsetMag=(X=10.000000,Y=3.000000,Z=12.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSPSniper'
    aimerror=42.000000
    Spread=0.005000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeSPSniper'
    DamageMax=90 // 180
    ShellEjectClass=None
}
