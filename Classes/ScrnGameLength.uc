Class ScrnGameLength extends Object
    dependson(ScrnTypes)
    dependson(ScrnWaveInfo)
    PerObjectConfig
    Config(ScrnGames);

// Deprecated config options. Those will be delete in future, so make sure not to use them.
var deprecated bool bStartingCashReset;
var deprecated int StartingCashBonus;
var deprecated bool bStartingCashRelative;


var ScrnGameType Game;
var TscGame TSC;
var FtgGame FTG;
var ScrnBalance Mut;
var ScrnWaveRule Rule;

var class<ScrnWaveInfo> WaveInfoClass;
var class<ScrnZedInfo> ZedInfoClass;

var config int GameVersion;
var config string GameTitle;
var config string Author;
var config int StartDosh, StartDoshPerWave, StartDoshMin, StartDoshMax;
var int RecommendedStartDosh;
var config float BountyScale;
var float NoBountyTime;
var config array<string> ServerPackages;
var config array<string> Mutators;
var config array<string> Waves;
var config array<string> Zeds;
var config bool bUniqueWaves;
var config bool bAllowZedEvents;
var config byte ForceZedEvent, FallbackZedEvent;
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

var class<KFMonster> FallbackZed;
var array<ScrnZedInfo> ZedInfos;
var array<string> ZedVotes;

struct SSpawnCandidate {
    var class<KFMonster> ZedClass;
    var float Chance;
};

struct SActiveZed {
    var string Alias;
    var array<SSpawnCandidate> Candidates;
    var int WaveSpawns, TotalSpawns;
};
var array<SActiveZed> ActiveZeds;
var array < class<KFMonster> > AllZeds;

const SQUAD_BREAK = -1;
// per-wave data
struct SSquadMember {
    var int ActiveZedIndex; // item index in ActiveZeds array
    var int Count;
};

struct SSquad {
    var bool bKeepWithPrev;
    var byte MinPlayers;
    var byte MaxPlayers;
    var byte ScaleByPlayers;
    var array<SSquadMember> Members;
};
var array<SSquad> Squads;
var array<SSquad> SpecialSquads;
var array<int> PendingSquads;
var array<int> PendingSpecialSquads;

var transient array < class<KFMonster> > PendingNextSpawnSquad;

var ScrnWaveInfo Wave, NextWave;
var protected int NextWaveNum;
var transient int ZedsBeforeSpecial;
var transient bool bLoadedSpecial;  // is the last loaded squad special
var transient bool bBossSpawned;
var transient int LoadedCount;  // loaded monster count (without squad breaks)
var transient float PlayerCountOverrideForHealth;
var transient array<name> AllowWeapons, BlockWeapons;
var transient array<string> UsedWaves;

var transient float WaveEndTime;
var transient int WaveCounter;
var transient float Timelimit;
var transient bool bTimelimit30;

struct SZedCmdCache {
    var string Alias;
    var int LastCmdIdx;
};
var transient array<SZedCmdCache> ZedCmdCache;

var class<ScrnGameDialogueHandler> DialogueHandlerClass;
var ScrnGameDialogueHandler DialogueHandler;
var transient bool bSkipDialogue;

// Called from InitGame()
// WARNING! GameReplicationInfo does not yet exist at this moment
function LoadGame(ScrnGameType MyGame)
{
    local int i, j;
    local ScrnZedInfo zi;
    local class<KFMonster> zedc;
    local byte HardcoreDifficulty;

    Game = MyGame;
    TSC = TscGame(MyGame);
    FTG = FtgGame(MyGame);
    Mut = Game.ScrnBalanceMut;

    if ( bTest ) {
        Mut.SetTestMap();
    }

    if ( bDebug ) {
        Game.MaximizeDebugLogging();
    }

    FtgSpawnRateMod = fclamp(FtgSpawnRateMod, 0.2, 1.0);
    MinDifficulty = clamp(MinDifficulty, Game.DIFF_MIN, Game.DIFF_MAX);
    if ( MaxDifficulty == 0 ) {
        MaxDifficulty = Game.DIFF_MAX;
    }
    else {
        MaxDifficulty = clamp(MaxDifficulty, MinDifficulty, Game.DIFF_MAX);
    }
    HardcoreDifficulty = Mut.GetHardcoreDifficulty();
    if ( HardcoreDifficulty < MinDifficulty ) {
        Mut.SetGameDifficulty(MinDifficulty);
        HardcoreDifficulty = Mut.GetHardcoreDifficulty();
    }
    else if ( HardcoreDifficulty > MaxDifficulty ) {
        Mut.SetGameDifficulty(MaxDifficulty);
        HardcoreDifficulty = Mut.GetHardcoreDifficulty();
    }
    else {
        ApplyGameDifficulty(HardcoreDifficulty);
        Mut.SetLevels();
    }

    for ( i = 0; i < ServerPackages.length; ++i ) {
        Log("Add server package: " $ ServerPackages[i], class.name);
        Game.AddToPackageMap(ServerPackages[i]);
    }

    for ( i = 0; i < Mutators.length; ++i ) {
        if ( Mutators[i] != "" )  {
            Log("Loading additional mutator: " $ Mutators[i], class.name);
            Game.AddMutator(Mutators[i], true);
        }
    }

    if (TraderSpeedBoost != 0) {
        Mut.bTraderSpeedBoost = TraderSpeedBoost > 0;
        Mut.SetReplicationData();
    }

    log("WaveInfoClass=" $ WaveInfoClass, class.name);
    log("ZedInfoClass=" $ ZedInfoClass, class.name);

    if (bAllowZedEvents) {
        if (ForceZedEvent > 0) {
            Mut.CurrentEventNum = ForceZedEvent;
        }
        if (Mut.CurrentEventNum == Mut.ZEDEVENT_RANDOM) {
            PickRandomZedEvent();
        }
        else if (Mut.CurrentEventNum > 0) {
            log("ZED Event " $ Mut.CurrentEventNum, class.name);
        }
        else if (FallbackZedEvent > 0) {
            Mut.CurrentEventNum = FallbackZedEvent;
            log("ZED Event " $ Mut.CurrentEventNum $ " (fallback)", class.name);
        }
    }
    else if (Mut.CurrentEventNum > 0) {
        Mut.CurrentEventNum = 0;
        log("ZED Events disabled", class.name);
    }

    ZedInfos.length = Zeds.length;
    for ( i = 0; i < Zeds.length; ++i ) {
        zi = new(none, Zeds[i]) ZedInfoClass;

        if ( bAllowZedEvents && zi.EventNum != Mut.CurrentEventNum
                && zi.EventNum != 0 && Mut.CurrentEventNum != 0 ) {
            continue;
        }

        for ( j = 0; j < zi.Zeds.length; ++j ) {
            if ( zi.Zeds[j].Vote != "" )
                AddZedVote(zi.Zeds[j].Vote);

            if ( zi.Zeds[j].bDisabled )
                continue;

            zedc = class<KFMonster>(DynamicLoadObject(zi.Zeds[j].ZedClass, class'Class'));
            if ( zedc == none ) {
                Game.LogZedSpawn(Game.LOG_WARN, "Unable to load zed class '" $ zi.Zeds[j].ZedClass $ "' for "
                        $ zi.Zeds[j].Alias);
                continue;
            }

            if ( zedc.outer.name != 'KFChar' ) {
                Game.AddToPackageMap(string(zedc.outer.name));
                if ( zi.Zeds[j].Package != "" )
                    Game.AddToPackageMap(zi.Zeds[j].Package);
            }

            AddActiveZed(zi.Zeds[j].Alias, zedc, zi.Zeds[j].Pct);
        }

        // store zed info for config save after voting
        ZedInfos[i] = zi;
    }
    for ( i = 0; i < ZedInfos.length; ++i ) {
        if (ZedInfos[i] == none) {
            ZedInfos.remove(i--, 1);
        }
    }

    if ( ActiveZeds.length == 0 ) {
        Game.LogZedSpawn(Game.LOG_ERROR, "No active zeds! Loading fallback zeds");
        for ( j = 0; j < ZedInfoClass.default.Zeds.length; ++j ) {
            zedc = class<KFMonster>(DynamicLoadObject(ZedInfoClass.default.Zeds[j].ZedClass, class'Class'));
            if ( zedc == none ) {
                Game.LogZedSpawn(Game.LOG_ERROR, "Unable to load a fallback zed class '"
                        $ ZedInfoClass.default.Zeds[j].ZedClass);
                continue;
            }
            AddActiveZed(ZedInfoClass.default.Zeds[j].Alias, zedc, 0.f);
        }
    }
    RecalculateSpawnChances();

    Game.LogZedSpawn(Game.LOG_INFO, AllZeds.length $ " unique zeds");
    if ( Game.Level.NetMode != NM_DedicatedServer ) {
        for ( i = 0; i < AllZeds.length; ++i ) {
            AllZeds[i].static.PreCacheAssets(Game.Level);
        }
    }

    if ( ZedVotes.length > 0 )
        AddVoting();

    if (ZedTimeTrigger != ZT_Default) {
        Game.ZedTimeTrigger = ZedTimeTrigger;
        Game.ZedTimeChanceMult = fmax(ZedTimeChanceMult, 0.0);
        Game.ZedTimeDuration = clamp(ZedTimeDuration, 3, 240);
    }

    Game.StartingCash = 0;  // the game must call CalcStartingCash() instead
    if (StartDoshMax <= 0) {
        StartDoshMax = 1000000;
    }
    else {
        RecommendedStartDosh = StartDoshMax;
    }

    // this makes sure the Wave is never none
    if ( Waves.length == 0 ) {
        warn("ScrnGameLength: NO WAVES DEFINED!");
        Wave = new(none, "Wave1") WaveInfoClass;
        Game.bUseEndGameBoss = false;
    }
    else {
        Wave = CreateWave(Waves[Waves.length-1]);
        Game.bUseEndGameBoss = Wave.EndRule == RULE_KillBoss;
        UsedWaves.Length = 0;

        Wave = CreateWave(Waves[0]);
        if (StartDosh == 0 && StartDoshPerWave == 0) {
            StartDoshPerWave = RecommendedStartDosh / Waves.length / 25 * 25;
            StartDosh = StartDoshPerWave;
            log("Calculated StartDoshPerWave=" $ StartDoshPerWave, class.name);
        }
    }
    Wave.bRespawnDeadPlayers = true;  // always allow player start on wave 1
    NextWave = Wave;  // prevent loading the same object again during LoadWave(0) call
    NextWaveNum = 0;
    Game.FinalWave = Waves.length;
    if ( Game.bUseEndGameBoss ) {
        Game.FinalWave--;  // the boss wave is after the final wave, e.g., wave 11/10
    }

    LoadWeaponLists();
}

