class FscGame extends FtgGame
    config;

defaultproperties
{
    GameName="FTG Survival Competition"
    Description="FTG+TSC: Follow The Guardian + Team Survival Competition combined into one game."
    ScreenShotName="TSC_T.Team.BritishLogo"

    DefaultGameLength=40
    bSingleTeamGame=false
    bUseEndGameBoss=false
    MinBaseZ=-60
    MaxBaseZ=200

    ScoreBoardType="ScrnBalanceSrv.TSCScoreBoard"
    BaseGuardianClasses(0)=class'FtgBaseGuardianRed'
    BaseGuardianClasses(1)=class'FtgBaseGuardianBlue'
    StinkyClass=class'StinkyClot'
}
