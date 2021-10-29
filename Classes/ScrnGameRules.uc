class ScrnGameRules extends GameRules
    Config(ScrnBalanceSrv);

var ScrnBalance Mut;
var KFGameType KF;

var bool bShowDamages;

var int HardcoreLevel;
var float HardcoreLevelFloat;
var bool bForceHardcoreLevel;
var localized string msgHardcore, msgHardcoreLowered, msgWeaponBlame;
var bool bUseAchievements;
var array<int> BoringMonsters;  // TotalMaxMonsters when the corresponding boring stage set

var bool bScrnDoom; // is server running ScrN version of Doom3 mutator?
var localized string msgDoom3Monster, msgDoomPercent, msgDoom3Boss;
var transient int WaveTotalKills, WaveDoom3Kills, GameDoom3Kills;
var transient int WaveAmmoPickups;

var transient bool bHasCustomZeds;

var class<KFMonster> BossClass;
var KFMonster Boss;
var transient bool bSuperPat, bDoomPat;
var bool bFinalWave; // is this a final wave


// Damage flags
const DF_STUNNED   = 0x01; // stun shot
const DF_RAGED     = 0x02; // rage shot
const DF_STUPID    = 0x04; // damage shouldn't be done to this zed
const DF_DECAP     = 0x08; // decapitaion shot
const DF_HEADSHOT  = 0x10; // 100% sure that this damage was made by headshot

// buy flags
const BUY_REJECT      = 0x00;
const BUY_ALLOW       = 0x01;
const BUY_SLIGHTLY_OP = 0x02;
const BUY_OP          = 0x04;
const BUY_MEGA_OP     = 0x06;  // (BUY_SLIGHTLY_OP | BUY_OP);
const BUY_BLAME       = 0x10;

struct MonsterInfo {
    var KFMonster Monster;
    var float SpawnTime;
    var float FirstHitTime; // time when Monster took first damage
    var int HitCount; // how many hits monster received

    var byte PlayerKillCounter; // how many players this monster killed
    var int DamageCounter; // how much damage monster delivered to players
    var float PlayerKillTime; // last time when monster killed a player

    var ScrnPlayerInfo KillAss1, KillAss2; // who helped player to kill this monster
    var class<KFWeaponDamageType> DamType1, DamType2;
    var float DamTime1, DamTime2;
    var int DamageFlags1, DamageFlags2;
    var bool TW_Ach_Failed; //if true, no TeamWork achievements can be earned on this zed

    var bool bHeadshot; // was last damage from headshot?
    var int RowHeadshots; // headshots in a row done to this monster. RowHeadshots doesn't reset after decapitation
    var int Headshots; // number of headshots made to this monster
    var int BodyShots; // number of bodyshots made to this monster by weapons, which can score headshots
    var int OtherHits; // number of hits made to this monster by weapons, which can NOT score headshots

    // variables below are set after NetDamage() call
    var float LastHitTime; // time when Monster took last damage
    var int MaxHeadHealth;
    var int HeadHealth; // track head health to check headshots
    var bool bWasDecapitated; // was the monster decapitated before last damage? If bWasDecapitated=true then bHeadshot=false
    var bool bWasBackstabbed; // previous hit was a melee backstab
};
var array<MonsterInfo> MonsterInfos;
var private transient KFMonster LastSeachedMonster; //used to optimize GetMonsterIndex()
var private transient int       LastFoundMonsterIndex;


struct MapAlias {
    var string FileName;
    var string AchName;
};
var config array<MapAlias> MapAliases;

var array< class<KFMonster> > CheckedMonsterClasses;

var ScrnGameRulesMod Mods;

var array<ScrnAchHandlerBase> AchHandlers;
var transient ScrnPlayerInfo PlayerInfo;
var private transient ScrnPlayerInfo BackupPlayerInfo;
var protected int WavePlayerCount, WaveDeadPlayers;

var class<ScrnAchievements> AchClass;
var class<ScrnMapAchievements> MapAchClass;

var localized string strWeaponLocked, strWeaponLockedOwn, strPerkedWeaponsOnly;
var localized string strWaveAccuracy;

// moved here from ScrnWeaponPack for extended compatibility with other muts
var array< class<KFWeaponDamageType> > SovietDamageTypes;

struct SHardcoreMonster {
    var config string MonsterClass;
    var config float HL;
    var transient bool bUsed;
};
var config float HL_Normal, HLMult_Normal, HL_Hard, HLMult_Hard, HL_Suicidal, HLMult_Suicidal, HL_HoE, HLMult_HoE;
var config float HL_Hardcore, HLMult_Hardcore;
var config array<SHardcoreMonster> HardcoreZeds, HardcoreBosses;
var transient float ZedHLMult;
var config bool bBroadcastHL;

struct SHardcoreGame
{
    var config string GameClass;
    var config float HL;
};
var config array<SHardcoreGame> HardcoreGames;


function PostBeginPlay()
{
    if( Level.Game.GameRulesModifiers==None )
        Level.Game.GameRulesModifiers = Self;
    else
        Level.Game.GameRulesModifiers.AddGameRules(Self);

    KF = KFGameType(Level.Game);
    Mut = class'ScrnBalance'.static.Myself(Level);

    MonsterInfos.Length = Mut.KF.MaxZombiesOnce; //reserve a space that will be required anyway
    InitHardcoreLevel();
}

event Destroyed()
{
    local ScrnPlayerInfo SPI;
    local int i;
    local ScrnGameRulesMod Mod;

    log("ScrnGameRules destroyed", 'ScrnBalance');
    // clear all ScrnPlayerInfo objects
    while ( PlayerInfo != none ) {
        SPI = PlayerInfo;
        PlayerInfo = SPI.NextPlayerInfo;
        SPI.Destroy();
    }
    while ( BackupPlayerInfo != none ) {
        SPI = BackupPlayerInfo;
        BackupPlayerInfo = SPI.NextPlayerInfo;
        SPI.Destroy();
    }

    // destroy all ach handlers
    for ( i=0; i<AchHandlers.length; ++i ) {
        if ( AchHandlers[i] != none )
            AchHandlers[i].Destroy();
    }
    AchHandlers.length = 0;

    while ( Mods != none ) {
        Mod = Mods;
        Mods = Mod.Next;
        Mod.Destroy();
    }

    super.Destroyed();

    log("ScrnGameRules destroyed", 'ScrnBalance');
}

function AddGameRules(GameRules GR)
{
    if ( GR!=Self ) //prevent adding same rules more than once
        Super.AddGameRules(GR);
}

function AddMod(ScrnGameRulesMod Mod)
{
    if ( Mods == None )
        Mods = Mod;
    else
        Mods.AddMod(Mod);
}

function AdjustZedSpawnRate()
{
    if ( Mut.ScrnGT != none ) {
        Mut.ScrnGT.SetBoringStage(0);
    }
    else if ( !Mut.bStoryMode ) {
        Mut.KF.KFLRules.WaveSpawnPeriod = Mut.OriginalWaveSpawnPeriod;
        Mut.KF.KFLRules.WaveSpawnPeriod /= 1.0 + 0.25 * fmax(0.0, AlivePlayerCount() - 6);
    }
}

function OnBoringStageSet(byte BoringStage)
{
    BoringMonsters.length = BoringStage + 1;
    BoringMonsters[BoringStage] = Mut.KF.TotalMaxMonsters;
}

function DestroyBuzzsawBlade()
{
    local ScrnCrossbuzzsawBlade Blade;
    local array<ScrnCrossbuzzsawBlade> Blades;
    local int i;

    foreach DynamicActors(class'ScrnCrossbuzzsawBlade', Blade) {
        Blades[i] = Blade;
    }

    for ( i = 0; i < Blades.length; ++i )
        Blades[i].ReplicatedDestroy();
}

function WaveStarted()
{
    local int i;
    local Controller P;
    local PlayerController PC;
    local ScrnPlayerInfo SPI;

    WaveDoom3Kills = 0;
    WaveTotalKills = 0;
    WavePlayerCount = 0;
    WaveDeadPlayers = 0;
    WaveAmmoPickups = 0;
    bFinalWave = Mut.KF.WaveNum == Mut.KF.FinalWave;

    ClearNonePlayerInfos();
    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        PC = PlayerController(P);
        if ( PC != none && PC.Pawn != none && PC.Pawn.Health > 0 ) {
            ++WavePlayerCount;
            if ( ScrnPlayerController(PC) != none )
                ScrnPlayerController(PC).ResetWaveStats();
            SPI = CreatePlayerInfo(PC, false);
            // in case when stats were created before ClientReplLink created
            if ( !SPI.GameStartStats.bSet )
                SPI.BackupStats(SPI.GameStartStats);
        }
    }

    AdjustZedSpawnRate();

    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        SPI.WaveStarted(Mut.KF.WaveNum);
    }

    for ( i=0; i<AchHandlers.length; ++i ) {
        AchHandlers[i].WaveStarted(Mut.KF.WaveNum);
    }

    if ( Mut.bStoryMode )
        log("Wave "$(Mut.KF.WaveNum+1)$" started at " $ Mut.GameTimeStr(), 'ScrnBalance');
    else if (bFinalWave)
        log("Final wave started at " $ Mut.GameTimeStr(), 'ScrnBalance');
    else
        log("Wave "$(Mut.KF.WaveNum+1)$"/"$(Mut.KF.FinalWave)$" started at " $ Mut.GameTimeStr(), 'ScrnBalance');

    DestroyBuzzsawBlade(); // prevent cheating
}

