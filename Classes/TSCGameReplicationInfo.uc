class TSCGameReplicationInfo extends ScrnGameReplicationInfo;

var bool bSingleTeamGame;
var ShopVolume BlueShop;
var byte OvertimeWaves;         // number of Overtime waves
var byte SudDeathWaves;         // number of Sudden Death waves
var transient bool bOverTime, bSuddenDeath;
var byte HumanDamageMode;
var bool bHumanDamageEnabled;
var bool bHumanDamageAtBaseIntersection;

var PlayerReplicationInfo TeamCaptain[2];   // MVOTE TEAM CAPTAIN
var PlayerReplicationInfo TeamCarrier[2];   // MVOTE TEAM CARRIER
var float BaseRadiusSqr; // Base radius squared, set from TSCGameType
var float MinBaseZ, MaxBaseZ; // min and max Z difference between player and base, set from TSCGameType

var int WaveKillReq; // required kills in the current wave for both team

replication
{
    reliable if ( bNetInitial && Role==ROLE_Authority )
        bSingleTeamGame, bHumanDamageAtBaseIntersection, OvertimeWaves, SudDeathWaves,
        BaseRadiusSqr, MinBaseZ, MaxBaseZ;

    reliable if( bNetDirty && Role == ROLE_Authority )
        BlueShop, bOverTime, bSuddenDeath,
        bHumanDamageEnabled, HumanDamageMode, TeamCaptain, TeamCarrier,
        WaveKillReq;
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

simulated function bool AtBase(Vector CheckLocation, Actor TeamBase, optional bool bIgnoreStunned)
{
    local float ZDiff;
    local TSCBaseGuardian gnome;

    gnome = TSCBaseGuardian(TeamBase);
    if ( gnome == none )
        return false;

    if ( !gnome.bActive && (!gnome.bStunned || bIgnoreStunned) )
        return false;


    ZDiff = CheckLocation.Z - gnome.GetLocation().Z;
    return ZDiff >= MinBaseZ && ZDiff <= MaxBaseZ
        && VSizeSquared(CheckLocation - gnome.GetLocation()) < BaseRadiusSqr;
}

simulated function bool AtOwnBase(Pawn Player, optional bool bIgnoreStunned)
{
    if ( Player.PlayerReplicationInfo == none || Player.PlayerReplicationInfo.Team == none )
        return false;

    return AtBase(Player.Location, Player.PlayerReplicationInfo.Team.HomeBase, bIgnoreStunned);
}

simulated function bool AtEnemyBase(Pawn Player, optional bool bIgnoreStunned)
{
    local int TeamIndex;

    if ( Player.PlayerReplicationInfo == none || Player.PlayerReplicationInfo.Team == none )
        return false;

    TeamIndex = Player.PlayerReplicationInfo.Team.TeamIndex;
    if ( TeamIndex < 0 || TeamIndex > 1 )
        return false;

    return AtBase(Player.Location, Teams[1-TeamIndex].HomeBase, bIgnoreStunned);
}

// TeamNum must be 0 or 1
static function int GetTeamCmbValue(int CmdValue, byte TeamNum)
{
    return (CmdValue >>> ((TeamNum & 1) << 3)) & 0xFFFF;
}

static function int SetTeamCmbValue(int Team0Val, int Team1Val)
{
    return ((Team1Val & 0xFFFF) << 8) | (Team0Val & 0xFFFF);
}


defaultproperties
{
    BaseRadiusSqr=1562500 // 25 m
    MinBaseZ=-60
    MaxBaseZ=200
    bHumanDamageAtBaseIntersection=true
}
