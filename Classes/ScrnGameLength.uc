Class ScrnGameLength extends Object
    dependson(ScrnTypes)
    PerObjectConfig
    Config(ScrnGames);

// Deprecated config options. Those will be delete in future, so make sure not to use them.
var deprecated bool bStartingCashReset;
var deprecated int StartingCashBonus;
var deprecated bool bStartingCashRelative;


var config int GameVersion;
var config string GameTitle;
var config string Author;
var config int StartDosh, StartDoshPerWave, StartDoshMin, StartDoshMax;
var config float BountyScale;
var config array<string> ServerPackages;
var config array<string> Mutators;
var config array<string> Waves;
var config array<string> Zeds;
var config bool bUniqueWaves;
var config bool bAllowZedEvents;
var config byte ForceZedEvent, FallbackZedEvent;
var config int SmallMapZeds, NormalMapZeds, BigMapZeds, WideOpenMapZeds;
var config bool bLogStats;
var config bool bDebug, bTest;
var config ScrnTypes.EZedTimeTrigger ZedTimeTrigger;
var config float ZedTimeChanceMult;
var config byte ZedTimeDuration;
var config bool bRandomTrader;
var config int TraderSpeedBoost;
var config int SuicideTime;
var config int SuicideTimePerWave;
var config float SuicideTimePerPlayerMult, SuicideTimePerPlayerDeath;
var config float FriendlyFireScale;

struct SHL {
    var byte Difficulty;
    var int HL;
};
var config array<SHL> HardcoreLevel;
var config float HLMult;
var config byte MinDifficulty, MaxDifficulty;
var config byte MinBonusLevel, MaxBonusLevel;
var config bool bForceTourney;
var config int TourneyFlags;
var config array<name> AllowWeaponPackages;
var config array<name> BlockWeaponPackages;
var config array<string> AllowWeaponLists;
var config array<string> BlockWeaponLists;
var config array<name> AllowPerks;
var config array<name> BlockPerks;

// Doom3
var config bool Doom3DisableSuperMonsters;
var config byte Doom3DisableSuperMonstersFromWave;

// TSC
var config byte NWaves, OTWaves, SDWaves;

// FTG
var config float FtgSpawnRateMod, FtgSpawnDelayOnPickup;

defaultproperties
{
    Waves(0)="Wave1"
    Zeds(0)="NormalZeds"
    HLMult=1.0
    BountyScale=1.0
    bLogStats=true
    bRandomTrader=true
    ZedTimeTrigger=ZT_Default
    ZedTimeChanceMult=1.0
    ZedTimeDuration=4
    FtgSpawnRateMod=0.8
    FtgSpawnDelayOnPickup=10.0
    MinBonusLevel=255
    MaxBonusLevel=255
}
