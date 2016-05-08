/**
 * ScrN Total Game Balance
 * @author PooSH, contact via steam: [ScrN]PooSH
 * Copyright (c) 2012-2014 PU Developing IK, All Rights Reserved.
 */

class ScrnBalance extends Mutator
    Config(ScrnBalance);


const VERSION = 76101;

var ScrnBalance Mut; // pointer to self to use in default functions, i.e class'ScrnBalance'.default.Mut

var const string BonusCapGroup;

var localized string strBonusLevel;
var localized string strVersion;
var localized string strStatus, strStatus2;
var localized string strSrvWarning, strSrvWarning2;
var localized string strBetaOnly;

var() globalconfig bool bSpawnBalance, bWeaponFix, bGunslinger, bAltBurnMech;
var() globalconfig bool bReplacePickups, bReplacePickupsStory, bReplaceNades, bShieldWeight;
var() globalconfig bool bSpawn0;
var() globalconfig bool bShowDamages;
var() globalconfig byte ReqBalanceMode;

var() globalconfig bool bManualReload, bForceManualReload, bHardcore, bBeta;

var() globalconfig int ForcedMaxPlayers;

var() globalconfig int
    BonusLevelNormalMax
    , BonusLevelHardMin, BonusLevelHardMax
    , BonusLevelSuiMin, BonusLevelSuiMax
    , BonusLevelHoeMin, BonusLevelHoeMax;
var() globalconfig float Post6RequirementScaling;


var transient int MinLevel, MaxLevel;
// Changing default value of variable disables its replication, cuz engine thinks it wasn't changed
var transient int SrvMinLevel, SrvMaxLevel;
var transient bool bInitialized;

var KFGameType KF;
var ScrnGameType ScrnGT;
var bool bStoryMode; // Objective Game mode (KFStoryGameInfo)
var bool bTSCGame; // Team Survival Competition (TSCGame)


struct SPickupReplacement {
    var class<Pickup> oldClass;
    var class<Pickup> newClass;
};
var array<SPickupReplacement> pickupReplaceArray;
var const int FragReplacementIndex;

var class<ScrnFunctions> Functions;

var protected  byte GameStartCountDown;

//v3
/**
 * PerkedWeapons is a list of weapons, which gets bonuses of specified perk
 * PerkedAmmo: list of WEAPONS, which gets bonuses for primary ammo (count, mag. size etc.)
 * PerkedSecondaryAmmo: list of WEAPONS, which gets bonuses for secondary ammo (count)
 *
 * All 3 lists have the same format:
 * PerkedWeapons|PerkedAmmo|PerkedSecondaryAmmo=<perk index>:<Weapon class name>:<Bonuses>
 *   , where
 *     Perk index is an index in Perks array, 0-7.
 *     weapon class name: class name of custom weapon without package name, e.g. G36CAssaultRifle
 *     Bonuses: string of bonus letters:
 *      A - primary ammo bonuses (count, magazine size, discounts)
 *      B - secondary ammo bonuses
 *      P - primary fire bonuses (damage, headshot multiplier, fire rate)
 *      S - secondary fire bonuses
 *      $ - discount
 *      D - change primary fire's damage type to perk's default one
 *      d - change secondary fire's damage type to perk's default one
 *      * - add to special weapons list
 *     If bonuses aren't specified, all of them will be applied, except Dd*
 */
var() globalconfig array<string> PerkedWeapons, CustomPerks;
//var StringReplicationInfo ClientPerkedWeaponsSRI, ClientPerksSRI;
var array< class<ScrnVeterancyTypes> > Perks;

/*
 // removed because array replication doesn't wort in unreal engine 2
 struct CustomPerkedClass {
    var int PerkIndex;
    var class BonusClass;
};
var array<CustomPerkedClass> CustomPerkedClassArray;
*/

var ScrnBurnMech BurnMech; // Alternate Burning Mechanism

var transient byte CurrentSpawnSetupNo;
var transient float NextItemSpawnTime, LastItemSetupTime; //how often reset random pickups on the map

var ScrnGameRules GameRules;

var localized string strAchEarn;
var() globalconfig bool bBroadcastAchievementEarn; //tell other players that somebody earned an achievement (excluding map achs)
var() globalconfig int AchievementFlags;
var bool bUseAchievements;
const ACH_ALLFLAGS   = 0xFFFFFFFF;
const ACH_ENABLE     = 0x0001;
const ACH_HARD       = 0x0002;
const ACH_SUI        = 0x0004;
const ACH_HOE        = 0x0008;
const ACH_SCRNZEDS   = 0x0010;
const ACH_WPCZEDS    = 0x0020;
const ACH_HARDPAT    = 0x0040;
const ACH_DOOM3      = 0x0080;


var() globalconfig bool bSaveStatsOnAchievementEarned; //save stats to serverpeprks database every time an achievement is earned
var transient bool bNeedToSaveStats;
var transient float NextStatSaveTime;

var protected bool bTradingDoorsOpen; // used to check wave start / end
var protected transient byte CurWave; // used to check wave start / end


var() globalconfig float WeldingRequirementScaling, StalkerRequirementScaling;

var ScrnCustomWeaponLink CustomWeaponLink;

var transient float FirstTickTime;
var transient bool bTickExecuted;
var transient bool bInitReplicationReceived;

var Mutator ServerPerksMut;
var transient bool bAllowAlwaysPerkChanges; // value replicated from ServerPerksMut

var() globalconfig bool bAllowVoting;
var ScrnBalanceVoting MyVotingOptions;
var globalconfig bool bPauseTraderOnly; //game can be vote-paused in trader time only
var globalconfig float SkippedTradeTimeMult; //how much of the skipped trader time (mvote ENDTRADE) to add to the next one (0 - don't add, 1 - full, 0.5 - half of the skipped time)
var transient int TradeTimeAddSeconds; //amount of seconds to add to the next trader time
var globalconfig bool bAllowBlameVote, bAllowKickVote;
var globalconfig int BlameVoteCoolDown;
var globalconfig bool bAllowPauseVote, bAllowLockPerkVote, bAllowBoringVote;
var globalconfig byte MaxVoteKillMonsters;
var globalconfig int  MaxVoteKillHP;
var globalconfig bool bVoteKillCheckVisibility;
var globalconfig float VoteKillPenaltyMult;

var globalconfig bool bDynamicLevelCap;
var int OriginalMaxLevel;

var globalconfig string ServerPerksPkgName; // if user didn't added SP mut before ScrnBalance - do it for him!

var globalconfig bool bReplaceHUD, bReplaceScoreBoard;

var globalconfig float Post6ZedSpawnInc, Post6AmmoSpawnInc;
var globalconfig float Post6ZedsPerPlayer;
var globalconfig bool bAlterWaveSize;
var globalconfig int MaxWaveSize;

var globalconfig int MaxZombiesOnce;
struct SMapInfo {
    var String MapName;
    var int MaxZombiesOnce;
    var float Difficulty; // map difficulty, where 0 is normal difficulty, -1.0 - easiest, 2.0 - twice harder that normal
    var byte ForceEventNum; // use event zeds for this map. 0 - don't force
};
var globalconfig array<SMapInfo> MapInfo;

var globalconfig byte FakedPlayers; // Min numbers of players to be used in calculation of zed count in wave

var globalconfig float EndGameStatBonus;
var globalconfig bool  bStatBonusUsesHL;
var globalconfig int  StatBonusMinHL;

var globalconfig int SharpProgMinDmg; // if headshot damage dealth with Sharpshooter's weapon exceeds this, then SS gets +1 to perk progression

var globalconfig bool bAllowWeaponLock; // allows players to lock their dropped weapon. If weapons locked, they can not be picked up by other players
var globalconfig bool bBroadcastPickups; // broadcast weapon pickups
var globalconfig String BroadcastPickupText; // broadcast weapon pickups

var protected globalconfig byte EventNum;
var transient byte CurrentEventNum;
var globalconfig bool bForceEvent;

var globalconfig bool bAutoKickOffPerkPlayers;
var localized String strAutoKickOffPerk;

struct SSquadConfig {
    var String SquadName;
    var string MonsterClass;
    var byte NumMonsters;
};
var globalconfig array<SSquadConfig> VoteSquad;

var globalconfig bool bResetSquadsAtStart; // calls ScrnGameRules.ResetSquads() at map start

struct SSquad {
    var String SquadName;
    var array < class<KFMonster> > Monsters;
};
var array<SSquad> Squads;
// KF.WaveMonsters value after all zeds added by SpawnSquad() are spawned
// if ( SquadSpawnedMonsters > 0 && KF.WaveMonsters < SquadSpawnedMonsters )
// then those zeds are still waiting in spawn queue
var int SquadSpawnedMonsters; 

struct SCustomEvent {
    var byte EventNum;
    var String MonstersCollection;
    var array<String> ServerPackages;
};
var globalconfig array<SCustomEvent> CustomEvents;

var float OriginalWaveSpawnPeriod;

var globalconfig bool bNoRequiredEquipment;
var globalconfig bool bUseExpLevelForSpawnInventory;
var globalconfig array<string> SpawnInventory;

var globalconfig int StartCashNormal, StartCashHard, StartCashSui, StartCashHoE;
var globalconfig int MinRespawnCashNormal, MinRespawnCashHard, MinRespawnCashSui, MinRespawnCashHoE;
var globalconfig int TraderTimeNormal, TraderTimeHard, TraderTimeSui, TraderTimeHoE;
var globalconfig bool bNoStartCashToss, bMedicRewardFromTeam;
var globalconfig bool bLeaveCashOnDisconnect;

var globalconfig bool b10Stars;

struct SColorTag {
    var string T;
    var byte R, G, B;
};
var array<SColorTag> ColorTags;

var globalconfig bool bCloserZedSpawns;
var globalconfig bool bServerInfoVeterancy;

var globalconfig bool bScrnClientPerkRepLink;

var transient array<KFUseTrigger> DoorKeys;

var StaticMesh          AmmoBoxMesh;
var float               AmmoBoxDrawScale;
var vector              AmmoBoxDrawScale3D;


replication
{
    reliable if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        SrvMinLevel, SrvMaxLevel;

    reliable if ( bNetInitial && Role == ROLE_Authority )
        bSpawnBalance, bSpawn0, bWeaponFix, bAltBurnMech, bGunslinger,
        bReplaceNades, bShieldWeight, bBeta,
        bShowDamages, bManualReload, bForceManualReload, bHardcore,
        Post6RequirementScaling, WeldingRequirementScaling, StalkerRequirementScaling, ReqBalanceMode,
        AchievementFlags, 
        CustomWeaponLink,
        bAllowWeaponLock,
		bNoStartCashToss, bMedicRewardFromTeam,
        b10Stars;
}

// ======================================= FUNCTIONS =======================================
simulated function PostNetReceive()
{
    super.PostNetReceive();
    if ( bInitReplicationReceived && Role < ROLE_Authority ) {
        TimeLog("Additional Settings received from a server.");
        ClientInitSettings();
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if ( Role < ROLE_Authority ) {
        TimeLog("Initial Settings received from a server.");
        ClientInitSettings();
        bInitReplicationReceived = true;
    }
}


// client-side only
simulated function ClientInitSettings()
{
    local ScrnPlayerController LocalPlayer;

    // setting default settings on server screws up repliction
    if ( Role == ROLE_Authority )
        return;

    Mut = self;
    bStoryMode = KF_StoryGRI(Level.GRI) != none;
    bTSCGame = TSCGameReplicationInfoBase(Level.GRI) != none;
    MinLevel = SrvMinLevel;
    MaxLevel = SrvMaxLevel;

    // support of extended classes 
    // if class MyBalance extends ScrnBalance, then default settings must be
    // set for both class'MyBalance' and class'ScrnBalance'
    ClientInitStaticSettings(self.class);
    if ( self.class != class'ScrnBalance' )
        ClientInitStaticSettings(class'ScrnBalance');
        
    LocalPlayer = ScrnPlayerController(Level.GetLocalPlayerController());
    if ( LocalPlayer != none ) {
        LocalPlayer.Mut = self;
        LocalPlayer.LoadMutSettings();
    }  

    InitSettings();
}


simulated function ClientInitStaticSettings(class<ScrnBalance> MyBalanceClass)
{
    if ( Role == ROLE_Authority )
        return;
        
    MyBalanceClass.default.Mut = self;  

    MyBalanceClass.default.MinLevel = SrvMinLevel;
    MyBalanceClass.default.MaxLevel = SrvMaxLevel;

    MyBalanceClass.default.bSpawnBalance = bSpawnBalance;
    MyBalanceClass.default.bWeaponFix = bWeaponFix;
    MyBalanceClass.default.bGunslinger = bGunslinger;
    MyBalanceClass.default.bShowDamages = bShowDamages;
    MyBalanceClass.default.bShieldWeight = bShieldWeight;
    MyBalanceClass.default.bReplaceNades = bReplaceNades;
    MyBalanceClass.default.WeldingRequirementScaling = WeldingRequirementScaling;
    MyBalanceClass.default.StalkerRequirementScaling = StalkerRequirementScaling;
    MyBalanceClass.default.Post6RequirementScaling = Post6RequirementScaling;
    MyBalanceClass.default.ReqBalanceMode = ReqBalanceMode;

    MyBalanceClass.default.AchievementFlags = AchievementFlags;

    MyBalanceClass.default.bManualReload = bManualReload;
    MyBalanceClass.default.bForceManualReload = bForceManualReload;
    MyBalanceClass.default.bHardcore = bHardcore;
    MyBalanceClass.default.bBeta = bBeta;
    MyBalanceClass.default.bAllowWeaponLock = bAllowWeaponLock;
    MyBalanceClass.default.bNoStartCashToss = bNoStartCashToss;
    MyBalanceClass.default.bMedicRewardFromTeam = bMedicRewardFromTeam;
    MyBalanceClass.default.b10Stars = b10Stars;
}

// client & server side
simulated function InitSettings()
{
    ApplySpawnBalance();
    ApplyWeaponFix();

    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[0]=1000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[1]=2000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[2]=7000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[3]=35000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[4]=120000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[5]=250000.0 * WeldingRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetSupportSpec'.default.progressArray0[6]=370000.0 * WeldingRequirementScaling;

    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[0]=10.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[1]=30.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[2]=100.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[3]=350.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[4]=1200.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[5]=2400.0 * StalkerRequirementScaling;
    class'ScrnBalanceSrv.ScrnVetCommando'.default.progressArray0[6]=3600.0 * StalkerRequirementScaling;

    if ( ReqBalanceMode == 1) {
        class'ScrnBalanceSrv.ScrnVetSharpshooter'.default.progressArray0[3] = 800;

        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[1] = 450;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[2] = 1750;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[3] = 9000;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[4] = 25000;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[5] = 50000;
    }
    else {
        class'ScrnBalanceSrv.ScrnVetSharpshooter'.default.progressArray0[3] = 700;

        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[1] = 200;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[2] = 750;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[3] = 4000;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[4] = 12000;
        class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.progressArray0[5] = 25000;
    }

    if (bShieldWeight) {
        bReplaceNades = true;
        default.bReplaceNades = true;
        class'ScrnBalance'.default.bReplaceNades = true;
        class'ScrnFrag'.default.Weight = 0;
        class'ScrnBalanceSrv.ScrnHumanPawn'.default.StandardVestClass.default.Weight = 1;
    }
    else {
        class'ScrnFrag'.default.Weight = 1;
        class'ScrnBalanceSrv.ScrnHumanPawn'.default.StandardVestClass.default.Weight = 0;
    }
    class'ScrnFragPickup'.default.Weight = class'ScrnFrag'.default.Weight;
    RecalcAllPawnWeight();
    
    class'KFMod.Knife'.default.Priority = 2; // set lowest priority
	class'KFMod.CrossbowArrow'.default.DamageRadius = 0; // isn't used anywhere. Set to 0 to fix description

    // Achievements
    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);
    default.bUseAchievements = bUseAchievements;
    
    default.bStoryMode = bStoryMode;
    default.bTSCGame = bTSCGame;

    // fixes critical bug:
    // Assertion failed: inst->KPhysRootIndex != INDEX_NONE && inst->KPhysLastIndex != INDEX_NONE [File:.\KSkeletal.cpp] [Line: 595]
    class'FellLava'.default.bSkeletize = false;
    
    EventZedNames();

    bInitialized = true;
}

