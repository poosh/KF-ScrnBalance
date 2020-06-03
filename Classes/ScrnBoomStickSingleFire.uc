//=============================================================================
// BoomStick Single Fire
//=============================================================================
class ScrnBoomStickSingleFire extends BoomStickAltFire;

var transient bool bLastBulletInMag;

simulated function bool AllowFire()
{
    local KFPawn KFP;

    if( KFWeap.bIsReloading )
        return false;

    KFP = KFPawn(Instigator);
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
    local float Rec;
    local KFPlayerReplicationInfo KFPRI;

    if (!AllowFire())
        return;

    bLastBulletInMag = KFWeap.MagAmmoRemaining == 1;
    bVeryLastShotAnim = KFWeap.AmmoAmount(0) <= AmmoPerFire;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    Spread = Default.Spread;
    Rec = 1;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);

    if( !bFiringDoesntAffectMovement ) {
        if (FireRate > 0.25) {
            Instigator.Velocity.x *= 0.1;
            Instigator.Velocity.y *= 0.1;
        }
        else {
            Instigator.Velocity.x *= 0.5;
            Instigator.Velocity.y *= 0.5;
        }
    }

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if ( Weapon.Role == ROLE_Authority ) {
        Weapon.ConsumeAmmo(ThisModeNum, Load);
        DoFireEffect();
        HoldTime = 0;    // if bot decides to stop firing, HoldTime must be reset first
        if ( Instigator == None || Instigator.Controller == None )
            return;

        if ( AIController(Instigator.Controller) != None )
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    if ( Instigator.IsLocallyControlled() ) {
        ShakeView();
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
    }
    else {
        ServerPlayFiring();
    }

    Weapon.IncrementFlashCount(ThisModeNum);

    if( bLastBulletInMag && !bVeryLastShotAnim ) {
        NextFireTime += FireLastRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }
    else {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }

    Load = AmmoPerFire;
    HoldTime = 0;

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None) {
        bIsFiring = false;
        Weapon.PutDown();
    }
    else if( bLastBulletInMag && !bVeryLastShotAnim ) {
        Weapon.GotoState('FireAndReload');
    }
    // end code from WeaponFire

    // client
    if ( Instigator.IsLocallyControlled() ) {
        HandleRecoil(Rec);
    }
}

function PlayFiring()
{
    local float RandPitch;

    if ( Weapon.Mesh != None ) {
        if( KFWeap.bAimingRifle ) {
            if( bLastBulletInMag && !bVeryLastShotAnim ) {
                Weapon.PlayAnim(FireLastAimedAnim, FireAnimRate, TweenTime);
            }
            else {
                Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
            }
        }
        else {
            if( bLastBulletInMag && !bVeryLastShotAnim ) {
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
     AmmoPerFire=1
}
