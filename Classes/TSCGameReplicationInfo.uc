class TSCGameReplicationInfo extends ScrnGameReplicationInfo;

var bool bSingleTeamGame;
var ShopVolume BlueShop;
var byte OvertimeWaves;         // number of Overtime waves
var byte SudDeathWaves;         // number of Sudden Death waves
var transient bool bSuddenDeath;
var byte HumanDamageMode;

var PlayerReplicationInfo TeamCaptain[2];   // MVOTE TEAM CAPTAIN
var PlayerReplicationInfo TeamCarrier[2];   // MVOTE TEAM CARRIER
var float BaseRadiusSqr; // Base radius squared, set from TSCGameType
var float MinBaseZ, MaxBaseZ; // min and max Z difference between player and base, set from TSCGameType

replication
{
    reliable if ( bNetInitial && Role==ROLE_Authority )
        bSingleTeamGame, OvertimeWaves, SudDeathWaves,
        BaseRadiusSqr, MinBaseZ, MaxBaseZ;

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
    local float ZDiff;
    local TSCBaseGuardian gnome;

    gnome = TSCBaseGuardian(TeamBase);
    if ( gnome == none || !gnome.bActive )
        return false;

    ZDiff = CheckLocation.Z - gnome.GetLocation().Z;
    return ZDiff >= MinBaseZ && ZDiff <= MaxBaseZ
        && VSizeSquared(CheckLocation - gnome.GetLocation()) < BaseRadiusSqr;
}

simulated function bool AtOwnBase(Pawn Player)
{
    if ( Player.PlayerReplicationInfo == none || Player.PlayerReplicationInfo.Team == none )
        return false;

    return AtBase(Player.Location, Player.PlayerReplicationInfo.Team.HomeBase);
}

simulated function bool AtEnemyBase(Pawn Player)
{
    local int TeamIndex;

    if ( Player.PlayerReplicationInfo == none || Player.PlayerReplicationInfo.Team == none )
        return false;

    TeamIndex = Player.PlayerReplicationInfo.Team.TeamIndex;
    if ( TeamIndex < 0 || TeamIndex > 1 )
        return false;

    return AtBase(Player.Location, Teams[1-TeamIndex].HomeBase);
}


defaultproperties
{
    BaseRadiusSqr=1562500 // 25 m
    MinBaseZ=-60
    MaxBaseZ=200
}