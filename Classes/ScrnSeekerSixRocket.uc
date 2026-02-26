class ScrnSeekerSixRocket extends ScrnRocketProjectile;

// That's retarded and should be converted into a SoundGroup.
var array<string> AltAmbientSoundRefs;
var array<Sound> AltAmbientSounds;

// XXX: Should we move it to the parent class?
var class<xEmitter> xSmokeClass;
var class<xEmitter> xTrailClass;
var xEmitter xSmoke;
var xEmitter xTrail;

var Actor SeekTarget;
var float SeekForce, SeekAccel;

replication
{
    reliable if (bNetInitial && Role == ROLE_Authority)
        SeekTarget;
}


static function PreloadAssets()
{
    local int i;

    super.PreloadAssets();

    default.AltAmbientSounds.Length = default.AltAmbientSoundRefs.Length;
    for (i = 0; i < default.AltAmbientSoundRefs.Length; ++i) {
        default.AltAmbientSounds[i] = sound(DynamicLoadObject(default.AltAmbientSoundRefs[i], class'Sound', true));
    }
}

static function bool UnloadAssets()
{
    default.AltAmbientSounds.Length = 0;
    return super.UnloadAssets();
}

simulated function PostBeginPlay()
{
    local int i;

    super.PostBeginPlay();

    i = rand(AltAmbientSounds.Length + 1);
    if (i < AltAmbientSounds.Length) {
        AmbientSound = AltAmbientSounds[i];
    }

    if (Level.NetMode != NM_DedicatedServer) {
        if (xSmokeClass != none) {
            xSmoke = Spawn(xSmokeClass, self);
        }
        if (xTrailClass != none) {
            xTrail = Spawn(xTrailClass, self);
        }
    }

    SetTimer(0.1, true);
}

simulated function Destroyed()
{
    if (xSmoke != none) {
        xSmoke.mRegen = false;
        xSmoke.SetPhysics(PHYS_None);
        xSmoke.GotoState('');
    }
    if (xTrail != none) {
        xTrail.mRegen = false;
        xTrail.SetPhysics(PHYS_None);
        xTrail.GotoState('');
    }

    Super.Destroyed();
}

simulated function Timer()
{
    local vector ForceDir, TargetLoc;
    local float VelMag;

    if (bHidden) {
        Super.Timer();
        return;
    }

    if (SeekTarget != None && SeekTarget != Instigator) {
        TargetLoc = SeekTarget.Location;
        if (KFMonster(SeekTarget) != none) {
            TargetLoc.Z += KFMonster(SeekTarget).OnlineHeadshotOffset.Z;
        }

        // Do normal guidance to target.
        ForceDir = Normal(TargetLoc - Location);

        if ((ForceDir Dot Dir) > 0) {
            VelMag = VSize(Velocity);
            ForceDir = Normal(ForceDir * SeekForce * VelMag + Velocity);
            Velocity =  VelMag * ForceDir;
            Acceleration += SeekAccel * ForceDir;
        }
        else {
            // overshot, no turning back;
            Acceleration = vect(0,0,0);
            SeekTarget = none;
        }
        // Update rocket so it faces in the direction its going.
        SetRotation(rotator(Velocity));
    }
}


defaultproperties
{
    Health=100
    ArmDistSquared=22500
    Damage=130 // 100
    DamageRadius=200
    MyDamageType=class'ScrnDamTypeSeekerSixRocket'
    ImpactDamage=75
    ImpactDamageType=Class'KFMod.DamTypeSeekerRocketImpact'
    Speed=2000
    MaxSpeed=2000
    SeekForce=0.8
    SeekAccel=5.0

    StaticMeshRef="KF_IJC_Halloween_Weps2.seeker6_projectile"
    DrawScale=2.5
    RotationRate=(Roll=50000)
    SmokeTrailClass=none
    TracerClass=none
    xSmokeClass=class'SeekerSixRocketSmokeX'
    xTrailClass=class'SeekerSixRocketTrailX'
    AmbientSoundRef="KF_FY_SeekerSixSND.WEP_Seeker_Rocket_LP"
    AltAmbientSoundRefs[0]="KF_FY_SeekerSixSND.WEP_Seeker_Rocket_LP_02"
    AltAmbientSoundRefs[1]="KF_FY_SeekerSixSND.WEP_Seeker_Rocket_LP_03"
    ExplosionSoundRef="KF_FY_SeekerSixSND.WEP_Seeker_Explode"
    ExplosionDecal=Class'FlameThrowerBurnMark_Medium'
    ExplosionClass=class'SeekerSixExplosionEmitter'
}
