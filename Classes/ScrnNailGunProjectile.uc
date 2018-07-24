/* WARNING!
This projectile uses KFMonster's bZedUnderControl and NumZCDHits for own purposes!
It sohuldn't be an issue because those variables seem not be used by anything
bZedUnderControl - zed has been nailed and flying nail takes zed with it (can't be nailed more in this state)
NumZCDHits - number of nails zed is pinned with. Can be nailed more. Zed will be released when NumZCDHits reaches 0.
*/


class ScrnNailGunProjectile extends ScrnCustomShotgunBullet;

var     String         ImpactSoundRefs[6];

var byte Bounces;
var transient bool bBounced;
var bool bFinishedPenetrating;

var KFMonster MonsterHeadAttached;
var ProjectileBodyPart Giblet;


var KFMonster   NailedMonster; //monster that currently is attached to nail
var transient KFMonster   OldNailedMonster; //used for replication
var vector      NailHitDelta; // distance between hit's and victim's locations
var transient vector      NailingLocation; // location, where zed was hit by nail
var transient float       NailedFlyDistance; // how far did zed flew away?
var transient bool        bStillFlying; // NailedMonster is still flying (not pinned yet)
var transient ScrnAchievements.AchStrInfo ach_Nail100m, ach_NailToWall, ach_PushShiver, ach_ProNailer; //related achievements

var Pawn PendingDeadVictim;
var vector PendingHitSpot;

var float LifeSpanAfterHitWall; // for how long keep zeds nailed to a wall?

var(Movement) float VelocityModMass;
var(Movement) float VelocityModHealth;


replication
{
    reliable if ( bNetInitial && Role == ROLE_Authority )
        Bounces;

    reliable if ( bNetDirty && Role == ROLE_Authority )
        MonsterHeadAttached, bFinishedPenetrating,
        PendingHitSpot, PendingDeadVictim,
        NailedMonster, NailHitDelta;
}

static function PreloadAssets()
{
    default.ImpactSounds[0] = sound(DynamicLoadObject(default.ImpactSoundRefs[0], class'Sound', true));
    default.ImpactSounds[1] = sound(DynamicLoadObject(default.ImpactSoundRefs[1], class'Sound', true));
    default.ImpactSounds[2] = sound(DynamicLoadObject(default.ImpactSoundRefs[2], class'Sound', true));
    default.ImpactSounds[3] = sound(DynamicLoadObject(default.ImpactSoundRefs[3], class'Sound', true));
    default.ImpactSounds[4] = sound(DynamicLoadObject(default.ImpactSoundRefs[4], class'Sound', true));
    default.ImpactSounds[5] = sound(DynamicLoadObject(default.ImpactSoundRefs[5], class'Sound', true));

    super.PreloadAssets();
}

static function bool UnloadAssets()
{
    default.ImpactSounds[0] = none;
    default.ImpactSounds[1] = none;
    default.ImpactSounds[2] = none;
    default.ImpactSounds[3] = none;
    default.ImpactSounds[4] = none;
    default.ImpactSounds[5] = none;

    return super.UnloadAssets();
}

simulated function PostBeginPlay()
{
    super(Projectile).PostBeginPlay();

    Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    //SetTimer(0.4, false); //wut? There is no Timer function defined in parent classes

    if ( Level.NetMode != NM_DedicatedServer ) {
        if ( !PhysicsVolume.bWaterVolume )
        {
            Trail = Spawn(class'NailGunTracer',self);
            Trail.Lifespan = Lifespan;
        }
    }
}

simulated function PostNetReceive()
{
    local Coords boneCoords;

    super.PostNetReceive();

    //log ("Nail.PostNetReceive NailedMonster="$NailedMonster @ "NailHitDelta="$NailHitDelta, 'ScrnBalance');


    if( Giblet == none && MonsterHeadAttached != none )
    {
       boneCoords = MonsterHeadAttached.GetBoneCoords( 'head' );

       Giblet = Spawn( Class'ProjectileBodyPart',,, boneCoords.Origin, Rotator(boneCoords.XAxis) );
       Giblet.SetStaticMesh(MonsterHeadAttached.DetachedHeadClass.default.StaticMesh);
       Giblet.SetLocation(Location);
       Giblet.SetPhysics( PHYS_None );
       Giblet.SetBase(self);
       Giblet.Lifespan = Lifespan;
    }

    if ( NailedMonster != OldNailedMonster ) {
        if ( NailedMonster != none ) {
            Mass = NailedMonster.Mass;
            Bounces=0;
            NailedMonster.SetBase(self);
            NailedMonster.SetPhysics(PHYS_Flying); // fly away, baby ;)
            NailedMonster.bZedUnderControl = true; //indicate that nail is taking zed with it

            if ( Physics != PHYS_None )
                SetPhysics(PHYS_Falling);
        }
        else {
            Mass = default.Mass;
        }
        if ( OldNailedMonster != none) {
            if ( OldNailedMonster.Physics == PHYS_Flying )
                OldNailedMonster.SetPhysics(PHYS_Walking);
        }
        OldNailedMonster = NailedMonster;
    }
}