simulated function EventZedNames()
{
  class'KFChar.ZombieClot_HALLOWEEN'.default.MenuName = "Honey Biscuit";
  class'KFChar.ZombieBloat_HALLOWEEN'.default.MenuName = "Mama Bessie";
  class'KFChar.ZombieStalker_HALLOWEEN'.default.MenuName = "Maggie May";
  class'KFChar.ZombieCrawler_HALLOWEEN'.default.MenuName = "Half of Uncle Pervis";
  class'KFChar.ZombieGorefast_HALLOWEEN'.default.MenuName = "Banjo Chewey";
  class'KFChar.ZombieHusk_HALLOWEEN'.default.MenuName = "Brother Sparky";
  class'KFChar.ZombieSiren_HALLOWEEN'.default.MenuName = "Granny Crystal May";
  class'KFChar.ZombieScrake_HALLOWEEN'.default.MenuName = "Cousin Otis";
  class'KFChar.ZombieFleshpound_HALLOWEEN'.default.MenuName = "Bubba";
  class'KFChar.ZombieBoss_HALLOWEEN'.default.MenuName = "Sheriff Wade";
  
  class'KFChar.ZombieClot_XMAS'.default.MenuName = "Elf";
  class'KFChar.ZombieBloat_XMAS'.default.MenuName = "Fake Santa";
  class'KFChar.ZombieStalker_XMAS'.default.MenuName = "Mrs. Claws";
  class'KFChar.ZombieCrawler_XMAS'.default.MenuName = "Reindeer";
  class'KFChar.ZombieGorefast_XMAS'.default.MenuName = "Gingerfast";
  class'KFChar.ZombieHusk_XMAS'.default.MenuName = "Snow Husk";
  class'KFChar.ZombieSiren_XMAS'.default.MenuName = "Screaming Tree";
  class'KFChar.ZombieScrake_XMAS'.default.MenuName = "Jack Frost";
  class'KFChar.ZombieFleshpound_XMAS'.default.MenuName = "Nutcracker";
  class'KFChar.ZombieBoss_XMAS'.default.MenuName = "Santriarch";  
}

simulated function TimeLog(coerce string s)
{
    log("["$String(Level.TimeSeconds - FirstTickTime)$"s]" @ s, class.outer.name);
}

static function MessageBonusLevel(PlayerController KPC)
{
    local String msg;

    if ( KPC == none )
        return;

    msg = default.strBonusLevel;
    ReplaceText(msg, "%s", String(class'ScrnBalanceSrv.ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(KFPlayerReplicationInfo(KPC.PlayerReplicationInfo))));

    KPC.ClientMessage(msg);
}

static final function string GetVersionStr()
{
    local String msg, s;
    local int v, sub_v;

    msg = default.strVersion;
    v = VERSION / 100;
    sub_v = VERSION % 100;

    s = String(int(v%100));
    if ( len(s) == 1 )
        s = "0" $ s;
    if ( sub_v > 0 )
        s @= "(BETA "$sub_v$")";
    ReplaceText(msg, "%n", s);

    s = String(v/100);
    ReplaceText(msg, "%m",s);

    //left for backward comp.
    ReplaceText(msg, "%s", "6");
    ReplaceText(msg, "%p", "01");

    return msg;
}
static function MessageVersion(PlayerController PC)
{
    if ( PC != none )
        PC.ClientMessage(default.FriendlyName @ GetVersionStr());
}

function MessageStatus(PlayerController PC)
{
    local String msg;
    local KFPlayerReplicationInfo KFPRI;
    local ClientPerkRepLink R;
    local int i, j;
    local array<name> WeaponPackages;
    local name pkg;

    if ( PC == none )
        return;

    KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);

    if ( ScrnGT != none && ScrnGT.IsTourney() )
        PC.ClientMessage("*** TOURNEY MODE ***", 'Log');
    
    msg = strStatus;
    ReplaceText(msg, "%v", String(KFPRI.ClientVeteranSkillLevel));
    ReplaceText(msg, "%b", String(class'ScrnBalanceSrv.ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(KFPRI)));
    ReplaceText(msg, "%n", String(MinLevel));
    ReplaceText(msg, "%x", String(MaxLevel));
    PC.ClientMessage(msg, 'Log');

    msg = strStatus2;
    ReplaceText(msg, "%s", String(bSpawnBalance));
    ReplaceText(msg, "%w", String(bWeaponFix));
    ReplaceText(msg, "%g", String(bGunslinger));
    ReplaceText(msg, "%a", String(bAltBurnMech));
    ReplaceText(msg, "%m", String(KF.MaxZombiesOnce));
    PC.ClientMessage(msg, 'Log');
    
    R = SRStatsBase(PC.SteamStatsAndAchievements).Rep;
    if ( R != none ) {
        msg = "Weapon Packages:";
        for ( i=0; i<R.ShopInventory.length; ++i ) {
            pkg = R.ShopInventory[i].PC.outer.name;
            for ( j=0; j<WeaponPackages.length; ++j ) {
                if ( WeaponPackages[j] == pkg ) {
                    pkg = '';
                    break;
                }
            }
            if ( pkg != '' ) {
                WeaponPackages[WeaponPackages.length] = pkg;
                msg @= string(pkg);
            }
        }
        PC.ClientMessage(msg, 'Log');
    }
}

//message to clients their effective bonus levels, it they don't match perk level
function BroadcastBonusLevels()
{
    local Controller P;
    local KFPlayerController Player;
    local KFPlayerReplicationInfo KFPRI;

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        if ( !P.bIsPlayer )
            continue;
        Player = KFPlayerController(P);
        if ( Player != none ) {
            KFPRI = KFPlayerReplicationInfo(Player.PlayerReplicationInfo);
            if (KFPRI.ClientVeteranSkillLevel != class'ScrnBalanceSrv.ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(KFPRI))
                MessageBonusLevel(Player);
        }
    }
}


function BroadcastMessage(string Msg, optional bool bSaveToLog)
{
    local Controller P;
    local PlayerController Player;
    local name MsgType;
    
    if ( bSaveToLog) {
        log(Msg, class.outer.name);
        MsgType = 'Log';
    }

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = PlayerController(P);
        if ( Player != none ) {
            Player.ClientMessage(Msg, MsgType);
        }
    }
}


// copy-pasted from ScrnPlayerController for easy access
static final function string ColorString(string s, byte R, byte G, byte B)
{
    return chr(27)$chr(max(R,1))$chr(max(G,1))$chr(max(B,1))$s;
}

static final function string StripColor(string s)
{
    local int p;

    p = InStr(s,chr(27));
    while ( p>=0 )
    {
        s = left(s,p)$mid(S,p+4);
        p = InStr(s,Chr(27));
    }

    return s;
}

// returns first i amount of characters excluding escape color codes
static final function string LeftCol(string ColoredString, int i)
{
    local string s;
    local int p, c;

    if ( Len(ColoredString) <= i )
        return ColoredString;

    c = i;
    s = ColoredString;
    p = InStr(s,chr(27));
    while ( p >=0 && p < i ) {
        c+=4; // add 4 more characters due to color code
        s = left(s, p) $ mid(s, p+4);
        p = InStr(s,Chr(27));        
    }
    
    return Left(ColoredString, c);
}

simulated function string ParseColorTags(string ColoredText)
{
    local int i;
    local string s;
    
    s = ColoredText;
    for ( i=0; i<ColorTags.Length; ++i ) {
        if ( InStr(s, ColorTags[i].T) != -1 )
            ReplaceText(s, ColorTags[i].T, ColorString("", 
                ColorTags[i].R, ColorTags[i].G, ColorTags[i].B));
    }
    
    return s;
}

simulated function string StripColorTags(string ColoredText)
{
    local int i;
    local string s;
    
    s = ColoredText;
    
    for ( i=0; i<ColorTags.Length; ++i ) {
        if ( InStr(s, ColorTags[i].T) != -1 )
            ReplaceText(s, ColorTags[i].T, "");
    }
    
    return s;
}

simulated function string ColoredPlayerName(PlayerReplicationInfo PRI)
{
    if ( PRI == none )
        return "";
        
    return ParseColorTags(PRI.PlayerName);
}

function StolenWeapon(Pawn NewOwner, KFWeaponPickup WP)
{
    local string str;
    
    str = BroadcastPickupText;
    ReplaceText(str, "%p", ColorString(ParseColorTags(NewOwner.GetHumanReadableName()), 192, 1, 1) $ ColorString("", 192, 192, 192));
    ReplaceText(str, "%o", ColorString(ColoredPlayerName(WP.DroppedBy.PlayerReplicationInfo), 1, 192, 1) $ ColorString("", 192, 192, 192));
    ReplaceText(str, "%w", ColorString(WP.ItemName, 1, 96, 192) $ ColorString("", 192, 192, 192));
    ReplaceText(str, "%$", ColorString(String(WP.SellValue), 192, 192, 1) $ ColorString("", 192, 192, 192));
    BroadcastMessage(str);
}

//recalculate
function RecalcAllPawnWeight()
{
    local ScrnHumanPawn P;

    foreach DynamicActors(class'ScrnBalanceSrv.ScrnHumanPawn', P)
        P.RecalcWeight();
}

function WelcomeMessage(PlayerController PC)
{
    if ( PC != none ) {
        MessageVersion(PC);
        MessageStatus(PC);
        if ( (Level.NetMode == NM_Standalone || Level.NetMode == NM_ListenServer) && class.outer.name == 'ScrnBalanceSrv' ) {
            PC.ClientMessage(strSrvWarning);
            PC.ClientMessage(strSrvWarning2);
        }
    }
}


// Setup the random ammo pickups
function SetupPickups()
{
    local float W, A; //chance of spawning weapon / ammo box
    local bool bW, bA;
    local int i;
    local byte SetupNo;

    if ( !KF.IsInState('MatchInProgress') )
        return;

    if ( KF.bTradingDoorsOpen )
        SetupNo = 40; // 4 times less spawns in trader time - buy, not search!
    else if ( KF.NumMonsters <= 10 )
        SetupNo = 30; // 3 times less spawns, when only a few zeds left
    else if ( KF.TotalMaxMonsters <= 0 )
        SetupNo = 20; // half of spawns, when all zeds in wave have already spawned
    else
        SetupNo = 10;

    if ( SetupNo == CurrentSpawnSetupNo && Level.TimeSeconds < NextItemSpawnTime )
        return; //spawn is already set up, don't change it

    CurrentSpawnSetupNo = SetupNo;
    LastItemSetupTime = Level.TimeSeconds;
    NextItemSpawnTime = Level.TimeSeconds + 300.0; //reset pickup spawns every 5 minutes
    if ( KF.NumPlayers > 6 )
        NextItemSpawnTime -= fmin(180, (KF.NumPlayers - 6 ) * 10); // more players = faster spawn reset

    // Randomize Available Ammo Pickups
    if ( KF.GameDifficulty >= 5.0 ) // Suicidal and Hell on Earth
    {
        W = 0.1;
        A = 0.25;
    }
    else if ( KF.GameDifficulty >= 4.0 ) // Hard
    {
        W = 0.25;
        A = 0.40;
    }
    else if ( KF.GameDifficulty >= 2.0 ) // Normal
    {
        W = 0.35;
        A = 0.5;
    }
    else // Beginner
    {
        W = 1.0; //spawn all weapons
        A = 1.0; //spawn all ammo boxes
    }
    
    if ( KF.NumPlayers > 6 ) {
        A *= 1.0 + float(KF.NumPlayers - 6)*Post6AmmoSpawnInc; 
    }

    if ( SetupNo > 10 && KF.GameDifficulty >= 2.0 ) { //on beginner always spawn all items
        W /= float(SetupNo) * 0.075; //don't lower weapons so much
        A /= float(SetupNo) * 0.10;
    }

    for ( i = 0; i < KF.WeaponPickups.Length ; i++ )
    {
        if ( frand() < W ) {
            KF.WeaponPickups[i].EnableMe();
            bW = true;
        }
        else
            KF.WeaponPickups[i].DisableMe();
    }

    for ( i = 0; i < KF.AmmoPickups.Length ; i++ )
    {
        if ( frand() < A ) {
            if ( kf.AmmoPickups[i].bSleeping )
                KF.AmmoPickups[i].GotoState('Pickup');
            bA = true;
        }
        else
            KF.AmmoPickups[i].GotoState('Sleeping', 'Begin');
    }

    // enable at least 1 spawn of each type
    if ( !bW && KF.WeaponPickups.Length > 0 )
        KF.WeaponPickups[rand(KF.WeaponPickups.Length)].EnableMe();
    if ( !bA && KF.AmmoPickups.Length > 0 )
        KF.AmmoPickups[rand(KF.AmmoPickups.Length)].GotoState('Pickup');
}

function ForceMaxPlayers()
{
    if ( ForcedMaxPlayers > 0 && ForcedMaxPlayers != Level.Game.MaxPlayers ) {
        Log("Forcing server max players from " $ Level.Game.MaxPlayers $ " to " $ ForcedMaxPlayers,Class.Outer.Name);
        Level.Game.MaxPlayers = ForcedMaxPlayers;
        Level.Game.Default.MaxPlayers = ForcedMaxPlayers;
    }
}


function AchievementEarned(ScrnAchievements AchHandler, int AchIndex)
{
    if ( bSaveStatsOnAchievementEarned && AchHandler.AchDefs[AchIndex].bUnlockedJustNow )
        bNeedToSaveStats = true;
    NextStatSaveTime = Level.TimeSeconds + 5; // wait a bit - maybe other achievements will be earned soon
    if ( bBroadcastAchievementEarn )
        BroadcastAchEarn(AchHandler, AchIndex);
}

function BroadcastAchEarn(ScrnAchievements AchHandler, int AchIndex)
{
    local Controller C;
    local ScrnPlayerController ScrnPlayer;
    local string s;

    if ( PlayerController(AchHandler.Owner) == none || PlayerController(AchHandler.Owner).PlayerReplicationInfo == none )
        return;

    s = strAchEarn;
    ReplaceText(s, "%p", PlayerController(AchHandler.Owner).PlayerReplicationInfo.PlayerName);
    ReplaceText(s, "%a", AchHandler.AchDefs[AchIndex].DisplayName);

    for (C = Level.ControllerList; C != None; C = C.NextController) {
        if ( !C.bIsPlayer )
            continue;    
        ScrnPlayer = ScrnPlayerController(C);
        if ( ScrnPlayer != None && ScrnPlayer != AchHandler.Owner ) {
            ScrnPlayer.ClientMessage(ScrnPlayer.ConsoleColorString(s, 1, 150, 255));
        }
    }
}

function BroadcastFakedAchievement(int AchIndex)
{
    local Controller C;

    for (C = Level.ControllerList; C != None; C = C.NextController) {
        if ( !C.bIsPlayer )
            continue;    
        if ( PlayerController(C) != none)
            PlayerController(C).ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFakedAchMsg', AchIndex);
    }
}

function Mutator FindServerPerksMut()
{
    local Mutator M;
    
    if ( ServerPerksMut != none )
        return ServerPerksMut;

    for ( M = KF.BaseMutator; M != None; M = M.NextMutator ) {

        if ( M.IsA('ServerPerksMut') ) {
            ServerPerksMut = M;
            break;
        }
    }
    if ( ServerPerksMut == none ) {
        log("ServerPerksMut not found!", class.outer.name);
    }
    
    return ServerPerksMut;
}

// do everything possible to find ScrnBalance mutator
static final function ScrnBalance Myself(LevelInfo Level)
{
    local Mutator M;
    local ScrnBalance SBM;

    if ( default.Mut != none )
        return default.Mut;
    
    // shouldn't reach here
        
    // server-side
    if ( Level.Game != none ) {
        for ( M = Level.Game.BaseMutator; M != None; M = M.NextMutator ) {
            SBM = ScrnBalance(M);
            if ( SBM != none ) {
                default.Mut = SBM;
                return SBM;
            }
        }
    }
    
    // clien-side
    foreach Level.DynamicActors(class'ScrnBalance', SBM) {
        default.Mut = SBM;
        return SBM;
    }
    
    log("Unable to find myself :(", 'ScrnBalance');
    return none;
}

final function GetRidOfMut(name MutatorName)
{
    local Mutator M;

    for ( M = KF.BaseMutator; M != None; M = M.NextMutator ) {

        if ( M.IsA(MutatorName) ) {
            M.Destroy();
            return;
        }
    }
}

//can't statically link to ServerPerksMut, cuz it is server-side only
function SaveStats()
{
    bNeedToSaveStats = false;

    if ( ServerPerksMut == none )
        FindServerPerksMut();
    if ( ServerPerksMut == none )
        return;

    if ( Level.Game.bGameEnded ) {
        GotoState('StatsSaving');
        // goto EndGameTracker state again to force save perks
        // doing so will increment win/loose counter extra time - need to contact Marco about this
    }
    else {
        // adjust variables of ServerPerksMut to force saving
        ServerPerksMut.SetPropertyText("WaveCounter", "100");
        ServerPerksMut.SetPropertyText("LastSavedWave", "-1");
    }
}

state StatsSaving
{
Begin:
    log("Saving stats...", class.outer.name);
    ServerPerksMut.GotoState('');
    sleep(1.0);
    if ( ServerPerksMut.IsInState('EndGameTracker') ) {
        log("Can't save stats!", class.outer.name);
    }
    else {
        ServerPerksMut.GotoState('EndGameTracker');
    }
    GotoState('');
}

function DynamicLevelCap()
{
    local int num, m;

    if ( !bDynamicLevelCap )
        return;

    m = OriginalMaxLevel;
    if ( bTSCGame )
        num = max(KF.Teams[0].Size, KF.Teams[1].Size);
    else 
        num = KF.NumPlayers;
    
    if (num > 6)
        m += num-6; //extra level per player

    if ( MaxLevel != m) {
        MaxLevel = m;
        default.MaxLevel = m;
        SrvMaxLevel = m; //send value to clients
    }
}

// kick players, who have no perk
function KickOffPerkPlayers()
{
    local Controller C;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

        
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( !C.bIsPlayer )
            continue;
            
        KFPC = KFPlayerController(C);
        KFPRI = KFPlayerReplicationInfo(C.PlayerReplicationInfo);
        if ( KFPC != none && KFPC.Pawn != none && NetConnection(KFPC.Player)!=None  
                && KFPRI != none && KFPRI.ClientVeteranSkill == none  
                && !KFPRI.bOnlySpectator && !KFPRI.bIsSpectator )
        {
            KFPC.ClientNetworkMessage("AC_Kicked", strAutoKickOffPerk);
            if ( KFPC.Pawn != none && Vehicle(KFPC.Pawn) == none )
                KFPC.Pawn.Destroy();
            KFPC.Destroy();                
        }
    }
}

// executes each second while match is in progress
function GameTimer()
{
    if ( !bStoryMode && (Level.TimeSeconds < NextItemSpawnTime || (KF.TotalMaxMonsters <= 0 && Level.TimeSeconds > LastItemSetupTime + 15)) )
        SetupPickups();

    // check for wave start/end
    if ( bTradingDoorsOpen != KF.bTradingDoorsOpen ) {
        bTradingDoorsOpen = KF.bTradingDoorsOpen;
		
		if ( bStoryMode ) {
			// by default, story game doesn't set bWaveInProgress, and this screws up perk selection in ServerPerks
			KF.bWaveInProgress = !KFStoryGameInfo(KF).IsTraderTime(); 
			KFGameReplicationInfo(Level.GRI).bWaveInProgress = KF.bWaveInProgress;
		}	
			
        if ( bTradingDoorsOpen ) {
			// Trader Time
			if ( bStoryMode && KF.WaveNum == CurWave ) {
				// seems like story game doesn't increment wave counter
				KF.WaveNum++;
			}
			
            GameRules.WaveEnded();

            KF.WaveCountDown += TradeTimeAddSeconds;
            TradeTimeAddSeconds = 0;
        }
        else {
			// Wave in Progress
			CurWave = KF.WaveNum;
			
            if ( bAutoKickOffPerkPlayers )
                KickOffPerkPlayers();
            SquadSpawnedMonsters = 0;
            
            GameRules.WaveStarted();

            if ( MyVotingOptions != none && MyVotingOptions.VotingHandler.IsMyVotingRunning(MyVotingOptions, MyVotingOptions.VOTE_ENDTRADE) )
                MyVotingOptions.VotingHandler.VoteFailed();
                
            if ( bWeaponFix ) {
                DestroyExtraPipebombs();
            }
        }
        
        if ( bDynamicLevelCap )
            DynamicLevelCap();
    }
	
	// in story mode check bWaveInProgress every seconds, if if trader door are closed but wave is not in progress 
	if ( bStoryMode ) {
        if ( !bTradingDoorsOpen && !KF.bWaveInProgress ) {
            // by default, story game doesn't set bWaveInProgress, and this screws up perk selection in ServerPerks
            KF.bWaveInProgress = !KFStoryGameInfo(KF).IsTraderTime(); 
            KFGameReplicationInfo(Level.GRI).bWaveInProgress = KF.bWaveInProgress;
        }
	}	
    else {
        CheckDoors();
    }
}

function Timer()
{
    // todo - talk to Marco about forcing game saving
    if ( bNeedToSaveStats && Level.TimeSeconds > NextStatSaveTime ) {
        SaveStats();
    }

    if ( KF.IsInState('MatchInProgress') ) {
        if ( GameStartCountDown > 0)
            GameStartCountDown--; // wait for 10 seconds for game to be started and set up first wave
        else
            GameTimer();
    }
}

simulated function Tick( float DeltaTime )
{
    if ( !bTickExecuted ) {
        bTickExecuted = true;
        FirstTickTime = Level.TimeSeconds;
    }

    if ( Role == ROLE_Authority ) {
		OriginalWaveSpawnPeriod = KF.KFLRules.WaveSpawnPeriod;
        ForceMaxPlayers();
		if ( !bStoryMode ) {
            InitDoors();
			SetStartCash();
        }
        SetTimer(1, true);
        Disable('Tick');
    }
    else if ( bInitialized ) {
        Disable('Tick');
    }
    else if ( Level.TimeSeconds - FirstTickTime > 5 ) {
        // this shouldn't happen
        Timelog("Settings receiving timeout failed - initializing with default settings");
        InitSettings();
        Disable('Tick');
    }
}

function SetStartCash()
{
	local Controller C;
    if ( KF.GameDifficulty >= 7 ) // HoE
    {
		KF.TimeBetweenWaves = TraderTimeHoE;
		KF.StartingCash = StartCashHoE;
		KF.MinRespawnCash = MinRespawnCashHoE;
    }
    else if (KF.GameDifficulty >= 5 ) // Suicidal
    {
		KF.TimeBetweenWaves = TraderTimeSui;
		KF.StartingCash = StartCashSui;
		KF.MinRespawnCash = MinRespawnCashSui;
    }
    else if ( KF.GameDifficulty >= 4 ) // Hard
    {
		KF.TimeBetweenWaves = TraderTimeHard;
		KF.StartingCash = StartCashHard;
		KF.MinRespawnCash = MinRespawnCashHard;
    }
    else
    {
		KF.TimeBetweenWaves = TraderTimeNormal;
		KF.StartingCash = StartCashNormal;
		KF.MinRespawnCash = MinRespawnCashNormal;
    }
	
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
		if ( C.PlayerReplicationInfo != none )
			C.PlayerReplicationInfo.Score = KF.StartingCash;	
	}
}

