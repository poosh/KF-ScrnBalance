class ScrnGameReplicationInfo extends KFGameReplicationInfo;

var string GameTitle;
var string WaveHeader, WaveTitle, WaveMessage;
var byte WaveEndRule;
var int WaveCounter;
var bool bTraderArrow;

var byte FakedPlayers, FakedAlivePlayers;

replication
{
    reliable if( bNetInitial && Role == ROLE_Authority )
        GameTitle;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveHeader, WaveTitle, WaveMessage, WaveEndRule, bTraderArrow;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        WaveCounter;

    reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        FakedPlayers, FakedAlivePlayers;
}

defaultproperties
{
    WaveEndRule=0 // RULE_KillEmAll
    bTraderArrow=True
}
