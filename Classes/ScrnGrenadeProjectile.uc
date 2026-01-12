class ScrnGrenadeProjectile extends M79GrenadeProjectile;

var class<ScrnExplosiveFunc> Func;
var class<Emitter> ExplosionClass;
var float ExplosionSoundVolume;
var class<PanzerfaustTrail> SmokeTrailClass;
var class<Emitter> TracerClass;
var Emitter Tracer;
var string ImpactSoundRef;

// allow double damage bug/feature when hitting ExtendedZCollision
var bool bDoubleDamageOnImpact;
var int Health;

var transient bool bBegunPlay;

static function PreloadAssets()
{
    super.PreloadAssets();

    if (default.ImpactSoundRef != "")
        default.ImpactSound = sound(DynamicLoadObject(default.ImpactSoundRef, class'Sound', true));
}

static function bool UnloadAssets()
{
    default.ImpactSound = none;
    return super.UnloadAssets();
}

simulated function PostBeginPlay()
{
    local rotator SmokeRotation;

    bBegunPlay = true;
    if (Role == ROLE_Authority && (bHasExploded || bDud)) {
        // Set a delayed destroy.
        // If we destroy the projectile in PostBeginPlay(),
        // BaseProjectileFire.SpawnProjectile() receives none, thinks the spawn failed and spawns
        // another one via ForceSpawnProjectile()
        SetTimer(0.01, false);
    }

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

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    if (Level.NetMode == NM_DedicatedServer || !bDynamicLight)
        return;

    if (Level.bDropDetail || Level.DetailMode == DM_Low) {
        bDynamicLight = false;
        LightType = LT_None;
        return;
    }
}

//don't blow up on minor damage
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if (bDisintegrated || bDud || bHasExploded)
        return;

    Health -= Damage;
    if (damageType == class'SirenScreamDamage') {
        // disable disintegration by dead Siren scream
        if (InstigatedBy != none && InstigatedBy.Health > 0)
            Disintegrate(HitLocation, vect(0,0,1));
    }
    else if (Health <= 0) {
        if ( (VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))
            Disintegrate(HitLocation, vect(0,0,1));
        else
            Explode(HitLocation, vect(0,0,0));
    }
}

// At a point-blank range, ProcessTouch may trigger during BeginPlay(), i.e. before PostBeginPlay()
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local Vector X;

    // Don't let it hit this player, or blow up on another player
    if (bDud || bHasExploded || Other == none || Other == Instigator || Other.Base == Instigator
            || !Other.bBlockHitPointTraces || Other.IsA('KFBulletWhipAttachment'))
        return;

    if (class'ScrnBalance'.default.Mut.bProjIgnoreHuman && ScrnHumanPawn(Other) != none)
        return;  // the game mode allows projectiles flying through human bodies

    X = Vector(Rotation);

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if (Role < ROLE_Authority && Instigator != none)
        OrigLoc = Instigator.Location;

    if (ArmDistSquared > 0 && ((Role == ROLE_Authority && !bBegunPlay)
            || VSizeSquared(Location - OrigLoc) < ArmDistSquared)) {
        if (Role == ROLE_Authority) {
            AmbientSound=none;
            PlaySound(Sound'ProjectileSounds.PTRD_deflect04',,2.0);
            Other.TakeDamage(ImpactDamage, Instigator, HitLocation, X, ImpactDamageType);
        }

        bDud = true;
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }

    if (!bDud) {
       Explode(HitLocation,Normal(HitLocation-Other.Location));
    }
}

simulated function ProcessExplosionFX(Emitter Explosion);

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController LocalPlayer;
    local Emitter Explosion;

    if (bHasExploded)
        return;
    bHasExploded = True;

    // Don't explode if this is a dud
    if (bDud) {
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
        return;
    }

    PlaySound(ExplosionSound,,ExplosionSoundVolume);
    if (EffectIsRelevant(Location,false)) {
        if (ExplosionClass != none) {
            Explosion = Spawn(ExplosionClass,,,HitLocation + HitNormal*20,rotator(HitNormal));
            if (Explosion != none) {
                ProcessExplosionFX(Explosion);
            }
        }
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    BlowUp(HitLocation);

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ((LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius)) {
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
    }

    for (C=Level.ControllerList; C != none; C = C.NextController)  {
        if (C.bIsPlayer && PlayerController(C) != none && C != LocalPlayer
                && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius)) {
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
        }
    }

    if (bBegunPlay || Role < ROLE_Authority) {
        Destroy();
    }
}

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
    local int NumKilled;
    if ( bHurtEntry )
        return;

    if (!bDoubleDamageOnImpact) {
        LastTouched = none;
    }
    NumKilled = Func.static.HurtRadius(self, DamageAmount, DamageRadius, DamageType, Momentum, HitLocation, true);

    if (NumKilled >= 2 && Role == ROLE_Authority && ScrnGameType(Level.Game) == none) {
        // legacy code for multikills. ScrnGameType handles ZT in its own way.
        KFGameType(Level.Game).DramaticEvent(0.03 + NumKilled);
    }
}


defaultproperties
{
    Func=class'ScrnExplosiveFunc'
    SmokeTrailClass=class'ReducedGrenadeTrail'
    ExplosionClass=class'KFMod.KFNadeLExplosion'
    ExplosionSoundVolume=2.0
    Health=150
    bDoubleDamageOnImpact=True
}