function DebugArmor(PlayerController Sender)
{
    local Controller P;
    local ScrnHumanPawn ScrnPawn;

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        ScrnPawn = ScrnHumanPawn(P.Pawn);
        if ( ScrnPawn != none ) {
            Sender.ClientMessage(ScrnPawn.PlayerReplicationInfo.PlayerName @ GetItemName(String(ScrnPawn.GetCurrentVestClass())) @ int(ScrnPawn.ShieldStrength)$"/"$int(ScrnPawn.ShieldStrengthMax));
        }
    }
}

function MessagePerkStats(PlayerController Sender)
{
    local ScrnPlayerInfo SPI;
    
    SPI = GameRules.GetPlayerInfo(Sender);
    
    if ( SPI == none )
        Sender.ClientMessage("No player info record found");
    else {
        Sender.ClientMessage(ColorString("Initial Perk Stats: " $ SPI.PerkStatStr(SPI.GameStartStats), 255, 1, 200));    
        Sender.ClientMessage(ColorString("Perk Progression:   " $ SPI.PerkProgressStr(SPI.GameStartStats), 255, 1, 200));    
    }
}    

// returns number of zeds, which have Other as enemy
function MsgEnemies(PlayerController Sender)    
{
    local Controller C;
    local PlayerController PC;
    local array<PlayerController> Players;
    local array<int> Enemies;
    local int i;
        
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( !C.bIsPlayer && C.Enemy != none ) { 
            PC = PlayerController(C.Enemy.Controller);
            if ( PC != none ) {
                for ( i=0; i<Players.length; ++i ) {
                    if ( Players[i] == PC )
                        break;
                }
                if ( i == Players.length ) {
                    Players[i] = PC;
                    Enemies[i] = 1;
                }
                else
                    Enemies[i] = Enemies[i] + 1;
            }
        }
    }
    for ( i=0; i<Players.length; ++i ) {
        Sender.ClientMessage(Enemies[i] $ " enemy(-ies) vs " $ Players[i].PlayerReplicationInfo.PlayerName );
    }
}

// splits long message on short ones
static function LongMessage(PlayerController Sender, string S, optional int MaxLen, optional string Divider)
{
    local int pos;
    local string part;
    
    if ( Sender == none )
        return;
    if ( MaxLen == 0 ) 
        MaxLen = 80;
    if ( Divider == "" )
        Divider = " ";
        
    while ( len(part) + len(S) > MaxLen ) {
        pos = InStr(S, Divider);
        if ( pos == -1 )
            break; // no more dividers
        
        if ( len(part) + pos + 1 > MaxLen) {
            Sender.ClientMessage(part);
            part = "";
        }
        part $= Left(S, pos + 1);
        S = Mid(S, pos+1);
    }

    part $= S;
    if ( part != "" )
        Sender.ClientMessage(S);
}

function Mutate(string MutateString, PlayerController Sender)
{
    super.Mutate(MutateString, Sender);

    MutateString = caps(MutateString);
    
    if ( MutateString == "ACCURACY" )
        SendAccuracy(Sender);
    else if( MutateString == "CHECK" )
        Sender.ClientMessage(FriendlyName);
    else if ( MutateString == "LEVEL" )
        MessageBonusLevel(Sender);
    else if ( MutateString == "VERSION" )
        MessageVersion(Sender);
    else if ( MutateString == "STATUS")
        MessageStatus(Sender);
    else if ( MutateString == "MUTLIST" ) 
        Sender.ClientMessage(MutatorList());
    else if ( MutateString == "STATS" || MutateString == "PERKSTATS" )
        MessagePerkStats(Sender);        
    else if ( MutateString == "HARDCORELEVEL" || MutateString == "HL" )
        Sender.ClientMessage("Hardcore Level = " $ GameRules.HardcoreLevel);
    else if ( MutateString == "PLAYERLIST" ) 
        SendPlayerList(Sender);  
    else if ( MutateString == "ZEDLIST" ) 
        SendZedList(Sender);  
    else if ( MutateString == "TESTSPEC") {
        Sender.ClientMessage("Pawn="$Sender.Pawn @ "ViewTarget="$Sender.ViewTarget @ "RealViewTarget="$Sender.RealViewTarget);
        Sender.ClientMessage("Pawn.bViewTarget="$ScrnHumanPawn(Sender.Pawn).bViewTarget
            @ "Pawn.SpecWeapon="$ScrnHumanPawn(Sender.Pawn).SpecWeapon
            @ "Pawn.SpecMagAmmo="$ScrnHumanPawn(Sender.Pawn).SpecMagAmmo
            @ "Pawn.SpecMags="$ScrnHumanPawn(Sender.Pawn).SpecMags
            @ "Pawn.SpecSecAmmo="$ScrnHumanPawn(Sender.Pawn).SpecSecAmmo);
    }
    else if ( Level.NetMode == NM_Standalone || (Sender.PlayerReplicationInfo != none && Sender.PlayerReplicationInfo.bAdmin) ) 
    {
        // admin commands
        if ( MutateString == "CMDLINE" ) {
            if ( ScrnGT != none )
                LongMessage(Sender, ScrnGT.GetCmdLine(), 80, "?");
            else 
                Sender.ClientMessage("Avaliable in ScrnGameType only!");
        }
        else if ( MutateString == "DEBUGGAME" ) {
            Sender.ClientMessage("Game=" $ KF.class.name
                @ "EventNum=" $ CurrentEventNum
                @ "MonsterCollection=" $ KF.MonsterCollection
                @ "Boss=" $ KF.MonsterCollection.default.EndGameBossClass);
        }
        else if ( MutateString == "ENEMIES" )
            MsgEnemies(Sender);
        else if ( ScrnGT == none || !ScrnGT.IsTourney() ) {
            if ( MutateString == "RESETBOSS" ) {
                switch (CurrentEventNum) {
                    case 1:
                        KF.MonsterCollection.default.EndGameBossClass = "KFChar.ZombieBoss_CIRCUS";
                        break;
                    case 2:
                        KF.MonsterCollection.default.EndGameBossClass = "KFChar.ZombieBoss_HALLOWEEN";
                        break;
                    case 2:
                        KF.MonsterCollection.default.EndGameBossClass = "KFChar.ZombieBoss_XMAS";
                        break;
                    default:
                        KF.MonsterCollection.default.EndGameBossClass = "KFChar.ZombieBoss";
                }
                Sender.ClientMessage("End game boss reset to " $ KF.MonsterCollection.default.EndGameBossClass);
            }
            else if ( Left(MutateString, 7) == "MAPZEDS" ) {
                if ( SetMapZeds(int(Mid(MutateString, 8))) )
                    Sender.ClientMessage("Max zeds at once for this map is set to " $ Mid(MutateString, 8));
                else
                    Sender.ClientMessage("Max zeds at once must be in range [32..192], e.g. 'mutate mapzeds 64'");
            }
            else if ( MutateString == "FORCEZEDS" ) {
                SetMaxZombiesOnce();
                Sender.ClientMessage("Max zeds at once forced to " $ KF.MaxZombiesOnce);
            }
            else if ( Left(MutateString, 7) == "MAPDIFF" ) 
                SetMapDifficulty(Mid(MutateString, 8), Sender);
            else if ( Left(MutateString, 13) == "MAPDIFFICULTY" ) 
                SetMapDifficulty(Mid(MutateString, 14), Sender);
        }   
    }
}

