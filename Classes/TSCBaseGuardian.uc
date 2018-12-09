class TSCBaseGuardian extends TSCTeamBase;

var UnrealTeamInfo Team;
var int Damage; // damage per seconds that Base Guardian does to enemies
var int SameTeamCounter; // if nobody of team members are at the base longer than this value, base will be lost

var TSCGameReplicationInfo TSCGRI;

var localized string strUseMessage;
var localized string strUsedMessage;
var localized string strCarryHintMessage;
var localized string strITookTheGnome;
var transient float LastTouchTime;
var transient Pawn BaseSetter;
// damage type to apply on the team when base is lost
// none (default) = no team wipe on base lost
var class<DamageType> WipeOnBaseLost;

var int StunThreshold;
var int StunDuration;
var float StunFadeoutRate;
var transient float StunDamage;

var ShopVolume MyShop;
var transient ScrnPlayerController LastHolder;

replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        Team;
}

simulated function PostBeginPlay()
{
    TSCGRI = TSCGameReplicationInfo(Level.GRI);
    //log("TSCGRI = " $ TSCGRI, 'TSCBaseGuardian');

    super.PostBeginPlay();
}

simulated function PostNetReceive()
{
    if ( Role < ROLE_Authority ) {
        if ( bHeld && Base != none ) {
            // lame replication fix
            SetRelativeLocation(GameObjOffset);
            SetRelativeRotation(GameObjRot);
        }
    }
}

function UsedBy( Pawn user )
{
    if (!ValidHolder(user))
        return;

    SetHolder(user.Controller);
}

function SetHolder(Controller C)
{
    local PlayerController PC;

    super.SetHolder(C);
    PC = PlayerController(C);
    if ( PC != none) {
        PC.ClientMessage(strUsedMessage, 'CriticalEvent');
        PC.TeamSay(strITookTheGnome);
    }
}

simulated function vector GetLocation()
{
    if ( bHeld ) {
        if ( Base != none && !Base.bWorldGeometry )
            return Base.Location;
        else if ( Holder != none )
            return Holder.Location;
    }

    return Location;
}

function bool ShouldWipeOnBaseLost()
{
    return false;
}

singular function Touch(Actor Other)
{
    if (!ValidHolder(Other))
        return;

    if ( Pawn(Other) != none && PlayerController(Pawn(Other).Controller) != none) {
        if ( Level.TimeSeconds - LastTouchTime > 1 )
            PlayerController(Pawn(Other).controller).ClientMessage(strUseMessage, 'CriticalEvent');
        LastTouchTime = Level.TimeSeconds;
    }
}


function bool SameTeam(Controller c)
{
    if ( c == None || c.PlayerReplicationInfo == none || c.PlayerReplicationInfo.Team != Team )
        return false;

    return true;
}

function bool ValidHolder(Actor Other)
{
    local Pawn p;

    if( bDisabled || bActive || bHome || bHeld )
        return false;

    p = Pawn(other);
    if ( p == None || p.Health <= 0 || !p.bCanPickupInventory || !p.IsPlayerPawn() )
        return false;

    if ( !SameTeam(p.Controller) )
        return false;

    if ( TSCGRI.TeamCarrier[Team.TeamIndex] != none ) {
        if ( TSCGRI.TeamCarrier[Team.TeamIndex].Team != Team )
            TSCGRI.TeamCarrier[Team.TeamIndex] = none; // carrier changed team
        else
            return p.PlayerReplicationInfo == TSCGRI.TeamCarrier[Team.TeamIndex]
                || p.PlayerReplicationInfo == TSCGRI.TeamCaptain[Team.TeamIndex];
    }

    return true;
}

function PlayerController GetBaseSetter()
{
    local PlayerController PC;

    if ( Holder != none )
        PC = PlayerController(Holder.Controller);
    if ( PC == none && BaseSetter != none )
        PC = PlayerController(BaseSetter.Controller);
    return PC;
}

function bool ValidPlaceForBase(Vector CheckLoc)
{
    local TSCBaseGuardian EnemyBase;
    local ShopVolume Shop;
    local PlayerController PC;

    EnemyBase = TSCBaseGuardian(TSCGRI.Teams[1-Team.TeamIndex].HomeBase);
    if ( TSCGRI.AtBase(CheckLoc, EnemyBase) )
        return false;

    // check for Z difference to prevent vertical intersection
    CheckLoc.Z += TSCGRI.MaxBaseZ + TSCGRI.MinBaseZ;
    if ( TSCGRI.AtBase(CheckLoc, EnemyBase) ) {
        PC = GetBaseSetter();
        if ( PC != none )
            PC.ReceiveLocalizedMessage(class'TSCMessages', 310);
        return false;
    }

    // can't place a base inside a shop
    foreach TouchingActors(Class'ShopVolume',Shop) {
        PC = GetBaseSetter();
        if ( PC != none )
            PC.ReceiveLocalizedMessage(class'TSCMessages', 313);
        return false;
    }

    if ( Holder != none ) {
        foreach Holder.TouchingActors(Class'ShopVolume',Shop) {
            PC = GetBaseSetter();
            if ( PC != none )
                PC.ReceiveLocalizedMessage(class'TSCMessages', 313);
            return false;
        }
    }

    return true;
}

