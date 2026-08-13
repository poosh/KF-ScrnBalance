//=============================================================================
 //SCARMK17 Fire
//=============================================================================
class ScrnSCARMK17Fire extends ScrnFire;

//lock charging handle after firing last shot
simulated function bool AllowFire()
{
    if (super.AllowFire() && KFWeap.MagAmmoRemaining <= 1 && !ScrnSCARMK17AssaultRifle(Weapon).bBoltLockQueued ) {
        ScrnSCARMK17AssaultRifle(Weapon).bBoltLockQueued = true; //make sure it only gets set once
        ScrnSCARMK17AssaultRifle(Weapon).BoltLockTime = (Level.TimeSeconds + 0.075); //move bolt to locked position after 0.075 seconds
    }
    return Super.AllowFire();
}

defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=500
    maxHorizontalRecoilAngle=250
    ShellEjectClass=Class'ROEffects.KFShellEjectSCAR'
    ShellEjectBoneName="Shell_eject"
    bAccuracyBonusForSemiAuto=True
    FireSoundRef="KF_SCARSnd.SCAR_Fire"
    StereoFireSoundRef="KF_SCARSnd.SCAR_FireST"
    NoAmmoSoundRef="KF_SCARSnd.SCAR_DryFire"
    DamageMax=65
    Momentum=8500.000000
    bPawnRapidFireAnim=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    FireRate=0.096000
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
    Spread=0.007500
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeSCARMK17AssaultRifle'
    AmmoClass=class'ScrnSCARMK17Ammo'
}
