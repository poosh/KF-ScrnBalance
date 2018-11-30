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
    RULE_GrabAmmo
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

var config string Header, Title, Message, TraderMessage;
var config int TraderTime;
var config bool bOpenTrader;
var config bool bRespawnDeadPlayers;
var config bool bStartAtTrader;
var config bool bTraderArrow;
var config EDoorControl DoorControl, DoorControl2;
var config EWaveEndRule EndRule;
var config int Counter, MaxCounter;
var config float PerPlayerMult;
var config float SpawnRateMod;
var config byte MaxZombiesOnce;
var config float BountyScale;
var config float XP_Bonus, XP_BonusAlive;

var config bool bRandomSpawnLoc;
var config float SpecialSquadHealthMod;
var config int ZedsPerSpecialSquad;
var config bool bRandomSquads;
var config bool bRandomSpecialSquads;
var config array<string> SpecialSquads;
var config array<string> Squads;

defaultproperties
{
    TraderTime=60
    bOpenTrader=true
    bRespawnDeadPlayers=true
    bTraderArrow=true
    DoorControl=DOOR_Default
    EndRule=RULE_KillEmAll
    Counter=30
    SpecialSquadHealthMod=1.0
    ZedsPerSpecialSquad=50
    SpawnRateMod=1.0
    Squads(0)="4*CL"
    bRandomSquads=true
    bRandomSpecialSquads=true
}
