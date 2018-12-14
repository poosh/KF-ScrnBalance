/*****************************************************************************
 * ScrN Total Game Balance
 * @author [ScrN]PooSH, contact via steam: http://steamcommunity.com/id/scrn-poosh/
 * Copyright (c) 2012-2018 PU Developing IK, All Rights Reserved.
 *****************************************************************************/

class ScrnBalance extends Mutator
    Config(ScrnBalanceSrv);

#exec OBJ LOAD FILE=ScrnAnims.ukx
#exec OBJ LOAD FILE=ScrnTex.utx
#exec OBJ LOAD FILE=ScrnAch_T.utx


const VERSION = 96106;

var ScrnBalance Mut; // pointer to self to use in static functions, i.e class'ScrnBalance'.default.Mut

var const string BonusCapGroup;

var localized string strBonusLevel;
var localized string strVersion;
var localized string strStatus, strStatus2;
var localized string strSrvWarning, strSrvWarning2;
var localized string strBetaOnly;

// SRVFLAGS
var transient int SrvFlags; // used for network replication of the values below
var globalconfig bool bSpawn0, bNoStartCashToss, bMedicRewardFromTeam;
var globalconfig bool bAltBurnMech, bDoubleDoT;
var globalconfig bool bReplaceNades, bShieldWeight, bHardcore, bBeta;
var globalconfig bool bShowDamages, bManualReload, bForceManualReload, bAllowWeaponLock;
var globalconfig bool bNoPerkChanges, bPerkChangeBoss, bPerkChangeDead, b10Stars;
VAR globalconfig bool bTraderSpeedBoost;
// END OF SRVFLAGS
var transient byte HardcoreLevel; // set from ScrnGameRules. Used for replication purposes only.

var deprecated byte ReqBalanceMode;
var transient byte SrvReqBalanceMode;

var globalconfig int ForcedMaxPlayers;

var globalconfig int
    BonusLevelNormalMax
    , BonusLevelHardMin, BonusLevelHardMax
    , BonusLevelSuiMin, BonusLevelSuiMax
    , BonusLevelHoeMin, BonusLevelHoeMax;
var globalconfig float Post6RequirementScaling, WeldingRequirementScaling, StalkerRequirementScaling;


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
var globalconfig bool bReplacePickups, bReplacePickupsStory;

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
var globalconfig array<string> PerkedWeapons, CustomPerks;
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

// v9.05: replaced ammo spawn behavior.
// Now ammo boxes are spawned only once per wave (at the beginning).
// When picked up, another box will spawn somewhere else on the map (after some cooldown time).
// When wave is near the end (TotalMaxMonsters == 0 and NumMonsters < 10), ammo box count is lowered
// 5 times.
var transient byte PickupSetupMonsters;
var transient bool bPickupSetupReduced;

var ScrnMapInfo MapInfo;
var ScrnGameRules GameRules;
var ScrnSrvReplInfo SrvInfo;

var localized string strAchEarn;
var globalconfig bool bBroadcastAchievementEarn; //tell other players that somebody earned an achievement (excluding map achs)
var globalconfig int AchievementFlags;
var transient int SrvAchievementFlags; // used for network replication
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
const ACH_TOURNEY    = 0x1000;


var globalconfig bool bSaveStatsOnAchievementEarned; //save stats to serverpeprks database every time an achievement is earned
var transient bool bNeedToSaveStats;
var transient float NextStatSaveTime;

var protected bool bTradingDoorsOpen; // used to check wave start / end
var protected transient byte CurWave; // used to check wave start / end

var ScrnCustomWeaponLink CustomWeaponLink;

var transient float FirstTickTime;
var transient bool bTickExecuted;
var transient bool bInitReplicationReceived;

var Mutator ServerPerksMut;
var transient bool bAllowAlwaysPerkChanges; // value replicated from ServerPerksMut

var globalconfig bool bAllowVoting;
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
var globalconfig byte MinVoteFF, MaxVoteFF;
var globalconfig byte MinVoteDifficulty;

var ScrnBalancePersistence Persistence;

var globalconfig bool bDynamicLevelCap;
var int OriginalMaxLevel;

var globalconfig string ServerPerksPkgName; // if user didn't added SP mut before ScrnBalance - do it for him!
var globalconfig array<string> AutoLoadMutators;

var globalconfig bool bReplaceHUD, bReplaceScoreBoard;

var globalconfig float Post6ZedSpawnInc, Post6AmmoSpawnInc;
var globalconfig float Post6ZedsPerPlayer;
var globalconfig bool bAlterWaveSize;
var globalconfig int MaxWaveSize;

var globalconfig int MaxZombiesOnce;

var globalconfig float EndGameStatBonus;
var globalconfig float FirstStatBonusMult;
var globalconfig bool  bStatBonusUsesHL;
var globalconfig int  StatBonusMinHL;

var globalconfig int SharpProgMinDmg; // if headshot damage dealth with Sharpshooter's weapon exceeds this, then SS gets +1 to perk progression

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

var globalconfig bool bNoRequiredEquipment;
var globalconfig bool bUseExpLevelForSpawnInventory;
var globalconfig array<string> SpawnInventory;

var globalconfig int StartCashNormal, StartCashHard, StartCashSui, StartCashHoE;
var globalconfig int MinRespawnCashNormal, MinRespawnCashHard, MinRespawnCashSui, MinRespawnCashHoE;
var globalconfig int TraderTimeNormal, TraderTimeHard, TraderTimeSui, TraderTimeHoE;
var globalconfig bool bLeaveCashOnDisconnect, bPlayerZEDTime;

struct SColorTag {
    var string T;
    var byte R, G, B;
};
var array<SColorTag> ColorTags;
var globalconfig string ColoredServerName;

var float OriginalWaveSpawnPeriod;
var globalconfig float MinZedSpawnPeriod;
var globalconfig bool bSpawnRateFix;
var globalconfig bool bServerInfoVeterancy;

var transient array<KFUseTrigger> DoorKeys;
var transient array<KFUseTrigger> DoubleDoorKeys; // keys with at least 2 doors

var StaticMesh          AmmoBoxMesh;
var float               AmmoBoxDrawScale;
var vector              AmmoBoxDrawScale3D;

struct SSpecialPlayers {
    var int SteamID32;
    var string AvatarRef, ClanIconRef, PreNameIconRef, PostNameIconRef;
    var Material Avatar, ClanIcon, PreNameIcon, PostNameIcon;
    var Color PrefixIconColor, PostfixIconColor;
    var int Playoffs, TourneyWon;
};
var const private array<SSpecialPlayers> HighlyDecorated;
var globalconfig string MySteamID64;

enum ECustomLockType
{
    LOCK_Level,
    LOCK_Ach,
    LOCK_AchGroup
};

var name NameOfString; // used in StringToName()

struct SDLCLock {
    var String Item;
    var byte Group;
    var ECustomLockType Type;
    var name ID;
    var byte Value;

    // non-config stuff
    var transient class<Pickup> PickupClass;
};
var globalconfig array<SDLCLock> DLCLocks; // replicated via ScrnClientPerkRepLink
var globalconfig bool bUseDLCLocks,bUseDLCLevelLocks;
var protected transient int LockCount;
var globalconfig bool bBuyPerkedWeaponsOnly, bPickPerkedWeaponsOnly;

struct SNameValuePair {
    var name ID;
    var int Value;
};

var globalconfig bool bFixMusic;

var globalconfig bool bRespawnDoors;

var transient bool bTeamsLocked; // Set by ScrnGameType. Used for replication purposes.
var globalconfig float LockTeamMinWave, LockTeamAutoWave;
var globalconfig bool bForceSteamNames;

var globalconfig bool bLogObjectsAtMapStart, bLogObjectsAtMapEnd;

// MutateCommands must be in UPPERCASE and sorted
var const array<string> MutateCommands;
enum EMutateCommand
{
    MUTATE_ACCURACY,
    MUTATE_CHECK,
    MUTATE_CMDLINE,
    MUTATE_DEBUGGAME,
    MUTATE_DEBUGPICKUPS,
    MUTATE_DEBUGSPI,
    MUTATE_ENEMIES,
    MUTATE_GIMMECOOKIES,
    MUTATE_HELP,
    MUTATE_HL,
    MUTATE_LEVEL,
    MUTATE_MAPDIFF,
    MUTATE_MAPZEDS,
    MUTATE_MUTLIST,
    MUTATE_PERKSTATS,
    MUTATE_PLAYERLIST,
    MUTATE_STATUS,
    MUTATE_VERSION,
    MUTATE_ZED,
    MUTATE_ZEDLIST
};

var globalconfig bool bScrnWaves;

// TSC stuff
var globalconfig bool bNoTeamSkins;
// SrvTourneyMode should be used for informative purposes only.
// All real checks must be done server-side only to prevent cheating.
var transient byte SrvTourneyMode;
// END OF TSC STUFF

replication
{
    reliable if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        SrvMinLevel, SrvMaxLevel, HardcoreLevel, bTeamsLocked;

        // flags to replicate config variables
    reliable if ( bNetInitial && Role == ROLE_Authority )
        SrvFlags, SrvAchievementFlags, SrvReqBalanceMode;

    // non-config vars and configs vars which seem to replicate fine
    reliable if ( bNetInitial && Role == ROLE_Authority )
        CustomWeaponLink, SrvTourneyMode, bTSCGame,
        Post6RequirementScaling, WeldingRequirementScaling, StalkerRequirementScaling;

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
    default.Mut = self;
    class'ScrnBalance'.default.Mut = self;
    bStoryMode = KF_StoryGRI(Level.GRI) != none;
    LoadReplicationData();

    LocalPlayer = ScrnPlayerController(Level.GetLocalPlayerController());
    if ( LocalPlayer != none && LocalPlayer.Mut == none ) {
        LocalPlayer.Mut = self;
        LocalPlayer.LoadMutSettings();
    }

    InitSettings();
}


// v8: no more using default settings
// use class'ScrnBalance'.default.Mut.<variable> instead of class'ScrnBalance'.default.<variable>
/*
simulated function ClientInitStaticSettings(class<ScrnBalance> MyBalanceClass)
{
}
*/

// client & server side
simulated function InitSettings()
{
    ApplySpawnBalance();
    ApplyWeaponFix();

    class'ScrnVetSupportSpec'.default.progressArray1[0]=1000.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[1]=2000.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[2]=7000.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[3]=33500.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[4]=120000.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[5]=250000.0 * WeldingRequirementScaling;
    class'ScrnVetSupportSpec'.default.progressArray1[6]=370000.0 * WeldingRequirementScaling;

    class'ScrnVetCommando'.default.progressArray0[0]=10.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[1]=30.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[2]=100.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[3]=325.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[4]=1200.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[5]=2400.0 * StalkerRequirementScaling;
    class'ScrnVetCommando'.default.progressArray0[6]=3600.0 * StalkerRequirementScaling;

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

    class'KFMod.CrossbowArrow'.default.DamageRadius = 0; // isn't used anywhere. Set to 0 to fix description

    // Achievements
    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);
    default.bUseAchievements = bUseAchievements;

    default.bStoryMode = bStoryMode;
    default.bTSCGame = bTSCGame;

    // fixes critical bug:
    // Assertion failed: inst->KPhysRootIndex != INDEX_NONE && inst->KPhysLastIndex != INDEX_NONE [File:.\KSkeletal.cpp] [Line: 595]
    class'FellLava'.default.bSkeletize = false;

    // Fix missing textures
    class'Welder'.default.TraderInfoTexture = texture(class'Welder'.default.SelectedHudImage);
    class'Syringe'.default.TraderInfoTexture = texture(class'Syringe'.default.SelectedHudImage);

    EventZedNames();

    bInitialized = true;
}

