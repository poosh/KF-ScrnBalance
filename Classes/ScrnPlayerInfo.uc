// Additional player info used in achievements
class ScrnPlayerInfo extends Info
    config(ScrnBalance);

// variable below are initially set by ScrnGameRules
var ScrnGameRules GameRules;
var PlayerController PlayerOwner;
var ScrnPlayerInfo NextPlayerInfo;
var byte StartWave; // wave number, when player joined the game 0 - first wave
// -----


var LinkedReplicationInfo CustomReplicationInfo;    // for use by mod authors to link PRI.CustomReplicationInfo

const IGNORE_STAT = 0x7FFFFFFF;

// used to backup ServerPerks stats
struct TCustomStat {
    var class<SRCustomProgress> CustomStatClass;
    var int Progress;
};

struct TPerkStats {
    var bool bSet;

    var int RDamageHealedStat,
        RWeldingPointsStat, RShotgunDamageStat,
        RHeadshotKillsStat,
        RStalkerKillsStat, RBullpupDamageStat,
        RMeleeDamageStat,
        RFlameThrowerDamageStat,
        RExplosivesDamageStat;
    var array<TCustomStat> CustomStats;
};
var TPerkStats GameStartStats; // perk stats at the game start or when player just joined the game
var globalconfig array<string> ExcludeBonusStats;


struct TWeapInfo {
    var KFWeapon Weapon;
    var class<KFWeapon> WeaponClass;
    var class<KFWeaponDamageType> DamType;
    var byte PickupWave; // wave number, when weapon was picked up
    var    PlayerController PrevOwner; // player who owned this weapon before us
    var bool bPrevOwnerDead; // was PrevOwner dead when we picked up his weapon?

    var float LastDmgTime, LastKillTime; // time when last damage was made

    var int TotalKills, TotalHeadshots, TotalDecaps, TotalDamage;

    var bool bHeadshot; // Was last damage made from this weapon a headshot?
    var int RowHeadshots; //number of headshots in a row made from this weapon
    var int HeadshotsPerShot, HeadshotsPerMagazine, HeadshotsPerWave;

    var int KillsPerShot; //number of kills made from this weapon without releasing the trigger or firing again
    var int KillsPerMagazine; //number of kills made from this weapon without reloading
    var int KillsPerWave; //number of kills made from this weapon in wave

    var int DecapsPerShot, DecapsPerMagazine, DecapsPerWave; // decapitations
    var int DamagePerShot, DamagePerMagazine, DamagePerWave; // damages

    // Minimal values to trigger an event. If Value >= Trigger value, event will be called.
    var int TriggerRowHeadshots,
        TriggerHeadshotsPerShot, TriggerHeadshotsPerMagazine,
        TriggerKillsPerShot, TriggerKillsPerMagazine,
        TriggerDecapsPerShot, TriggerDecapsPerMagazine,
        TriggerDamagePerShot, TriggerDamagePerMagazine;
};
var array<TWeapInfo> WeapInfos;

var bool bDied;  // did player died during the way. Valid also during the next trader time.
var byte Deaths; // how many times player died in the game (excluding suicides at trader time)
var byte DeathsByMonster; // how many times player died in the game (excluding suicides at trader time)
var Controller LastKilledBy; // enemy who killed player last time

var float LastDmgTime, LastKillTime;
var float LastDamage; // last damage value
var class<KFWeaponDamageType> LastDamageType;
var KFMonster LastDamagedMonster; // last monster, who was damaged by the player
var bool bHeadshot; // was last damage made by this player a headshot?
var byte RowHeadshots; //number of headshots in a row made by this player
var int HeadshotsPerWave, HeadshotsPerGame;
var int BodyshotsPerWave, BodyshotsPerGame; // this number doesn't include damages with bCheckForHeadShots=false
var int KillsPerWave; // total kills per game are already tracked in PRI
var int DecapsPerWave, DecapsPerGame; // number of decapitations in the current wave
var int DamagePerWave, DamagePerGame;

var int DamageReceivedPerWave, DamageReceivedPerGame; // damage received from monsters
var int HealedPointsInWave;
var int MedicDamage;
var int MEDICXP_PER_1000DMG;

// Minimal values to trigger an event. If Value >= Trigger value, event will be called.
var int TriggerRowHeadshots;

var KFWeapon LastFiredWeapon;
var int LastWeapInfoIndex; // index in WeapInfos array of last updated record

// how much dosh player donated to teammates and how much he received back.
// CashFound - cash spawned on the map (wasn't dropped by a player)
var int CashDonated, CashReceived, CashFound;
var int CashDonatedPerWave, CashReceivedPerWave, CashFoundPerWave;

//stuctures to store custom data form achievement handlers
struct TCustomData {
    var ScrnAchHandlerBase AchHandler;
    var name StatName;
    var bool bWaveReset; // if true, stat will be automatically reset at the new wave begin
    var String StrVal;
    var int IntVal;
    var float FloatVal;
};
var private array<TCustomData> CustomData;
var private ScrnAchHandlerBase LastSearchedAchHandler;
var private name LastSearchedStatName;
var private int LastFoundCustomDataIndex;


// Backup data for PlayerReplicationInfo
var int SteamID32;
var int PRI_Score, PRI_Kills, PRI_KillAssists, PRI_Deaths, PRI_StartTime;
var byte PRI_BlameCounter;
var class<KFVeterancyTypes> PRI_ClientVeteranSkill;
var byte PRI_TeamIndex;

