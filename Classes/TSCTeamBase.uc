class TSCTeamBase extends GameObject
abstract;

var bool bActive, bStunned;

replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        bActive, bStunned;
}

simulated function vector GetLocation()
{
    return Location;
}