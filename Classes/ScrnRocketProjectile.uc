class ScrnRocketProjectile extends LAWProj;

var class<ScrnExplosiveFunc> Func;
var class<Emitter> ExplosionClass;
var class<PanzerfaustTrail> SmokeTrailClass;
var class<Emitter> TracerClass;
var Emitter Tracer;

var string ImpactSoundRef;

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
    if( damageType == class'SirenScreamDamage')
    {
        // disable disintegration by dead Siren scream
        if ( InstigatedBy != none && InstigatedBy.Health > 0 )
            Disintegrate(HitLocation, vect(0,0,1));
    }
    else if ( !bDud && Damage >= 200 ) {
        if ( (VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))
            Disintegrate(HitLocation, vect(0,0,1));
        else
            Explode(HitLocation, vect(0,0,0));
    }
}

// overrided to add ExplosionClass
simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController  LocalPlayer;

    bHasExploded = True;

    // Don't explode if this is a dud
    if( bDud )
    {
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }


    PlaySound(ExplosionSound,,2.0);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(ExplosionClass,,,HitLocation + HitNormal*20,rotator(HitNormal));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    BlowUp(HitLocation);
    Destroy();

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local Vector X;

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
            Other.TakeDamage( ImpactDamage, Instigator, HitLocation, X, ImpactDamageType );
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
    Func=class'ScrnExplosiveFunc'
    ExplosionClass=class'ScrnLawExplosion'
    Damage=1000.000000
    ImpactDamage=350
    //adds light to projectile
    LightType=LT_Steady
    LightBrightness=128.0 //128
    LightRadius=6
    LightHue=25
    LightSaturation=100
    LightCone=16
    bDynamicLight=True
}
