Class ScrnWaveInfo extends Object
	PerObjectConfig
	Config(ScrnWaves);

enum EWaveEndRule {
    RULE_KillEmAll,
    RULE_SpawnEmAll,
    RULE_Timeout,
    RULE_EarnDosh,
    RULE_KillBoss
};

var config string Title, Message, TraderMessage;
var config int TraderTime;
var config bool bOpenTrader;
var config EWaveEndRule EndRule;
var config int Counter, MaxCounter;
var config float PerPlayerMult;
var config float SpawnRateMod;

var config float SpecialSquadHealthMod;
var config int ZedsPerSpecialSquad;
var config array<string> SpecialSquads;
var config array<string> Squads;

defaultproperties
{
    TraderTime=60
    bOpenTrader=true
    EndRule=RULE_KillEmAll
    Counter=30
    SpecialSquadHealthMod=1.0
    ZedsPerSpecialSquad=50
    SpawnRateMod=1.0
    Squads(0)="4*CL"
}