class TSCMessages extends CriticalEventPlus;

var color RedTeamColor,BlueTeamColor,WarningColor;

var(Message) localized string strEnemyShop;
var(Message) localized string strWaveEnding;
var(Message) localized string strSeconds;
var(Message) localized string strEnemyDmgEnabled, strHDmgEnabled, strHDmgDisabled;
var(Message) localized string strOvertime;
var(Message) localized string strSuddenDeath;
var(Message) localized string strGetBackToBase;
var(Message) localized string strGetBackToBaseOrDie;
var(Message) localized string strGetOutFromBase;
var(Message) localized string strPendingShuffle;
var(Message) localized string strTeamShuffle;
var(Message) localized string strBaseZ;
var(Message) localized string strBaseShop;
var(Message) localized string strTeamLocked;
var(Message) localized string strTeamUnlocked;

var(Message) localized string strBaseEstablished[2];
var(Message) localized string strBaseLost[2];
var(Message) localized string strTeamWiped[2];
var(Message) localized string strBaseStunned[2];
var(Message) localized string strBaseWakeUp[2];

var(Message) localized string strTeamNames[2];


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch) {
        // red team
        case   1:   return default.strBaseEstablished[0];
        case   2:   return default.strBaseLost[0];
        case   3:   return default.strBaseStunned[0];
        case   4:   return default.strBaseWakeUp[0];
        case  10:   return default.strTeamWiped[0];

        // blue team
        case 101:   return default.strBaseEstablished[1];
        case 102:   return default.strBaseLost[1];
        case 103:   return default.strBaseStunned[1];
        case 104:   return default.strBaseWakeUp[1];
        case 110:   return default.strTeamWiped[1];

        case 200:    return default.strWaveEnding @ class'TSCGame'.default.WaveEndingCountDown @ default.strSeconds;
        case 201:    return default.strOvertime;
        case 202:    return default.strSuddenDeath;
        case 211:    return default.strGetBackToBase;
        case 230:    return default.strHDmgDisabled;
        case 231:    return default.strHDmgEnabled;
        case 232:    return default.strEnemyDmgEnabled;
        case 240:    return default.strPendingShuffle;
        case 241:    return default.strTeamShuffle;
        case 242:    return default.strTeamUnlocked;
        case 243:    return default.strTeamLocked;

        // warning
        case 300:    return default.strEnemyShop;
        case 302:    return default.strSuddenDeath;
        case 310:    return default.strBaseZ;
        case 311:    return default.strGetBackToBaseOrDie;
        case 312:    return default.strGetOutFromBase;
        case 313:    return default.strBaseShop;


    }
    return "";
}

static function string TeamName(TeamInfo Team)
{
    if ( Team != none && Team.TeamIndex < 2 )
        return default.strTeamNames[Team.TeamIndex];

    return "";
}

static function color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    if ( Switch < 100 )
        return default.RedTeamColor;
    else if ( Switch < 200 )
        return default.BlueTeamColor;
    else if ( Switch >= 300 )
        return default.WarningColor;

    return Default.DrawColor;
}

defaultproperties
{
    RedTeamColor=(R=255,G=50,B=50,A=255)
    BlueTeamColor=(R=75,G=139,B=198,A=255)
    WarningColor=(R=255,G=128,B=0,A=255)
    DrawColor=(R=225,G=200,B=64,A=255)
    PosX=0.500000
    PosY=0.60
    FontSize=3
    Lifetime=5

    strTeamNames(0)="British"
    strTeamNames(1)="Steampunk"

    strWaveEnding="Wave will end in"
    strSeconds="seconds"
    strHDmgDisabled="Human Damage OFF"
    strHDmgEnabled="Human Damage ON"
    strEnemyDmgEnabled="Enemy Damage ON"
    strOvertime="Overtime Wave"
    strSuddenDeath="SUDDEN DEATH"

    strEnemyShop="Can not trade in Enemy Shop!"
    strBaseZ="Can not set up a Base just below the Enemy Base!"
    strGetBackToBase="GET BACK TO THE BASE! Or it will be lost."
    strGetBackToBaseOrDie="GET BACK TO THE BASE OR DIE!"
    strGetOutFromBase="You are at the ENEMY BASE! Get out of here!"
    strBaseShop="Can not set up a Base inside a Shop!"

    strPendingShuffle="Teams will be shuffled at the end of the wave"
    strTeamShuffle="Teams shuffled"
    strTeamLocked="Teams locked. New players can join only by invite."
    strTeamUnlocked="Teams unlocked. Everybody can join the game."

    strBaseEstablished(0)="British Base established"
    strBaseEstablished(1)="Steampunk Base established"
    strBaseLost(0)="British Base lost"
    strBaseLost(1)="Steampunk Base lost"
    strTeamWiped(0)="British Squad WIPED!"
    strTeamWiped(1)="Steampunk Squad WIPED!"
    strBaseStunned(0)="British Guardian stunned"
    strBaseStunned(1)="Steampunk Guardian stunned"
    strBaseWakeUp(0)="British Guardian woke up"
    strBaseWakeUp(1)="Steampunk Guardian woke up"

}