// for debug purposes only
/*
private final function DebugDoors(PlayerController Sender)
{
    local KFDoorMover door;
	local Inventory I;
    local int c;
    
    foreach DynamicActors(class'KFDoorMover', door)
        door.RespawnDoor();
        
    if ( Sender.Pawn != none ) {
		for ( I = Sender.Pawn.Inventory; I != none; I = I.Inventory ) {
            if ( Single(I) != none ) {
                KFFire(Single(I).GetFireMode(0)).DamageType = class'DamTypeFrag';
                KFFire(Single(I).GetFireMode(0)).DamageMax = 1000;
                return;
            }
            
            if ( ++c > 1000 )
                return; //circular link prevention
		}
	}
}
*/


function string MutatorList()
{
    local Mutator M;
    local string result;

    result = string(KF.BaseMutator.class);
    for ( M = KF.BaseMutator.NextMutator; M != None; M = M.NextMutator ) {
        result $= ","$string(M.class);
    }
    return result;
}

function SendZedList(PlayerController Sender)
{
    local int i, j, NumZeds;
    local string str, ZedClass;
    
    Sender.ClientMessage("Collection: " $ KF.MonsterCollection);
    Sender.ClientMessage("Boss: " $ KF.MonsterCollection.default.EndGameBossClass);
    for ( i=0; i< KF.MonsterCollection.default.MonsterClasses.Length; ++i ) {
        Sender.ClientMessage(KF.MonsterCollection.default.MonsterClasses[i].MID $ ": " $ KF.MonsterCollection.default.MonsterClasses[i].MClassName);
    }
    Sender.ClientMessage("SpecialSquads:");
    for ( i=0; i< KF.MonsterCollection.default.SpecialSquads.Length; ++i ) {
        if ( KF.MonsterCollection.default.SpecialSquads[i].ZedClass.Length > 0 ) {
            str = "";
            for( j=0; j<KF.MonsterCollection.default.SpecialSquads[i].ZedClass.Length; j++ ) {
                ZedClass = KF.MonsterCollection.default.SpecialSquads[i].ZedClass[j];
                NumZeds = KF.MonsterCollection.default.SpecialSquads[i].NumZeds[j];
                if( ZedClass != "" ) {
                    str @= NumZeds$"x"$GetItemName(ZedClass);
                }
            }
            if ( str != "" )
                Sender.ClientMessage("Wave "$string(i+1)$":" $ str);
        }
    }
}

function SendPlayerList(PlayerController Sender)
{
	local array<PlayerReplicationInfo> AllPRI;
    local PlayerController PC;
	local int i;
	
	Level.Game.GameReplicationInfo.GetPRIArray(AllPRI);
	for (i = 0; i<AllPRI.Length; i++) {
        PC = PlayerController(AllPRI[i].Owner);
		if( PC != none && AllPRI[i].PlayerName != "WebAdmin")
			Sender.ClientMessage(Right("   "$AllPRI[i].PlayerID, 3)$")"
                @ PC.GetPlayerIDHash()
                @ AllPRI[i].PlayerName
                , 'Log');
	}	
}

// @param Pct 0..1
simulated function string GetColoredPercent(float Pct, optional bool bRightAlign)
{
    local string s;
    
    s = string(int(100*Pct)) $ "%";
    if ( bRightAlign && Pct < 1.0 )
        s = " "$s;
    
    if ( Pct >= 0.90 )
        return ColorString(s,1,100,200); // light blue
    else if ( Pct >= 0.75 )
        return ColorString(s,1,200,1); // green
    else if ( Pct >= 0.50 )
        return ColorString(s,200,200,1); // yellow        
    
    return ColorString(s,200,1,1); // red        
}

function SendAccuracy(PlayerController Sender)
{
    local ScrnPlayerInfo SPI;
    local string msg;

    for ( SPI=GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner == none || SPI.PlayerOwner.PlayerReplicationInfo == none || SPI.HeadshotsPerGame == 0 )
            continue;
            
        msg = 
            ColoredPlayerName(SPI.PlayerOwner.PlayerReplicationInfo) $ ": "
            @ "Wave: "$GetColoredPercent(SPI.GetAccuracyWave(), false)
            @ ColorString(string(SPI.HeadshotsPerWave),1,220,1)$ColorString("/"$SPI.BodyShotsPerWave,200,200,200)
            @ " Game: "$GetColoredPercent(SPI.GetAccuracyGame(), false)
            @ ColorString(string(SPI.HeadshotsPerGame),1,220,1)$ColorString("/"$SPI.BodyshotsPerGame,200,200,200);
        if ( ScrnPlayerController(SPI.PlayerOwner) != none && ScrnPlayerController(SPI.PlayerOwner).ab_warning > 0 )
            msg @= ColorString("AB="$ScrnPlayerController(SPI.PlayerOwner).ab_warning$"%", 255, 200, 1);
		Sender.ClientMessage(msg);
    }     
    
}


static final function String FormatTime( int Seconds )
{
    local int Minutes, Hours;
    local String Time;

    if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

        Time = Hours$":";
	}
	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    if( Minutes >= 10 || Hours == 0 )
        Time = Time $ Minutes $ ":";
    else
        Time = Time $ "0" $ Minutes $ ":";

    if( Seconds >= 10 )
        Time = Time $ Seconds;
    else
        Time = Time $ "0" $ Seconds;

    return Time;
}


static function FillPlayInfo(PlayInfo PlayInfo)
{
    Super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelNormalMax","2.Normal Max Bonus Level ",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelHardMin","4.Hard Min Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelHardMax","4.Hard Max Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelSuiMin","5.Suicidal Min Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelSuiMax","5.Suicidal Max Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelHoeMin","7.HoE Min Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"BonusLevelHoeMax","7.HoE Max Bonus Level",1,0, "Text", "4;0:70",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"Post6RequirementScaling","Level 7+ Scaling",1,0, "Text", "6;0.01:4.00",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"MaxZombiesOnce","Max Specimens At Once",1,0, "Text", "4;8:254",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"FakedPlayers","Faked Players",1,0, "Text", "3;1:254",,,True);

    PlayInfo.AddSetting(default.BonusCapGroup,"bSpawnBalance","Balance Initial Inventory and Prices",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bSpawn0","Zero Cost of Initial Inventory",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bWeaponFix","Balance Weapons",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bHardcore","Hardcore Mode",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickups","Replace Pickups",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickupsStory","Replace Pickups (Story)",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceNades","Replace Grenades",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShieldWeight","Armor Has Weight",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bAltBurnMech","Alternate Burning Mechanism",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bGunslinger","Gunslinger Perk",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShowDamages","Show Damages",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceHUD","Replace HUD",1,0, "Check");

    PlayInfo.AddSetting(default.BonusCapGroup,"EventNum","Event", 0, 1, "Select", "0;Autodetect;255;Normal;1;Summer;2;Halloween;3;Xmas",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"bForceEvent","Force Event",1,0, "Check");

    //PlayInfo.AddSetting(default.BonusCapGroup,"PerkedWeapons","Custom Perked Weapons",1,1,"Text","42",,,True);
    //PlayInfo.AddSetting(default.BonusCapGroup,"CustomPerks","Custom Perks",1,1,"Text","42",,,True);

}

static function string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "BonusLevelNormalMax":         return "Maximum perk level, which bonuses can be applied on  difficulty. Perk levels above this won't have any extra bonuses.";
        case "BonusLevelHardMin":           return "Minimum perk level, which bonuses can be applied on Hard difficulty. Perk levels below will be granted with minimal bonus anyway.";
        case "BonusLevelHardMax":           return "Maximum perk level, which bonuses can be applied on Hard difficulty. Perk levels above this won't have any extra bonuses.";
        case "BonusLevelSuiMin":            return "Minimum perk level, which bonuses can be applied on Suicidal difficulty. Perk levels below will be granted with minimal bonus anyway.";
        case "BonusLevelSuiMax":            return "Maximum perk level, which bonuses can be applied on Suicidal difficulty. Perk levels above this won't have any extra bonuses.";
        case "BonusLevelHoeMin":            return "Minimum perk level, which bonuses can be applied on HoE difficulty. Perk levels below will be granted with minimal bonus anyway.";
        case "BonusLevelHoeMax":            return "Maximum perk level, which bonuses can be applied on HoE difficulty. Perk levels above this won't have any extra bonuses.";
        case "BonusLevelHoeMax":            return "Maximum perk level, which bonuses can be applied on HoE difficulty. Perk levels above this won't have any extra bonuses.";
        case "Post6RequirementScaling":     return "Additional requirement scaling after reaching level 6";
        case "MaxZombiesOnce":              return "Maximum specimens at once on playtime, note that high values will LAG when theres a lot of them.";
        case "FakedPlayers":                return "Minimal amount of players to use in calculation of zed count in wave. If FakedPlayers=6 and there are 3 players on the server, then wave will be in 6-player size.";

        case "bSpawnBalance":               return "Balances spawn weapons and its prices (e.g. Crossbow sell price = 225p instead of 600).";
        case "bHardcore":                   return "For those who still think game is too easy...";
        case "bSpawn0":                     return "All initial weapons costs nothing";
        case "bWeaponFix":                  return "Balances weapons. Replaces perk's initial inventory with Scrn Edition (SE) weapons.";
        case "bReplacePickups":             return "Replaces weapon pickups on a map with their Scrn Editon (SE) versions.";
        case "bReplacePickupsStory":        return "Replaces weapon pickups in Objective Mode with their Scrn Editon (SE) versions.";
        case "bReplaceNades":               return "Replaces hand grenades with 'coockable' ScrN version. Players can disable grenade cooking in ScrN Settings menu anyway. Disabling it here removes this ability from the server.";
        case "bShieldWeight":               return "Kevlar Vest weights 1 block instead of hand grenades. Players without vest can carry more. Automatically enables hand grenade replacing with ScrN version";
        case "bAltBurnMech":                return "Use Alternate Burning Mechanism. Shorter burning period, but higher damage at the begining. Also fixes many bugs, including Crawler Infinite Burning.";
        case "bGunslinger":                 return "Enabling Gunslinger perk will also remove dual pistols from the Sharpshooter perk";
        case "bShowDamages":                return "Allows showing damage values on the HUD. Clients will still be able to turn it off in their User.ini";
        case "bReplaceHUD":                 return "Replace heads-up display with ScrN version (recommended). Disable only if you have compatibility issues with other mods!";
        
        case "bForceEvent":                 return "Check it to force selected event";

        //case "PerkedWeapons":               return "List of perked custom weapons for perk bonuses in format '<PerkIndex>:<WeaponClassName>:<Bonuses>'";
        //case "CustomPerks":                 return "List of custom perks. Perks should be defined the same way as in Serverperks.ini";
        
    }
    return Super.GetDescriptionText(PropName);
}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    // append the mutator name.
    local int i;
    local string wave_status;

    super.GetServerDetails(ServerState);
    
    if ( !bServerInfoVeterancy ) {
        for ( i=0; i<ServerState.ServerInfo.Length; i++ ) {
            if ( ServerState.ServerInfo[i].Key == "Veterancy" )
                ServerState.ServerInfo.remove(i--, 1);
        }
    }

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.insert(i, 4);

    ServerState.ServerInfo[i].Key = "ScrN Balance";
    ServerState.ServerInfo[i++].Value = GetVersionStr();

    ServerState.ServerInfo[i].Key = "Min Bonus Level";
    ServerState.ServerInfo[i++].Value = String(MinLevel);
    ServerState.ServerInfo[i].Key = "Max Bonus Level";
    ServerState.ServerInfo[i++].Value = String(MaxLevel);


    if ( KF.IsInState('PendingMatch') )
        wave_status = "LOBBY";
    else if ( KF.IsInState('MatchInProgress') )
        wave_status = String(KF.WaveNum + 1) $ " / " $ KF.FinalWave;
    else if ( KF.IsInState('MatchOver') )
        wave_status = "Game Over";
    else
        wave_status = "Unknown";
    ServerState.ServerInfo[i].Key = "Current Wave";
    ServerState.ServerInfo[i++].Value = wave_status;
}

function SetLevels()
{
    if ( Level.Game.GameDifficulty >= 7 ) // HoE
    {
        MinLevel = BonusLevelHoeMin;
        MaxLevel = BonusLevelHoeMax;
    }
    else if (Level.Game.GameDifficulty >= 5 ) // Suicidal
    {
        MinLevel = BonusLevelSuiMin;
        MaxLevel = BonusLevelSuiMax;
    }
    else if ( Level.Game.GameDifficulty >= 4 ) // Hard
    {
        MinLevel = BonusLevelHardMin;
        MaxLevel = BonusLevelHardMax;
    }
    else
    {
        MinLevel = -1;
        MaxLevel = BonusLevelNormalMax;
    }
    
    if ( ScrnGT != none && ScrnGT.IsTourney() ) {
        MaxLevel = clamp(MaxLevel, 0, 6);
        MinLevel = MaxLevel;
    }    
    
    if ( MinLevel > MaxLevel )
        MinLevel = MaxLevel;
 
    default.MinLevel = MinLevel;
    default.MaxLevel = MaxLevel;
    if ( self.class != class'ScrnBalance' ) {
        class'ScrnBalance'.default.MinLevel = MinLevel;
        class'ScrnBalance'.default.MaxLevel = MaxLevel;
    }
    OriginalMaxLevel = MaxLevel;

    //for the replication
    SrvMinLevel = MinLevel;
    SrvMaxLevel = MaxLevel;

}

