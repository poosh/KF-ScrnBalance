/*****************************************************************************
 * ScrN Total Game Balance
 * @GitHub: https://github.com/poosh/KF-ScrnBalance
 * @author [ScrN]PooSH, contact via Steam: http://steamcommunity.com/id/scrn-poosh/
 *                      or Discord: https://discord.gg/Y3W5crSXA5
 * Copyright (c) 2012-2022 PU Developing IK, All Rights Reserved.
 *****************************************************************************/

class ScrnBalance extends ScrnMutator
    Config(ScrnBalanceSrv);

#exec OBJ LOAD FILE=ScrnAnims.ukx
#exec OBJ LOAD FILE=ScrnTex.utx
#exec OBJ LOAD FILE=ScrnAch_T.utx

var ScrnBalance Mut; // pointer to self to use in static functions, i.e class'ScrnBalance'.default.Mut

var const string BonusCapGroup;

var localized string strBonusLevel;
var localized string strStatus, strStatus2;
var localized string strBetaOnly;
var localized string strXPInitial, strXPProgress, strXPBonus;
var localized string strOnlyAdmin, strOnlyScrnGT, strOnlyNotInTourney;

// SRVFLAGS
var transient int SrvFlags; // used for network replication of the values below
var globalconfig bool bSpawn0, bNoStartCashToss, bMedicRewardFromTeam;
var globalconfig bool bAltBurnMech;
var globalconfig bool bReplaceNades, bShieldWeight, bBeta;
var globalconfig bool bShowDamages, bAllowWeaponLock;
var deprecated bool bManualReload, bForceManualReload;
var globalconfig bool bNoPerkChanges, bPerkChangeBoss, bPerkChangeDead, b10Stars;
var globalconfig bool bTraderSpeedBoost;
var bool bHardcore;
// END OF SRVFLAGS
var transient byte HardcoreLevel; // set from ScrnGameRules. Used for replication purposes only.

var globalconfig int ForcedMaxPlayers;
var globalconfig bool bAllowBehindView;

var globalconfig int
    BonusLevelNormalMax
    , BonusLevelHardMin, BonusLevelHardMax
    , BonusLevelSuiMin, BonusLevelSuiMax
    , BonusLevelHoeMin, BonusLevelHoeMax;

var transient int MinLevel, MaxLevel;
// Changing default value of variable disables its replication, cuz engine thinks it wasn't changed
var transient int SrvMinLevel, SrvMaxLevel;
var transient bool bInitialized;

var ScrnGameType ScrnGT;
var bool bStoryMode; // Objective Game mode (KFStoryGameInfo)
var bool bTSCGame; // Team Survival Competition (TSCGame)
var transient bool bTestMap, bRandomMap;
var transient string MapName;
var transient string OriginalMapName; // based on ScrnGameRules.MapAliases

struct SPickupReplacement {
    var class<Pickup> oldClass;
    var class<Pickup> newClass;
};
var array<SPickupReplacement> pickupReplaceArray;
var const int FragReplacementIndex;
var globalconfig bool bReplacePickups, bReplacePickupsStory;

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

var transient bool bInitReplicationReceived;

var Mutator ServerPerksMut;
var transient bool bDoom;
var transient bool bAllowAlwaysPerkChanges;

var globalconfig bool bAllowVoting;
var ScrnBalanceVoting MyVotingOptions;
var globalconfig bool bPauseTraderOnly; //game can be vote-paused in trader time only
var globalconfig float SkippedTradeTimeMult; //how much of the skipped trader time (mvote ENDTRADE) to add to the next one (0 - don't add, 1 - full, 0.5 - half of the skipped time)
var transient int TradeTimeAddSeconds; //amount of seconds to add to the next trader time
var globalconfig bool bAllowBlameVote, bAllowKickVote;
var globalconfig int BlameVoteCoolDown;
var globalconfig bool bBlameFart;
var transient int BlameCounter;
var globalconfig bool bAllowPauseVote, bAllowLockPerkVote, bAllowBoringVote;
var globalconfig int MaxPauseTime, MaxPauseTimePerWave;
var transient int PauseTimeRemaining;
var globalconfig byte MaxVoteKillMonsters;
var globalconfig int  MaxVoteKillHP;
var globalconfig bool bVoteKillCheckVisibility;
var globalconfig float VoteKillPenaltyMult;
var globalconfig byte MinVoteFF, MaxVoteFF;
var globalconfig byte MinVoteDifficulty;
var byte MaxDifficulty;

var ScrnBalancePersistence Persistence;

var globalconfig bool bDynamicLevelCap;
var int OriginalMaxLevel;

var globalconfig string ServerPerksPkgName; // if user didn't added SP mut before ScrnBalance - do it for him!
var globalconfig array<string> AutoLoadMutators;

var globalconfig bool bReplaceHUD, bReplaceScoreBoard;

var globalconfig int MaxWaveSize;
var globalconfig int MaxZombiesOnce;

var globalconfig float EndGameStatBonus;
var globalconfig float FirstStatBonusMult;
var globalconfig float RandomMapStatBonus;
var globalconfig bool  bStatBonusUsesHL;
var globalconfig int   StatBonusMinHL;

var globalconfig bool bBroadcastPickups; // broadcast weapon pickups
var globalconfig String BroadcastPickupText; // broadcast weapon pickups

const ZEDEVENT_RANDOM = 254;
var protected globalconfig byte EventNum;
var transient byte CurrentEventNum;
var globalconfig bool bForceEvent;
var globalconfig bool bResetSquadsAtStart; // calls ScrnGameRules.ResetSquads() at map start

var globalconfig bool bAutoKickOffPerkPlayers;
var localized String strAutoKickOffPerk;

struct SSquadConfig {
    var String SquadName;
    var string MonsterClass;
    var byte NumMonsters;
};
var deprecated array<SSquadConfig> VoteSquad;


struct SSquad {
    var String SquadName;
    var array < class<KFMonster> > Monsters;
};
var deprecated array<SSquad> Squads;
var deprecated int SquadSpawnedMonsters;

var globalconfig bool bNoRequiredEquipment;
var globalconfig bool bUseExpLevelForSpawnInventory;
var globalconfig array<string> SpawnInventory;

var globalconfig int StartCashNormal, StartCashHard, StartCashSui, StartCashHoE;
var globalconfig int MinRespawnCashNormal, MinRespawnCashHard, MinRespawnCashSui, MinRespawnCashHoE;
var globalconfig int TraderTimeNormal, TraderTimeHard, TraderTimeSui, TraderTimeHoE;
var globalconfig bool bLeaveCashOnDisconnect, bPlayerZEDTime;

var globalconfig string ColoredServerName;

var float OriginalWaveSpawnPeriod;
var globalconfig float MinZedSpawnPeriod;
var globalconfig bool bZedFights;
var globalconfig bool bServerInfoVeterancy;

var transient array<KFUseTrigger> DoorKeys;
var transient array<KFUseTrigger> DoubleDoorKeys; // keys with at least 2 doors

var transient name                AmmoBoxName;
var transient StaticMesh          AmmoBoxMesh;
var transient float               AmmoBoxDrawScale;
var transient vector              AmmoBoxDrawScale3D;


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
var globalconfig bool bUseDLCLocks,bUseDLCLevelLocks;
var ScrnLock LockManager;
var globalconfig bool bBuyPerkedWeaponsOnly, bPickPerkedWeaponsOnly;

struct SNameValuePair {
    var name ID;
    var int Value;
};

var globalconfig bool bFixMusic;

var globalconfig bool bRespawnDoors;

var transient bool bTeamsLocked; // Set by ScrnGameType. Used for replication purposes.
var globalconfig float LockTeamMinWave, LockTeamMinWaveTourney, LockTeamAutoWave;
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

var globalconfig bool bScrnWaves, bUserGames;

struct SVersionedItem {
    var string item;
    var int v;
};
var array<SVersionedItem> Versions;

struct SActors {
    var array<Actor> Actors;
};

// TSC stuff
var globalconfig bool bNoTeamSkins;
// SrvTourneyMode should be used for informative purposes only.
// All real checks must be done server-side only to prevent cheating.
var transient int SrvTourneyMode;
// END OF TSC STUFF

replication
{
    reliable if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        SrvMinLevel, SrvMaxLevel, HardcoreLevel, bTeamsLocked, SrvFlags, SrvAchievementFlags;

    // non-config vars and configs vars which seem to replicate fine
    reliable if ( bNetInitial && Role == ROLE_Authority )
        CustomWeaponLink, SrvTourneyMode, bTSCGame, bTestMap;

}

// ======================================= FUNCTIONS =======================================
static function class<GameInfo> GameByMapPrefix( string MapPrefix, class<GameInfo> DefaultGame )
{
    if ( MapPrefix == "KF" )
        return class'ScrnGameType';
    else if ( MapPrefix == "KFO")
        return class'ScrnStoryGameInfo';
    else if ( MapPrefix == "KFT")
        return class'ScrnTestGame';

    return DefaultGame;
}

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

