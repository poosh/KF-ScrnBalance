class ScrnGameReplicationInfo extends KFGameReplicationInfo;

var string GameTitle, GameAuthor;
var string WaveHeader, WaveTitle, WaveMessage;
var int WaveCounter;
var int SuicideTime;  // the value of ElapsedTime when team suicides. 0 - disabled
var transient int ClientSuicideTime, NextSuicideCheckTime;
var byte WaveEndRule;
var bool bTraderArrow;

var byte FakedPlayers, FakedAlivePlayers;


replication
{
    reliable if( bNetInitial && Role == ROLE_Authority )
        GameTitle, GameAuthor;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveHeader, WaveTitle, WaveMessage, WaveEndRule, bTraderArrow;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveCounter, SuicideTime;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        FakedPlayers, FakedAlivePlayers;
}

simulated function Timer()
{
    super.Timer();

    if ( Level.NetMode != NM_DedicatedServer ) {
        if ( SuicideTime > 0 && (ElapsedTime >= NextSuicideCheckTime || ClientSuicideTime != SuicideTime) ) {
            CheckSuicideMsg();
        }
    }
}

simulated function CheckSuicideMsg()
{
    local PlayerController PC;
    local int TimeLeft, DisplayDuration;
    local bool bTimeUpdated;

    bTimeUpdated = ClientSuicideTime != SuicideTime;
    ClientSuicideTime = SuicideTime;
    if ( SuicideTime == 0 )
        return;

    TimeLeft = SuicideTime - ElapsedTime;
    if ( TimeLeft >= 3600 ) {
        NextSuicideCheckTime = TimeLeft - 3600;
        return;
    }

    if ( TimeLeft <= 60 ) {
        DisplayDuration = TimeLeft + 10;
        NextSuicideCheckTime = ElapsedTime + DisplayDuration;
    }
    else {
        DisplayDuration = 10;
        // display every 5 minutes if T > 5m, or every minute if T < 5m;
        if ( TimeLeft > 300 ) {
            NextSuicideCheckTime = SuicideTime - TimeLeft / 300 * 300;
        }
        else {
            NextSuicideCheckTime = SuicideTime - TimeLeft / 60 * 60;
        }

        if ( NextSuicideCheckTime - ElapsedTime < 2*DisplayDuration ) {
            return; // too close to the next display time - ignore for now
        }
    }

    PC = Level.GetLocalPlayerController();
    if ( PC == none )
        return;

    class'ScrnSuicideMsg'.default.Lifetime = DisplayDuration;
    PC.ReceiveLocalizedMessage(class'ScrnSuicideMsg', 0, PC.PlayerReplicationInfo, , self);
}


defaultproperties
{
    WaveEndRule=0 // RULE_KillEmAll
    bTraderArrow=True
}