function PickRandomZedEvent()
{
    local array<byte> EventNums;
    local int i, j;
    local ScrnZedInfo zi;
    local string s;

    // load all possible events and chose the random one
    for ( i = 0; i < Zeds.length; ++i ) {
        zi = new(none, Zeds[i]) ZedInfoClass;
        if (zi.EventNum == 0)
            continue;

        for (j = 0; j < EventNums.length; ++j) {
            if (zi.EventNum <= EventNums[j]) {
                break;
            }
        }
        if (j == EventNums.length || EventNums[j] != zi.EventNum) {
            EventNums.insert(j, 1);
            EventNums[j] = zi.EventNum;
        }
    }

    if (EventNums.Length == 0) {
        log("No zed events available", class.name);
        Mut.CurrentEventNum = 0;
        return;
    }

    Mut.CurrentEventNum = EventNums[rand(EventNums.Length)];
    s = "";
    for (j = 0; j < EventNums.length; ++j) {
        s @= EventNums[j];
    }
    log("ZED Event " $ Mut.CurrentEventNum $ " is randomly chosen from {" $ s $" }", class.name);
}

function bool ApplyGameDifficulty(byte HardcoreDifficulty)
{
    local int i, ForceHL;

    if ( HardcoreDifficulty < MinDifficulty || HardcoreDifficulty > MaxDifficulty ) {
        log("Game difficulty " $ HardcoreDifficulty $ " is out of founds ["$MinDifficulty$".." $ MaxDifficulty $ "]",
                class.name);
        return false;
    }

    if ( HardcoreLevel.length > 0 ) {
        for ( i = 0; i < HardcoreLevel.length; ++i ) {
            if ( HardcoreDifficulty >= HardcoreLevel[i].Difficulty && ForceHL < HardcoreLevel[i].HL )
                ForceHL = HardcoreLevel[i].HL;
        }
    }

    if ( ForceHL > 0 ) {
        Mut.GameRules.ForceHardcoreLevel(ForceHL);
    }
    else {
        Mut.GameRules.ScaleHardcoreLevel(HLMult);
    }
    return true;
}

function AdjustBonusLevels(out int MinLevel, out int MaxLevel)
{
    if (MinBonusLevel != 255) {
        MinLevel = MinBonusLevel;
    }
    if (MaxBonusLevel != 255) {
        MaxLevel = MaxBonusLevel;
    }
}

function bool VersionCheck()
{
    return GameVersion == Wave.GameVersion || Wave.GameVersion == 0;
}

function AddVoting()
{
    local ScrnVotingHandlerMut VH;
    local ScrnZedVoting VO;

    VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Game);
    if ( VH != none ) {
        Game.AddMutator(string(class'ScrnVotingHandlerMut'), false);
        VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Game);
    }
    if ( VH == none ) {
        log("Unable to spawn voting handler mutator", class.name);
        return;
    }

    VO = ScrnZedVoting(VH.AddVotingOptions(class'ScrnZedVoting'));
    if ( VO != none ) {
        VO.GL = self;
    }
}

function int FindZedCmdCache(String Alias, bool bCreate)
{
    local int i;

    for (i = 0; i < ZedCmdCache.Length; ++i) {
        if (ZedCmdCache[i].Alias == Alias) {
            return i;
        }
    }
    if (bCreate) {
        ZedCmdCache.insert(i, 1);
        ZedCmdCache[i].Alias = Alias;
        ZedCmdCache[i].LastCmdIdx = 1;
        return i;
    }
    return -1;
}

