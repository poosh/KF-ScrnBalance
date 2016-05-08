class TSCTeamBase extends GameObject
abstract;

var bool bActive;

replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        bActive;
}

simulated function vector GetLocation()
{
    return Location;
}