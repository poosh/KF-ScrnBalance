class ToiletPaperProj extends ScrnNade;

#exec OBJ LOAD FILE=ScrnSM.usx
#exec OBJ LOAD FILE=ScrnSnd.uax
#exec OBJ LOAD FILE=ScrnTex.utx

var() int Load;
var transient float SpawnTime;
var() class<Emitter> ExplodeEffectClass;
var() Sound PickupSound;
var() Sound AddAmmoSound;
var transient bool bExploded;
var Actor IgnoreActor;


replication
{
    reliable if ( Role == ROLE_Authority && bNetDirty )
        bExploded;
}


simulated function PostBeginPlay()
{
    super(Projectile).PostBeginPlay();

    SpawnTime = Level.TimeSeconds;

    if ( Role == ROLE_Authority ) {
        RandSpin(25000);
        Velocity = Speed * Vector(Rotation);
        bCanHitOwner = false;
        if (Instigator.HeadVolume.bWaterVolume) {
            bHitWater = true;
            Velocity = 0.6*Velocity;
        }
    }
}

simulated function PostNetReceive()
{
    if( bExploded ) {
        Explode(Location, vect(0,0,1));
    }
    else if( bHidden && !bDisintegrated ) {
        Disintegrate(Location, vect(0,0,1));
    }
}

function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType,
        optional int HitIndex)
{
    Explode(HitLocation, Normal(Momentum));
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    bExploded = true;
    PlayOwnedSound(DisintegrateSound,,2.0);
    if ( EffectIsRelevant(Location,false) ) {
        Spawn(ExplodeEffectClass,,, Location, rotator(HitNormal));
    }
    Disintegrate(HitLocation, HitNormal);
}

function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
}

simulated function Disintegrate(vector HitLocation, vector HitNormal)
{
    GotoState('Disintegrating');
    if ( Role == ROLE_Authority ) {
        NetUpdateTime = Level.TimeSeconds - 1;
    }
}

simulated function Touch( Actor Other )
{
    if ( Other == IgnoreActor || ROBulletWhipAttachment(Other) != none || (Other == Instigator && Damage > 0) )
        return;

    if ( Role == ROLE_Authority && Damage == 0 && PickBy(Pawn(Other)) ) {
        return;
    }
    super.Touch(Other);
}

function bool PickBy(Pawn Other)
{
    local KFMonster Zed;
    local ToiletPaperAmmo TPAmmo;
    local bool bAddedAmmo;

    if ( Other == none || Other.Health <= 0 )
        return false;

    Zed = KFMonster(Other);
    if ( Zed != none && Zed.bDecapitated )
        return false;  // decapitated zeds cannot pick our precious

    if ( Load > 0 ) {
        TPAmmo = ToiletPaperAmmo(Other.FindInventoryType(class'ToiletPaperAmmo'));
        if ( TPAmmo != none ) {
            if ( TPAmmo.AmmoAmount >= TPAmmo.MaxAmmo )
                return false;

            bAddedAmmo = true;
            TPAmmo.AddAmmo(Load);
            Load = 0;
            PlaySound(AddAmmoSound, SLOT_Interact);
        }
    }
    if ( !bAddedAmmo )
        PlaySound(PickupSound, SLOT_Interact);
    Disintegrate(Location, vect(0,0,1));
    return true;
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
    local Vector OtherVelocity;

    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
        return;

    if ( ROBulletWhipAttachment(Other) != none )
        return;

    if ( ToiletPaperProj(Other) != none )
        return;

    // remember velocity before taking damage
    OtherVelocity = Other.Velocity;

    if ( Damage > 0 ) {
        Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    }

    HitWall( Normal(HitLocation), Other );
    Velocity += Normal(Velocity) * (Normal(Velocity) dot OtherVelocity);
    IgnoreActor = Other;
}