function ClientPerkRepLink GetRep()
{
    return class'ScrnClientPerkRepLink'.static.FindMe(PlayerOwner);
}

function string PerkStatStr(out TPerkStats Stats)
{
    return "MEDIC"$Stats.RDamageHealedStat
        @"SUP"$Stats.RWeldingPointsStat$"/"$Stats.RShotgunDamageStat
        @"SS"$Stats.RHeadshotKillsStat
        @"CMD"$Stats.RStalkerKillsStat$"/"$Stats.RBullpupDamageStat
        @"ZERK"$Stats.RMeleeDamageStat
        @"FB"$Stats.RFlameThrowerDamageStat
        @"DEMO"$Stats.RExplosivesDamageStat;
}

function string PerkProgressStr(out TPerkStats InitialStats)
{
    local ClientPerkRepLink L;

    L = GetRep();
    if ( L == none )
        return "";

    return "MEDIC"$(L.RDamageHealedStat - InitialStats.RDamageHealedStat)
        @"SUP"$(L.RWeldingPointsStat - InitialStats.RWeldingPointsStat)$"/"$(L.RShotgunDamageStat - InitialStats.RShotgunDamageStat)
        @"SS"$(L.RHeadshotKillsStat - InitialStats.RHeadshotKillsStat)
        @"CMD"$(L.RStalkerKillsStat - InitialStats.RStalkerKillsStat)$"/"$(L.RBullpupDamageStat - InitialStats.RBullpupDamageStat)
        @"ZERK"$(L.RMeleeDamageStat - InitialStats.RMeleeDamageStat )
        @"FB"$(L.RFlameThrowerDamageStat - InitialStats.RFlameThrowerDamageStat)
        @"DEMO"$(L.RExplosivesDamageStat - InitialStats.RExplosivesDamageStat);
}

// backups only if Stats.bSet = false !!!
function BackupStats(out TPerkStats Stats)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local int i;
    local string ClassName;

    if ( Stats.bSet )
        return;

    L = GetRep();
    if ( L == none )
        return;

    Stats.bSet = true;
    Stats.RDamageHealedStat        = L.RDamageHealedStat;
    Stats.RWeldingPointsStat       = L.RWeldingPointsStat;
    Stats.RShotgunDamageStat       = L.RShotgunDamageStat;
    Stats.RHeadshotKillsStat       = L.RHeadshotKillsStat;
    Stats.RStalkerKillsStat        = L.RStalkerKillsStat;
    Stats.RBullpupDamageStat       = L.RBullpupDamageStat;
    Stats.RMeleeDamageStat         = L.RMeleeDamageStat;
    Stats.RFlameThrowerDamageStat  = L.RFlameThrowerDamageStat;
    Stats.RExplosivesDamageStat    = L.RExplosivesDamageStat;

    Stats.CustomStats.length = 0;
    for ( S=L.CustomLink; S!=none; S=S.NextLink ) {
        if ( SRCustomProgressInt(S) == none && SRCustomProgressFloat(S) == none )
            continue; // store only int values

        ClassName = GetItemName(String(S.class));
        for ( i=0; i<ExcludeBonusStats.length; ++i ) {
            if ( ClassName ~= ExcludeBonusStats[i] ) {
                i = -1;
                break;
            }
        }
        if ( i == -1 )
            continue;

        i = Stats.CustomStats.length;
        Stats.CustomStats.insert(i, 1);
        Stats.CustomStats[i].CustomStatClass = S.class;
        Stats.CustomStats[i].Progress = S.GetProgressInt();
    }
    //PlayerOwner.ClientMessage(class'ScrnPlayerController'.static.ConsoleColorString("Initial Perks Stats: " $ PerkStatStr(Stats), 255, 1, 200));

}

