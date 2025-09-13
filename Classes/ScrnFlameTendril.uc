//=============================================================================
// Flame
//=============================================================================
class ScrnFlameTendril extends FlameTendril;

var class<Emitter> FlameTrailClass;
var class<xEmitter> TrailClass;
var class<Emitter> GroundFireClass;

simulated function PostBeginPlay()
{
    SetTimer(0.2, true);

    Velocity = Speed * Vector(Rotation);

    if (Level.NetMode != NM_DedicatedServer) {
        if (!PhysicsVolume.bWaterVolume) {
            FlameTrail = Spawn(FlameTrailClass, self);
            Trail = Spawn(TrailClass, self);
        }
    }

    Velocity.z += TossZ;
}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;
    local KFMonster KFMonsterVictim;


    if ( bHurtEntry )
        return;

    bHurtEntry = true;
    foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
    {
        KFMonsterVictim = none; //tbs

        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
        {
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;

            KFMonsterVictim = KFMonster(Victims);

            if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
            {
                KFMonsterVictim = none;
            }

            if ( KFMonsterVictim != none && class'ScrnBalance'.default.Mut.BurnMech != none) {
                class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                    KFMonsterVictim,
                    damageScale * DamageAmount,
                    Instigator,
                    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                    (damageScale * Momentum * dir),
                    DamageType
                );
            }
            else {
                Victims.TakeDamage
                (
                    damageScale * DamageAmount,
                    Instigator,
                    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                    (damageScale * Momentum * dir),
                    DamageType
                );
            };
            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        }
    }
    /*
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
    {
        Victims = LastTouched;
        LastTouched = None;
        dir = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dir));
        dir = dir/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
        if ( Instigator == None || Instigator.Controller == None )
            Victims.SetDelayedDamageInstigatorController(InstigatorController);
        Victims.TakeDamage
        (
            damageScale * DamageAmount,
            Instigator,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
            (damageScale * Momentum * dir),
            DamageType
        );
        if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
    }
    */

    bHurtEntry = false;
}

simulated function Explode(vector HitLocation,vector HitNormal) {
    if ( Role == ROLE_Authority ) {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }

    if (KFHumanPawn(Instigator) != none && EffectIsRelevant(Location, false)) {
        Spawn(ExplosionDecal, self,, Location, rotator(-HitNormal));
        Spawn(GroundFireClass, self,, Location);
    }

    SetCollisionSize(0.0, 0.0);
    Destroy();
}


defaultproperties
{
    FlameTrailClass=class'ScrnFlameThrowerFlameB'
    TrailClass=class'FlameThrowerFlame'
    GroundFireClass=class'ScrnFuelFlame'
}
