class ScrnFire extends KFFire
    abstract;

var const bool bHasFireLoop;  // Enable if the class has FireLoop state
var const bool bHasFireBurst;  // Enable if the class has FireBurst state

var byte  MaxPenetrations;  // how many enemies can penetrate a single bullet
var float PenDmgReduction;   // penetration damage scale. 1.0 - no reduction, 0.75 - 25% reduction (75% damage remaining)
// if the damaged pawn is still alive, an additional scale gets applied, depending from the remaining health.
// 0.0005 - zed with 1000 health reduce the remaining damage by half (0.0005 * 1000 = 0.5)
var float PenDmgReductionByHealth;

var transient int KillCountPerTrace;

var int MaxSpreadBurst; // number of shots in a burst to reach MaxSpread
var float SpreadAimMod, SpreadCrouchMod, SpreadSemiAutoMod;
var float SpreadResetTime;
var float MovementEffect;  // the default 0.0 means auto

var protected bool bOldWaitForRelease;

// On the client, the new MagAmmoRemaining can be already replicated tbefore triggering ModeDoFire(),
// causing the following bug:
// 1. MagAmmoRemaining=1 before fire.
// 2. Server executes ModeDoFire(), eventually calling weapon.ConsumeAmmo() => --MagAmmoRemaining.
// 3. MagAmmoRemaining get replicated to the client.
// 4. Client ModeDoFire() fails the AllowFire() check due to MagAmmoRemaining=0.
// To bypass the issue, we introduce ClientMagAmmoRemaining. It is not replicated but PREDICTED value.
// NB! ClientMagAmmoRemaining value is unreliable as it might be incorrect. Actually, it is incorrect in ~50% cases.
// The magic is that "if (MagAmmoRemaining > 0 || ClientMagAmmoRemaining > 0)" is 100% reliable.
var transient int ClientMagAmmoRemaining;


// should be called by the weapon when after the fire mode change (e.g., switch from full- to semi-auto)
function FireModeChanged();

function PostBeginPlay()
{
    super.PostBeginPlay();
    bOldWaitForRelease = bWaitForRelease;

    if (MovementEffect <= 0) {
        if (FireRate > 0.25) {
            MovementEffect = 0.1;
        }
        else {
            MovementEffect = 0.5;
        }
    }
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local byte HitCount, PenCounter;
    local float HitDamage, HitMomentum;
    local array<int> HitPoints;
    local array<Actor> IgnoreActors;
    local KFPawn HitPawn;
    local KFMonster Zed;
    local int i;
    local bool bWasDecapitated;

    KillCountPerTrace = 0;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() ) {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
        Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    HitDamage = DamageMax;
    HitMomentum = Momentum;

    // HitCount isn't a number of max penetration. It is just to be sure we won't stuck in infinite loop
    while( ++HitCount < 127 && HitDamage >= DamageMin )
    {
        Zed = none;
        HitPawn = none;

        Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
        if( Other == none ) {
            break;
        }
        else if( Other==Instigator || Other.Base == Instigator ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
            Start = HitLocation;
            continue;
        }
        else if ( Other.bWorldGeometry || Other == Level ) {
            if( KFWeaponAttachment(Weapon.ThirdPersonActor) != None )
                KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
            break;
        }

        Zed = KFMonster(Other);
        if ( Zed != none ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
        }
        else if( ExtendedZCollision(Other) != none && Other.Owner != none ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
            Other.SetCollision(false);
            Other.Owner.SetCollision(false);
            Zed = KFMonster(Other.Owner);
        }
        else {
            HitPawn = KFPawn(Other);
        }

        if (HitPawn != none) {
            if(!HitPawn.bDeleteMe) {
                DamagePlayer(HitPawn, HitDamage, HitLocation, HitMomentum*X, HitPoints);
            }
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
            Other.SetCollision(false);
            HitPawn.AuxCollisionCylinder.SetCollision(false);
        }
        else if (Zed != none) {
            bWasDecapitated = Zed.bDecapitated;
            DamageZed(Zed, AdjustZedDamage(Zed, X, HitDamage), HitLocation, HitMomentum*X);
            if (Zed == none || Zed.Health <= 0 || (!bWasDecapitated && Zed.bDecapitated)) {
                ++KillCountPerTrace;
            }
            else if (Zed != none && PenDmgReductionByHealth > 0) {
                HitDamage *= 1.0 - PenDmgReductionByHealth * Zed.Health;
                HitMomentum *= 1.0 - PenDmgReductionByHealth * Zed.Health;
            }
        }
        else {
            Other.TakeDamage(HitDamage, Instigator, HitLocation, HitMomentum*X, DamageType);
            break;
        }

        if (++PenCounter > MaxPenetrations)
            break;

        HitDamage *= PenDmgReduction;
        HitMomentum *= PenDmgReduction;
        Start = HitLocation;
    }

    // Turn the collision back on for any actors we turned it off
    for (i = 0; i < IgnoreActors.Length; ++i) {
        if (IgnoreActors[i] != none) {
            IgnoreActors[i].SetCollision(true);
        }
    }
}

