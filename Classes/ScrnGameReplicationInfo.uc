class ScrnGameReplicationInfo extends KFGameReplicationInfo;

var string GameTitle;
var string WaveTitle, WaveMessage;
var byte WaveEndRule;
var int WaveCounter;

var byte FakedPlayers, FakedAlivePlayers;

replication
{
	reliable if( bNetInitial && Role == ROLE_Authority )
		GameTitle;

	reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
		WaveTitle, WaveMessage, WaveEndRule;

	reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
		WaveCounter;

	reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
		FakedPlayers, FakedAlivePlayers;
}

defaultproperties
{
    WaveEndRule=0 // RULE_KillEmAll
}
