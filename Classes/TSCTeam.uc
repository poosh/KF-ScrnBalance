class TSCTeam extends xTeamRoster;

var TSCClanReplicationInfo ClanRep;

var int ZedKills, Deaths;
var int LastMinKills;       // how many kills team scored, exluding current minute
var int PrevMinKills;       // how many kills team scored, exluding current and previous minute
var int WaveKills;          // how many kills team scored in previous waves
var int Health;             // total health of all players in the team
var int Armor;              // total health of all players in the team

var int InventorySellValue; // total sell value of all inventory items of all team members

var Material TeamLogos[2];

replication
{
    // Variables the server should send to the client.
    reliable if( bNetDirty && (Role==ROLE_Authority) )
        ClanRep;

    reliable if( bNetDirty && (Role==ROLE_Authority) )
        ZedKills, Deaths, LastMinKills, PrevMinKills, WaveKills,
        InventorySellValue, Health, Armor;
}

simulated function int GetCurWaveKills()
{
    return max(0, ZedKills - WaveKills);
}

simulated function int GetCurMinuteKills()
{
    return max(0, ZedKills - LastMinKills);
}

simulated function int GetPrevMinuteKills()
{
    return max(0, LastMinKills - PrevMinKills);
}

function CalcInventorySellValue()
{
    local Controller C;
    local ScrnHumanPawn ScrnPawn;
    local int val;

    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if (C.PlayerReplicationInfo == none || C.PlayerReplicationInfo.Team != self || C.Pawn == none)
            continue;

        ScrnPawn = ScrnHumanPawn(C.Pawn);
        if (ScrnPawn != none) {
            val += ScrnPawn.CalcTotalSellValue();
        }

    }
    InventorySellValue = val;
}

function bool AddToTeam( Controller Other )
{
    local bool result;

    result = super.AddToTeam(Other);
    if (result && ScrnHumanPawn(Other.Pawn) != none) {
        CalcInventorySellValue();
    }
    return result;
}

function RemoveFromTeam(Controller Other)
{
    super.RemoveFromTeam(Other);
    CalcInventorySellValue();
}

simulated function string GetHumanReadableName()
{
    if (ClanRep != none)
        return ClanRep.ClanName;

    if (TeamIndex < 2)
        return ColorNames[TeamIndex];
    return TeamName @ TeamIndex;
}

simulated function Material GetLogo()
{
    if (ClanRep != none && ClanRep.Logo != none)
        return ClanRep.Logo;

    if (TeamIndex < 2)
        return TeamLogos[TeamIndex];

    return none;
}

defaultproperties
{
    ColorNames(0)="British"
    ColorNames(1)="Steampunk"

    TeamLogos(0)=Texture'TSC_T.Team.BritishLogo'
    TeamLogos(1)=Texture'TSC_T.Team.SteampunkLogo'
}