// allows admins to control zed infos via MUTATE ZED <cmd>
function ZedCmd(PlayerController Sender, string cmd)
{
    local array<string> args;
    local int max_args;
    local int search_idx, cur_idx; // starts with 1
    local int BoolValue;
    local int i, j;
    local bool bNeedChanges, bChanged;
    local color c;
    local float Pct;
    local bool bSetPct;
    local byte SpawnCount, Spawned;
    local bool bSummon;
    local string msg;
    local int CacheIdx;

    BoolValue = -1;
    c.B = 1;
    CacheIdx = -1;

    Split(cmd, " ", args);
    if ( args.length == 0 || args[0] == "" ) {
        Sender.ClientMessage("MUTATE ZED LIST|(<alias> [<index>] [ON|OFF] [PCT <val>] [SUMMON|(SPAWN <count>)])");
        return;
    }

    if ( args[0] ~= "LIST" ) {
        PrintAliases(Sender);
        return;
    }

    max_args = args.length;
    if ( args.length > 1 ) {
        for ( i = 1; i < args.length; ++i ) {
            if ( args[i] ~= "PCT" && i < args.length - 1) {
                bSetPct = true;
                bNeedChanges = true;
                Pct = float(args[i+1]);
                args.remove(i,2);
                max_args = i;
            }
            else if ( args[i] ~= "SUMMON" ) {
                bSummon = true;
                SpawnCount = 1;
                args.remove(i,1);
                max_args = i;
            }
            else if ( args[i] ~= "SPAWN" ) {
                if ( i < args.length - 1 ) {
                    SpawnCount = int(args[i+1]);
                    if ( SpawnCount > 0 || args[i+1] == "0" )
                        args.remove(i+1,1);
                }
                if ( SpawnCount == 0 )
                    SpawnCount = 1;
                args.remove(i,1);
                max_args = i;
            }
        }

        if ( max_args > 1 ) {
            search_idx = int(args[1]);
            if ( max_args > 2 ) {
                BoolValue = class'ScrnVotingOptions'.static.TryStrToBoolStatic(args[2]);
                if ( BoolValue != -1 )
                    bNeedChanges = true;
            }
        }
    }

    if ( bNeedChanges && !Mut.CheckAdmin(Sender) )
        return;

    Sender.ClientMessage("INDEX / STATUS / SPAWN CHANCE / ZED CLASS");
    Sender.ClientMessage("=========================================================");
    for ( i = 0; i < ZedInfos.length; ++i ) {
        bChanged = false;

        for ( j = 0; j < ZedInfos[i].Zeds.length; ++j ) {
            if ( ZedInfos[i].Zeds[j].Alias != args[0] )
                continue;

            ++cur_idx;

            if (CacheIdx == -1) {
                CacheIdx = FindZedCmdCache(args[0], true);
            }

            if ( ZedInfos[i].Zeds[j].bDisabled ) {
                c.R = 255;
                c.G = 1;
            }
            else {
                c.R = 1;
                c.G = 255;
            }

            if ( (cur_idx == search_idx) || (search_idx == 0 && cur_idx == ZedCmdCache[CacheIdx].LastCmdIdx) ) {
                if ( BoolValue != -1 ) {
                    ZedInfos[i].Zeds[j].bDisabled = !bool(BoolValue);
                    bChanged = true;
                }
                if ( bSetPct) {
                    ZedInfos[i].Zeds[j].Pct = Pct;
                    bChanged = true;
                }
                if (bSummon) {
                    Spawned = SummonZed(Sender, ZedInfos[i].Zeds[j].Alias, ZedInfos[i].Zeds[j].ZedClass, msg);
                }
                else if ( SpawnCount > 0 ) {
                    Game.TotalMaxMonsters += SpawnCount;
                    Spawned = SpawnZed(ZedInfos[i].Zeds[j].Alias, ZedInfos[i].Zeds[j].ZedClass, SpawnCount, msg);
                    // if not all zeds are spawned, restore the original TotalMaxMonsters
                    Game.TotalMaxMonsters -= (SpawnCount - Spawned);
                }
                c.R = 255;
                c.G = 255;
                ZedCmdCache[CacheIdx].LastCmdIdx = cur_idx;
            }
            Sender.ClientMessage(class'ScrnFunctions'.static.ColorStringC(
                class'ScrnF'.static.LPad(string(cur_idx), 3)
                    @ class'ScrnF'.static.RPad(eval(ZedInfos[i].Zeds[j].bDisabled, "OFF", "ON"), 5)
                    @ class'ScrnF'.static.LPad(eval(ZedInfos[i].Zeds[j].Pct == 0, "AUTO", string(ZedInfos[i].Zeds[j].Pct)), 7)
                    @ ZedInfos[i].Zeds[j].ZedClass
                , c ));
        }
        if ( bChanged )
            ZedInfos[i].SaveConfig();
    }
    if ( cur_idx == 0 ) {
        Sender.ClientMessage("No zeds with alias '"$args[0]$"' found!");
    }
    else if ( bSummon ) {
        if ( Spawned == 0 )
            Sender.ClientMessage("Cannot summon " $ args[0]);
        else
            Sender.ClientMessage("Summoned " $ args[0]);
    }
    else if ( SpawnCount > 0 ) {
        if ( Spawned == 0 )
            Sender.ClientMessage("Cannot spawn " $ args[0]);
        else
            Sender.ClientMessage("Spawned " $ Spawned $ "*" $ args[0]);
    }
    if ( msg != "" ) {
        Sender.ClientMessage(msg);
    }
}

function PrintAliases(PlayerController Sender)
{
    local array<string> aliases;
    local array<int> count;
    local int i, j, k;
    local string msg;

    Sender.ClientMessage("Zed aliases (candidate count):");
    for ( i = 0; i < ZedInfos.length; ++i ) {
        for ( j = 0; j < ZedInfos[i].Zeds.length; ++j ) {
            for ( k = 0; k < aliases.length; ++k ) {
                if ( ZedInfos[i].Zeds[j].Alias == aliases[k] )
                    break;
            }
            if ( k == aliases.length ) {
                aliases[k] = ZedInfos[i].Zeds[j].Alias;
                count[k] = 1;
            }
            else {
                ++count[k];
            }
        }
    }

    for ( k = 0; k < aliases.length; ++k ) {
        msg $= aliases[k] $ " ("$count[k]$") ";
        if ( len(msg) >= 80 ) {
            Sender.ClientMessage(msg);
            msg = "";
        }
    }
    if ( msg != "" ) {
        Sender.ClientMessage(msg);
    }
}

function ZedSpawned(KFMonster M)
{
    if (bLoadedSpecial && Wave.EndRule == RULE_KillSpecial) {
        Game.Bosses[Game.Bosses.Length] = M;
        bBossSpawned = true;
    }
}

protected function bool LoadNextWave()
{
    local int i;
    local SSquad squad;
    local Controller C;
    local KFPlayerController KFPC;
    local int NumPlayers;

    bLoadedSpecial = false;
    bBossSpawned = false;
    PendingSquads.length = 0;
    PendingSpecialSquads.length = 0;
    Squads.length = 0;
    SpecialSquads.length = 0;
    PendingNextSpawnSquad.length = 0;
    NoBountyTime = 0;
    bTimelimit30 = false;
    TimeLimit = Game.Level.TimeSeconds + 99999; // will be set later in RunWave

    NumPlayers = max(Game.NumPlayers + Game.NumBots, Game.ScrnGRI.FakedPlayers);

    if ( bLogStats && Wave != none )
        LogStats();

    if ( NextWave == none ) {
        return false;
    }
    log("Loading wave #"$NextWaveNum @ NextWave.name, class.name);
    Wave = NextWave;
    NextWave = none;

    if (Wave.EndRule == RULE_Dialogue && bSkipDialogue) {
        log("Skip dialogue wave", class.name);
        return false;
    }

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        ActiveZeds[i].WaveSpawns = 0;
    }

    for ( i = 0; i < Wave.Squads.length; ++i ) {
        if ( ParseSquad(Wave.Squads[i], squad) ) {
            Squads[Squads.length] = squad;
        }
    }
    if ( Squads.length == 0 ) {
        log("No squads in wave", class.name);
        return false;
    }

    for ( i = 0; i < Wave.SpecialSquads.length; ++i ) {
        if ( ParseSquad(Wave.SpecialSquads[i], squad) ) {
            SpecialSquads[SpecialSquads.length] = squad;
        }
    }

    if (Wave.EndRule == RULE_KillBoss && !(NextWaveNum == Game.FinalWave && Game.bUseEndGameBoss)) {
        // RULE_KillBoss can use used only for end-game boss.
        // Use RULE_KillSpecial for mid-wave bosses.
        Wave.EndRule = RULE_KillSpecial;
    }
    if (Wave.EndRule == RULE_KillSpecial &&  SpecialSquads.length == 0) {
        log("No special squads in wave", class.name);
        return false;
    }

    if ( Wave.MaxZombiesOnce > 0 )
        Game.MaxZombiesOnce = Wave.MaxZombiesOnce;
    else if ( Wave.EndRule == RULE_KillBoss )
        Game.MaxZombiesOnce = 16;
    else
        Game.MaxZombiesOnce = Game.StandardMaxZombiesOnce;

    if ( NextWaveNum == 0 ) {
        Game.AddSuicideTime(SuicideTime * (1.0 + SuicideTimePerPlayerMult * (NumPlayers - 1)), true);
    }
    else if ( Wave.SuicideTime != 0 || Wave.bSuicideTimeReset ) {
        Game.AddSuicideTime(Wave.SuicideTime * (1.0 + Wave.SuicideTimePerPlayerMult * (NumPlayers - 1)),
                Wave.bSuicideTimeReset);
    }
    else if ( SuicideTimePerWave != 0 && NextWaveNum != 0 ) {
        Game.AddSuicideTime(SuicideTimePerWave * (1.0 + SuicideTimePerPlayerMult * (NumPlayers - 1)), false);
    }

    Game.WaveCountDown = Wave.TraderTime;
    Game.ScrnGRI.bTraderArrow = Wave.bTraderArrow || Wave.bOpenTrader;
    Game.ScrnGRI.WaveEndRule = Wave.EndRule;
    Game.bZedPickupDosh = Wave.EndRule == RULE_GrabDoshZed;
    Game.bZedDropDosh = Wave.EndRule == RULE_GrabDoshZed || Wave.EndRule == RULE_GrabDosh;
    if (Game.bZedDropDosh) {
        Game.bZedGiveBounty = false;
    }
    else if (Wave.EndRule == RULE_EarnDosh) {
        Game.bZedGiveBounty = true;
    }
    else if (Wave.NoBountyTimeout > 0) {
        Game.bZedGiveBounty = true;
        NoBountyTime = Game.Level.TimeSeconds + Wave.NoBountyTimeout + Wave.TraderTime;
    }
    else {
        Game.bZedGiveBounty = !Wave.bNoBounty;
    }

    SetWaveInfo();

    if (FTG != none) {
        LoadFtgWave();
    }

    if ( Wave.TraderMessage != "" ) {
        for ( C = Game.Level.ControllerList; C != none; C = C.NextController ) {
            KFPC = KFPlayerController(C);
            if ( C.PlayerReplicationInfo != none && KFPC != none ) {
                // this is needed to show a trader portrait
                KFPC.ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 0);
                KFPC.TeamMessage(C.PlayerReplicationInfo, Wave.TraderMessage, 'TRADER');
            }
        }
    }
    LoadDialogues(Wave.TraderDialogues);
    bSkipDialogue = false;

    DoorControl(Wave.DoorControl, Mut.bRespawnDoors || Mut.bTSCGame);

    switch (Wave.EndRule) {
        case RULE_ReachTrader:
            Rule = new class'ScrnWaveRule_ReachTrader';
            break;
        default:
            Rule = none;
    }

    if (Rule != none) {
        Rule.GL = self;
        Rule.Load();
    }

    return true;
}