// Code taken from Marco's HL2 Crossbow
simulated function NailDeadBodiesToWall()
{
    local vector X,HL,HN;

    // Attempt to pin body onto wall
    X = vector(Rotation);
    if( PendingDeadVictim!=None && PendingDeadVictim.Health<=0 && PendingDeadVictim.Physics==PHYS_KarmaRagdoll )
    {
        if( Trace(HL,HN,Location+X*1000.f,Location-X*10.f,False)!=None )
            Spawn(Class'BodyAttacher',PendingDeadVictim,,PendingHitSpot).AttachEndPoint = HL-HN*4;
    }
    PendingDeadVictim = none;
}


function ReleaseMonster()
{

    if ( NailedMonster == none )
        return;

    Mass = default.Mass;

    if ( --NailedMonster.NumZCDHits <= 0 ) {
        NailedMonster.bZedUnderControl = false;
        NailedMonster.AirSpeed = NailedMonster.default.AirSpeed * NailedMonster.GroundSpeed / NailedMonster.default.GroundSpeed;

        if ( NailedMonster.Base == self )
            NailedMonster.SetBase(none);

        //drop zed on the ground and let him walk away
        if ( NailedMonster.Physics == PHYS_Flying )
            NailedMonster.SetPhysics(PHYS_Walking);
    }

    // achievements
    //PlayerController(Instigator.Controller).ClientMessage("NailedFlyDistance = " $ sqrt(NailedFlyDistance) $ " ("$ sqrt(NailedFlyDistance) / 50.0 $"m)");
    if ( NailedFlyDistance >= 25000000.0 && ach_Nail100m.AchHandler != none )
        ach_Nail100m.AchHandler.ProgressAchievement(ach_Nail100m.AchIndex, 1);
    if ( NailedFlyDistance >= 62500.0 && ach_PushShiver.AchHandler != none && NailedMonster.IsA('ZombieShiver') )
        ach_PushShiver.AchHandler.ProgressAchievement(ach_PushShiver.AchIndex, 1);

    NailedMonster = none;
    NetUpdateTime = Level.TimeSeconds - 1;
}


simulated function Tick(float DeltaTime)
{
    local vector X,HL,HN, ZedNewLoc;


    super.Tick(DeltaTime);

    if ( Level.NetMode != NM_DedicatedServer && Physics != PHYS_None )
    {
        SetRotation(Rotator(Normal(Velocity)));
    }

    if ( NailedMonster != none ) {
        // take naled zed with me
        ZedNewLoc = Location - NailHitDelta;
        X = vector(Rotation);
        if ( NailedMonster.Health > 0 ) {
            NailedMonster.Velocity = Velocity;
            if ( Physics != PHYS_None ) {
                bStillFlying = true;
                if ( NailedMonster.bZedUnderControl ) {
                    if ( !NailedMonster.SetLocation(ZedNewLoc) )
                        ReleaseMonster();
                }
            }
            else {
                if ( bStillFlying ) {
                    bStillFlying = false;
                    if ( NailedMonster.bZedUnderControl ) {
                        NailedMonster.SetLocation(ZedNewLoc); // set final pinned location
                        NailedMonster.bZedUnderControl = false; //allow other nails to pin this zed
                    }
                    // nail stopped, so trace precise location where to pin the zed
                    // if( Trace(HL, HN, ZedNewLoc+X*50.0, ZedNewLoc-X*50.f, true) == none ) {
                        // ReleaseMonster();
                        // return;
                    // }
                    //NailedMonster.SetLocation(HL);
                }
            }
            if ( Role == ROLE_Authority && NailedMonster != none ) {
                NailedFlyDistance = fmax(NailedFlyDistance, VSizeSquared(NailedMonster.Location - NailingLocation));
                if ( VSizeSquared(ZedNewLoc - NailedMonster.Location) > 2500 ) {
                    ReleaseMonster(); //too far from the nail - release zed
                    return;
                }
                if ( !bStillFlying && NailedMonster != none && ach_NailToWall.AchHandler != none ) {
                    ach_NailToWall.AchHandler.ProgressAchievement(ach_NailToWall.AchIndex, 1);
                    ach_NailToWall.AchHandler = none;
                }
            }
        }
        else if ( NailedMonster.Physics==PHYS_KarmaRagdoll ) {
            // attach dead body to a wall
            if( Trace(HL,HN,ZedNewLoc+X*1000.0, ZedNewLoc-X*10.0, False) != none )
                Spawn(Class'BodyAttacher',NailedMonster,,PendingHitSpot).AttachEndPoint = HL-HN*4;
            ReleaseMonster();
        }
    }
}


simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int>    HitPoints;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn HitPawn;
    local Pawn Victim;
    local KFMonster KFM;
    local bool bWasDecapitated;
    local Actor TempActor;
    local float PerkedDamage;

    ReleaseMonster(); //release currently nailed monster, when hitting another

    if ( Other == none || Other == Instigator  || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
        return;

    if( bFinishedPenetrating ) {
       return;
    }


    //Test - don't pin ExtendedZCollision
    // if ( ExtendedZCollision(Other) != none )
        // Victim = Pawn(Other.Owner); // ExtendedZCollision is attached to KFMonster
    // else if ( Pawn(Other) != none )
        Victim = Pawn(Other);

    X = Vector(Rotation);
    KFM = KFMonster(Victim);

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    // damage bonus also makes it fly faster
    PerkedDamage = Damage;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        PerkedDamage = KFPRI.ClientVeteranSkill.Static.AddDamage(KFPRI, KFM, KFPawn(Instigator), Damage, MyDamageType);

    if ( KFM != none ) {
        bWasDecapitated = KFM.bDecapitated;
        Velocity /= 1.0 + (KFM.Mass*VelocityModMass + KFM.Health*VelocityModHealth)/PerkedDamage; //heavy and healthy pawns slow down nails more
    }

     if( ROBulletWhipAttachment(Other) != none ) {
        // we touched player's auxilary collision cylinder, not let's trace to the player himself
        // Other.Base = KFPawn
        if( Other.Base == none || Other.Base.bDeleteMe )
            return;

        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

        if( Other == none || HitPoints.Length == 0 )
            return; // bullet didn't hit a pawn

        HitPawn = KFPawn(Other);

        if (Role == ROLE_Authority) {
            if ( HitPawn != none && !HitPawn.bDeleteMe ) {
                HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * Normal(Velocity), MyDamageType,HitPoints);
            }
        }
    }
    else {
        if ( Victim != none && Victim.IsHeadShot(HitLocation, X, 1.0) ) {
            // HEADSHOT
            Victim.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);

            if( Role == ROLE_Authority && KFM != none && !bWasDecapitated ) {
                if ( bBounced && KFM.bDecapitated )
                    ach_ProNailer.AchHandler.ProgressAchievement(ach_ProNailer.AchIndex, 1);

                if( MonsterHeadAttached == none && KFM.Health < 0 )  {
                    MonsterHeadAttached = KFM;
                    if( Level.NetMode == NM_ListenServer || Level.NetMode == NM_StandAlone )
                        PostNetReceive();
                }
            }
        }
        else {
            // BODYSHOT
            Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
        }
    }

    //Bounces=0; // don't bounce after hit somebody

    // penetration damage reduction
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
           PenDamageReduction = KFPRI.ClientVeteranSkill.static.GetShotgunPenetrationDamageMulti(KFPRI,default.PenDamageReduction);
    else
           PenDamageReduction = default.PenDamageReduction;
    // loose penetration damage after hitting specific zeds -- PooSH
    if ( KFM != none)
        PenDamageReduction *= ZedPenDamageReduction(KFM);
    Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.
    speed = VSize(Velocity);

    // if we've struck through more than the max number of foes, destroy.
    if ( Damage / default.Damage < (default.PenDamageReduction ** MaxPenetrations) + 0.0001
            || Speed < (default.Speed * 0.25))
    {
        ReleaseMonster();
        bFinishedPenetrating = true;
        SetPhysics(PHYS_Falling);
        Velocity = PhysicsVolume.Gravity;
        Bounces=0;
    }
    else if ( Role == ROLE_Authority && KFM != none
            && (bWasDecapitated || !KFM.bDecapitated) ) //don't nail zed on decapitating shot
    {
        PendingHitSpot = HitLocation;
        if ( Victim.Health <= 0) {
            PendingDeadVictim = KFM;
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else if ( !KFM.bZedUnderControl  && (bWasDecapitated ||
                    ( // KFM.CollisionRadius < 27 && (!KFM.bUseExtendedCollision || KFM.ColRadius < 27) &&
                        KFM.Mass < 360 && KFM.Health < PerkedDamage * 10 && ZombieSiren(KFM) == none)) )
        {
            // can pin only small zeds (up to Clot) or wounded medium zeds (Gorefast, Siren)

            // find a point where nail should go out of body after a penetration:
            // go behind the actor and trace in reverse direction
            TempActor = Trace(TempHitLocation, HitNormal,
                HitLocation, HitLocation + X * 2.0 * (KFM.CollisionRadius + KFM.CollisionHeight),
                true);
            if ( TempActor == KFM || TempActor == KFM.MyExtCollision) {
                NailingLocation = KFM.Location; // need for ach
                if ( KFM.NumZCDHits <= 0 ) {
                    // not pinned yet
                    KFM.NumZCDHits = 1;
                    NailedMonster = KFM;
                    NailHitDelta = TempHitLocation - KFM.Location;
                    KFM.bZedUnderControl = true; // under our conrol
                    KFM.SetPhysics(PHYS_Flying); // fly away, baby ;)
                    KFM.AirSpeed = 0;
                    KFM.SetBase(self);
                    if ( Physics != PHYS_None )
                        SetPhysics(PHYS_Falling);
                    Mass = KFM.Mass;
                    Bounces=0;

                    NetUpdateTime = Level.TimeSeconds - 1;
                }
                else {
                    KFM.NumZCDHits++;
                }
            }
        }
    }
}





