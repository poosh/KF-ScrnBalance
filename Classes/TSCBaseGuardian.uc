class TSCBaseGuardian extends TSCTeamBase;

var UnrealTeamInfo Team;
var int Damage; // damage per seconds that Base Guardian does to enemies
var int SameTeamCounter; // if nobody of team members are at the base longer than this value, base will be lost

var TSCGameReplicationInfo TSCGRI;
var class<TSCMessages> TscMessages;

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
var int StunDuration, WakeUpDuration;
var float StunFadeoutRate;
var transient float StunDamage;
var float StunFadeoutTime;  // time after last damage taken to start fading out
var deprecated float InvulTime;
var bool bInvul;

var ShopVolume MyShop;
var transient ScrnPlayerController LastHolder;

var byte GuardianBrightness, GuardianLightRadius, GuardianHue;

var enum EClientState {
    CS_Home,
    CS_Dropped,
    CS_Held,
    CS_SettingUp,
    CS_Guarding,
    CS_Stunned,
    CS_WakingUp
} ClientState;

replication
{
    reliable if ((bNetInitial || bNetDirty) && Role == ROLE_Authority)
        Team, ClientState;

    reliable if (bNetInitial && Role == ROLE_Authority)
        GuardianBrightness, GuardianLightRadius, GuardianHue;
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
        ApplyClientState();
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

simulated function Actor GetWorldActor()
{
    if (bHeld && Holder != none) {
        return Holder;
    }
    return self;
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

function ScrnPlayerController GetBaseSetter()
{
    local ScrnPlayerController PC;

    if ( Holder != none )
        PC = ScrnPlayerController(Holder.Controller);
    if ( PC == none && BaseSetter != none )
        PC = ScrnPlayerController(BaseSetter.Controller);
    if ( PC == none )
        PC = LastHolder;
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
            PC.ReceiveLocalizedMessage(TscMessages, 310);
        return false;
    }

    // can't place a base inside a shop
    foreach TouchingActors(Class'ShopVolume',Shop) {
        PC = GetBaseSetter();
        if ( PC != none )
            PC.ReceiveLocalizedMessage(TscMessages, 313);
        return false;
    }

    if ( Holder != none ) {
        foreach Holder.TouchingActors(Class'ShopVolume',Shop) {
            PC = GetBaseSetter();
            if ( PC != none )
                PC.ReceiveLocalizedMessage(TscMessages, 313);
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

function SetBrightness(byte value)
{
    if (value == 0) {
        value = default.GuardianBrightness;
    }
    GuardianBrightness = value;
    ApplyClientState();
}

function SetLightRadius(byte value)
{
    if (value == 0) {
        value = default.GuardianLightRadius;
    }
    GuardianLightRadius = value;
    ApplyClientState();
}

function SetHue(byte value)
{
    if (value == 0) {
        value = default.GuardianHue;
    }
    GuardianHue = value;
    ApplyClientState();
}

function SetClientState(EClientState NewState)
{
    if ( ClientState != NewState ) {
        ClientState = NewState;
        NetUpdateTime = Level.TimeSeconds - 1;
        ApplyClientState();
    }
}

simulated function ApplyClientState()
{
    LightRadius = GuardianLightRadius;
    LightBrightness = GuardianBrightness;
    if (GuardianHue != 0) {
        LightHue = GuardianHue;
    }
    switch (ClientState) {
        case CS_Home:
            LightType = LT_None;
            break;

        case CS_Dropped:
        case CS_Held:
            LightType = LT_Pulse;
            LightRadius *= 0.5;
            break;

        case CS_SettingUp:
        case CS_WakingUp:
            LightType = LT_Pulse;
            LightBrightness *= 1.5;
            break;

        case CS_Guarding:
            LightType = LT_Steady;
            break;

        case CS_Stunned:
            LightType = LT_Flicker;
            LightRadius *= 0.3;
            break;
    }
}

auto state Home
{
    ignores BaseSetupFailed;

    function BeginState()
    {
        SetClientState(CS_Home);
        // log("State --> Home", class.name);
        Disable('Touch');
        SetCollision(false, false);
        bCollideWorld=false;
        bHome = true;
        bHidden = true;
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
        SetClientState(CS_Dropped);
        // log("State --> Dropped", class.name);
        SetCollision(true, false);
        bCollideWorld=True;
        bHidden = false;
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
        SetClientState(CS_Held);
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
    ignores Score, Touch, UsedBy;

    // There is a bug in UnrealScript where it can sometimes ignore the "ignore" statement and execute the global
    // funciton. Defining an empty function is safer.
    function ScoreOrHome() {}

    function BeginState()
    {
        SetClientState(CS_SettingUp);
        // log("State --> SettingUp", class.name);
        bActive = true;
        Disable('Touch');

        SetCollision(true, false);
        bCollideWorld=true;
        Velocity = PhysicsVolume.Gravity;
        SetPhysics(PHYS_Falling);

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
        BroadcastLocalizedMessage(TscMessages, 1+Team.TeamIndex*100);
        GotoState('Guarding');
    }
}

state Guarding
{
    ignores Score, Touch, UsedBy;

    function ScoreOrHome() {}

    function BeginState()
    {
        local Controller C;
        local ScrnPlayerController ScrnC;
        local rotator r;

        SetClientState(CS_Guarding);
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

        if ( bInvul )
            return;

        if ( damageType == class'DamTypeFrag' )
            Damage *= 5;
        if ( InstigatedBy != none )
            PC = ScrnPlayerController(InstigatedBy.Controller);
        if ( PC != none ) {
            PC.DamageMade(Damage, Hitlocation, 10);
        }
        StunDamage += Damage;
        StunFadeoutTime = Level.TimeSeconds + default.StunFadeoutTime;
        if ( StunDamage >= StunThreshold ) {
            GotoState('Stunned');
        }
    }

    function Timer()
    {
        local Controller C;
        local ScrnPlayerController SC;
        local bool bNobodyAtBase, bNobodyAlive;

        if ( StunDamage > 0 && Level.TimeSeconds > StunFadeoutTime ) {
            StunDamage -= StunFadeoutRate;
            if ( StunDamage < 0 )
                StunDamage = 0;
        }

        if (TSCGRI.EndGameType > 0)
            return; // game has ended

        bNobodyAtBase = true;
        bNobodyAlive = true;
        for ( C = Level.ControllerList; C != none; C = C.nextController ) {
            if ( C.bIsPlayer && C.Pawn != none && C.Pawn.Health > 0
                    && C.PlayerReplicationInfo != none )
            {
                if ( C.PlayerReplicationInfo.Team != Team && TSCGRI.AtBase(C.Pawn.Location, self) ) {
                    C.Pawn.TakeDamage(Damage, none, C.Pawn.Location, vect(0,0,0), class'DamTypeEnemyBase');
                    SC = ScrnPlayerController(C);
                    if (SC != none && SC.ScrnPawn != none && Level.TimeSeconds > SC.ScrnPawn.NextEnemyBaseDamageMsg) {
                        SC.ReceiveLocalizedMessage(TscMessages, 312);
                        SC.ScrnPawn.NextEnemyBaseDamageMsg = Level.TimeSeconds + 6.0;
                    }
                }
                else if (C.PlayerReplicationInfo.Team == Team) {
                    bNobodyAlive = false;
                    if (TSCGRI.AtBase(C.Pawn.Location, self)) {
                        bNobodyAtBase = false;
                    }
                    else {
                        SC = ScrnPlayerController(C);
                        if (SC != none && Level.TimeSeconds > SC.LastBaseMarkTime + 6.0) {
                            SC.ClientMark(KFPlayerReplicationInfo(SC.PlayerReplicationInfo), GetWorldActor(),
                                    GetLocation(), "", class'ScrnHUD'.default.MARK_BASE);
                            SC.LastBaseMarkTime = Level.TimeSeconds;

                            if (SameTeamCounter == default.SameTeamCounter
                                    && Level.TimeSeconds > SC.ScrnPawn.NextEnemyBaseDamageMsg) {
                                // Tell the player to return back to base, unless bNobodyAtBase triggered
                                // Or the player is at the enemy base (and received a different warning)
                                SC.ReceiveLocalizedMessage(TscMessages, 211);
                            }
                        }
                    }
                }
            }
        }

        if ( bNobodyAtBase ) {
            if ( bNobodyAlive || --SameTeamCounter <= 0 ) {
                if (ScrnGameType(Level.Game).ScrnBalanceMut.GameRules.IsEndGameDelayed()) {
                    // player crashed an might return
                    return;
                }
                BroadcastLocalizedMessage(TscMessages, 2+Team.TeamIndex*100);
                SendHome();
            }
            else if ( (SameTeamCounter & 3) == 0 ) {
                for ( C = Level.ControllerList; C != none; C = C.nextController ) {
                    if ( C.bIsPlayer && C.PlayerReplicationInfo != none
                            && C.Pawn != none && C.Pawn.Health > 0
                            && C.PlayerReplicationInfo.Team == Team )
                    {
                        SC = ScrnPlayerController(C);
                        if ( SC != none ) {
                            SC.ServerShowPathTo(1); // show path to base
                            if ( SameTeamCounter <= 12 && ShouldWipeOnBaseLost() )
                                SC.ReceiveLocalizedMessage(TscMessages, 311); // critical message
                            else
                                SC.ReceiveLocalizedMessage(TscMessages, 211);
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
    ignores Score, Touch, UsedBy, TakeDamage;

    function BeginState()
    {
        local rotator r;

        SetClientState(CS_Stunned);
        bStunned = true;
        // log("State --> Stunned", class.name);
        r = Rotation;
        r.Pitch = -16384;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_None);

        SetTimer(StunDuration, false);
        NetUpdateTime = Level.TimeSeconds - 1; // replicate immediately
        BroadcastLocalizedMessage(TscMessages, 3+Team.TeamIndex*100);
    }

    function EndState()
    {
        // log("State <-- Stunned", class.name);
        bStunned = false;
    }

    function ScoreOrHome()
    {
        GotoState('Guarding');
    }

    function Timer()
    {
        GotoState('WakingUp');
    }
}

state WakingUp
{
    ignores Score, Touch, UsedBy;

    function BeginState()
    {
        local rotator r;

        SetClientState(CS_WakingUp);
        bStunned = true;

        // log("State --> WakingUp", class.name);
        r = Rotation;
        r.Pitch = 0;
        r.Roll = 0;
        SetRotation(r);
        SetPhysics(PHYS_Rotating);

        SetTimer(WakeUpDuration, false);
        BroadcastLocalizedMessage(TscMessages, 4+Team.TeamIndex*100);
    }

    function EndState()
    {
        // log("State <-- WakingUp", class.name);
        bStunned = false;
    }

    function ScoreOrHome()
    {
        GotoState('Guarding');
    }

    function Timer()
    {
        BroadcastLocalizedMessage(TscMessages, 5+Team.TeamIndex*100);
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
    StunThreshold=500
    StunDuration=30
    WakeUpDuration=10
    StunFadeoutRate=50
    StunFadeoutTime=2.0
    SameTeamCounter=14
    bCanBeDamaged=False
    ClientState=CS_Home

    LightType=LT_None
    LightEffect=LE_QuadraticNonIncidence
    LightRadius=50
    GuardianLightRadius=50
    LightBrightness=100
    GuardianBrightness=100
    LightSaturation=127
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