function BaseSetupFailed()
{
    SendHome();
}

// Score() is used for setting up base
function Score()
{
    if ( bDisabled || bActive )
        return;

    if ( ValidPlaceForBase(GetLocation()) ) {
        BaseSetter = Holder;
        GotoState('SettingUp');
    }
    else {
        log("Invalid place for base @ " $ GetLocation(), class.name);
    }
}

// If base is not active, try setting it up.
// If unable to setup base, then send it home.
// Usually used at the start of the wave.
function ScoreOrHome()
{
    Score();
      // if base still isn't established - send it home
    if ( !bActive )
        BaseSetupFailed();
}

function MoveToShop(ShopVolume Shop)
{
    local int i;

    if ( Shop == none )
        return;

    BaseSetter = none;

    if ( !Shop.bTelsInit )
        Shop.InitTeleports();

    if ( Shop.bHasTeles ) {
        if ( Shop.TelList.length == 1 ) {
            i = 0;
        }
        else if ( Team.TeamIndex == 0 ) {
            i = Rand(Shop.TelList.length/2);
        }
        else {
            i = ceil(Shop.TelList.length/2.0) + Rand(Shop.TelList.length/2);
            // shouldn't happen, just to be 110% sure
            if( i >= Shop.TelList.length ) {
                i = Shop.TelList.length - 1;
            }
        }
        SetLocation(Shop.TelList[i].Location + (vect(0,0,1) * CollisionHeight)) ;
        SetPhysics(PHYS_Falling);
        GotoState('Dropped');
    }
    else {
        warn( Shop $ " has no teleporters" );
        // if none of teleporters can accept us, just give me to the closest team member
        GiveToClosestPlayer(Shop.Location);
    }
}

function GiveToClosestPlayer(vector Loc)
{
    local Controller C, Best;
    local float BestDistSqr;

    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( C.bIsPlayer && C.Pawn != none && ValidHolder(C.Pawn) ) {
            if ( Best == none || VSizeSquared(C.Pawn.Location - Loc) < BestDistSqr )
                Best = C;
        }
    }
    if ( Best != none ) {
        GotoState('Dropped');
        SetHolder(Best);
    }
}

auto state Home
{
    ignores BaseSetupFailed;

    function BeginState()
    {
        // log("State --> Home", class.name);
        Disable('Touch');
        SetCollision(false, false);
        bCollideWorld=false;
        bHome = true;
        bHidden = true;
        LightType = LT_None;
        BaseSetter = none;
        LastHolder = none;
    }

    function EndState()
    {
        // log("State <-- Home", class.name);
        bHome = false;
        bHidden = false;
        TakenTime = Level.TimeSeconds;
    }

    function CheckTouching() {}
}

state Dropped
{
    function BeginState()
    {
        // log("State --> Dropped", class.name);
        SetCollision(true, false);
        bCollideWorld=True;
        bHidden = false;
        LightType = LT_Pulse;
        Enable('Touch');

        super.BeginState();
    }

    function EndState()
    {
        // log("State <-- Dropped", class.name);
    }
}

state Held
{
    function BeginState()
    {
        // log("State --> Held", class.name);
        super.BeginState();
        Holder.bAlwaysRelevant = true;
        BaseSetter = none;
        LastHolder = ScrnPlayerController(Holder.Controller);
    }

    function EndState()
    {
        // log("State <-- Held", class.name);
        if ( Holder != none ) {
            Holder.bAlwaysRelevant = false;
            SetLocation(Holder.Location); // prevent holder to exploit GameObjOffset
        }
        super.EndState();
    }

    function SendHome() // unignore
    {
        global.SendHome();
    }

    function MoveToShop(ShopVolume Shop)
    {
        Drop(PhysicsVolume.Gravity); // make sure the holder will not force his location after moving to shop
        global.MoveToShop(Shop);
    }
}


