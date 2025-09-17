class ScrnGrenadeProjectile extends M79GrenadeProjectile;

var class<ScrnExplosiveFunc> Func;
var class<PanzerfaustTrail> SmokeTrailClass;
var class<Emitter> TracerClass;
var Emitter Tracer;

var transient bool bBegunPlay;

simulated function PostBeginPlay()
{
    local rotator SmokeRotation;

    bBegunPlay = true;
    BCInverse = 1 / BallisticCoefficient;

    if (Level.NetMode != NM_DedicatedServer) {
        if (SmokeTrailClass != none) {
            SmokeTrail = Spawn(SmokeTrailClass, self);
            SmokeTrail.SetBase(self);
            SmokeRotation.Pitch = 32768;
            SmokeTrail.SetRelativeRotation(SmokeRotation);
        }
        if (TracerClass != none) {
            Tracer = Spawn(TracerClass, self);
        }
    }

    OrigLoc = Location;

    if (!bDud) {
        Dir = vector(Rotation);
        Velocity = speed * Dir;
        Velocity.Z += TossZ;
    }

    if (PhysicsVolume.bWaterVolume) {
        bHitWater = True;
        Velocity=0.6*Velocity;
    }
    super(Projectile).PostBeginPlay();
}

simulated function Destroyed()
{
    if (Tracer != none && !Tracer.bDeleteMe) {
        Tracer.Destroy();
    }
    Super.Destroyed();
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local vector X;

    // Don't let it hit this player, or blow up on another player
    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces )
        return;

    // Don't collide with bullet whip attachments
    if( KFBulletWhipAttachment(Other) != none )
    {
        return;
    }

    // Don't allow hits on people on the same team - except hardcore mode
    if( !class'ScrnBalance'.default.Mut.bHardcore && KFPawn(Other) != none && Instigator != none
            && KFPawn(Other).GetTeamNum() == Instigator.GetTeamNum() )
    {
        return;
    }

    X = Vector(Rotation);

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if( Instigator != none )
    {
        OrigLoc = Instigator.Location;
    }

    if( !bDud && ((VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0)) )
    {
        if( Role == ROLE_Authority )
        {
            AmbientSound=none;
            PlaySound(Sound'ProjectileSounds.PTRD_deflect04',,2.0);
            Other.TakeDamage(ImpactDamage, Instigator, HitLocation, X, ImpactDamageType);
        }
        bDud = true;
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }

    if( !bDud )
    {
       Explode(HitLocation,Normal(HitLocation-Other.Location));
    }
}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
    local int NumKilled;
    if ( bHurtEntry )
        return;

    NumKilled = Func.static.HurtRadius(self, DamageAmount, DamageRadius, DamageType, Momentum, HitLocation, true);

    if (NumKilled >= 2 && Role == ROLE_Authority && ScrnGameType(Level.Game) == none) {
        // legacy code for multikills. ScrnGameType handles ZT in its own way.
        KFGameType(Level.Game).DramaticEvent(0.03 + NumKilled);
    }
}


defaultproperties
{
    SmokeTrailClass=class'ReducedGrenadeTrail'
    Func=class'ScrnExplosiveFunc'
}
