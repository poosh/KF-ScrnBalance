class StinkyClot extends ZombieClot;

var() name CompleteAnim;
var() name GrabBone;

var float NextStuckTestTime;
var transient vector OldLocation;
var transient int StuckCounter;

// Teleporting
const TELEPORT_NONE     = 0;
const TELEPORT_FADEOUT  = 1;
const TELEPORT_FADEIN   = 2;
var byte TeleportPhase, ClientTeleportPhase;
var transient vector TeleportLocation;
var transient float AlphaFader;
var string TeleportSoundRef;
var sound TeleportSound;
var transient Actor LastMoveTarget[2];

replication
{
    reliable if (Role == ROLE_Authority)
        TeleportPhase;
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( TeleportSound == none ) {
        TeleportSound = sound(DynamicLoadObject(TeleportSoundRef, class'Sound', true));
        default.TeleportSound = TeleportSound;
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    SetSkin();
}

simulated event PostNetReceive()
{
    super.PostNetReceive();

    if (ClientTeleportPhase != TeleportPhase) {
        ClientTeleportPhase = TeleportPhase;
        if (TeleportPhase == TELEPORT_FADEIN) {
            AlphaFader = 1;
            PlaySound(TeleportSound, SLOT_Interact, 4.0);
        }
        else {
            AlphaFader = 255;
        }
    }
    SetSkin();
}

simulated function Tick(float dt)
{
    super.Tick(dt);

    if ( Controller != none && Controller.MoveTarget != none && Controller.MoveTarget != self
            && Controller.IsInState('Moving') )
    {
        if ( LastMoveTarget[0] != Controller.MoveTarget && LastMoveTarget[1] != Controller.MoveTarget ) {
            LastMoveTarget[1] = LastMoveTarget[0];
            LastMoveTarget[0] = Controller.MoveTarget;
            OldLocation = Location;
            StuckCounter = 0;
            NextStuckTestTime = Level.TimeSeconds + 1;
        }
        else if ( Level.TimeSeconds > NextStuckTestTime ) {
            NextStuckTestTime = Level.TimeSeconds + 1;
            OldLocation.Z = Location.Z; // ignore Z difference, because zed may be constantly jumping
            if ( VSizeSquared(Location - OldLocation) < 10000 ) {
                StuckCounter += 3;  // 10 seconds to move away from the current location
            }
            else {
                OldLocation = Location;
                StuckCounter += 1; // 30s to reach the target
            }

            if ( StuckCounter >= 30 ) {
                // if can't reach the target - simply teleport to it
                TeleportLocation = Controller.MoveTarget.Location;
                TeleportLocation.Z += CollisionHeight;
                StartTeleport();
            }
        }
    }

    if ( TeleportPhase != TELEPORT_NONE ) {
        switch ( TeleportPhase ) {
            case TELEPORT_FADEOUT:
                AlphaFader = FMax(AlphaFader - dt * 512, 0);

                if (Level.NetMode != NM_Client && AlphaFader == 0) {
                    DoTeleport();
                }
                break;
            case TELEPORT_FADEIN:
                AlphaFader = FMin(AlphaFader + dt * 256, 255);

                if (Level.NetMode != NM_Client && AlphaFader == 255) {
                    TeleportPhase = TELEPORT_NONE;
                    if (Level.NetMode != NM_DedicatedServer)
                        SetSkin();
                }
                break;
        }

        if (Level.NetMode != NM_DedicatedServer && ColorModifier(Skins[0]) != none) {
            ColorModifier(Skins[0]).Color.A = AlphaFader;
        }
    }
}

simulated function SetSkin()
{
    if ( bBlockActors && TeleportPhase == TELEPORT_NONE) {
        Skins[0] = default.Skins[0];
        if ( bCrispified )
            ZombieCrispUp();
    }
    else {
        Skins[0] = ColorModifier'ScrnTex.Zeds.StinkyColor';
        ColorModifier(Skins[0]).Color.A = AlphaFader;
        ColorModifier(Skins[0]).AlphaBlend = TeleportPhase != TELEPORT_NONE;
    }
}

function StartTeleport()
{
    TeleportPhase = TELEPORT_FADEOUT;
    AlphaFader = 255;
    if ( Level.NetMode != NM_DedicatedServer ) {
        SetSkin();
    }
    StuckCounter = 0;
    NextStuckTestTime = Level.TimeSeconds + 5;
}

function DoTeleport()
{
    TeleportPhase = TELEPORT_FADEIN;
    AlphaFader = 0;
    if ( Level.NetMode != NM_DedicatedServer ) {
        SetSkin();
    }
    Velocity = vect(0,0,0);
    Acceleration = vect(0,0,0);
    if (SetLocation(TeleportLocation))
    {
        PlaySound(TeleportSound, SLOT_Interact, 4.0);
        Controller.StopWaiting();
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType, optional int HitIndex )
{
    if ( bBlockActors )
        super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType, HitIndex);
    // stinky clot does not take damage
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local int i;
    local TheGuardian gnome;

    for( i=0; i<Attached.length; i++ ) {
        gnome = TheGuardian(Attached[i]);
        if ( gnome != none )
            gnome.PawnBaseDied();
    }

    super.Died(Killer,damageType,HitLocation);
}


function bool FlipOver()
{
    return false;
}

function RemoveHead()
{
    KilledBy(LastDamagedBy);
}

// removed references to KFMonsterController
event Bump(actor Other)
{
    if ( KFDoorMover(Other) != none )
        BlowUpDoor(KFDoorMover(Other));
    else
        super(Monster).Bump(Other);
}

function BlowUpDoor(KFDoorMover door)
{
    local int i;
    local KFUseTrigger key;

    if ( door == none || !door.bClosed )
        return;

    key = door.MyTrigger;
    if ( key != none ) {
        for ( i=0; i<key.DoorOwners.Length; ++i ) {
            if ( !key.DoorOwners[i].bDoorIsDead )
                key.DoorOwners[i].GoBang(self, Location, vector(Rotation), none);
        }
    }
    else
        door.GoBang(self, Location, vector(Rotation), none);
}

function KickActor()
{
    // no KFMonsterController to perform a kick
}


simulated function SetBurningBehavior()
{
}

simulated function UnSetBurningBehavior()
{
}

simulated function float GetOriginalGroundSpeed()
{
    return GroundSpeed;
}


defaultproperties
{
    MenuName="Stinky Clot"
    EventClasses(0)="ScrnBalanceSrv.StinkyClot"

    ControllerClass=Class'ScrnBalanceSrv.StinkyController'
    CompleteAnim="ClotPunt"
    GrabBone="CHR_RArmPalm"

    bAlwaysRelevant=true
    bUseExtendedCollision=false
    DrawScale=0.5
    CollisionRadius=13
    CollisionHeight=22
    bBlockActors=false
    GroundSpeed=55
    Health=1000
    HealthMax=1000
    HeadHealth=1000
    JumpZ=480

    MoanVoice=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Talk'
    MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_HitPlayer'
    JumpSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Jump'
    DetachedArmClass=Class'KFChar.SeveredArmClot'
    DetachedLegClass=Class'KFChar.SeveredLegClot'
    DetachedHeadClass=Class'KFChar.SeveredHeadClot'
    HitSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Pain'
    DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Death'
    ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
    AmbientSound=Sound'KF_BaseClot.Clot_Idle1Loop'
    Mesh=SkeletalMesh'KF_Freaks_Trip.CLOT_Freak'
    Skins(0)=Combiner'KF_Specimens_Trip_T.clot_cmb'

    TeleportSoundRef="ScrnZedPack_S.Shiver.ShiverWarpGroup";
}
