class ScrnDualDeagleFire extends ScrnFire_Dualies;

var ScrnDualDeagle ScrnWeap; // avoid typecasting

var bool bCheck4Ach;
var transient float NextAchSpeechTime;


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualDeagle(Weapon);
}

function SetPistolFireOrder(bool bNextFireLeft)
{
    super.SetPistolFireOrder(bNextFireLeft);
    ScrnWeap.bConsumeLeft = bFireLeft;
}

function SwapPistolFireOrder()
{
    SetPistolFireOrder(!bFireLeft || ScrnWeap.RightGunAmmoRemaining() == 0);
}

function PlayFiring()
{
    local int MagAmmoRemainingAfterShot;

    super.PlayFiring();

    // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
    // and we cannon be sure if the replication happened at this moment or not yet
    // FiringRound stores MagAmmoRemaining on client before the fire.
    // If FiringRound == MagAmmoRemaining, then property is not replicated yet.
    // If FiringRound - 1 == MagAmmoRemaining, then property is already replicated.
    if ( ScrnWeap.FiringRound <= ScrnWeap.MagAmmoRemaining ) {
        MagAmmoRemainingAfterShot = ScrnWeap.FiringRound - 1;
    }
    else {
        MagAmmoRemainingAfterShot = ScrnWeap.MagAmmoRemaining;
    }

    if( MagAmmoRemainingAfterShot == 0 ) {
        ScrnWeap.LockLeftSlideBack();
        ScrnWeap.LockRightSlideBack();
    }
    else if ( MagAmmoRemainingAfterShot == ScrnWeap.LeftGunAmmoRemaining ) {
        ScrnWeap.LockRightSlideBack();
        ScrnWeap.bTweenLeftSlide = true;
    }
    else if ( bFireLeft ) {
        ScrnWeap.DoLeftHammerDrop( GetFireSpeed() );
        ScrnWeap.AddExtraLeftSlideMovement( GetFireSpeed() );
    }
    else {
        ScrnWeap.DoRightHammerDrop( GetFireSpeed() );
        ScrnWeap.AddExtraRightSlideMovement( GetFireSpeed() );
    }
}

function DoTrace(Vector Start, Rotator Dir)
{
    super.DoTrace(Start, Dir);

    if (Weapon.Role == Role_Authority && KillCountPerTrace >= 4) {
        if (Level.TimeSeconds > NextAchSpeechTime && KFPlayerController(Instigator.Controller) != none) {
            KFPlayerController(Instigator.Controller).Speech('AUTO', 22, "");
            NextAchSpeechTime = Level.TimeSeconds + 60;
        }
        if (bCheck4Ach) {
            class'ScrnAchCtrl'.static.Ach2Pawn(Weapon.Instigator, 'HC4Kills', 1);
            bCheck4Ach = false;
        }
    }
}

defaultproperties
{
    // vanilla
    maxVerticalRecoilAngle=1200
    maxHorizontalRecoilAngle=200
    ShellEjectClass=Class'ROEffects.KFShellEjectHandCannon'
    StereoFireSoundRef="KF_HandcannonSnd.50AE_FireST"
    DamageMax=115
    Momentum=20000.000000
    FireSound=SoundGroup'KF_HandcannonSnd.50AE_Fire'
    NoAmmoSound=Sound'KF_HandcannonSnd.50AE_DryFire'
    FireRate=0.130000
    ShakeRotMag=(Z=400.000000)
    ShakeRotRate=(X=12500.000000,Y=12500.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(Y=1.000000,Z=8.000000)
    ShakeOffsetTime=2.500000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
    aimerror=40.000000
    Spread=0.010000

    // ScrN
    PenDmgReduction=0.650000
    MaxPenetrations=4
    PenDmgReductionByHealth=0
    bCheck4Ach=True
    DamageType=class'ScrnDamTypeDualDeagle'
    AmmoClass=class'ScrnDeagleAmmo'
}
