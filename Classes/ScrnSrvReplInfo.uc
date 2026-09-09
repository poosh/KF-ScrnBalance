// This is general class to replicate all ScrN settings from server to clients
// In the future ScrnBalance class will be server-side only and all replication info
// will be moved here

class ScrnSrvReplInfo extends ReplicationInfo;

var private transient ScrnSrvReplInfo Me;

var bool bForceSteamNames;

var byte PlayerUpdateCounter;
var transient byte OldPlayerUpdateCounter;
var transient byte Attempts;

replication
{
    // flags to replicate config variables
    reliable if ( bNetInitial && Role == ROLE_Authority )
        bForceSteamNames;

    // must be bNetDirty - the whole point is that it changes during the match
    reliable if ( bNetDirty && Role == ROLE_Authority )
        PlayerUpdateCounter;
}


static final function ScrnSrvReplInfo Instance()
{
    return class'ScrnSrvReplInfo'.default.Me;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    // ScrnSrvReplInfo is supposed to be a singleton
    if (class'ScrnSrvReplInfo'.default.Me != none && class'ScrnSrvReplInfo'.default.Me != self)
        class'ScrnSrvReplInfo'.default.Me.Destroy();

    if (Role == ROLE_Authority) {
        class'ScrnSrvReplInfo'.default.Me = self;
        Me = self;
    }
    else {
        // need to wait until initial replication before this class can be used
        class'ScrnSrvReplInfo'.default.Me = none;
        Me = none;
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if (Role == ROLE_Authority)
        return;

    class'ScrnSrvReplInfo'.default.Me = self;
    Me = self;

    GotoState('WaitingForLocalPlayerName');
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if (PlayerUpdateCounter != OldPlayerUpdateCounter) {
        OldPlayerUpdateCounter = PlayerUpdateCounter;
        if (!RefreshPlayerNames()) {
            // ScrnCustomPRI hasn't replicated yet
            WaitForPlayerNames();
        }
    }
}

simulated function WaitForPlayerNames()
{
    if (Role < ROLE_Authority) {
        GotoState('UpdatingPlayerNames');
    }
}

function NotifyPlayerNameChange()
{
    ++PlayerUpdateCounter;
    NetUpdateTime = Level.TimeSeconds - 1;
    RefreshPlayerNames();
}

// @return false, if at least one non-bot PRI has no ScrnCustomPRI yet (not replicated).
simulated function bool RefreshPlayerNames()
{
    local int i;
    local PlayerReplicationInfo PRI;
    local ScrnCustomPRI ScrnPRI;
    local bool bAllResolved;

    if (Level.GRI == none)
        return false;

    bAllResolved = true;
    for (i = 0; i < Level.GRI.PRIArray.Length; ++i) {
        PRI = Level.GRI.PRIArray[i];
        if (PRI == none)
            continue;

        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
        if (ScrnPRI != none) {
            ScrnPRI.UpdatePlayerNames();
        }
        else if (!PRI.bBot) {
            bAllResolved = false; // bots never own a ScrnCustomPRI
        }
    }
    return bAllResolved;
}

simulated function Destroyed()
{
    if ( class'ScrnSrvReplInfo'.default.Me == self ) {
        class'ScrnSrvReplInfo'.default.Me = none;
    }
    super.Destroyed();
}

simulated state WaitingForLocalPlayerName
{
    // We transition to UpdatingPlayerNames later
    simulated function WaitForPlayerNames() {}

    simulated function BeginState()
    {
        SetTimer(2.0, true);
        Attempts = 0;
    }

    simulated function EndState()
    {
        SetTimer(0, false);
    }

    simulated function Timer()
    {
        local ScrnPlayerController PC;

        PC = ScrnPlayerController(Level.GetLocalPlayerController());
        if (PC != none && PC.PlayerName != "") {
            PC.SetName(PC.PlayerName);
            GotoState('UpdatingPlayerNames');
        }
        else if (++Attempts >= 5) {
            // Give up waiting for the local player - the other names still need to be resolved.
            GotoState('UpdatingPlayerNames');
        }
    }
}

simulated state UpdatingPlayerNames
{
    simulated function BeginState()
    {
        Attempts = 0;
        SetTimer(1.0, true);
    }

    simulated function EndState()
    {
        SetTimer(0, false);
    }

    simulated function Timer()
    {
        if (RefreshPlayerNames() || ++Attempts >= 10)
            GotoState('');
    }
}

defaultproperties
{
    bForceSteamNames=True
    bNetNotify=True
}
