class ScrnGameReplicationInfo extends KFGameReplicationInfo;

var string GameTitle, GameAuthor;
var int GameVersion;
var string WaveHeader, WaveTitle, WaveMessage;
var int WaveCounter;
var int EndGameCounter;
var byte WaveEndRule;
var bool bTraderArrow;

var byte FakedPlayers, FakedAlivePlayers;
var byte NewDifficulty;  // allows changing difficulty mid-game

var class<LocalMessage> RemainingTimeMsg;
var transient float LastBeepTime;

replication
{
    reliable if( bNetInitial && Role == ROLE_Authority )
        GameTitle, GameAuthor, GameVersion;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveHeader, WaveTitle, WaveMessage, WaveEndRule, bTraderArrow;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveCounter;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        FakedPlayers, FakedAlivePlayers, NewDifficulty;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    // Level.TimeDilation does NOT affect KFGameType's timer rate, which is always 1.1. Same here.
    SetTimer(1.1, true);
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    SetTimer(1.1, true);
}

simulated function PostNetReceive()
{
    if ( NewDifficulty != 0 ) {
        BaseDifficulty = NewDifficulty;
        GameDiff = NewDifficulty;
        NewDifficulty = 0;
    }
}

simulated function Timer()
{
    local int i;
    local PlayerReplicationInfo OldHolder[2];
    local Controller C;
    local bool bTimeSync, bForceDisplay;

    if ( Level.NetMode == NM_Client ) {
        if ( bMatchHasBegun ) {
            ElapsedTime++;
        }

        if ( RemainingMinute != 0 ) {
            bTimeSync = true;
            bForceDisplay = abs(RemainingMinute - RemainingTime) >= 60;
            RemainingTime = RemainingMinute;
            RemainingMinute = 0;
        }
        if ( RemainingTime > 0 && !bStopCountDown ) {
            RemainingTime--;
            if ( bTimeSync || ElapsedTime == 1 ) {
                ShowTimeMsg(bForceDisplay);
            }
        }
        else {
            LastBeepTime = 0;
        }

        if ( !bTeamSymbolsUpdated )
            TeamSymbolNotify();

        if ( EndGameType > 0 ) {
            EndGameCounter++;
            if (EndGameCounter == 5) {
                if ( EndGameType == 2 ) {
                    // won the game = get rid of suicide bombs
                    // do it locally to show the disintegration effect. At this moment, server replication is halted.
                    class'ScrnSuicideBomb'.static.DisintegrateAll(Level);
                }
            }
        }
    }
    else if ( Level.NetMode != NM_Standalone ) {
        OldHolder[0] = FlagHolder[0];
        OldHolder[1] = FlagHolder[1];
        FlagHolder[0] = None;
        FlagHolder[1] = None;
        for ( i=0; i<PRIArray.length; i++ )
            if ( (PRIArray[i].HasFlag != None) && (PRIArray[i].Team != None) )
                FlagHolder[PRIArray[i].Team.TeamIndex] = PRIArray[i];

        for ( i=0; i<2; i++ )
            if ( OldHolder[i] != FlagHolder[i] )
            {
                for ( C=Level.ControllerList; C!=None; C=C.NextController )
                    if ( PlayerController(C) != None )
                        PlayerController(C).ClientUpdateFlagHolder(FlagHolder[i],i);
            }
    }
}

simulated function ShowTimeMsg(optional bool bForceDisplay)
{
    local PlayerController PC;
    local int Beep;

    if ( RemainingTimeMsg == none || Level.NetMode == NM_DedicatedServer )
        return;

    PC = Level.GetLocalPlayerController();
    if ( PC == none )
        return;

    if ( RemainingTime >= 3600 )
        return;

    if ( RemainingTime <= 60 ) {
        Beep = 1;
        RemainingTimeMsg.default.Lifetime = RemainingTime + 10;
        if ( RemainingTime < 30 ) {
            RemainingTimeMsg.default.Lifetime += 10;
        }
    }
    else {
        if ( !bForceDisplay ) {
            // display every five minutes, or every minute during the last 5m
            if ( (RemainingTime > 300 && class'ScrnF'.static.mod(RemainingTime, 300) != 0)
                    || class'ScrnF'.static.mod(RemainingTime, 60) != 0 )
            {
                return;
            }
        }
        Beep = int(LastBeepTime == 0);
        RemainingTimeMsg.default.Lifetime = 10;
    }

    if ( Beep > 0 ) {
        LastBeepTime = Level.TimeSeconds;
    }
    PC.ReceiveLocalizedMessage(RemainingTimeMsg, Beep, PC.PlayerReplicationInfo, , self);
}


defaultproperties
{
    bNetNotify = true;
    RemainingTimeMsg=class'ScrnBalanceSrv.ScrnSuicideMsg'
    WaveEndRule=0 // RULE_KillEmAll
    bTraderArrow=True
}
