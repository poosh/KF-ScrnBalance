class ScrnHighROFFire extends KFHighROFFire;

var int MaxSpreadBurst; // number of shots in a burst to reach MaxSpread
var float SpreadAimMod, SpreadCrouchMod, SpreadSemiAutoMod;
var float SpreadResetTime;

var transient float FireRateReminder;

event ModeDoFire()
{
    if (bWaitForRelease) {
        super(KFFire).ModeDoFire();
    }
    // else must be in FireLoop state
}

function float GetSpread()
{
    local float NewSpread;
    local float AccuracyMod;

    AccuracyMod = 1.0;

    if (KFWeap.bAimingRifle)
        AccuracyMod *= SpreadAimMod;

    if (Instigator != none && Instigator.bIsCrouched)
        AccuracyMod *= SpreadCrouchMod;

    if (bAccuracyBonusForSemiAuto && bWaitForRelease)
        AccuracyMod *= SpreadSemiAutoMod;

    if (Level.TimeSeconds - LastFireTime > SpreadResetTime) {
        NewSpread = default.Spread;
        NumShotsInBurst=0;
    }
    else {
        ++NumShotsInBurst;
        NewSpread = FMin(Default.Spread + (NumShotsInBurst * (MaxSpread / MaxSpreadBurst)), MaxSpread);
    }

    NewSpread *= AccuracyMod;

    return NewSpread;
}

simulated function HandleRecoil(float Rec)
{
    local rotator NewRecoilRotation;
    local KFPlayerController KFPC;
    local KFPawn KFPwn;
    local vector AdjustedVelocity;
    local float AdjustedSpeed;

    if( Instigator != none )
    {
        KFPC = KFPlayerController(Instigator.Controller);
        KFPwn = KFPawn(Instigator);
    }

    if( KFPC == none || KFPwn == none )
        return;

    if (KFPC.bFreeCamera || !bIsFiring)
        return;


    NewRecoilRotation.Pitch = RandRange(maxVerticalRecoilAngle * 0.5, maxVerticalRecoilAngle);
    NewRecoilRotation.Yaw = RandRange(maxHorizontalRecoilAngle * 0.5, maxHorizontalRecoilAngle);

    if (!bRecoilRightOnly && Rand(2) == 1)
        NewRecoilRotation.Yaw *= -1;

    if (RecoilVelocityScale > 0) {
        if (Weapon.Owner != none && Weapon.Owner.Physics == PHYS_Falling &&
            Weapon.Owner.PhysicsVolume.Gravity.Z > class'PhysicsVolume'.default.Gravity.Z)
        {
            AdjustedVelocity = Weapon.Owner.Velocity;
            // Ignore Z velocity in low grav so we don't get massive recoil
            AdjustedVelocity.Z = 0;
            AdjustedSpeed = VSize(AdjustedVelocity);
            //log("AdjustedSpeed = "$AdjustedSpeed$" scale = "$(AdjustedSpeed* RecoilVelocityScale * 0.5));

            // Reduce the falling recoil in low grav
            NewRecoilRotation.Pitch += (AdjustedSpeed* RecoilVelocityScale * 0.5);
            NewRecoilRotation.Yaw += (AdjustedSpeed* RecoilVelocityScale * 0.5);
        }
        else {
            //log("Velocity = "$VSize(Weapon.Owner.Velocity)$" scale = "$(VSize(Weapon.Owner.Velocity)* RecoilVelocityScale));
            NewRecoilRotation.Pitch += VSize(Weapon.Owner.Velocity) * RecoilVelocityScale;
            NewRecoilRotation.Yaw += VSize(Weapon.Owner.Velocity) * RecoilVelocityScale;
        }
    }
    NewRecoilRotation *= Rec;

    KFPC.SetRecoil(NewRecoilRotation, RecoilRate / (default.FireRate/FireRate));
}

state FireLoop
{
    function EndState()
    {
        super.EndState();
        FireRateReminder = 0;
    }

    event ModeDoFire()
    {
        if ( Level.TimeSeconds - LastFireTime > 0.1 )
            FireRateReminder = 0;
        else
            FireRateReminder += fmax(Level.TimeSeconds - FireRate - LastFireTime, 0.f); // do precise fire rate

        super(KFFire).ModeDoFire();

        if ( FireRateReminder > 0 ) {
            NextFireTime -= FireRateReminder;
            if ( NextFireTime < Level.TimeSeconds ) {
                FireRateReminder = Level.TimeSeconds - NextFireTime;
                NextFireTime = Level.TimeSeconds;
            }
        }
    }
}

defaultproperties
{
    MaxSpreadBurst=6
    MaxSpread=0.12
    SpreadAimMod=0.5
    SpreadCrouchMod=0.85
    SpreadSemiAutoMod=0.85
    SpreadResetTime=0.5
}
