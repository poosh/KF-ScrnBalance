class ScrnDualiesFire extends DualiesFire;

var ScrnDualies ScrnWeap; // avoid typecasting

var protected bool bFireLeft;


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualies(Weapon);
}

//called after reload and on zoom toggle, sets next pistol to fire to sync with slide lock order
function SetPistolFireOrder(bool bNextFireLeft)
{
    bFireLeft = bNextFireLeft;

    if (bFireLeft)
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.FlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.altFlashBoneName;
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    else
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.altFlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.FlashBoneName;
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
    }
}

function bool GetPistolFireOrder()
{
    return bFireLeft;
}

event ModeDoFire()
{
    if ( !AllowFire() )
        return;

    super(KFFire).ModeDoFire();

    InitEffects();
    SetPistolFireOrder(!bFireLeft);
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
    else if ( MagAmmoRemainingAfterShot == 1 ) {
        ScrnWeap.LockRightSlideBack();
        ScrnWeap.bTweenLeftSlide = true;
    }
    else if ( bFireLeft ) {
        ScrnWeap.DoLeftHammerDrop( GetFireSpeed() );
    }
    else {
        ScrnWeap.DoRightHammerDrop( GetFireSpeed() );
    }
}

// Remove left gun's aiming bug  (c) PooSH
// Thanks to n87, Benjamin
function DoFireEffect()
{
    super(KFFire).DoFireEffect();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeDualies'
}