function PlayerLeaving(ScrnPlayerController PC)
{
    local ScrnPlayerInfo SPI;

    if ( Level.Game.bGameEnded )
        return; // game over

    SPI = GetPlayerInfo(PC);
    if ( SPI != none ) {
        SPI.BackupPRI();
        SPI.PlayerOwner = none;
    }
}

// Ensure that PC has valid SteamID before this function call!
function PlayerEntering(ScrnPlayerController PC)
{
    CreatePlayerInfo(PC, true);
}

function WaveEnded()
{
    local int i;
    local string s;
    local ScrnPlayerInfo SPI;
    local byte WaveNum;
    local Controller P;
    local PlayerController PC;
    local float Accuracy;
    local float BoringHL;

    // KF.WaveNum already set to a next wave, when WaveEnded() has been called
    // E.g. KF.WaveNum == 1 means that first wave has been ended (wave with index 0)
    WaveNum = KF.WaveNum-1;

    // give HL for boring votes
    for ( i = 1; i < BoringMonsters.length; ++i ) {
        //    ^ there is no typo. Zero index = no boring
        if ( BoringMonsters[i] < 100 )
            break;

        BoringHL += HardcoreLevelFloat * BoringMonsters[i] / 500.0 / Mut.KF.FinalWave;
    }
    if ( BoringHL > 0.09 ) {
        RaiseHardcoreLevel(BoringHL, Mut.ScrnGT.GetBoringString(i-1));
    }

    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        SPI.WaveEnded(WaveNum);
        SPI.BackupPRI(); // just in case

        // broadcast players with high accuracy
        if ( bFinalWave || SPI.DecapsPerWave >= 30 ) {
            Accuracy = SPI.GetAccuracyWave();
            if ( Accuracy > 0.75 ) {
                s = strWaveAccuracy;
                ReplaceText(s, "%p", Mut.ColoredPlayerName(SPI.PlayerOwner.PlayerReplicationInfo));
                ReplaceText(s, "%a", Mut.GetColoredPercent(Accuracy));
                mut.BroadcastMessage(s);
            }
        }
    }

    for ( i=0; i<AchHandlers.length; ++i ) {
        AchHandlers[i].WaveEnded(WaveNum);
    }

    // create player infos for the newcomers
    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        PC = PlayerController(P);
        if ( PC != none ) {
            if ( P.bIsPlayer && P.Pawn != none && P.Pawn.Health > 0 )
                CreatePlayerInfo(PC);

            // call this in story mode to enable perk selection in ServerPerks
            if ( Mut.bStoryMode ) {
                if ( KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements) != none )
                    KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements).WaveEnded();
            }
        }
    }
}

function bool IsMapBlackListed(string MapName)
{
    return !Mut.bTestMap;
}

//returns true if any custom or super specimens are found
function bool HasCustomZeds()
{
    return bHasCustomZeds;
}

function bool CheckMapAlias(out String MapName)
{
    local int i;

    for ( i = 0; i < MapAliases.length; ++i ) {
        if ( MapName ~= MapAliases[i].FileName ) {
            MapName = MapAliases[i].AchName;
            return true;
        }
    }
    return false;
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local bool bWin;
    local string MapName;
    local int i;

    if ( Level.Game.bGameEnded ) {
        return true;
    }
    else if ( Level.Game.bWaitingToStartMatch ) {
        return false;
    }

    if ( NextGameRules != None && !NextGameRules.CheckEndGame(Winner,Reason) )
        return false;

    // KFStoryGameInfo first call GameRules.CheckEndGame() and only then sets EndGameType
    if ( Mut.bStoryMode )
        bWin = Reason ~= "WinAction";
    else {
        bWin = KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType==2;
    }

    if ( bWin ) {
        mut.BroadcastMessage("Game WON in " $ Mut.GameTimeStr()
            $". HL="$HardcoreLevel, true);
        // Map achievements
        MapName = Mut.KF.GetCurrentMapName(Level);
        CheckMapAlias(MapName);
        if ( !IsMapBlackListed(MapName) ) {
            Mut.bNeedToSaveStats = false;
            GiveMapAchievements(MapName);
            for ( i=0; i<AchHandlers.length; ++i )
                AchHandlers[i].GameWon(MapName);
            // no need to save stats at this moment, because Level.Game.bGameEnded=False yet,
            // i.e. ServerPerks hasn't done the final save yet
            //Mut.SaveStats();
        }
        Mut.bNeedToSaveStats = false;
        Mut.bSaveStatsOnAchievementEarned = false;
    }
    else {
        if ( Mut.ScrnGT != none ) {
            for ( i = 0; i < Mut.ScrnGT.Bosses.Length; ++i ) {
                if ( Mut.ScrnGT.Bosses[i] != none && Mut.ScrnGT.Bosses[i].Health > 0 ) {
                    Boss = Mut.ScrnGT.Bosses[i];
                    mut.BroadcastMessage(Boss.MenuName $ "'s HP = " $ Boss.Health $" / " $ int(Boss.HealthMax)
                        $ " ("$100.0*Boss.Health/Boss.HealthMax$"%)");
                }
            }
        }
        else if ( Boss != none && Boss.Health > 0 )
            mut.BroadcastMessage(Boss.MenuName $ "'s HP = " $ Boss.Health $" / " $ int(Boss.HealthMax)
                $ " ("$100.0*Boss.Health/Boss.HealthMax$"%)");

        mut.BroadcastMessage("Game LOST in " $ Mut.GameTimeStr()
            $ " @ wave "$(Mut.KF.WaveNum+1)
            $", HL="$HardcoreLevel, true);
    }

    for ( i=0; i<AchHandlers.length; ++i ) {
        AchHandlers[i].GameEnded();
    }

    return true;
}

function GiveMapAchievements(optional String MapName)
{
    local bool bCustomMap, bGiveHardAch, bGiveSuiAch, bGiveHoeAch, bNewAch;
    local ScrnPlayerInfo SPI;
    local ClientPerkRepLink PerkLink;
    local TeamInfo WinnerTeam;
    local float BonusMult;
    local bool bGiveBonus;
    local int i;
    local int MapResult;

    WinnerTeam = TeamInfo(Level.Game.GameReplicationInfo.Winner);
    if ( Mut.bStoryMode ) {
        bGiveHardAch = Level.Game.GameDifficulty >= 4;
        bGiveSuiAch = Level.Game.GameDifficulty >= 5;
        bGiveHoeAch = Level.Game.GameDifficulty >= 7;
    }
    else {
        bGiveHardAch = HardcoreLevel >= 5 && HasCustomZeds();
        bGiveSuiAch = HardcoreLevel >= 10 && ( Mut.KF.IsA('TurboGame') || Mut.KF.KFGameLength == 9
                || (Mut.KF.KFGameLength >= 72 && Mut.KF.KFGameLength <= 99) );
        bGiveHoeAch = HardcoreLevel >= 15 && ( GameDoom3Kills > 0 ) || Mut.KF.IsA('FtgGame');
    }

    // end game bonus
    BonusMult = Mut.EndGameStatBonus;
    if ( Mut.bStatBonusUsesHL )
        BonusMult *= fmax(1.0, HardcoreLevel - Mut.StatBonusMinHL);
    i = Mut.MapInfo.FindMapInfo();
    if ( i != -1 )
        BonusMult *= 1.0 + Mut.MapInfo.MapInfo[i].Difficulty;
    bGiveBonus = BonusMult >= 0.1;
    if ( bGiveBonus )
        log("Giving bonus xp to winners (x"$BonusMult$")", 'ScrnBalance');

    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner == none || SPI.PlayerOwner.PlayerReplicationInfo == none )
            continue;

        PerkLink = SPI.GetRep();
        if ( PerkLink == none )
            continue;

        if ( WinnerTeam != none && SPI.PlayerOwner.PlayerReplicationInfo.Team != WinnerTeam )
            continue; // no candies for loosers

        // additional achievements that are granted only when surviving the game
        if ( ScrnPlayerController(SPI.PlayerOwner) != none && !ScrnPlayerController(SPI.PlayerOwner).bChangedPerkDuringGame )
            SPI.ProgressAchievement('PerkFavorite', 1);

        //unlock "Normal" achievement and see if the map is found
        MapResult = MapAchClass.static.UnlockMapAchievement(PerkLink, MapName, 0);
        bCustomMap = (MapResult == -2);
        bNewAch = (MapResult == 1);
        if ( bCustomMap ) {
            //map not found - progress custom map achievements
            if ( bGiveHardAch && AchClass.static.ProgressAchievementByID(PerkLink, 'WinCustomMapsHard', 1) )
                bNewAch = true;
            if ( bGiveSuiAch && AchClass.static.ProgressAchievementByID(PerkLink, 'WinCustomMapsSui', 1) )
                bNewAch = true;
            if ( bGiveHoeAch && AchClass.static.ProgressAchievementByID(PerkLink, 'WinCustomMapsHoE', 1) )
                bNewAch = true;
            AchClass.static.ProgressAchievementByID(PerkLink, 'WinCustomMapsNormal', 1);
            if ( AchClass.static.ProgressAchievementByID(PerkLink, 'WinCustomMaps', 1) )
                bNewAch = true;
        }
        else {
            //map found - give related achievements
            if ( bGiveHardAch && MapAchClass.static.UnlockMapAchievement(PerkLink, MapName, 1) == 1 )
                bNewAch = true;
            if ( bGiveSuiAch && MapAchClass.static.UnlockMapAchievement(PerkLink, MapName, 2) == 1 )
                bNewAch = true;
            if ( bGiveHoeAch && MapAchClass.static.UnlockMapAchievement(PerkLink, MapName, 3) == 1 )
                bNewAch = true;
        }
        // END-GAME STAT BONUS
        if ( bGiveBonus ) {
            if ( bNewAch )
                SPI.BonusStats(SPI.GameStartStats, BonusMult * fmax(1.0, Mut.FirstStatBonusMult));
            else
                SPI.BonusStats(SPI.GameStartStats, BonusMult);
        }
    }
}