simulated function ApplySpawnBalance()
{
    if ( bSpawnBalance ) {
        // todo: make derived classes of the weapons below and change default values there
        class'CrossbowPickup'.default.cost = 1000; //increased from 800 and applied standard discount rate


        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.SRLevelEffects[5]="100% extra melee damage|20% faster melee attacks|20% faster melee movement|75% less damage from Bloat Bile|30% resistance to all damage|60% discount on Katana/Chainsaw/Sword|Spawn with an Axe|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";
        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.SRLevelEffects[6]="100% extra melee damage|25% faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|70% discount on Katana/Chainsaw/Sword|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";
        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.CustomLevelInfo="%r extra melee damage|%s faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|%d discount on Katana/Chainsaw/Sword|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";

        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[0]="5% extra Explosives damage|25% resistance to Explosives|10% discount on Explosives|52% off Remote Explosives and M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[1]="10% extra Explosives damage|30% resistance to Explosives|+1 Rocket, M203 and Hand Grenade capacity|Can carry 3 Remote Explosives|20% discount on Explosives|5% discount on Grenades and Rockets|56% off Remote Explosives and M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[2]="20% extra Explosives damage|35% resistance to Explosives|+2 Rocket, M203 and Hand Grenade capacity|Can carry 4 Remote Explosives|30% discount on Explosives|10% discount on Grenades and Rockets|60% off Remote Explosives and M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[3]="30% extra Explosives damage|40% resistance to Explosives|+3 Rocket, M203 and Hand Grenade capacity|Can carry 5 Remote Explosives|40% discount on Explosives|15% discount on Grenades and Rockets|64% off Remote Explosives and M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[4]="40% extra Explosives damage|45% resistance to Explosives|+4 Rocket, M203 and Hand Grenade capacity|Can carry 6 Remote Explosives|50% discount on Explosives|20% discount on Grenades and Rockets|68% off Remote Explosives and M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[5]="50% extra Explosives damage|50% resistance to Explosives|+5 Rocket, M203 and Hand Grenade capacity|Can carry 7 Remote Explosives|60% discount on Explosives|25% discount on Grenades and Rockets|72% off Remote Explosives and M79|Spawn with 10 hand grenades";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[6]="60% extra Explosives damage|55% resistance to Explosives|+6 Rocket, M203 and Hand Grenade capacity|Can carry 8 Remote Explosives|70% discount on Explosives|30% discount on Grenades and Rockets|76% off Remote Explosives and M79|Spawn with an M79";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.CustomLevelInfo="%s extra Explosives damage|%r resistance to Explosives|+%g Rocket, M203 and Hand Grenade capacity|Can carry %x Remote Explosives|70% discount on Explosives|%n discount on Grenades and Rockets|76% off Remote Explosives and M79|Spawn with an M79";

        // //class'FlamethrowerPickup'.default.cost = 1000; // up from 750 to match spawn value of other perks
        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.SRLevelEffects[5]="50% extra flame weapon damage|50% faster Flamethrower reload|25% faster MAC10 reload|50% faster Husk Gun charging|50% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|60% discount on flame weapons|Spawn with a MAC10";
        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.SRLevelEffects[6]="60% extra flame weapon damage|60% faster Flamethrower reload|30% faster MAC10 reload|60% faster Husk Gun charging|60% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|70% discount on flame weapons|Spawn with a Flamethrower";
        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.CustomLevelInfo="%s extra flame weapon damage|%m faster Flamethrower reload|%n faster MAC10 reload|%m faster Husk Gun charging|%s more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|%d discount on flame weapons|Spawn with a Flamethrower";
    }
    else
    {
        //restore default values
        class'CrossbowPickup'.default.cost = 800; //let players suicide-cheat

        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.SRLevelEffects[5]="100% extra melee damage|20% faster melee attacks|20% faster melee movement|75% less damage from Bloat Bile|30% resistance to all damage|60% discount on Katana/Chainsaw/Sword|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";
        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.SRLevelEffects[6]="100% extra melee damage|25% faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|70% discount on Katana/Chainsaw/Sword|Spawn with a Chainsaw and Body Armor|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";
        // class'ScrnBalanceSrv.ScrnVetBerserker'.default.CustomLevelInfo="%r extra melee damage|%s faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|%d discount on Katana/Chainsaw/Sword|Spawn with a Chainsaw and Body Armor|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions";

        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[0]="5% extra Explosives damage|25% resistance to Explosives|10% discount on Explosives|50% off Remote Explosives";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[1]="10% extra Explosives damage|30% resistance to Explosives|20% increase in Rocket, M203 and Hand Grenade capacity|Can carry 3 Remote Explosives|20% discount on Explosives|54% off Remote Explosives and M79|5% discount on Grenades and Rockets";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[2]="20% extra Explosives damage|35% resistance to Explosives|40% increase in Rocket, M203 and Hand Grenade capacity|Can carry 4 Remote Explosives|30% discount on Explosives|58% off Remote Explosives and M79|10% discount on Grenades and Rockets";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[3]="30% extra Explosives damage|40% resistance to Explosives|60% increase in Rocket, M203 and Hand Grenade capacity|Can carry 5 Remote Explosives|40% discount on Explosives|62% off Remote Explosives and M79|15% discount on Grenades and Rockets";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[4]="40% extra Explosives damage|45% resistance to Explosives|80% increase in Rocket, M203 and Hand Grenade capacity|Can carry 6 Remote Explosives|50% discount on Explosives|66% off Remote Explosives and M79|20% discount on Grenades and Rockets";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[5]="50% extra Explosives damage|50% resistance to Explosives|100% increase in Rocket, M203 and Hand Grenade capacity|Can carry 7 Remote Explosives|60% discount on Explosives|70% off Remote Explosives|25% discount on Grenades and Rockets|Spawn with a Pipe Bomb";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.SRLevelEffects[6]="60% extra Explosives damage|55% resistance to Explosives|120% increase in Rocket, M203 and Hand Grenade capacity|Can carry 8 Remote Explosives|70% discount on Explosives|74% off Remote Explosives|30% discount on Grenades and Rockets|Spawn with an M79 and Pipe Bomb";
        // class'ScrnBalanceSrv.ScrnVetDemolitions'.default.CustomLevelInfo="%s extra Explosives damage|%r resistance to Explosives|120% increase in Rocket, M203 and Hand Grenade capacity|Can carry %x Remote Explosives|%y discount on Explosives|%d off Remote Explosives|30% discount on Grenades and Rockets|Spawn with an M79 and Pipe Bomb";

        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.SRLevelEffects[5]="50% extra flame weapon damage|50% faster Flamethrower reload|25% faster MAC10 reload|50% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|60% discount on flame weapons|Spawn with a Flamethrower";
        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.SRLevelEffects[6]="60% extra flame weapon damage|60% faster Flamethrower reload|30% faster MAC10 reload|60% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|70% discount on flame weapons|Spawn with a Flamethrower and Body Armor";
        // class'ScrnBalanceSrv.ScrnVetFirebug'.default.CustomLevelInfo="%s extra flame weapon damage|%m faster Flamethrower reload|%n faster MAC10 reload|%s more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|%d discount on flame weapons|Spawn with a Flamethrower and Body Armor";
    }
}

simulated function ApplyWeaponFix()
{
    class'KFMod.ZEDGun'.default.UnlockedByAchievement = -1;
    class'KFMod.ZEDGun'.default.AppID = 0;
    class'KFMod.DwarfAxe'.default.UnlockedByAchievement = -1;
    class'KFMod.DwarfAxe'.default.AppID = 0;
    
    if ( bWeaponFix )
    {
        class'ScrnHumanPawn'.default.HealthRestoreRate = 7; //30% lower off-perk, but medics now have a bonus

        //class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.SRLevelEffects[6]="200% faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|18% faster movement speed|100% larger Medic Gun clip|50% faster reload with MP5/MP7|60% better Body Armor|70% discount on Body Armor||87% discount on Medic Guns| Spawn with Body Armor and MP7M";
        //class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.CustomLevelInfo="%s faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|%r faster movement speed|100% larger Medic Gun clip|50% faster reload with MP5/MP7|%a better Body Armor|%d discount on Body Armor||%m discount on Medic Guns| Spawn with Body Armor and MP7M";
    }
    else
    {
        class'ScrnHumanPawn'.default.HealthRestoreRate = 10;

        //class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.SRLevelEffects[6]="200% faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|18% faster movement speed|100% larger Medic Gun clip|50% faster reload with MP5/MP7|75% better Body Armor|70% discount on Body Armor||87% discount on Medic Guns| Spawn with Body Armor and MP7M";
        //class'ScrnBalanceSrv.ScrnVetFieldMedic'.default.CustomLevelInfo="%s faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|%r faster movement speed|100% larger Medic Gun clip|50% faster reload with MP5/MP7|75% better Body Armor|%d discount on Body Armor||%m discount on Medic Guns| Spawn with Body Armor and MP7M";
    }
}


/*
    Weapon bonuses' letters:
    W - weapon bonuses (reload, recoil)
    $ - discount (weapon, ammo)
    A - primary ammo bonuses (count, magazine size)
    B - secondary ammo bonuses (count)
    D - Override damage type with perk's default one (to enable leveling).
    d - Override secondary fire's damage type
    P - primary fire bonuses (damage, headshot multiplier, fire rate)
    S - secondary fire bonuses (damage, headshot multiplier, fire rate)
    * - Special weapon
 */
function LoadCustomWeapons()
{
    local string S, WeaponClassStr, WeaponBonusStr, PriceStr;
    local int i,j;
    local int PerkIndex, MaxPerkIndex;
    local bool AllBonuses;
    local class<KFWeapon> W;
    local class<ScrnVeterancyTypes> ScrnPerk;
    local ScrnCustomWeaponLink ClientLink;
	local int ForcePrice;
    
    if ( ScrnGT != none && ScrnGT.IsTourney() )
        return; // no custom weapons in tourney mode

    // Load custom perks first
    MaxPerkIndex = 9;
    for( i = 0; i < CustomPerks.Length; i++ ) {
        S = CustomPerks[i];
        j = InStr(S,":");
        if ( j > 0 ) {
            PerkIndex = int(Left(S, j));
            if ( PerkIndex < 10 || PerkIndex > 255 ) {
                log("Custom Perk index must be between 10 and 255! Perk '"$S$"' ignored", Class.Outer.Name);
                continue;
            }
            S = Mid(S, j+1);
        }
        else {
            PerkIndex = MaxPerkIndex + 1;
        }

        ScrnPerk = class<ScrnVeterancyTypes>(DynamicLoadObject(S, Class'Class'));
        if( ScrnPerk != None ) {
            Perks[PerkIndex] = ScrnPerk;
            AddToPackageMap(String(ScrnPerk.Outer.Name));
            MaxPerkIndex = max(MaxPerkIndex, PerkIndex);
            log("Perk: '" $ S $"' loaded with index = " $ String(PerkIndex), Class.Outer.Name);
        }
        else
            log("Unable to load custom perk: '" $ S $"'.", Class.Outer.Name);
    }

    // Load weapon bonuses
    for( i=0; i < PerkedWeapons.Length; i++ ) {
		PriceStr = "";
		WeaponBonusStr = "";
		
        S = PerkedWeapons[i];
        j = InStr(S,":");
        if( j <= 0 ) {
            log("Illegal Custom Weapon definition: '" $ S $"'! Wrong perk index.", Class.Outer.Name);
            continue;
        }

        PerkIndex = int(Left(S, j));
        if ( PerkIndex < 0 || PerkIndex >= Perks.length || Perks[PerkIndex] == none ) {
            log("Illegal Custom Weapon definition: '" $ S $"'! Wrong perk index.", Class.Outer.Name);
            continue;
        }
        ScrnPerk = Perks[PerkIndex];
        WeaponClassStr = Mid(S, j+1);
		// bonuses
        j = InStr(WeaponClassStr,":");
        if ( j >= 0 ) {
            WeaponBonusStr =  Mid(WeaponClassStr, j+1);
            WeaponClassStr = Left(WeaponClassStr, j);
			
			// price
			j = InStr(WeaponBonusStr,":");
			if ( j >= 0 ) {
				PriceStr =  Mid(WeaponBonusStr, j+1);
				WeaponBonusStr = Left(WeaponBonusStr, j);
			}
        }
		AllBonuses = WeaponBonusStr == "";
		ForcePrice = int(PriceStr);
		//log("WeaponBonusStr="$WeaponBonusStr @ "ForcePrice="$ForcePrice  , Class.Outer.Name);

        W = class<KFWeapon>(DynamicLoadObject(WeaponClassStr, Class'Class'));
        if( W == none ) {
            log("Can't load Custom Weapon: '" $ WeaponClassStr $"'!", Class.Outer.Name);
            continue;
        }

        ClientLink = spawn(class'ScrnBalanceSrv.ScrnCustomWeaponLink', self);
        if ( ClientLink == none ) {
            log("Can't load Client Replication Link for a Custom Weapon: '" $ W $"'!", Class.Outer.Name);
            continue;
        }
        //add to the begining
        ClientLink.NextReplicationInfo = CustomWeaponLink;
        CustomWeaponLink = ClientLink;

        ClientLink.Perk = ScrnPerk;
        ClientLink.WeaponClass = W;
        if ( AllBonuses ) {
            ClientLink.bWeapon = true;
            ClientLink.bDiscount = true;
            ClientLink.bFire = true;
            ClientLink.bFireAlt = true;
            ClientLink.bAmmo = true;
            ClientLink.bAmmoAlt = true;
        }
        else {
            ClientLink.bWeapon = InStr(WeaponBonusStr,"W") != -1;
            ClientLink.bDiscount = InStr(WeaponBonusStr,"$") != -1;
            ClientLink.bFire = InStr(WeaponBonusStr,"P") != -1;
            ClientLink.bFireAlt = InStr(WeaponBonusStr,"S") != -1;
            ClientLink.bAmmo = InStr(WeaponBonusStr,"A") != -1;
            ClientLink.bAmmoAlt = InStr(WeaponBonusStr,"B") != -1;
        }
        ClientLink.bOverrideDamType = InStr(WeaponBonusStr,"D") != -1;
        ClientLink.bOverrideDamTypeAlt = InStr(WeaponBonusStr,"d") != -1;
        ClientLink.bSpecial = InStr(WeaponBonusStr,"*") != -1;
        ClientLink.ForcePrice = ForcePrice;

        ClientLink.LoadWeaponBonuses();
    }
}