state SettingUp
{
    ignores Score, ScoreOrHome, Touch, UsedBy;

    function BeginState()
    {
        // log("State --> SettingUp", class.name);
        bActive = true;
        Disable('Touch');

        SetCollision(true, false);
        bCollideWorld=true;
        Velocity = PhysicsVolume.Gravity;
        SetPhysics(PHYS_Falling);

        LightType = LT_Pulse;

        SetTimer(10, false); // just in case

        NetUpdateTime = Level.TimeSeconds - 1; // replicate immediately
    }

    function EndState()
    {
        // log("State <-- SettingUp", class.name);
        bActive = false;
        SetTimer(0, false);
    }

    event Landed( vector HitNormal )
    {
        local rotator r;

        Velocity = vect(0,0,0); // just to be sure :)

        if ( !ValidPlaceForBase(Location) ) {
            // can't setup base here (probably dropped down to enemy base)
            // give gnome back to its last holder
            if ( TSCGRI.bWaveInProgress ) {
                BaseSetupFailed();
            }
            else if ( BaseSetter != none ) {
                SetPhysics(PHYS_None);
                SetHolder(BaseSetter.Controller);
            }
            else {
                GotoState('Dropped');
            }
            return;
        }

        r = Rotation;
        r.Pitch = 0;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_Rotating);
        SetTimer(5, false); // activate the base in 5 seconds
    }


    function Timer()
    {
        BroadcastLocalizedMessage(class'TSCMessages', 1+Team.TeamIndex*100);
        GotoState('Guarding');
    }
}

state Guarding
{
    ignores Score, ScoreOrHome, Touch, UsedBy;

    function BeginState()
    {
        local Controller C;
        local ScrnPlayerController ScrnC;
        local rotator r;

        // log("State --> Guarding", class.name);
        bActive = true;
        Disable('Touch');

        SetCollision(true, false);
        bCollideWorld = true;
        r = Rotation;
        r.Pitch = 0;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_Rotating);

        LightType = LT_Steady;

        StunDamage = 0;
        SameTeamCounter = default.SameTeamCounter;
        SetTimer(1, true);

        for ( C = Level.ControllerList; C != none; C = C.nextController ) {
            if ( C.bIsPlayer && SameTeam(C) ) {
                ScrnC = ScrnPlayerController(C);
                if ( ScrnC != none && ScrnC.bShoppedThisWave )
                    ScrnPlayerController(C).ServerShowPathTo(1); // show path to base
            }
        }
    }

    function EndState()
    {
        // log("State <-- Guarding", class.name);
        bActive = false;
        SetTimer(0, false);
    }

    function SendHome()
    {
        if ( ShouldWipeOnBaseLost() )
        {
            TSCGame(Level.Game).WipeTeam(Team, WipeOnBaseLost);
        }
        global.SendHome();
    }

    function bool ShouldWipeOnBaseLost()
    {
        return WipeOnBaseLost != none && TSCGRI.MaxMonsters > 10;
    }

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
    {
        local ScrnPlayerController PC;

        if ( damageType == class'DamTypeFrag' )
            Damage *= 5;
        if ( InstigatedBy != none )
            PC = ScrnPlayerController(InstigatedBy.Controller);
        if ( PC != none ) {
            PC.ClientPlayerDamaged(Damage, Hitlocation, 10);
        }
        StunDamage += Damage;
    }

    function Tick(float DeltaTime)
    {
        super.Tick(DeltaTime);

        if ( StunDamage > 0 ) {
            if ( StunDamage >= StunThreshold ) {
                GotoState('Stunned');
            }
            else {
                StunDamage -= StunFadeoutRate * DeltaTime;
                if ( StunDamage < 0 )
                    StunDamage = 0;
            }
        }
    }

    function Timer()
    {
        local Controller C;
        local ScrnPlayerController SC;
        local bool bNobodyAtBase, bNobodyAlive;

        bNobodyAtBase = true;
        bNobodyAlive = true;
        for ( C = Level.ControllerList; C != none; C = C.nextController ) {
            if ( C.bIsPlayer && C.Pawn != none && C.Pawn.Health > 0
                    && C.PlayerReplicationInfo != none )
            {
                if ( C.PlayerReplicationInfo.Team != Team && TSCGRI.AtBase(C.Pawn.Location, self) ) {
                    C.Pawn.TakeDamage(Damage, none, C.Pawn.Location, vect(0,0,0), class'DamTypeEnemyBase');
                    if ( PlayerController(C) != none && ScrnHumanPawn(C.Pawn) != none
                            && ScrnHumanPawn(C.Pawn).NextEnemyBaseDamageMsg < Level.TimeSeconds )
                    {
                        PlayerController(C).ReceiveLocalizedMessage(class'TSCMessages', 312);
                        ScrnHumanPawn(C.Pawn).NextEnemyBaseDamageMsg = Level.TimeSeconds + 6.0;
                    }
                }
                else if ( bNobodyAtBase && C.PlayerReplicationInfo.Team == Team ) {
                    bNobodyAlive = false;
                    if ( TSCGRI.AtBase(C.Pawn.Location, self) )
                        bNobodyAtBase = false;
                }
            }
        }
        if ( bNobodyAtBase ) {
            if ( bNobodyAlive || --SameTeamCounter <= 0 ) {
                BroadcastLocalizedMessage(class'TSCMessages', 2+Team.TeamIndex*100);
                SendHome();
            }
            else if ( SameTeamCounter % 3 == 0 ) {
                for ( C = Level.ControllerList; C != none; C = C.nextController ) {
                    if ( C.bIsPlayer && C.PlayerReplicationInfo != none
                            && C.Pawn != none && C.Pawn.Health > 0
                            && C.PlayerReplicationInfo.Team == Team )
                    {
                        SC = ScrnPlayerController(C);
                        if ( SC != none ) {
                            SC.ServerShowPathTo(1); // show path to base
                            if ( ShouldWipeOnBaseLost() )
                                SC.ReceiveLocalizedMessage(class'TSCMessages', 311); // critical message
                            else
                                SC.ReceiveLocalizedMessage(class'TSCMessages', 211);
                        }
                    }
                }
            }
        }
        else {
            SameTeamCounter = default.SameTeamCounter;
        }
    }
}