simulated event HitWall( vector HitNormal, actor HitWall )
{
    local Vector VNorm;

    SetPhysics(PHYS_Falling);
    Damage = 0;  // no reflective damage
    IgnoreActor = none;

    // Reflect off Wall w/damping
    VNorm = (Velocity dot HitNormal) * HitNormal;
    Velocity = -VNorm * DampenFactor + (Velocity - VNorm) * DampenFactorParallel;

    RandSpin(100000);
    Speed = VSize(Velocity);

    if ( Speed < 20 || !bBounce ) {
        bBounce = False;
        AlignToGround(false);
        Speed = 0;
        Velocity = vect(0,0,0);
        SetPhysics(PHYS_Falling);
    }
    else {
        if ( Level.NetMode != NM_DedicatedServer && Speed > 250 ) {
            if ( ImpactSound != none ) {
                PlaySound(ImpactSound, SLOT_Misc );
            }
        }
        else {
            AlignToGround(false);
        }
    }
}

simulated event Landed( vector HitNormal )
{
    GotoState('OnGround');
}

simulated function AlignToGround(bool bInstant)
{
    DesiredRotation.Pitch = 0;
    DesiredRotation.Roll = 0;
    // DesiredRotation.Pitch = 16384 * ((Rotation.Pitch + 8192) / 16384);
    // if ( DesiredRotation.Pitch > 32767 ) {
    //     DesiredRotation.Pitch -= 32768;
    // }
    bFixedRotationDir = false;
    RotationRate.Pitch = 5000;
    bRotateToDesired = true;
    if (bInstant) {
        SetRotation(DesiredRotation);
    }
}

simulated state OnGround
{
    ignores ProcessTouch;

    simulated function BeginState()
    {
        // AlignToGround(true);
        SetTimer(ExplodeTimer, false);
        Damage = 0;
        IgnoreActor = none;
        bCanHitOwner = true;
    }

    function Timer()
    {
        Explode(Location, vect(0,0,1));
    }
}

simulated state Disintegrating
{
    ignores HitWall, ProcessTouch, Landed, Explode, Disintegrate, TakeDamage, PostNetReceive;

    simulated function BeginState()
    {
        bHidden = true;
        bDisintegrated = true;
        SetCollision(false, false);

        if( Role == ROLE_Authority ) {
            // replicate disintegration to clients
            SetTimer(0.2, false);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else {
            Destroy();
        }
    }

    function Timer()
    {
        Destroy();
    }
}


defaultproperties
{
    Damage=33
    MyDamageType=class'ToiletPaperDamType'

    RotationRate=(pitch=5000,yaw=5000,roll=5000)
    Load=1
    Physics=PHYS_Falling
    Speed=300
    MaxSpeed=700
    DampenFactor=0.20
    DampenFactorParallel=0.50


    bOrientOnSlope=true
    // PrePivot gets applied before DrawScale
    PrePivot=(Z=40)
    DrawScale=0.25
    bUseCylinderCollision=true
    CollisionRadius=5
    CollisionHeight=10
    bCollideWorld=true
    bCollideActors=true
    bBlockActors=false
    bBlockZeroExtentTraces=true
    bBlockNonZeroExtentTraces=true
    bBlockHitPointTraces=true
    bProjTarget=true
    ExplodeTimer=30
    LifeSpan=60
    StaticMesh=StaticMesh'ScrnSM.TP.TP_SM'
    DrawType=DT_StaticMesh
    ImpactSound=none
    Mass=10
    ExplodeEffectClass=class'ToiletPaperExplode'
    PickupSound=Sound'KF_InventorySnd.Medkit_Pickup'
    AddAmmoSound=Sound'ScrnSnd.piece_of_candy'

    RemoteRole=ROLE_SimulatedProxy
    bNetInitialRotation=true
    bNetNotify=true
    bUpdateSimulatedPosition=true
    bSkipActorPropertyReplication=false
    bReplicateMovement=true
    bNetTemporary=false  // Need to be false, otherwise no replication will happen after the spawn

    bUnlit=false
    bAcceptsProjectors=true
    AmbientGlow=0
}
