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

// DoTrace is called server-side only from DoFireEffect()
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

    if (Other != none) {
        HitFX(Other, HitLocation, HitNormal);
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
    local float NewRecoilSpeed;
    local KFPlayerController KFPC;
    local KFPawn P;
    local vector HorzVelocity;
    local float HorzSpeed;

    if (Instigator == none)
        return;

    KFPC = KFPlayerController(Instigator.Controller);
    P = KFPawn(Instigator);

    if (KFPC == none || P == none)
        return;

    if (KFPC.bFreeCamera || !bIsFiring)
        return;

    if (Instigator.bIsCrouched)
        Rec *= SpreadCrouchMod;

    NewRecoilRotation.Pitch = RandRange(maxVerticalRecoilAngle * 0.5, maxVerticalRecoilAngle);
    NewRecoilRotation.Yaw = RandRange(maxHorizontalRecoilAngle * 0.5, maxHorizontalRecoilAngle);

    if (!bRecoilRightOnly && Rand(2) == 1)
        NewRecoilRotation.Yaw *= -1;

    if (RecoilVelocityScale > 0 && abs(P.Velocity.X) + abs(P.Velocity.Y) > 50) {
        HorzVelocity = P.Velocity;
        HorzVelocity.Z = 0;
        HorzSpeed = VSize(HorzVelocity);

        if (P.Physics == PHYS_Falling) {
            // Reduce recoil while falling
            HorzSpeed = fmin(HorzSpeed, P.GroundSpeed);
            HorzSpeed *= 0.5;
        }

        NewRecoilRotation.Pitch += HorzSpeed * RecoilVelocityScale;
        NewRecoilRotation.Yaw += HorzSpeed * RecoilVelocityScale;
    }

    NewRecoilRotation *= Rec;
    NewRecoilSpeed = RecoilRate / (default.FireRate / FireRate);
    KFPC.SetRecoil(NewRecoilRotation, NewRecoilSpeed);
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

    if (KFWeap.bIsReloading && !KFWeap.bHoldToReload)
        return false;

    if (p.SecondaryItem != none || p.bThrowingNade)
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

function ModeTick(float dt)
{
    super.ModeTick(dt);

    if (bIsFiring && Weapon.ROLE < Role_Authority) {
        CheckAttachment();
    }
}

function HitFX(Actor HitActor, vector HitLocation, vector HitNormal)
{
    local KFWeaponAttachment WA;

    // XXX: The original InstantFire doesn't trigger UpdateHit on hitting Pawns. Investigate why?

    WA = KFWeaponAttachment(Weapon.ThirdPersonActor);
    if (WA == none)
        return;

    // Only HitLocation is replicated to the client (weapon owner).
    // HitActor and HitNormal are estimated in KFWeaponAttachment.ThirdPersonEffects() after SpawnHitCount update.
    WA.UpdateHit(HitActor, HitLocation, HitNormal);
}

// Fixed the bug where Tracer is spawned only on weapon fire release.
// For non-owner clients, WeaponAttachment.ThirdPersonEffects() is called on FlashCount update.
// The weapon owner calls WeaponAttachment.ThirdPersonEffects() from IncrementFlashCount(), which, in turn,
// is called from WeponFire.ModeDoFire().
// When the "WeponFire.ModeDoFire() => Weapon.IncrementFlashCount() => WeaponAttachment.ThirdPersonEffects()" chain
// is called on the client, WeaponAttachment.SpawnHitCount and mHitLocation might not be replicated yet, and
// "OldSpawnHitCount != SpawnHitCount" check in KFWeaponAttachment.ThirdPersonEffects() fails.
// When the client finally receives SpawnHitCount, ThirdPersonEffects() is not called because Mr. (c) 20099 was too
// busy choosing which car to drive rather than writing good code.
//
// The ultimate solution is to call ThirdPersonEffects() from KFWeaponAttachment.PostNetReceive() when
// SpawnHitCount != OldSpawnHitCount.
function CheckAttachment()
{
    local KFWeaponAttachment WA;

    WA = KFWeaponAttachment(Weapon.ThirdPersonActor);
    if (WA != none && WA.SpawnHitCount != WA.OldSpawnHitCount) {
        WA.ThirdPersonEffects();
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
    RecoilVelocityScale=1.5
}
