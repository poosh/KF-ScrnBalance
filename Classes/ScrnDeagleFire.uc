class ScrnDeagleFire extends ScrnFire;

var ScrnDeagle ScrnWeap; // avoid typecasting

var bool  bCheck4Ach;

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDeagle(Weapon);
}

function PlayFiring()
{
    super.PlayFiring();

    // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
    // and we cannon be sure if the replication happened at this moment or not yet
    if( ScrnWeap.MagAmmoRemaining == 0 || ScrnWeap.bFiringLastRound ) {
        //lock slide back if fired last round
        ScrnWeap.LockSlideBack();
        ScrnWeap.RotateHammerBack();
    }
    else {
        ScrnWeap.AddExtraSlideMovement( GetFireSpeed() );
        ScrnWeap.DoHammerDrop( GetFireSpeed() );
    }
}

function DoTrace(Vector Start, Rotator Dir)
{
    super.DoTrace(Start, Dir);

    if (Weapon.Role == Role_Authority && bCheck4Ach && KillCountPerTrace >= 4) {
        class'ScrnAchCtrl'.static.Ach2Pawn(Weapon.Instigator, 'HC4Kills', 1);
        bCheck4Ach = false;
    }
}

defaultproperties
{
    // vanilla
    FireAimedAnim="Iron_Fire"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=1200
    maxHorizontalRecoilAngle=200
    ShellEjectClass=Class'ROEffects.KFShellEjectHandCannon'
    ShellEjectBoneName="Shell_eject"
    StereoFireSoundRef="KF_HandcannonSnd.50AE_FireST"
    Momentum=20000.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireLoopAnim=
    FireEndAnim=
    TweenTime=0.025000
    FireSound=SoundGroup'KF_HandcannonSnd.50AE_Fire'
    NoAmmoSound=Sound'KF_HandcannonSnd.50AE_DryFire'
    FireRate=0.250000
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=400.000000)
    ShakeRotRate=(X=12500.000000,Y=12500.000000,Z=10000.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(X=6.000000,Y=1.000000,Z=8.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.500000
    BotRefireRate=0.650000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
    aimerror=40.000000
    Spread=0.010000
    SpreadStyle=SS_Random

    // ScrN
    DamageMax=115
    PenDmgReduction=0.65
    MaxPenetrations=4
    PenDmgReductionByHealth=0
    bCheck4Ach=True
    DamageType=class'ScrnDamTypeDeagle'
    AmmoClass=class'ScrnDeagleAmmo'
}