protected function LoadFtgWave()
{
    local class<DamageType> WipeOnBaseLost;

    FTG.bNoBases = Wave.FtgRule == FTG_NoBase;
    if (Wave.FtgRule != FTG_TSCBase) {
        WipeOnBaseLost = class'FtgBaseGuardian'.default.WipeOnBaseLost;
    }

    if (FTG.TeamBases[0] != none) {
        FTG.TeamBases[0].WipeOnBaseLost = WipeOnBaseLost;
    }
    if (FTG.TeamBases[1] != none) {
        FTG.TeamBases[1].WipeOnBaseLost = WipeOnBaseLost;
    }
}

function bool LoadWave(int WaveNum)
{
    if ( NextWave == none || WaveNum != NextWaveNum ) {
        NextWaveNum = WaveNum;
        if ( NextWaveNum < Waves.length ) {
            NextWave = CreateWave(Waves[NextWaveNum]);
        }
        else {
            warn("ScrnGameLength: Illegal wave number: " $ WaveNum);
            if ( Wave == none )
                NextWave = CreateWave("Wave1");  // fallback wave
            else
                NextWave = Wave;  // use the previous wave
        }
    }

    if ( !LoadNextWave() ) {
        log("Failed to load wave " $ WaveNum, class.name);
        return false;
    }

    NextWaveNum = WaveNum + 1;
    if ( NextWaveNum < Waves.length ) {
        NextWave = CreateWave(Waves[NextWaveNum]);
    }
    return true;
}

function string PickWaveName(array<string> Candidates) {
    local int i;
    local string ReqWave, NewWave;
    local bool bOK;

    while (Candidates.Length > 0) {
        i = rand(Candidates.Length);
        if (Divide(Candidates[i], "=>", ReqWave, NewWave)) {
            bOk = ReqWave == UsedWaves[UsedWaves.Length-1];
        }
        else if (Divide(Candidates[i], ">>", ReqWave, NewWave)) {
            bOk = class'ScrnF'.static.SearchStr(UsedWaves, ReqWave) != -1;
        }
        else {
            NewWave = Candidates[i];
            bOk = true;
        }

        if (bOk && bUniqueWaves && Candidates.Length > 1 && class'ScrnF'.static.SearchStr(UsedWaves, NewWave) != -1) {
            // not unique
            bOk = false;
        }

        if (bOK) {
            return NewWave;
        }
        Candidates.remove(i, 1);
    }
    return "";
}

function ScrnWaveInfo CreateWave(string WaveDefinition)
{
    local ScrnWaveInfo NewWave;
    local array<string> Parts;
    local string WaveName;
    local bool bRandomlyPicked;

    // get rid of spaces
    WaveName = Repl(WaveDefinition, " ", "", true);
    if (InStr(WaveName, "|") != -1) {
        Split(WaveName, "|", Parts);
        WaveName = PickWaveName(Parts);
        bRandomlyPicked = true;
    }
    else {
        Parts[0] = WaveName;
        WaveName = PickWaveName(Parts);
    }

    if (WaveName == "") {
        log("Failed to create wave " $ WaveName $ ": '"$WaveDefinition$"'", class.name);
        return none;
    }

    log("Creating wave " $ WaveName, class.name);
    UsedWaves[UsedWaves.Length] = WaveName;
    NewWave = new(none, WaveName) WaveInfoClass;
    NewWave.bRandomlyPicked = bRandomlyPicked;
    return NewWave;
}

// Called by Game.SetupWave() when Battle Time starts (Trader/Cooldown Time ends)
function RunWave()
{
    local string s;
    local bool bHasTitle, bHasMsg;

    SetWaveInfo();
    DoorControl(Wave.DoorControl2, false);
    Game.ScrnGRI.bTraderArrow = Wave.bTraderArrow;
    if (Wave.TimeLimit > 0 && Wave.EndRule != RULE_Timeout) {
        TimeLimit = Game.Level.TimeSeconds + Wave.TimeLimit - class'TSCGame'.default.WaveEndingCountDown;
    }

    if ( Wave.bRandomSpawnLoc ) {
        Game.ZedSpawnLoc = ZSLOC_RANDOM;
    }

    bHasTitle = Game.ScrnGRI.WaveTitle != "" && Game.ScrnGRI.WaveTitle != " ";
    bHasMsg = Game.ScrnGRI.WaveMessage != "" && Game.ScrnGRI.WaveMessage != " ";

    if (bHasTitle || bHasMsg) {
        if (bHasTitle) {
            s = class'ScrnFunctions'.static.ColorString(Game.ScrnGRI.WaveTitle, 255, 204, 1);
        }
        if (bHasMsg) {
            if ( s != "" )
                s $= ": ";
            s $= Game.ScrnGRI.WaveMessage;
        }
        Game.Broadcast(Game, s);
    }
    LoadDialogues(Wave.CombatDialogues);

    if ( Doom3DisableSuperMonstersFromWave > 1 && Game.WaveNum + 1 == Doom3DisableSuperMonstersFromWave ) {
        Mut.DisableDoom3Monsters();
    }

    switch (Wave.EndRule) {
        case RULE_EarnDosh:
        case RULE_GrabDosh:
        case RULE_GrabDoshZed:
            // Make sure the Team Wallet is empty when the goal is dosh earning
            Game.RewardAlivePlayers();
            break;

        case RULE_GrabAmmo:
            Mut.GameRules.WaveAmmoPickups = 0;
            break;
    }

    if (Rule != none) {
        Rule.Run();
    }
}