function DamagePlayer(KFPawn Victim, int Damage, vector HitLocation, vector HitMomentum, out array<int> HitPoints)
{
    Victim.ProcessLocationalDamage(Damage, Instigator, HitLocation, HitMomentum, DamageType, HitPoints);
}

function int AdjustZedDamage(KFMonster Zed, Vector ray, int Damage)
{
    return Damage;
}

function DamageZed(KFMonster Victim, int Damage, vector HitLocation, vector HitMomentum)
{
    Victim.TakeDamage(Damage, Instigator, HitLocation, HitMomentum, DamageType);
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

        if (Instigator.bIsCrouched) {
            Rec *= SpreadCrouchMod;
        }
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

// Unreliable. Always use together with the (MagAmmoRemaining == 0) check.
simulated function bool MayClientHaveAmmo()
{
    return ClientMagAmmoRemaining >= AmmoPerFire;
}

simulated function bool AllowFire()
{
    local KFPawn p;

    p = KFPawn(Instigator);

    if (KFWeap.bIsReloading || p.SecondaryItem != none || p.bThrowingNade)
        return false;

    if (Weapon.AmmoAmount(ThisModeNum) < AmmoPerFire)
        return false;

    if (KFWeap.MagAmmoRemaining < AmmoPerFire && (KFWeap.Role == ROLE_Authority || KFWeap.MagCapacity <= AmmoPerFire
            || !MayClientHaveAmmo())) {
        if (Level.TimeSeconds - LastClickTime > FireRate)
            LastClickTime = Level.TimeSeconds;

        if (AIController(Instigator.Controller) != None)
            KFWeap.ReloadMeNow();

        return false;
    }

    return true;
}

event ModeDoFire()
{
    local float Rec;
    local KFPlayerReplicationInfo KFPRI;

    if (!AllowFire())
        return;

    if (Instigator==None || Instigator.Controller==none)
        return;

    if (bOldWaitForRelease != bWaitForRelease) {
        bOldWaitForRelease = bWaitForRelease;
        FireModeChanged();
    }

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    Spread = GetSpread();

    Rec = GetFireSpeed();
    FireRate = default.FireRate/Rec;
    FireAnimRate = default.FireAnimRate*Rec;
    ReloadAnimRate = default.ReloadAnimRate*Rec;
    Rec = 1;

    if (KFPRI != none && KFPRI.ClientVeteranSkill != none){
        Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);
    }

    LastFireTime = Level.TimeSeconds;

    if (Weapon.Owner != none && !bFiringDoesntAffectMovement) {
        Weapon.Owner.Velocity.x *= MovementEffect;
        Weapon.Owner.Velocity.y *= MovementEffect;
    }

    Super(WeaponFire).ModeDoFire();

    // client
    if (Instigator.IsLocallyControlled()) {
        if (bDoClientRagdollShotFX && Weapon.Level.NetMode == NM_Client) {
            DoClientOnlyFireEffect();
        }
        HandleRecoil(Rec);
    }

    if (Weapon.Role < ROLE_Authority) {
        if (ClientMagAmmoRemaining == KFWeap.MagAmmoRemaining) {
            // MagAmmoRemaining is not replicated yet. Manually decrease it.
            ClientMagAmmoRemaining -= AmmoPerFire;
        }
        else {
            // Sync with the server. The value might be incorrect, but it's irrelevant for the AllowFire() check
            ClientMagAmmoRemaining = KFWeap.MagAmmoRemaining;
        }
    }
}

// Works only on the locally-controlled Instigator
function bool IsFireButtonPressed()
{
    if (Instigator == none || Instigator.Controller == none) return false;
    if (ThisModeNum == 0) return Instigator.Controller.bFire > 0;
    if (ThisModeNum == 0) return Instigator.Controller.bAltFire > 0;
    return false;
}

defaultproperties
{
    MaxPenetrations=0
    PenDmgReduction=0.50
    PenDmgReductionByHealth=0.0005  // zed with 100 hp remaining reduces the following damage by 5%
    DamageMin=10  // the bullet cannot over-penetrate the body if its leftover damage is lower than DamageMin
    MaxSpreadBurst=6
    MaxSpread=0.12
    SpreadAimMod=0.5
    SpreadCrouchMod=0.85
    SpreadSemiAutoMod=0.85
    SpreadResetTime=0.5
}
