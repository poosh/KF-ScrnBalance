class ScrnTestGame extends ScrnGameType;

event InitGame( string Options, out string Error )
{
    super.InitGame(Options, Error);

    ScrnBalanceMut.SetTestMap();
}

function bool IsTestMap()
{
    return true;
}

defaultproperties
{
    GameName="ScrN Test Game"
    Description="ScrN Floor's modification for test maps"
    Acronym="KFT"
    MapPrefix="KFT"
    MapListType="ScrnBalanceSrv.ScrnTestMapList"
    DefaultGameLength=8
}