function SetWaveInfo()
{
    local int ExtraPlayers;

    WaveCounter = Wave.Counter;
    ZedsBeforeSpecial = Wave.ZedsBeforeSpecialSquad;
    if ( ZedsBeforeSpecial > 0 && Wave.bRandomSquads ) {
        ZedsBeforeSpecial *= 0.85 + 0.3*frand();
    }

    if (Wave.PerPlayerMult == 0) {
        switch ( Wave.EndRule ) {
            case RULE_KillEmAll:
            case RULE_SpawnEmAll:
                WaveCounter = Game.ScaleMonsterCount(WaveCounter, Wave.MaxCounter); // apply default scaling
        }
    }
    else {
        ExtraPlayers = max(Game.AlivePlayerCount, Game.ScrnGRI.FakedPlayers) - Wave.PerPlayerExclude;
        if (ExtraPlayers > 0) {
            WaveCounter *= 1.0 + Wave.PerPlayerMult * ExtraPlayers;
            ZedsBeforeSpecial *= 1.0 + Wave.PerPlayerMult * ExtraPlayers;
        }
    }

    if (Wave.MaxCounter > 0) {
        WaveCounter = min(WaveCounter, Wave.MaxCounter);
        ZedsBeforeSpecial = min(ZedsBeforeSpecial, Wave.MaxCounter);
    }
    WaveEndTime = Game.Level.TimeSeconds + WaveCounter + 0.1;

    switch (Wave.EndRule) {
        case RULE_GrabAmmo:
            if ( Game.DesiredAmmoBoxCount < WaveCounter ) {
                Mut.AdjustAmmoBoxCount(clamp(WaveCounter, Game.AmmoPickups.length * 0.7, Game.AmmoPickups.length * 0.9));
                Game.DesiredAmmoBoxCount = max(6, ceil(Game.AmmoPickups.length * 0.7));
            }
            break;
    }

    if (Wave.bRandomlyPicked && Game.WaveCountDown > 10) {
        // hide wave info during trader time to prevent premature reveal of a random wave
        Game.ScrnGRI.WaveHeader = "";
        Game.ScrnGRI.WaveTitle = "";
        Game.ScrnGRI.WaveMessage = "";
    }
    else {
        Game.ScrnGRI.WaveHeader = class'ScrnFunctions'.static.ParseColorTags(Wave.Header);
        Game.ScrnGRI.WaveTitle = class'ScrnFunctions'.static.ParseColorTags(Wave.Title);
        Game.ScrnGRI.WaveMessage = class'ScrnFunctions'.static.ParseColorTags(
                Repl(Wave.Message, "%c", string(WaveCounter), true));
        if (Game.ScrnGRI.WaveHeader == "-") {
            Game.ScrnGRI.WaveHeader = " ";
        }
        if (Game.ScrnGRI.WaveTitle == "-") {
            Game.ScrnGRI.WaveTitle = " ";
        }
        if (Game.ScrnGRI.WaveMessage == "-") {
            Game.ScrnGRI.WaveMessage = " ";
        }
    }
    Game.ScrnGRI.WaveCounter = 0;
    Game.ScrnGRI.WaveCounterMax = 0;
    WaveTimer();
}

function WaveTimer()
{
    if (Game.bZedGiveBounty && NoBountyTime > 0 && Game.Level.TimeSeconds > NoBountyTime) {
        Game.bZedGiveBounty = false;
        NoBountyTime = 0;
        Game.BroadcastLocalizedMessage(class'ScrnGameMessages', 301);
    }

    if (Rule != none) {
        Rule.WaveTimer();
        return;
    }

    switch (Wave.EndRule) {
        case RULE_Timeout:
            Game.WaveEndTime = WaveEndTime;
            if ( Game.bWaveBossInProgress || Game.bWaveInProgress) {
                Game.ScrnGRI.TimeToNextWave = WaveEndTime - Game.Level.TimeSeconds;
            }
            break;

        case RULE_EarnDosh:
        case RULE_GrabDosh:
        case RULE_GrabDoshZed:
            Game.ScrnGRI.WaveCounter = max(0, WaveCounter - max(Game.Teams[0].Score, Game.Teams[1].Score));
            break;

        case RULE_GrabAmmo:
            Game.ScrnGRI.WaveCounter = max(0, WaveCounter - Mut.GameRules.WaveAmmoPickups);
            break;

        case RULE_KillSpecial:
            if (bBossSpawned) {
                Game.ScrnGRI.WaveCounter = AliveZedCount(Game.Bosses);
            }
            else {
                Game.ScrnGRI.WaveCounter = -1;  // Show "?" on HUD
                Game.ScrnGRI.WaveCounterMax = -1;  // Show "?" on HUD
            }
            break;

        case RULE_Dialogue:
            Game.ScrnGRI.WaveCounter = -1;  // Show "?" on HUD
            Game.ScrnGRI.WaveCounterMax = -1;  // Show "?" on HUD
            break;
    }

    if (Game.ScrnGRI.WaveCounterMax < Game.ScrnGRI.WaveCounter) {
        Game.ScrnGRI.WaveCounterMax = Game.ScrnGRI.WaveCounter;
    }
}

function bool CanKillRemainingZeds() {
    return Wave.EndRule == RULE_KillEmAll && Game.TotalMaxMonsters <= 0 && Game.NumMonsters < 10;
}

// Called by ScrnGameType at the end of the wave - just before loading the next wave
function WaveEnded()
{
    local ScrnPlayerInfo SPI;
    local bool bXP;

    bXP = !(Wave.XP_Bonus ~= 0 && Wave.XP_BonusAlive ~= 0);
    if (!bXP && Wave.CashBonus == 0)
        return;

    for (SPI=Mut.GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo) {
        if (SPI.PlayerOwner == none || SPI.PlayerOwner.PlayerReplicationInfo == none)
            continue;

        SPI.PlayerOwner.PlayerReplicationInfo.Score += Wave.CashBonus;
        if (SPI.PlayerOwner.PlayerReplicationInfo.Score < 0) {
            SPI.PlayerOwner.PlayerReplicationInfo.Score = 0;
        }

        if (bXP) {
            if (SPI.bDied || Wave.XP_BonusAlive ~= 0) {
                SPI.BonusStats(SPI.GameStartStats, Wave.XP_Bonus);
            }
            else {
                SPI.BonusStats(SPI.GameStartStats, Wave.XP_BonusAlive);
            }
        }
    }

    if (DialogueHandler != none && DialogueHandler.IsRunning()) {
        DialogueHandler.EndDialogue();
    }
}

function DoorControl(ScrnWaveInfo.EDoorControl dc, bool bRespawnDefault)
{
    switch (dc) {
        case DOOR_Default:
            if (bRespawnDefault) {
                Mut.RespawnDoors();
            }
            break;
        case DOOR_Respawn:
            Mut.RespawnDoors();
            break;
        case DOOR_Blow:
            Mut.BlowDoors();
            break;
        case DOOR_Unweld:
            Mut.UnweldDoors();
            break;
        case DOOR_UnweldRespawn:
            Mut.WeldDoors(0);
            break;
        case DOOR_Weld1p:
            Mut.WeldDoors(0.01);
            break;
        case DOOR_WeldHalf:
            Mut.WeldDoors(0.5);
            break;
        case DOOR_WeldFull:
            Mut.WeldDoors(1.0);
            break;
        case DOOR_WeldRandom:
            Mut.WeldDoors(-1.0);
            break;
        case DOOR_Randomize:
            Mut.RandomizeDoors();
            break;
    }
}

function LogStats()
{
    local int i, total;

    for ( i = 0; i < ActiveZeds.length; ++i )
        total += ActiveZeds[i].WaveSpawns;
    if ( total == 0 )
        return;

    log("Spawn Stats for " $ string(Wave.name) $ ":", class.name);
    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].WaveSpawns > 0 )
            log(ActiveZeds[i].Alias $ ": " $ ActiveZeds[i].WaveSpawns $ " / "
                    $ string(ActiveZeds[i].WaveSpawns * 100.0 / total) $ "%");
    }
}

