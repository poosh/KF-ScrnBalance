class ScrnGameReplicationInfo extends KFGameReplicationInfo;

var string WaveTitle, WaveMessage;
var byte WaveEndRule;

replication
{
	reliable if( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
		WaveTitle, WaveMessage, WaveEndRule;
}

defaultproperties
{
    WaveEndRule=0 // RULE_KillEmAll
}