// add bonus values to all stats by multiplying gained progress with Mult, e.g.:
// RDamageHealedStat += (RDamageHealedStat - InitialStats.RDamageHealedStat) * Mult;
// InitialStats.bSet must be true
// New stats will be written into InitialStats
function BonusStats(out TPerkStats InitialStats, float Mult)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local SRStatsBase SteamStats;
    local int i, v;

    if ( Mult <= 0 )
        return;
    if ( !InitialStats.bSet ) {
        PlayerOwner.ClientMessage(class'ScrnPlayerController'.static.ConsoleColorString("Unable to give end game bonus! No stat backup found", 255, 1, 1));
        return;
    }

    SteamStats = SRStatsBase(PlayerOwner.SteamStatsAndAchievements);
    if ( SteamStats == none )
        return;

    L = SteamStats.Rep;
    if ( L == none )
        return;

    PlayerOwner.ClientMessage(class'ScrnPlayerController'.static.ConsoleColorString("Stat Bonus (x"$Mult$"): " $ PerkProgressStr(InitialStats), 255, 1, 200));

    v = Mult * (L.RDamageHealedStat - InitialStats.RDamageHealedStat);
    if ( v > 0 )
        SteamStats.AddDamageHealed(v);

    v = Mult * (L.RWeldingPointsStat - InitialStats.RWeldingPointsStat);
    if ( v > 0 )
        SteamStats.AddWeldingPoints(v);
    v = Mult * (L.RShotgunDamageStat - InitialStats.RShotgunDamageStat);
    if ( v > 0 )
        SteamStats.AddShotgunDamage(v);

    // that is fucking gay, dude!
    v = Mult * (L.RHeadshotKillsStat - InitialStats.RHeadshotKillsStat);
    while ( v-- > 0 )
        SteamStats.AddHeadshotKill(false);

    v = Mult * (L.RStalkerKillsStat - InitialStats.RStalkerKillsStat);
    while ( v-- > 0 )
        SteamStats.AddStalkerKill();
    v = Mult * (L.RBullpupDamageStat - InitialStats.RBullpupDamageStat);
    if ( v > 0 )
        SteamStats.AddBullpupDamage(v);

    v = Mult * (L.RMeleeDamageStat - InitialStats.RMeleeDamageStat);
    if ( v > 0 )
        SteamStats.AddMeleeDamage(v);

    v = Mult * (L.RFlameThrowerDamageStat - InitialStats.RFlameThrowerDamageStat);
    if ( v > 0 )
        SteamStats.AddFlameThrowerDamage(v);

    v = Mult * (L.RExplosivesDamageStat - InitialStats.RExplosivesDamageStat);
    if ( v > 0 )
        SteamStats.AddExplosivesDamage(v);

    for ( S=L.CustomLink; S!=none; S=S.NextLink ) {
        if ( SRCustomProgressInt(S) == none && SRCustomProgressFloat(S) == none )
            continue; // proceed only int and float values

        for ( i=0; i< InitialStats.CustomStats.length; ++i) {
            if ( InitialStats.CustomStats[i].CustomStatClass == S.Class ) {
                v = Mult * (S.GetProgressInt() - InitialStats.CustomStats[i].Progress);
                if ( v > 0 )
                    S.IncrementProgress(v);
                InitialStats.CustomStats.remove(i, 1);
                break;
            }
        }
    }

    // store modified stats to prevent multiple bonuses
    InitialStats.bSet = false;
    BackupStats(InitialStats);
}


final function bool ProgressAchievement(name AchID, int Inc)
{
    if ( SRStatsBase(PlayerOwner.SteamStatsAndAchievements) == none )
        return false;

    return class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
            SRStatsBase(PlayerOwner.SteamStatsAndAchievements).Rep, AchID, Inc);
}

final function ScrnAchievements GetAchievementsByClass(class<ScrnAchievements> AchClass)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;

    L = GetRep();
    if ( L == none )
        return none;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        if( ClassIsChildOf(S.Class, AchClass) )
            return ScrnAchievements(S);
    }
    return none;
}

final function ScrnAchievements GetAchievementsByID(name AchID, out int AchIndex)
{
    local ClientPerkRepLink L;
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i;

    L = GetRep();
    if ( L == none )
        return none;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                if ( A.AchDefs[i].ID == AchID ) {
                    AchIndex = i;
                    return A;
                }
            }
        }
    }
    return none;
}


// returns array index or -1, if record not found
protected function int FindCustomData(ScrnAchHandlerBase AchHandler, name StatName, optional bool bCreate)
{
    local int i;

    if ( AchHandler == LastSearchedAchHandler && StatName == LastSearchedStatName )
        return LastFoundCustomDataIndex;

    for ( i=0; i<CustomData.length; ++i ) {
        if ( CustomData[i].AchHandler == AchHandler && CustomData[i].StatName == StatName ) {
            LastSearchedAchHandler = AchHandler;
            LastSearchedStatName = StatName;
            LastFoundCustomDataIndex = i;
            return i;
        }
    }
    if ( bCreate ) {
        CustomData.insert(i, 1);
        CustomData[i].AchHandler = AchHandler;
        CustomData[i].StatName = StatName;
        LastSearchedAchHandler = AchHandler;
        LastSearchedStatName = StatName;
        LastFoundCustomDataIndex = i;
        return i;
    }
    return -1;
}

function bool HasCustomValue(ScrnAchHandlerBase AchHandler, name StatName)
{
    return FindCustomData(AchHandler, StatName) != -1;
}

function string GetCustomString(ScrnAchHandlerBase AchHandler, name StatName)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName);
    if (idx != -1)
        return CustomData[idx].StrVal;
    return "";
}

function int GetCustomValue(ScrnAchHandlerBase AchHandler, name StatName)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName);
    if (idx != -1)
        return CustomData[idx].IntVal;
    return 0;
}

function float GetCustomFloat(ScrnAchHandlerBase AchHandler, name StatName)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName);
    if (idx != -1)
        return CustomData[idx].FloatVal;
    return 0.f;
}

function SetCustomString(ScrnAchHandlerBase AchHandler, name StatName, string Value, optional bool bWaveReset)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName, true);
    CustomData[idx].bWaveReset = bWaveReset;
    CustomData[idx].StrVal = Value;
    CustomData[idx].IntVal = int(Value);
    CustomData[idx].FloatVal = float(Value);
}

function SetCustomValue(ScrnAchHandlerBase AchHandler, name StatName, int Value, optional bool bWaveReset)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName, true);
    CustomData[idx].bWaveReset = bWaveReset;
    CustomData[idx].StrVal = string(Value);
    CustomData[idx].IntVal = Value;
    CustomData[idx].FloatVal = Value;
}

function SetCustomFloat(ScrnAchHandlerBase AchHandler, name StatName, float Value, optional bool bWaveReset)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName, true);
    CustomData[idx].bWaveReset = bWaveReset;
    CustomData[idx].StrVal = string(Value);
    CustomData[idx].IntVal = Value;
    CustomData[idx].FloatVal = Value;
}