static function TrimCollectionToDefault(out class<KFMonstersCollection> Collection, class<KFMonstersCollection> DefaultCollection)
{
    local int i, j, L;

    log ("Resetting Collection '"$Collection$"' to default '"$DefaultCollection$"'", 'ScrnBalance');
    // v7.51
    // seems like simple assigning of multi-dimensional arrays (i.e. arrays of structs of arrays) doesn't work correctly
    // that's why we assigning each element individually
    Collection.default.MonsterClasses.length = DefaultCollection.default.MonsterClasses.length;
    // StandardMonsterClasses isn't in use anywhere now, but who now that bloody Tripwire? ;)
    Collection.default.StandardMonsterClasses.length = DefaultCollection.default.MonsterClasses.length;
    for ( i=0; i<DefaultCollection.default.MonsterClasses.length; ++i ) {
        Collection.default.MonsterClasses[i].MClassName = DefaultCollection.default.MonsterClasses[i].MClassName;
        Collection.default.StandardMonsterClasses[i].MClassName = DefaultCollection.default.MonsterClasses[i].MClassName;

    }

    // v7.51: fix to replace empty squads
    Collection.default.SpecialSquads.length = 0;

    Collection.default.ShortSpecialSquads.length = Collection.default.ShortSpecialSquads.length;
    for ( i=0; i<DefaultCollection.default.ShortSpecialSquads.length; ++i ) {
        L = DefaultCollection.default.ShortSpecialSquads[i].ZedClass.length;
        Collection.default.ShortSpecialSquads[i].ZedClass.length = L;
        Collection.default.ShortSpecialSquads[i].NumZeds.length = L;
        for ( j=0; j<L; ++j ) {
            Collection.default.ShortSpecialSquads[i].ZedClass[j] = DefaultCollection.default.ShortSpecialSquads[i].ZedClass[j];
            Collection.default.ShortSpecialSquads[i].NumZeds[j] = DefaultCollection.default.ShortSpecialSquads[i].NumZeds[j];
        }
    }
    Collection.default.NormalSpecialSquads.length = Collection.default.NormalSpecialSquads.length;
    for ( i=0; i<DefaultCollection.default.NormalSpecialSquads.length; ++i ) {
        L = DefaultCollection.default.NormalSpecialSquads[i].ZedClass.length;
        Collection.default.NormalSpecialSquads[i].ZedClass.length = L;
        Collection.default.NormalSpecialSquads[i].NumZeds.length = L;
        for ( j=0; j<L; ++j ) {
            Collection.default.NormalSpecialSquads[i].ZedClass[j] = DefaultCollection.default.NormalSpecialSquads[i].ZedClass[j];
            Collection.default.NormalSpecialSquads[i].NumZeds[j] = DefaultCollection.default.NormalSpecialSquads[i].NumZeds[j];
        }
    }
    Collection.default.LongSpecialSquads.length = Collection.default.LongSpecialSquads.length;
    for ( i=0; i<DefaultCollection.default.LongSpecialSquads.length; ++i ) {
        L = DefaultCollection.default.LongSpecialSquads[i].ZedClass.length;
        Collection.default.LongSpecialSquads[i].ZedClass.length = L;
        Collection.default.LongSpecialSquads[i].NumZeds.length = L;
        for ( j=0; j<L; ++j ) {
            Collection.default.LongSpecialSquads[i].ZedClass[j] = DefaultCollection.default.LongSpecialSquads[i].ZedClass[j];
            Collection.default.LongSpecialSquads[i].NumZeds[j] = DefaultCollection.default.LongSpecialSquads[i].NumZeds[j];
        }
    }
    Collection.default.FinalSquads.length = Collection.default.FinalSquads.length;
    for ( i=0; i<DefaultCollection.default.FinalSquads.length; ++i ) {
        L = DefaultCollection.default.FinalSquads[i].ZedClass.length;
        Collection.default.FinalSquads[i].ZedClass.length = L;
        Collection.default.FinalSquads[i].NumZeds.length = L;
        for ( j=0; j<L; ++j ) {
            Collection.default.FinalSquads[i].ZedClass[j] = DefaultCollection.default.FinalSquads[i].ZedClass[j];
            Collection.default.FinalSquads[i].NumZeds[j] = DefaultCollection.default.FinalSquads[i].NumZeds[j];
        }
    }

    Collection.default.FallbackMonsterClass = DefaultCollection.default.FallbackMonsterClass;
    Collection.default.EndGameBossClass = DefaultCollection.default.EndGameBossClass;
}

function ResetSquads()
{
    ResetGameSquads(Mut.KF, Mut.CurrentEventNum);
}