simulated function HitWall( vector HitNormal, actor Wall )
{
    if ( !Wall.bStatic && !Wall.bWorldGeometry
        && ((Mover(Wall) == None) || Mover(Wall).bDamageTriggered) )
    {
        if ( Level.NetMode != NM_Client )
        {
            if ( Instigator == None || Instigator.Controller == None )
                Wall.SetDelayedDamageInstigatorController( InstigatorController );
            Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
        }
        Destroy();
        return;
    }

    SetRotation(rotator(Normal(Velocity)));

    if (Bounces > 0)
    {
        if ( !Level.bDropDetail && (FRand() < 0.4) )
            Playsound(ImpactSounds[Rand(6)]);

        Velocity = 0.65 * (Velocity - 2.0*HitNormal*(Velocity dot HitNormal));
        SetPhysics(PHYS_Falling);
        --Bounces;
        bBounced=True;

        if ( !Level.bDropDetail && (Level.NetMode != NM_DedicatedServer))
        {
            Spawn(class'ROEffects.ROBulletHitMetalEffect',,,Location, rotator(hitnormal));
        }
    }
    else
    {
        if (ImpactEffect != None && (Level.NetMode != NM_DedicatedServer))
        {
            Spawn(ImpactEffect,,, Location, rotator(-HitNormal));
        }
        SetPhysics(PHYS_None);
        Bounces=0;
        NailDeadBodiesToWall();
        //NailAliveZedsToWall();
        LifeSpan = LifeSpanAfterHitWall;

        bBounce = false;
        if (Trail != None)
        {
            Trail.mRegen=False;
            Trail.SetPhysics(PHYS_None);
            //Trail.mRegenRange[0] = 0.0;//trail.mRegenRange[0] * 0.6;
            //Trail.mRegenRange[1] = 0.0;//trail.mRegenRange[1] * 0.6;
        }
    }
}

simulated function PhysicsVolumeChange( PhysicsVolume Volume )
{
    if (Volume.bWaterVolume)
    {
        if ( Trail != None )
            Trail.mRegen=False;
        Velocity *= 0.65;
    }
}

simulated function Landed( Vector HitNormal )
{
    SetPhysics(PHYS_None);
    Bounces=0;
    LifeSpan = LifeSpanAfterHitWall;
}

simulated function Destroyed()
{
    super.Destroyed();

    if( Giblet != none )
    {
        Giblet.Destroy();
        Giblet = none;
    }

    if( MonsterHeadAttached != none )
    {
        MonsterHeadAttached = none;
    }

    ReleaseMonster();
}

defaultproperties
{
     ImpactSoundRefs(0)="ProjectileSounds.Bullets.Impact_Metal"
     ImpactSoundRefs(1)="ProjectileSounds.Bullets.Impact_Metal"
     ImpactSoundRefs(2)="ProjectileSounds.Bullets.Impact_Metal"
     ImpactSoundRefs(3)="ProjectileSounds.Bullets.Impact_Metal"
     ImpactSoundRefs(4)="ProjectileSounds.Bullets.Impact_Metal"
     ImpactSoundRefs(5)="ProjectileSounds.Bullets.Impact_Metal"
     Bounces=2
     LifeSpanAfterHitWall=2.000000
     VelocityModMass=0.005000
     VelocityModHealth=0.120000
     BigZedPenDmgReduction=0.00
     MediumZedPenDmgReduction=0.00  // nerf from 0.75 in v9.60.3
     StaticMeshRef="EffectsSM.Weapons.Vlad_9000_Nail"
     PenDamageReduction=0.33  // nerf from 0.75 in v9.60.3
     Damage=40.000000
     Speed=3500
     MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeNailGun'
     ExplosionDecal=Class'KFMod.NailGunDecal'
     bNetTemporary=False
     LifeSpan=10.000000
     bNetNotify=True
     bBounce=True

     // all properties below are required to replicate Velocity
     RemoteRole=ROLE_SimulatedProxy
     bSkipActorPropertyReplication=false
     bReplicateMovement=true
     bUpdateSimulatedPosition=true


}