function LoadSpawnInventory()
{
	local int i, j, index;
	local string S, PickupStr, LevelStr, AmmoStr, SellStr;
	local int PerkIndex;
	local class<ScrnVeterancyTypes> ScrnPerk;
	local class<Pickup> Pickup;
	
	for ( i=0; i<SpawnInventory.length; ++i ) {
		LevelStr = "";
		AmmoStr = "";
		SellStr = "";
		S = SpawnInventory[i];
		j = InStr(S,":");
        if( j <= 0 ) {
            log("Illegal Spawn Inventory definition: '" $ S $"'! Wrong perk index.", Class.Outer.Name);
            continue;
        }	
        PerkIndex = int(Left(S, j));
        if ( PerkIndex < 0 || PerkIndex >= Perks.length || Perks[PerkIndex] == none ) {
            log("Illegal Spawn Inventory definition: '" $ S $"'! Wrong perk index.", Class.Outer.Name);
            continue;
        }	
		ScrnPerk = Perks[PerkIndex];	
		PickupStr = Mid(S, j+1);
		//pickup
		j = InStr(PickupStr,":");
		if ( j >= 0 ) {
            LevelStr = Mid(PickupStr, j+1);
            PickupStr = Left(PickupStr, j);		

			// ammo
			j = InStr(LevelStr,":");
			if ( j >= 0 ) {
				AmmoStr =  Mid(LevelStr, j+1);
				LevelStr = Left(LevelStr, j);
				
				// sell value
				j = InStr(AmmoStr,":");
				if ( j >= 0 ) {
					SellStr = Mid(AmmoStr, j+1);
					AmmoStr = Left(AmmoStr, j);
				}				
			}			
		}
		Pickup = class<Pickup>(DynamicLoadObject(PickupStr, Class'Class'));
        if( Pickup == none ) {
            log("Can't load Spawn Inventory: '" $ PickupStr $"'!", Class.Outer.Name);
            continue;
        }	

		index = ScrnPerk.default.DefaultInventory.length;
		ScrnPerk.default.DefaultInventory.insert(index, 1);
		ScrnPerk.default.DefaultInventory[index].PickupClass = Pickup;
		// LevelStr in format <MinLevel>[-<MaxLevel>]
		j = InStr(LevelStr,"-");
		if ( j > 0 ) {
			ScrnPerk.default.DefaultInventory[index].MinPerkLevel = byte(Left(LevelStr, j));
			ScrnPerk.default.DefaultInventory[index].MaxPerkLevel = byte(Mid(LevelStr, j+1));
		}
		else {
			ScrnPerk.default.DefaultInventory[index].MinPerkLevel = byte(LevelStr);
			ScrnPerk.default.DefaultInventory[index].MaxPerkLevel = ScrnPerk.default.DefaultInventory[index].MinPerkLevel;
		}
		// AmmoStr in format <Ammo>[+<AmmoPerLevel>]
		if ( AmmoStr != "" ) {
			ScrnPerk.default.DefaultInventory[index].bSetAmmo = true;
			j = InStr(AmmoStr,"+");
			if ( j > 0 ) {
				ScrnPerk.default.DefaultInventory[index].AmmoAmount = int(Left(AmmoStr, j));
				ScrnPerk.default.DefaultInventory[index].AmmoPerLevel = int(Mid(AmmoStr, j+1));
			}
			else {
				ScrnPerk.default.DefaultInventory[index].AmmoAmount = int(AmmoStr);
			}
		}
		// SellValue
		if ( SellStr != "" )
			ScrnPerk.default.DefaultInventory[index].SellValue = int(SellStr);
	}
}


function SetupRandomSpawn(ScrnRandomItemSpawn item)
{
    if ( !bReplacePickups ) {
        item.PickupClasses[0] = Class'KFMod.DualiesPickup';
        item.PickupClasses[1] = Class'KFMod.ShotgunPickup';
        item.PickupClasses[2] = Class'KFMod.BullpupPickup';
        item.PickupClasses[3] = Class'KFMod.DeaglePickup';
        item.PickupClasses[4] = Class'KFMod.WinchesterPickup';
        item.PickupClasses[5] = Class'KFMod.AxePickup';
        item.PickupClasses[6] = Class'KFMod.MachetePickup';
        item.PickupClasses[8] = Class'KFMod.MAC10Pickup';
    }
}

function SetupStoryRules(KFLevelRules_Story StoryRules)
{
	local int i,j;
	local Class<Inventory> OldInv;
	
	for( i=0; i<StoryRules.RequiredPlayerEquipment.Length; ++i ) {
		OldInv = StoryRules.RequiredPlayerEquipment[i];
		for ( j=0; j<pickupReplaceArray.length; ++j ) {
			if ( pickupReplaceArray[j].oldClass.default.InventoryType == OldInv ) {
				StoryRules.RequiredPlayerEquipment[i] = pickupReplaceArray[j].NewClass.default.InventoryType;
				break;
			}
		}
	}
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local int i;
    //Log("CheckReplacement: " $ String(Other), Class.Outer.Name);
    
    // first check classes that need to be replaced
	if ( Other.class == class'KFRandomItemSpawn' ) {	
		ReplaceWith(Other, "ScrnBalanceSrv.ScrnRandomItemSpawn");
		return false;
	}  
	else if ( Other.class == class'KFAmmoPickup' ) {
        AmmoBoxMesh = Other.StaticMesh;
        AmmoBoxDrawScale = Other.DrawScale;
        AmmoBoxDrawScale3D = Other.DrawScale3D;
		ReplaceWith(Other, "ScrnBalanceSrv.ScrnAmmoPickup");
		return false;
	}  
	else if ( bReplacePickups && Pickup(Other) != none && KF.IsInState('MatchInProgress') ) {
        // don't replace pickups placed on the map by the author - replace only dropped ones
        // or spawned by KFRandomItemSpawn
		i = FindPickupReplacementIndex(Pickup(Other));
		if ( i != -1 ) {
			ReplaceWith(Other, string(pickupReplaceArray[i].NewClass));
			return false;
		}
        return true; // no need to replace
	}    


    // classes below do not need replacement
    if ( PlayerController(Other)!=None ) {
        if ( ScrnPlayerController(Other) != none )
            ScrnPlayerController(Other).Mut = self;
    }
    else if ( KFMonster(Other) != none ) {
        // harder zapping 
        if ( bWeaponFix ) {
            if ( ZombieFleshPound(Other) != none )
                KFMonster(Other).ZapThreshold = 3.75;
            else if ( KFMonster(Other).default.Health >= 1000 )
                KFMonster(Other).ZapThreshold = 1.75;
        }
        
        GameRules.RegisterMonster(KFMonster(Other));
    }
    else if ( SRStatsBase(Other) != none ) {
        class'ScrnAchievements'.static.InitAchievements(SRStatsBase(Other).Rep); 
        SetupRepLink(SRStatsBase(Other).Rep);
    }
	else if ( ScrnRandomItemSpawn(Other) != none) {
		SetupRandomSpawn(ScrnRandomItemSpawn(Other));
	}
    else if ( Other.class == class'ScrnAmmoPickup' ) {
        Other.SetStaticMesh(AmmoBoxMesh);
        Other.SetDrawScale(AmmoBoxDrawScale);
        Other.SetDrawScale3D(AmmoBoxDrawScale3D);
    }    
	else if ( bStoryMode ) {
		if ( KFLevelRules_Story(Other) != none  ) {
			if ( bReplacePickupsStory )
				SetupStoryRules(KFLevelRules_Story(Other));
		}	
		else if ( KF_StoryNPC(Other) != none ) {
			if ( Other.class == class'KF_BreakerBoxNPC' ) // don't alter subclasses
				KF_StoryNPC(Other).BaseAIThreatRating = 20;
			else if ( Other.class == class'KF_RingMasterNPC' )
				KF_StoryNPC(Other).BaseAIThreatRating = 40;
		}
	}
    
    return true;
}

function SetupRepLink(ClientPerkRepLink R)
{
    local ScrnClientPerkRepLink ScrnRep;
    local PlayerReplicationInfo PRI;
    local LinkedReplicationInfo L;
    
    if ( R == none )
        return;
        
    // replace with ScrnClientPerkRepLink
    ScrnRep = ScrnClientPerkRepLink(R);
    if ( bScrnClientPerkRepLink && ScrnRep == none ) {
        ScrnRep = Spawn(Class'ScrnClientPerkRepLink',R.Owner);
        ScrnRep.StatObject = R.StatObject;
        ScrnRep.StatObject.Rep = ScrnRep;
        ScrnRep.NextReplicationInfo = R.NextReplicationInfo;
        
        ScrnRep.ServerWebSite = R.ServerWebSite;
        ScrnRep.MinimumLevel = R.MinimumLevel;
        ScrnRep.MaximumLevel = R.MaximumLevel;
        ScrnRep.RequirementScaling = R.RequirementScaling;
        ScrnRep.CachePerks = R.CachePerks;
        
        PRI = R.StatObject.PlayerOwner.PlayerReplicationInfo; 
		if( PRI.CustomReplicationInfo==None || PRI.CustomReplicationInfo==R)
			PRI.CustomReplicationInfo = ScrnRep;
		else
		{
			for( L=PRI.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo )
				if( L.NextReplicationInfo==None || L.NextReplicationInfo==R)
				{
					L.NextReplicationInfo = ScrnRep;
					break;
				}
		}        
        
        R.GotoState('');
        R.Destroy();
        R = ScrnRep;
    }
    
    if ( ScrnGT != none )
        ScrnGT.SetupRepLink(R);
        
    if ( ScrnRep != none ) {
        // used for client replication
        ScrnRep.TotalCategories = min(ScrnRep.ShopCategories.Length, 255);
        ScrnRep.TotalWeapons = ScrnRep.ShopInventory.Length;
        ScrnRep.TotalChars = ScrnRep.CustomChars.Length;    
    }
}



static function ModifyGameHints()
{
    local int i;

    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: You can reload a single shell into Hunting Shotgun.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: You can't skip Hunting Shotgun's reload. So use it with caution.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Combat Shotgun is made much better. Give it a try.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Shotguns, except Combat and Hunting, penetrate fat bodies worse than small enemies.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: M99 can't stun Scrake with a body-shot. Crossbow has no fire speed bonus as in original game before v1035.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: M14EBR has different laser sights. Choose the color you like!";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Hand grenades can be 'cooked'. You can enable this on 'Scrn Balance' settings page in the Main Menu.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Husk Gun's secondary fire acts as Napalm Thrower. You should definitely try it out!";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Gunslinger has bonuses both for single and dual pistols. But real Cowboys use only dualies.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Gunslinger becomes a Cowboy while using dual pistols without wearing an armor (except jacket). Cowboy moves, shoots and reloads his pistols much faster. From the other side, he dies faster too..";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Berserker, while holding non-melee weapons, moves slower than other perks.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Chaisaw's secondary fire can stun Scrakes the same way as an Axe.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Chainsaw consumes fuel. Raised power makes it a beast... until you need to refill";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Medic, while holding a syringe, runs same fast as while holding a knife.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Medics can heal much faster than other perks. If you aren't a Medic, don't screw up the healing process with your lame injection.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: FN-FAL has bullet penetration and 2-bullet fixed burst mode.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: MK23 has no bullet penetration but double size of magazine, comparing to Magnum .44";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Your experience and perk bonus levels can be different. If they are, you'll see 2 perk icons on your HUD.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: If you see two perk icons on your HUD, left one shows your experience level, right - actual level of perk bonuses you gain.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Flare pistol has an incremental burn DoT (iDoT). The more you shoot the more damage zeds take from burning.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Medic nades are for healing only. Zeds are not taking damage neither fear them";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: If you have just joined the game and got blamed - maybe it is just a welcome gift. Don't worry - shit happens.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Balance: Nailgun can nail enemies to walls... nail them alive! Crucify your ZED!";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Console Command: TOGGLEPLAYERINFO - hides health bars while keeping the rest of the HUD.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Console Command: MVOTE - access to ScrN Voting. Type MVOTE HELP for more info.";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Console Command: DROPALLWEAPONS - drops all your weapons to the ground. What else did you expected?";
    class'KFMod.KFGameType'.default.KFHints[i++] = "ScrN Console Command: TOGGLEWEAPONLOCK - lock/unlocks your weapons on the ground.";
}

simulated function PreBeginPlay()
{
    super.PreBeginPlay();

    // v7.31: do not modify KFGameType's hints, if other game type is in place (e.g. ScrnStoryGame)
    if ( Level.GetGameClass() == class'KFMod.KFGameType' )
        ModifyGameHints();
}

function ForceEvent()
{
    local int i, j;
    local class<KFMonstersCollection> MC;
    
    if ( EventNum == 255 ) {
        // force regular zeds
        log("Normal zeds forced by server setting (EventNum=255)", class.outer.name);
        KF.MonsterCollection = class'KFMonstersCollection';
        CurrentEventNum = 0;
    }
    else {
        i = FindMapInfo();
        if ( i != -1 && MapInfo[i].ForceEventNum > 0 ) 
            CurrentEventNum = MapInfo[i].ForceEventNum;
        else if ( EventNum == 0 )
            CurrentEventNum = int(KF.GetSpecialEventType()); // autodetect event
        else
            CurrentEventNum = EventNum;
        
        // custom events
        if ( CurrentEventNum >= 100 && CurrentEventNum < 200 ) {
            for ( i=0; i<CustomEvents.length; ++i ) {
                if ( CustomEvents[i].EventNum == CurrentEventNum ) {
                    MC = Class<KFMonstersCollection>(DynamicLoadObject(CustomEvents[i].MonstersCollection, Class'Class'));
                    break;
                }
            }
            if ( MC != none ) {
                log("Custom zeds forced for this map: " $ MC, class.outer.name);
                KF.MonsterCollection = MC;
                for ( j=0; j<CustomEvents[i].ServerPackages.length; ++j ) {
                    AddToPackageMap(CustomEvents[i].ServerPackages[j]);
                    log(CustomEvents[i].ServerPackages[j] $ " added to ServerPackages", class.outer.name);
                }
            }
            else {
                log("Custom event ("$CurrentEventNum$") is illegal. Regular zeds will be used instead.", class.outer.name);
                KF.MonsterCollection = class'KFMonstersCollection';
                CurrentEventNum = 0;
            }
        }
        else {
            switch (CurrentEventNum) {
                case 0: case 255: // force regular zeds
                    log("Normal zeds forced for this map", class.outer.name);
                    KF.MonsterCollection = class'KFMonstersCollection';
                    CurrentEventNum = 0;
                    break;
                case 1:
                    log("Summer zeds forced for this map", class.outer.name);
                    KF.MonsterCollection = class'KFMonstersSummer';
                    break;
                case 2:
                    log("Halloween zeds forced for this map", class.outer.name);
                    KF.MonsterCollection = class'KFMonstersHalloween';
                    break;
                case 3:
                    log("Xmas zeds forced for this map", class.outer.name);
                    KF.MonsterCollection = class'KFMonstersXmas';
                    break;
                default:
                    log("Unknown Event Number: "$CurrentEventNum, class.outer.name);
                    CurrentEventNum = EventNum;
                    return;
            }
        }
    }
    KF.SpecialEventMonsterCollections[KF.GetSpecialEventType()] = KF.MonsterCollection;
    class'ScrnGameRules'.static.ResetGameSquads(KF, CurrentEventNum);
    KF.PrepareSpecialSquads();
    KF.LoadUpMonsterList();
}

// returns index from Squads array or -1, if squad is not found and bCreateNew=false
// quad is not found and bCreateNew=true, new squad will be added with a given name
function int FindSquad(String SquadName, optional bool bCreateNew)
{
    local int i;
    
    for ( i=0; i<Squads.length; ++i )
        if ( Squads[i].SquadName ~= SquadName )
            return i;
            
    if ( bCreateNew ) {
        Squads.insert(i, 1);
        Squads[i].SquadName = SquadName;
        return i;
    }
    
    return -1;
}

function SetupVoteSquads()
{
    local int i, j, q;
    local Class<KFMonster> MC;
    local name pkg;
    
    for ( i=0; i<VoteSquad.length; ++i ) {
        if ( VoteSquad[i].SquadName == "" || VoteSquad[i].MonsterClass == "" || VoteSquad[i].NumMonsters == 0 )
            continue;
            
        MC = Class<KFMonster>(DynamicLoadObject(VoteSquad[i].MonsterClass,Class'Class'));
        if ( MC == none ) {
            log("SetupVoteSquad: Unable to load monster '"$VoteSquad[i].MonsterClass, class.outer.name);
            continue;
        }
        
        MC.static.PreCacheAssets(Level);
        
        pkg = MC.outer.name;
        if ( pkg != 'KFChar' ) {
            AddToPackageMap(String(pkg));
            log(pkg $ " added to ServerPackages", class.outer.name);
        }
        
        q = FindSquad(VoteSquad[i].SquadName, true);
        j = VoteSquad[i].NumMonsters;
        while ( j-- > 0 )
            Squads[q].Monsters[Squads[q].Monsters.length] = MC;
    }
}