function int AliveZedCount(out array<KFMonster> ZedList)
{
    local int i, c;
    local KFMonster M;

    for (i = ZedList.length - 1; i >= 0; --i) {
        M = ZedList[i];
        if (M != none && !M.bDeleteMe && M.Health > 0) {
            ++c;
        }
        else {
            ZedList.remove(i, 1);
        }
    }
    return c;
}

function bool CheckWaveEnd()
{
    if (Game.Level.TimeSeconds > TimeLimit) {
        if (bTimelimit30) {
            TimeLimit = Game.Level.TimeSeconds + 99999;
            return true;
        }

        TimeLimit = Game.Level.TimeSeconds + class'TSCGame'.default.WaveEndingCountDown;
        bTimelimit30 = true;
        Game.BroadcastLocalizedMessage(class'ScrnGameMessages', 200);
    }

    if (Rule != none) {
        return Rule.CheckWaveEnd();
    }

    switch ( Wave.EndRule ) {
        case RULE_KillEmAll:
            return Game.TotalMaxMonsters <= 0 && Game.NumMonsters <= 0;
        case RULE_SpawnEmAll:
            return Game.TotalMaxMonsters <= 0;

        case RULE_KillBoss:
            return Game.bBossSpawned && Game.bHasSetViewYet && AliveZedCount(Game.Bosses) == 0;
        case RULE_KillSpecial:
            return bBossSpawned && AliveZedCount(Game.Bosses) == 0;

        case RULE_Timeout:
            return Game.Level.TimeSeconds >= WaveEndTime;

        case RULE_EarnDosh:
        case RULE_GrabDosh:
        case RULE_GrabDoshZed:
            return max(Game.Teams[0].Score, Game.Teams[1].Score) >= WaveCounter;

        case RULE_GrabAmmo:
            return Mut.GameRules.WaveAmmoPickups >= WaveCounter;

        case RULE_Dialogue:
            return DialogueHandler == none || !DialogueHandler.IsRunning();
    }

    // fallback scenario
    return Game.Level.TimeSeconds >= Game.WaveEndTime
            || (Game.TotalMaxMonsters <= 0 && Game.NumMonsters <= 0);
}

function int GetWaveZedCount()
{
    switch ( Wave.EndRule ) {
        case RULE_KillBoss:
            return 1;
        case RULE_KillSpecial:
        case RULE_Timeout:
        case RULE_EarnDosh:
        case RULE_GrabDosh:
        case RULE_GrabDoshZed:
        case RULE_GrabAmmo:
        case RULE_ReachTrader:
        case RULE_Dialogue:
            return 999;
    }
    return WaveCounter;
}

function float GetWaveEndTime()
{
    switch ( Wave.EndRule ) {
        case RULE_Timeout:
            return WaveEndTime;
    }
    return Game.Level.TimeSeconds + 60;
}

function AdjustNextSpawnTime(out float NextSpawnTime, float MinSpawnTime)
{
    local float SpawnRateMod;

    if (PendingNextSpawnSquad.length > 0) {
        NextSpawnTime = 0.25;
        return;
    }

    SpawnRateMod = fclamp(Wave.SpawnRateMod, 0.1, 10.0);
    if (bLoadedSpecial) {
        NextSpawnTime += Wave.SpecialSquadCooldown;
    }

    if (Game.HasEnoughZeds()) {
           // for maps with MaxZombiesOnce > 32: slower spawns if there are already 32+ zeds spawned
        if (Game.NumMonsters >= 32) {
            NextSpawnTime *= 1.5;
        }
        // slower spawns on Normal difficulty
        if (Game.BaseDifficulty < Game.DIFF_HARD) {
            NextSpawnTime *= 2.0;
            MinSpawnTime *= 1.5;
        }
        // Slower spawns in FTG while the Guardian is being carried
        if (FTG != none && (FTG.TeamBases[0].bHeld || FTG.TeamBases[1].bHeld)) {
            SpawnRateMod *= FtgSpawnRateMod;
        }

        if (Wave.bRandomSquads && !bLoadedSpecial) {
            // 1.0 .. 3.0
            NextSpawnTime *= 1.0 + Game.WaveSinMod();
        }
        else {
            // average between 1.0 and 3.0
            NextSpawnTime *= 2.0;
        }
    }

    NextSpawnTime /= SpawnRateMod;
    MinSpawnTime /= SpawnRateMod;
    NextSpawnTime = fmax(NextSpawnTime, MinSpawnTime);
}

function bool HasPendingSquad()
{
    return PendingNextSpawnSquad.length > 0;
}

function LoadNextSpawnSquad(out array < class<KFMonster> > NextSpawnSquad)
{
    local int i;

    if ( PendingNextSpawnSquad.length == 0 ) {
        LoadedCount = 0;
        if (ZedsBeforeSpecial <= 0 && SpecialSquads.length > 0 && !bBossSpawned) {
            LoadNextSpawnSquadInternal(PendingNextSpawnSquad, SpecialSquads, PendingSpecialSquads, Wave.bRandomSpecialSquads);
            ZedsBeforeSpecial = Wave.ZedsPerSpecialSquad;
            if ( Wave.bRandomSquads ) {
                ZedsBeforeSpecial *= 0.85 + 0.3*frand();
            }
            bLoadedSpecial = true;
        }
        else if (bLoadedSpecial && Wave.EndRule == RULE_KillSpecial && !bBossSpawned) {
            log("Boss failed to spawn", class.name);
            bBossSpawned = true;
        }
        else {
            LoadNextSpawnSquadInternal(PendingNextSpawnSquad, Squads, PendingSquads, Wave.bRandomSquads);
            ZedsBeforeSpecial -= PendingNextSpawnSquad.length;
            bLoadedSpecial = false;
        }
    }

    for (i = 0; i < PendingNextSpawnSquad.Length; ++i) {
        if ( PendingNextSpawnSquad[i] == class'KFMonster' ) {
            // squad break
            NextSpawnSquad.length = i;
            PendingNextSpawnSquad.remove(0, i + 1);  // remove including KFMonster
            return;
        }
        NextSpawnSquad[i] = PendingNextSpawnSquad[i];
    }
    // if reached here, PendingNextSpawnSquad is fully copied into NextSpawnSquad
    NextSpawnSquad.length = i;
    PendingNextSpawnSquad.length = 0;
}

protected function LoadNextSpawnSquadInternal(out array < class<KFMonster> > NextSpawnSquad,
        out array<SSquad> AllSquads, out array<int> Pending, bool bRandom, optional int Recursions)
{
    local int i, j, c, r;
    local int PlayerCount;

    PlayerCountOverrideForHealth = 0;
    PlayerCount = Game.GetPlayerCountForMonsterHealth();

    if ( AllSquads.length == 0 ) {
        NextSpawnSquad.length = 1;
        NextSpawnSquad[0] = FallbackZed;
        LoadedCount++;
        return;
    }

    NextSpawnSquad.length = 0;
    if ( Pending.length == 0 ) {
        Pending.length = AllSquads.length;
        for ( i = 0; i < Pending.length; ++i ) {
            Pending[i] = i;
        }
    }
    if (bRandom && !AllSquads[Pending[0]].bKeepWithPrev) {
        i = rand(Pending.length);
        while (i > 0 && AllSquads[Pending[i]].bKeepWithPrev) {
            --i;
        }
    }
    else {
        i = 0;
    }
    r = Pending[i];
    Pending.remove(i, 1);

    if ( PlayerCount >= AllSquads[r].MinPlayers
            && (PlayerCount <= AllSquads[r].MaxPlayers || AllSquads[r].MaxPlayers == 0) )
    {
        for ( i = 0; i < AllSquads[r].Members.length; ++i ) {
            for ( j = 0; j < AllSquads[r].Members[i].Count; ++j ) {
                if (AllSquads[r].ScaleByPlayers == 0) {
                    c = 1;
                }
                else {
                    c = 1 + int( (PlayerCount - 0.5) / AllSquads[r].ScaleByPlayers );
                    PlayerCountOverrideForHealth = float(PlayerCount) / c;
                }

                while (c-- > 0) {
                    NextSpawnSquad[NextSpawnSquad.length] = ActivateZed(AllSquads[r].Members[i].ActiveZedIndex);
                }
            }
        }
    }
    else if ( Recursions < 10 ){
        // squad didn't passed player count restriction - pick another squad
        LoadNextSpawnSquadInternal(NextSpawnSquad, AllSquads, Pending, bRandom, Recursions + 1);
    }
}