//resets squads to default ones, because default ones are screwed
static function ResetGameSquads(KFGameType Game, byte EventNum)
{
    local class<KFMonstersCollection> DefaultCollection;
    local int i;

    for ( i=0; i<16; ++i ) {
        Game.ShortWaves[i] = Game.default.ShortWaves[i];
        Game.NormalWaves[i] = Game.default.NormalWaves[i];
        Game.LongWaves[i] = Game.default.LongWaves[i];
    }

    switch ( EventNum ) {
        case 0:
            DefaultCollection = class'DefaultMonstersCollection';
            break;
        case 1:
            DefaultCollection = class'DefaultMonstersCollectionSummer';
            break;
        case 2:
            DefaultCollection = class'DefaultMonstersCollectionHalloween';
            break;
        case 3:
            DefaultCollection = class'DefaultMonstersCollectionXmas';
            break;
        default:
            return; // custom collection used, don't screw it
    }

    Game.EndGameBossClass = DefaultCollection.default.EndGameBossClass;
    Game.StandardMonsterClasses.Length = 0; //fill MonstersCollection instead
    TrimCollectionToDefault(Game.MonsterCollection, DefaultCollection);
    // if ( Game.MonsterCollection != Game.default.MonsterCollection )
        // TrimCollectionToDefault(Game.default.MonsterCollection, DefaultCollection);
}

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy,
    vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local byte DamTypeNum;
    local int idx, i;
    local ScrnPlayerInfo SPI;
    local class<KFWeaponDamageType> KFDamType;
    local bool bP2M;
    local ScrnPlayerController ScrnPC;
    local KFMonster ZedVictim;
    local bool bDamageAck;

    // log("NetDamage: " $ injured $ " took damage from " $ instigatedBy $ " with " $ DamageType, 'ScrnBalance');

    // forward call to next rules
    if ( NextGameRules != None )
        Damage = NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );

    if ( Damage == 0 )
        return 0;

    KFDamType = class<KFWeaponDamageType>(damageType);
    ZedVictim = KFMonster(injured);
    if ( instigatedBy != none )
        ScrnPC = ScrnPlayerController(instigatedBy.Controller);
    bP2M = ZedVictim != none && KFDamType != none && instigatedBy != none && ScrnPC != none;
    bDamageAck = bShowDamages && ScrnPC != none && ScrnPC.DamageAck > 0;

    if ( ZedVictim != none ) {
        idx = GetMonsterIndex(ZedVictim);
        // prevent zed from rotating while stunned
        // Special case fo Husks -  201+ sniper damage stuns them
        if (ZedVictim.Controller != none && (Damage*1.5 >= ZedVictim.default.Health
                || (Damage > 200 && KFDamType != none && KFDamType.default.bSniperWeapon
                    && ZedVictim.IsA('ZombieHusk') && !ZedVictim.IsA('TeslaHusk'))) )
        {
            ZedVictim.Controller.Focus = none;
            ZedVictim.Controller.FocalPoint = ZedVictim.Location + 512 * vector(ZedVictim.Rotation);
        }
    }

    if ( bP2M ) {
        MonsterInfos[idx].HitCount++;
        if ( MonsterInfos[idx].FirstHitTime == 0 )
            MonsterInfos[idx].FirstHitTime = Level.TimeSeconds;

        MonsterInfos[idx].bHeadshot = !MonsterInfos[idx].bWasDecapitated && KFDamType.default.bCheckForHeadShots
            && (ZedVictim.bDecapitated || int(ZedVictim.HeadHealth) < MonsterInfos[idx].HeadHealth);

        if ( MonsterInfos[idx].bHeadshot ) {
            MonsterInfos[idx].RowHeadshots++;
            MonsterInfos[idx].Headshots++;

            // add Sharpshooter perk progress for every damage that is capable of stunning Scrakes
            if ( KFDamType.default.bSniperWeapon && Damage >= 667 && !ZedVictim.bDecapitated
                    && SRStatsBase(ScrnPC.SteamStatsAndAchievements) != none )
                SRStatsBase(ScrnPC.SteamStatsAndAchievements).AddHeadshotKill(false);
        }
        else if ( !ZedVictim.bDecapitated ) {
            MonsterInfos[idx].RowHeadshots = 0;
            if ( KFDamType.default.bCheckForHeadShots )
                MonsterInfos[idx].Bodyshots++;
            else
                MonsterInfos[idx].OtherHits++;
        }

        if ( Mods != none ) {
            Damage = Mods.ModifyMonsterDamage(MonsterInfos[idx], ScrnPC, OriginalDamage, Damage,
                    HitLocation, Momentum, KFDamType);
            if ( Damage == 0 )
                return Damage;
        }

        if ( (MonsterInfos[idx].bHeadshot || ZedVictim.bDecapitated)
                && KFDamType.default.HeadShotDamageMult < 1.0 && KFDamType.default.HeadShotDamageMult > 0 )
        {
            if ( bDamageAck && MonsterInfos[idx].bHeadshot ) {
                ScrnPC.DamageMade(Damage, HitLocation, 1, ZedVictim, KFDamType);
            }
            // weapon does less damage to head - make sure to do the rest of the damage to body
            Damage = Damage / KFDamType.default.HeadShotDamageMult + 1;

            if ( bDamageAck ) {
                if (MonsterInfos[idx].bHeadshot) {
                    ScrnPC.DamageMade(Damage - OriginalDamage, HitLocation, 0, ZedVictim, KFDamType);
                }
                else {
                    ScrnPC.DamageMade(Damage, HitLocation, 3, ZedVictim, KFDamType);
                }
            }
        }
        else if ( bDamageAck ) {
            // display damages on the hud
            if ( MonsterInfos[idx].bHeadshot )
                DamTypeNum = 1;
            else if ( KFDamType.default.bDealBurningDamage )
                DamTypeNum = 2;
            else if ( ZedVictim.bDecapitated )
                DamTypeNum = 3;

            if ( HitLocation == vect(0, 0, 0) ) //DoT
                HitLocation = injured.Location;
            ScrnPC.DamageMade(Damage, HitLocation, DamTypeNum, ZedVictim, KFDamType);
        }

        SPI = GetPlayerInfo(PlayerController(instigatedBy.Controller));
        // SPI.MadeDamage() calls AchHandlers.MonsterDamaged()
        if ( SPI != none )
            SPI.MadeDamage(Damage, ZedVictim, KFDamType, MonsterInfos[idx].bHeadshot, MonsterInfos[idx].bWasDecapitated);
    }
    else if ( ZedVictim != none ) {
        if ( Damage > 1 && KFMonster(instigatedBy) != none ) {
            // Monster2Monster damage
            if ( !Mut.bStoryMode && DamageType != class'SirenScreamDamage'
                    && KFMonsterController(ZedVictim.Controller) != none ) {
                // allow monsters fighting each other
                KFMonsterController(ZedVictim.Controller).bUseThreatAssessment = false;
            }
        }
    }
    else if ( KFHumanPawn(injured) != none ) {
        if ( KFMonster(instigatedBy) != none ) {
            // M2P damage
            idx = GetMonsterIndex(KFMonster(instigatedBy));
            MonsterInfos[idx].DamageCounter += Damage;
            // SPI.TookDamage() calls AchHandlers.PlayerDamaged()
            SPI = GetPlayerInfo(PlayerController(injured.Controller));
            if ( SPI != none )
                SPI.TookDamage(Damage, MonsterInfos[idx].Monster, DamageType);
        }
        else if ( DamageType == class'SirenScreamDamage' ) {
            // game bug: Siren doesn't set herself as the instigator when dealing screaming damage. Such a sneaky bicth!
            // Fixed in ScrnZedPack
            SPI = GetPlayerInfo(PlayerController(injured.Controller));
            if ( SPI != none )
                SPI.TookDamage(Damage, none, DamageType);
        }
        else if ( ScrnPC != none ) {
            // P2P damage
            if ( bShowDamages ) {
                if ( HitLocation == vect(0, 0, 0) ) //DoT
                    HitLocation = injured.Location;
                ScrnPC.DamageMade(Damage, HitLocation, 10, injured, KFDamType);
            }
        }
    }

    for ( i=0; i<AchHandlers.length; ++i ) {
        AchHandlers[i].NetDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
    }

    if ( ZedVictim != none ) {
        if ( bP2M ) {
            MonsterInfos[idx].LastHitTime = Level.TimeSeconds;
        }
        MonsterInfos[idx].HeadHealth = ZedVictim.HeadHealth;
        MonsterInfos[idx].bWasDecapitated = ZedVictim.bDecapitated;
        MonsterInfos[idx].bWasBackstabbed = ZedVictim.bBackstabbed;
    }

    return Damage;
}

function ScoreKill(Controller Killer, Controller Killed)
{
    local int i;

    if ( NextGameRules != None )
        NextGameRules.ScoreKill(Killer, Killed);

    for ( i=0; i<AchHandlers.length; ++i ) {
        AchHandlers[i].ScoreKill(Killer, Killed);
    }

    if ( Killed.bIsPlayer ) {
        AdjustZedSpawnRate();
        if ( Mut.bPlayerZEDTime && Killer != none && Killer != Killed )
            Mut.KF.DramaticEvent(1.0); // always zed time on player death
    }
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local ScrnPlayerInfo SPI;
    local int idx;
    local class<KFWeaponDamageType> KFDamType;
    local ScrnHumanPawn ScrnKillerPawn;

    if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
        return true;

    KFDamType = class<KFWeaponDamageType>(DamageType);
    if ( Killer != none ) {
        ScrnKillerPawn = ScrnHumanPawn(Killer.Pawn);
    }

    ++WaveTotalKills;
    if ( Killed.IsA('DoomMonster') ) {
        ++WaveDoom3Kills;
        ++GameDoom3Kills;
    }

    if (ScrnKillerPawn != none && ClassIsChildOf(KFDamType, class'DamTypeMachete') ) {
        ScrnKillerPawn.MacheteResetTime = Level.TimeSeconds + 3.0;
        ScrnKillerPawn.bMacheteDamageBoost = true;
    }

    if ( KFMonster(Killed) != none ) {
        if ( PlayerController(Killer) != none && KFDamType != none ) {
            SPI = GetPlayerInfo(PlayerController(Killer));
            if ( SPI != none ) {
                SPI.KilledMonster(KFMonster(Killed), KFDamType);
            }
        }
    }
    else if ( KFHumanPawn(Killed) != none && PlayerController(Killed.Controller) != none ) {
        ++WaveDeadPlayers;
        if ( Killer != none && KFMonster(Killer.Pawn) != none ) {
            // player killed by monster
            idx = GetMonsterIndex(KFMonster(Killer.Pawn));
            MonsterInfos[idx].PlayerKillCounter++;
            MonsterInfos[idx].PlayerKillTime = Level.TimeSeconds;
        }
        // don't count suicide deaths during trader time
        if ( !Mut.KF.bTradingDoorsOpen ) {
            SPI = GetPlayerInfo(PlayerController(Killed.Controller));
            if ( SPI != none ) {
                SPI.Died(Killer, DamageType);
            }
        }
        if ( Mut.bSpawn0 || Mut.bStoryMode ) {
            idx = Killed.Health;
            Killed.Health = max(Killed.Health, 1); // requires health to spawn second pistol
            class'ScrnHumanPawn'.static.DropAllWeapons(Killed); // toss all weapons after death, if bSpawn0=true or in Story Mode
            Killed.Health = idx;
        }
    }

    return false;
}