function bool IsSquadWaitingToSpawn()
{
    return SquadSpawnedMonsters > 0 && KF.WaveMonsters < SquadSpawnedMonsters;
}

function SpawnSquad(String SquadName)
{
    local int q, count, i;
    
    if ( KF.bTradingDoorsOpen || KF.TotalMaxMonsters <= 0 || IsSquadWaitingToSpawn() )
        return;
    
    q = FindSquad(SquadName);
    if ( q == -1 )
        return;
        
    count = Squads[q].Monsters.length;
    if ( count == 0 || count > KF.TotalMaxMonsters - KF.NextSpawnSquad.Length )
        return;
    SquadSpawnedMonsters = KF.WaveMonsters + count;
    KF.NextSpawnSquad.insert(0, count);
    for ( i=0; i<count; ++i )
        KF.NextSpawnSquad[i] = Squads[q].Monsters[i];
    //if( KF.NextSpawnSquad.length > 6 )
    //        KF.NextSpawnSquad.Remove(6, KF.NextSpawnSquad.length - 6);
    KF.LastZVol = KF.FindSpawningVolume();
    KF.LastSpawningVolume = KF.LastZVol;    
}

function SetMaxZombiesOnce()
{
    local int i, value;
    
    i = FindMapInfo();
    if ( i != -1 && MapInfo[i].MaxZombiesOnce >= 16 )
        value = MapInfo[i].MaxZombiesOnce;
    else 
        value = MaxZombiesOnce;

    value = clamp(value, 16, 254);
    KF.StandardMaxZombiesOnce = value;
    KF.MaxZombiesOnce = value;
    KF.MaxMonsters = Clamp(KF.TotalMaxMonsters,5,value);
}

function PostBeginPlay()
{
    local ScrnVotingHandlerMut VH;

    KF = KFGameType(Level.Game);
    if (KF == none) {
        Log("ERROR: Wrong GameType (requires KFGameType)", Class.Outer.Name);
        Destroy();
        return;
    }
    
    Mut = self;
    default.Mut = self;
    class'ScrnBalance'.default.Mut = self; // in case of classes extended from ScrnBalance
    
    KF.MonsterCollection = KF.SpecialEventMonsterCollections[KF.GetSpecialEventType()]; // v1061 fix
    KF.bUseZEDThreatAssessment = true; // always use ScrnHumanPawn.AssessThreatTo()
    bStoryMode = KFStoryGameInfo(KF) != none;
    bTSCGame = KF.IsA('TSCGame');
    ScrnGT = ScrnGameType(KF);
    if ( ScrnGT != none ) {
        ScrnGT.ScrnBalanceMut = self;
        ScrnGT.bCloserZedSpawns = bCloserZedSpawns;
    }

    
    if ( bForceEvent )
        ForceEvent();
    else 
        CurrentEventNum = int(KF.GetSpecialEventType()); // autodetect event

    AddToPackageMap("ScrnSnd.uax"); // Promoted!!!!!!!!!! :)

	if ( !bStoryMode ) {
		SetMaxZombiesOnce();
	}
    
    // CHECK & LOAD SERVERPERKS
    GetRidOfMut('AliensKFServerPerksMut');
    FindServerPerksMut();
    if ( ServerPerksMut == none ) {
        log("ServerPerksMut must be loaded before ScrN Balance! Loading it now...", class.outer.name);
        Level.Game.AddMutator(ServerPerksPkgName, false);
        //check again
        FindServerPerksMut();
        if ( ServerPerksMut == none )
            log("Unable to spawn " $ ServerPerksPkgName, class.outer.name);
    }
    bAllowAlwaysPerkChanges = ServerPerksMut.GetPropertyText("bAllowAlwaysPerkChanges") ~= "True";
    
    
    if ( !ClassIsChildOf(KF.PlayerControllerClass, class'ScrnBalanceSrv.ScrnPlayerController') ) {
        KF.PlayerControllerClass = class'ScrnBalanceSrv.ScrnPlayerController';
        KF.PlayerControllerClassName = string(Class'ScrnBalanceSrv.ScrnPlayerController');
    }

    if ( bReplaceHUD )
        KF.HUDType = string(Class'ScrnBalanceSrv.ScrnHUD');
		
	if ( bReplaceScoreBoard )
		Level.Game.ScoreBoardType = string(Class'ScrnBalanceSrv.ScrnScoreBoard');

    KF.LoginMenuClass = string(Class'ScrnBalanceSrv.ScrnInvasionLoginMenu');

    SetLevels();
    //exec this on server side only
    ApplySpawnBalance();
    ApplyWeaponFix();

    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);
    GameRules = Spawn(Class'ScrnBalanceSrv.ScrnGameRules', self);
    if ( GameRules != none ) {
        GameRules.bShowDamages = bShowDamages;
        GameRules.bUseAchievements = bUseAchievements && KF.GameDifficulty >= 2;
        if ( GameRules.bUseAchievements ) {
            // spawn achievement handlers
            GameRules.Spawn(Class'ScrnBalanceSrv.ScrnAchHandler', GameRules);
        }
        
        if ( bResetSquadsAtStart ) {
            GameRules.ResetGameSquads(KF, CurrentEventNum);
        }
    }
    else {
        log("Unable to spawn Game Rules!", class.outer.name);
    }
    
    if (bAltBurnMech) {
        BurnMech = spawn(class'ScrnBalanceSrv.ScrnBurnMech');
        default.BurnMech = BurnMech;
        class'ScrnBalance'.default.BurnMech = BurnMech;
    }

    if ( bAllowVoting ) {
        VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Level.Game);
        if ( VH == none ) {
            Level.Game.AddMutator(string(class'ScrnVotingHandlerMut'), false);
            VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Level.Game);
        }
        if ( VH != none ) {
            MyVotingOptions = ScrnBalanceVoting(VH.AddVotingOptions(class'ScrnBalanceSrv.ScrnBalanceVoting'));
            if ( MyVotingOptions != none ) {
                MyVotingOptions.Mut = self;
            }
        }
        else
            log("Unable to spawn voting handler mutator", class.outer.name);
    }

    LoadCustomWeapons();
    InitSettings();
	LoadSpawnInventory();
    SetupVoteSquads();

	if ( bStoryMode ) {
		class'ScrnAchievements'.static.RegisterAchievements(class'AchObjMaps');
	}
    
    
    Log(FriendlyName @ GetVersionStr()$" loaded", class.outer.name);
}

function InitDoors()
{
    local KFUseTrigger t;
    
    foreach DynamicActors(class'KFUseTrigger', t) {
        if ( t.DoorOwners.Length >= 2 )
            DoorKeys[DoorKeys.Length] = t;
    }
}

function CheckDoors()
{
    local int i, j;
    local bool bBlowDoors;
    local KFUseTrigger key;
    
    for ( i=0; i<DoorKeys.length; ++i) {
        key = DoorKeys[i];
        bBlowDoors = false;
        for ( j=1; j<key.DoorOwners.Length; ++j ) {
            // blow all doors if one is blown
            if ( key.DoorOwners[j].bDoorIsDead != key.DoorOwners[0].bDoorIsDead ) {
                bBlowDoors = true;
                break;
            }
        }
        if ( bBlowDoors ) {
            for ( j=0; j<key.DoorOwners.Length; ++j ) {
                if ( !key.DoorOwners[j].bDoorIsDead )
                    key.DoorOwners[j].GoBang(none, vect(0,0,0), vect(0,0,0), none);
            }        
        }
    }
    
}


function LockPerk(class<ScrnVeterancyTypes> Perk, bool bLock)
{
    local Controller P;
    local PlayerController Player;
    local ClientPerkRepLink L;
    local int i;

    Perk.default.bLocked = bLock;

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = PlayerController(P);
        if ( Player != none && SRStatsBase(Player.SteamStatsAndAchievements) != none ) {
            L = SRStatsBase(Player.SteamStatsAndAchievements).Rep;
            if ( L != none ) {
                for ( i=0; i < L.CachePerks.length; ++i ) {
                    if ( L.CachePerks[i].PerkClass == Perk ) {
                        L.CachePerks[i].CurrentLevel = Perk.static.PerkIsAvailable(L);
                        L.ClientReceivePerk(i, L.CachePerks[i].PerkClass, L.CachePerks[i].CurrentLevel);
                        // if player uses locked perk, pick another, unlocked perk for him
                        if ( L.CachePerks[i].CurrentLevel == 0 && KFPlayerReplicationInfo(Player.PlayerReplicationInfo).ClientVeteranSkill == Perk ) {
                            L.ServerSelectPerk(L.PickRandomPerk());
                        }
                        break;
                    }
                }
            }
        }
    }
}

// searches MapInfo array for a given map 
// returns -1 if map not found
function int FindMapInfo(optional string MapName)
{
    local int i;
    
    if ( MapName == "" )
        MapName = KF.GetCurrentMapName(Level);
    
    for ( i = 0; i < MapInfo.length; ++i ) {
        if ( MapInfo[i].MapName ~= MapName )
            return i;
    }
    
    return -1;
}
// creates new MapInfo record, if map is not found. 
// Returns array index
function int CreateMapInfo(optional string MapName)
{
    local int i;

    if ( MapName == "" )
        MapName = KF.GetCurrentMapName(Level);
        
    i = FindMapInfo(MapName);
    
    if ( i == -1 ) {
        i = MapInfo.length;
        MapInfo.insert(MapInfo.length, 1);
        MapInfo[i].MapName = MapName;    
        MapInfo[i].MaxZombiesOnce = MaxZombiesOnce;
    }
    
    return i;
}

function bool SetMapZeds(int value)
{
    local int i;
    
    if ( value < 32 || value > 192 )
        return false;
    
    i = CreateMapInfo();
    MapInfo[i].MaxZombiesOnce = value;
    SaveConfig();
    return true;
}