// incremets custom progress and returns its new value
function int IncCustomValue(ScrnAchHandlerBase AchHandler, name StatName, int Inc, optional bool bWaveReset)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName, true);
    CustomData[idx].bWaveReset = bWaveReset;
    CustomData[idx].IntVal += Inc;
    CustomData[idx].StrVal = string(CustomData[idx].IntVal);
    CustomData[idx].FloatVal = CustomData[idx].IntVal;
    return CustomData[idx].IntVal;
}

function int IncCustomFloat(ScrnAchHandlerBase AchHandler, name StatName, float Inc, optional bool bWaveReset)
{
    local int idx;

    idx = FindCustomData(AchHandler, StatName, true);
    CustomData[idx].bWaveReset = bWaveReset;
    CustomData[idx].FloatVal += Inc;
    CustomData[idx].StrVal = string(CustomData[idx].FloatVal);
    CustomData[idx].IntVal = CustomData[idx].FloatVal;
    return CustomData[idx].FloatVal;
}


// returns index in WeapInfos
function int RegisterDamageType(KFWeapon Weapon, class<DamageType> DamType, bool bClearPerShotInfo)
{
    local int i;
    local class<KFWeaponDamageType> KFDamType;

    KFDamType = class<KFWeaponDamageType>(DamType);

    if ( Weapon == none || KFDamType == none )
        return -1;

    for ( i=0; i<WeapInfos.Length; ++i ) {
        if ( WeapInfos[i].WeaponClass == Weapon.class && WeapInfos[i].DamType == KFDamType ) {
            WeapInfos[i].Weapon = Weapon;
            if ( bClearPerShotInfo ) {
                WeapInfos[i].KillsPerShot = 0;
                WeapInfos[i].HeadshotsPerShot = 0;
                WeapInfos[i].DecapsPerShot = 0;
                WeapInfos[i].DamagePerShot = 0;
            }
            return i;
        }
    }
    WeapInfos.insert(i, 1);
    WeapInfos[i].Weapon = Weapon;
    WeapInfos[i].WeaponClass = Weapon.class;
    WeapInfos[i].PickupWave = GameRules.Mut.KF.WaveNum;
    // Hack in ScrnHumanPawn forces the game to set Tier3WeaponGiver for all weapons despite their tier.
    // After player kills somebody with this weapon, Tier3WeaponGiver will be set to none in KFGameType.Killed()
    // So only PrevOwner can be used to identify origonal owner
    if ( Weapon.Tier3WeaponGiver != none && Weapon.Tier3WeaponGiver != self ) {
        WeapInfos[i].PrevOwner = Weapon.Tier3WeaponGiver;
        WeapInfos[i].bPrevOwnerDead = Weapon.Tier3WeaponGiver.IsDead();
    }
    WeapInfos[i].DamType = KFDamType;
    WeapInfos[i].TriggerRowHeadshots = 2;
    WeapInfos[i].TriggerHeadshotsPerShot = 2;
    WeapInfos[i].TriggerHeadshotsPerMagazine = 2;
    WeapInfos[i].TriggerKillsPerShot = 2;
    WeapInfos[i].TriggerKillsPerMagazine = 2;
    WeapInfos[i].TriggerDecapsPerShot = 2;
    WeapInfos[i].TriggerDecapsPerMagazine = 2;
    WeapInfos[i].TriggerDamagePerShot = 2;
    WeapInfos[i].TriggerDamagePerMagazine = 2;;
    return i;
}

function ClearWeapInfos()
{
    local int i;

    while ( i<WeapInfos.Length ) {
        WeapInfos[i].HeadshotsPerWave = 0;
        WeapInfos[i].KillsPerWave = 0;
        WeapInfos[i].DecapsPerWave = 0;
        WeapInfos[i].DamagePerWave = 0;
        i++;
    }
}

// calculates all damage types together
// bHeadshot, RowHeadshots and per-shot stats not included and always be returned as 0
function TWeapInfo GetFullWeaponInfo(class<KFWeapon> WC)
{
    local TWeapInfo result;
    local int i;

    for ( i=0; i<WeapInfos.Length; ++i ) {
        if ( WeapInfos[i].WeaponClass == WC ) {
            if ( WeapInfos[i].LastDmgTime > result.LastDmgTime )
                result.LastDmgTime = WeapInfos[i].LastDmgTime;
            result.TotalKills += WeapInfos[i].TotalKills;
            result.TotalHeadshots += WeapInfos[i].TotalHeadshots;
            result.TotalDecaps += WeapInfos[i].TotalDecaps;
            result.TotalDamage += WeapInfos[i].TotalDamage;
            result.HeadshotsPerMagazine += WeapInfos[i].HeadshotsPerMagazine;
            result.HeadshotsPerWave += WeapInfos[i].HeadshotsPerWave;
            result.KillsPerMagazine += WeapInfos[i].KillsPerMagazine;
            result.KillsPerWave += WeapInfos[i].KillsPerWave;
            result.DecapsPerMagazine += WeapInfos[i].DecapsPerMagazine;
            result.DecapsPerWave += WeapInfos[i].DecapsPerWave;
            result.DamagePerMagazine += WeapInfos[i].DamagePerMagazine;
            result.DamagePerWave += WeapInfos[i].DamagePerWave;
        }
    }
    return result;
}

