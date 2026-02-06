class TSCTeamBase extends GameObject
abstract;

var bool bActive, bStunned, bInvul;
var byte HealthPct;

replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        bActive, bStunned, bInvul, HealthPct;
}

simulated function vector GetLocation()
{
    return Location;
}