function class<KFMonster> ActivateZed(int idx)
{
    local float r;
    local int i;

    if ( idx == SQUAD_BREAK ) {
        return class'KFMonster';
    }

    ActiveZeds[idx].WaveSpawns++;
    ActiveZeds[idx].TotalSpawns++;
    LoadedCount++;

    if ( ActiveZeds[idx].Candidates.length == 1 )
        return ActiveZeds[idx].Candidates[0].ZedClass;

    r = frand();
    for ( i = 0; r > ActiveZeds[idx].Candidates[i].Chance && i < ActiveZeds[idx].Candidates.length - 1; ++i ) {
        r -= ActiveZeds[idx].Candidates[i].Chance;
    }
    return ActiveZeds[idx].Candidates[i].ZedClass;
}

function bool ParseSquad(string SquadDef, out SSquad Squad)
{
    local int i, j, k, idx, count;
    local array<string> blocks;
    local array<string> parts;
    local string s, count_str, alias, fallback;

    Squad.Members.length = 0;
    Squad.bKeepWithPrev = false;
    Squad.MinPlayers = 0;
    Squad.MaxPlayers = 0;
    Squad.ScaleByPlayers = 0;

    // format example: 0-6: 2*CL/GF + BR/TH/HU + BL
    // another example: ~6: BOSS

    // get rid of spaces
    s = Repl(SquadDef, " ", "", true);

    if ( Left(s, 1) == "^" ) {
        Squad.bKeepWithPrev = true;
        s = Right(s, Len(s) - 1);
    }

    Divide(s, ":", count_str, s);
    if ( count_str != "" ) {
        if ( Left(count_str, 1) == "~" ) {
            Squad.ScaleByPlayers = int(Mid(count_str, 1));
        }
        else {
            Divide(count_str, "-", count_str, fallback);
            Squad.MinPlayers = int(count_str);
            Squad.MaxPlayers = int(fallback);
        }
    }

    Split(s, "|", blocks);
    for ( k = 0; k < blocks.length; ++k ) {
        if ( blocks[k] == "" || Squad.Members.length > 0 ) {
            j = Squad.Members.length;
            Squad.Members.insert(j, 1);
            Squad.Members[j].ActiveZedIndex = SQUAD_BREAK;
            Squad.Members[j].Count = 1;
            if ( blocks[k] == "" )
                continue;
        }

        Split(blocks[k], "+", parts);
        for ( i = 0; i < parts.length; ++i ) {
            s = parts[i];
            do {
                if ( !Divide(s, "/", alias, fallback) ) {
                    alias = s;
                    fallback = "";
                }
                s = alias;
                if ( !Divide(s, "*", count_str, alias) ) {
                    count = 1;
                    alias = s;
                }
                else {
                    count = int(count_str);
                }
                idx = FindActiveZed(alias);
                s = fallback;
            } until ( idx != -1 || fallback == "" );

            if ( idx == -1 ) {
                Game.LogZedSpawn(Game.LOG_DETAIL, "No zeds available to fit " $ parts[i] $ " in " $ SquadDef);
                Squad.Members.length = 0;
                return false;
            }
            else {
                j = Squad.Members.length;
                Squad.Members.insert(j, 1);
                Squad.Members[j].ActiveZedIndex = idx;
                Squad.Members[j].Count = count;
            }
        }
    }
    return true;
}

function int FindActiveZed(string alias)
{
    local int i;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Alias == alias )
            return i;
    }
    Game.LogZedSpawn(Game.LOG_DEBUG, "Zed with alias '"$alias$"' not found");
    return -1;
}

function AddZedVote(string VoteString)
{
    local int i;

    for ( i = 0; i < ZedVotes.length; ++i ) {
        if ( VoteString == ZedVotes[i] )
            return; // already added
        else if ( VoteString < ZedVotes[i])
            break; // sort alphabetically
    }
    ZedVotes.insert(i, 1);
    ZedVotes[i] = VoteString;
}

function AddActiveZed(string Alias, class<KFMonster> ZedClass, optional float Chance)
{
    local int i, j;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Alias == Alias )
            break;
    }
    if ( i == ActiveZeds.length ) {
        ActiveZeds.insert(i, 1);
        ActiveZeds[i].Alias = Alias;
    }

    j = ActiveZeds[i].Candidates.length;
    ActiveZeds[i].Candidates.insert(j, 1);
    ActiveZeds[i].Candidates[j].ZedClass = ZedClass;
    ActiveZeds[i].Candidates[j].Chance = Chance;

    for ( i = 0; i < AllZeds.length; ++i ) {
        if ( AllZeds[i] == ZedClass )
            break;
    }
    if ( i == AllZeds.length ) {
        AllZeds[i] = ZedClass;
    }
}

// Recalculate spawn chances, removes records that have zero chance to spawn.
function RecalculateSpawnChances()
{
    local int i, j;
    local float chance;
    local int AutoChanceCount;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Candidates.length == 0 ) {
            Game.LogZedSpawn(Game.LOG_DEBUG, "Alias " $ ActiveZeds[i].Alias $ " has no zeds");
            ActiveZeds[i].Candidates.remove(i--, 1);
            continue;
        }

        chance = 0;
        AutoChanceCount = 0;
        for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
            if ( ActiveZeds[i].Candidates[j].Chance == 0.0 )
                ++AutoChanceCount;
            else
                chance += ActiveZeds[i].Candidates[j].Chance;
        }

        if ( AutoChanceCount > 0 ) {
            // split remaining change equally on remaining records
            chance = (1.0 - chance) / AutoChanceCount;
            for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
                if ( ActiveZeds[i].Candidates[j].Chance == 0.0 ) {
                    if ( chance > 0.0 )
                        ActiveZeds[i].Candidates[j].Chance = chance;
                    else
                        ActiveZeds[i].Candidates.remove(j--, 1);
                }
            }
        }
        else if ( abs(chance) - 1.0 > 0.01 ) {
            // modify all records to have total chance = 1.0
            chance = 1.0 / chance;
            for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
                ActiveZeds[i].Candidates[j].Chance *= chance;
            }
        }
    }
}

function bool ShouldBoostAmmo()
{
    return Wave != none && (Wave.EndRule == RULE_GrabAmmo || Wave.bMoreAmmoBoxes);
}

function float GetBountyScale()
{
    if (Wave.BountyScale > 0)
        return Wave.BountyScale;
    return BountyScale;
}

function class<KFMonster> FindActiveZedByAlias(string Alias, optional string ZedClassStr) {
    local int i, j;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if (ActiveZeds[i].Alias == Alias) {
            for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
                if ( ZedClassStr == "" || ZedClassStr ~= string(ActiveZeds[i].Candidates[j].ZedClass) ) {
                    return ActiveZeds[i].Candidates[j].ZedClass;
                }
            }
        }
    }
    return none;
}

