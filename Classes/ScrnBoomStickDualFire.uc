//=============================================================================
// BoomStick Dual Fire
//=============================================================================
class ScrnBoomStickDualFire extends BoomStickFire;

simulated function bool AllowFire()
{
    local KFPawn KFP;

    KFP = KFPawn(Instigator);

    if( KFWeap.bIsReloading )
        return false;

    if ( KFP.SecondaryItem != none || KFP.bThrowingNade )
        return false;

    if ( KFWeap.MagAmmoRemaining < AmmoPerFire ) {
        if ( KFWeap.MagAmmoRemaining == 0 &&  KFWeap.AmmoAmount(0) > KFWeap.MagAmmoRemaining )
            KFWeap.ReloadMeNow();
        return false;
    }

    if ( Level.TimeSeconds - LastClickTime > FireRate )
        LastClickTime = Level.TimeSeconds;

    return super(WeaponFire).AllowFire();
}

event ModeDoFire()
{
    if (!AllowFire())
        return;

    bVeryLastShotAnim = KFWeap.AmmoAmount(0) <= AmmoPerFire;
    Load = min(Load, KFWeap.MagAmmoRemaining);
    super(KFShotgunFire).ModeDoFire();

    if ( !bVeryLastShotAnim && Weapon.ClientState != WS_PutDown ) {
        Weapon.GotoState('FireAndReload');
    }
}

function PlayFiring()
{
    local float RandPitch;

    if ( Weapon.Mesh != None ) {
        if( KFWeap.bAimingRifle ) {
            if( bVeryLastShotAnim ) {
                Weapon.PlayAnim(FireLastAimedAnim, FireAnimRate, TweenTime);
            }
            else {
                Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
            }
        }
        else {
            if( bVeryLastShotAnim ) {
                Weapon.PlayAnim(FireLastAnim, FireAnimRate, TweenTime);
            }
            else {
                Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
            }
        }
    }

    if( bRandomPitchFireSound ) {
        RandPitch = FRand() * RandomPitchAdjustAmt;
        if( FRand() < 0.5 ) {
            RandPitch *= -1.0;
        }
    }

    if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled()
            && Weapon.Instigator.IsFirstPerson() && StereoFireSound != none )
    {
        Weapon.PlayOwnedSound(StereoFireSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,(1.0 + RandPitch),false);
    }
    else {
        Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0 + RandPitch),false);
    }
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}


defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnBoomStickBullet'
     AmmoPerFire=2
}