// reward assistants with TeamWork achievements
function RewardTeamwork(ScrnPlayerInfo KillerInfo, int MonsterIndex, name AchievementName)
{
    local int tc;
    if ( MonsterInfos[MonsterIndex].TW_Ach_Failed || MonsterInfos[MonsterIndex].Monster.bDamagedAPlayer )
        return;

    if ( KillerInfo != none )
        tc++;
    if ( MonsterInfos[MonsterIndex].KillAss1 != none && MonsterInfos[MonsterIndex].KillAss1 != KillerInfo)
        tc++;
    if ( MonsterInfos[MonsterIndex].KillAss2 != none && MonsterInfos[MonsterIndex].KillAss2 != KillerInfo
            && MonsterInfos[MonsterIndex].KillAss2 != MonsterInfos[MonsterIndex].KillAss1 )
        tc++;
    if ( tc < 2 )
        return; // Teamwork requires TEAM

    if ( KillerInfo != none )
        KillerInfo.ProgressAchievement(AchievementName, 1);

    if ( MonsterInfos[MonsterIndex].KillAss1 != none && MonsterInfos[MonsterIndex].KillAss1 != KillerInfo ) {
        MonsterInfos[MonsterIndex].KillAss1.ProgressAchievement(AchievementName, 1);
    }

    if ( MonsterInfos[MonsterIndex].KillAss2 != none && MonsterInfos[MonsterIndex].KillAss2 != KillerInfo
            && MonsterInfos[MonsterIndex].KillAss2 != MonsterInfos[MonsterIndex].KillAss1 ) {
        MonsterInfos[MonsterIndex].KillAss2.ProgressAchievement(AchievementName, 1);
    }
}

function ClearMonsterInfo(int index)
{
    MonsterInfos[index].Monster = none;
    MonsterInfos[index].HitCount = 0;
    MonsterInfos[index].FirstHitTime = 0;
    MonsterInfos[index].PlayerKillCounter = 0;
    MonsterInfos[index].DamageCounter = 0;
    MonsterInfos[index].PlayerKillTime = 0;
    MonsterInfos[index].KillAss1 = none;
    MonsterInfos[index].DamType1 = none;
    MonsterInfos[index].DamageFlags1 = 0;
    MonsterInfos[index].KillAss2 = none;
    MonsterInfos[index].DamType2 = none;
    MonsterInfos[index].DamageFlags2 = 0;
    MonsterInfos[index].TW_Ach_Failed = false;
    MonsterInfos[index].bHeadshot = false;
    MonsterInfos[index].RowHeadshots = 0;
    MonsterInfos[index].Headshots = 0;
    MonsterInfos[index].BodyShots = 0;
    MonsterInfos[index].OtherHits = 0;
    MonsterInfos[index].LastHitTime = 0;
    MonsterInfos[index].MaxHeadHealth = 0;
    MonsterInfos[index].HeadHealth = 0;
    MonsterInfos[index].bWasDecapitated = false;
}

//creates a new record, if monster not found
function int GetMonsterIndex(KFMonster Monster)
{
    local int i, count, free_index;

    if ( LastSeachedMonster == Monster )
        return LastFoundMonsterIndex;

    count = MonsterInfos.length;
    free_index = count;
    LastSeachedMonster = Monster;
    for ( i = 0; i < count; ++i ) {
        if ( MonsterInfos[i].Monster == Monster ) {
            LastFoundMonsterIndex = i;
            return i;
        }
        if ( free_index == count && MonsterInfos[i].Monster == none )
            free_index = i;
    }
    // if reached here - no monster is found, so init a first free record
    if ( free_index >= MonsterInfos.length ) {
        // if free_index out of bounds, maybe MaxZombiesOnce is changed during the game
        if ( MonsterInfos.length < Mut.KF.MaxZombiesOnce )
            MonsterInfos.insert(free_index, Mut.KF.MaxZombiesOnce - MonsterInfos.length);
        // MaxZombiesOnce was ok, just added extra monsters
        if ( free_index >= MonsterInfos.length )
            MonsterInfos.insert(free_index, 1);
    }
    ClearMonsterInfo(free_index);
    MonsterInfos[free_index].Monster = Monster;
    MonsterInfos[free_index].MaxHeadHealth = Monster.HeadHealth * Monster.DifficultyHeadHealthModifer() * Monster.NumPlayersHeadHealthModifer();
    MonsterInfos[free_index].HeadHealth = MonsterInfos[free_index].MaxHeadHealth;
    MonsterInfos[free_index].SpawnTime = Level.TimeSeconds;
    LastFoundMonsterIndex = free_index;
    return free_index;
}

// if monster not found - returns false
function bool RetrieveMonsterInfo(KFMonster Monster, out int index)
{
    if ( LastSeachedMonster == Monster ) {
        index = LastFoundMonsterIndex;
        return true;
    }

    for ( index = 0; index < MonsterInfos.length; ++index ) {
        if ( MonsterInfos[index].Monster == Monster ) {
            LastSeachedMonster = Monster;
            LastFoundMonsterIndex = index;
            return true;
        }
    }
    index = -1;
    return false;
}

function RegisterMonster(KFMonster Monster)
{
    local int i;

    GetMonsterIndex(Monster); // add to MonsterInfos

    if ( Mut.KF.bUseEndGameBoss && Mut.KF.WaveNum == Mut.KF.FinalWave && BossClass == none
            && GetItemName(Mut.KF.MonsterCollection.default.EndGameBossClass) ~= GetItemName(String(Monster.class)) )
    {
        InitBoss(Monster);
        return;
    }

    for ( i = 0; i < CheckedMonsterClasses.Length; ++i ) {
        if ( Monster.class == CheckedMonsterClasses[i] )
            return;
    }

    if ( Mut.IsSquadWaitingToSpawn() )
        return; // this monster is spawned by "mvote spawn", so ignore it in HL and achievement calculations

    //log("Monster=" $ String(Other) @ "Outer="$String(Other.outer) @ "OuterClass="$String(Other.class.outer), 'ScrnBalance');
    CheckedMonsterClasses[CheckedMonsterClasses.length] = Monster.class;
    CheckNewMonster(Monster);

    for ( i=0; i<AchHandlers.length; ++i )
        AchHandlers[i].MonsterIntroduced(Monster);
}

function CheckNewMonster(KFMonster Monster)
{
    local int i;
    local string MCS;

    MCS = GetItemName(string(Monster.Class));

    for ( i=0; i<HardcoreZeds.length; ++i ) {
        if ( !HardcoreZeds[i].bUsed && HardcoreZeds[i].MonsterClass ~= MCS ) {
            HardcoreZeds[i].bUsed = true;
            bHasCustomZeds = true;
            RaiseHardcoreLevel(HardcoreZeds[i].HL * ZedHLMult, Monster.MenuName);
            break;
        }
    }
}

function InitBoss(KFMonster Monster)
{
    local int i;
    local string BossClassStr;

    Boss = Monster;
    BossClass = Monster.class;
    BossClassStr = GetItemName(string(BossClass.name));
    bSuperPat = Monster.IsA('ZombieSuperBoss') || Monster.IsA('HardPat');
    bDoomPat = Monster.IsA('DoomMonster');

    for ( i=0; i<HardcoreBosses.length; ++i ) {
        if ( !HardcoreBosses[i].bUsed && HardcoreBosses[i].MonsterClass ~= BossClassStr ) {
            HardcoreBosses[i].bUsed = true;
            RaiseHardcoreLevel(HardcoreBosses[i].HL * ZedHLMult, Boss.MenuName);
            break;
        }
    }

    for ( i=0; i<AchHandlers.length; ++i )
        AchHandlers[i].BossSpawned(Monster);
}

function ReinitMonster(KFMonster Monster)
{
    local int index;

    index = GetMonsterIndex(Monster);
    MonsterInfos[index].MaxHeadHealth = Monster.HeadHealth;
    MonsterInfos[index].HeadHealth = Monster.HeadHealth;
}

// called from ScrnNade
function ScrakeNaded(ZombieScrake Scrake)
{
    local int index;

    index = GetMonsterIndex(Scrake);
    MonsterInfos[index].DamType2 = class'KFMod.DamTypeFrag';
    MonsterInfos[index].DamageFlags2 = DF_RAGED | DF_STUPID;
}

// returns true if last damage to zed was a headshot
function bool WasHeadshot(KFMonster Monster)
{
    local int idx;

    return RetrieveMonsterInfo(Monster, idx) && MonsterInfos[idx].bHeadshot;
}

