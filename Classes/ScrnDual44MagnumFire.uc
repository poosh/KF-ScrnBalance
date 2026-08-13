class ScrnDual44MagnumFire extends ScrnFire_Dualies;

var ScrnDual44Magnum ScrnWeap; // avoid typecasting


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDual44Magnum(Weapon);
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


defaultproperties
{
    // vanilla
    maxVerticalRecoilAngle=1200
    maxHorizontalRecoilAngle=200
    ShellEjectClass=None
    FireSoundRef="KF_RevolverSnd.Revolver_Fire_M"
    StereoFireSoundRef="KF_RevolverSnd.Revolver_Fire_S"
    NoAmmoSoundRef="KF_HandcannonSnd.50AE_DryFire"
    Momentum=15000.000000
    FireSound=None
    NoAmmoSound=None
    FireRate=0.075000
    ShakeRotMag=(Z=400.000000)
    ShakeRotRate=(X=12500.000000,Y=12500.000000)
    ShakeRotTime=3.500000
    ShakeOffsetMag=(Y=1.000000,Z=8.000000)
    ShakeOffsetTime=2.500000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stKar'
    aimerror=40.000000
    Spread=0.009000

    // ScrN
    PenDmgReduction=0.50
    MaxPenetrations=3
    PenDmgReductionByHealth=0
    DamageType=class'ScrnDamTypeDual44Magnum'
    DamageMax=90
    AmmoClass=class'ScrnMagnum44Ammo'
}
