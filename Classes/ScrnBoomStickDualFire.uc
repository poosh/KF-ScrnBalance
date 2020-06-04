//=============================================================================
// BoomStick Dual Fire
//=============================================================================
class ScrnBoomStickDualFire extends BoomStickFire;

var() float FireVeryLastRate;
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

    if ( Weapon.Role == ROLE_Authority ) {
        bLastBulletInMag = KFWeap.MagAmmoRemaining == 1;
    } // else already set in ScrnBoomStick.AltFire()
    bVeryLastShotAnim = KFWeap.AmmoAmount(0) <= AmmoPerFire;

    if ( !bVeryLastShotAnim ) {
        Weapon.GotoState('FireAndReload');
    }
    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    if (bLastBulletInMag)
        Load = 1;
    else
        Load = 2;

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
    // if( bVeryLastShotAnim ) {
    //     NextFireTime = Level.TimeSeconds + FireVeryLastRate;
    // }
    // else {
    //     NextFireTime = Level.TimeSeconds + FireRate;
    // }

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

function FlashMuzzleFlash()
{
    if( !bLastBulletInMag ) {
        if (FlashEmitter != None)
            FlashEmitter.Trigger(Weapon, Instigator);
    }
    if (Flash2Emitter != None)
        Flash2Emitter.Trigger(Weapon, Instigator);
}

defaultproperties
{
    FireVeryLastRate=0.25
    FireRate=2.75
    ProjectileClass=Class'ScrnBalanceSrv.ScrnBoomStickBullet'
    AmmoClass=Class'ScrnBalanceSrv.ScrnBoomStickAmmo'
    AmmoPerFire=2
    ProjPerFire=10  // * Load, which is AmmoPerFire
}
