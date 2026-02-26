class ScrnSPGrenadeProjectile extends ScrnGrenadeProjectile;


var float DampenFactor, DampenFactorParallel;  // How much to dampen the velocity of the bomb with each bounce
var float ExplodeTimer;  // How long this bomb will wait to explode

var class<Emitter> SmokeTrailEmitterClass;
var Emitter SmokeTrailEmitter;  // the original SmokeTrail's type is PanzerfaustTrail. Cannot use regular emitters


simulated function PostBeginPlay()
{
    SetTimer(ExplodeTimer, false);

    super.PostBeginPlay();

    if (Level.NetMode != NM_DedicatedServer) {
        if (!PhysicsVolume.bWaterVolume) {
            SmokeTrailEmitter = Spawn(SmokeTrailEmitterClass, self);
        }
    }
}

simulated function Destroyed()
{
    if (SmokeTrailEmitter != none) {
        SmokeTrailEmitter.Kill();
        SmokeTrailEmitter.SetPhysics(PHYS_None);
    }

    Super.Destroyed();
}

function Timer()
{
    if (!bHasExploded) {
        Explode(Location, vect(0,0,1));
    }
    else {
        Destroy();
    }
}

simulated function HitWall(vector HitNormal, actor Wall)
{
    local Vector VNorm;

    if( Instigator != none ){
        OrigLoc = Instigator.Location;
    }

    if (Pawn(Wall) != none || DestroyableObjective(Wall) != none || GameObject(Wall) != none) {
        Explode(Location, HitNormal);
        return;
    }

    ArmDistSquared = 0;  // always explode after bounce

    // Reflect off Wall w/damping
    VNorm = (Velocity dot HitNormal) * HitNormal;
    Velocity = -VNorm * DampenFactor + (Velocity - VNorm) * DampenFactorParallel;

    Speed = VSize(Velocity);

    if (Speed < 20) {
        bBounce = False;
        SetPhysics(PHYS_None);
        DesiredRotation = Rotation;
        DesiredRotation.Roll = 0;
        DesiredRotation.Pitch = 0;
        SetRotation(DesiredRotation);
    }
    else if (Level.NetMode != NM_DedicatedServer && Speed > 250) {
        PlaySound(ImpactSound, SLOT_Misc );
    }
}

simulated function Landed(vector HitNormal)
{
    HitWall(HitNormal, None);
}

simulated function Tick(float dt)
{
    super.Tick(dt);

    SetRotation(Rotator(Normal(Velocity)));
}

defaultproperties
{
    Func=class'ScrnExplosiveFunc_Nade'
    ImpactDamageType=Class'KFMod.DamTypeSPGrenadeImpact'
    ImpactDamage=200
    MyDamageType=Class'KFMod.DamTypeSPGrenade'
    Damage=325
    DamageRadius=350
    ArmDistSquared=40000

    Speed=1000
    MaxSpeed=1500
    TossZ=150
    bInitialAcceleration=False
    bTrueBallistics=False

    bBounce=True
    DampenFactor=0.5
    DampenFactorParallel=0.80
    ExplodeTimer=2.5
    LifeSpan=10.0

    StaticMeshRef="KF_IJC_Summer_Weps.SPGrenade_proj"
    DrawType=DT_StaticMesh
    DrawScale=2.0
    SmokeTrailClass=none  // we use SmokeTrailEmitterClass instead
    SmokeTrailEmitterClass=Class'KFMod.SPGrenadeTrail'
    ExplosionClass=Class'KFMod.SPGrenadeExplosion'

    LightType=LT_Steady
    LightHue=21
    LightSaturation=64
    LightBrightness=128.000000
    LightRadius=4.000000
    LightCone=16
    bDynamicLight=True
    bUnlit=False

    ExplosionSoundRef="KF_GrenadeSnd.Nade_Explode_1"
    DisintegrateSoundRef="Inf_Weapons.faust_explode_distant02"
    ImpactSoundRef="KF_GrenadeSnd.Nade_HitSurf"
    AmbientSoundRef="KF_IJC_HalloweenSnd.KF_FlarePistol_Projectile_Loop"
    AmbientVolumeScale=2.000000
    SoundVolume=255
    SoundRadius=250.000000
    TransientSoundVolume=2.000000
    TransientSoundRadius=500.000000

    RemoteRole=ROLE_SimulatedProxy
    bNetInitialRotation=true
    //bOrientToVelocity=true
    bNetNotify=true
    bUpdateSimulatedPosition=true
    bSkipActorPropertyReplication=false
    bNetTemporary=false  // Need to be false, otherwise no replication will happen after the spawn
}