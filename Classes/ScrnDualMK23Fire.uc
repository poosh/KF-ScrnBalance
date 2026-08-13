//The dual MK23s firing order is actually reversed due to reload animation, so all references to bFireLeft actually fire the right
class ScrnDualMK23Fire extends ScrnFire_Dualies;

var ScrnDualMK23Pistol ScrnWeap; // avoid typecasting


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualMK23Pistol(Weapon);
}

function SetPistolFireOrder(bool bNextFireLeft)
{
    super.SetPistolFireOrder(bNextFireLeft);
    ScrnWeap.bConsumeLeft = bFireLeft;
}

function SwapPistolFireOrder()
{
    SetPistolFireOrder(!bFireLeft && ScrnWeap.LeftGunAmmoRemaining > 0);
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
        ScrnWeap.bTweenLeftSlide = true;
        ScrnWeap.bTweenRightSlide = true;

    }
    else if ( MagAmmoRemainingAfterShot == ScrnWeap.RightGunAmmoRemaining() ) {
        ScrnWeap.LockLeftSlideBack();
        ScrnWeap.bTweenRightSlide = true;
    }
}


defaultproperties
{
    // Vanilla
    maxVerticalRecoilAngle=500
    maxHorizontalRecoilAngle=100
    ShellEjectClass=Class'KFMod.MK23Shell'
    FireSoundRef="KF_MK23Snd.MK23_Fire_M"
    StereoFireSoundRef="KF_MK23Snd.MK23_Fire_S"
    NoAmmoSoundRef="KF_HandcannonSnd.50AE_DryFire"
    DamageMax=82
    Momentum=18000.000000
    FireSound=None
    NoAmmoSound=None
    FireRate=0.120000
    ShakeRotMag=(Z=290.000000)
    ShakeRotRate=(X=10080.000000,Y=10080.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(Y=1.000000,Z=8.000000)
    ShakeOffsetTime=2.500000
    FlashEmitterClass=Class'KFMod.MuzzleFlashMK'
    aimerror=40.000000
    Spread=0.010000

    // ScrN
    bDefaultLeft=true
    bFireLeft=true
    MaxPenetrations=0
    DamageType=class'ScrnDamTypeDualMK23Pistol'
    FireAnim="FireLeft"
    FireAimedAnim2=FireRight_Iron
    FireAimedAnim=FireLeft_Iron
    FireAnim2="FireRight"
    AmmoClass=class'ScrnMK23Ammo'
}