function InitHardcoreLevel()
{
    local int i;
    local string GameClass;

    GameClass = GetItemName(string(Level.Game.Class));

    if ( Level.Game.GameDifficulty >= 7 ) {
       HardcoreLevelFloat = HL_HoE;
       ZedHLMult = HLMult_HoE;
    }
    else if ( Level.Game.GameDifficulty >= 5 ) {
       HardcoreLevelFloat = HL_Suicidal;
       ZedHLMult = HLMult_Suicidal;
    }
    else if ( Level.Game.GameDifficulty >= 4 ) {
       HardcoreLevelFloat = HL_Hard;
       ZedHLMult = HLMult_Hard;
    }
    else {
       HardcoreLevelFloat = HL_Normal;
       ZedHLMult = HLMult_Normal;
    }

    if ( Mut.bHardcore ) {
        HardcoreLevelFloat += HL_Hardcore;
        ZedHLMult += HLMult_Hardcore;
    }

    for ( i=0; i<HardcoreGames.length; ++i ) {
        if ( HardcoreGames[i].GameClass ~= GameClass ) {
            HardcoreLevelFloat += HardcoreGames[i].HL;
            break;
        }
    }

    HardcoreLevel = int(HardcoreLevelFloat+0.01);
    // replicate to clients
    Mut.HardcoreLevel = clamp(HardcoreLevel,0,255);
}

function RaiseHardcoreLevel(float inc, string reason)
{
    local string s;

    if ( bForceHardcoreLevel )
        return;

    if ( HardcoreLevelFloat < HardcoreLevel )
        HardcoreLevelFloat = HardcoreLevel; // just to be sure

    HardcoreLevelFloat = fclamp(HardcoreLevelFloat + inc, 0, 255);
    HardcoreLevel = int(HardcoreLevelFloat+0.01);
    // replicate to clients
    Mut.HardcoreLevel = clamp(HardcoreLevel,0,255);
    Mut.NetUpdateTime = Level.TimeSeconds - 1;

    if ( bBroadcastHL ) {
        if ( inc >= 0 )
            s = msgHardcore;
        else
            s = msgHardcoreLowered;
        ReplaceText(s, "%a", String(HardcoreLevel));
        ReplaceText(s, "%i", String(inc));
        ReplaceText(s, "%r", reason);
        Mut.BroadcastMessage(s, true);
    }
}

function ForceHardcoreLevel(int value)
{
    HardcoreLevel = value;
    HardcoreLevelFloat = value;
    bForceHardcoreLevel = true;
    // replicate to clients
    Mut.HardcoreLevel = clamp(HardcoreLevel,0,255);
}

function WeaponReloaded(PlayerController WeaponOwner, KFWeapon W)
{
    local ScrnPlayerInfo SPI;

    SPI = GetPlayerInfo(WeaponOwner);
    if ( SPI != none )
        SPI.WeaponReloaded(W);
}

function WeaponFire(PlayerController WeaponOwner, KFWeapon W, byte FireMode)
{
    local ScrnPlayerInfo SPI;

    SPI = GetPlayerInfo(WeaponOwner);
    if ( SPI != none )
        SPI.WeaponFired(W, FireMode);
}


function RegisterAchHandler(ScrnAchHandlerBase Handler)
{
    local int i;

    for ( i=0; i<AchHandlers.length; ++i ) {
        if ( AchHandlers[i] == Handler )
            return;
    }
    AchHandlers[AchHandlers.length] = Handler;
}

function ScrnPlayerInfo GetPlayerInfo(PlayerController PlayerOwner)
{
    local ScrnPlayerInfo SPI;

    if ( PlayerOwner == none )
        return none;

    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner == PlayerOwner )
            return SPI;
    }
    return none;
}

function int AlivePlayerCount()
{
    return WavePlayerCount - WaveDeadPlayers;
}

function int PlayerCountInWave()
{
    return WavePlayerCount;
}

/**
 * Increments achievement progress for all players who have PlayerInfo object, except ExcludeSPI.
 * @param AchID         Achievement ID
 * @param Inc             Achievement progress. Usually 1.
 * @param bOnlyAlive    if true, then achievement will not be granted for dead players (SPI.bDied = true)
 * @param ExcludeSPI    player to exclude from achievement progress.
 */
// if bOnlyAlive=true, then achievment will not be granted for dead players (bDied = true)
function ProgressAchievementForAllPlayers(name AchID, int Inc, optional bool bOnlyAlive,
        optional ScrnPlayerInfo ExcludeSPI, optional TeamInfo Team)
{
    local ScrnPlayerInfo SPI;

    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI != ExcludeSPI && SPI.PlayerOwner != none
                && (!SPI.bDied || !bOnlyAlive)
                && SPI.PlayerOwner.PlayerReplicationInfo != none
                && (Team == none || SPI.PlayerOwner.PlayerReplicationInfo.Team == Team)
            )
        {
            SPI.ProgressAchievement(AchID, Inc);
        }
    }
}

final private function BackupOrDestroySPI(ScrnPlayerInfo SPI)
{
    if ( SPI.SteamID32 > 0 && (SPI.PRI_Kills > 0 || SPI.PRI_Deaths > 0 || SPI.PRI_KillAssists > 0
            || SPI.HasCustomPlayerInfo() ) )
    {
        if ( BackupPlayerInfo == none ) {
            SPI.NextPlayerInfo = none;
            BackupPlayerInfo = SPI;
        }
        else {
            SPI.NextPlayerInfo = BackupPlayerInfo;
            BackupPlayerInfo = SPI;
        }
    }
    else
        SPI.Destroy();
}

// destroys player infos without PlayerOwner
final function ClearNonePlayerInfos()
{
    local ScrnPlayerInfo SPI, PrevSPI;

    while ( PlayerInfo!=none && (PlayerInfo.PlayerOwner == none || PlayerInfo.PlayerOwner.Pawn == none) )
    {
        PrevSPI = PlayerInfo;
        PlayerInfo = PrevSPI.NextPlayerInfo;
        BackupOrDestroySPI(PrevSPI);
    }

    if ( PlayerInfo == none )
        return;

    PrevSPI = PlayerInfo;
    // we already know that PlayerInfo has PlayerOwner, otherwise we won't reach here
    SPI = PrevSPI.NextPlayerInfo;
    while ( SPI != none ) {
        if ( SPI.PlayerOwner == none || PlayerInfo.PlayerOwner.Pawn == none ) {
            PrevSPI.NextPlayerInfo = SPI.NextPlayerInfo;
            BackupOrDestroySPI(SPI);
        }
        else {
            PrevSPI = SPI;
        }
        SPI = PrevSPI.NextPlayerInfo;
    }
}

/**
 * Returns ScrnPlayerInfo (SPI) object for given PlayerController. If SPI object already exists and
 * active (i.e. player is in the game), then just returns it. If there is no active SPI record found,
 * function looks for backup, comparing by SteamID32 (in case of reconnecting players).
 * If SPI object is not found in both active and backup lists, then creates a new one.
 *
 * @param   PlayerOwner             PlayerController, which owns the SPI object. Note that it means
 *                                  SPI.PlayerOwner = PlayerOwner, NOT SPI.Owner (latter is none)
 * @param   bDontRestoreFromBackup  This parameter is used only when SPI object is in the backup.
 *                                  True means it will be kept in backup.
 *                                  False means it will be restored to active player info list.
 * @return  SPI object which is linked to given PlayerOwner. Theoretically function always should returns
 *          a valid pointer.
 */
final function ScrnPlayerInfo CreatePlayerInfo(PlayerController PlayerOwner, optional bool bDontRestoreFromBackup)
{
    local ScrnPlayerInfo SPI, PrevSPI;
    local ScrnCustomPRI ScrnPRI;
    local int SteamID32;

    if ( PlayerOwner == none )
        return none;

    // Does it exist and active?
    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner == PlayerOwner )
            return SPI;
    }

    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PlayerOwner.PlayerReplicationInfo);
    if ( ScrnPRI != none )
        SteamID32 = ScrnPRI.GetSteamID32();
    // check by SteamID for quickly reconnecting players (e.g. crashed)
    if ( SteamID32 > 0 ) {
        for ( SPI = PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
            if ( SPI.SteamID32 == SteamID32 ) {
                SPI.PlayerOwner = PlayerOwner;
                SPI.RestorePRI();
                return SPI;
            }
        }
    }

    // Check for backup
    if ( BackupPlayerInfo != none && SteamID32 > 0 ) {
        for ( SPI = BackupPlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
            if ( SPI.SteamID32 == SteamID32) {
                if ( SPI.PlayerOwner != PlayerOwner ) {
                    SPI.PlayerOwner = PlayerOwner;
                    SPI.RestorePRI();
                }

                if ( bDontRestoreFromBackup ) {
                    //remove from backup
                    if ( PrevSPI != none )
                        PrevSPI.NextPlayerInfo = SPI.NextPlayerInfo;
                    else
                        BackupPlayerInfo = SPI.NextPlayerInfo;
                    SPI.NextPlayerInfo = none;

                    // link to PlayerInfo list
                    if ( PlayerInfo == none )
                        PlayerInfo = SPI;
                    else {
                        SPI.NextPlayerInfo = PlayerInfo;
                        PlayerInfo = SPI;
                    }
                }

                return SPI;
            }
            PrevSPI = SPI;
        }
    }

    // not active and not backed up - create a new one
    SPI = spawn(class'ScrnPlayerInfo');
    if ( SPI == none ) {
        // this never should happen
        log("Unable to spawn ScrnPlayerInfo!", 'ScrnBalance');
        return none;
    }

    if ( PlayerInfo == none )
        PlayerInfo = SPI;
    else {
        SPI.NextPlayerInfo = PlayerInfo;
        PlayerInfo = SPI;
    }
    // initial data
    SPI.PlayerOwner = PlayerOwner;
    SPI.GameRules = self;
    SPI.PlayerName = Mut.StripColorTags(PlayerOwner.PlayerReplicationInfo.PlayerName);
    SPI.SteamID32 = SteamID32;
    SPI.StartWave = Mut.KF.WaveNum;
    SPI.BackupStats(SPI.GameStartStats);
    SPI.ProgressAchievement('Welcome', 1);
    return SPI;
}