state Stunned
{
    ignores Score, ScoreOrHome, Touch, UsedBy, TakeDamage;

    function BeginState()
    {
        local rotator r;

        // log("State --> Stunned", class.name);
        r = Rotation;
        r.Pitch = -16384;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_None);

        LightType = LT_Flicker;
        LightRadius = default.LightRadius * 0.3;
        SetTimer(StunDuration, false);
        NetUpdateTime = Level.TimeSeconds - 1; // replicate immediately
        BroadcastLocalizedMessage(class'TSCMessages', 3+Team.TeamIndex*100);
    }

    function EndState()
    {
        // log("State <-- Stunned", class.name);
        LightRadius = default.LightRadius;
    }

    function Timer()
    {
        GotoState('WakingUp');
    }
}

state WakingUp
{
    ignores Score, ScoreOrHome, Touch, UsedBy;

    function BeginState()
    {
        local rotator r;

        // log("State --> WakingUp", class.name);
        r = Rotation;
        r.Pitch = 0;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_Rotating);

        bActive = true;
        LightType = LT_Pulse;
        SetTimer(5, false);
        NetUpdateTime = Level.TimeSeconds - 1; // replicate immediately
        BroadcastLocalizedMessage(class'TSCMessages', 4+Team.TeamIndex*100);
    }

    function EndState()
    {
        // log("State <-- WakingUp", class.name);
        bActive = false;
    }

    function Timer()
    {
        GotoState('Guarding');
    }
}

defaultproperties
{
    strUseMessage="Press USE to take the Base Guardian"
    strUsedMessage="You took the Base Guardian"
    strITookTheGnome="I took our Base Guardian"
    MaxDropTime=0
    GameObjBone="CHR_Spine3"
    GameObjOffset=(X=0,Y=15,Z=0)
    GameObjRot=(Pitch=-16384,Yaw=0,Roll=0)
    Damage=5
    StunThreshold=700
    StunDuration=25
    StunFadeoutRate=50
    SameTeamCounter=10
    bCanBeDamaged=False

    LightType=LT_Steady
    LightEffect=LE_QuadraticNonIncidence
    LightRadius=25
    LightSaturation=128
    LightBrightness=150 // 220
    LightPeriod=30
    bStatic=False
    bHidden=True
    bDynamicLight=True
    bStasis=False
    NetPriority=3.000000
    bUnlit=True

    bCollideActors=False
    bCollideWorld=True
    bBlockHitPointTraces=True
    bBlockZeroExtentTraces=True
    bBlockNonZeroExtentTraces=True
    bProjTarget=True
    bUseCylinderCollision=True
    bFixedRotationDir=True
    SurfaceType=EST_Flesh
    Mass=30.000000
    Buoyancy=20.000000
    RotationRate=(Yaw=25000)
    MessageClass=Class'UnrealGame.CTFMessage'

    Style=STY_Normal
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'HillbillyHorror_SM.GardenGnome'
    CollisionRadius=15

    CollisionHeight=15
    DrawScale=0.75
    PrePivot=(Z=23)


    // fucking replication
    bAlwaysRelevant=true
    bNetNotify=true
    /*
    bReplicateMovement=true
    bSkipActorPropertyReplication=false
    RemoteRole=Role_SimulatedProxy
    */
}