simulated function EventZedNames()
{
  class'KFChar.ZombieClot_CIRCUS'.default.MenuName = "Strange Little Clot";
  class'KFChar.ZombieBloat_CIRCUS'.default.MenuName = "Pukey the Clown";
  class'KFChar.ZombieStalker_CIRCUS'.default.MenuName = "Assistant";
  class'KFChar.ZombieCrawler_CIRCUS'.default.MenuName = "Two-Head Girl";
  class'KFChar.ZombieGorefast_CIRCUS'.default.MenuName = "Sword Polisher";
  class'KFChar.ZombieHusk_CIRCUS'.default.MenuName = "Mecha-Man";
  class'KFChar.ZombieSiren_CIRCUS'.default.MenuName = "Bearded Beauty";
  class'KFChar.ZombieScrake_CIRCUS'.default.MenuName = "Man Monkey";
  class'KFChar.ZombieFleshpound_CIRCUS'.default.MenuName = "Flesh Clown";
  class'KFChar.ZombieBoss_CIRCUS'.default.MenuName = "Ring Leader";

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
    log("["$Level.TimeSeconds$"s]" @ s, 'ScrnBalance');
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
    local String msg;
    local int v;
    local byte major, minor, patch;

    msg = default.strVersion;
    v = VERSION;
    // for some reason, UnrealScript has operator % declared only for float not for int.
    // So we can't use % here do to precision
    major = v / 10000; v -= major * 10000;
    minor = v / 100;   v -= minor * 100;
    patch = v;

    ReplaceText(msg, "%m", string(major));
    ReplaceText(msg, "%n", class'ScrnFunctions'.static.LPad(minor, 2, "0"));
    ReplaceText(msg, "%p", string(patch));

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
        log(Msg, 'ScrnBalance');
        MsgType = 'Log';
    }

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = PlayerController(P);
        if ( Player != none ) {
            Player.ClientMessage(Msg, MsgType);
        }
    }
}

function SendFriendlyFireWarning(PlayerController Player)
{
    if ( !bTSCGame )
        Player.ClientMessage(ColorString("FRIENDLY FIRE " $int(KF.FriendlyFireScale*100)$"% !!!", 255, 127, 1));
}


// copy-pasted from ScrnPlayerController for easy access
static final function string ColorString(string s, byte R, byte G, byte B)
{
    return chr(27)$chr(max(R,1))$chr(max(G,1))$chr(max(B,1))$s;
}