function DebugSPI(PlayerController Sender)
{
    local ScrnPlayerInfo SPI;

    Sender.ClientMessage("Active SPIs:");
    Sender.ClientMessage("------------------------------------");
    for ( SPI = Mut.GameRules.PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner != none )
            Sender.ClientMessage(SPI.SteamID32 @ SPI.PlayerOwner.PlayerReplicationInfo.PlayerName
                @  SPI.PRI_Kills @ "Machete-steps: " $ SPI.GetCustomValue(none, 'MacheteWalker') );
        else
            Sender.ClientMessage(SPI.SteamID32 @ "none" @  SPI.PRI_Kills );
    }
    Sender.ClientMessage("------------------------------------");
    Sender.ClientMessage("Backup SPIs:");
    Sender.ClientMessage("------------------------------------");
    for ( SPI = Mut.GameRules.BackupPlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner != none )
            Sender.ClientMessage(SPI.SteamID32 @ SPI.PlayerOwner.PlayerReplicationInfo.PlayerName @  SPI.PRI_Kills );
        else
            Sender.ClientMessage(SPI.SteamID32 @ "none" @  SPI.PRI_Kills );
    }
}


/* OverridePickupQuery()
when pawn wants to pickup something, gamerules given a chance to modify it.  If this function
returns true, bAllowPickup will determine if the object can be picked up.
*/
function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
    local bool result;
    local KFWeaponPickup WP;
    local CashPickup Cash;
    local ScrnPlayerInfo SPI;
    local string str;
    local ScrnHumanPawn ScrnPawn;

    if ( Other.Health <= 0 ) {
        bAllowPickup = 0; // prevent dying bodies of picking up items
        return true;
    }

    ScrnPawn = ScrnHumanPawn(Other);

    Mut.ReplacePickup(item);    // replace pickup's inventory with ScrN version
    WP = KFWeaponPickup(item);
    Cash = CashPickup(item);
    if ( Mut.bPickPerkedWeaponsOnly && WP != none && ScrnPawn != none
        && WP.CorrespondingPerkIndex != 7 //off-perk
        && WP.CorrespondingPerkIndex != ScrnPawn.ScrnPerk.default.PerkIndex
        && !ScrnPawn.ScrnPerk.static.OverridePerkIndex(WP.class) )
    {
        if ( PlayerController(Other.Controller) != none )
            PlayerController(Other.Controller).ClientMessage(Mut.ColorString(strPerkedWeaponsOnly,192,100,1));
        result = true;
        bAllowPickup = 0;
    }
    else if ( NextGameRules != None )
        result = NextGameRules.OverridePickupQuery(Other, item, bAllowPickup);

    if ( !result || bAllowPickup == 1 )    {
        if ( WP != none ) {
            // weapon lock and broadcast
            if ( WP.DroppedBy != Other.Controller
                    && WP.DroppedBy != none && WP.DroppedBy.PlayerReplicationInfo != none )
            {
                if ( ScrnPlayerController(WP.DroppedBy) != none && ScrnPlayerController(WP.DroppedBy).bWeaponsLocked
                        && (Other.PlayerReplicationInfo == none || WP.DroppedBy.PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team) )
                {
                    // ScrN Players can lock weapons from picking up by teammates
                    result = true;
                    bAllowPickup = 0;
                    if ( ScrnPlayerController(Other.Controller) != none && Level.TimeSeconds > ScrnPlayerController(Other.Controller).LastLockMsgTime + 1.0 ) {
                        str = strWeaponLocked;
                        ReplaceText(str, "%o",  Mut.ColoredPlayerName(WP.DroppedBy.PlayerReplicationInfo));
                        ReplaceText(str, "%w", WP.ItemName);
                        ScrnPlayerController(Other.Controller).ClientMessage(Mut.ColorString(str,192,1,1));
                        ScrnPlayerController(Other.Controller).LastLockMsgTime = Level.TimeSeconds;
                    }
                }
                else if ( ScrnPlayerController(Other.Controller) != none && ScrnPlayerController(Other.Controller).bWeaponsLocked ) {
                    // Players cannot pick other's weapons while own weapons are locked
                    result = true;
                    bAllowPickup = 0;
                    if ( Level.TimeSeconds > ScrnPlayerController(Other.Controller).LastLockMsgTime + 1.0 ) {
                        ScrnPlayerController(Other.Controller).ClientMessage(Mut.ColorString(strWeaponLockedOwn,192,128,1));
                        ScrnPlayerController(Other.Controller).LastLockMsgTime = Level.TimeSeconds;
                    }
                }
                else if ( WP.SellValue > 0 && Mut.bBroadcastPickups && !HasInventoryClass(Other, WP.InventoryType) )
                    Mut.StolenWeapon(Other, WP);
            }
        }

        if ( !result || bAllowPickup == 1 )    {
            SPI = GetPlayerInfo(PlayerController(Other.Controller));
            if ( SPI != none ) {
                if ( WP != none ) {
                    if ( Mods != none && !Mods.AllowWeaponPickup(SPI, WP) ) {
                        result = true;
                        bAllowPickup = 0;
                    }
                    else {
                        SPI.PickedWeapon(WP);
                    }
                }
                else if ( Cash != none ) {
                    if ( Mods != none && !Mods.AllowCashPickup(SPI, Cash) ) {
                        result = true;
                        bAllowPickup = 0;
                    }
                    else {
                        SPI.PickedCash(Cash);
                    }
                }
                else {
                    SPI.PickedItem(item);
                }
            }
        }
    }
    return result;
}

function bool CanBuyWeapon(ScrnHumanPawn P, class<KFWeaponPickup> WP)
{
    local ScrnPlayerController PC;
    local ScrnClientPerkRepLink PerkLink;
    local byte BuyRules;
    local string s;

    PC = ScrnPlayerController(P.Controller);
    if ( PC == none )
        return true;  // shouldn't happen, maybe a bot?

    PerkLink = class'ScrnClientPerkRepLink'.static.FindMe(PC);
    if ( PerkLink != none && !PerkLink.IsInShopInventory(WP) )
        return false;

    BuyRules = BUY_ALLOW;
    if ( Mods == none || !Mods.OverrideWeaponBuy(PC, WP, BuyRules) ) {
        DefaultOverrideWeaponBuy(PC, WP, BuyRules);
    }

    if ( (BuyRules & BUY_BLAME) != 0 ) {
        s = msgWeaponBlame;
        ReplaceText(s, "%w", WP.default.ItemName);
        Mut.BlamePlayer(PC, s);
    }

    if ( (BuyRules & BUY_ALLOW) != 0 && (BuyRules & BUY_MEGA_OP) != 0 ) {
        if ( (BuyRules & BUY_MEGA_OP) == BUY_MEGA_OP )
            RaiseHardcoreLevel(-4, WP.default.ItemName);
        else if ( (BuyRules & BUY_OP) != 0 )
            RaiseHardcoreLevel(-2, WP.default.ItemName);
        else
            RaiseHardcoreLevel(-1, WP.default.ItemName);
    }

    return (BuyRules & BUY_ALLOW) != 0;
}

function DefaultOverrideWeaponBuy(ScrnPlayerController PC, class<KFWeaponPickup> WP, out byte BuyRules)
{
    local class<KFWeapon> WC;
    local bool bBossWave;

    bBossWave = Mut.ScrnGT != none && Mut.ScrnGT.bUseEndGameBoss && Mut.ScrnGT.WaveNum >= Mut.ScrnGT.FinalWave;
    WC = class<KFWeapon>(WP.default.InventoryType);
    if ( WC == none )
        return;

    if ( bBossWave ) {
        if ( class<M99SniperRifle>(WC) != none ) {
            BuyRules = BUY_ALLOW | BUY_BLAME | BUY_SLIGHTLY_OP;
        }
        else if ( WC.name == 'RPG' ) {
            BuyRules = BUY_ALLOW | BUY_BLAME | BUY_MEGA_OP;
        }
        else if ( WC.name == 'M41AAssaultRifle' ) {
            BuyRules = BUY_ALLOW | BUY_BLAME | BUY_OP;
        }
    }
}

