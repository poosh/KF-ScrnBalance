// this class is reserved for TSC
class TSCGameReplicationInfoBase extends KFGameReplicationInfo
abstract;

var ShopVolume BlueShop;
var transient bool bSuddenDeath;

var byte HumanDamageMode;

var PlayerReplicationInfo TeamCaptain[2];   // MVOTE TEAM CAPTAIN
var PlayerReplicationInfo TeamCarrier[2];   // MVOTE TEAM CARRIER

replication
{
	reliable if( bNetDirty && Role == ROLE_Authority )
		BlueShop, bSuddenDeath,
        HumanDamageMode, TeamCaptain, TeamCarrier;
}

simulated function ShopVolume GetPlayerShop(PlayerReplicationInfo PRI)
{
    if ( PRI == none || PRI.Team == none )
        return none;
    
    switch ( PRI.Team.TeamIndex ) {
        case 0:
            return CurrentShop;
            break;
        case 1:
            return BlueShop;
            break;
    }
    return none;    
}

simulated function ShopVolume GetTeamShop(int TeamNum)
{
    switch ( TeamNum ) {
        case 0:
            return CurrentShop;
            break;
        case 1:
            return BlueShop;
            break;
    }
    return none;  
}

simulated function bool AtBase(Vector CheckLocation, Actor TeamBase)
{
    return false;
}
