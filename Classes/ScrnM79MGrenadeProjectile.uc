class ScrnM79MGrenadeProjectile extends ScrnM79GrenadeProjectile;

#exec OBJ LOAD FILE=KF_GrenadeSnd.uax
#exec OBJ LOAD FILE=Inf_WeaponsTwo.uax
#exec OBJ LOAD FILE=KF_LAWSnd.uax

var bool                    bHealing;       // nade is currently healing
var transient int           TotalHeals;     // The total number of times this nade has healed
var() int                   MaxHeals;       // The total number of times this nade will heal until its done healing
var() float                 HealTimer;      // How often to do healing

var transient int           HealedHP;   //total amount of HP restored to players
var transient array<Pawn>   HealedPlayers;

var transient KFWeapon      InstigatorWeapon;

var Emitter GreenCloud;
var class<Emitter> GreenCloudClass;
var Sound HealingSound;

var Rotator  IntitialRotationAdjustment; // used to rotate nade in a proper direction

var() float DampenFactor, DampenFactorParallel;

replication
{
    reliable if ( Role==ROLE_Authority && (bNetInitial || bNetDirty) )
        bHealing;
}

simulated function PostNetReceive()
{
    if (Role == ROLE_Authority)
        return; // just to be sure

    // sync states with server based on flags
    if( bHidden ) {
        if ( !bDisintegrated ) {
            GoToState('Disintegrating');
        }
    }
    else if ( bHealing ) {
        if ( !bHasExploded ) {
            GoToState('Healing');
        }
    }
    else if ( bDud ) {
        if ( !bOutOfPropellant ) {
            GoToState('Dropping');
        }
    }
}


//overrided to disable smoke trail
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( SmokeTrail != none )
        SmokeTrail.SetRelativeRotation(rot(32768,0,0));

    if ( Instigator != none)
        InstigatorWeapon = KFWeapon(Instigator.Weapon);
}

simulated function PostNetBeginPlay()
{
    if ( Role < ROLE_Authority ) {
        PostNetReceive();
    }
}

function Timer()
{
}

simulated function Tick( float DeltaTime )
{
    SetRotation(IntitialRotationAdjustment + Rotator(Normal(Velocity)));

    if ( bHealing && !bHasExploded && Role < ROLE_Authority ) {
        GoToState('Healing');
    }
}

simulated function Disintegrate(vector HitLocation, vector HitNormal)
{
    if ( !bDisintegrated )
        GoToState('Disintegrating');
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    if ( !bHasExploded )
        GotoState('Healing');
}

function BlowUp(vector HitLocation)
{
    MakeNoise(1.0);
}

simulated function Destroyed()
{
    StopFX();
    Super(Projectile).Destroyed();
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if( damageType == class'SirenScreamDamage' )
    {
        Disintegrate(HitLocation, vect(0,0,1));
    }
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
    local vector X;

    // Don't let it hit this player, or blow up on another player
    if ( Other == none || Other == Instigator || Other.Base == Instigator )
        return;

    // Don't collide with bullet whip attachments
    if( KFBulletWhipAttachment(Other) != none )
        return;

    if (bBegunPlay) {
        X = Normal(Velocity);
    }
    else {
        // touch on spawn; PostBeginPlay() hasn't been called yet, and, therefore, Velocity is not set
        X = Vector(Rotation);
    }

    Other.TakeDamage(ImpactDamage, Instigator, HitLocation, X, ImpactDamageType);

    // more realistic interactions with karma objects.
    if (Other.IsA('NetKActor')) {
        KAddImpulse(Velocity,HitLocation);
        return;
    }

    Speed = 0;
    Velocity = vect(0,0,0);
    SetPhysics(PHYS_Falling);
    GotoState('Dropping');
}

simulated function HitWall( vector HitNormal, actor Wall )
{
    local Vector VNorm;

    if ( ROBulletWhipAttachment(Wall) != none )
        return; // don't collide with this shit, cuz it is on server side only and screws clients

    // Reflect off Wall w/damping
    VNorm = (Velocity dot HitNormal) * HitNormal;
    Velocity = -VNorm * DampenFactor + (Velocity - VNorm) * DampenFactorParallel;
    Speed = VSize(Velocity);
    ImpactDamage *= DampenFactor;
    SetPhysics(PHYS_Falling);
    GotoState('FallingDown');
}

simulated function Landed( vector HitNormal )
{
    GotoState('Healing');
}

function HealRadius(float HealAmount, float HealRadius, vector HealLocation)
{
    local KFHumanPawn Victim;
    local ScrnHumanPawn ScrnVictim;
    // Healing
    local KFPlayerReplicationInfo KFPRI;
    local float HealSum; // for modifying based on perks
    local float HealPotency;

    if ( bHurtEntry )
        return;
    bHurtEntry = true;

    HealPotency = 1.0;
    // raise it half a meter to be sure it doesn't stuck inside a floor like bugged pipes
    HealLocation.Z = HealLocation.Z + 25;

    if ( Instigator != none )
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if (KFPRI != none && KFPRI.ClientVeteranSkill != none) {
        HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);
    }
    HealSum = HealAmount * HealPotency;

    foreach CollidingActors(class'KFHumanPawn', Victim, HealRadius, HealLocation) {
        if( Victim.Health <= 0 || Victim.Health >= Victim.HealthMax )
            continue;

        ScrnVictim = ScrnHumanPawn(Victim);

        if (ScrnVictim != none) {
            if (ScrnVictim.TakeHealing(ScrnVictim, HealSum, HealPotency, InstigatorWeapon)) {
                HealedHP += ScrnVictim.LastHealAmount;
                class'ScrnFunctions'.static.ObjAddUnique(HealedPlayers, Victim);
            }
        }
        else {
            Victim.GiveHealth(HealSum, Victim.HealthMax);
        }
    }
    bHurtEntry = false;
}

