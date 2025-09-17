class ScrnExplosiveFunc extends Object abstract;

static function int HurtRadius(Projectile Proj, float Damage, float DamageRadius, class<DamageType> DamageType,
        float MomentumScale, vector HitLocation, bool bCheckExposure)
{
    local int NumKilled;
    local Actor Victim;
    local float DamScale, dist;
    local vector dir;

    if (Damage < 1.0)
        return 0;
    if (Proj.bHurtEntry)
        return 0;
    Proj.bHurtEntry = true;

    NumKilled = 0;

    foreach Proj.CollidingActors(class'Actor', Victim, DamageRadius, HitLocation) {
        if (Victim.bStatic || Victim.Role != ROLE_Authority || Victim == Proj || Victim == Proj.LastTouched
                || Victim == Proj.Hurtwall || Victim.IsA('FluidSurfaceInfo') || Victim.IsA('ExtendedZCollision'))
            continue;

        dir = Victim.Location - HitLocation;
        dist = FMax(1.0, VSize(dir));
        dir = dir/dist;
        DamScale = 1 - FMax(0, (dist - Victim.CollisionRadius - Proj.CollisionRadius) / DamageRadius);

        if (HurtVictim(Proj, Victim, Damage * DamScale,
                Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * dir,
                DamScale * MomentumScale * dir, DamageType, bCheckExposure, HitLocation)) {
            ++NumKilled;
        }
    }

    // The bug that has turned into a feature. LastTouched is not checked against ExtendedZCollision, allowing damaging
    // big zeds twise when hit into the upper body.
    Victim = Proj.LastTouched;
    if (Victim != none && !Victim.bStatic && Victim != Proj && Victim.Role == ROLE_Authority
            && !Victim.IsA('FluidSurfaceInfo')) {
        dir = normal(Victim.Location - HitLocation);
        // deal full damage to the target directly hit by the projectile
        if (HurtVictim(Proj, Victim, Damage,
                Victim.Location - 0.5 * (Victim.CollisionHeight + Victim.CollisionRadius) * dir,
                MomentumScale * dir, DamageType, false)) {
            ++NumKilled;
        }
    }

    Proj.bHurtEntry = false;
    return NumKilled;
}

static function bool HurtVictim(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType, bool bCheckExposure, optional vector ExposureLocation)
{
    local float DamScale;
    local Pawn P;
    local class<Pawn> PawnClass;
    local KFMonster Zed;
    local bool bWasDead;

    bWasDead = true;
    DamScale = 1.0;
    P = Pawn(Victim);
    if (P != none) {
        bWasDead = P.Health <= 0;
        PawnClass = P.class;
        Zed = KFMonster(Victim);
        if (Zed != none) {
            if (bCheckExposure)
                DamScale *=Zed.GetExposureTo(ExposureLocation);
            ScaleZedDamage(Proj, Zed, HitLocation, DamScale);
        }
        else if (KFPawn(Victim) != none) {
            if (Proj.Instigator == none || Proj.Instigator.Health <=0)
                return false;  // prevent disconnected players from killing teammates
            if (bCheckExposure)
                DamScale *= KFPawn(Victim).GetExposureTo(ExposureLocation);
            ScaleHumanDamage(Proj, KFPawn(Victim), HitLocation, DamScale);
        }
    }
    else if (bCheckExposure && !Proj.FastTrace(Victim.Location, Proj.Location)) {
        return false;
    }

    Damage *= DamScale;
    if (Damage <= 0)
        return false;

    if (Proj.Instigator == none || Proj.Instigator.Controller == none)
        Victim.SetDelayedDamageInstigatorController(Proj.InstigatorController);

    DealDamage(Proj, Victim, Damage, HitLocation, Momentum, DamageType);

    if (Vehicle(Victim) != None && Vehicle(Victim).Health > 0) {
        Vehicle(Victim).DriverRadiusDamage(Damage, Proj.DamageRadius, Proj.InstigatorController, DamageType,
                VSize(Momentum), HitLocation);
    }

    if (bWasDead || (P != none && P.Health > 0))
        return false;

    Killed(Proj, PawnClass);
    return true;
}

static function ScaleZedDamage(Projectile Proj, KFMonster Zed, vector HitLocation, out float DamScale);
static function ScaleHumanDamage(Projectile Proj, KFPawn Human, vector HitLocation, out float DamScale);

static function DealDamage(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType)
{
    Victim.TakeDamage(Damage, Proj.Instigator, HitLocation, Momentum, DamageType);
}

static function Killed(Projectile Proj, class<Pawn> KilledClass);