function WeaponFired(KFWeapon W, byte FireMode)
{
    local WeaponFire WF;
    local class<Projectile> proj;

    if ( W == none )
        return;

    LastFiredWeapon = W;
    WF = W.GetFireMode(FireMode);
    if ( WF == none || WF.class == Class'KFMod.NoFire' )
        return;

    proj = WF.default.ProjectileClass;
    if ( proj != none ) {
        RegisterDamageType(W, proj.default.MyDamageType, true);
        if ( class<LAWProj>(proj) != none )
            RegisterDamageType(W, class<LAWProj>(proj).default.ImpactDamageType, true);
        else if ( class<M79GrenadeProjectile>(proj) != none )
            RegisterDamageType(W, class<M79GrenadeProjectile>(proj).default.ImpactDamageType, true);
    }
    if ( InstantFire(WF) != none )
        RegisterDamageType(W, InstantFire(WF).DamageType, true);
    else if ( KFMeleeFire(WF) != none )
        RegisterDamageType(W, KFMeleeFire(WF).hitDamageClass, true);
}

function WeaponReloaded(KFWeapon W)
{
    local int i;
    if ( W == none
    )
        return;

    for ( i=0; i<GameRules.AchHandlers.length; ++i )
        GameRules.AchHandlers[i].WeaponReloaded(self, W);

    for ( i=0; i<WeapInfos.Length; ++i ) {
        if ( WeapInfos[i].Weapon == W ) {
            WeapInfos[i].KillsPerShot = 0;
            WeapInfos[i].KillsPerMagazine = 0;

            WeapInfos[i].DecapsPerShot = 0;
            WeapInfos[i].DecapsPerMagazine = 0;

            WeapInfos[i].DamagePerShot = 0;
            WeapInfos[i].DamagePerMagazine = 0;

            WeapInfos[i].HeadshotsPerShot = 0;
            WeapInfos[i].HeadshotsPerMagazine = 0;
        }
    }
}

function KFWeapon GetCurrentWeapon()
{
    if ( PlayerOwner.Pawn == none || PlayerOwner.Pawn.Health <= 0 )
        return none;

    return KFWeapon(PlayerOwner.Pawn.Weapon);
}


/** Locates WeapInfos record by a given damage type. If there are multiple records with the same
 * damage type, looks for a match with LastFiredWeapon. If such not found, returns last record with
 * matched damage type
 *
 * @param DamType weapon damage type to search
 * @return record index in WeapInfos array or -1, if record not found
*/
function int FindWeaponInfoByDamType(class<KFWeaponDamageType> DamType)
{
    local int i, idx;

    if (  LastWeapInfoIndex >= 0 && LastWeapInfoIndex < WeapInfos.Length
            &&  WeapInfos[LastWeapInfoIndex].DamType == DamType )
        return LastWeapInfoIndex;

    idx = -1;
    for ( i=0; i<WeapInfos.Length; ++i ) {
        if ( WeapInfos[i].DamType == DamType ) {
            // if this damage type can be delivered by last fired weapon, then use it.
            // Otherwice use last registered record with this damage type
            idx = i;
            if ( WeapInfos[i].Weapon == LastFiredWeapon )
                break;
        }
    }
    return idx;
}


function KFWeapon FindWeaponByDamType(class<KFWeaponDamageType> DamType)
{
    local int idx;

    idx = FindWeaponInfoByDamType(DamType);

    if ( idx != -1 )
        return WeapInfos[idx].Weapon;

    return none;
}

/**
 * This function is called each time when player made damage to the monster. P2P damages or damages
 * made by non-KFWeaponDamageType aren't triggered here.
 *
 * @param Damage damage delivered (including perk bonuses, resistance etc.).
 * @param Injured Monster that took damage. Note that Monster.Health isn't touched yet, i.e.
 *          Damage isn't subtracted yet, but Monster.HeadHealth already has actual value.
 * @param DamType damage type.
 * @param bHeadshot is this damage acquired by a headshot? False for any shot made to already decapitaded enemy.
 * @param bWasDecapitated was Injured decapitaded before this shot? If true, bHeadshot will always be false.
 */
