class ScrnDualiesFire extends ScrnFire_Dualies;

var ScrnDualies ScrnWeap; // avoid typecasting


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualies(Weapon);
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


defaultproperties
{
    DamageMax=35
    DamageType=class'ScrnDamTypeDualies'
    bFiringDoesntAffectMovement=true
    RecoilVelocityScale=0
}
