class ScrnSingleFire extends ScrnFire;

var ScrnSingle ScrnWeap; // avoid typecasting

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnSingle(Weapon);
}

function PlayFiring()
{
    super.PlayFiring();

    // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
    // and we cannon be sure if the replication happened at this moment or not yet
    if( ScrnWeap.MagAmmoRemaining == 0 || ScrnWeap.bFiringLastRound ) {
        //lock slide back if fired last round
        ScrnWeap.LockSlideBack();
    }
    else {
        ScrnWeap.DoHammerDrop( GetFireSpeed() );
    }
}

defaultproperties
{
    // vanilla
    FireAimedAnim="Fire_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=300
    maxHorizontalRecoilAngle=50
    ShellEjectClass=Class'ROEffects.KFShellEject9mm'
    ShellEjectBoneName="Shell_eject"
    bRandomPitchFireSound=False
    StereoFireSoundRef="KF_9MMSnd.9mm_FireST"
    DamageMax=35
    Momentum=10000.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireAnimRate=1.500000
    TweenTime=0.025000
    FireSound=SoundGroup'KF_9MMSnd.9mm_Fire'
    NoAmmoSound=Sound'KF_9MMSnd.9mm_DryFire'
    FireForce="AssaultRifleFire"
    FireRate=0.175000
    AmmoClass=Class'KFMod.SingleAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=250.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=3.000000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=10.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.350000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stMP'
    aimerror=30.000000
    Spread=0.015000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeSingle'
    bFiringDoesntAffectMovement=true
    RecoilVelocityScale=0
}