function MadeDamage(int Damage, KFMonster Injured, class<KFWeaponDamageType> DamType, bool bHeadshot, bool bWasDecapitated )
{
    local int i, m, v;
    local float t;
    local KFWeapon Weapon;
    local KFPlayerReplicationInfo KFPRI;

    if ( PlayerOwner == none )
        return;
    KFPRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);

    LastDamage = Damage;
    LastDamageType = DamType;
    LastDamagedMonster = Injured;
    DamagePerWave += Damage;
    DamagePerGame += Damage;

    self.bHeadshot = bHeadshot;
    if ( bHeadshot ) {
        RowHeadshots++;
        HeadshotsPerWave++;
        HeadshotsPerGame++;
        if ( Injured.bDecapitated ) {
            DecapsPerWave++;
            DecapsPerGame++;
        }
        // EVENT
        if ( RowHeadshots >= TriggerRowHeadshots ) {
            m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
            for ( i=0; i<GameRules.AchHandlers.length; ++i )
                m = min(m, GameRules.AchHandlers[i].RowHeadhots(self, RowHeadshots));
            TriggerRowHeadshots = m;
        }
        // END OF EVENT
    }
    else if ( !bWasDecapitated ) { // don't clear headshots when hitting decapitated bodies
        RowHeadshots = 0;
        if ( DamType.default.bCheckForHeadShots ) {
            BodyshotsPerWave++;
            BodyshotsPerGame++;
        }
    }

    // count medic damage
    if ( ClassIsChildOf(DamType, class'ScrnDamTypeMedicBase')
        || (ClassIsChildOf(DamType, class'DamTypeKatana')
            && KFPRI != none &&  ClassIsChildOf(KFPRI.ClientVeteranSkill, class'ScrnVetFieldMedic')) )
    {
        MedicDamage += min(Damage, Injured.Health);
        if ( MedicDamage >= 1000 ) {
            SRStatsBase(PlayerOwner.SteamStatsAndAchievements).AddDamageHealed(MedicDamage / 1000 * MEDICXP_PER_1000DMG);
            MedicDamage = MedicDamage % 1000;
        }
    }

    LastWeapInfoIndex = FindWeaponInfoByDamType(DamType);
    for ( i=0; i<GameRules.AchHandlers.length; ++i ) {
        GameRules.AchHandlers[i].MonsterDamaged(Damage, Injured, self, DamType, bHeadshot, bWasDecapitated);
    }


    if ( LastWeapInfoIndex != -1 ) {
        Weapon = WeapInfos[LastWeapInfoIndex].Weapon;
        WeapInfos[LastWeapInfoIndex].DamagePerShot += Damage;
        WeapInfos[LastWeapInfoIndex].DamagePerMagazine += Damage;
        WeapInfos[LastWeapInfoIndex].DamagePerWave += Damage;
        WeapInfos[LastWeapInfoIndex].TotalDamage += Damage;
        WeapInfos[LastWeapInfoIndex].bHeadshot = bHeadshot;
        if ( bHeadshot ) {
            WeapInfos[LastWeapInfoIndex].RowHeadshots++;
            WeapInfos[LastWeapInfoIndex].HeadshotsPerShot++;
            WeapInfos[LastWeapInfoIndex].HeadshotsPerMagazine++;
            WeapInfos[LastWeapInfoIndex].HeadshotsPerWave++;
            WeapInfos[LastWeapInfoIndex].TotalHeadshots++;
            if ( Injured.bDecapitated ) {
                WeapInfos[LastWeapInfoIndex].DecapsPerShot++;
                WeapInfos[LastWeapInfoIndex].DecapsPerMagazine++;
                WeapInfos[LastWeapInfoIndex].DecapsPerWave++;
                WeapInfos[LastWeapInfoIndex].TotalDecaps++;
                // EVENT
                if ( WeapInfos[LastWeapInfoIndex].DecapsPerShot >= WeapInfos[LastWeapInfoIndex].TriggerDecapsPerShot ) {
                    m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
                    v = WeapInfos[LastWeapInfoIndex].DecapsPerShot;
                    t = Level.TimeSeconds - WeapInfos[LastWeapInfoIndex].LastDmgTime;
                    for ( i=0; i<GameRules.AchHandlers.length; ++i )
                        m = min(m, GameRules.AchHandlers[i].WDecapsPerShot(self, Weapon, DamType, v, t));
                    WeapInfos[LastWeapInfoIndex].TriggerDecapsPerShot = m;
                }
                if ( WeapInfos[LastWeapInfoIndex].DecapsPerMagazine >= WeapInfos[LastWeapInfoIndex].TriggerDecapsPerMagazine ) {
                    m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
                    v = WeapInfos[LastWeapInfoIndex].DecapsPerMagazine;
                    for ( i=0; i<GameRules.AchHandlers.length; ++i )
                        m = min(m, GameRules.AchHandlers[i].WDecapsPerMagazine(self, Weapon, DamType, v));
                    WeapInfos[LastWeapInfoIndex].TriggerDecapsPerMagazine = m;
                }
                // END OF EVENT
            }
            // EVENT
            if ( WeapInfos[LastWeapInfoIndex].RowHeadshots >= WeapInfos[LastWeapInfoIndex].TriggerRowHeadshots ) {
                m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
                v = WeapInfos[LastWeapInfoIndex].RowHeadshots;
                for ( i=0; i<GameRules.AchHandlers.length; ++i )
                    m = min(m, GameRules.AchHandlers[i].WRowHeadhots(self, Weapon, DamType, v));
                WeapInfos[LastWeapInfoIndex].TriggerRowHeadshots = m;
            }
            if ( WeapInfos[LastWeapInfoIndex].HeadshotsPerShot >= WeapInfos[LastWeapInfoIndex].TriggerHeadshotsPerShot ) {
                m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
                v = WeapInfos[LastWeapInfoIndex].HeadshotsPerShot;
                for ( i=0; i<GameRules.AchHandlers.length; ++i )
                    m = min(m, GameRules.AchHandlers[i].WInstantHeadhots(self, Weapon, DamType, v));
                WeapInfos[LastWeapInfoIndex].TriggerHeadshotsPerShot = m;
            }
            if ( WeapInfos[LastWeapInfoIndex].HeadshotsPerMagazine >= WeapInfos[LastWeapInfoIndex].TriggerHeadshotsPerMagazine ) {
                m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
                v = WeapInfos[LastWeapInfoIndex].HeadshotsPerMagazine;
                for ( i=0; i<GameRules.AchHandlers.length; ++i )
                    m = min(m, GameRules.AchHandlers[i].WHeadshotsPerMagazine(self, Weapon, DamType, v));
                WeapInfos[LastWeapInfoIndex].TriggerHeadshotsPerMagazine = m;
            }
            // END OF EVENT
        }
        else if ( !bWasDecapitated ) {
            WeapInfos[LastWeapInfoIndex].RowHeadshots = 0;
        }
        // EVENT
        if ( WeapInfos[LastWeapInfoIndex].DamagePerShot >= WeapInfos[LastWeapInfoIndex].TriggerDamagePerShot ) {
            m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
            v = WeapInfos[LastWeapInfoIndex].DamagePerShot;
            t = Level.TimeSeconds - WeapInfos[LastWeapInfoIndex].LastDmgTime;
            for ( i=0; i<GameRules.AchHandlers.length; ++i )
                m = min(m, GameRules.AchHandlers[i].WDamagePerShot(self, Weapon, DamType, v, t));
            WeapInfos[LastWeapInfoIndex].TriggerDamagePerShot = m;
        }
        if ( WeapInfos[LastWeapInfoIndex].DamagePerMagazine >= WeapInfos[LastWeapInfoIndex].TriggerDamagePerMagazine ) {
            m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
            v = WeapInfos[LastWeapInfoIndex].DamagePerMagazine;
            for ( i=0; i<GameRules.AchHandlers.length; ++i )
                m = min(m, GameRules.AchHandlers[i].WDamagePerMagazine(self, Weapon, DamType, v));
            WeapInfos[LastWeapInfoIndex].TriggerDamagePerMagazine = m;
        }
        // END OF EVENT

        WeapInfos[LastWeapInfoIndex].LastDmgTime = Level.TimeSeconds;
    }
    LastDmgTime = Level.TimeSeconds;
}

