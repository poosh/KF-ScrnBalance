Class ScrnZedInfo extends Object
    PerObjectConfig
    Config(ScrnWaves);

struct SZedInfo {
    var string Alias;
    var string ZedClass;
    var string Package;
    var string Vote;
    var bool bVoteInvert;
    var bool bDisabled;
    var float Pct;
};

var config byte EventNum;
var config array<SZedInfo> Zeds;

defaultproperties
{
    Zeds(1)=(Alias="CL",ZedClass="KFChar.ZombieClot_STANDARD")
    Zeds(2)=(Alias="BL",ZedClass="KFChar.ZombieBloat_STANDARD")
    Zeds(3)=(Alias="GF",ZedClass="KFChar.ZombieGorefast_STANDARD")
    Zeds(4)=(Alias="CR",ZedClass="KFChar.ZombieCrawler_STANDARD")
    Zeds(5)=(Alias="ST",ZedClass="KFChar.ZombieStalker_STANDARD")
    Zeds(6)=(Alias="SI",ZedClass="KFChar.ZombieSiren_STANDARD")
    Zeds(7)=(Alias="HU",ZedClass="KFChar.ZombieHusk_STANDARD")
    Zeds(8)=(Alias="SC",ZedClass="KFChar.ZombieScrake_STANDARD")
    Zeds(9)=(Alias="FP",ZedClass="KFChar.ZombieFleshpound_STANDARD")
    Zeds(10)=(Alias="BOSS",ZedClass="KFChar.ZombieBoss_STANDARD")
}