function SetMapDifficulty(string StrDiff, PlayerController Sender)
{
    local int i;
    local float d;
    
    i = FindMapInfo();
    
    if ( StrDiff == "" ) {
        if ( i != -1 )
            d = MapInfo[i].Difficulty;
        Sender.ClientMessage("Map Difficulty = "$d$". (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
        return;
    }
    
    if ( StrDiff != "0" && StrDiff != "0.0" && StrDiff != "0.00" ) {
        d = float(StrDiff);
        if ( d == 0.0 ) {
            Sender.ClientMessage("Map Difficulty must be a number between -1.0 and 1.0! (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
            return;
        }
    }
    if ( d < -1.0 || d > 1.0 ) {
        Sender.ClientMessage("Map Difficulty must be a number between -1.0 and 1.0! (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
        return;
    }
    
    if ( i == -1 ) 
        i = CreateMapInfo();
    MapInfo[i].Difficulty = d;
    SaveConfig();
}

function bool ShouldReplacePickups()
{
	if ( bStoryMode )
		return bReplacePickupsStory;
	
	return bReplacePickups;	
}

// replaces weapon pickup's inventory type with ScrN version of that weapon
// returns true of replacement was made
function bool ReplacePickup( Pickup item )
{
	local int i;
	
	if ( FragPickup(item) != none ) {
		if ( !bReplaceNades || ScrnFragPickup(item) != none )
			return false;
			
		i = FragReplacementIndex; // index of frag replacement
	}
	else {
		if ( !ShouldReplacePickups() ) 
			return false;
		i = FindPickupReplacementIndex(item);
		if ( i == -1 )
			return false;
	}
	item.InventoryType = pickupReplaceArray[i].NewClass.default.InventoryType;
	item.default.InventoryType = pickupReplaceArray[i].NewClass.default.InventoryType; // pistols reset they inventory type to default
	if ( KFWeaponPickup(item) != none ) {
		KFWeaponPickup(item).Weight = class<KFWeaponPickup>(pickupReplaceArray[i].NewClass).default.Weight;
		KFWeaponPickup(item).default.Weight = class<KFWeaponPickup>(pickupReplaceArray[i].NewClass).default.Weight;
	}
	return true;
}

// returns -1, if not found
function int FindPickupReplacementIndex( Pickup item )
{
	local int i;
	
	for ( i=0; i<pickupReplaceArray.length; ++i ) {
		if ( pickupReplaceArray[i].oldClass == item.class ) 
			return i;
	}
	return -1;
}

// returns true if there are doom3 monsters in the game. 
//If there are no doom3 monsters spawned yet, then function returns false, even if server is running doom3 mutator
function bool Doom3Check()
{
	return GameRules.DoomHardcorePointsGained > 0;
}

function ServerTraveling(string URL, bool bItems)
{
	if (NextMutator != None)
    	NextMutator.ServerTraveling(URL,bItems);
    
    class'ScrnGameRules'.static.ResetGameSquads(KF, CurrentEventNum);
	class'ScrnAchievements'.static.ResetAchList();
}

// Limits placed pipebomb count to perk's capacity
function DestroyExtraPipebombs()
{
	local PipeBombProjectile P;
    local KFPlayerReplicationInfo KFPRI;
    local array<KFPlayerReplicationInfo> KFPRIArray;
    local array<byte> PipeBombCapacity;
    local int i;
		
	foreach DynamicActors(Class'PipeBombProjectile',P)
	{
		if( !P.bHidden && P.Instigator != none )
		{
            KFPRI = KFPlayerReplicationInfo(P.Instigator.PlayerReplicationInfo);
            if ( KFPRI == none || KFPRI.ClientVeteranSkill == none )
                continue;
                
            for ( i=0; i<KFPRIArray.length; ++i ) {
                if ( KFPRIArray[i] == KFPRI )
                    break;
            }
            if ( i == KFPRIArray.length ) {
                KFPRIArray[i] = KFPRI;
                PipeBombCapacity[i] = 2 * KFPRI.ClientVeteranSkill.static.AddExtraAmmoFor(KFPRI, class'PipeBombAmmo');
            }
            
            if ( PipeBombCapacity[i] > 0 )
                PipeBombCapacity[i]--;
            else
                P.bEnemyDetected = true; // blow up
		}
	}    
}


defaultproperties
{
    BonusCapGroup="ScrnBalance"
    strBonusLevel="Your effective perk bonus level is [%s]"
    strStatus="Your perk level: Visual=%v, Effective=[%b]. Server perk range is [%n..%x]."
    strStatus2="Spawn balance=%s. Weapon balance=%w. Gunslinger=%g. Alt.Burn=%a. MaxZombiesOnce=%m."
    strSrvWarning="You are using dedicated server version of ScrnBalance that shouldn't be installed on local machines! Please Obtain client version from Steam Workshop."
    strSrvWarning2="If you are getting version mismatch erros, delete KillingFloorSystemScrnBalanceSrv.u file."
    strBetaOnly="Only avaliable during Beta testing (bBeta=True)"
    
    bSpawnBalance=True
    bWeaponFix=True
    bGunslinger=True
    bAltBurnMech=True
    bReplacePickups=True
    bReplacePickupsStory=True
    bReplaceNades=True
    bShowDamages=True
    bAllowVoting=True
    bAllowBlameVote=True
    BlameVoteCoolDown=60
    bAllowKickVote=True
    bPauseTraderOnly=True
    bAllowPauseVote=True
    bAllowLockPerkVote=True
    bAllowBoringVote=True
    MaxVoteKillMonsters=5
	MaxVoteKillHP=2000
	bVoteKillCheckVisibility=True
	VoteKillPenaltyMult=5.0
	
    ReqBalanceMode=1
    BonusLevelNormalMax=3
    BonusLevelHardMax=4
    BonusLevelSuiMin=4
    BonusLevelSuiMax=6
    BonusLevelHoeMin=6
    BonusLevelHoeMax=6
    Post6RequirementScaling=1.000000
    pickupReplaceArray(0)=(oldClass=Class'KFMod.MP7MPickup',NewClass=Class'ScrnBalanceSrv.ScrnMP7MPickup')
    pickupReplaceArray(1)=(oldClass=Class'KFMod.MP5MPickup',NewClass=Class'ScrnBalanceSrv.ScrnMP5MPickup')
    pickupReplaceArray(2)=(oldClass=Class'KFMod.KrissMPickup',NewClass=Class'ScrnBalanceSrv.ScrnKrissMPickup')
    pickupReplaceArray(3)=(oldClass=Class'KFMod.M7A3MPickup',NewClass=Class'ScrnBalanceSrv.ScrnM7A3MPickup')
    pickupReplaceArray(4)=(oldClass=Class'KFMod.ShotgunPickup',NewClass=Class'ScrnBalanceSrv.ScrnShotgunPickup')
    pickupReplaceArray(5)=(oldClass=Class'KFMod.BoomStickPickup',NewClass=Class'ScrnBalanceSrv.ScrnBoomStickPickup')
    pickupReplaceArray(6)=(oldClass=Class'KFMod.NailGunPickup',NewClass=Class'ScrnBalanceSrv.ScrnNailGunPickup')
    pickupReplaceArray(7)=(oldClass=Class'KFMod.KSGPickup',NewClass=Class'ScrnBalanceSrv.ScrnKSGPickup')
    pickupReplaceArray(8)=(oldClass=Class'KFMod.BenelliPickup',NewClass=Class'ScrnBalanceSrv.ScrnBenelliPickup')
    pickupReplaceArray(9)=(oldClass=Class'KFMod.AA12Pickup',NewClass=Class'ScrnBalanceSrv.ScrnAA12Pickup')
    pickupReplaceArray(10)=(oldClass=Class'KFMod.SinglePickup',NewClass=Class'ScrnBalanceSrv.ScrnSinglePickup')
    pickupReplaceArray(11)=(oldClass=Class'KFMod.Magnum44Pickup',NewClass=Class'ScrnBalanceSrv.ScrnMagnum44Pickup')
    pickupReplaceArray(12)=(oldClass=Class'KFMod.MK23Pickup',NewClass=Class'ScrnBalanceSrv.ScrnMK23Pickup')
    pickupReplaceArray(13)=(oldClass=Class'KFMod.DeaglePickup',NewClass=Class'ScrnBalanceSrv.ScrnDeaglePickup')
    pickupReplaceArray(14)=(oldClass=Class'KFMod.WinchesterPickup',NewClass=Class'ScrnBalanceSrv.ScrnWinchesterPickup')
    pickupReplaceArray(15)=(oldClass=Class'KFMod.SPSniperPickup',NewClass=Class'ScrnBalanceSrv.ScrnSPSniperPickup')
    pickupReplaceArray(16)=(oldClass=Class'KFMod.M14EBRPickup',NewClass=Class'ScrnBalanceSrv.ScrnM14EBRPickup')
    pickupReplaceArray(17)=(oldClass=Class'KFMod.M99Pickup',NewClass=Class'ScrnBalanceSrv.ScrnM99Pickup')
    pickupReplaceArray(18)=(oldClass=Class'KFMod.BullpupPickup',NewClass=Class'ScrnBalanceSrv.ScrnBullpupPickup')
    pickupReplaceArray(19)=(oldClass=Class'KFMod.AK47Pickup',NewClass=Class'ScrnBalanceSrv.ScrnAK47Pickup')
    pickupReplaceArray(20)=(oldClass=Class'KFMod.M4Pickup',NewClass=Class'ScrnBalanceSrv.ScrnM4Pickup')
    pickupReplaceArray(21)=(oldClass=Class'KFMod.SPThompsonPickup',NewClass=Class'ScrnBalanceSrv.ScrnSPThompsonPickup')
    pickupReplaceArray(22)=(oldClass=Class'KFMod.ThompsonDrumPickup',NewClass=Class'ScrnBalanceSrv.ScrnThompsonDrumPickup')
    pickupReplaceArray(23)=(oldClass=Class'KFMod.SCARMK17Pickup',NewClass=Class'ScrnBalanceSrv.ScrnSCARMK17Pickup')
    pickupReplaceArray(24)=(oldClass=Class'KFMod.FNFAL_ACOG_Pickup',NewClass=Class'ScrnBalanceSrv.ScrnFNFAL_ACOG_Pickup')
    pickupReplaceArray(25)=(oldClass=Class'KFMod.MachetePickup',NewClass=Class'ScrnBalanceSrv.ScrnMachetePickup')
    pickupReplaceArray(26)=(oldClass=Class'KFMod.AxePickup',NewClass=Class'ScrnBalanceSrv.ScrnAxePickup')
    pickupReplaceArray(27)=(oldClass=Class'KFMod.ChainsawPickup',NewClass=Class'ScrnBalanceSrv.ScrnChainsawPickup')
    pickupReplaceArray(28)=(oldClass=Class'KFMod.KatanaPickup',NewClass=Class'ScrnBalanceSrv.ScrnKatanaPickup')
    pickupReplaceArray(29)=(oldClass=Class'KFMod.ScythePickup',NewClass=Class'ScrnBalanceSrv.ScrnScythePickup')
    pickupReplaceArray(30)=(oldClass=Class'KFMod.ClaymoreSwordPickup',NewClass=Class'ScrnBalanceSrv.ScrnClaymoreSwordPickup')
    pickupReplaceArray(31)=(oldClass=Class'KFMod.CrossbuzzsawPickup',NewClass=Class'ScrnBalanceSrv.ScrnCrossbuzzsawPickup')
    pickupReplaceArray(32)=(oldClass=Class'KFMod.MAC10Pickup',NewClass=Class'ScrnBalanceSrv.ScrnMAC10Pickup')
    pickupReplaceArray(33)=(oldClass=Class'KFMod.FlareRevolverPickup',NewClass=Class'ScrnBalanceSrv.ScrnFlareRevolverPickup')
    pickupReplaceArray(34)=(oldClass=Class'KFMod.DualFlareRevolverPickup',NewClass=Class'ScrnBalanceSrv.ScrnDualFlareRevolverPickup')
    pickupReplaceArray(35)=(oldClass=Class'KFMod.FlameThrowerPickup',NewClass=Class'ScrnBalanceSrv.ScrnFlameThrowerPickup')
    pickupReplaceArray(36)=(oldClass=Class'KFMod.HuskGunPickup',NewClass=Class'ScrnBalanceSrv.ScrnHuskGunPickup')
    pickupReplaceArray(37)=(oldClass=Class'KFMod.PipeBombPickup',NewClass=Class'ScrnBalanceSrv.ScrnPipeBombPickup')
    pickupReplaceArray(38)=(oldClass=Class'KFMod.M4203Pickup',NewClass=Class'ScrnBalanceSrv.ScrnM4203Pickup')
    pickupReplaceArray(39)=(oldClass=Class'KFMod.M32Pickup',NewClass=Class'ScrnBalanceSrv.ScrnM32Pickup')
    pickupReplaceArray(40)=(oldClass=Class'KFMod.LAWPickup',NewClass=Class'ScrnBalanceSrv.ScrnLAWPickup')
    pickupReplaceArray(41)=(oldClass=Class'KFMod.Dual44MagnumPickup',NewClass=Class'ScrnBalanceSrv.ScrnDual44MagnumPickup')
    pickupReplaceArray(42)=(oldClass=Class'KFMod.DualMK23Pickup',NewClass=Class'ScrnBalanceSrv.ScrnDualMK23Pickup')
    pickupReplaceArray(43)=(oldClass=Class'KFMod.DualDeaglePickup',NewClass=Class'ScrnBalanceSrv.ScrnDualDeaglePickup')
    pickupReplaceArray(44)=(oldClass=Class'KFMod.SyringePickup',NewClass=Class'ScrnBalanceSrv.ScrnSyringePickup')
    pickupReplaceArray(45)=(oldClass=Class'KFMod.FragPickup',NewClass=Class'ScrnBalanceSrv.ScrnFragPickup')
    pickupReplaceArray(46)=(oldClass=Class'KFMod.M79Pickup',NewClass=Class'ScrnBalanceSrv.ScrnM79Pickup')
	FragReplacementIndex=45
	
    Functions=Class'ScrnBalanceSrv.ScrnFunctions'
	
    Perks(0)=Class'ScrnBalanceSrv.ScrnVetFieldMedic'
    Perks(1)=Class'ScrnBalanceSrv.ScrnVetSupportSpec'
    Perks(2)=Class'ScrnBalanceSrv.ScrnVetSharpshooter'
    Perks(3)=Class'ScrnBalanceSrv.ScrnVetCommando'
    Perks(4)=Class'ScrnBalanceSrv.ScrnVetBerserker'
    Perks(5)=Class'ScrnBalanceSrv.ScrnVetFirebug'
    Perks(6)=Class'ScrnBalanceSrv.ScrnVetDemolitions'
    Perks(7)=Class'ScrnBalanceSrv.ScrnVetGunslinger' // old one - just for backward compatibility
    Perks(8)=Class'ScrnBalanceSrv.ScrnVetGunslinger' // new one
    Perks(9)=Class'ScrnBalanceSrv.ScrnVeterancyTypes'
    strAchEarn="%p earned an achievement: %a"
    bBroadcastAchievementEarn=True
    AchievementFlags=255
    bSaveStatsOnAchievementEarned=True
    bTradingDoorsOpen=True
    WeldingRequirementScaling=1.000000
    StalkerRequirementScaling=1.000000
    SkippedTradeTimeMult=1.0
    ServerPerksPkgName="ServerPerksMut.ServerPerksMut"
    bReplaceHUD=True
    bReplaceScoreBoard=True
    bBroadcastPickups=True
    BroadcastPickupText="%p picked up %o's %w ($%$)."    
    bAllowWeaponLock=True
    bAutoKickOffPerkPlayers=True
    strAutoKickOffPerk="You have been auto kicked from the server for playing without a perk. Type RECONNECT in the console to join the server again and choose a perk."
    strVersion="v%m.%n"

	
    CustomEvents(0)=(EventNum=100,MonstersCollection="ScrnBalanceSrv.Doom3MonstersCollection",ServerPackages=("ScrnDoom3KF"))
	
    bLeaveCashOnDisconnect=True
	StartCashNormal=250
	StartCashHard=250
	StartCashSui=200
	StartCashHoE=200
	MinRespawnCashNormal=200
	MinRespawnCashHard=200
	MinRespawnCashSui=150
	MinRespawnCashHoE=100	
	TraderTimeNormal=60
	TraderTimeHard=60
	TraderTimeSui=60
	TraderTimeHoE=60
	
	SpawnInventory(0)="0:ScrnBalanceSrv.ScrnCombatVestPickup:5-255:100"
	SpawnInventory(1)="0:ScrnBalanceSrv.ScrnMP7MPickup:6-255:200+20:157"
	SpawnInventory(2)="1:ScrnBalanceSrv.ScrnShotgunPickup:5:24:150"
	SpawnInventory(3)="1:ScrnBalanceSrv.ScrnBoomStickPickup:6-255:24+6:225"
	SpawnInventory(4)="2:ScrnBalanceSrv.ScrnWinchesterPickup:5:40:150"
	SpawnInventory(5)="2:KFMod.CrossbowPickup:6-255:12+3:225"
	SpawnInventory(6)="3:ScrnBalanceSrv.ScrnBullpupPickup:5:200:150"
	SpawnInventory(7)="3:ScrnBalanceSrv.ScrnAK47Pickup:6-255:150+30:225"
	SpawnInventory(8)="4:ScrnBalanceSrv.ScrnAxePickup:5::150"
	SpawnInventory(9)="4:ScrnBalanceSrv.ScrnChainsawPickup:6-255:500+50:225"
	SpawnInventory(10)="5:ScrnBalanceSrv.ScrnMAC10Pickup:5:200:150"
	SpawnInventory(11)="5:ScrnBalanceSrv.ScrnFlameThrowerPickup:6-255:320+80:225"
	SpawnInventory(12)="6:ScrnBalanceSrv.ScrnFragPickup:5:10"
	SpawnInventory(13)="6:ScrnBalanceSrv.ScrnM79Pickup:6-255:12+2:225"
	SpawnInventory(14)="8:ScrnBalanceSrv.ScrnDualiesPickup:5:150:150"
	SpawnInventory(15)="8:ScrnBalanceSrv.ScrnDual44MagnumPickup:6-255:66+12:225"
    
    ColorTags(0)=(T="^0",R=1,G=1,B=1)
    ColorTags(1)=(T="^1",R=200,G=1,B=1)
    ColorTags(2)=(T="^2",R=1,G=200,B=1)
    ColorTags(3)=(T="^3",R=200,G=200,B=1)
    ColorTags(4)=(T="^4",R=1,G=1,B=255)
    ColorTags(5)=(T="^5",R=1,G=255,B=255)
    ColorTags(6)=(T="^6",R=200,G=1,B=200)
    ColorTags(7)=(T="^7",R=200,G=200,B=200)
    ColorTags(8)=(T="^8",R=244,G=237,B=205)
    ColorTags(9)=(T="^9",R=128,G=128,B=128)    
    
    Post6ZedSpawnInc=0.25
    Post6AmmoSpawnInc=0.20
    AmmoBoxMesh=StaticMesh'kf_generic_sm.pickups.Metal_Ammo_Box'
    AmmoBoxDrawScale=1.000000
    AmmoBoxDrawScale3D=(X=1.000000,Y=1.000000,Z=1.000000)
    bAlterWaveSize=true
    Post6ZedsPerPlayer=0.40    
    MaxWaveSize=800
    MaxZombiesOnce=48
    FakedPlayers=1
    GameStartCountDown=12
    SharpProgMinDmg=1000
    bCloserZedSpawns=True
    bServerInfoVeterancy=True
    bScrnClientPerkRepLink=True

    bAddToServerPackages=True
    bAlwaysRelevant=True
    bOnlyDirtyReplication=False
    RemoteRole=ROLE_SimulatedProxy
    bNetNotify=True
    
    GroupName="KF-Scrn"

    FriendlyName="The ScrN Balance Server"
    Description="This Mutator must be used only on servers. Clients should use workshop version"

    // FriendlyName="Total Game Balance + Gunslinger Perk [ScrN]"
    // Description="Balances perk levels, weapons and money. Fixes bugs, issues and exploits. Brings new Gunslinger perk and server-side achievements. Supports workshop weapons."
}