// took damage from the monster
function TookDamage(int Damage, KFMonster InstigatedBy, class<DamageType> DamType)
{
    local int i;

    DamageReceivedPerWave += Damage;
    DamageReceivedPerGame += Damage;

    for ( i=0; i<GameRules.AchHandlers.length; ++i ) {
        GameRules.AchHandlers[i].PlayerDamaged(Damage, self, InstigatedBy, DamType);
    }
}

function KilledMonster(KFMonster Killed, class<KFWeaponDamageType> DamType)
{
    local int i, m, v;
    local float t;
    local KFWeapon Weapon;

    KillsPerWave++;
    LastWeapInfoIndex = FindWeaponInfoByDamType(DamType);
    if ( LastWeapInfoIndex != -1 ) {
        Weapon = WeapInfos[LastWeapInfoIndex].Weapon;
        WeapInfos[LastWeapInfoIndex].KillsPerShot++;
        WeapInfos[LastWeapInfoIndex].KillsPerMagazine++;
        WeapInfos[LastWeapInfoIndex].KillsPerWave++;
        WeapInfos[LastWeapInfoIndex].TotalKills++;

        // EVENT
        if ( WeapInfos[LastWeapInfoIndex].KillsPerShot >= WeapInfos[LastWeapInfoIndex].TriggerKillsPerShot ) {
            m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
            v = WeapInfos[LastWeapInfoIndex].KillsPerShot;
            t = Level.TimeSeconds - WeapInfos[LastWeapInfoIndex].LastKillTime;
            for ( i=0; i<GameRules.AchHandlers.length; ++i )
                m = min(m, GameRules.AchHandlers[i].WKillsPerShot(self, Weapon, DamType, v, t));
            WeapInfos[LastWeapInfoIndex].TriggerKillsPerShot = m;
        }
        if ( WeapInfos[LastWeapInfoIndex].KillsPerMagazine >= WeapInfos[LastWeapInfoIndex].TriggerKillsPerMagazine ) {
            m = IGNORE_STAT; // next time trigger event when reaching minimal returned value
            v = WeapInfos[LastWeapInfoIndex].KillsPerMagazine;
            for ( i=0; i<GameRules.AchHandlers.length; ++i )
                m = min(m, GameRules.AchHandlers[i].WKillsPerMagazine(self, Weapon, DamType, v));
            WeapInfos[LastWeapInfoIndex].TriggerKillsPerMagazine = m;
        }
        // END OF EVENT

        WeapInfos[LastWeapInfoIndex].LastKillTime = Level.TimeSeconds;
    }
    for ( i=0; i<GameRules.AchHandlers.length; ++i ) {
        GameRules.AchHandlers[i].MonsterKilled(Killed, self, DamType);
    }
    LastKillTime = Level.TimeSeconds;
}

function Died(Controller Killer, class<DamageType> DamType)
{
    local int i;

    if ( !bDied ) {
        bDied = true;
        Deaths++;
        LastKilledBy = Killer;
        if ( KFMonster(Killer.Pawn) != none )
            DeathsByMonster++;
        for ( i=0; i<GameRules.AchHandlers.length; ++i ) {
            GameRules.AchHandlers[i].PlayerDied(self, Killer, DamType);
        }
    }
}

/* This player healed anothe one
 * @param HealAmount    the amount of health Patient received
 * @param Patient        player, who received healing
 * @param MedicGun        Instigator's weapon, which was used for healing
 */
function Healed(int HealAmount, ScrnHumanPawn Patient, KFWeapon MedicGun)
{
    local int i;

    HealedPointsInWave += HealAmount;

    for ( i=0; i<GameRules.AchHandlers.length; ++i )
        GameRules.AchHandlers[i].HealingMade(HealAmount, Patient, self, MedicGun);
}

/**
 * Function is called every time after the start of new wave
 * @param WaveNum - wave number, where 0 is first wave
 */
