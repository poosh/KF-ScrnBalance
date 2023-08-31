class StinkyClot extends StinkyClotZed;

var() name CompleteAnim;
var() name GrabBone;
var() float OutOfBaseSpeedMod, MaxBoostSpeedMod;  // multipliers for GroundSpeed
var transient float OutOfBaseSpeed, MaxBoostSpeed;

var float NextStuckTestTime;
var transient vector OldLocation;
var transient int StuckCounter;
var transient float TargetClosestDist;

// Teleporting
const TELEPORT_NONE     = 0;
const TELEPORT_FADEOUT  = 1;
const TELEPORT_FADEIN   = 2;
var byte TeleportPhase, ClientTeleportPhase;
var transient vector TeleportLocation;
var transient float AlphaFader;
var string TeleportSoundRef;
var sound TeleportSound;
var transient Actor MoveHistory[3];


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

    OutOfBaseSpeed = OutOfBaseSpeedMod * OriginalGroundSpeed;
    MaxBoostSpeed = MaxBoostSpeedMod * OriginalGroundSpeed;
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

function bool CanSpeedAdjust()
{
    return false;
}

function ClearMoveHistory()
{
    local int i;

    for ( i = 0; i < ArrayCount(MoveHistory); ++i ) {
        MoveHistory[i] = none;
    }
}

function OnMoveTarget(Actor MoveTarget)
{
    local int i;

    for ( i = 0; i < ArrayCount(MoveHistory); ++i ) {
        if ( MoveHistory[i] == MoveTarget )
            return;  // not a new target
    }

    for ( i = ArrayCount(MoveHistory) - 1; i > 0; --i ) {
        MoveHistory[i] = MoveHistory[i-1];
    }
    MoveHistory[0] = MoveTarget;

    OldLocation = Location;
    StuckCounter = 0;
    TargetClosestDist = VSizeSquared(Location - MoveTarget.Location);
    NextStuckTestTime = Level.TimeSeconds + 1;
}

function CheckStuck()
{
    local float dist;

    if ( Controller == none || Controller.MoveTarget == none || Controller.MoveTarget == self
            || !Controller.IsInState('Moving') )
        return;  // cannot stuck if not moving

    if ( Controller.MoveTarget == MoveHistory[0] ) {
        dist = VSizeSquared(Location - Controller.MoveTarget.Location);
        if ( dist - TargetClosestDist < -2500 ) {
            // we are getting closer to our target. Delay the teleportation
            StuckCounter = max(0, StuckCounter - 10);
            TargetClosestDist = dist;
            return;
        }
    }

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
        TeleportToNextPath();
    }
}

simulated function Tick(float dt)
{
    super.Tick(dt);

    if ( TeleportPhase != TELEPORT_NONE ) {
        switch ( TeleportPhase ) {
            case TELEPORT_FADEOUT:
                AlphaFader -= dt * 512;
                if (Level.NetMode != NM_Client && AlphaFader <= 0) {
                    DoTeleport();
                }
                break;
            case TELEPORT_FADEIN:
                AlphaFader += dt * 256;
                if (Level.NetMode != NM_Client && AlphaFader >= 255) {
                    TeleportPhase = TELEPORT_NONE;
                    if (Level.NetMode != NM_DedicatedServer)
                        SetSkin();
                }
                break;
        }

        if (Level.NetMode != NM_DedicatedServer && ColorModifier(Skins[0]) != none) {
            ColorModifier(Skins[0]).Color.A = clamp(AlphaFader, 0, 255);
        }
    }
    else if ( Role == ROLE_Authority && Level.TimeSeconds > NextStuckTestTime ) {
        NextStuckTestTime = Level.TimeSeconds + 1;
        CheckStuck();
    }
}

function SetInvulnerability(bool invul)
{
    SetCollision(!invul, !invul);

    if ( Level.NetMode != NM_DedicatedServer ) {
        SetSkin();
    }
    else {
        AdjustCollision();
    }
}