static final function string ColorStringC(string s, color c)
{
    return chr(27)$chr(max(c.R,1))$chr(max(c.G,1))$chr(max(c.B,1))$s;
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

simulated function string ParseColorTags(string ColoredText, optional PlayerReplicationInfo PRI)
{
    local int i;
    local string s;

    s = ColoredText;
    if ( PRI != none && PRI.Team != none )
        ReplaceText(s, "^t", ColorStringC("", class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex]));
    else
        ReplaceText(s, "^t", "");

    if ( KFPlayerReplicationInfo(PRI) != none )
        ReplaceText(s, "^p", ColorStringC("", class'ScrnHUD'.static.PerkColor(KFPlayerReplicationInfo(PRI).ClientVeteranSkillLevel)));
    else
        ReplaceText(s, "^p", "");


    for ( i=0; i<ColorTags.Length; ++i ) {
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
    ReplaceText(s, "^p", "");
    ReplaceText(s, "^t", "");
    for ( i=0; i<ColorTags.Length; ++i ) {
        ReplaceText(s, ColorTags[i].T, "");
    }

    return s;
}

simulated function string ColoredPlayerName(PlayerReplicationInfo PRI)
{
    if ( PRI == none )
        return "";

    return ParseColorTags(PRI.PlayerName, PRI);
}

function StolenWeapon(Pawn NewOwner, KFWeaponPickup WP)
{
    local string str;

    str = BroadcastPickupText;
    ReplaceText(str, "%p", ColorString(ParseColorTags(NewOwner.GetHumanReadableName(), NewOwner.PlayerReplicationInfo), 192, 1, 1) $ ColorString("", 192, 192, 192));
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
function SetupPickups(optional bool bReduceAmount, optional bool bBoostAmount)
{
    local float W, A; //chance of spawning weapon / ammo box
    local bool bSpawned;
    local int i;

    // randomize remaining monster count, when pickups are reset to avoid players exploiting this
    // knowledge
    PickupSetupMonsters = 10 + rand(10);
    bPickupSetupReduced = bReduceAmount;

    // Except the beginner, where all pickups are still spawned
    if ( KF.GameDifficulty < 2 ) {
        for ( i = 0; i < KF.WeaponPickups.Length ; i++ )
            KF.WeaponPickups[i].EnableMe();
        for ( i = 0; i < KF.AmmoPickups.Length ; i++ )
            KF.AmmoPickups[i].GotoState('Pickup');
        return;
    }

    // Randomize Available Ammo Pickups
    if ( bReduceAmount ) {
        W = 0.10;
        A = 0.10;
    }
    else if ( bBoostAmount ) {
        W = 0.50;
        A = 0.70;
    }
    else if ( KF.GameDifficulty >= 5.0 ) {
        // Suicidal and Hell on Earth
        W = 0.15;
        A = 0.35;
    }
    else if ( KF.GameDifficulty >= 4.0 ) {
        // Hard
        W = 0.25;
        A = 0.50;
    }
    else {
        // Normal
        W = 0.35;
        A = 0.50;
    }

    if ( KF.NumPlayers > 6 ) {
        A *= 1.0 + float(KF.NumPlayers - 6)*Post6AmmoSpawnInc;
    }

    if ( KF.WeaponPickups.Length > 0 ) {
        for ( i = 0; i < KF.WeaponPickups.Length ; i++ )
        {
            if ( frand() < W ) {
                if ( !KF.WeaponPickups[i].bIsEnabledNow )
                    KF.WeaponPickups[i].EnableMe();
                bSpawned = true;
            }
            else if ( KF.WeaponPickups[i].bIsEnabledNow )
                KF.WeaponPickups[i].DisableMe();
        }
        if ( !bSpawned )
            KF.WeaponPickups[rand(KF.WeaponPickups.Length)].EnableMe();
    }

    AdjustAmmoBoxCount(ceil(A * KF.AmmoPickups.Length));
}

function AdjustAmmoBoxCount(int DesiredAmmoBoxCount)
{
    local int i;
    local array<KFAmmoPickup> AvailableAmmoBoxes;
    local int CurrentAmmoBoxCount;

    for ( i = 0; i < KF.AmmoPickups.Length ; i++ ) {
        if ( !KF.AmmoPickups[i].bSleeping )
            ++CurrentAmmoBoxCount;
    }

    if ( CurrentAmmoBoxCount < DesiredAmmoBoxCount ) {
        // not enough ammo on the map - spawn more
        for ( i = 0; i < KF.AmmoPickups.Length ; i++ ) {
            if ( KF.AmmoPickups[i].bSleeping )
                AvailableAmmoBoxes[AvailableAmmoBoxes.Length] = KF.AmmoPickups[i];
        }
        while ( CurrentAmmoBoxCount < DesiredAmmoBoxCount && AvailableAmmoBoxes.Length > 0 ) {
            i = rand(AvailableAmmoBoxes.Length);
            AvailableAmmoBoxes[i].GotoState('Pickup');
            AvailableAmmoBoxes.remove(i, 1);
            ++CurrentAmmoBoxCount;
        }
    }
    else if ( CurrentAmmoBoxCount > DesiredAmmoBoxCount ) {
        // too many ammo boxes - remove those which are not seen by players
        for ( i = 0; i < KF.AmmoPickups.Length ; i++ ) {
            if ( !KF.AmmoPickups[i].bSleeping && !KF.AmmoPickups[i].PlayerCanSeeMe() )
                AvailableAmmoBoxes[AvailableAmmoBoxes.Length] = KF.AmmoPickups[i];
        }
        while ( CurrentAmmoBoxCount > DesiredAmmoBoxCount && AvailableAmmoBoxes.Length > 0 ) {
            i = rand(AvailableAmmoBoxes.Length);
            AvailableAmmoBoxes[i].GotoState('Sleeping', 'Begin');
            AvailableAmmoBoxes.remove(i, 1);
            --CurrentAmmoBoxCount;
        }
    }

    if ( ScrnGT != none ) {
        ScrnGT.DesiredAmmoBoxCount = DesiredAmmoBoxCount;
    }
}


function MessagePickups(PlayerController Sender)
{
    local int i, a, w;
    local String msg;

    a = KF.AmmoPickups.length;
    for ( i = 0; i < KF.AmmoPickups.length; ++i ) {
        if ( KF.AmmoPickups[i].bSleeping )
            --a;
    }

    w = KF.WeaponPickups.length;
    for ( i = 0; i < KF.WeaponPickups.length; ++i ) {
        if ( !KF.WeaponPickups[i].bIsEnabledNow )
            --w;
    }

    msg = "Ammo boxes Spawned/Total: "  $ a $ "/" $ KF.AmmoPickups.length;
    if ( ScrnGT != none ) {
        msg $= "; Current/Desired: " $ ScrnGT.CurrentAmmoBoxCount $ "/" $ ScrnGT.DesiredAmmoBoxCount;
        msg $= "; In queue: " $ ScrnGT.SleepingAmmo.length;
    }
    msg $= ".  Weapons Spawned/Total: " $ w $ "/" $ KF.WeaponPickups.length;
    Sender.ClientMessage(msg);
}

function ForceMaxPlayers()
{
    if ( ForcedMaxPlayers > 0 && ForcedMaxPlayers != Level.Game.MaxPlayers ) {
        Log("Forcing server max players from " $ Level.Game.MaxPlayers $ " to " $ ForcedMaxPlayers,'ScrnBalance');
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
            ScrnPlayer.ClientMessage(ColorString(s, 1, 150, 255));
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
        log("ServerPerksMut not found!", 'ScrnBalance');
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
        // v8.18 - do nothing, Serverperks will save game itself
        // GotoState('StatsSaving');
        // goto EndGameTracker state again to force save perks
        // doing so will increment win/loose counter extra time - need to contact Marco about this
    }
    else {
        // adjust variables of ServerPerksMut to force saving
        ServerPerksMut.SetPropertyText("WaveCounter", "100");
        ServerPerksMut.SetPropertyText("LastSavedWave", "-1");
    }
}

/*
state StatsSaving
{
Begin:
    log("Saving stats...", 'ScrnBalance');
    ServerPerksMut.GotoState('');
    sleep(1.0);
    if ( ServerPerksMut.IsInState('EndGameTracker') ) {
        log("Can't save stats!", 'ScrnBalance');
    }
    else {
        ServerPerksMut.GotoState('EndGameTracker');
    }
    GotoState('');
}
*/

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
    if ( bStoryMode ) {
        KF.bWaveInProgress = !KFStoryGameInfo(KF).IsTraderTime();
        KFGameReplicationInfo(Level.GRI).bWaveInProgress = KF.bWaveInProgress;
    }

    // check for wave start/end
    if ( bTradingDoorsOpen != KF.bTradingDoorsOpen )
    {
        bTradingDoorsOpen = KF.bTradingDoorsOpen;
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

            DestroyExtraPipebombs();

            // call SetupPickups only when playing non-ScrnGameType mode.
            // ScrnGameType automatically calls SetupPickups() during wave begin.
            if ( ScrnGT == none && !bStoryMode )
                SetupPickups(false);
        }

        if ( bDynamicLevelCap )
            DynamicLevelCap();
    }

    if ( !bStoryMode ) {
        CheckDoors();

        if ( !bPickupSetupReduced && KF.TotalMaxMonsters <= 0 && KF.NumMonsters < PickupSetupMonsters )
            SetupPickups(true);
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

function FixMusic()
{
    if ( KF.MapSongHandler == none )
        KF.MapSongHandler = spawn(class'ScrnMusicTrigger');
    // Allow L.D. to set boss battle song.
    // Don't use Dirge music as boss battle, because default KF_Abandon better.
    if ( left(KF.MonsterCollection.default.EndGameBossClass,
            InStr(KF.MonsterCollection.default.EndGameBossClass,".")) ~= "ScrnDoom3KF" )
        KF.BossBattleSong = "EGT-SignOfEvil"; // try this. If client doesn't have that song, then KF_Abandon will be played
    else if ( KF.MapSongHandler.WaveBasedSongs.Length > 10 && KF.MapSongHandler.WaveBasedSongs[10].CombatSong != ""
            &&  !(left(KF.MapSongHandler.WaveBasedSongs[10].CombatSong, 5) ~= "Dirge") )
        KF.BossBattleSong = KF.MapSongHandler.WaveBasedSongs[10].CombatSong;
}

simulated function Tick( float DeltaTime )
{
    if ( !bTickExecuted ) {
        bTickExecuted = true;
        FirstTickTime = Level.TimeSeconds;
    }

    if ( Role == ROLE_Authority ) {
        OriginalWaveSpawnPeriod = KF.KFLRules.WaveSpawnPeriod;
        if ( OriginalWaveSpawnPeriod < MinZedSpawnPeriod ) {
            OriginalWaveSpawnPeriod = MinZedSpawnPeriod;
            KF.KFLRules.WaveSpawnPeriod = MinZedSpawnPeriod;
        }
        ForceMaxPlayers();
        if ( !bStoryMode ) {
            if ( ScrnGT != none ) {
                ScrnGT.CheckZedSpawnList();
            }
            InitDoors();
            SetStartCash();
            if ( bFixMusic )
                FixMusic();
        }
        if ( bTSCGame ) {
            Level.GRI.bNoTeamSkins = bNoTeamSkins && !ScrnGT.IsTourney();
        }
        if ( ColoredServerName != "" ) {
            Level.GRI.ServerName = ParseColorTags(ColoredServerName);
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
        if ( C.PlayerReplicationInfo != none ) {
            if ( ScrnGT != none && PlayerController(C) != none )
                ScrnGT.GiveStartingCash(PlayerController(C));
            else
                C.PlayerReplicationInfo.Score = KF.StartingCash;
        }
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

/** Splits long message on short ones before sending it to client.
 *  @param   Sender     Player, who will receive message(-s).
 *  @param   S          String to send.
 *  @param   MaxLen     Max length of one string. Default: 80. If S is longer than this value,
 *                      then it will be splitted on serveral messages.
 *  @param  Divider     Character to be used as divider. Default: Space. String is splitted
 *                      at last divder's position before MaxLen is reached.
 */
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

        if ( part != "" && len(part) + pos + 1 > MaxLen) {
            Sender.ClientMessage(part);
            part = "";
        }
        part $= Left(S, pos + 1);
        S = Mid(S, pos+1);
    }

    part $= S;
    if ( part != "" )
        Sender.ClientMessage(part);
}


function bool CheckAdmin(PlayerController Sender)
{
    if ( (Sender.PlayerReplicationInfo != none && Sender.PlayerReplicationInfo.bAdmin)
            || Level.NetMode == NM_Standalone || Level.NetMode == NM_ListenServer )
        return true;

    Sender.ClientMessage("Requires ADMIN priviledges");
    return false;
}

function bool CheckScrnGT(PlayerController Sender)
{
    if ( ScrnGT != none )
        return true;

    Sender.ClientMessage("Avaliable in ScrnGameType only!");
    return false;
}

function bool CheckNotTourney(PlayerController Sender)
{
    if ( ScrnGT == none || !ScrnGT.IsTourney() )
        return true;

    Sender.ClientMessage("Not Available in TOURNEY mode");
    return false;
}

function Mutate(string MutateString, PlayerController Sender)
{
    local string Value;
    local int cmd;

    if ( MutateString == "" )
        return;

    super.Mutate(MutateString, Sender);

    Divide(MutateString, " ", MutateString, Value);
    MutateString = caps(MutateString);
    cmd = BinarySearchStr(MutateCommands, MutateString);
    if ( cmd == -1 )
        return; //unknown command

    switch ( EMutateCommand(cmd) ) {
        case MUTATE_ACCURACY:
            SendAccuracy(Sender);
            break;
        case MUTATE_CHECK:
            Sender.ClientMessage(FriendlyName);
            break;
        case MUTATE_CMDLINE:
            if ( CheckAdmin(Sender) && CheckScrnGT(Sender) )
                LongMessage(Sender, ScrnGT.GetCmdLine(), 80, "?");
            break;
        case MUTATE_DEBUGGAME:
            if ( CheckAdmin(Sender) )
                Sender.ClientMessage("Game=" $ KF.class.name
                    @ "EventNum=" $ CurrentEventNum
                    @ "MonsterCollection=" $ KF.MonsterCollection
                    @ "Boss=" $ KF.MonsterCollection.default.EndGameBossClass);
            break;
        case MUTATE_DEBUGPICKUPS:
            MessagePickups(Sender);
            break;
        case MUTATE_DEBUGSPI:
            GameRules.DebugSPI(Sender);
            break;
        case MUTATE_ENEMIES:
            if ( CheckAdmin(Sender) )
                MsgEnemies(Sender);
            break;
        case MUTATE_GIMMECOOKIES:
            XPBoost(Sender, 'TSCT', 6);
            break;
        case MUTATE_HELP:
            MessageMutateCommands(Sender);
            break;
        case MUTATE_HL:
            Sender.ClientMessage("Hardcore Level = " $ GameRules.HardcoreLevel);
            break;
        case MUTATE_LEVEL:
            MessageBonusLevel(Sender);
            break;
        case MUTATE_MAPDIFF:
            if ( CheckAdmin(Sender) )
                MapInfo.SetMapDifficulty(Value, Sender);
            break;
        case MUTATE_MAPZEDS:
            if ( CheckAdmin(Sender) && CheckNotTourney(Sender) ) {
                if ( MapInfo.SetMapZeds(int(Value), Sender) ) {
                    SetMaxZombiesOnce();
                    BroadcastMessage("Max zeds at once set to " $ KF.MaxZombiesOnce);
                }
            }
            break;
        case MUTATE_MUTLIST:
            Sender.ClientMessage(MutatorList());
            break;
        case MUTATE_PERKSTATS:
            MessagePerkStats(Sender);
            break;
        case MUTATE_PLAYERLIST:
            SendPlayerList(Sender);
            break;
        case MUTATE_STATUS:
            MessageStatus(Sender);
            break;
        case MUTATE_VERSION:
            MessageVersion(Sender);
            break;
        case MUTATE_ZED:
            if ( ScrnGT == none || ScrnGT.ScrnGameLength == none )
                Sender.ClientMessage("Avaliable only in ScrnGameType + bScrnWaves");
            else if ( CheckAdmin(Sender) ) {
                ScrnGT.ScrnGameLength.ZedCmd(Sender, Value);
            }
            break;
        case MUTATE_ZEDLIST:
            if ( ScrnGT == none || ScrnGT.ScrnGameLength == none )
                SendZedList(Sender);
            else
                ScrnGT.ScrnGameLength.ZedCmd(Sender, "LIST");
            break;
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

function MessageMutateCommands(PlayerController Sender)
{
    local int i;
    Sender.ClientMessage("ScrN Mutate Commands");
    Sender.ClientMessage("====================");
    for ( i = 0; i < MutateCommands.length; ++i ) {
        Sender.ClientMessage(MutateCommands[i]);
    }
}

function XPBoost(PlayerController Sender, name Achievement, byte Level)
{
    local ScrnCustomPRI ScrnPRI;
    local SRStatsBase SteamStats;
    local ScrnPlayerInfo SPI;
    local SRCustomProgress S;
    local int v;

    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(Sender.PlayerReplicationInfo);
    if ( ScrnPRI == none || !ScrnPRI.IsTourneyMember() )
        return;

    SteamStats = SRStatsBase(Sender.SteamStatsAndAchievements);
    SPI = GameRules.GetPlayerInfo(Sender);
    if ( SPI == none || SteamStats == none ) {
        Sender.ClientMessage("Player achievements are not loaded yet. Try again later.");
        return;
    }
    // ProgressAchievement() returns true if progress has been made, i.e.
    // achievement wasn't achieved before
    if ( Achievement == '' || SPI.ProgressAchievement(Achievement, 1) ) {
        SteamStats.AddDamageHealed(class'ScrnVetFieldMedic'.default.progressArray0[Level]);
        SteamStats.AddShotgunDamage(class'ScrnVetSupportSpec'.default.progressArray0[Level]);
        SteamStats.AddWeldingPoints(class'ScrnVetSupportSpec'.default.progressArray1[Level]);
        v = class'ScrnVetSharpshooter'.default.progressArray0[Level];
        while ( v-- > 0 )
            SteamStats.AddHeadshotKill(false);
        v = class'ScrnVetCommando'.default.progressArray0[Level];
        while ( v-- > 0 )
            SteamStats.AddStalkerKill();
        SteamStats.AddBullpupDamage(class'ScrnVetCommando'.default.progressArray1[Level]);
        SteamStats.AddMeleeDamage(class'ScrnVetBerserker'.default.progressArray0[Level]);
        SteamStats.AddFlameThrowerDamage(class'ScrnVetFirebug'.default.progressArray0[Level]);
        SteamStats.AddExplosivesDamage(class'ScrnVetDemolitions'.default.progressArray0[Level]);
        for ( S = SteamStats.Rep.CustomLink; S!=none; S=S.NextLink ) {
            if ( ScrnPistolKillProgress(S) != none )
                S.IncrementProgress(class'ScrnVetGunslinger'.default.progressArray0[Level]);
            else if ( ScrnPistolDamageProgress(S) != none )
                S.IncrementProgress(class'ScrnVetGunslinger'.default.progressArray1[Level]);
        }
        SaveStats(); // for ServerPerks to write stats
        // ensure that xp boost won't be multiplied by end-game bonus
        SPI.GameStartStats.bSet = false;
        SPI.BackupStats(SPI.GameStartStats);
    }
}


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
    local int i, j, k, NumZeds;
    local string str, ZedClass;

    Sender.ClientMessage("Collection: " $ KF.MonsterCollection);
    Sender.ClientMessage("Boss: " $ KF.MonsterCollection.default.EndGameBossClass);
    for ( k=0; k< KF.MonsterCollection.default.MonsterClasses.Length; ++k ) {
        Sender.ClientMessage(
            ColorString(KF.MonsterCollection.default.MonsterClasses[k].MID, 1, 100, 200)
            $ ColorString(": "$KF.MonsterCollection.default.MonsterClasses[k].MClassName, 200, 200, 200));
    }
    Sender.ClientMessage("SpecialSquads:");
    for ( i=0; i< KF.MonsterCollection.default.SpecialSquads.Length; ++i ) {
        if ( KF.MonsterCollection.default.SpecialSquads[i].ZedClass.Length > 0 ) {
            str = "";
            for( j=0; j<KF.MonsterCollection.default.SpecialSquads[i].ZedClass.Length; j++ ) {
                ZedClass = KF.MonsterCollection.default.SpecialSquads[i].ZedClass[j];
                NumZeds = KF.MonsterCollection.default.SpecialSquads[i].NumZeds[j];
                if( ZedClass != "" ) {
                    // replace zed class with MonsterID
                    for ( k=0; k< KF.MonsterCollection.default.MonsterClasses.Length; ++k ) {
                        if ( ZedClass ~= KF.MonsterCollection.default.MonsterClasses[k].MClassName ) {
                            ZedClass = ColorString(KF.MonsterCollection.default.MonsterClasses[k].MID, 1, 100, 200);
                            break;
                        }
                    }
                    if ( k == KF.MonsterCollection.default.MonsterClasses.Length )
                        ZedClass = GetItemName(ZedClass); // zed class not found in monster collection
                    str @= ColorString(NumZeds$"x", 200, 200, 200) $ GetItemName(ZedClass);
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
            @ ColorString("("$SPI.HeadshotsPerWave,1,220,1)$ColorString("/"$SPI.BodyShotsPerWave,200,200,200)$")"
            @ " Game: "$GetColoredPercent(SPI.GetAccuracyGame(), false)
            @ ColorString("("$SPI.HeadshotsPerGame,1,220,1)$ColorString("/"$SPI.BodyshotsPerGame,200,200,200)$")";
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

    PlayInfo.AddSetting(default.BonusCapGroup,"bSpawn0","Zero Cost of Initial Inventory",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bHardcore","Hardcore Mode",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickups","Replace Pickups",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickupsStory","Replace Pickups (Story)",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceNades","Replace Grenades",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShieldWeight","Armor Has Weight",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bAltBurnMech","Alternate Burning Mechanism",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShowDamages","Show Damages",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceHUD","Replace HUD",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bNoPerkChanges","No Perk Changes",1,0, "Check");

    PlayInfo.AddSetting(default.BonusCapGroup,"EventNum","Event", 0, 1, "Select", "0;Autodetect;255;Normal;1;Summer;2;Halloween;3;Xmas;254;Random",,,True);
    PlayInfo.AddSetting(default.BonusCapGroup,"bForceEvent","Force Event",1,0, "Check");

    PlayInfo.AddSetting(default.BonusCapGroup,"bUseDLCLocks","Trader Requirements",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bUseDLCLevelLocks","Perk Level Requirements",1,0, "Check");

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

        case "bHardcore":                   return "For those who still think game is too easy...";
        case "bSpawn0":                     return "All initial weapons costs nothing";
        case "bReplacePickups":             return "Replaces weapon pickups on a map with their Scrn Editon (SE) versions.";
        case "bReplacePickupsStory":        return "Replaces weapon pickups in Objective Mode with their Scrn Editon (SE) versions.";
        case "bReplaceNades":               return "Replaces hand grenades with 'coockable' ScrN version. Players can disable grenade cooking in ScrN Settings menu anyway. Disabling it here removes this ability from the server.";
        case "bShieldWeight":               return "Kevlar Vest weights 1 block instead of hand grenades. Players without vest can carry more. Automatically enables hand grenade replacing with ScrN version";
        case "bAltBurnMech":                return "Use Alternate Burning Mechanism. Shorter burning period, but higher damage at the begining. Also fixes many bugs, including Crawler Infinite Burning.";
        case "bShowDamages":                return "Allows showing damage values on the HUD. Clients will still be able to turn it off in their User.ini";
        case "bReplaceHUD":                 return "Replace heads-up display with ScrN version (recommended). Disable only if you have compatibility issues with other mods!";
        case "bNoPerkChanges":              return "Disables perk changes during the game.";

        case "EventNum":                    return "Setup KF event zeds";
        case "bForceEvent":                 return "Check it to force selected event";

        case "bUseDLCLocks":                return "If checked, then trader items may have perk level or/and achievement requirements.";
        case "bUseDLCLevelLocks":           return "Uncheck this to leave only achievement-specific trader requirements.";

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
        for ( i=0; i<ServerState.ServerInfo.Length; ++i ) {
            if ( ServerState.ServerInfo[i].Key == "Veterancy" || Left(ServerState.ServerInfo[i].Key, 9) == "SP: Perk " )
                ServerState.ServerInfo.remove(i--, 1);
        }
    }

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.insert(i, 4);

    ServerState.ServerInfo[i].Key = "ScrN Balance";
    ServerState.ServerInfo[i++].Value = GetVersionStr();

    ServerState.ServerInfo[i].Key = "Perk bonus level min";
    ServerState.ServerInfo[i++].Value = String(MinLevel);
    ServerState.ServerInfo[i].Key = "Perk bonus level max";
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
    OriginalMaxLevel = MaxLevel;

    //for the replication
    SrvMinLevel = MinLevel;
    SrvMaxLevel = MaxLevel;
}


function SetReplicationData()
{
    SrvMinLevel = MinLevel;
    SrvMaxLevel = MaxLevel;
    SrvAchievementFlags = AchievementFlags;

    SrvFlags = 0;
    // if ( bSpawnBalance )                    SrvFlags = SrvFlags | 0x00000001;
    if ( bSpawn0 )                          SrvFlags = SrvFlags | 0x00000002;
    if ( bNoStartCashToss )                 SrvFlags = SrvFlags | 0x00000004;
    if ( bMedicRewardFromTeam )             SrvFlags = SrvFlags | 0x00000008;

    // if ( bWeaponFix )                       SrvFlags = SrvFlags | 0x00000010;
    if ( bAltBurnMech )                     SrvFlags = SrvFlags | 0x00000020;
    // if ( bGunslinger )                      SrvFlags = SrvFlags | 0x00000040;
    if ( bTraderSpeedBoost )                SrvFlags = SrvFlags | 0x00000080;

    if ( bReplaceNades )                    SrvFlags = SrvFlags | 0x00000100;
    if ( bShieldWeight )                    SrvFlags = SrvFlags | 0x00000200;
    if ( bHardcore )                        SrvFlags = SrvFlags | 0x00000400;
    if ( bBeta )                            SrvFlags = SrvFlags | 0x00000800;

    if ( bShowDamages )                     SrvFlags = SrvFlags | 0x00001000;
    if ( bManualReload )                    SrvFlags = SrvFlags | 0x00002000;
    if ( bForceManualReload )               SrvFlags = SrvFlags | 0x00004000;
    if ( bAllowWeaponLock )                 SrvFlags = SrvFlags | 0x00008000;

    if ( bNoPerkChanges )                   SrvFlags = SrvFlags | 0x00010000;
    if ( bPerkChangeBoss )                  SrvFlags = SrvFlags | 0x00020000;
    if ( b10Stars )                         SrvFlags = SrvFlags | 0x00040000;
    if ( bBuyPerkedWeaponsOnly )            SrvFlags = SrvFlags | 0x00080000;
}

simulated function LoadReplicationData()
{
    if ( Role == ROLE_Authority )
        return;

    MinLevel = SrvMinLevel;
    MaxLevel = SrvMaxLevel;
    AchievementFlags = SrvAchievementFlags;

    // bSpawnBalance                      = (SrvFlags & 0x00000001) > 0;
    bSpawn0                            = (SrvFlags & 0x00000002) > 0;
    bNoStartCashToss                   = (SrvFlags & 0x00000004) > 0;
    bMedicRewardFromTeam               = (SrvFlags & 0x00000008) > 0;

    // bWeaponFix                         = (SrvFlags & 0x00000010) > 0;
    bAltBurnMech                       = (SrvFlags & 0x00000020) > 0;
    // bGunslinger                        = (SrvFlags & 0x00000040) > 0;
    bTraderSpeedBoost                  = (SrvFlags & 0x00000080) > 0;

    bReplaceNades                      = (SrvFlags & 0x00000100) > 0;
    bShieldWeight                      = (SrvFlags & 0x00000200) > 0;
    bHardcore                          = (SrvFlags & 0x00000400) > 0;
    bBeta                              = (SrvFlags & 0x00000800) > 0;

    bShowDamages                       = (SrvFlags & 0x00001000) > 0;
    bManualReload                      = (SrvFlags & 0x00002000) > 0;
    bForceManualReload                 = (SrvFlags & 0x00004000) > 0;
    bAllowWeaponLock                   = (SrvFlags & 0x00008000) > 0;

    bNoPerkChanges                     = (SrvFlags & 0x00010000) > 0;
    bPerkChangeBoss                    = (SrvFlags & 0x00020000) > 0;
    b10Stars                           = (SrvFlags & 0x00040000) > 0;
    bBuyPerkedWeaponsOnly              = (SrvFlags & 0x00080000) > 0;

    bPerkChangeDead                     = (SrvFlags & 0x00100000) > 0;
    //                                  = (SrvFlags & 0x00200000) > 0;
    //                                  = (SrvFlags & 0x00400000) > 0;
    //                                  = (SrvFlags & 0x00800000) > 0;
}

simulated function ApplySpawnBalance()
{
    // nothing left here
}

simulated function ApplyWeaponFix()
{
    class'KFMod.ZEDGun'.default.UnlockedByAchievement = -1;
    class'KFMod.ZEDGun'.default.AppID = 0;
    class'KFMod.DwarfAxe'.default.UnlockedByAchievement = -1;
    class'KFMod.DwarfAxe'.default.AppID = 0;

    // fix missing references
    class'KFMod.Shotgun'.default.HudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun_unselected";
    class'KFMod.Shotgun'.default.SelectedHudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun";
    class'KFMod.Shotgun'.default.SelectSoundRef="KF_PumpSGSnd.SG_Select";
    class'KFMod.Shotgun'.default.MeshRef="KF_Weapons_Trip.Shotgun_Trip";
    class'KFMod.Shotgun'.default.SkinRefs[0]="KF_Weapons_Trip_T.Shotguns.shotgun_cmb";
    class'KFMod.ShotgunAttachment'.default.MeshRef="KF_Weapons3rd_Trip.Shotgun_3rd";

    class'KFMod.DualDeagle'.default.HudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon_unselected";
    class'KFMod.DualDeagle'.default.SelectedHudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon";
    class'KFMod.DualDeagle'.default.SelectSoundRef="KF_HandcannonSnd.50AE_Select";
    class'KFMod.DualDeagle'.default.MeshRef="KF_Weapons_Trip.Dual50_Trip";
    class'KFMod.DualDeagle'.default.SkinRefs[0]="KF_Weapons_Trip_T.Pistols.deagle_cmb";

    class'KFMod.GoldenDualDeagle'.default.HudImageRef="KillingFloor2HUD.WeaponSelect.Gold_Dual_Deagle_unselected";
    class'KFMod.GoldenDualDeagle'.default.SelectedHudImageRef="KillingFloor2HUD.WeaponSelect.Gold_Dual_Deagle";
    class'KFMod.GoldenDualDeagle'.default.SelectSoundRef="KF_HandcannonSnd.50AE_Select";
    class'KFMod.GoldenDualDeagle'.default.MeshRef="KF_Weapons_Trip.Dual50_Trip";
    class'KFMod.GoldenDualDeagle'.default.SkinRefs[0]="KF_Weapons_Gold_T.Weapons.Gold_deagle_cmb";

    // prevent weapons from dropping on death
    class'Knife'.default.bCanThrow = bStoryMode;
    class'Syringe'.default.bCanThrow = bStoryMode;
    class'Welder'.default.bCanThrow = bStoryMode;
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

    // Load custom perks first
    MaxPerkIndex = 9;
    for( i = 0; i < CustomPerks.Length; i++ ) {
        S = CustomPerks[i];
        j = InStr(S,":");
        if ( j > 0 ) {
            PerkIndex = int(Left(S, j));
            if ( PerkIndex < 10 || PerkIndex > 255 ) {
                log("Custom Perk index must be between 10 and 255! Perk '"$S$"' ignored", 'ScrnBalance');
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
            log("Perk: '" $ S $"' loaded with index = " $ String(PerkIndex), 'ScrnBalance');
        }
        else
            log("Unable to load custom perk: '" $ S $"'.", 'ScrnBalance');
    }

    // Load weapon bonuses
    for( i=0; i < PerkedWeapons.Length; i++ ) {
        PriceStr = "";
        WeaponBonusStr = "";

        S = PerkedWeapons[i];
        j = InStr(S,":");
        if( j <= 0 ) {
            log("Illegal Custom Weapon definition: '" $ S $"'! Wrong perk index.", 'ScrnBalance');
            continue;
        }

        PerkIndex = int(Left(S, j));
        if ( PerkIndex < 0 || PerkIndex >= Perks.length || Perks[PerkIndex] == none ) {
            log("Illegal Custom Weapon definition: '" $ S $"'! Wrong perk index.", 'ScrnBalance');
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
        //log("WeaponBonusStr="$WeaponBonusStr @ "ForcePrice="$ForcePrice  , 'ScrnBalance');

        W = class<KFWeapon>(DynamicLoadObject(WeaponClassStr, Class'Class'));
        if( W == none ) {
            log("Can't load Custom Weapon: '" $ WeaponClassStr $"'!", 'ScrnBalance');
            continue;
        }

        ClientLink = spawn(class'ScrnBalanceSrv.ScrnCustomWeaponLink');
        if ( ClientLink == none ) {
            log("Can't load Client Replication Link for a Custom Weapon: '" $ W $"'!", 'ScrnBalance');
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
    local int i, j, index, k;
    local byte X;
    local string S, PickupStr, LevelStr, AmmoStr, SellStr, AchStr;
    local int PerkIndex;
    local class<ScrnVeterancyTypes> ScrnPerk;
    local class<Pickup> Pickup;
    local bool bAllPerks;
    local bool bTourney;

    bTourney = ScrnGT != none && ScrnGT.IsTourney();

    // clear old inventory left from previous map
    for ( j=0; j<Perks.length; ++j )
        if ( Perks[j] != none )
            Perks[j].default.DefaultInventory.length = 0;

    for ( i=0; i<SpawnInventory.length; ++i ) {
        bAllPerks = false;
        LevelStr = "";
        AmmoStr = "";
        SellStr = "";
        AchStr = "";
        X = 0;

        S = SpawnInventory[i];
        j = InStr(S,":");
        if( j <= 0 ) {
            log("Illegal Spawn Inventory definition: '" $ S $"'! Wrong perk index.", 'ScrnBalance');
            continue;
        }
        PickupStr = Mid(S, j+1);
        S = Left(S, j);
        j = InStr(S,"-"); // "PerkIndex-X"
        if ( j > 0 ) {
            X = int(Mid(S, j+1));
            S = Left(S, j);
        }

        if ( S == "*" ) {
            bAllPerks = true;
            PerkIndex = 0;
        }
        else
            PerkIndex = int(S);
        if ( PerkIndex < 0 || PerkIndex >= Perks.length || Perks[PerkIndex] == none ) {
            log("Illegal Spawn Inventory definition: '" $ S $"'! Wrong perk index.", 'ScrnBalance');
            continue;
        }
        ScrnPerk = Perks[PerkIndex];

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

                // Achievement
                j = InStr(SellStr,":");
                if ( j >= 0 ) {
                    AchStr = Mid(SellStr, j+1);
                    SellStr = Left(SellStr, j);
                }
            }
        }
        if ( bTourney && AchStr != "" )
            continue; // do not allow achievement-specific inventory in tournaments

        Pickup = class<Pickup>(DynamicLoadObject(PickupStr, Class'Class'));
        if( Pickup == none ) {
            log("Can't load Spawn Inventory: '" $ PickupStr $"'!", 'ScrnBalance');
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
        if ( AchStr != "" )
            ScrnPerk.default.DefaultInventory[index].Achievement = StringToName(AchStr);
        ScrnPerk.default.DefaultInventory[index].X = X;

        if ( bAllPerks ) {
            for ( j=1; j<Perks.length; ++j ) {
                if ( Perks[j] != none && Perks[j] != ScrnPerk && Perks[j] != Class'ScrnVeterancyTypes' ) {
                    k = Perks[j].default.DefaultInventory.length;
                    Perks[j].default.DefaultInventory.insert(k, 1);
                    Perks[j].default.DefaultInventory[k].PickupClass = ScrnPerk.default.DefaultInventory[index].PickupClass;
                    Perks[j].default.DefaultInventory[k].MinPerkLevel = ScrnPerk.default.DefaultInventory[index].MinPerkLevel;
                    Perks[j].default.DefaultInventory[k].MaxPerkLevel = ScrnPerk.default.DefaultInventory[index].MaxPerkLevel;
                    Perks[j].default.DefaultInventory[k].bSetAmmo = ScrnPerk.default.DefaultInventory[index].bSetAmmo;
                    Perks[j].default.DefaultInventory[k].AmmoAmount = ScrnPerk.default.DefaultInventory[index].AmmoAmount;
                    Perks[j].default.DefaultInventory[k].AmmoPerLevel = ScrnPerk.default.DefaultInventory[index].AmmoPerLevel;
                    Perks[j].default.DefaultInventory[k].SellValue = ScrnPerk.default.DefaultInventory[index].SellValue;
                    Perks[j].default.DefaultInventory[k].Achievement = ScrnPerk.default.DefaultInventory[index].Achievement;
                    Perks[j].default.DefaultInventory[k].X = ScrnPerk.default.DefaultInventory[index].X;
                }
            }
        }
    }
}

// UE2 doesn't support direct string to name typecasting
// That's why need to use the following hack
final function name StringToName(string str)
{
    SetPropertyText("NameOfString", str);
    return NameOfString;
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
    //Log("CheckReplacement: " $ String(Other), 'ScrnBalance');

    // first check classes that need to be replaced
    if ( Other.class == class'KFRandomItemSpawn' ) {
        if ( !bReplacePickups )
            return true;
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
        if ( ZombieFleshPound(Other) != none )
            KFMonster(Other).ZapThreshold = 3.75;
        else if ( KFMonster(Other).default.Health >= 1000 )
            KFMonster(Other).ZapThreshold = 1.75;

        GameRules.RegisterMonster(KFMonster(Other));
    }
    else if ( SRStatsBase(Other) != none ) {
        SetupRepLink(SRStatsBase(Other).Rep);
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
    local int i, j;

    if ( R == none )
        return;

    // replace with ScrnClientPerkRepLink
    if ( ScrnClientPerkRepLink(R) != none )
        return; // already set up

    ScrnRep = Spawn(Class'ScrnClientPerkRepLink',R.Owner);
    ScrnRep.StatObject = R.StatObject;
    ScrnRep.StatObject.Rep = ScrnRep;

    ScrnRep.ServerWebSite = R.ServerWebSite;
    ScrnRep.MinimumLevel = R.MinimumLevel;
    ScrnRep.MaximumLevel = R.MaximumLevel;
    ScrnRep.RequirementScaling = R.RequirementScaling;
    ScrnRep.CachePerks = R.CachePerks;
    // remove non-scrn perks
    for( i=0; i<ScrnRep.CachePerks.Length; ++i) {
        if ( class<ScrnVeterancyTypes>(ScrnRep.CachePerks[i].PerkClass) == none )
            ScrnRep.CachePerks.remove(i--, 1);
    }

    ScrnRep.OwnerPC = ScrnPlayerController(R.Owner);
    ScrnRep.OwnerPRI = KFPlayerReplicationInfo(ScrnRep.OwnerPC.PlayerReplicationInfo);
    log("Creating ScrnClientPerkRepLink for player " $ ScrnRep.OwnerPRI.PlayerName, 'ScrnBalance');

    R.GotoState('');
    R.Destroy();
    R = ScrnRep;

    class'ScrnAchievements'.static.InitAchievements(ScrnRep);

    if ( bUseDLCLocks && !bTSCGame && (ScrnGT == none || !ScrnGT.IsTourney()) ) {
        ScrnRep.Locks.Length = LockCount;
        for( i=0; i<DLCLocks.Length; ++i) {
            if ( DLCLocks[i].PickupClass != none
                    && (bUseDLCLevelLocks || DLCLocks[i].Type != LOCK_Level) )
            {
                ScrnRep.Locks[j].PickupClass = DLCLocks[i].PickupClass;
                ScrnRep.Locks[j].Group       = DLCLocks[i].Group;
                ScrnRep.Locks[j].Type        = DLCLocks[i].Type;
                ScrnRep.Locks[j].ID          = DLCLocks[i].ID;
                ScrnRep.Locks[j].MaxProgress = DLCLocks[i].Value;
                ++j;
            }
        }
    }

    if ( ScrnGT != none )
        ScrnGT.SetupRepLink(ScrnRep);

    // used for client replication
    if ( ScrnRep.ShopCategories.Length > 250 )
        ScrnRep.ShopCategories.Length = 250; //wtf?
    ScrnRep.TotalCategories = ScrnRep.ShopCategories.Length;
    ScrnRep.TotalWeapons = ScrnRep.ShopInventory.Length;
    ScrnRep.TotalLocks = ScrnRep.Locks.Length;
    ScrnRep.TotalChars = ScrnRep.CustomChars.Length;
}

function ForceEvent()
{
    local int i;
    local class<KFMonstersCollection> MC;

    i = MapInfo.FindMapInfo(false);
    if ( i != -1 && MapInfo.MapInfo[i].ForceEventNum > 0 )
        CurrentEventNum = MapInfo.MapInfo[i].ForceEventNum;
    else if ( EventNum == 0 )
        CurrentEventNum = int(KF.GetSpecialEventType()); // autodetect event
    else
        CurrentEventNum = EventNum;

    if ( CurrentEventNum == 254 ) {
        // 254 - random event
        CurrentEventNum = 1 + rand(4);
    }

    if (bScrnWaves) {
        return;  // all we need for ScrnWaves is to load CurrentEventNum. ScrnGameLength will handle everything else.
    }

    if ( MC == none ) {
        switch (CurrentEventNum) {
            case 0: case 4: case 255: // force regular zeds
                log("Normal zeds forced for this map", 'ScrnBalance');
                KF.MonsterCollection = class'KFMod.KFMonstersCollection';
                CurrentEventNum = 0;
                break;
            case 1:
                log("Summer zeds forced for this map", 'ScrnBalance');
                KF.MonsterCollection = class'KFMod.KFMonstersSummer';
                break;
            case 2:
                log("Halloween zeds forced for this map", 'ScrnBalance');
                KF.MonsterCollection = class'KFMod.KFMonstersHalloween';
                break;
            case 3:
                log("Xmas zeds forced for this map", 'ScrnBalance');
                KF.MonsterCollection = class'KFMod.KFMonstersXmas';
                break;
            default:
                log("Unknown Event Number: "$CurrentEventNum, 'ScrnBalance');
                CurrentEventNum = EventNum;
                return;
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
            log("SetupVoteSquad: Unable to load monster '"$VoteSquad[i].MonsterClass, 'ScrnBalance');
            continue;
        }

        MC.static.PreCacheAssets(Level);

        pkg = MC.outer.name;
        if ( pkg != 'KFChar' ) {
            AddToPackageMap(String(pkg));
            log(pkg $ " added to ServerPackages", 'ScrnBalance');
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

    i = MapInfo.FindMapInfo(false);
    if ( i != -1 && MapInfo.MapInfo[i].MaxZombiesOnce >= 16 )
        value = MapInfo.MapInfo[i].MaxZombiesOnce;
    else
        value = MaxZombiesOnce;

    value = clamp(value, 16, 254);
    KF.StandardMaxZombiesOnce = value;
    KF.MaxZombiesOnce = value;
    KF.MaxMonsters = Clamp(KF.TotalMaxMonsters,5,value);
}

function LogObjects()
{
    log("LIST OF LOADED OBJECTS:");
    ConsoleCommand("OBJ LIST", true);
}

function PostBeginPlay()
{
    local ScrnVotingHandlerMut VH;
    local ScrnAchHandler AchHandler;
    local int i;
    local KFGameReplicationInfo KFGRI;

    KF = KFGameType(Level.Game);
    if (KF == none) {
        Log("ERROR: Wrong GameType (requires KFGameType)", 'ScrnBalance');
        Destroy();
        return;
    }
    KFGRI = KFGameReplicationInfo(Level.Game.GameReplicationInfo);

    if ( bLogObjectsAtMapStart )
        LogObjects();

    if ( Mut != none && Mut != self )
        Mut.Destroy();
    Mut = self;
    default.Mut = self;
    class'ScrnBalance'.default.Mut = self; // in case of classes extended from ScrnBalance

    KF.MonsterCollection = KF.SpecialEventMonsterCollections[KF.GetSpecialEventType()]; // v1061 fix
    KF.bUseZEDThreatAssessment = true; // always use ScrnHumanPawn.AssessThreatTo()
    bStoryMode = KFStoryGameInfo(KF) != none;
    bTSCGame = TSCGame(KF) != none && !TSCGame(KF).bSingleTeamGame;
    ScrnGT = ScrnGameType(KF);
    if ( ScrnGT != none ) {
        ScrnGT.ScrnBalanceMut = self;
    }
    else if ( ScrnStoryGameInfo(KF) != none ) {
        ScrnStoryGameInfo(KF).ScrnBalanceMut = self;
    }
    MapInfo = Spawn(Class'ScrnBalanceSrv.ScrnMapInfo');


    if ( bForceEvent )
        ForceEvent();
    else
        CurrentEventNum = int(KF.GetSpecialEventType()); // autodetect event

    AddToPackageMap("ScrnAnims.ukx");
    AddToPackageMap("ScrnSnd.uax"); // Promoted!!!!!!!!!! :)

    if ( !bStoryMode ) {
        SetMaxZombiesOnce();
    }

    // CHECK & LOAD SERVERPERKS
    GetRidOfMut('AliensKFServerPerksMut');
    FindServerPerksMut();
    if ( ServerPerksMut == none ) {
        log("ServerPerksMut must be loaded before ScrN Balance! Loading it now...", 'ScrnBalance');
        Level.Game.AddMutator(ServerPerksPkgName, false);
        //check again
        FindServerPerksMut();
        if ( ServerPerksMut == none )
            log("Unable to spawn " $ ServerPerksPkgName, 'ScrnBalance');
    }
    bAllowAlwaysPerkChanges = ServerPerksMut.GetPropertyText("bAllowAlwaysPerkChanges") ~= "True";
    bNoPerkChanges = bNoPerkChanges && !bAllowAlwaysPerkChanges;


    if ( !ClassIsChildOf(KF.PlayerControllerClass, class'ScrnBalanceSrv.ScrnPlayerController') ) {
        KF.PlayerControllerClass = class'ScrnBalanceSrv.ScrnPlayerController';
        KF.PlayerControllerClassName = string(Class'ScrnBalanceSrv.ScrnPlayerController');
    }

    if ( bReplaceHUD )
        KF.HUDType = string(Class'ScrnBalanceSrv.ScrnHUD');

    if ( bReplaceScoreBoard )
        Level.Game.ScoreBoardType = string(Class'ScrnBalanceSrv.ScrnScoreBoard');

    KF.LoginMenuClass = string(Class'ScrnBalanceSrv.ScrnInvasionLoginMenu');

    Persistence = new class'ScrnBalancePersistence';

    if ( Persistence.Difficulty > 0 ) {
        if ( Persistence.Difficulty == 6 || Persistence.Difficulty == 8 ) {
            bHardcore = true;
            KF.GameDifficulty = Persistence.Difficulty - 1;
            log("Game difficulty: " $ string(KF.GameDifficulty) $ " + Hardcore", 'ScrnBalance');
        }
        else {
            bHardcore = false;
            KF.GameDifficulty = Persistence.Difficulty;
            log("Game difficulty: " $ string(KF.GameDifficulty), 'ScrnBalance');
        }
        KFGRI.GameDiff = KF.GameDifficulty;
        KFGRI.BaseDifficulty = KF.GameDifficulty;
    }

    SetLevels();
    SetReplicationData();
    //exec this on server side only
    ApplySpawnBalance();
    ApplyWeaponFix();

    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);
    GameRules = Spawn(Class'ScrnBalanceSrv.ScrnGameRules');
    if ( GameRules != none ) {
        GameRules.Mut = self;
        GameRules.bShowDamages = bShowDamages;
        GameRules.bUseAchievements = bUseAchievements && KF.GameDifficulty >= 2;
        if ( GameRules.bUseAchievements ) {
            // spawn achievement handlers
            AchHandler = GameRules.Spawn(Class'ScrnBalanceSrv.ScrnAchHandler');
        }

        if ( !bScrnWaves && (bResetSquadsAtStart || EventNum == 254) ) {
            GameRules.ResetGameSquads(KF, CurrentEventNum);
        }
    }
    else {
        log("Unable to spawn Game Rules!", 'ScrnBalance');
    }

    if (bAltBurnMech) {
        BurnMech = spawn(class'ScrnBalanceSrv.ScrnBurnMech');
        default.BurnMech = BurnMech;
        if ( bDoubleDoT ) {
            BurnMech.BurnPeriod = 0.5;
            BurnMech.BurnDuration = 16;
            BurnMech.BurnInCount = 4;
            if ( AchHandler != none )
                AchHandler.iDoT_Damage = 150;
        }
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
            log("Unable to spawn voting handler mutator", 'ScrnBalance');
    }

    LoadCustomWeapons();
    // proceed DLCLocks
    LockCount = 0;
    for ( i=0; i<DLCLocks.length; ++i ) {
        if ( DLCLocks[i].Item != "" )
            DLCLocks[i].PickupClass = class<Pickup>(DynamicLoadObject(DLCLocks[i].Item, Class'Class'));
        if ( DLCLocks[i].PickupClass != none && (bUseDLCLevelLocks || DLCLocks[i].Type != LOCK_Level) )
            ++LockCount;
    }
    InitSettings();
    LoadSpawnInventory();
    SetupVoteSquads();
    SetupSrvInfo();

    if ( bStoryMode ) {
        class'ScrnAchievements'.static.RegisterAchievements(class'AchObjMaps');
    }

    Log(FriendlyName @ GetVersionStr()$" loaded", 'ScrnBalance');

    for ( i=0; i<AutoLoadMutators.length; ++i ) {
        if ( AutoLoadMutators[i] != "" )  {
            Log("Loading additional mutator: " $ AutoLoadMutators[i], 'ScrnBalance');
            KF.AddMutator(AutoLoadMutators[i], true);
        }
    }
}

function SetupSrvInfo()
{
    if ( SrvInfo == none )
        SrvInfo = Spawn(Class'ScrnBalanceSrv.ScrnSrvReplInfo');

    SrvInfo.bForceSteamNames = bForceSteamNames;
}


function InitDoors()
{
    local KFUseTrigger t;

    foreach DynamicActors(class'KFUseTrigger', t) {
        DoorKeys[DoorKeys.Length] = t;
        if ( t.DoorOwners.Length >= 2 )
            DoubleDoorKeys[DoubleDoorKeys.Length] = t;
    }
}

function CheckDoors()
{
    local int i, j;
    local bool bBlowDoors;
    local KFUseTrigger key;

    for ( i=0; i<DoubleDoorKeys.length; ++i ) {
        key = DoubleDoorKeys[i];
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

function RespawnDoors()
{
    local int i, j;
    local KFUseTrigger key;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        for ( j = 0; j < key.DoorOwners.Length; ++j ) {
            key.DoorOwners[j].RespawnDoor();
        }
    }
}

function BlowDoors()
{
    local int i, j;
    local KFUseTrigger key;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        for ( j = 0; j < key.DoorOwners.Length; ++j ) {
            if (!key.DoorOwners[j].bDoorIsDead) {
                key.DoorOwners[j].GoBang(none, vect(0,0,0), vect(0,0,0), none);
            }
        }
    }
}

function WeldDoors(float WeldPct)
{
    local int i, j;
    local KFUseTrigger key;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        if ( WeldPct ~= -1.0 )
            key.WeldStrength = fclamp((0.01 + frand()) * key.MaxWeldStrength, key.WeldStrength, key.MaxWeldStrength);
        else
            key.WeldStrength = WeldPct * key.MaxWeldStrength;

        for ( j = 0; j < key.DoorOwners.Length; ++j ) {
            key.DoorOwners[j].bShouldBeOpen = false;
            key.DoorOwners[j].RespawnDoor();
            key.DoorOwners[j].DoClose();
            if ( !key.DoorOwners[j].bNoSeal ) {
                key.DoorOwners[j].SetWeldStrength(key.WeldStrength);
            }
        }
    }
}

function UnweldDoors()
{
    local int i, j;
    local KFUseTrigger key;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        key.WeldStrength = 0;
        for ( j = 0; j < key.DoorOwners.Length; ++j ) {
            if ( !key.DoorOwners[j].bDoorIsDead ) {
                key.DoorOwners[j].SetWeldStrength(0);
            }
        }
    }
}

// 50% chance for dooor to be welded
// 25% - unweld
// 25% - blow
function RandomizeDoors()
{
    local int i, j;
    local KFUseTrigger key;
    local float f;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        f = frand();

        if ( f > 0.505 ) {  // weld
            key.WeldStrength = (f - 0.5) * 2.0;
            for ( j = 0; j < key.DoorOwners.Length; ++j ) {
                key.DoorOwners[j].bShouldBeOpen = false;
                key.DoorOwners[j].RespawnDoor();
                key.DoorOwners[j].DoClose();
                if ( !key.DoorOwners[j].bNoSeal ) {
                    key.DoorOwners[j].SetWeldStrength(key.WeldStrength);
                }
            }
        }
        else if ( f > 0.25 ) {  // unweld or respawn
            key.WeldStrength = 0;
            for ( j = 0; j < key.DoorOwners.Length; ++j ) {
                key.DoorOwners[j].RespawnDoor();
                key.DoorOwners[j].SetWeldStrength(0);
            }
        }
        else {  // blow
            for ( j = 0; j < key.DoorOwners.Length; ++j ) {
                if ( !key.DoorOwners[j].bDoorIsDead ) {
                    key.DoorOwners[j].GoBang(none, vect(0,0,0), vect(0,0,0), none);
                }
            }
        }

    }
}

static function class<ScrnVeterancyTypes> PickRandomPerk(ScrnClientPerkRepLink L)
{
    local array< class<ScrnVeterancyTypes> > CA;
    local int i;
    local class<ScrnVeterancyTypes> Perk;

    for ( i=0; i < L.CachePerks.length; ++i ) {
        if ( L.CachePerks[i].CurrentLevel > 0 ) {
            Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
            if ( Perk != none && !Perk.default.bLocked )
                CA[CA.Length] = Perk;
        }
    }

    if ( CA.Length > 0 )
        return CA[rand(CA.Length)];
    return none;
}

function LockPerk(class<ScrnVeterancyTypes> Perk, bool bLock)
{
    local Controller C;
    local PlayerController Player;
    local ClientPerkRepLink L;
    local int i;
    local class<ScrnVeterancyTypes> RandomPerk;

    Perk.default.bLocked = bLock;

    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        Player = PlayerController(C);
        if ( Player != none && SRStatsBase(Player.SteamStatsAndAchievements) != none ) {
            L = SRStatsBase(Player.SteamStatsAndAchievements).Rep;
            if ( L != none ) {
                for ( i=0; i < L.CachePerks.length; ++i ) {
                    if ( L.CachePerks[i].PerkClass == Perk ) {
                        if ( bLock ) {
                            L.ClientPerkLevel(i, 255);  // mark perk as locked
                            if ( KFPlayerReplicationInfo(Player.PlayerReplicationInfo).ClientVeteranSkill == Perk ) {
                                RandomPerk = PickRandomPerk(ScrnClientPerkRepLink(L));
                                if ( RandomPerk != none )
                                    ScrnClientPerkRepLink(L).ServerSelectPerkSE(RandomPerk);
                            }
                        }
                        else {
                            // set highest bit to 1 (128 = 10000000b) to notify client
                            // that perk has been unlocked
                            L.ClientPerkLevel(i, 0x80 | L.CachePerks[i].PerkClass.static.PerkIsAvailable(L));
                        }
                        break;
                    }
                }
            }
        }
    }
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
    return GameRules.GameDoom3Kills > 0;
}

static function DestroyLinkedInfo( LinkedReplicationInfo EntryLink )
{
    local LinkedReplicationInfo CurrentLink, NextLink;

    for ( CurrentLink = EntryLink; CurrentLink != none; CurrentLink = NextLink ) {
        NextLink = CurrentLink.NextReplicationInfo;
        CurrentLink.Destroy();
    }
    EntryLink = none;
}

function ServerTraveling(string URL, bool bItems)
{
    local int j;

    log("ServerTraveling", 'ScrnBalance');
    if ( bLogObjectsAtMapEnd )
        LogObjects();

    if (NextMutator != None)
        NextMutator.ServerTraveling(URL,bItems);

    if ( ScrnGT == none || ScrnGT.ScrnGameLength == none )
        class'ScrnGameRules'.static.ResetGameSquads(KF, CurrentEventNum);
    class'ScrnAchievements'.static.ResetAchList();

    if ( Level.NetMode == NM_DedicatedServer ) {
        // break links to self
        Mut = none;
        default.Mut = none;
        class'ScrnBalance'.default.Mut = none;
    }

    for ( j=0; j<Perks.length; ++j )
        if ( Perks[j] != none )
            Perks[j].default.DefaultInventory.length = 0;

    DestroyLinkedInfo(CustomWeaponLink);
    CustomWeaponLink = none;

    // destroy local objects
    if ( MapInfo != none ) {
        MapInfo.Destroy();
        MapInfo = none;
    }
    if ( BurnMech != none ) {
        BurnMech.Destroy();
        BurnMech = none;
    }
    if ( SrvInfo != none ) {
        SrvInfo.Destroy();
        SrvInfo = none;
    }
}

simulated function Destroyed()
{
    super.Destroyed();
    log("ScrnBalance destroyed", 'ScrnBalance');
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
                // KFPRI not found. Add a new record.
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

function BlamePlayer(ScrnPlayerController PC, string Reason, optional int BlameInc)
{
    local ScrnCustomPRI ScrnPRI;

    if ( PC == none )
        return;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PC.PlayerReplicationInfo);
    if ( ScrnPRI == none )
        return;
    if ( BlameInc == 0 )
        BlameInc = 1;
    ScrnPRI.BlameCounter += BlameInc;
    PC.ReceiveLocalizedMessage(class'ScrnBlamedMsg', ScrnPRI.BlameCounter);
    ReplaceText(Reason, "%p", PC.GetHumanReadableName());
    BroadcastMessage(ColorString(Reason, 200, 200, 1), false);
}

final static function bool GetHighlyDecorated(int SteamID32,
    out material Avatar, out material ClanIcon,
    out material PreNameIcon, out Color PrefixIconColor, out material PostNameIcon, out Color PostfixIconColor,
    out int Playoffs, out int TourneyWon)
{
    local int start, end, i;

    start = 0;
    end = default.HighlyDecorated.length;

    while ( start < end ) {
        i = start + ((end - start)>>1);
        if ( SteamID32 == default.HighlyDecorated[i].SteamID32 ) {
            if ( default.HighlyDecorated[i].Avatar == none && default.HighlyDecorated[i].AvatarRef != "" )
                default.HighlyDecorated[i].Avatar = Material(DynamicLoadObject(default.HighlyDecorated[i].AvatarRef, class'Material'));
            if ( default.HighlyDecorated[i].ClanIcon == none && default.HighlyDecorated[i].ClanIconRef != "" )
                default.HighlyDecorated[i].ClanIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].ClanIconRef, class'Material'));
            if ( default.HighlyDecorated[i].PreNameIcon == none && default.HighlyDecorated[i].PreNameIconRef != "" )
                default.HighlyDecorated[i].PreNameIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].PreNameIconRef, class'Material'));
            if ( default.HighlyDecorated[i].PostNameIcon == none && default.HighlyDecorated[i].PostNameIconRef != "" )
                default.HighlyDecorated[i].PostNameIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].PostNameIconRef, class'Material'));
            Avatar = default.HighlyDecorated[i].Avatar;
            ClanIcon = default.HighlyDecorated[i].ClanIcon;
            PreNameIcon = default.HighlyDecorated[i].PreNameIcon;
            PrefixIconColor = default.HighlyDecorated[i].PrefixIconColor;
            PostNameIcon = default.HighlyDecorated[i].PostNameIcon;
            PostfixIconColor = default.HighlyDecorated[i].PostfixIconColor;
            Playoffs = default.HighlyDecorated[i].Playoffs;
            TourneyWon = default.HighlyDecorated[i].TourneyWon;
            return true;
        }
        else if ( SteamID32 < default.HighlyDecorated[i].SteamID32 )
            end = i;
        else
            start = i + 1;
    }
    Avatar = none;
    ClanIcon = none;
    PreNameIcon = none;
    PostNameIcon = none;
    Playoffs = 0;
    TourneyWon = 0;
    return false;
}

/** Performs binary search on sorted array.
 * @param arr : array of sorted items (in ascending order). Array will not be modified.
 *              out modifier is used just for performance purpose (pass by reference).
 * @param val : value to search
 * @return array index or -1, if value not found.
 */
final static function int BinarySearch(out array<int> arr, int val)
{
    local int start, end, i;

    start = 0;
    end = arr.length;
    while ( start < end ) {
        i = start + ((end - start)>>1);
        if ( arr[i] == val )
            return i;
        else if ( val < arr[i] )
            end = i;
        else
            start = i + 1;
    }
    return -1;
}

final static function int BinarySearchStr(out array<string> arr, string val)
{
    local int start, end, i;

    start = 0;
    end = arr.length;
    while ( start < end ) {
        i = start + ((end - start)>>1);
        if ( arr[i] == val )
            return i;
        else if ( val < arr[i] )
            end = i;
        else
            start = i + 1;
    }
    return -1;
}

defaultproperties
{
    BonusCapGroup="ScrnBalance"
    strBonusLevel="Your effective perk bonus level is [%s]"
    strStatus="Your perk level: Visual=%v, Effective=[%b]. Server perk range is [%n..%x]."
    strStatus2="Alt.Burn=%a. MaxZombiesOnce=%m."
    strSrvWarning="You are using dedicated server version of ScrnBalance that shouldn't be installed on local machines! Please Obtain client version from Steam Workshop."
    strSrvWarning2="If you are getting version mismatch erros, delete KillingFloorSystemScrnBalanceSrv.u file."
    strBetaOnly="Only avaliable during Beta testing (bBeta=True)"

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
    MinVoteDifficulty=2
    bTraderSpeedBoost=True

    BonusLevelNormalMax=4
    BonusLevelHardMax=5
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
    pickupReplaceArray(47)=(oldClass=Class'KFMod.CrossbowPickup',NewClass=Class'ScrnBalanceSrv.ScrnCrossbowPickup')
    pickupReplaceArray(48)=(oldClass=Class'KFMod.KnifePickup',NewClass=Class'ScrnBalanceSrv.ScrnKnifePickup')
    FragReplacementIndex=45

    Functions=Class'ScrnBalanceSrv.ScrnFunctions'

    Perks(0)=Class'ScrnBalanceSrv.ScrnVetFieldMedic'
    Perks(1)=Class'ScrnBalanceSrv.ScrnVetSupportSpec'
    Perks(2)=Class'ScrnBalanceSrv.ScrnVetSharpshooter'
    Perks(3)=Class'ScrnBalanceSrv.ScrnVetCommando'
    Perks(4)=Class'ScrnBalanceSrv.ScrnVetBerserker'
    Perks(5)=Class'ScrnBalanceSrv.ScrnVetFirebug'
    Perks(6)=Class'ScrnBalanceSrv.ScrnVetDemolitions'
    Perks(7)=Class'ScrnBalanceSrv.ScrnVeterancyTypes' // off-perk
    Perks(8)=Class'ScrnBalanceSrv.ScrnVetGunslinger'
    Perks(9)=Class'ScrnBalanceSrv.ScrnVetCombatMedic'
    strAchEarn="%p earned an achievement: %a"
    bBroadcastAchievementEarn=True
    AchievementFlags=255
    bSaveStatsOnAchievementEarned=True
    bTradingDoorsOpen=True
    WeldingRequirementScaling=1.000000
    StalkerRequirementScaling=1.000000
    SkippedTradeTimeMult=1.0
    ServerPerksPkgName="ScrnSP.ServerPerksMutSE"
    bReplaceHUD=True
    bReplaceScoreBoard=True
    bBroadcastPickups=True
    BroadcastPickupText="%p picked up %o's %w ($%$)."
    bAllowWeaponLock=True
    bAutoKickOffPerkPlayers=True
    strAutoKickOffPerk="You have been auto kicked from the server for playing without a perk. Type RECONNECT in the console to join the server again and choose a perk."
    strVersion="v%m.%n.%p"

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
    SpawnInventory(5)="2:ScrnBalanceSrv.ScrnCrossbowPickup:6-255:12+3:225"
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

    ColorTags( 0)=(T="^0",R=1,G=1,B=1)
    ColorTags( 1)=(T="^1",R=200,G=1,B=1)
    ColorTags( 2)=(T="^2",R=1,G=200,B=1)
    ColorTags( 3)=(T="^3",R=200,G=200,B=1)
    ColorTags( 4)=(T="^4",R=1,G=1,B=255)
    ColorTags( 5)=(T="^5",R=1,G=255,B=255)
    ColorTags( 6)=(T="^6",R=200,G=1,B=200)
    ColorTags( 7)=(T="^7",R=200,G=200,B=200)
    ColorTags( 8)=(T="^8",R=255,G=127,B=0)
    ColorTags( 9)=(T="^9",R=128,G=128,B=128)

    ColorTags(10)=(T="^w$",R=255,G=255,B=255)
    ColorTags(11)=(T="^r$",R=255,G=1,B=1)
    ColorTags(12)=(T="^g$",R=1,G=255,B=1)
    ColorTags(13)=(T="^b$",R=1,G=1,B=255)
    ColorTags(14)=(T="^y$",R=255,G=255,B=1)
    ColorTags(15)=(T="^c$",R=1,G=255,B=255)
    ColorTags(16)=(T="^o$",R=255,G=140,B=1)
    ColorTags(17)=(T="^u$",R=255,G=20,B=147)
    ColorTags(18)=(T="^s$",R=1,G=192,B=255)
    ColorTags(19)=(T="^n$",R=139,G=69,B=19)

    ColorTags(20)=(T="^W$",R=112,G=138,B=144)
    ColorTags(21)=(T="^R$",R=132,G=1,B=1)
    ColorTags(22)=(T="^G$",R=1,G=132,B=1)
    ColorTags(23)=(T="^B$",R=1,G=1,B=132)
    ColorTags(24)=(T="^Y$",R=255,G=192,B=1)
    ColorTags(25)=(T="^C$",R=1,G=160,B=192)
    ColorTags(26)=(T="^O$",R=255,G=69,B=1)
    ColorTags(27)=(T="^U$",R=160,G=32,B=240)
    ColorTags(28)=(T="^S$",R=65,G=105,B=225)
    ColorTags(29)=(T="^N$",R=80,G=40,B=20)

    Post6ZedSpawnInc=0.25
    Post6AmmoSpawnInc=0.20
    AmmoBoxMesh=StaticMesh'kf_generic_sm.pickups.Metal_Ammo_Box'
    AmmoBoxDrawScale=1.000000
    AmmoBoxDrawScale3D=(X=1.000000,Y=1.000000,Z=1.000000)
    bAlterWaveSize=true
    Post6ZedsPerPlayer=0.40
    MaxWaveSize=800
    MaxZombiesOnce=48
    GameStartCountDown=12
    SharpProgMinDmg=1000
    bSpawnRateFix=True
    MinZedSpawnPeriod=2.0
    bScrnWaves=True
    bServerInfoVeterancy=True
    bPlayerZEDTime=True
    bUseDLCLocks=False
    bUseDLCLevelLocks=True
    bFixMusic=True
    LockTeamMinWave=7.0
    LockTeamAutoWave=8.5
    bForceSteamNames=True

    EndGameStatBonus=0.5
    bStatBonusUsesHL=True
    StatBonusMinHL=0
    FirstStatBonusMult=2

    MutateCommands(0)="ACCURACY"
    MutateCommands(1)="CHECK"
    MutateCommands(2)="CMDLINE"
    MutateCommands(3)="DEBUGGAME"
    MutateCommands(4)="DEBUGPICKUPS"
    MutateCommands(5)="DEBUGSPI"
    MutateCommands(6)="ENEMIES"
    MutateCommands(7)="GIMMECOOKIES"
    MutateCommands(8)="HELP"
    MutateCommands(9)="HL"
    MutateCommands(10)="LEVEL"
    MutateCommands(11)="MAPDIFF"
    MutateCommands(12)="MAPZEDS"
    MutateCommands(13)="MUTLIST"
    MutateCommands(14)="PERKSTATS"
    MutateCommands(15)="PLAYERLIST"
    MutateCommands(16)="STATUS"
    MutateCommands(17)="VERSION"
    MutateCommands(18)="ZED"
    MutateCommands(19)="ZEDLIST"

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

    HighlyDecorated(0)=(SteamID32=3907835,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(1)=(SteamID32=4787302,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(2)=(SteamID32=15243342,ClanIconRef="ScrnTex.Players.Code",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(3)=(SteamID32=18524053,AvatarRef="ScrnTex.Players.FabZen",ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(4)=(SteamID32=18871148,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Berserker_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(5)=(SteamID32=20530727,AvatarRef="ScrnTex.Players.LazyBunta",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(6)=(SteamID32=21825964,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(7)=(SteamID32=25188900,AvatarRef="ScrnTex.Players.Scuddles",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(8)=(SteamID32=26505257,Playoffs=1,AvatarRef="ScrnTex.Players.Duckbuster",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(9)=(SteamID32=27263782,Playoffs=1,AvatarRef="ScrnTex.Players.Termcat",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(10)=(SteamID32=27784497,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(11)=(SteamID32=32271863,AvatarRef="ScrnTex.Players.PooSH",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(12)=(SteamID32=32279441,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(13)=(SteamID32=32708029,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(14)=(SteamID32=32779545,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(15)=(SteamID32=32976519,Playoffs=1,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(16)=(SteamID32=34308728,AvatarRef="ScrnTex.Players.Janitor",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(17)=(SteamID32=37444251,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(18)=(SteamID32=41734606,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(19)=(SteamID32=43087787,Playoffs=1,AvatarRef="ScrnTex.Players.Chaos",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(20)=(SteamID32=43944237,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(21)=(SteamID32=44141219,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(22)=(SteamID32=44328745,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(23)=(SteamID32=44388687,AvatarRef="ScrnTex.Players.Aze",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(24)=(SteamID32=45006648,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(25)=(SteamID32=45088649,Playoffs=1,AvatarRef="ScrnTex.Players.Joe",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Berserker_Grey",PrefixIconColor=(R=255,G=255,B=255,A=0),PostfixIconColor=(A=0))
    HighlyDecorated(26)=(SteamID32=45352894,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(27)=(SteamID32=45594574,AvatarRef="ScrnTex.Players.CodeReaper",PreNameIconRef="ScrnTex.Players.BowieKnifeLeft",PostNameIconRef="ScrnTex.Players.BowieKnifeRight",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(28)=(SteamID32=46023864,AvatarRef="ScrnTex.Players.Baron",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PostNameIconRef="ScrnAch_T.Achievements.Baron",PrefixIconColor=(A=0),PostfixIconColor=(R=255,G=255,B=255,A=255))
    HighlyDecorated(29)=(SteamID32=47199674,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(30)=(SteamID32=47820768,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(31)=(SteamID32=49361376,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(32)=(SteamID32=51667940,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(33)=(SteamID32=52109233,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(34)=(SteamID32=53781980,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(35)=(SteamID32=54179805,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(36)=(SteamID32=54471316,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(37)=(SteamID32=57193815,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(38)=(SteamID32=58813412,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(39)=(SteamID32=59018230,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(40)=(SteamID32=59344954,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(41)=(SteamID32=59865355,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(42)=(SteamID32=61480134,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(43)=(SteamID32=61647562,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(44)=(SteamID32=63934831,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(45)=(SteamID32=64861994,Playoffs=1,AvatarRef="ScrnTex.Players.dkanus",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(46)=(SteamID32=66725591,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(47)=(SteamID32=66767874,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(48)=(SteamID32=67141366,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(49)=(SteamID32=68703215,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(50)=(SteamID32=68932148,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(51)=(SteamID32=70606615,AvatarRef="ScrnTex.Players.aaa",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(52)=(SteamID32=71427768,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(53)=(SteamID32=71462150,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(54)=(SteamID32=72523409,AvatarRef="ScrnTex.Players.Candybee",PreNameIconRef="ScrnTex.Players.Mudflapgirl_left",PostNameIconRef="ScrnTex.Players.Mudflapgirl_right",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(55)=(SteamID32=75600845,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(56)=(SteamID32=76661591,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(57)=(SteamID32=77967745,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(58)=(SteamID32=81279347,ClanIconRef="ScrnTex.Players.Dosh",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(59)=(SteamID32=81947447,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(60)=(SteamID32=82239578,AvatarRef="ScrnTex.Players.Toaste",PreNameIconRef="ScrnTex.Players.Yinyang",PostNameIconRef="ScrnTex.Players.Yinyang",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(61)=(SteamID32=83417929,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(62)=(SteamID32=84050600,AvatarRef="ScrnTex.Players.NikC",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(63)=(SteamID32=84652399,AvatarRef="ScrnTex.Players.Droop",PreNameIconRef="ScrnTex.Players.Batman",PostNameIconRef="ScrnTex.Players.Batman",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(64)=(SteamID32=85142081,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(65)=(SteamID32=87647886,ClanIconRef="ScrnTex.Players.Dosh",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(66)=(SteamID32=89323130,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(67)=(SteamID32=93919492,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(68)=(SteamID32=95752287,AvatarRef="ScrnTex.Players.FosterKF2",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=1),PostfixIconColor=(A=0))
    HighlyDecorated(69)=(SteamID32=99293732,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(70)=(SteamID32=102203653,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_chicken",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(71)=(SteamID32=102496714,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(72)=(SteamID32=106835439,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(73)=(SteamID32=107039826,Playoffs=1,AvatarRef="ScrnTex.Players.Seely",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(74)=(SteamID32=109654784,AvatarRef="ScrnTex.Players.BertieDastard",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(75)=(SteamID32=110496233,AvatarRef="ScrnTex.Players.VP",ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_dragon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(76)=(SteamID32=112564543,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(77)=(SteamID32=113961551,Playoffs=1,AvatarRef="ScrnTex.Players.Baffi",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(78)=(SteamID32=114826433,Playoffs=1,AvatarRef="ScrnTex.Players.nmm",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(79)=(SteamID32=121550025,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(80)=(SteamID32=124874371,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(81)=(SteamID32=127624729,AvatarRef="ScrnTex.Players.Scrublord",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(82)=(SteamID32=128107383,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(83)=(SteamID32=128199891,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(84)=(SteamID32=134825301,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(85)=(SteamID32=136078273,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(86)=(SteamID32=139723798,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(87)=(SteamID32=143999622,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(88)=(SteamID32=150832205,AvatarRef="ScrnTex.Players.Taloril",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(89)=(SteamID32=152138369,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(90)=(SteamID32=152983683,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(91)=(SteamID32=153788974,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(92)=(SteamID32=160715546,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(93)=(SteamID32=162712343,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(94)=(SteamID32=173722095,AvatarRef="ScrnTex.Players.catcat",PreNameIconRef="ScrnTex.Players.RadioActive",PostNameIconRef="ScrnTex.Players.RadioActive",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(95)=(SteamID32=182247922,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_kom",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(96)=(SteamID32=190669364,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(97)=(SteamID32=192070782,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(98)=(SteamID32=319278244,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(99)=(SteamID32=359866000,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_kom",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(100)=(SteamID32=374934166,AvatarRef="ScrnTex.Players.Bligiet",PreNameIconRef="ScrnTex.Players.BowieKnifeLeft",PostNameIconRef="ScrnTex.Players.BowieKnifeRight",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(101)=(SteamID32=378534555,AvatarRef="ScrnTex.Players.BossRoss",PreNameIconRef="ScrnTex.Players.BossRossNameIcon",PostNameIconRef="ScrnTex.Players.BossRossNameIcon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(102)=(SteamID32=389474897,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_homer",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(103)=(SteamID32=391528064,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(104)=(SteamID32=397272710,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(105)=(SteamID32=403136595,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_f",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(106)=(SteamID32=405312393,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
}