function byte SummonZed(PlayerController Sender, string Alias, string ZedClassStr, out string msg)
{
     local class<KFMonster> zedc;
     local Vector HitLoc, HitNormal;
     local Vector SenderLoc, EndLoc;
     local Vector x,y,z;
     local Actor target;
     local Vector SpawnLoc;
     local KFMonster M;

     zedc = FindActiveZedByAlias(Alias, ZedClassStr);
     if ( zedc == none ) {
         msg = "Zed " $ Alias @ ZedClassStr $ " is not loaded";
         return 0;
     }

     GetAxes( Sender.Rotation, x, y, z);
     EndLoc = SenderLoc + X*10000;
     if ( Sender.Pawn != none ) {
         SenderLoc = Sender.Pawn.Location;
         target = Sender.Pawn.Trace(HitLoc, HitNormal, EndLoc);
     }
     else {
         SenderLoc = Sender.Location;
         target = Sender.Trace(HitLoc, HitNormal, EndLoc);
     }

     if ( target == none || !target.bWorldGeometry ) {
         msg = "Look to the ground where to summon a zed";
         return 0;
     }

     SpawnLoc = HitLoc;
     SpawnLoc.Z += zedc.default.CollisionHeight + 25;
     M = Game.Spawn(zedc,,,SpawnLoc);
     if ( M == none ) {
         msg = "Spawn failed";
         return 0;
     }

     Game.OverrideMonsterHealth(M);
     Mut.GameRules.ReinitMonster(M);
     return 1;
}

function byte SpawnZed(string Alias, string ZedClassStr, byte count, out string msg)
{
    local int i;
    local array< class<KFMonster> > Squad;

    if ( count == 0 )
        count = 1;
    Squad.length = count;
    Squad[0] = FindActiveZedByAlias(Alias, ZedClassStr);
    if ( Squad[0] == none ) {
        msg = "Zed " $ Alias @ ZedClassStr $ " is not loaded";
        return 0;
    }

    for ( i = 1; i < count; ++i ) {
        Squad[i] = Squad[0];
    }

    return Game.SpawnSquadLog(Game.FindSpawningVolumeForSquad(Squad, ZSLOC_NONE, true), Squad);
}

function int CalcStartingCash(PlayerController PC)
{
    return clamp(StartDosh + Game.WaveNum * StartDoshPerWave, StartDoshMin, StartDoshMax);
}

function LoadWeaponList(string WLName, out array<string> LoadedLists, out array<name> LoadedWeapons)
{
    local ScrnWeaponList wl;
    local int i, j;

    if (class'ScrnFunctions'.static.SearchStrIgnoreCase(LoadedLists, WLName) != -1)
        return;  // already loaded

    LoadedLists[LoadedLists.length] = WLName;

    wl = new(none, WLName) class'ScrnWeaponList';
    if (wl.WeaponLists.Length > 0) {
        for (i = 0; i < wl.WeaponLists.Length; ++i) {
            LoadWeaponList(wl.WeaponLists[i], LoadedLists, LoadedWeapons);
        }
    }
    else if (wl.Weapons.Length == 0) {
        return;
    }

    j = LoadedWeapons.Length;
    LoadedWeapons.Length = j + wl.Weapons.Length;
    for (i = 0; i < wl.Weapons.Length; ++i) {
        LoadedWeapons[j++] = wl.Weapons[i];
    }
    Log("Weapon list '" $ WLName $ "' loaded ("$wl.Weapons.Length$" weapons)", class.name);
}


function LoadWeaponLists()
{
    local int i, j;
    local array<string> LoadedAllowedLists, LoadedBlockedLists;

    AllowWeapons.length = 0;
    BlockWeapons.length = 0;

    for (i = 0; i < AllowWeaponLists.Length; ++i) {
        LoadWeaponList(AllowWeaponLists[i], LoadedAllowedLists, AllowWeapons);
    }
    for (i = 0; i < BlockWeaponLists.Length; ++i) {
        LoadWeaponList(BlockWeaponLists[i], LoadedBlockedLists, BlockWeapons);
    }

    if (AllowWeapons.Length > 0 && BlockWeapons.Length > 0) {
        // if AllowWeapons specified, only those can appear in the game.
        // So we simply remove blocked weapons from the allowed list.
        // If a blocked weapon is not in the allowed list, it is not allowed anyway.
        for (i = 0; i < BlockWeapons.Length; ++i) {
            for (j = AllowWeapons.Length - 1; j >= 0; --j) {
                if (BlockWeapons[i] == AllowWeapons[j]) {
                    AllowWeapons.remove(j, 1);
                    // keep searching, as there may be duplicates
                }
            }
        }
        BlockWeapons.Length = 0;
    }
}

function bool IsItemAllowed(class<Pickup> PC)
{
    local class<ScrnFunctions> f;

    f = class'ScrnFunctions';
    return PC != none
            && (AllowWeaponPackages.Length == 0 || f.static.SearchName(AllowWeaponPackages, PC.outer.name) != -1)
            && (BlockWeaponPackages.Length == 0 || f.static.SearchName(BlockWeaponPackages, PC.outer.name) == -1)
            && (AllowWeapons.Length == 0 || f.static.SearchName(AllowWeapons, PC.name) != -1)
            && (BlockWeapons.Length == 0 || f.static.SearchName(BlockWeapons, PC.name) == -1);
}

function bool IsPerkAllowed(class<ScrnVeterancyTypes> Perk)
{
    local class<ScrnFunctions> f;

    f = class'ScrnFunctions';
    return Perk != none
            && (AllowPerks.Length == 0 || f.static.SearchName(AllowPerks, Perk.name) != -1)
            && (BlockPerks.Length == 0 || f.static.SearchName(BlockPerks, Perk.name) == -1);
}

function SetupRepLink(ScrnClientPerkRepLink R)
{
    local int i;

    for (i = R.ShopInventory.length-1; i >= 0; --i ) {
        if (!IsItemAllowed( R.ShopInventory[i].PC)) {
            R.ShopInventory.remove(i, 1);
        }
    }

    for (i = R.CachePerks.length-1; i >= 0; --i ) {
        if (!IsPerkAllowed(class<ScrnVeterancyTypes>((R.CachePerks[i].PerkClass)))) {
            R.CachePerks.remove(i, 1);
        }
    }
}

function SetupRandomItemSpawn(ScrnRandomItemSpawn Items)
{
    local int i;
    local bool bHasItems;

    if (Items.bForceDefault) {
        // we don't want to mess up with the default items, so we copy them to the object and disable bForceDefault
        for (i = 0; i < ArrayCount(Items.PickupClasses); ++i) {
            Items.PickupClasses[i] = Items.default.PickupClasses[i];
            Items.PickupWeight[i] = Items.default.PickupWeight[i];
        }
        Items.bForceDefault = false;
    }

    for (i = 0; i < ArrayCount(Items.PickupClasses); ++i) {
        if (IsItemAllowed(Items.PickupClasses[i])) {
            bHasItems = true;
        }
        else {
            Items.PickupClasses[i] = none;
            Items.PickupWeight[i] = 0;
        }
    }

    if (!bHasItems) {
        Items.bPermanentlyDisabled = true;
        Items.DisableMe();
    }
}

function bool IsStinkyClotAllowed()
{
    return Wave.FtgRule == FTG_Standard;
}

function bool LoadDialogues(out array<string> Dialogues)
{
    if (Dialogues.Length == 0)
        return false;

    if (DialogueHandler == none) {
        DialogueHandler = Game.spawn(DialogueHandlerClass, Game);
        if (DialogueHandler == none)
            return false;
        DialogueHandler.Game = Game;
    }

    return DialogueHandler.Load(Dialogues);
}

function SkipDialogue()
{
    bSkipDialogue = true;
    if (DialogueHandler != none && DialogueHandler.IsRunning()) {
        DialogueHandler.EndDialogue();
    }
}

defaultproperties
{
    WaveInfoClass=class'ScrnWaveInfo'
    ZedInfoClass=class'ScrnZedInfo'
    DialogueHandlerClass=class'ScrnGameDialogueHandler'
    Waves(0)="Wave1"
    Zeds(0)="NormalZeds"
    FallbackZed=class'KFChar.ZombieClot_STANDARD'
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
    RecommendedStartDosh=2000
}
