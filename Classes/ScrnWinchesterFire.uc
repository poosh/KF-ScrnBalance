class ScrnWinchesterFire extends ScrnFire;


simulated function bool MayClientHaveAmmo()
{
    return ScrnWinchester(Weapon).bFiringLastRound || super.MayClientHaveAmmo();
}

event ModeDoFire()
{
    if (KFWeap.MagAmmoRemaining <= 1 && !KFWeap.bIsReloading) {
        ScrnWinchester(Weapon).HideBullet(); //hide bullet
    }
    super.ModeDoFire();
}

defaultproperties
{
    // vanilla
    FireAimedAnim="AimFire"
    RecoilRate=0.100000
    maxVerticalRecoilAngle=800
    maxHorizontalRecoilAngle=250
    StereoFireSoundRef="KF_RifleSnd.Rifle_FireST"
    DamageMax=140
    Momentum=18000.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    bModeExclusive=False
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireLoopAnim=
    FireEndAnim=
    FireSound=SoundGroup'KF_RifleSnd.Rifle_Fire'
    NoAmmoSound=Sound'KF_RifleSnd.Rifle_DryFire'
    FireForce="ShockRifleFire"
    FireRate=0.900000
    AmmoClass=Class'KFMod.WinchesterAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=100.000000,Y=100.000000,Z=500.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=2.000000
    ShakeOffsetMag=(X=10.000000,Y=3.000000,Z=12.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.650000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
    aimerror=0.000000
    Spread=0.007000

    // ScrN
    DamageType=class'ScrnDamTypeWinchester'
}