// client & server side
simulated function InitSettings()
{
    ApplySpawnBalance();
    ApplyWeaponFix();

    if (bShieldWeight) {
        bReplaceNades = true;
        class'ScrnFrag'.default.Weight = 0;
        class'ScrnHumanPawn'.default.StandardVestClass.default.Weight = 1;
    }
    else {
        class'ScrnFrag'.default.Weight = 1;
        class'ScrnHumanPawn'.default.StandardVestClass.default.Weight = 0;
    }
    class'ScrnFragPickup'.default.Weight = class'ScrnFrag'.default.Weight;
    RecalcAllPawnWeight();

    class'KFMod.CrossbowArrow'.default.DamageRadius = 0; // isn't used anywhere. Set to 0 to fix description

    // Achievements
    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);

    // fixes critical bug:
    // Assertion failed: inst->KPhysRootIndex != INDEX_NONE && inst->KPhysLastIndex != INDEX_NONE [File:.\KSkeletal.cpp] [Line: 595]
    class'FellLava'.default.bSkeletize = false;

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
    msg = Repl(msg, "%s", String(class'ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(
            KFPlayerReplicationInfo(KPC.PlayerReplicationInfo))), true);

    KPC.ClientMessage(msg);
}

function MessageVersion(PlayerController PC)
{
    local int i;

    if ( PC == none )
        return;

    PC.ClientMessage("ScrN Shared Lib" @ VersionStr(LibVersion()));
    PC.ClientMessage(FriendlyName @ GetVersionStr());
    for ( i = 0; i < Versions.length; ++i ) {
        PC.ClientMessage(Versions[i].item @ VersionStr(Versions[i].v));
    }
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
    msg = Repl(msg, "%v", String(KFPRI.ClientVeteranSkillLevel), true);
    msg = Repl(msg, "%b", String(class'ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(KFPRI)), true);
    msg = Repl(msg, "%n", String(MinLevel), true);
    msg = Repl(msg, "%x", String(MaxLevel), true);
    PC.ClientMessage(msg, 'Log');

    msg = strStatus2;
    msg = Repl(msg, "%a", String(bAltBurnMech), true);
    msg = Repl(msg, "%m", String(KF.MaxZombiesOnce), true);
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
            if (KFPRI.ClientVeteranSkillLevel != class'ScrnVeterancyTypes'.static.GetClientVeteranSkillLevel(KFPRI))
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
        log(class'ScrnFunctions'.static.StripColorTags(Msg), 'ScrnBalance');
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

static final function string ColorString(string s, byte R, byte G, byte B)
{
    return class'ScrnFunctions'.static.ColorString(s, R, G, B);
}

simulated function string PlainPlayerName(PlayerReplicationInfo PRI)
{
    if ( PRI == none )
        return "";

    return class'ScrnFunctions'.static.StripColorTags(PRI.PlayerName);
}

simulated function string ColoredPlayerName(PlayerReplicationInfo PRI)
{
    if ( PRI == none )
        return "";

    return class'ScrnFunctions'.static.ParseColorTags(PRI.PlayerName, PRI);
}

function StolenWeapon(Pawn NewOwner, KFWeaponPickup WP)
{
    local string str;

    str = BroadcastPickupText;
    str = Repl(str, "%p", ColorString(class'ScrnFunctions'.static.ParseColorTags(NewOwner.GetHumanReadableName(), NewOwner.PlayerReplicationInfo), 192, 1, 1) $ ColorString("", 192, 192, 192), true);
    str = Repl(str, "%o", ColorString(ColoredPlayerName(WP.DroppedBy.PlayerReplicationInfo), 1, 192, 1) $ ColorString("", 192, 192, 192), true);
    str = Repl(str, "%w", ColorString(WP.ItemName, 1, 96, 192) $ ColorString("", 192, 192, 192), true);
    str = Repl(str, "%$", ColorString(String(WP.SellValue), 192, 192, 1) $ ColorString("", 192, 192, 192), true);
    BroadcastMessage(str);
}

//recalculate
function RecalcAllPawnWeight()
{
    local ScrnHumanPawn P;

    foreach DynamicActors(class'ScrnHumanPawn', P)
        P.RecalcWeight();
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
    else {
        // Hard and below
        W = 0.35;
        A = 0.50;
    }

    if ( KF.NumPlayers > 6 ) {
        A *= 1.0 + float(KF.NumPlayers - 6)*0.2;
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
    s = Repl(s, "%p", PlayerController(AchHandler.Owner).PlayerReplicationInfo.PlayerName, true);
    s = Repl(s, "%a", AchHandler.AchDefs[AchIndex].DisplayName, true);

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
            PlayerController(C).ReceiveLocalizedMessage(class'ScrnFakedAchMsg', AchIndex);
    }
}

function CheckMutators()
{
    local Mutator M;

    for ( M = KF.BaseMutator; M != None; M = M.NextMutator ) {
        if ( M.IsA('ServerPerksMut') ) {
            ServerPerksMut = M;
            if ( !M.IsA('ServerPerksMutSE') ) {
                log("ScrnSP.ServerPerksMutSE is recommeded. Used: " $ M.class, 'ScrnBalance');
            }
        }
    }
}

function Mutator FindServerPerksMut()
{
    if ( ServerPerksMut != none )
        return ServerPerksMut;

    CheckMutators();
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


//can't statically link to ServerPerksMut, cuz it is server-side only
function SaveStats()
{
    bNeedToSaveStats = false;

    if ( bTestMap )
        return;

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

function DynamicLevelCap()
{
    local int num, m;

    if ( !bDynamicLevelCap )
        return;

    m = OriginalMaxLevel;
    if ( bTSCGame && KF.Teams[1] != none )
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

function OnTraderTime()
{
    if ( bStoryMode && KF.WaveNum == CurWave ) {
        // seems like story game doesn't increment wave counter
        KF.WaveNum++;
    }

    GameRules.WaveEnded();

    if ( MyVotingOptions != none && MyVotingOptions.VotingHandler.IsVoteInProgress() ) {
        if ( MyVotingOptions.VotingHandler.IsMyVotingRunning(MyVotingOptions, MyVotingOptions.VOTE_BORING )
                || MyVotingOptions.VotingHandler.IsMyVotingRunning(MyVotingOptions, MyVotingOptions.VOTE_ENDWAVE ) )
        {
            MyVotingOptions.VotingHandler.VoteFailed();
        }
    }

    KF.WaveCountDown += TradeTimeAddSeconds;
    TradeTimeAddSeconds = 0;
    PauseTimeRemaining = MaxPauseTimePerWave;
}

function OnWaveBegin()
{
    // Wave in Progress
    CurWave = KF.WaveNum;

    if ( bAutoKickOffPerkPlayers )
        KickOffPerkPlayers();

    GameRules.WaveStarted();

    if ( MyVotingOptions != none && MyVotingOptions.VotingHandler.IsMyVotingRunning(MyVotingOptions,
            MyVotingOptions.VOTE_ENDTRADE) )
        MyVotingOptions.VotingHandler.VoteFailed();

    DestroyExtraPipebombs();

    // call SetupPickups only when playing non-ScrnGameType mode.
    // ScrnGameType automatically calls SetupPickups() during wave begin.
    if ( ScrnGT == none && !bStoryMode )
        SetupPickups(false);
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
            OnTraderTime();
        }
        else {
            OnWaveBegin();
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
    // Don't use Dirge music as boss battle, because the default KF_Abandon is much better.
    if ( bDoom ) {
        // try this. If client doesn't have that song, then KF_Abandon will be played
        KF.BossBattleSong = "EGT-SignOfEvil";
    }
    else if ( KF.MapSongHandler.WaveBasedSongs.Length > 10 && KF.MapSongHandler.WaveBasedSongs[10].CombatSong != ""
            &&  !(left(KF.MapSongHandler.WaveBasedSongs[10].CombatSong, 5) ~= "Dirge") )
    {
        KF.BossBattleSong = KF.MapSongHandler.WaveBasedSongs[10].CombatSong;
    }
}

function DisableDoom3Monsters()
{
    log("Disabling Doom3 monsters", 'ScrnBalance');
    bDoom = PublishValue('SpawnDoom3Monsters', 0);
    if ( !bDoom ) {
        log("Doom3Mutator not found!", 'ScrnBalance');
    }
}

function bool SetCustomValue(name Key, int Value, optional ScrnMutator Publisher)
{
    switch (Key) {
        case 'GetSpawnDoom3Monsters':
            // Bit mask:
            // 1 - regular monsters
            // 2 - mid-game bosses
            // 4 - end-game boss
            bDoom = true;
            if ( Publisher != none && ScrnGT != none && bScrnWaves ) {
                // regular monsters and end-game boss are spawned via ScrnGameLength.
                // Keep only mid-game bosses
                // WARNING! ScrnGT.ScrnGameLength may not yet exist at this moment
                Publisher.SetCustomValue('SpawnDoom3Monsters', Value & 2, self);
                return true;
            }
    }
    return false;
}


auto simulated state WaitingForTick
{
    function SrvFirstTick()
    {
        if ( MapInfo.WaveSpawnPeriod > 0 ) {
            OriginalWaveSpawnPeriod = MapInfo.WaveSpawnPeriod;
            KF.KFLRules.WaveSpawnPeriod = MapInfo.WaveSpawnPeriod;
        }
        else {
            OriginalWaveSpawnPeriod = KF.KFLRules.WaveSpawnPeriod;
            if ( OriginalWaveSpawnPeriod < MinZedSpawnPeriod ) {
                OriginalWaveSpawnPeriod = MinZedSpawnPeriod;
                KF.KFLRules.WaveSpawnPeriod = MinZedSpawnPeriod;
            }
        }

        ForceMaxPlayers();
        if ( !bStoryMode ) {
            InitDoors();
            FixShops();
            SetStartCash();
            if ( ScrnGT != none ) {
                if ( bTSCGame ) {
                    Level.GRI.bNoTeamSkins = bNoTeamSkins && !ScrnGT.IsTourney();
                }
                ScrnGT.CheckZedSpawnList();
                if ( ScrnGT.ScrnGameLength != none ) {
                    if ( ScrnGT.ScrnGameLength.Doom3DisableSuperMonsters
                            || ScrnGT.ScrnGameLength.Doom3DisableSuperMonstersFromWave == 1 )
                    {
                        DisableDoom3Monsters();
                    }
                    else if ( !bDoom ) {
                        // Enable super monsters but disable regular D3 mobs cuz we will spawn them via ScrnWaves
                        bDoom = PublishValue('SpawnDoom3Monsters', 2);
                    }
                }
            }
            if ( bFixMusic ) {
                FixMusic();
            }
        }
        if ( ColoredServerName != "" ) {
            Level.GRI.ServerName = class'ScrnFunctions'.static.ParseColorTags(ColoredServerName);
        }
    }

    simulated function Tick( float DeltaTime )
    {
        Disable('Tick');

        if ( Role == ROLE_Authority) {
            SrvFirstTick();
            SetTimer(1, true);
            GoToState('');
        }
        else {
            GotoState('ClientWaitingForNet');
        }
    }
}

simulated state ClientWaitingForNet
{
Begin:
    sleep(5.0);
    if ( bInitialized ) {
        GotoState('');
    }
    else {
        Timelog("Settings receiving timeout failed - initializing with default settings");
        InitSettings();
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
        class'ScrnFunctions'.static.LongMessage(Sender, strXPInitial $ SPI.PerkStatStr(SPI.GameStartStats));
        class'ScrnFunctions'.static.LongMessage(Sender, strXPProgress $ SPI.PerkProgressStr(SPI.GameStartStats));
    }
}

function MessageEndGameBonus(PlayerController Sender)
{
    local float BonusMult;

    BonusMult = GameRules.CalcEndGameBonusMult();
    if (BonusMult >= 0.1) {
        Sender.ClientMessage(strXPBonus $ class'ScrnVeterancyTypes'.static.GetPercentStr(BonusMult));
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


function bool IsAdmin(PlayerController Sender)
{
    return (Sender.PlayerReplicationInfo != none && Sender.PlayerReplicationInfo.bAdmin)
            || Level.NetMode == NM_Standalone
            || (Level.NetMode == NM_ListenServer && NetConnection(Sender.Player) == none);
}

function bool CheckAdmin(PlayerController Sender)
{
    if ( IsAdmin(Sender) )
        return true;

    Sender.ClientMessage(strOnlyAdmin);
    return false;
}

function bool CheckScrnGT(PlayerController Sender)
{
    if ( ScrnGT != none )
        return true;

    Sender.ClientMessage(strOnlyScrnGT);
    return false;
}

function bool CheckNotTourney(PlayerController Sender)
{
    if ( ScrnGT == none || !ScrnGT.IsTourney() )
        return true;

    Sender.ClientMessage(strOnlyNotInTourney);
    return false;
}

function Mutate(string MutateString, PlayerController Sender)
{
    local string Key, Value;
    local int cmd, i;

    if ( MutateString == "" )
        return;

    Key = caps(MutateString);
    Divide(Key, " ", Key, Value);
    cmd = class'ScrnFunctions'.static.BinarySearchStr(MutateCommands, Key);
    if ( cmd == -1 ) {
        super(Mutator).Mutate(MutateString, Sender);
        return; //unknown command
    }

    switch ( EMutateCommand(cmd) ) {
        case MUTATE_ACCURACY:
            SendAccuracy(Sender);
            break;
        case MUTATE_CHECK:
            Sender.ClientMessage(FriendlyName);
            break;
        case MUTATE_CMDLINE:
            if ( CheckAdmin(Sender) && CheckScrnGT(Sender) )
                class'ScrnFunctions'.static.LongMessage(Sender, ScrnGT.GetCmdLine(), 80, "?");
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
            if ( bTestMap || CheckAdmin(Sender) )
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
            // deprecated
            break;
        case MUTATE_MAPZEDS:
            if ( CheckAdmin(Sender) && CheckNotTourney(Sender) ) {
                i = int(value);
                if ( i == 0 ) {
                    Sender.ClientMessage("MaxZombiesOnce=" $ KF.MaxZombiesOnce);
                }
                else if ( i < 32 || i > 192 ) {
                    Sender.ClientMessage("Map-zeds-at-once must be in range [32..192], e.g.: MUTATE MAPZEDS 64");
                }
                else {
                    SetMaxZombiesOnce(i);
                    BroadcastMessage("MaxZombiesOnce=" $ KF.MaxZombiesOnce);
                }
            }
            break;
        case MUTATE_MUTLIST:
            Sender.ClientMessage(MutatorList());
            break;
        case MUTATE_PERKSTATS:
            MessagePerkStats(Sender);
            MessageEndGameBonus(Sender);
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
            else if ( bTestMap || CheckAdmin(Sender) ) {
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

    super(Mutator).Mutate(MutateString, Sender);
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
        v = class'ScrnVetSharpshooter'.default.progressArray0[Level];
        while ( --v >= 0 )
            SteamStats.AddHeadshotKill(false);
        SteamStats.AddBullpupDamage(class'ScrnVetCommando'.default.progressArray0[Level]);
        SteamStats.AddMeleeDamage(class'ScrnVetBerserker'.default.progressArray0[Level]);
        SteamStats.AddFlameThrowerDamage(class'ScrnVetFirebug'.default.progressArray0[Level]);
        SteamStats.AddExplosivesDamage(class'ScrnVetDemolitions'.default.progressArray0[Level]);
        for ( S = SteamStats.Rep.CustomLink; S!=none; S=S.NextLink ) {
            if ( ScrnPistolKillProgress(S) != none )
                S.IncrementProgress(class'ScrnVetGunslinger'.default.progressArray0[Level]);
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

function simulated String GameTimeStr()
{
    return class'ScrnFunctions'.static.FormatTime(Level.Game.GameReplicationInfo.ElapsedTime);
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
    PlayInfo.AddSetting(default.BonusCapGroup,"MaxZombiesOnce","Max Specimens At Once",1,0, "Text", "4;8:254",,,True);

    PlayInfo.AddSetting(default.BonusCapGroup,"bSpawn0","Zero Cost of Initial Inventory",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickups","Replace Pickups",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplacePickupsStory","Replace Pickups (Story)",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceNades","Replace Grenades",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShieldWeight","Armor Has Weight",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bAltBurnMech","Alternate Burning Mechanism",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bShowDamages","Show Damages",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bReplaceHUD","Replace HUD",1,0, "Check");
    PlayInfo.AddSetting(default.BonusCapGroup,"bNoPerkChanges","No Perk Changes",1,0, "Check");

    PlayInfo.AddSetting(default.BonusCapGroup,"EventNum","Event", 0, 1, "Select", "0;Autodetect;4;Normal;1;Summer;2;Halloween;3;Xmas;254;Random",,,True);
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
        case "MaxZombiesOnce":              return "Maximum specimens at once on playtime, note that high values will LAG when theres a lot of them.";

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
    local int i, j;
    local string wave_status;

    super(Mutator).GetServerDetails(ServerState);

    if ( !bServerInfoVeterancy ) {
        for ( i=0; i<ServerState.ServerInfo.Length; ++i ) {
            if ( ServerState.ServerInfo[i].Key == "Veterancy" || Left(ServerState.ServerInfo[i].Key, 9) == "SP: Perk " )
                ServerState.ServerInfo.remove(i--, 1);
        }
    }

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.insert(i, 5 + Versions.length);

    ServerState.ServerInfo[i].Key = "ScrN Shared Lib";
    ServerState.ServerInfo[i++].Value = VersionStr(LibVersion());

    ServerState.ServerInfo[i].Key = "ScrN Balance";
    ServerState.ServerInfo[i++].Value = GetVersionStr();

    for ( j = 0; j < Versions.length; ++j ) {
        ServerState.ServerInfo[i].Key = Versions[j].item;
        ServerState.ServerInfo[i++].Value = VersionStr(Versions[j].v);
    }

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
    DynamicLevelCap();
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
    // if ( bManualReload )                    SrvFlags = SrvFlags | 0x00002000;
    // if ( bForceManualReload )               SrvFlags = SrvFlags | 0x00004000;
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
    // bManualReload                      = (SrvFlags & 0x00002000) > 0;
    // bForceManualReload                 = (SrvFlags & 0x00004000) > 0;
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

    // Fix missing textures
    class'Welder'.default.TraderInfoTexture = texture(class'Welder'.default.SelectedHudImage);
    class'Syringe'.default.TraderInfoTexture = texture(class'Syringe'.default.SelectedHudImage);
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

        ClientLink = spawn(class'ScrnCustomWeaponLink');
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

function bool SpawnBalanceRequired()
{
    return ScrnGT != none && (bTSCGame || ScrnGT.IsTourney());
}

function LoadSpawnInventory()
{
    local int i, j, index, k, skipped;
    local byte X;
    local string S, PickupStr, LevelStr, AmmoStr, SellStr;
    local int PerkIndex;
    local class<ScrnVeterancyTypes> ScrnPerk;
    local class<Pickup> Pickup;
    local bool bAllPerks;
    local bool bSpawnBalance;
    local name Ach;

    bSpawnBalance = SpawnBalanceRequired();

    // clear old inventory left from previous map
    for ( j=0; j<Perks.length; ++j )
        if ( Perks[j] != none )
            Perks[j].default.DefaultInventory.length = 0;

    for ( i=0; i<SpawnInventory.length; ++i ) {
        bAllPerks = false;
        LevelStr = "";
        AmmoStr = "";
        SellStr = "";
        Ach = '';
        X = 0;
        ++skipped;

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
            if ( !bSpawnBalance ) {
                // exclusion indexes are used only for achievement-related inventory
                X = int(Mid(S, j+1));
            }
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
                    Ach = StringToName(Mid(SellStr, j+1));
                    SellStr = Left(SellStr, j);
                }
            }
        }

        if ( bSpawnBalance ) {
            if ( Ach == 'TSC' ) {
                Ach = '';
            }
            else if ( Ach != '' ) {
                continue; // do not allow achievement-specific inventory in tournaments
            }
        }
        else if ( Ach == 'TSC' ) {
            continue;  // TSC and/or tournament item
        }

        Pickup = class<Pickup>(DynamicLoadObject(PickupStr, Class'Class'));
        if( Pickup == none ) {
            log("Can't load Spawn Inventory: '" $ PickupStr $"'!", 'ScrnBalance');
            continue;
        }

        index = ScrnPerk.default.DefaultInventory.length;
        ScrnPerk.default.DefaultInventory.insert(index, 1);
        --skipped;
        if ( X > skipped ) {
            X -= skipped;
        }
        else {
            X = 0;
        }
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
        ScrnPerk.default.DefaultInventory[index].Achievement = Ach;


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

        skipped = 0;
    }
}

// UE2 doesn't support direct string to name typecasting
// That's why need to use the following hack
final function name StringToName(string str)
{
    if ( str == "" )
        return '';
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
        ReplaceWith(Other, string(class'ScrnRandomItemSpawn'));
        return false;
    }
    else if ( Other.class == class'KFAmmoPickup' ) {
        AmmoBoxName = Other.name;
        AmmoBoxMesh = Other.StaticMesh;
        AmmoBoxDrawScale = Other.DrawScale;
        AmmoBoxDrawScale3D = Other.DrawScale3D;
        ReplaceWith(Other, string(class'ScrnAmmoPickup'));
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
        SetupMonster(KFMonster(Other));
    }
    else if ( SRStatsBase(Other) != none ) {
        SetupRepLink(SRStatsBase(Other).Rep);
    }
    else if ( Other.class == class'ScrnAmmoPickup' ) {
        ScrnAmmoPickup(Other).OriginalName = AmmoBoxName;
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

function SetupMonster(KFMonster M)
{
    if ( M.default.Health >= 1000 ) {
        // harder zapping
        if ( ZombieFleshPound(M) != none )
            M.ZapThreshold = 3.75;
        else
            M.ZapThreshold = 1.75;
    }
    GameRules.RegisterMonster(M);
}

function SetupRepLink(ClientPerkRepLink R)
{
    local ScrnClientPerkRepLink ScrnRep;
    local class<ScrnVeterancyTypes> Perk;
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
    // cannot go past level 70 to avoid int32 overflow
    ScrnRep.MaximumLevel = min(R.MaximumLevel, 70);
    ScrnRep.MinimumLevel = min(R.MinimumLevel, ScrnRep.MaximumLevel);
    ScrnRep.RequirementScaling = R.RequirementScaling;
    ScrnRep.CachePerks = R.CachePerks;
    // remove non-scrn perks
    for( i=0; i<ScrnRep.CachePerks.Length; ++i) {
        Perk = class<ScrnVeterancyTypes>(ScrnRep.CachePerks[i].PerkClass);
        if ( Perk == none || (bHardcore && !Perk.default.bHardcoreReady) )
            ScrnRep.CachePerks.remove(i--, 1);
    }

    ScrnRep.OwnerPC = ScrnPlayerController(R.Owner);
    ScrnRep.OwnerPRI = KFPlayerReplicationInfo(ScrnRep.OwnerPC.PlayerReplicationInfo);
    log("Creating ScrnClientPerkRepLink for player " $ ScrnRep.OwnerPRI.PlayerName, 'ScrnBalance');

    R.GotoState('');
    R.Destroy();
    R = ScrnRep;

    class'ScrnAchCtrl'.static.InitLink(ScrnRep);

    if ( LockManager != none && LockManager.GetDLCDLCLockCount() > 0 ) {
        ScrnRep.Locks.Length = LockManager.GetDLCDLCLockCount();
        for( i = 0; i < LockManager.DLCLocks.Length; ++i) {
            if ( LockManager.DLCLocks[i].PickupClass != none
                    && (bUseDLCLevelLocks || LockManager.DLCLocks[i].Type != LOCK_Level) )
            {
                ScrnRep.Locks[j].PickupClass = LockManager.DLCLocks[i].PickupClass;
                ScrnRep.Locks[j].Group       = LockManager.DLCLocks[i].Group;
                ScrnRep.Locks[j].Type        = LockManager.DLCLocks[i].Type;
                ScrnRep.Locks[j].ID          = LockManager.DLCLocks[i].ID;
                ScrnRep.Locks[j].MaxProgress = LockManager.DLCLocks[i].Value;
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
    ScrnRep.TotalZeds = ScrnRep.Zeds.Length;
    ScrnRep.TotalLocks = ScrnRep.Locks.Length;
    ScrnRep.TotalChars = ScrnRep.CustomChars.Length;
}

function ForceEvent()
{
    local class<KFMonstersCollection> MC;

    if (ScrnGT != none && ScrnGT.ZedEventNum > 0) {
        CurrentEventNum = ScrnGT.ZedEventNum;
    }
    else {
        CurrentEventNum = EventNum;
        if ( EventNum == 0 && MapInfo.ZedEventNum > 0 ) {
            CurrentEventNum = MapInfo.ZedEventNum;
        }
    }

    if (bScrnWaves) {
        return;  // all we need for ScrnWaves is to load CurrentEventNum. ScrnGameLength will handle everything else.
    }

    switch ( CurrentEventNum ) {
        case ZEDEVENT_RANDOM:  // random event
            CurrentEventNum = 1 + rand(4);
            break;
        case 255:
            CurrentEventNum = 4;  // force regular zeds
            break;
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
                log("Custom ZED Event Number: "$CurrentEventNum, 'ScrnBalance');
                CurrentEventNum = EventNum;
                return;
        }
    }
    KF.SpecialEventMonsterCollections[KF.GetSpecialEventType()] = KF.MonsterCollection;
    class'ScrnGameRules'.static.ResetGameSquads(KF, CurrentEventNum);
    KF.PrepareSpecialSquads();
    KF.LoadUpMonsterList();
}

function SetMaxZombiesOnce(optional int value)
{
    if ( value < 16 ) {
        if ( MapInfo.MaxZombiesOnce >= 16 )
            value = MapInfo.MaxZombiesOnce;
        else
            value = MaxZombiesOnce;
    }

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
    local string s;

    if ( bLogObjectsAtMapStart )
        LogObjects();

    super.PostBeginPlay();
    if ( bDeleteMe )
        return;

    // CHECK & LOAD SERVERPERKS
    if ( FindServerPerksMut() == none ) {
        log("Loading ServerPerksMut...", 'ScrnBalance');
        Level.Game.AddMutator(ServerPerksPkgName, false);
        //check again
        if ( FindServerPerksMut() == none ) {
            warn("Unable to spawn " $ ServerPerksPkgName);
            Level.Game.AddMutator("ScrnSP.ServerPerksMutSE", false);
        }
        if ( FindServerPerksMut() == none ) {
            warn("ServerPerksMut is required for ScrnBalance");
            Destroy();
            return;
        }
    }
    if ( Mut != none && Mut != self )
        Mut.Destroy();
    Mut = self;
    default.Mut = self;
    class'ScrnBalance'.default.Mut = self; // in case of classes extended from ScrnBalance
    // prematurely add myself to mutator chain, otherwise AutoLoadMutators won't find me in their PostBeginPlay()
    ServerPerksMut.AddMutator(self);

    KF.MonsterCollection = KF.SpecialEventMonsterCollections[KF.GetSpecialEventType()]; // v1061 fix
    KF.bUseZEDThreatAssessment = true; // always use ScrnHumanPawn.AssessThreatTo()
    bStoryMode = KFStoryGameInfo(KF) != none;
    bTSCGame = TSCGame(KF) != none && !TSCGame(KF).bSingleTeamGame;
    if ( bTSCGame ) {
        bScrnWaves = true;
    }
    ScrnGT = ScrnGameType(KF);
    if ( ScrnGT != none ) {
        ScrnGT.ScrnBalanceMut = self;
        MaxDifficulty = ScrnGT.DIFF_MAX;
    }
    else if ( ScrnStoryGameInfo(KF) != none ) {
        ScrnStoryGameInfo(KF).ScrnBalanceMut = self;
    }

    bUseAchievements = bool(AchievementFlags & ACH_ENABLE);
    GameRules = Spawn(Class'ScrnGameRules');
    GameRules.Mut = self;
    GameRules.bShowDamages = bShowDamages;
    GameRules.bUseAchievements = bUseAchievements && KF.GameDifficulty >= 2;
    if ( GameRules.bUseAchievements ) {
        // spawn achievement handlers
        AchHandler = GameRules.Spawn(Class'ScrnAchHandler');
    }

    MapName = KF.GetCurrentMapName(Level);
    OriginalMapName = GameRules.GetOriginalMapName(MapName);
    s = caps(MapName);
    MapInfo = new(none, OriginalMapName) class'ScrnMapInfo';
    MapInfo.Mut = self;

    if ( bForceEvent || (ScrnGT != none && ScrnGT.ZedEventNum > 0) )
        ForceEvent();
    else
        CurrentEventNum = int(KF.GetSpecialEventType()); // autodetect event

    if ( bResetSquadsAtStart || (EventNum == ZEDEVENT_RANDOM && !bScrnWaves) ) {
        GameRules.ResetGameSquads(KF, CurrentEventNum);
    }

    AddToPackageMap("ScrnAnims.ukx");
    AddToPackageMap("ScrnSM.usx");
    AddToPackageMap("ScrnSnd.uax");
    AddToPackageMap("ScrnShared.u");

    if ( bStoryMode ) {
        bTraderSpeedBoost = false;
    }
    else {
        SetMaxZombiesOnce();
    }

    if ( MapInfo.bTestMap )
        SetTestMap();

    if ( !ClassIsChildOf(KF.PlayerControllerClass, class'ScrnPlayerController') ) {
        KF.PlayerControllerClass = class'ScrnPlayerController';
        KF.PlayerControllerClassName = string(Class'ScrnPlayerController');
    }

    if ( ScrnGT == none && ScrnStoryGameInfo(KF) == none ) {
        if ( bReplaceHUD )
            KF.HUDType = string(Class'ScrnHUD');

        if ( bReplaceScoreBoard )
            Level.Game.ScoreBoardType = string(Class'ScrnScoreBoard');
    }
    KF.LoginMenuClass = string(Class'ScrnInvasionLoginMenu');

    Persistence = new class'ScrnBalancePersistence';
    bRandomMap = Persistence.bRandomMap;
    Persistence.bRandomMap = false;
    if ( Persistence.Difficulty > 0 ) {
        KF.GameDifficulty = Persistence.Difficulty;
    }
    SetGameDifficulty(KF.GameDifficulty);

    SetReplicationData();
    //exec this on server side only
    ApplySpawnBalance();
    ApplyWeaponFix();

    if (bAltBurnMech) {
        BurnMech = spawn(class'ScrnBurnMech');
    }

    if ( bAllowVoting ) {
        VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Level.Game);
        if ( VH == none ) {
            Level.Game.AddMutator(string(class'ScrnVotingHandlerMut'), false);
            VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Level.Game);
        }
        if ( VH != none ) {
            MyVotingOptions = ScrnBalanceVoting(VH.AddVotingOptions(class'ScrnBalanceVoting'));
            if ( MyVotingOptions != none ) {
                MyVotingOptions.Mut = self;
            }
        }
        else {
            log("Unable to spawn voting handler mutator", 'ScrnBalance');
        }
        PauseTimeRemaining = MaxPauseTimePerWave;
    }

    LoadCustomWeapons();
    if ( bUseDLCLocks && !SpawnBalanceRequired() ) {
        LockManager = spawn(class'ScrnLock');
        LockManager.LoadDLCLocks(bUseDLCLevelLocks);
    }
    else {
        log("DLC Locks disabled", 'ScrnBalance');
    }
    InitSettings();
    LoadSpawnInventory();
    SetupSrvInfo();

    if ( bStoryMode ) {
        class'ScrnAchCtrl'.static.RegisterAchievements(class'AchObjMaps');
    }

    Log(FriendlyName @ GetVersionStr()$" loaded", 'ScrnBalance');

    for ( i=0; i<AutoLoadMutators.length; ++i ) {
        if ( AutoLoadMutators[i] != "" )  {
            Log("Loading additional mutator: " $ AutoLoadMutators[i], 'ScrnBalance');
            KF.AddMutator(AutoLoadMutators[i], true);
        }
    }
}

function SetTestMap()
{
    bTestMap = true;
    ServerPerksMut.GotoState('TestMap');
    bAllowAlwaysPerkChanges = true;
    bNoPerkChanges = false;
}

function ChangeGameDifficulty(byte NewDifficulty, optional bool bForce)
{
    // save difficulty for the next map
    Mut.Persistence.Difficulty = NewDifficulty;
    Mut.Persistence.SaveConfig();

    if ( bForce && NewDifficulty > 0 && ScrnGT != none )
    {
        // mid-game difficulty change
        SetGameDifficulty(NewDifficulty);
    }
}

function byte GetHardcoreDifficulty()
{
    return byte(KF.GameDifficulty + 0.1) + byte(bHardcore);
}

function SetGameDifficulty(byte HardcoreDifficulty)
{
    local KFGameReplicationInfo KFGRI;
    local bool bNewHardcore;
    local byte Difficulty;

    switch (HardcoreDifficulty) {
        case 1:
        case 2:
        case 4:
        case 5:
        case 7:
            bNewHardcore = false;
            Difficulty = HardcoreDifficulty;
            break;

        case 6:
        case 8:
            bNewHardcore = true;
            Difficulty = HardcoreDifficulty - 1;
            break;

        default:
            log("Bad difficulty value: " $ Difficulty, 'ScrnBalance');
            return;
    }

    if ( ScrnGT != none ) {
        if ( ScrnGT.ScrnGameLength != none && !ScrnGT.ScrnGameLength.ApplyGameDifficulty(HardcoreDifficulty) )
            return;
        ScrnGT.BaseDifficulty = Difficulty;
    }
    bHardcore = bNewHardcore;
    KF.GameDifficulty = Difficulty;
    KFGRI = KFGameReplicationInfo(KF.GameReplicationInfo);
    if ( KFGRI != none ) {
        KFGRI.BaseDifficulty = Difficulty;  // only initial replication
        KFGRI.GameDiff = Difficulty;  // only initial replication
        if ( ScrnGT != none ) {
            ScrnGT.ScrnGRI.NewDifficulty = Difficulty;  // dirty replication
        }
    }
    if ( bHardcore ) {
        log("Game difficulty: " $ string(KF.GameDifficulty) $ " + Hardcore", 'ScrnBalance');
    }
    else {
        log("Game difficulty: " $ string(KF.GameDifficulty) $ "", 'ScrnBalance');
    }

    if ( GameRules != none ) {
        GameRules.InitHardcoreLevel();
    }
    SetLevels();
    SetStartCash();
    SetReplicationData();
}

function SetupSrvInfo()
{
    if ( SrvInfo == none )
        SrvInfo = Spawn(Class'ScrnSrvReplInfo');

    SrvInfo.bForceSteamNames = bForceSteamNames;
}

function FixShops()
{
    local int i, j;
    local ShopVolume Shop;
    local WeaponLocker Trader;
    local array<WeaponLocker> Traders;
    local float Dist, BestDist;

    foreach DynamicActors(class'WeaponLocker', Trader) {
        Traders[Traders.length] = Trader;
    }

    if ( Traders.length == 0 ) {
        log("Map does not have WeaponLockers (Traders)", 'ScrnBalance');
        return;
    }

    for ( i = 0; i < KF.ShopList.Length; ++i) {
        Shop = KF.ShopList[i];
        // First pass: look for WeaponLocker inside the shop
        if ( Shop.MyTrader == none ) {
            for ( j = 0; j < Traders.length; ++j ) {
                Trader = Traders[j];
                if ( Shop.Encompasses(Trader) ) {
                    Shop.MyTrader = Trader;
                    log("Fixed " $ Shop.name $ ".MyTrader=" $ Trader.name);
                    break;
                }
            }
        }
        // Second pass: Find the closest weapon locker
        if ( Shop.MyTrader == none ) {
            Trader = Traders[0];
            BestDist = VSizeSquared(Trader.Location - Shop.Location);
            for ( j = 1; j < Traders.length; ++j ) {
                Dist = VSizeSquared(Traders[j].Location - Shop.Location);
                if ( Dist < BestDist ) {
                    Trader = Traders[j];
                    BestDist = Dist;
                }
            }
            Shop.MyTrader = Trader;
            log("Used closest " $ Shop.name $ ".MyTrader=" $ Trader.name);
        }
    }
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

function KFDoorMover FindDoorByName(name n)
{
    local KFUseTrigger key;
    local KFDoorMover door;
    local int i, j;

    if ( n == '' )
        return none;

    for ( i = 0; i < DoorKeys.length; ++i ) {
        key = DoorKeys[i];
        for ( j = 0; j < key.DoorOwners.Length; ++j ) {
            door = key.DoorOwners[j];
            if ( door.name == n ) {
                return door;
            }
        }
    }
    return none;
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

    // pickupReplaceArray contains only KFMod items, so no need to cycle the entire array too look for items
    // that cannot be there, such as ScrN or custom weapons
    if ( item.class.outer.name != 'KFMod' )
        return -1;

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
    local string NewMapName, Options;
    local KFGameReplicationInfo KFGRI;
    local bool bMapRestart;

    KFGRI = KFGameReplicationInfo(Level.GRI);
    bMapRestart = URL ~= "?restart";

    log("******************** SERVER TRAVEL ********************", 'ScrnBalance');
    Divide(URL, "?", NewMapName, Options);
    Options = "?" $ Options;  // Options must start with "?", option parsing routines won't work
    if ( bMapRestart ) {
        log("MAP RESTART", 'ScrnBalance');
    }
    else {
        log("New Map: " $ NewMapName, 'ScrnBalance');
        log("Options: " $ Options, 'ScrnBalance');
    }

    if ( Persistence.Difficulty > 0 && KF.HasOption(Options, "Difficulty") ) {
        log("URL contains Difficulty. Disabling MVOTE DIFF.", 'ScrnBalance');
        Persistence.Difficulty = 0;
    }
    if ( KFGRI != none ) {
        Persistence.LastEndGameType = KFGRI.EndGameType;
    }
    else {
        Persistence.LastEndGameType = 0;
    }
    if ( !bMapRestart ) {
        Persistence.bRandomMapBonus = !bTSCGame && Persistence.LastEndGameType == 2;
    }
    Persistence.SaveConfig();

    if ( bLogObjectsAtMapEnd )
        LogObjects();

    if (NextMutator != None)
        NextMutator.ServerTraveling(URL,bItems);

    if ( ScrnGT == none || ScrnGT.ScrnGameLength == none )
        class'ScrnGameRules'.static.ResetGameSquads(KF, CurrentEventNum);
    class'ScrnAchCtrl'.static.Cleanup();

    if ( Level.NetMode == NM_DedicatedServer ) {
        // break links to self
        Mut = none;
        default.Mut = none;
        class'ScrnBalance'.default.Mut = none;
    }

    for ( j=0; j<Perks.length; ++j ) {
        if ( Perks[j] != none ) {
            Perks[j].default.DefaultInventory.length = 0;
            Perks[j].default.bLocked = false;
        }
    }

    DestroyLinkedInfo(CustomWeaponLink);
    CustomWeaponLink = none;

    // destroy local objects
    if ( MapInfo != none ) {
        MapInfo.Mut = none;
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
    if ( LockManager != none ) {
        LockManager.Destroy();
        LockManager = none;
    }
}

// Limits placed pipebomb count to perk's capacity
function DestroyExtraPipebombs()
{
    local ScrnPipeBombProjectile P;
    local KFPlayerReplicationInfo KFPRI;
    local array<KFPlayerReplicationInfo> KFPRIArray;
    local array<byte> PipeBombCapacity;
    local array<SActors> Pipebombs;
    local int i, c;

    foreach DynamicActors(Class'ScrnPipeBombProjectile', P) {
        if( !P.bHidden && P.Instigator != none && P.bDetectEnemies ) {
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
                Pipebombs.insert(i, 1);
            }

            c = Pipebombs[i].Actors.length;
            if (c >= PipeBombCapacity[i]) {
                // blow up the oldest pipebomb
                ScrnPipeBombProjectile(Pipebombs[i].Actors[0]).bEnemyDetected = true;
                Pipebombs[i].Actors.remove(0, 1);
                --c;
            }
            Pipebombs[i].Actors[c] = P;
        }
    }
}

function BlamePlayer(ScrnPlayerController PC, string Reason, optional int BlameInc)
{
    local ScrnCustomPRI ScrnPRI;
    local ScrnHumanPawn ScrnPawn;

    if ( PC == none )
        return;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PC.PlayerReplicationInfo);
    if ( ScrnPRI == none )
        return;
    ScrnPawn = ScrnHumanPawn(PC.Pawn);
    BlameCounter++;

    if ( BlameInc == 0 )
        BlameInc = 1;
    ScrnPRI.BlameCounter += BlameInc;
    if ( ScrnPRI.BlameCounter == 5 )
        class'ScrnAchCtrl'.static.Ach2Player(PC, 'MaxBlame');

    PC.ReceiveLocalizedMessage(class'ScrnBlamedMsg', ScrnPRI.BlameCounter);

    if ( Reason != "" ) {
        Reason = Repl(Reason, "%p", Mut.ColoredPlayerName(PC.PlayerReplicationInfo), true);
        BroadcastMessage(ColorString(Reason, 200, 200, 1), false);
    }

    if ( bBlameFart && ScrnPawn != none && ScrnGT != none && !ScrnGT.IsTourney() && !bTSCGame
            && Level.TimeSeconds - PC.LastBlamedTime > 60.0 ) {
        ScrnPawn.Fart(ScrnPRI.BlameCounter);
        ScrnPawn.Crap(10 * ScrnPRI.BlameCounter);
        ScrnPawn.ForceThreatLevel(0.01 + frand(), 15.0);
    }
    PC.LastBlamedTime = Level.TimeSeconds;
}


function bool IsScrnAuthority()
{
    return true;
}

function RegisterVersion(string ItemName, int Version)
{
    local int i;

    if ( Version == 0 ) {
        warn(ItemName $ " has no version");
        return;
    }

    log(ItemName @ VersionStr(Version), 'ScrnBalance');

    for ( i = 0; i < Versions.length; ++i ) {
        if ( Versions[i].item ~= ItemName ) {
            if ( Versions[i].v != Version ) {
                warn(ItemName $ " is already registered but versions differ: " $ VersionStr(Versions[i].v)  $ " <> "
                        $ VersionStr(Version));
            }
            return;
        }
    }
    Versions.insert(i, 1);
    Versions[i].item = ItemName;
    Versions[i].v = Version;
}


defaultproperties
{
    VersionNumber=96925
    GroupName="KF-Scrn"
    FriendlyName="ScrN Balance"
    Description="Total rework of KF1 to make it modern and the best game in the world while sticking to the roots of the original."

    // TODO: Mutator should exist server-side only. Move client stuff to ScrnSrvReplInfo.
    bAddToServerPackages=true
    bAlwaysRelevant=true
    bOnlyDirtyReplication=false
    RemoteRole=ROLE_SimulatedProxy
    bNetNotify=true

    BonusCapGroup="ScrnBalance"
    strBonusLevel="Your effective perk bonus level is [%s]"
    strStatus="Your perk level: Visual=%v, Effective=[%b]. Server perk range is [%n..%x]."
    strStatus2="Alt.Burn=%a. MaxZombiesOnce=%m."
    strBetaOnly="Only avaliable during Beta testing (bBeta=true)"
    strXPInitial="^G$Initial Perk Stats:"
    strXPProgress="^G$Perk Progression:"
    strXPBonus="^G$XP Bonus for winning: ^c$"
    strOnlyAdmin="Requires ADMIN priviledges"
    strOnlyScrnGT="Avaliable in ScrnGameType only!"
    strOnlyNotInTourney="Not Available in TOURNEY mode"

    Perks(0)=class'ScrnVetFieldMedic'
    Perks(1)=class'ScrnVetSupportSpec'
    Perks(2)=class'ScrnVetSharpshooter'
    Perks(3)=class'ScrnVetCommando'
    Perks(4)=class'ScrnVetBerserker'
    Perks(5)=class'ScrnVetFirebug'
    Perks(6)=class'ScrnVetDemolitions'
    Perks(7)=class'ScrnVeterancyTypes' // off-perk
    Perks(8)=class'ScrnVetGunslinger'
    Perks(9)=class'ScrnVetCombatMedic'

    BonusLevelNormalMax=6
    BonusLevelHardMin=0
    BonusLevelHardMax=6
    BonusLevelSuiMin=5
    BonusLevelSuiMax=6
    BonusLevelHoeMin=6
    BonusLevelHoeMax=6
    bDynamicLevelCap=true
    b10Stars=false
    bNoPerkChanges=false
    bPerkChangeBoss=false
    bPerkChangeDead=false
    bBuyPerkedWeaponsOnly=false
    bPickPerkedWeaponsOnly=false

    bSpawn0=true
    bMedicRewardFromTeam=true
    bLeaveCashOnDisconnect=true
    bNoStartCashToss=false
    StartCashNormal=100
    StartCashHard=100
    StartCashSui=100
    StartCashHoE=100
    MinRespawnCashNormal=100
    MinRespawnCashHard=100
    MinRespawnCashSui=100
    MinRespawnCashHoE=100

    bScrnWaves=true
    MaxWaveSize=500
    MaxZombiesOnce=48
    MinZedSpawnPeriod=2.0
    bZedFights=true
    EventNum=0
    bForceEvent=true
    bResetSquadsAtStart=false

    ForcedMaxPlayers=0
    bBroadcastPickups=true
    BroadcastPickupText="%p picked up %o's %w ($%$)."
    bAllowWeaponLock=true
    bAutoKickOffPerkPlayers=true
    strAutoKickOffPerk="You have been auto kicked from the server for playing without a perk. Type RECONNECT in the console to join the server again and choose a perk."
    bNoTeamSkins=false
    bForceSteamNames=true
    bPlayerZEDTime=true
    bShowDamages=true
    bAllowBehindView=true

    bReplacePickups=true
    bReplacePickupsStory=true
    bAltBurnMech=true
    bReplaceNades=true
    bShieldWeight=true
    pickupReplaceArray(0)=(oldClass=Class'KFMod.MP7MPickup',NewClass=class'ScrnMP7MPickup')
    pickupReplaceArray(1)=(oldClass=Class'KFMod.MP5MPickup',NewClass=class'ScrnMP5MPickup')
    pickupReplaceArray(2)=(oldClass=Class'KFMod.KrissMPickup',NewClass=class'ScrnKrissMPickup')
    pickupReplaceArray(3)=(oldClass=Class'KFMod.M7A3MPickup',NewClass=class'ScrnM7A3MPickup')
    pickupReplaceArray(4)=(oldClass=Class'KFMod.ShotgunPickup',NewClass=class'ScrnShotgunPickup')
    pickupReplaceArray(5)=(oldClass=Class'KFMod.BoomStickPickup',NewClass=class'ScrnBoomStickPickup')
    pickupReplaceArray(6)=(oldClass=Class'KFMod.NailGunPickup',NewClass=class'ScrnNailGunPickup')
    pickupReplaceArray(7)=(oldClass=Class'KFMod.KSGPickup',NewClass=class'ScrnKSGPickup')
    pickupReplaceArray(8)=(oldClass=Class'KFMod.BenelliPickup',NewClass=class'ScrnBenelliPickup')
    pickupReplaceArray(9)=(oldClass=Class'KFMod.AA12Pickup',NewClass=class'ScrnAA12Pickup')
    pickupReplaceArray(10)=(oldClass=Class'KFMod.SinglePickup',NewClass=class'ScrnSinglePickup')
    pickupReplaceArray(11)=(oldClass=Class'KFMod.Magnum44Pickup',NewClass=class'ScrnMagnum44Pickup')
    pickupReplaceArray(12)=(oldClass=Class'KFMod.MK23Pickup',NewClass=class'ScrnMK23Pickup')
    pickupReplaceArray(13)=(oldClass=Class'KFMod.DeaglePickup',NewClass=class'ScrnDeaglePickup')
    pickupReplaceArray(14)=(oldClass=Class'KFMod.WinchesterPickup',NewClass=class'ScrnWinchesterPickup')
    pickupReplaceArray(15)=(oldClass=Class'KFMod.SPSniperPickup',NewClass=class'ScrnSPSniperPickup')
    pickupReplaceArray(16)=(oldClass=Class'KFMod.M14EBRPickup',NewClass=class'ScrnM14EBRPickup')
    pickupReplaceArray(17)=(oldClass=Class'KFMod.M99Pickup',NewClass=class'ScrnM99Pickup')
    pickupReplaceArray(18)=(oldClass=Class'KFMod.BullpupPickup',NewClass=class'ScrnBullpupPickup')
    pickupReplaceArray(19)=(oldClass=Class'KFMod.AK47Pickup',NewClass=class'ScrnAK47Pickup')
    pickupReplaceArray(20)=(oldClass=Class'KFMod.M4Pickup',NewClass=class'ScrnM4Pickup')
    pickupReplaceArray(21)=(oldClass=Class'KFMod.SPThompsonPickup',NewClass=class'ScrnSPThompsonPickup')
    pickupReplaceArray(22)=(oldClass=Class'KFMod.ThompsonDrumPickup',NewClass=class'ScrnThompsonDrumPickup')
    pickupReplaceArray(23)=(oldClass=Class'KFMod.SCARMK17Pickup',NewClass=class'ScrnSCARMK17Pickup')
    pickupReplaceArray(24)=(oldClass=Class'KFMod.FNFAL_ACOG_Pickup',NewClass=class'ScrnFNFAL_ACOG_Pickup')
    pickupReplaceArray(25)=(oldClass=Class'KFMod.MachetePickup',NewClass=class'ScrnMachetePickup')
    pickupReplaceArray(26)=(oldClass=Class'KFMod.AxePickup',NewClass=class'ScrnAxePickup')
    pickupReplaceArray(27)=(oldClass=Class'KFMod.ChainsawPickup',NewClass=class'ScrnChainsawPickup')
    pickupReplaceArray(28)=(oldClass=Class'KFMod.KatanaPickup',NewClass=class'ScrnKatanaPickup')
    pickupReplaceArray(29)=(oldClass=Class'KFMod.ScythePickup',NewClass=class'ScrnScythePickup')
    pickupReplaceArray(30)=(oldClass=Class'KFMod.ClaymoreSwordPickup',NewClass=class'ScrnClaymoreSwordPickup')
    pickupReplaceArray(31)=(oldClass=Class'KFMod.CrossbuzzsawPickup',NewClass=class'ScrnCrossbuzzsawPickup')
    pickupReplaceArray(32)=(oldClass=Class'KFMod.MAC10Pickup',NewClass=class'ScrnMAC10Pickup')
    pickupReplaceArray(33)=(oldClass=Class'KFMod.FlareRevolverPickup',NewClass=class'ScrnFlareRevolverPickup')
    pickupReplaceArray(34)=(oldClass=Class'KFMod.DualFlareRevolverPickup',NewClass=class'ScrnDualFlareRevolverPickup')
    pickupReplaceArray(35)=(oldClass=Class'KFMod.FlameThrowerPickup',NewClass=class'ScrnFlameThrowerPickup')
    pickupReplaceArray(36)=(oldClass=Class'KFMod.HuskGunPickup',NewClass=class'ScrnHuskGunPickup')
    pickupReplaceArray(37)=(oldClass=Class'KFMod.PipeBombPickup',NewClass=class'ScrnPipeBombPickup')
    pickupReplaceArray(38)=(oldClass=Class'KFMod.M4203Pickup',NewClass=class'ScrnM4203Pickup')
    pickupReplaceArray(39)=(oldClass=Class'KFMod.M32Pickup',NewClass=class'ScrnM32Pickup')
    pickupReplaceArray(40)=(oldClass=Class'KFMod.LAWPickup',NewClass=class'ScrnLAWPickup')
    pickupReplaceArray(41)=(oldClass=Class'KFMod.Dual44MagnumPickup',NewClass=class'ScrnDual44MagnumPickup')
    pickupReplaceArray(42)=(oldClass=Class'KFMod.DualMK23Pickup',NewClass=class'ScrnDualMK23Pickup')
    pickupReplaceArray(43)=(oldClass=Class'KFMod.DualDeaglePickup',NewClass=class'ScrnDualDeaglePickup')
    pickupReplaceArray(44)=(oldClass=Class'KFMod.SyringePickup',NewClass=class'ScrnSyringePickup')
    pickupReplaceArray(45)=(oldClass=Class'KFMod.FragPickup',NewClass=class'ScrnFragPickup')
    pickupReplaceArray(46)=(oldClass=Class'KFMod.M79Pickup',NewClass=class'ScrnM79Pickup')
    pickupReplaceArray(47)=(oldClass=Class'KFMod.CrossbowPickup',NewClass=class'ScrnCrossbowPickup')
    pickupReplaceArray(48)=(oldClass=Class'KFMod.KnifePickup',NewClass=class'ScrnKnifePickup')
    FragReplacementIndex=45

    SpawnInventory(00)="*:ScrnBalanceSrv.ScrnKnifePickup:0-255::0"
    SpawnInventory(01)="*:ScrnBalanceSrv.ScrnSyringePickup:0-255::0"
    SpawnInventory(02)="*:KFMod.WelderPickup:0-255::0"
    SpawnInventory(03)="*:ScrnBalanceSrv.ScrnSinglePickup:0-255::0"
    SpawnInventory(04)="*:ScrnBalanceSrv.ScrnFragPickup:0-255:2:0"
    SpawnInventory(05)="0:ScrnBalanceSrv.ScrnCombatVestPickup:0-255:100"
    SpawnInventory(06)="0:ScrnBalanceSrv.ScrnMP7MPickup:0-255:80+20:150"
    SpawnInventory(07)="0:ScrnBalanceSrv.ScrnM79MPickup:0-255:3:0:OnlyHealer"
    SpawnInventory(08)="0:ScrnBalanceSrv.ScrnM79MAmmoPickup:0-255:1:0:ExplosionLove"
    SpawnInventory(09)="0:ScrnBalanceSrv.ScrnM79MAmmoPickup:0-255:1:0:TouchOfSavior"
    SpawnInventory(10)="1:ScrnBalanceSrv.ScrnShotgunPickup:0-255:24+4:150"
    SpawnInventory(11)="1:ScrnBalanceSrv.ScrnBoomStickPickup:0-255:12:0:TW_SC_LAWHSG"
    SpawnInventory(12)="1:ScrnBalanceSrv.ScrnBoomStickPickup:0-255:12:0:EvilDeadCombo"
    SpawnInventory(13)="1:KFMod.DBShotgunAmmoPickup:0-255:12::GetOffMyLawn"
    SpawnInventory(14)="1:KFMod.DBShotgunAmmoPickup:0-255:12::TW_Husk_Stun"
    SpawnInventory(15)="1:ScrnBalanceSrv.ScrnNailGunPickup:0-255:150:0:Nail250Zeds"
    SpawnInventory(16)="2:ScrnBalanceSrv.ScrnWinchesterPickup:0-255:30+5:150"
    SpawnInventory(17)="2:ScrnBalanceSrv.ScrnM14EBRPickup:0-255:40+5:0:DotOfDoom"
    SpawnInventory(18)="2-1:ScrnBalanceSrv.ScrnSPSniperPickup:0-255:20+5:0:SteampunkSniper"
    SpawnInventory(19)="2-1:ScrnBalanceSrv.ScrnMagnum44Pickup:0-255:18+2:0:Impressive"
    SpawnInventory(20)="3:ScrnBalanceSrv.ScrnAK47Pickup:0-255:90+30:150:Accuracy"
    SpawnInventory(21)="3:ScrnBalanceSrv.ScrnAK47Pickup:0-255:90+30:150:OutOfTheGum"
    SpawnInventory(22)="3:ScrnBalanceSrv.ScrnAK47Pickup:0-255:90+30:150:OP_Commando"
    SpawnInventory(23)="3-3:ScrnBalanceSrv.ScrnBullpupPickup:0-255:160+40:150"
    SpawnInventory(24)="3:ScrnBalanceSrv.ScrnSPThompsonPickup:0-255:300:150:OldGangster"
    SpawnInventory(25)="4:ScrnBalanceSrv.ScrnKatanaPickup:0-255::0:MeleeGod"
    SpawnInventory(26)="4:ScrnBalanceSrv.ScrnChainsawPickup:0-255:400+25:150:EvilDeadCombo"
    SpawnInventory(27)="4:ScrnBalanceSrv.ScrnChainsawPickup:0-255:400+25:150:BitterIrony"
    SpawnInventory(28)="4-2:ScrnBalanceSrv.ScrnAxePickup:0-255::150"
    SpawnInventory(29)="5:ScrnBalanceSrv.ScrnThompsonIncPickup:0-255:50+10:150:TW_Shiver"
    SpawnInventory(30)="5:ScrnBalanceSrv.ScrnThompsonIncPickup:0-255:50+10:150:OP_Firebug"
    SpawnInventory(31)="5-2:ScrnBalanceSrv.ScrnMAC10Pickup:0-255:120+30:150"
    SpawnInventory(32)="5:ScrnBalanceSrv.ScrnFlareRevolverPickup:0-255:12+2:0:iDoT"
    SpawnInventory(33)="5:KFMod.FragAmmoPickup:0-255:2:0:NapalmStrike"
    SpawnInventory(34)="5:KFMod.FragAmmoPickup:0-255:2:0:HuskGunSC"
    SpawnInventory(35)="6:ScrnBalanceSrv.ScrnM4203Pickup:0-255:60+15:150"
    SpawnInventory(36)="6:KFMod.M203AmmoPickup:1-255:1+1"
    SpawnInventory(37)="6:ScrnBalanceSrv.ScrnM79Pickup:0-255:3+1:0:RocketBlow"
    SpawnInventory(38)="6:KFMod.FragAmmoPickup:0-255:2:0:TW_PipeBlock"
    SpawnInventory(39)="6:KFMod.FragAmmoPickup:0-255:2:0:TW_FP_Pipe"
    SpawnInventory(40)="6:KFMod.FragAmmoPickup:0-255:2:0:MindBlowingSacrifice"
    SpawnInventory(41)="8:ScrnBalanceSrv.ScrnDual44MagnumPickup:0-255:36+12:150"
    SpawnInventory(42)="8:ScrnBalanceSrv.ScrnDualiesPickup:0-255:90+15:150:MadCowboy"
    SpawnInventory(43)="8:KFMod.Vest:0-255:25:0:TrueCowboy"
    SpawnInventory(44)="9:ScrnBalanceSrv.ScrnMP7MPickup:0-255:160+40:150"
    SpawnInventory(45)="9:ScrnBalanceSrv.ScrnKatanaPickup:0-255::0:MeleeKillMidairCrawlers"
    SpawnInventory(46)="9-1:ScrnBalanceSrv.ScrnKatanaPickup:0-255::0:TW_BackstabSC"
    SpawnInventory(47)="9:ScrnBalanceSrv.ScrnCombatVestPickup:0-255:50:CombatMedic"
    SpawnInventory(48)="*:ScrnBalanceSrv.ScrnMachetePickup:0-255::0:ComeatMe"
    SpawnInventory(49)="*-1:ScrnBalanceSrv.ScrnMachetePickup:0-255::0:Friday13"
    SpawnInventory(50)="*-2:ScrnBalanceSrv.ScrnMachetePickup:0-255::0:ThinIcePirouette"
    SpawnInventory(51)="*-3:ScrnBalanceSrv.ScrnMachetePickup:0-255::0:MacheteKillMidairCrawler"
    SpawnInventory(52)="*:ScrnBalanceSrv.ScrnAxePickup:0-255::0:OldSchoolKiting"
    SpawnInventory(53)="*:KFMod.FragAmmoPickup:0-255:50:0:ScrakeNader"
    SpawnInventory(54)="*:KFMod.CashPickup:0-255:50:0:MilkingCow"
    SpawnInventory(55)="*:KFMod.CashPickup:0-255:50:0:SavingResources"
    SpawnInventory(56)="*:KFMod.CashPickup:0-255:1+1:0:SpareChange"
    bNoRequiredEquipment=true
    bUseExpLevelForSpawnInventory=true
    bUseDLCLocks=false
    bUseDLCLevelLocks=true

    bBeta=false
    bReplaceHUD=true
    bReplaceScoreBoard=true
    ServerPerksPkgName="ScrnSP.ServerPerksMutSE"
    bServerInfoVeterancy=true
    bFixMusic=true
    bRespawnDoors=false

    AchievementFlags=255
    bSaveStatsOnAchievementEarned=false
    bBroadcastAchievementEarn=true
    strAchEarn="%p earned an achievement: %a"
    EndGameStatBonus=0.5
    bStatBonusUsesHL=true
    StatBonusMinHL=0
    FirstStatBonusMult=2.0
    RandomMapStatBonus=2.0

    SkippedTradeTimeMult=0.75
    TraderTimeNormal=60
    TraderTimeHard=60
    TraderTimeSui=60
    TraderTimeHoE=60
    bTraderSpeedBoost=true

    bAllowVoting=true
    bAllowPauseVote=true
    bPauseTraderOnly=false
    MaxPauseTime=120
    MaxPauseTimePerWave=180
    bAllowLockPerkVote=true
    bAllowKickVote=true
    bAllowBlameVote=true
    BlameVoteCoolDown=60
    bBlameFart=true
    bAllowBoringVote=true
    MaxVoteKillMonsters=10
    MaxVoteKillHP=2000
    bVoteKillCheckVisibility=true
    VoteKillPenaltyMult=5.0
    LockTeamMinWave=5.0
    LockTeamMinWaveTourney=1.0
    LockTeamAutoWave=8.5
    MinVoteFF=0
    MaxVoteFF=0
    MinVoteDifficulty=2
    MaxDifficulty=8

    AmmoBoxMesh=StaticMesh'kf_generic_sm.pickups.Metal_Ammo_Box'
    AmmoBoxDrawScale=1.000000
    AmmoBoxDrawScale3D=(X=1.000000,Y=1.000000,Z=1.000000)
    GameStartCountDown=12
    bTradingDoorsOpen=true

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
}