function SuccessfulHealAchievements()
{
    if ( HealedPlayers.Length >= 4 && Instigator != none )
        class'ScrnAchCtrl'.static.Ach2Pawn(Instigator, 'ExplosionLove', 1);
}

function SuccessfulHealMessage()
{
    if ( ScrnM79M(InstigatorWeapon) != none )
        ScrnM79M(InstigatorWeapon).ClientSuccessfulHeal(HealedPlayers.length, HealedHP);
}

simulated function StopFX()
{
    AmbientSound = none;

    if ( SmokeTrail != None )
        SmokeTrail.Kill();
    if ( GreenCloud != none )
        GreenCloud.Kill();
}


auto simulated state Flying
{
    simulated function EndState()
    {
        bOutOfPropellant = true;
        bDud = true;
    }
}

simulated state FallingDown
{
    simulated function BeginState()
    {
        SetPhysics(PHYS_Falling);
    }
}

simulated state Dropping extends FallingDown
{
    ignores HitWall, ProcessTouch, Tick;
}

simulated state Healing
{
    ignores HitWall, ProcessTouch, Landed, Explode;

    simulated function BeginState()
    {
        local rotator R;
        // turn on actor property replication to set the correct position of the healing grenade
        // actually it is ugly - nade teleports half a meter away from target due to lag. Rolling back...
        // bSkipActorPropertyReplication = false;
        // bUpdateSimulatedPosition = true;

        bHealing = true;
        bHasExploded = true;
        Speed = 0;
        Velocity = Vect(0,0,0);
        SetPhysics(PHYS_None);
        // land on the ground, keep yaw
        R = IntitialRotationAdjustment;
        R.Yaw = Rotation.Yaw;
        SetRotation(R);

        BlowUp(Location);
        PlaySound(ExplosionSound,,TransientSoundVolume);
        AmbientSound = HealingSound;

        if ( Level.NetMode != NM_DedicatedServer ) {
            GreenCloud = Spawn(GreenCloudClass,self,, Location, rotator(vect(0,0,1)));
            GreenCloud.SetBase(self);
            Spawn(ExplosionDecal,self,,Location, rotator(vect(0,0,-1)));
        }

        if ( SmokeTrail != none ) {
            SmokeTrail.SetRelativeRotation(Rotation * -1.0);
        }

        LifeSpan = MaxHeals * HealTimer + 2;
        SetTimer(HealTimer, true);
        Timer();

        if( Role == ROLE_Authority ) {
            Disable('Tick');
            NetUpdateTime = Level.TimeSeconds - 1; // update now
        }

    }

    simulated function EndState()
    {
        bHealing = false;
        StopFX();
        SetTimer(0, false);

        if ( HealedHP > 0 ) {
            SuccessfulHealAchievements();
            SuccessfulHealMessage();
        }
    }

    simulated function Timer()
    {
        HealRadius(Damage, DamageRadius, Location);
        if (--MaxHeals <= 0) {
            GoToState('Disintegrating');
        }
    }

    simulated function Tick( float DeltaTime )
    {
        if ( bHidden ) {
            GoToState('Disintegrating');
        }
    }
}

simulated state Disintegrating
{
    ignores HitWall, ProcessTouch, Landed, Explode, Disintegrate, TakeDamage;

    simulated function BeginState()
    {
        bHidden = true;
        bDisintegrated = true;
        PlaySound(DisintegrateSound,,2.0);
        if ( EffectIsRelevant(Location,false) )
        {
            Spawn(Class'KFMod.SirenNadeDeflect',,, Location, rotator(vect(0,0,1)));
        }
        StopFX();

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
    Damage=4
    // Slightly raised the radius to compensate nade location offset between server and client due to lag
    DamageRadius=225  // 200
    MaxHeals=20
    HealTimer=0.5
    LifeSpan=15 // make sure the LifeSpan is longer than MaxHeals * HealTimer
    ImpactDamage=200
    ImpactDamageType=class'ScrnDamTypeMedicGrenadeImpact'
    ArmDistSquared=0
    StraightFlightTime=1.0
    StaticMeshRef="KF_pickups5_Trip.nades.MedicNade_Pickup"
    PrePivot=(Z=-1.5)
    ExplosionSoundRef="KF_GrenadeSnd.NadeBase.MedicNade_Explode"
    Speed=2000
    MaxSpeed=2500
    DampenFactor=0.25
    DampenFactorParallel=0.25  // 0.40
    MyDamageType=Class'KFMod.DamTypeMedicNade'
    ExplosionDecal=class'ScrnMedicNadeDecal'
    SoundVolume=150
    SoundRadius=100.000000
    TransientSoundRadius=200.000000
    bBounce=False
    SmokeTrailClass=class'ScrnMedicNadeTrail'
    GreenCloudClass=class'ScrnNadeHealing'
    HealingSound=Sound'Inf_WeaponsTwo.smoke_loop'

    RemoteRole=ROLE_SimulatedProxy
    bNetInitialRotation=true
    bNetNotify=true
    bUpdateSimulatedPosition=true
    bSkipActorPropertyReplication=true
    bNetTemporary=false  // Need to be false, otherwise no replication will happen after the spawn
    bAlwaysRelevant=true

    DrawScale=2.0
    bUnlit=false
    bAcceptsProjectors=true

    CollisionRadius=10.000000
    CollisionHeight=1.000000
    bUseCylinderCollision=True

    IntitialRotationAdjustment=(Pitch=-10010,Roll=16384) //old value (Pitch=-8192,Roll=16384)
}
