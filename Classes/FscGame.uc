class FscGame extends FtgGame
    config;

defaultproperties
{
    GameName="FTG Survival Competition"
    Description="FTG+TSC: Follow The Guardian + Team Survival Competition combined into one game."
    ScreenShotName="TSC_T.Team.BritishLogo"

    bSingleTeamGame=False
    bUseEndGameBoss=False
    MinBaseZ=-60
    MaxBaseZ=200
    OvertimeWaves=2 // if both teams survived regular waves, add 2 overtime waves
    SudDeathWaves=1 // if both team survived overtime waves, add a Sudden Death wave

    BaseGuardianClasses(0)=class'ScrnBalanceSrv.TheGuardianRed'
    BaseGuardianClasses(1)=class'ScrnBalanceSrv.TheGuardianBlue'
    StinkyClass=class'ScrnBalanceSrv.StinkyClot'