function bool HasInventoryClass( Pawn P, class<Inventory> IC )
{
    local Inventory I;

    if ( P == none || IC == none )
        return false;

    for ( I=P.Inventory; I!=None; I=I.Inventory )
        if( I.Class==IC )
            return true;
    return false;
}

defaultproperties
{
    msgHardcore="Hardcore level raised to %a (+%i for %r)"
    msgHardcoreLowered="Hardcore level lowered down to %a (%i for %r)"
    msgWeaponBlame="%p blamed for buying %w"
    msgDoom3Monster="Doom3 monsters"
    msgDoom3Boss="Doom Boss"
    msgDoomPercent="Doom3 monster count in wave = %p%"
    strWeaponLocked="%w locked by %o"
    strWeaponLockedOwn="Can not pickup another's weapons while own are locked"
    strPerkedWeaponsOnly="You can pickup perked weapons only"
    strWaveAccuracy="%p scored %a accuracy in this wave!"

    AchClass=class'ScrnBalanceSrv.ScrnAchievements'
    MapAchClass=class'ScrnBalanceSrv.ScrnMapAchievements'

    MapAliases(0)=(FileName="KF-HarbourV3-fix",AchName="KF-HarbourV3")
    MapAliases(1)=(FileName="KF-Harbor",AchName="KF-HarbourV3")
    MapAliases(2)=(FileName="KF-SantasRetreatFinal1-1",AchName="KF-SantasRetreat")
    MapAliases(3)=(FileName="KF-BigSunriseBeta1-6",AchName="KF-BigSunrise")
    MapAliases(4)=(FileName="KF-SunnyLandSanitariumBeta1-5",AchName="KF-SunnyLandSanitarium")
    MapAliases(5)=(FileName="KF-SilentHillBeta2-0",AchName="KF-SilentHill")
    MapAliases(6)=(FileName="KF-HellGateFinal1-2",AchName="KF-HellGate")
    MapAliases(7)=(FileName="Kf-HellFinal1-5",AchName="KF-Hell")
    MapAliases(8)=(FileName="KF-Doom2-Final-V7",AchName="KF-D2M1")
    MapAliases(9)=(FileName="KF-Doom2-HiRes",AchName="KF-D2M1")
    MapAliases(10)=(FileName="KF-Doom2-HiRes11",AchName="KF-D2M1")
    MapAliases(11)=(FileName="KF-ZedDiscoThe1stFloor",AchName="KF-ZedDisco")
    MapAliases(12)=(FileName="KF-ZedDiscoThe2ndFloor",AchName="KF-ZedDisco")
    MapAliases(13)=(FileName="KF-Abandoned-Moonbase",AchName="KF-MoonBase")
    MapAliases(14)=(FileName="KF-DepartedNight",AchName="KF-Departed")
    MapAliases(15)=(FileName="KF-FoundryLightsOut",AchName="KF-Foundry")
    MapAliases(16)=(FileName="KF-HospitalhorrorsLightsOut",AchName="KF-Hospitalhorrors")
    MapAliases(17)=(FileName="KF-Doom2-SE",AchName="KF-D2M1")
    MapAliases(18)=(FileName="KF-Icebreaker-SE",AchName="KF-Icebreaker")
    MapAliases(19)=(FileName="KF-HellFreezesOver1-2",AchName="KF-Hell")
    MapAliases(20)=(FileName="KF-Train-fix",AchName="KF-Train")
    MapAliases(21)=(FileName="KF-PandorasBoxV2-fix",AchName="KF-PandorasBox")
    MapAliases(22)=(FileName="KF-Constriction-SE",AchName="KF-Constriction")

    SovietDamageTypes(0)=class'KFMod.DamTypeKnife'
    SovietDamageTypes(1)=class'KFMod.DamTypeFrag'
    SovietDamageTypes(2)=class'KFMod.DamTypeAK47AssaultRifle'
    SovietDamageTypes(3)=class'ScrnBalanceSrv.ScrnDamTypeAK47AssaultRifle'

    bBroadcastHL=true
    HL_Normal=0
    HLMult_Normal=0.5
    HL_Hard=2
    HLMult_Hard=0.75
    HL_Suicidal=5
    HLMult_Suicidal=1.0
    HL_HoE=7
    HLMult_HoE=1.25
    HL_Hardcore=2
    HLMult_Hardcore=0.15

    HardcoreBosses(00)=(MonsterClass="HardPat",HL=2)
    HardcoreBosses(01)=(MonsterClass="HardPatC",HL=2)
    HardcoreBosses(02)=(MonsterClass="HardPatG",HL=2)
    HardcoreBosses(03)=(MonsterClass="HardPatH",HL=2)
    HardcoreBosses(04)=(MonsterClass="HardPatX",HL=2)
    HardcoreBosses(05)=(MonsterClass="ZombieSuperBoss",HL=2)
    HardcoreBosses(06)=(MonsterClass="Sabaoth",HL=2)
    HardcoreBosses(07)=(MonsterClass="Vagary",HL=2)
    HardcoreBosses(08)=(MonsterClass="Maledict",HL=2)
    HardcoreBosses(09)=(MonsterClass="HunterInvul",HL=2)
    HardcoreBosses(10)=(MonsterClass="HunterBerserk",HL=2)
    HardcoreBosses(11)=(MonsterClass="HunterHellTime",HL=2)
    HardcoreBosses(12)=(MonsterClass="Guardian",HL=2)
    HardcoreBosses(13)=(MonsterClass="Cyberdemon",HL=2)

    HardcoreZeds(00)=(MonsterClass="Ghost",HL=0.5)
    HardcoreZeds(01)=(MonsterClass="Shiver",HL=1.0)
    HardcoreZeds(02)=(MonsterClass="Jason",HL=1.5)
    HardcoreZeds(03)=(MonsterClass="TeslaHusk",HL=1.5)
    HardcoreZeds(04)=(MonsterClass="Brute",HL=2.0)
    HardcoreZeds(05)=(MonsterClass="FemaleFP",HL=2.5)
    HardcoreZeds(06)=(MonsterClass="FemaleFP_MKII",HL=2.5)
    HardcoreZeds(07)=(MonsterClass="ZombieSuperStalker",HL=0.3)
    HardcoreZeds(08)=(MonsterClass="ZombieSuperGorefast",HL=0.3)
    HardcoreZeds(09)=(MonsterClass="GorefastG",HL=0.3)
    HardcoreZeds(10)=(MonsterClass="ZombieSuperCrawler",HL=0.3)
    HardcoreZeds(11)=(MonsterClass="ZombieSuperBloat",HL=0.3)
    HardcoreZeds(12)=(MonsterClass="BloatG",HL=0.3)
    HardcoreZeds(13)=(MonsterClass="ZombieSuperSiren",HL=1.0)
    HardcoreZeds(14)=(MonsterClass="ZombieSuperFP",HL=1.0)
    HardcoreZeds(15)=(MonsterClass="ZombieSuperHusk",HL=1.4)
    HardcoreZeds(16)=(MonsterClass="HuskG",HL=1.4)
    HardcoreZeds(17)=(MonsterClass="ZombieSuperScrake",HL=1.4)
    HardcoreZeds(18)=(MonsterClass="Imp",HL=1)
    HardcoreZeds(19)=(MonsterClass="Pinky",HL=1)
    HardcoreZeds(20)=(MonsterClass="Archvile",HL=1)
    HardcoreZeds(21)=(MonsterClass="HellKnight",HL=1)
    HardcoreZeds(22)=(MonsterClass="Sabaoth",HL=1)
    HardcoreZeds(23)=(MonsterClass="Vagary",HL=1)
    HardcoreZeds(24)=(MonsterClass="Maledict",HL=1)
    HardcoreZeds(25)=(MonsterClass="HunterInvul",HL=1)
    HardcoreZeds(26)=(MonsterClass="HunterBerserk",HL=1)
    HardcoreZeds(27)=(MonsterClass="HunterHellTime",HL=1)
    HardcoreZeds(28)=(MonsterClass="Guardian",HL=1)
    HardcoreZeds(29)=(MonsterClass="Cyberdemon",HL=1)

    HardcoreGames(0)=(GameClass="ScrnStoryGameInfo",HL=3)
    HardcoreGames(1)=(GameClass="TSCGame",HL=6)
    HardcoreGames(2)=(GameClass="FtgGame",HL=6)
    HardcoreGames(3)=(GameClass="TurboGame",HL=3)
    HardcoreGames(4)=(GameClass="FscGame",HL=10)
}
