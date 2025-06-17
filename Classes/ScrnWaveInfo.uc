Class ScrnWaveInfo extends Object
    PerObjectConfig
    Config(ScrnWaves);

enum EWaveEndRule {
    RULE_KillEmAll,
    RULE_SpawnEmAll,
    RULE_Timeout,
    RULE_EarnDosh,
    RULE_KillBoss,
    RULE_GrabDosh,
    RULE_GrabDoshZed,
    RULE_GrabAmmo,
    RULE_KillSpecial,
    RULE_ReachTrader,
};

enum EDoorControl {
    DOOR_Default,
    DOOR_Respawn,
    DOOR_Blow,
    DOOR_Unweld,
    DOOR_UnweldRespawn,
    DOOR_Weld1p,
    DOOR_WeldHalf,
    DOOR_WeldFull,
    DOOR_WeldRandom,
    DOOR_Randomize
};

enum EFtgRule {
    FTG_Standard,
    FTG_NoStinky,
    FTG_TSCBase,
    FTG_NoBase
};

var config int GameVersion;
var config string Header, Title, Message, TraderMessage;
var config int TraderTime;
var config bool bOpenTrader;
var config bool bRespawnDeadPlayers;
var config bool bStartAtTrader;
var config bool bTraderArrow;
var config EDoorControl DoorControl, DoorControl2;
var config EWaveEndRule EndRule;
var config EFtgRule FtgRule;

var config int Counter, MaxCounter;
var config float PerPlayerMult;
var config int PerPlayerExclude;
var config int Timelimit;
var config float SpawnRateMod;
var config float SpecialSquadCooldown;
var config byte MaxZombiesOnce;
var config float BountyScale;
var config bool bNoBounty;
var config int NoBountyTimeout;
var config int CashBonus;
var config float XP_Bonus, XP_BonusAlive;
var config int SuicideTime;
var config float SuicideTimePerPlayerMult;
var config bool bSuicideTimeReset;
var config bool bMoreAmmoBoxes;

var config bool bRandomSpawnLoc, bForceFastTrack;
var config float SpecialSquadHealthMod;
var config int ZedsBeforeSpecialSquad, ZedsPerSpecialSquad;
var config bool bRandomSquads;
var config bool bRandomSpecialSquads;
var config array<string> SpecialSquads;
var config array<string> Squads;

var transient bool bRandomlyPicked;

defaultproperties
{
    TraderTime=60
    bOpenTrader=true
    bRespawnDeadPlayers=true
    bTraderArrow=true
    DoorControl=DOOR_Default
    EndRule=RULE_KillEmAll
    FtgRule=FTG_Standard
    Counter=30
    PerPlayerExclude=1
    SpecialSquadHealthMod=1.0
    ZedsPerSpecialSquad=50
    SpawnRateMod=1.0
    SpecialSquadCooldown=3.0;
    Squads(0)="4*CL"
    bRandomSquads=true
    bRandomSpecialSquads=true
}