simulated function AdjustCollision()
{
    if ( bBlockActors ) {
        OnlineHeadshotOffset = class'StinkyClotZed'.default.OnlineHeadshotOffset;
        PrePivot = class'StinkyClotZed'.default.PrePivot;
        SetCollisionSize(class'StinkyClotZed'.default.CollisionRadius, class'StinkyClotZed'.default.CollisionHeight);
    }
    else {
        OnlineHeadshotOffset = default.OnlineHeadshotOffset;
        PrePivot = default.PrePivot;
        SetCollisionSize(default.CollisionRadius, default.CollisionHeight);
    }
}

simulated function SetSkin()
{
    AdjustCollision();
    if ( bBlockActors && TeleportPhase == TELEPORT_NONE) {
        Skins[0] = default.Skins[0];
        if ( bCrispified )
            ZombieCrispUp();
    }
    else {
        Skins[0] = ColorModifier'ScrnTex.Zeds.StinkyColor';
        ColorModifier(Skins[0]).Color.A = clamp(AlphaFader, 0, 255);
        ColorModifier(Skins[0]).AlphaBlend = TeleportPhase != TELEPORT_NONE;
    }
}

function LogPath()
{
    local StinkyController SC;

    SC = StinkyController(Controller);
    if ( SC != none ) {
        log(class'ScrnF'.static.RPad("Action " $ string(SC.ActionNum + 1) $ "/" $ SC.GetActionCount()$":", 15)
                $ SC.GetActionStart() $ " => " $ SC.GetActionTarget(), class.name);
    }
    log("Path history:  " $ MoveHistory[2] $ " => "  $ MoveHistory[1] $ " => " $ MoveHistory[0], class.name);
    if ( Controller.CurrentPath != none ) {
        log("Current route: " $ Controller.CurrentPath.Start $ " => " $ Controller.CurrentPath.End, class.name);
    }
    else {
        log ("No current route");
    }

    if ( Controller.CurrentPath != none ) {
        log("Next route:    " $ Controller.NextRoutePath.Start $ " => " $ Controller.NextRoutePath.End, class.name);
    }
    else {
        log ("No next route");
    }
}

function TeleportToActor(Actor TeleportDest)
{
    if ( TeleportDest == none )
        return;

    TeleportLocation = TeleportDest.Location;
    TeleportLocation.Z += CollisionHeight + 5;

    log("Teleporting to " $ TeleportDest $ " @ ("$TeleportLocation$")", class.name);
    LogPath();

    ClearMoveHistory();
    StuckCounter = 0;
    NextStuckTestTime = Level.TimeSeconds + 5;

    StartTeleport();
}

function bool TeleportToNextPath()
{
    local Actor TeleportDest;

    if ( Controller.NextRoutePath != none ) {
        TeleportDest = Controller.NextRoutePath.End;
    }
    if ( TeleportDest == none ) {
        TeleportDest = MoveHistory[0];
    }
    if ( TeleportDest == none ) {
        return false;
    }
    TeleportToActor(TeleportDest);
    return true;
}

function StartTeleport()
{
    TeleportPhase = TELEPORT_FADEOUT;
    AlphaFader = 255;
    if ( Level.NetMode != NM_DedicatedServer ) {
        SetSkin();
    }
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
    if (SetLocation(TeleportLocation)) {
        PlaySound(TeleportSound, SLOT_Interact, 4.0);
        SetMovementPhysics();
        Controller.MoveTarget = none;
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
    ControllerClass=class'StinkyController'
    bAlwaysRelevant=true

    bCollideActors=false
    bBlockActors=false
    // make collision the same as a regular clot while invulnerable - should less get stuck and fall into holes
    CollisionRadius=26
    CollisionHeight=44
    PrePivot=(X=0,Y=0,Z=-20)
    OnlineHeadshotOffset=(X=9,Z=-4)

    GroundSpeed=42
    OutOfBaseSpeedMod=0.65
    MaxBoostSpeedMod=3.0
    Health=1000
    HealthMax=1000
    HeadHealth=1000
    MotionDetectorThreat=0
    ScoringValue=100

    CompleteAnim="ClotPunt"
    GrabBone="CHR_RArmPalm"
    TeleportSoundRef="ScrnZedPack_S.Shiver.ShiverWarpGroup";
}
