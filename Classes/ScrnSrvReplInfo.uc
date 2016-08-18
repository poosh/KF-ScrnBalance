// This is general class to replicate all ScrN settings from server to clients
// In the future ScrnBalance class will be server-side only and all replication info
// will be moved here

class ScrnSrvReplInfo extends ReplicationInfo;

var private transient ScrnSrvReplInfo Me;

var bool bForceSteamNames;


replication
{
    // flags to replicate config variables
    reliable if ( bNetInitial && Role == ROLE_Authority )
        bForceSteamNames;
}


static final function ScrnSrvReplInfo Instance()
{
    return class'ScrnSrvReplInfo'.default.Me;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    
    // ScrnSrvReplInfo is supposed to be a singleton
    if ( class'ScrnSrvReplInfo'.default.Me != none && class'ScrnSrvReplInfo'.default.Me != self )
        class'ScrnSrvReplInfo'.default.Me.Destroy();

    if ( Role == ROLE_Authority )
    {
        class'ScrnSrvReplInfo'.default.Me = self;
        Me = self;
    }
    else 
    {
        // need to wait until initial replication before this class can be used
        class'ScrnSrvReplInfo'.default.Me = none;
        Me = none;
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    
    if ( Role == ROLE_Authority ) 
        return; 
        
    class'ScrnSrvReplInfo'.default.Me = self;
    Me = self;   
    
    SetTimer(2.0, false);
}

simulated function Timer()
{
    local ScrnPlayerController PC;

    PC = ScrnPlayerController(Level.GetLocalPlayerController());
    if ( PC != none ) {
        if ( PC.PlayerName != "" )
            PC.SetName(PC.PlayerName);
    }
}

simulated function Destroyed()
{
    if ( class'ScrnSrvReplInfo'.default.Me == self ) {
        class'ScrnSrvReplInfo'.default.Me = none;
    }
    super.Destroyed();
}

defaultproperties
{
    bForceSteamNames=True
}