function WaveStarted(byte WaveNum)
{
    local int i;

    ClearWeapInfos();

    for ( i=0; i<CustomData.length; ++i ) {
        if ( CustomData[i].bWaveReset ) {
            CustomData[i].StrVal = "";
            CustomData[i].IntVal = 0;
            CustomData[i].FloatVal = 0;
        }
    }

    bDied = PlayerOwner.Pawn == none || PlayerOwner.Pawn.Health <= 0;
    HeadshotsPerWave = 0;
    BodyshotsPerWave = 0;
    KillsPerWave = 0;
    DecapsPerWave = 0;
    DamagePerWave = 0;
    DamageReceivedPerWave = 0;
    HealedPointsInWave = 0;
    CashDonatedPerWave = 0;
    CashReceivedPerWave = 0;
    CashFoundPerWave = 0;
}

function WaveEnded(byte WaveNum)
{
}

// backup vital player data from KFPRI
function BackupPRI()
{
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;

    if ( PlayerOwner == none )
        return;

    KFPRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
    if ( KFPRI == none )
        return;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(KFPRI);

    if ( !GameRules.Mut.bLeaveCashOnDisconnect )
        PRI_Score = KFPRI.Score;
    PRI_Kills = KFPRI.Kills;
    PRI_KillAssists = KFPRI.KillAssists;
    PRI_Deaths = KFPRI.Deaths;
    PRI_StartTime = KFPRI.StartTime;
    PRI_ClientVeteranSkill = KFPRI.ClientVeteranSkill;

    if ( KFPRI.Team == none )
        PRI_TeamIndex = 255;
    else
        PRI_TeamIndex = KFPRI.Team.TeamIndex;

    if ( ScrnPRI != none ) {
        PRI_BlameCounter = ScrnPRI.BlameCounter;
    }
}

function RestorePRI()
{
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;

    if ( PlayerOwner == none )
        return;

    KFPRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
    if ( KFPRI == none )
        return;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(KFPRI);

    if ( KFPRI.Kills == 0 && KFPRI.KillAssists == 0 && KFPRI.Deaths == 0 ) {
        if ( PRI_ClientVeteranSkill != none )
            KFPRI.ClientVeteranSkill = PRI_ClientVeteranSkill;
        if ( PRI_TeamIndex < 2 && ( KFPRI.Team == none || KFPRI.Team.TeamIndex != PRI_TeamIndex ) )
            Level.Game.ChangeTeam( PlayerOwner, PRI_TeamIndex, true );
    }

    if ( !GameRules.Mut.bLeaveCashOnDisconnect )
        KFPRI.Score = max(PRI_Score, KFPRI.Score);
    KFPRI.Kills = max(PRI_Kills, KFPRI.Kills);
    KFPRI.KillAssists = max(PRI_KillAssists, KFPRI.KillAssists);
    KFPRI.Deaths = max(PRI_Deaths, KFPRI.Deaths);
    KFPRI.StartTime = min(PRI_StartTime, KFPRI.StartTime);

    if ( ScrnPRI != none ) {
        ScrnPRI.BlameCounter = max(PRI_BlameCounter, ScrnPRI.BlameCounter);
    }
}


function PickedCash(CashPickup Dosh)
{
    local ScrnPlayerInfo DonatorSPI;
    local int i;

    if ( Dosh.CashAmount == 0 )
        return;

    if ( Dosh.bDroppedCash ) {
        DonatorSPI = GameRules.GetPlayerInfo(PlayerController(Dosh.DroppedBy));
        if ( DonatorSPI == self )
            return; // picked up own dosh
        // dosh was dropped by other player
        CashReceived += Dosh.CashAmount;
        CashReceivedPerWave += Dosh.CashAmount;
        if ( DonatorSPI != none ) {
            DonatorSPI.CashDonated += Dosh.CashAmount;
            DonatorSPI.CashDonatedPerWave += Dosh.CashAmount;
        }
    }
    else {
        // dosh found on the map (wasn't dropped by a player)
        CashFound += Dosh.CashAmount;
        CashFoundPerWave += Dosh.CashAmount;
    }
    // achievements
    for ( i=0; i<GameRules.AchHandlers.length; ++i )
        GameRules.AchHandlers[i].PickedCash(Dosh.CashAmount, self, DonatorSPI, Dosh.bDroppedCash);
}

function PickedWeapon(KFWeaponPickup WeaponPickup)
{
    local int i;

    for ( i=0; i<GameRules.AchHandlers.length; ++i )
        GameRules.AchHandlers[i].PickedWeapon(self, WeaponPickup);
}

function PickedItem(Pickup Item)
{
    local int i;

    for ( i=0; i<GameRules.AchHandlers.length; ++i )
        GameRules.AchHandlers[i].PickedItem(self, Item);
}

function float GetAccuracyWave()
{
    if ( HeadshotsPerWave+BodyShotsPerWave == 0 )
        return 0.f;
    return float(HeadshotsPerWave) / float(HeadshotsPerWave+BodyShotsPerWave);
}

function float GetAccuracyGame()
{
    if ( HeadshotsPerGame+BodyShotsPerGame == 0 )
        return 0.f;
    return float(HeadshotsPerGame) / float(HeadshotsPerGame+BodyShotsPerGame);
}

defaultproperties
{
    MEDICXP_PER_1000DMG=20
    TriggerRowHeadshots=2
    RemoteRole=ROLE_None
    PRI_TeamIndex=255
}