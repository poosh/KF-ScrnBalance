//=============================================================================
// BoomStick Single Fire
//=============================================================================
class ScrnBoomStickSingleFire extends BoomStickAltFire;

var transient bool bLastBulletInMag;

simulated function bool AllowFire()
{
    return !KFWeap.bIsReloading && Weapon.AmmoAmount(0) > 0;
}

event ModeDoFire()
{
    local float Rec;
    local KFPlayerReplicationInfo KFPRI;

    if (!AllowFire())
        return;

    // ModeDoFire has nativereplication. It sometimes triggers first on server, sometimes - on client.
    // Sometimes, the server can execute ModeDoFire() and replicate MagAmmoRemaining to the client before
    // the ModeDoFire() call on the client.
    // Hence, the value of MagAmmoRemaining on the client side is unreliable at this moment.
    // On the client side, We set bLastBulletInMag in ScrnBoomStick.Fire()
    if ( Weapon.Role == ROLE_Authority ) {
        bLastBulletInMag = KFWeap.MagAmmoRemaining == 1;
    }
    bVeryLastShotAnim = bLastBulletInMag && KFWeap.AmmoAmount(0) <= AmmoPerFire;

    if( bLastBulletInMag && !bVeryLastShotAnim ) {
        Weapon.GotoState('FireAndReload');
    }

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    Spread = Default.Spread;
    Rec = 1;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);

    if( !bFiringDoesntAffectMovement ) {
        Instigator.Velocity.x *= 0.5;
        Instigator.Velocity.y *= 0.5;
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

    // Setting correct NextFireTime prevents nading and quick melee
    // if( bLastBulletInMag && !bVeryLastShotAnim ) {
    //     NextFireTime = Level.TimeSeconds + FireLastRate;
    // }
    // else {
    //     NextFireTime = Level.TimeSeconds + FireRate;
    // }
    NextFireTime = Level.TimeSeconds + FireRate;

    Load = AmmoPerFire;
    HoldTime = 0;

    if ( Instigator.PendingWeapon != None && Instigator.PendingWeapon != Weapon ) {
        bIsFiring = false;
        Weapon.PutDown();
    }

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

function FlashMuzzleFlash()
{
    if( bLastBulletInMag ) {
        // left barrel
        if (FlashEmitter != None)
            FlashEmitter.Trigger(Weapon, Instigator);
    }
    else {
        // right barrel
        if (Flash2Emitter != None)
            Flash2Emitter.Trigger(Weapon, Instigator);
    }
}


defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnBoomStickBullet'
     AmmoClass=Class'ScrnBalanceSrv.ScrnBoomStickAmmo'
     AmmoPerFire=1
}
