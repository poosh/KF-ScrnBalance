// the core GameInfo class for ScrN gameplay
class ScrnGameType extends KFGameType;

var ScrnBalance ScrnBalanceMut;
var ScrnGameReplicationInfo ScrnGRI;
var ScrnGameLength ScrnGameLength;

// Min numbers of players to be used in calculation of zed count in wave
// Those values are for configurations only. Set ScrnGRI.FakedPlayers to make in-game effect
var globalconfig protected byte FakedPlayers, FakedAlivePlayers;
var globalconfig string VotingHandlerOverride;  // override VotingHandlerType with this one
var config int DefaultGameLength;
var config bool bAntiBlocker;
var globalconfig byte LogZedSpawnLevel;
const LOG_ERROR     = 1;
const LOG_WARN      = 2;
const LOG_INFO      = 4;
const LOG_DETAIL    = 5;
const LOG_DEBUG     = 7;

var byte BaseDifficulty;  // rounded GameDifficulty, cuz the latter is float (wtf?)
const DIFF_MIN      = 1;
const DIFF_BEGINNER = 1;
const DIFF_NORMAL   = 2;
const DIFF_HARD     = 4;
const DIFF_SUICIDAL = 5;
const DIFF_HOE      = 7;
const DIFF_MAX      = 8; // HoE + Hardcore

var const float MAX_DIST_SQ;

enum EZedSpawnLocation {
    ZSLOC_VANILLA,    // Same as in Vanilla KF
    ZSLOC_CLOSER,     // Spawn zed closer to players (equals to bCloserZedSpawns=True in previous ScrN versions)
    ZSLOC_RANDOM,     // Spawn zeds in random locations no matter of distance to player
    ZSLOC_AUTO        // Auto set the best spawn rating depending from wave stats
};
var EZedSpawnLocation ZedSpawnLoc;
var protected int ZVolVisibleCount;  // number of ZombieVolumes in ZedSpawnList that require player visibility checks
var transient int ZVolCheckIndex; // the index of ZedSpawnList to start visibility check at
var float ZVolVisibilityCheckPeriod;  // Time to check all zombie volumes.
var float ZVolDisableTime, ZVolDisableTimeMax;
var bool bVanillaVisibilityCheck;
var transient float ZVolVisibilityCheckStart;
var float ZedSpawnMinDist, ZedSpawnMaxDist, BossSpawnRecDist;
var float FloorHeight, BasementZ;
var float FloorPenalty;
var float ElevatedSpawnMinZ, ElevatedSpawnMaxZ;
var bool bHighGround;

// Telemetry data of all living player pawns. Updates every tick.
struct STelemetry {
    var Pawn Pawn;
    var float VisibleDistSq;
};
var array<STelemetry> Telemetry;

var private string CmdLine;
var private int TourneyMode;
const TOURNEY_ENABLED           = 0x0001;  // Enable tourney. Allways must be set if any of the below flags is set.
const TOURNEY_VANILLA           = 0x0002;  // allow vanilla game weapons in tourney
const TOURNEY_SWP               = 0x0004;  // allow ScrnWeaponPack
const TOURNEY_ALL_WEAPONS       = 0x0008;  // no weapon filter in tourney
const TOURNEY_ALL_PERKS         = 0x0010;  // no perk filter in tourney
const TOURNEY_HMG               = 0x0020;  // allow Heavy MachineGunner perk

var array<KFAmmoPickup> SleepingAmmo;
var transient int CurrentAmmoBoxCount, DesiredAmmoBoxCount;
//var const protected array< class<Pickup> > CheatPickups; // disallowed pickups in tourney mode

var array<string> InviteList; // contains players' steam IDs

var protected float TurboScale;
var float ZEDTimeTransitionTime;  // time to transit from slowmo to normal game speed
var float ZEDTimeTransitionRate;  // how often (in seconds) to update game speed
var transient float ZEDTimeNextUpdate;

var const bool bSingleTeamGame;
var transient int WavePlayerCount; // alive player count at the beginning of the wave
var transient int AlivePlayerCount, AliveTeamPlayerCount[2];
var array<KFMonster> Bosses;
var transient bool bBossSpawned;
var transient float ZedLastSpawnTime;
var transient int NextSquadTarget[2];
var float KillRemainingZedsCooldown;  // time after LastSpawnTime when games tries to kill the remaining zeds
var int MaxSpawnAttempts, MaxSpecialSpawnAttempts; // maximum spawn attempts before deleting the squad
var float SpawnRatePlayerMod;  // per-player zed spawn rate increase
var int WavePct;  // Current wave's percentage to the final wave.
var string EngGameSong;
var byte ZedEventNum;

struct SBoringStage {
    var float SpawnPeriod;
    var float MinSpawnTime;
    var float ZVolUsageTime;  // time after the last spawn when ZombieVolume gets reduces rating
};
var array<SBoringStage> BoringStages;
var protected byte BoringStage;
var array<localized string> BoringStrings;

// list of actors that AI can't find path towards
var transient array<Actor> InvalidPathTargets;

var bool bKillMessages;  // should the game broadcast kill messages? Set to false if Marco's Kill Messages is in use.
var float DoshDifficultyMult; // Multiplier for Moster.ScoringValue to calculate kill reward

var bool bZedDropDosh, bZedPickupDosh;
enum EDropKind {
    DK_TOSS,
    DK_SPAWN,
    DK_FART
};

var int ExtraZedTimeExtensions;  // extra zed time extentions for all players
var bool bZedTimeEnabled;  // set it to false to completely disable the Zed Time in the game
var transient byte PlayerSpawnTraderTeleportIndex;
var name PlayerStartEvent;
var bool bSuicideTimer;
var transient bool bRestartPlayersTriggered;

var protected transient bool bDebugZedSpawn;
var protected transient ZombieVolume DebugZVols[5];
var protected transient Color DebugZVolColors[5];
var protected transient int NextDebugZVolIndex;

// InitGame() gets called before PreBeginPlay()! Therefore, GameReplicationInfo does not exist yet.
event InitGame( string Options, out string Error )
{
    local int ConfigMaxPlayers;
    local GameRules g;
    local string InOpt;
    local class<ScrnGameLength> GameLengthClass;

    CmdLine = Options;
    if (DefaultGameLength >= 0) {
        KFGameLength = DefaultGameLength;
    }
    KFGameLength = GetIntOption(Options, "GameLength", KFGameLength);
    ZedEventNum = GetIntOption(Options, "ZedEvent", ZedEventNum);
    ConfigMaxPlayers = default.MaxPlayers;

    InOpt = ParseOption( Options, "VotingHandler");
    if( InOpt != "" ) {
        log("VotingHandlerType="$InOpt, class.name);
    }
    else if ( VotingHandlerOverride != "" ) {
        log("Override VotingHandlerType with " $ VotingHandlerOverride, class.name);
        Options $= "?VotingHandler=" $ VotingHandlerOverride;
    }

    // bypass KFGameType
    super(Invasion).InitGame(Options, Error);

    InitLevelRules();
    InitGameVolumes();

    InOpt = ParseOption(Options, "UseBots");
    if ( InOpt != "" ) {
        bNoBots = !bool(InOpt);
    }

    if ( VotingHandler != none ) {
        log("VotingHandler=" $ VotingHandler.class, class.name);
    }
    else if ( Level.NetMode != NM_StandAlone ) {
        warn("No VotingHandler!");
    }

    MaxPlayers = Clamp(GetIntOption(Options, "MaxPlayers", ConfigMaxPlayers),0,32);
    default.MaxPlayers = Clamp(ConfigMaxPlayers, 0, 32);

    CheckScrnBalance();
    ScrnBalanceMut.SetStartCash();
    if ( ScrnBalanceMut.bScrnWaves ) {
        if (ScrnGameLength == none ) {  // mutators might already load this
            if (ScrnBalanceMut.bUserGames && KFGameLength >= 100 && KFGameLength < 200) {
                GameLengthClass = class'ScrnUserGameLength';
            }
            else {
                GameLengthClass = class'ScrnGameLength';
            }
            ScrnGameLength = new(none, string(KFGameLength)) GameLengthClass;
        }
        ScrnGameLength.LoadGame(self);
    }
    else {
        if ( KFGameLength < 0 || KFGameLength > 3) {
            log("GameLength must be in [0..3]: 0-short, 1-medium, 2-long, 3-custom", class.name);
            KFGameLength = GL_Long;
        }
        UpdateGameLength();

        MonsterCollection = SpecialEventMonsterCollections[ GetSpecialEventType() ];
        log("MonsterCollection = " $ MonsterCollection, class.name);

        bCustomGameLength = KFGameLength == GL_Custom;
        if (!bCustomGameLength) {
            InitialWave = 0;
            bUseEndGameBoss = true;
            bRespawnOnBoss = true;
            if (StandardMonsterClasses.Length > 0) {
                MonsterClasses = StandardMonsterClasses;
            }
            MonsterSquad = StandardMonsterSquads;
            MaxZombiesOnce = StandardMaxZombiesOnce;
            PrepareSpecialSquads();
        }
        LoadUpMonsterList();
    }

    WavePct = 100 / FinalWave;

    for ( g = GameRulesModifiers; g != none; g = g.NextGameRules ) {
        if ( g.IsA('KillsRules') ) {
            // Marco's Kill Messages mutator is active - deactivate the builtin messages
            bKillMessages = false;
        }
    }

    InitNavigationPoints();

    if ( IsTestMap() ) {
        bAntiBlocker = false; // disable AntiBlocker on test map
    }

    ScrnBalanceMut.CheckMutators();

    TourneyMode = GetIntOption(Options, "Tourney", TourneyMode);
    PreStartTourney(TourneyMode);
    if ( TourneyMode != 0 ) {
        if ( (TourneyMode & TOURNEY_ENABLED) == 0 ) {
            warn("TOURNEY_ENABLED flag is not set. Setting it now.");
            TourneyMode = TourneyMode | TOURNEY_ENABLED;
        }
        log("*** TOURNEY MODE ("$TourneyMode$")***", class.name);
    }
    if ( TourneyMode != 0 )
        StartTourney();
}

// this one is called from PreBeginPlay() but AFTER (!) InitGame()
function InitGameReplicationInfo()
{
    Super.InitGameReplicationInfo();

    ScrnGRI = ScrnGameReplicationInfo(GameReplicationInfo);
    if ( ScrnGRI == none ) {
        Warn("Wrong GameReplicationInfo class: " $ GameReplicationInfo);
        return;
    }

    if ( ScrnGameLength != none ) {
        if ( ScrnGameLength.VersionCheck() ) {
            ScrnGRI.GameVersion = ScrnGameLength.GameVersion;
        }
        else {
            ScrnGRI.GameVersion = -1;
            log("Bad game version! Game " $ ScrnBalanceMut.VersionStr(ScrnGameLength.GameVersion)
                    $ ", Wave " $ ScrnBalanceMut.VersionStr(ScrnGameLength.Wave.GameVersion), class.name);
        }
        ScrnGRI.GameTitle = ScrnGameLength.GameTitle;
        ScrnGRI.GameAuthor = ScrnGameLength.Author;
        ScrnGRI.FakedPlayers = FakedPlayers;
        ScrnGRI.FakedAlivePlayers = FakedAlivePlayers;
        ScrnGRI.bStopCountDown = !bSuicideTimer;
    }
}

function InitLevelRules()
{
    local KFLevelRules KFLRit;

    foreach DynamicActors(class'KFLevelRules', KFLRit) {
        if (KFLRules==none) {
            KFLRules = KFLRit;
            log("KFLRules = " $ KFLRules);
        }
        else {
            warn("MULTIPLE KFLEVELRULES FOUND!!!!!");
        }
    }

    //provide default rules if mapper did not need custom one
    if(KFLRules==none) {
        log("Map has no KFLevelRules. Spawn default.", class.name);
        KFLRules = spawn(class'KFLevelRules');
    }
}

function InitGameVolumes()
{
    local ShopVolume SH;
    local ZombieVolume ZVol;

    foreach AllActors(class'ShopVolume', SH) {
        if (!SH.bObjectiveModeOnly || bUsingObjectiveMode) {
            ShopList[ShopList.Length] = SH;
        }
    }

    foreach DynamicActors(class'ZombieVolume', ZVol) {
        if (!ZVol.bObjectiveModeOnly || bUsingObjectiveMode) {
            ZedSpawnList[ZedSpawnList.Length] = ZVol;
        }
    }
}

static event class<GameInfo> SetGameType( string MapName )
{
    local string prefix;

    prefix = Caps(Left(MapName, InStr(MapName, "-")));
    if ( prefix == default.MapPrefix )
        return default.class;
    return class'ScrnBalance'.static.GameByMapPrefix(prefix, default.class);
}

function bool IsTestMap()
{
    return ScrnBalanceMut.bTestMap;
}

protected function CheckScrnBalance()
{
    if ( ScrnBalanceMut == none ) {
        log("Loading ScrnBalance...", class.name);
        AddMutator(class'ScrnGameType'.outer.name $ ".ScrnBalance", false);
        if ( ScrnBalanceMut == none )
            log("Unable to spawn ScrnBalance!", class.name);
    }
}

// is called in the first tick from ScrnBalance.Tick()
function CheckZedSpawnList()
{
    local int i;
    local ZombieVolume ZVol;
    local ScrnMapInfo MapInfo;
    local float f, DesireMin, DesireMax, DesireTotal;
    local int DesireDefaultCount;
    local rotator rot;
    local NavigationPoint N;

    MapInfo = ScrnBalanceMut.MapInfo;

    // first pass: remove bad volumes
    for ( i = 0; i < ZedSpawnList.Length; ++i ) {
        ZVol = ZedSpawnList[i];
        if ( ZVol == none ) {
            ZedSpawnList.remove(i--, 1);
            continue;
        }
        if ( ZVol.SpawnPos.length == 0 ) {
            ZVol.InitSpawnPoints();
            if ( ZVol.SpawnPos.length == 0 ) {
                LogZedSpawn(LOG_WARN, ZVol.name $ " init failed");
                ZedSpawnList.remove(i--, 1);
                continue;
            }
        }
        // We reuse bHasInitSpawnPoints to mark elevated spawns.
        // The original bHasInitSpawnPoints is redundant because we can simply check SpawnPos.length
        ZVol.bHasInitSpawnPoints = false;
    }

    // second pass: load ZVol map config
    FloorPenalty = fclamp(MapInfo.FloorPenalty, 0.0, 0.9);
    FloorHeight = fmax(MapInfo.FloorHeight, 64);
    BasementZ = MapInfo.BasementZ;
    if ( MapInfo.ElevatedSpawnMinZ != 0 ) {
        ElevatedSpawnMinZ = MapInfo.ElevatedSpawnMinZ;
    }
    else {
        ElevatedSpawnMinZ = fmin(FloorHeight * 0.5, 160);
    }
    if ( MapInfo.ElevatedSpawnMaxZ != 0 ) {
        ElevatedSpawnMaxZ = MapInfo.ElevatedSpawnMaxZ;
    }
    else {
        ElevatedSpawnMaxZ = FloorHeight * 2.0;
    }
    ZedSpawnMaxDist = fmax(MapInfo.ZedSpawnMaxDist, ZedSpawnMinDist);
    bHighGround = MapInfo.bHighGround;
    ZVolDisableTime = MapInfo.ZVolDisableTime;
    ZVolDisableTimeMax = MapInfo.ZVolDisableTimeMax;
    bVanillaVisibilityCheck = MapInfo.bVanillaVisibilityCheck;
    MapInfo.ProcessZombieVolumes(ZedSpawnList);

    // third pass: precalc stuff
    ZVolVisibleCount = 0;
    DesireMin = ZedSpawnList[0].SpawnDesirability;
    DesireMax = ZedSpawnList[0].SpawnDesirability;
    for (i = 0; i < ZedSpawnList.Length; ++i ) {
        ZVol = ZedSpawnList[i];
        if ( !ZVol.bAllowPlainSightSpawns ) {
            ++ZVolVisibleCount;
        }

        f = ZVol.SpawnDesirability;
        DesireTotal += f;
        if ( f < DesireMin ) {
            DesireMin = f;
        }
        else if ( f > DesireMax ) {
            DesireMax = f;
        }
        if ( abs(f - class'ZombieVolume'.default.SpawnDesirability) < 1.0 ) {
            ++DesireDefaultCount;
        }
        else {
            LogZedSpawn(LOG_DEBUG, ZVol.name $ ".SpawnDesirability=" $ ZVol.SpawnDesirability);
        }

        // Rotate spawned zeds to the closest path node. It lowers the chance to get stuck.
        // Volumes do not use DesiredRotation. So we reuse it to store desired rotation
        N = FindClosestPathNode(ZVol);
        if ( N != none && ZVol.bAllowPlainSightSpawns && ZVol.Encompasses(N) ) {
            // stupid L.D. put PathNode inside the volume, screwing up navigation.
            InvalidatePathTarget(N);
            N = FindClosestPathNode(ZVol);
        }
        if ( N != none ) {
            rot = rotator(N.Location - ZVol.Location);
            rot.yaw = (rot.yaw + 8192) / 16384;  // snap to 90 degrees
        }
        else {
            // random rotation to one of four sides
            rot.yaw = 16384 * rand(4);
        }
        rot.pitch = 0;
        rot.roll = 0;
        ZVol.DesiredRotation = rot;
    }
    if ( MapInfo.bTestMap ) {
        LogZedSpawn(LOG_INFO, "TEST MAP");
    }
    LogZedSpawn(LOG_INFO, "Map has " $ ZedSpawnList.Length $ " valid zombie volumes: " $ ZVolVisibleCount
            $ " visible + " $ string(ZedSpawnList.Length - ZVolVisibleCount) $ " invisible");
    if ( DesireMax - DesireMin < 1 ) {
        LogZedSpawn(LOG_INFO, "All zomvie volumes have the same SpawnDesirability="$ int(DesireMin+0.5));
    }
    else {
        LogZedSpawn(LOG_INFO, DesireDefaultCount$"/"$ZedSpawnList.Length
                $ " zombie volumes have default SpawnDesirability."
                $ " Min=" $ int(DesireMin+0.5) $ " Max=" $ int(DesireMax+0.5)
                $ " Avg="$int(DesireTotal/ZedSpawnList.Length + 0.5));
    }
    LogZedSpawn(LOG_INFO,   "MaxZombiesOnce=" $ MaxZombiesOnce);
    LogZedSpawn(LOG_INFO,   "WaveSpawnPeriod=" $ KFLRules.WaveSpawnPeriod);
    LogZedSpawn(LOG_INFO,   "ZVolDisableTime=" $ ZVolDisableTime);
    LogZedSpawn(LOG_INFO,   "ZVolDisableTimeMax=" $ ZVolDisableTimeMax);
    LogZedSpawn(LOG_INFO,   "bVanillaVisibilityCheck=" $ bVanillaVisibilityCheck);
    LogZedSpawn(LOG_INFO,   "ZedSpawnMaxDist=" $ ZedSpawnMaxDist);
    LogZedSpawn(LOG_INFO,   "FloorHeight=" $ FloorHeight);
    if ( BasementZ != 0 )
        LogZedSpawn(LOG_INFO, "BasementZ=" $ BasementZ);
    LogZedSpawn(LOG_INFO,   "FloorPenalty=" $ FloorPenalty);
    LogZedSpawn(LOG_INFO,   "bHighGround=" $ bHighGround);
    LogZedSpawn(LOG_INFO,   "ElevatedSpawnMinZ=" $ ElevatedSpawnMinZ);
    LogZedSpawn(LOG_INFO,   "ElevatedSpawnMaxZ=" $ ElevatedSpawnMaxZ);
}

function bool IsPathTargetValid(Actor PathTarget)
{
    local int i;

    for ( i = 0; i < InvalidPathTargets.length; ++i ) {
        if ( InvalidPathTargets[i] == PathTarget )
            return false;
    }
    return true;
}

function InvalidatePathTarget(Actor PathTarget, optional bool bForceAdd)
{
    if ( PathTarget == none )
        return;

    if ( bForceAdd || IsPathTargetValid(PathTarget) ) {
        LogZedSpawn(LOG_WARN, "Invalid Path Target: " $ PathTarget);
        InvalidPathTargets[InvalidPathTargets.length] = PathTarget;
    }
}

function NavigationPoint FindClosestPathNode(Actor anActor, optional float MaxDist)
{
    local NavigationPoint N, BestN;
    local float NDistSquared, BestDistSquared;
    local bool bNVisible, bBestVisible;

    if ( anActor == none )
        return none;

    if ( MaxDist == 0 ) {
        MaxDist = 262144;  // 512uu squared (roughly 10m)
    }
    else {
        MaxDist *= MaxDist;
    }

    for (N = Level.NavigationPointList; N != none; N = N.nextNavigationPoint) {
        if ( !N.IsA('PathNode') || N == anActor )
            continue; // ignore teleporters, jumpads etc.
        NDistSquared = VSizeSquared(anActor.Location - N.Location);
        if ( NDistSquared < MaxDist ) {
            bNVisible = FastTrace(anActor.Location, N.Location);
            if ( bBestVisible && !bNVisible )
                continue; // ignore invisible points if there are visible alteratives
            else if ( BestN == none || (bNVisible && !bBestVisible) || NDistSquared < BestDistSquared ) {
                if ( IsPathTargetValid(N) ) {
                    BestN = N;
                    BestDistSquared = NDistSquared;
                    bBestVisible = bNVisible;
                }
            }
        }
    }
    return BestN;
}

function NavigationPoint FindPathNodeByName(name PathName)
{
    local NavigationPoint N;

    if ( PathName == '' )
        return none;

    for (N = Level.NavigationPointList; N != none; N = N.nextNavigationPoint) {
        if ( N.name == PathName )
            return N;
    }
    return none;
}

function LoadUpMonsterList()
{
    CheckScrnBalance();
    if ( !ScrnBalanceMut.bScrnWaves )
        super.LoadUpMonsterList();
}

function PrepareSpecialSquads()
{
    CheckScrnBalance();
    if ( !ScrnBalanceMut.bScrnWaves )
        super.PrepareSpecialSquads();
}

function SetTurboScale(float NewScale)
{
    if ( IsTourney() )
        return;

    TurboScale = fmax( NewScale, 0.2 );
}

// Overriden to handle ZEDTime zombie death slomo system
event Tick(float dt)
{
    if( bZEDTimeActive ) {
        HandleZedTime(dt);
    }
}

function LoadTelemetry()
{
    local Controller C;
    local int i, j;

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if ( C.bIsPlayer && C.Pawn!=none && C.Pawn.Health>0 ) {
            if ( i < Telemetry.length && Telemetry[i].Pawn != C.Pawn ) {
                // the current telemetry entry probably belongs to a dead player
                // remove dead bodies
                for ( j = i; j < Telemetry.length; ++j) {
                    if ( Telemetry[j].Pawn == C.Pawn )
                        break;
                }
                Telemetry.remove(i, j - i);
            }

            if ( i >= Telemetry.length || Telemetry[i].Pawn != C.Pawn ) {
                Telemetry.insert(i, 1);
                Telemetry[i].Pawn = C.Pawn;
            }

            if ( C.Pawn.Region.Zone.bDistanceFog ) {
                Telemetry[i].VisibleDistSq = C.Pawn.Region.Zone.DistanceFogEnd**2;
            }
            else {
                Telemetry[i].VisibleDistSq = MAX_DIST_SQ;
            }
            ++i;
        }
    }
    Telemetry.length = i;
}

// called each time when all zombie volumes got checked
function ZVolCheckNewCycle()
{
    ZVolVisibilityCheckStart = Level.TimeSeconds;
}

function protected bool ZVolCheckTrace(ZombieVolume ZVol, vector PlayerPos, vector ZVolPos,
        out float MinDistSq, float MaxDistSq)
{
    MinDistSq = fmin(MinDistSq, VSizeSquared(ZVolPos - PlayerPos));
    return ZVol.bAllowPlainSightSpawns || MinDistSq > MaxDistSq || !FastTrace(ZVolPos, PlayerPos);
}

function ZVolCheckPlayers(int count)
{
    local ZombieVolume ZVol;
    local int i, x;
    local Vector EyeLoc;
    local Pawn P;
    local float CheckBegin, MaxDistSq, MinDistSq;
    local bool bSecondLoop;

    // start validating volumes half-way before they become valid.
    CheckBegin = Level.TimeSeconds + ZVolDisableTime * 0.5;

    while ( count > 0 ) {
        ZVol = ZedSpawnList[ZVolCheckIndex];
        // LastCheckTime actually is the time until ZVol is invalid
        if ( CheckBegin > ZVol.LastCheckTime ) {
            MinDistSq = MAX_DIST_SQ;
            x = ZVol.SpawnPos.length;
            for ( i = 0; i < Telemetry.length; ++i ) {
                P = Telemetry[i].Pawn;
                MaxDistSq = Telemetry[i].VisibleDistSq;
                EyeLoc = P.Location + P.EyePosition();

                if( ZVol.Encompasses(P) ) {
                    // player is inside this volume
                    DisableZombieVolume(ZVol);
                    break;
                }

                if ( bVanillaVisibilityCheck ) {
                    if (!ZVolCheckTrace(ZVol, EyeLoc, ZVol.Location, MinDistSq, MaxDistSq)) {
                        // player sees the volume
                        DisableZombieVolume(ZVol);
                        break;
                    }
                }
                else if ( !ZVolCheckTrace(ZVol, EyeLoc, ZVol.SpawnPos[0], MinDistSq, MaxDistSq)
                        || (x > 1 && !ZVolCheckTrace(ZVol, EyeLoc, ZVol.SpawnPos[x-1], MinDistSq, MaxDistSq))
                        || (x > 7 && !ZVolCheckTrace(ZVol, EyeLoc, ZVol.SpawnPos[x>>1], MinDistSq, MaxDistSq)
                            || !ZVolCheckTrace(ZVol, EyeLoc, ZVol.SpawnPos[x>>2], MinDistSq, MaxDistSq)) )
                {
                    // player sees the spawn points in the volume
                    DisableZombieVolume(ZVol);
                    break;
                }
            }
            // CanRespawnTime is not used elsewhere; we reuse it to store the closest distance to players
            ZVol.CanRespawnTime = sqrt(MinDistSq);
        }

        if ( ++ZVolCheckIndex >= ZedSpawnList.length ) {
            ZVolCheckIndex = 0;
            if ( bSecondLoop ) {
                warn("Circular loop detected in processing zombie volumes");
                return;
            }
            bSecondLoop = true;
            ZVolCheckNewCycle();
        }
        --count;
    }
}

function int GetZVolVisibleCount()
{
    return ZVolVisibleCount;
}

function HandleZedTime(float dt)
{
    local Controller C;

    if( !bZEDTimeActive )
        return;

    // convert dt into true time
    CurrentZEDTimeDuration -= dt * 1.1/Level.TimeDilation;

    if( CurrentZEDTimeDuration <= 0 ) {
        bZEDTimeActive = false;
        bSpeedingBackUp = false;
        SetGameSpeed(TurboScale);
        ZedTimeExtensionsUsed = -ExtraZedTimeExtensions;
    }
    else if( CurrentZEDTimeDuration < ZEDTimeTransitionTime ) {
        if( !bSpeedingBackUp ) {
            bSpeedingBackUp = true;
            ZEDTimeNextUpdate = CurrentZEDTimeDuration;
            for( C=Level.ControllerList;C!=None;C=C.NextController ) {
                if (KFPlayerController(C)!= none)
                    KFPlayerController(C).ClientExitZedTime();
            }
        }
        if ( CurrentZEDTimeDuration <= ZEDTimeNextUpdate || Level.NetMode == NM_StandAlone ) {
            ZEDTimeNextUpdate = CurrentZEDTimeDuration - ZEDTimeTransitionRate;
            SetGameSpeed(Lerp(CurrentZEDTimeDuration/ZEDTimeTransitionTime, TurboScale, ZedTimeSlomoScale ));
        }
    }
}

function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum,
        class<DamageType> DamageType)
{
    local KFPlayerController InstigatorPC;
    local KFPlayerReplicationInfo InjuredKFPRI;

    if( injured.InGodMode() )
        return 0;

    if ( instigatedBy != none )
        InstigatorPC = KFPlayerController(instigatedBy.Controller);

    if ( Monster(Injured) != None ) {
        if ( InstigatorPC != none && Class<KFWeaponDamageType>(damageType) != none ) {
            Class<KFWeaponDamageType>(damageType).Static.AwardDamage(
                    KFSteamStatsAndAchievements(InstigatorPC.SteamStatsAndAchievements), Clamp(Damage, 1, Injured.Health));
        }
        return super(GameInfo).ReduceDamage( Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType );
    }

    if ( KFPawn(Injured) != none ) {
        InjuredKFPRI = KFPlayerReplicationInfo(Injured.PlayerReplicationInfo);
        if ( InjuredKFPRI != none && InjuredKFPRI.ClientVeteranSkill != none )
            Damage = InjuredKFPRI.ClientVeteranSkill.Static.ReduceDamage(InjuredKFPRI, KFPawn(Injured), instigatedBy,
                    Damage, DamageType);
    }

    if ( injured == instigatedBy ) {
        // self damage
        if ( BaseDifficulty < DIFF_HARD )
            Damage *= 0.25;
        else
            Damage *= 0.5;
    }
    else if ( instigatedBy != none ) {
        if ( Level.TimeSeconds - injured.SpawnTime < SpawnProtectionTime
                && (class<WeaponDamageType>(DamageType) != None || class<VehicleDamageType>(DamageType) != None) )
            return 0;

        damage *= instigatedBy.DamageScaling;

        if ( InstigatorPC == none && InjuredKFPRI != none && KFFriendlyAI(InstigatedBy.Controller) != None )
            Damage *= 0.25;

        if ( MonsterController(InstigatedBy.Controller) == None
                && (instigatedBy.Controller==None || instigatedBy.GetTeamNum()==injured.GetTeamNum()) )
        {
            // Friendly fire
            if ( class<WeaponDamageType>(DamageType) != None || class<VehicleDamageType>(DamageType) != None )
                Momentum *= TeammateBoost;
            if ( Bot(injured.Controller) != None )
                Bot(Injured.Controller).YellAt(instigatedBy);

            if ( FriendlyFireScale==0.0 || (Vehicle(injured) != None && Vehicle(injured).bNoFriendlyFire) ) {
                if ( GameRulesModifiers != None )
                    return GameRulesModifiers.NetDamage( Damage, 0,injured,instigatedBy,HitLocation,Momentum,DamageType );
                else
                    return 0;
            }
            Damage = round( Damage * FriendlyFireScale );
        }
    }

    Damage = super(GameInfo).ReduceDamage(Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType);

    return Damage;
}

// removed checks for steam achievements
function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local KFPlayerReplicationInfo KFPRI;
    local KFSteamStatsAndAchievements StatsAndAchievements;
    local class<KFWeaponDamageType> KFDamType;
    local KFMonster KilledMonster;

    KFDamType = class<KFWeaponDamageType>(damageType);
    KilledMonster = KFMonster(KilledPawn);

    if ( PlayerController(Killer) != none ) {
        KFPRI = KFPlayerReplicationInfo(Killer.PlayerReplicationInfo);
        if ( KilledMonster != None && Killed != Killer ) {
            if ( bZEDTimeActive && KFPRI != none && KFPRI.ClientVeteranSkill != none
                    && KFPRI.ClientVeteranSkill.static.ZedTimeExtensions(KFPRI) > ZedTimeExtensionsUsed )
            {
                // Force Zed Time extension for every kill as long as the Player's Perk has Extensions left
                if ( Level.TimeSeconds - LastZedTimeEvent > 0.05 ) {
                    DramaticEvent(1.0);
                    ZedTimeExtensionsUsed++;
                }
            }
            else if ( Level.TimeSeconds - LastZedTimeEvent > 0.1 ) {
                // Possibly do a slomo event when a zombie dies, with a higher chance if the zombie is closer to a player
                if( Killer.Pawn != none && VSizeSquared(Killer.Pawn.Location - KilledPawn.Location) < 22500 ) // 3 meters
                    DramaticEvent(0.05);
                else
                    DramaticEvent(0.025);
            }

            StatsAndAchievements = KFSteamStatsAndAchievements(PlayerController(Killer).SteamStatsAndAchievements);
            if ( StatsAndAchievements != none ) {
                if ( KFDamType != none ) {
                    KFDamType.Static.AwardKill(StatsAndAchievements,KFPlayerController(Killer), KilledMonster);
                }

                StatsAndAchievements.AddKill(false, false, false, false, false, false, false, false, false, "");
            }
        }
    }

    if ( KilledMonster != none || MonsterController(Killed) != None ) {
        ZombiesKilled++;
        ScrnGRI.MaxMonsters = Max(TotalMaxMonsters + NumMonsters - 1, 0);

        if ( bZedDropDosh ) {
            ZedTossCashFromDamage(KilledMonster, KFDamType);
        }

        if ( !bDidTraderMovingMessage )
        {
            if ( PlayerController(Killer) != none && float(ZombiesKilled) / float(ZombiesKilled + TotalMaxMonsters + NumMonsters - 1) >= 0.20 )
            {
                if ( WaveNum < FinalWave - 1 || (WaveNum < FinalWave && bUseEndGameBoss) )
                {
                    // Have Trader tell players that the Shop's Moving
                    PlayerController(Killer).ServerSpeech('TRADER', 0, "");
                }

                bDidTraderMovingMessage = true;
            }
        }
        else if ( !bDidMoveTowardTraderMessage )
        {
            if ( PlayerController(Killer) != none && float(ZombiesKilled) / float(ZombiesKilled + TotalMaxMonsters + NumMonsters - 1) >= 0.80 )
            {
                if ( WaveNum < FinalWave - 1 || (WaveNum < FinalWave && bUseEndGameBoss) )
                {
                    if ( Level.NetMode != NM_Standalone || Killer.Pawn == none || ScrnGRI.CurrentShop == none ||
                         VSizeSquared(Killer.Pawn.Location - ScrnGRI.CurrentShop.Location) > 2250000 ) // 30 meters
                    {
                        // Have Trader tell players that the Shop's Almost Open
                        PlayerController(Killer).Speech('TRADER', 1, "");
                    }
                }

                bDidMoveTowardTraderMessage = true;
            }
        }
    }

    Super(Invasion).Killed(Killer,Killed,KilledPawn,DamageType);
}

function DramaticEvent(float BaseZedTimePossibility, optional float DesiredZedTimeDuration)
{
    if ( bZedTimeEnabled && BaseZedTimePossibility > 0 ) {
        super.DramaticEvent(BaseZedTimePossibility, DesiredZedTimeDuration);
    }
}

function ScoreKill(Controller Killer, Controller Victim)
{
    local PlayerReplicationInfo VictimPRI;
    local float KillScore;
    local Controller C;

    VictimPRI = Victim.PlayerReplicationInfo;
    if ( VictimPRI != None ) {
        if ( VictimPRI.bOnlySpectator )
            return;  // player became a spectator

        VictimPRI.NumLives++;
        VictimPRI.Score -= (VictimPRI.Score * (GameDifficulty * 0.05));
        if (VictimPRI.Score < 0 )
            VictimPRI.Score = 0;
        VictimPRI.NetUpdateTime = Level.TimeSeconds - 1;

        if ( VictimPRI.Team != none ) {
            VictimPRI.Team.Score -= 100;
            if (VictimPRI.Team.Score < 0 )
                VictimPRI.Team.Score = 0;
            VictimPRI.Team.NetUpdateTime = Level.TimeSeconds - 1;
        }

        VictimPRI.bOutOfLives = true;
        if( Killer!=None && Killer.PlayerReplicationInfo!=None && Killer.bIsPlayer )
            BroadcastLocalizedMessage(class'KFInvasionMessage',1,VictimPRI,Killer.PlayerReplicationInfo);
        else if( Killer==None || Monster(Killer.Pawn)==None )
            BroadcastLocalizedMessage(class'KFInvasionMessage',1,VictimPRI);
        else
            BroadcastLocalizedMessage(class'KFInvasionMessage',1,VictimPRI,,Killer.Pawn.Class);

        CheckScore(None);
    }

    if ( GameRulesModifiers != None )
        GameRulesModifiers.ScoreKill(Killer, Victim);

    if ( Killer == None || !Killer.bIsPlayer || Killer.PlayerReplicationInfo == none )
        return;

    if ( Killer == Victim ) {
        ScoreEvent(VictimPRI, -1, "self_frag");
        return;
    }

    if ( Victim.bIsPlayer ) {
        // p2p kills
        if ( Killer.PlayerReplicationInfo.Team == VictimPRI.Team ) {
            if ( VictimPRI != none ) {
                KillScore = min(200, Killer.PlayerReplicationInfo.Score);
                Killer.PlayerReplicationInfo.Score -= KillScore;
                VictimPRI.Score += KillScore;
                Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
            }
            ScoreEvent(Killer.PlayerReplicationInfo, -1, "team_frag");
        }
        else {
            Killer.PlayerReplicationInfo.Score += 100;
            Killer.PlayerReplicationInfo.Team.Score += 100;
            Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
            Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
            ScoreEvent(Killer.PlayerReplicationInfo, 1, "tdm_frag");
        }

        if (Killer.PlayerReplicationInfo.Score < 0 )
            Killer.PlayerReplicationInfo.Score = 0;
        if (Killer.PlayerReplicationInfo.Team.Score < 0 )
            Killer.PlayerReplicationInfo.Team.Score = 0;
        return;
    }

    // v9.52: allow customization of ScoringValue for each zed in addition to zed type
    if ( Monster(Victim.Pawn) != none ) {
        KillScore = Monster(Victim.Pawn).ScoringValue;
    }
    else if ( LastKilledMonsterClass != none ) {
        KillScore = LastKilledMonsterClass.Default.ScoringValue;
    }
    else {
        KillScore = 5; // reward for killing some crap: non-player, non-monster...
    }

    // Scale killscore by difficulty
    KillScore *= DoshDifficultyMult;

    KillScore = Max(1,int(KillScore));
    Killer.PlayerReplicationInfo.Kills++;

    ScoreKillAssists(KillScore, Victim, Killer);

    Killer.PlayerReplicationInfo.Team.Score += KillScore;
    Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
    Killer.PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
    TeamScoreEvent(Killer.PlayerReplicationInfo.Team.TeamIndex, 1, "tdm_frag");

    if (Killer.PlayerReplicationInfo.Score < 0)
        Killer.PlayerReplicationInfo.Score = 0;

    if ( bKillMessages ) {
        if( Class'HUDKillingFloor'.Default.MessageHealthLimit<=Victim.Pawn.Default.Health ||
        Class'HUDKillingFloor'.Default.MessageMassLimit<=Victim.Pawn.Default.Mass )
        {
            for( C=Level.ControllerList; C!=None; C=C.nextController )
            {
                if( C.bIsPlayer && xPlayer(C)!=None )
                {
                    xPlayer(C).ReceiveLocalizedMessage(Class'KillsMessage',1,Killer.PlayerReplicationInfo,,Victim.Pawn.Class);
                }
            }
        }
        else
        {
            if( xPlayer(Killer)!=None )
            {
                xPlayer(Killer).ReceiveLocalizedMessage(Class'KillsMessage',,,,Victim.Pawn.Class);
            }
        }
    }
}

function ScoreKillAssists(float Score, Controller Victim, Controller Killer)
{
    local int i;
    local float GrossDamage, ScoreMultiplier, KillScore;
    local KFMonsterController MyVictim;
    local KFPlayerReplicationInfo KFPRI;

    MyVictim = KFMonsterController(Victim);

    if ( MyVictim == none || MyVictim.KillAssistants.Length < 1 )
        return;

    for ( i = 0; i < MyVictim.KillAssistants.Length; ++i ) {
        GrossDamage += MyVictim.KillAssistants[i].Damage;
    }

    if ( GrossDamage <= 0 )
        return;

    ScoreMultiplier = Score / GrossDamage;

    for ( i = 0; i < MyVictim.KillAssistants.Length; i++  ) {
        if ( MyVictim.KillAssistants[i].PC != none
                && MyVictim.KillAssistants[i].PC.PlayerReplicationInfo != none)
        {
            KillScore = ScoreMultiplier * MyVictim.KillAssistants[i].Damage;
            if ( KillScore < 0.5 )
                continue;

            KillScore = round(KillScore);
            MyVictim.KillAssistants[i].PC.PlayerReplicationInfo.Score += KillScore;

            KFPRI = KFPlayerReplicationInfo(MyVictim.KillAssistants[i].PC.PlayerReplicationInfo) ;
            if ( KFPRI != none ) {
                if ( MyVictim.KillAssistants[i].PC != Killer ) {
                    KFPRI.KillAssists ++ ;
                }
                KFPRI.ThreeSecondScore += KillScore;
            }
        }
    }
}

function bool RewardSurvivingPlayers()
{
    local Controller C;
    local int SurvivedPlayers[2];
    local int moneyPerPlayer[2];
    local byte t;

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none
                && C.PlayerReplicationInfo.Team.TeamIndex < 2 )
        {
            t = C.PlayerReplicationInfo.Team.TeamIndex;
            SurvivedPlayers[t]++;
        }
    }


    for ( t = 0; t < 2; ++t ) {
        // bug: Team 0 scored $-1.#J. 6 survivors, earned $0 each.
        if ( Teams[t].Score < 0 || Teams[t].Score > 1000000000 ) {
            log("!!! BUGGED TEAM SCORE: " $ Teams[t].Score, 'ScrnBalance');
            Teams[t].Score = 0;
        }
        else if ( !(Teams[t].Score < 0 || Teams[t].Score >= 0) ) {
            log("!!! BUGGED TEAM SCORE (NAN): " $ Teams[t].Score, 'ScrnBalance');
            Teams[t].Score = 0;
        }
        else if ( SurvivedPlayers[t] > 0 ) {
            moneyPerPlayer[t] = Teams[t].Score / SurvivedPlayers[t];
            Teams[t].NetUpdateTime = Level.TimeSeconds - 1;
            log("Team " $ t $ " scored $" $  Teams[t].Score $ ". " $ SurvivedPlayers[t]
                    $ " survivors, earned $" $ moneyPerPlayer[t] $ " each."
                    , 'ScrnBalance');
        }
    }

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if ( C.Pawn != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none
                && C.PlayerReplicationInfo.Team.TeamIndex < 2 )
        {
            t = C.PlayerReplicationInfo.Team.TeamIndex;
            if ( SurvivedPlayers[t] > 1 ) {
                C.PlayerReplicationInfo.Score += moneyPerPlayer[t];
                Teams[t].Score -= moneyPerPlayer[t];
            }
            else if ( SurvivedPlayers[t] == 1 ) {
                C.PlayerReplicationInfo.Score += Teams[t].Score;
                Teams[t].Score = 0;
            }
            SurvivedPlayers[t]--;
            C.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
        }
    }

    return true;
}

function CalcDoshDifficultyMult() {
    if ( BaseDifficulty >= DIFF_SUICIDAL ) {
        DoshDifficultyMult = 0.65;
    }
    else if ( BaseDifficulty >= DIFF_HARD ) {
        DoshDifficultyMult = 0.85;
    }
    else if ( BaseDifficulty >= DIFF_NORMAL ) {
        DoshDifficultyMult = 1.0;
    }
    else {
        DoshDifficultyMult = 2.0;  // Beginner
    }

    if( ScrnGameLength != none ) {
        DoshDifficultyMult *= ScrnGameLength.GetBountyScale();
    }
    else if ( KFGameLength == GL_Short ) {
        // Increase score in a short game, so the player can afford to buy cool stuff by the end
        DoshDifficultyMult *= 1.75;
    }
}

function ZedTossCashFromDamage(KFMonster M, class<KFWeaponDamageType> KFDamType, optional int Amount)
{
    local EDropKind dk;

    if ( KFDamType == none || KFDamType == class'DamTypeBleedOut' || !KFDamType.default.bCheckForHeadShots )
        dk = DK_SPAWN;
    else if ( ScrnBalanceMut.GameRules.WasHeadshot(M) )
        dk = DK_TOSS; // toss dosh toward players on headshot
    else
        dk = DK_FART; // body shot from weapon capable of doing headhots

    ZedTossCash(M, dk, Amount);
}

function ZedTossCash(KFMonster M, EDropKind DropKind, optional int Amount)
{
    local Vector X,Y,Z;
    local ScrnZedDoshPickup DoshPickup;
    local Vector TossVel, SpawnLocation;

    if ( M == none )
        return;

    if ( Amount <= 0 || Amount > M.ScoringValue )
        Amount = M.ScoringValue;

    if ( Amount <= 0 )
        return;

    M.GetAxes(M.Rotation,X,Y,Z);

    TossVel = Vector(M.GetViewRotation());
    switch ( DropKind ) {
        case DK_SPAWN:
            SpawnLocation =  M.Location;
            //SpawnLocation.Z += M.CollisionHeight * 0.5 - 2.5;
            //TossVel = M.PhysicsVolume.Gravity;
            TossVel = vect(0,0,500);
            break;
        case DK_FART:
            TossVel = -400 * X; // + M.PhysicsVolume.Gravity/2;
            // TossVel = TossVel * ((M.Velocity Dot TossVel) + 500) * Vect(-0.2,-0.2,0);
            // TossVel.Z = M.PhysicsVolume.Gravity.Z;
            SpawnLocation =  M.Location - 0.8 * M.CollisionRadius * X;
            break;
        default:
            TossVel = TossVel * (0.5 + 0.5*frand()) * ((M.Velocity Dot TossVel) + 1000) + Vect(0,0,200);
            SpawnLocation =  M.Location + 0.8 * M.CollisionRadius * X - 0.5 * M.CollisionRadius * Y;
            break;
    }

    DoshPickup = Spawn(class'ScrnZedDoshPickup',,, SpawnLocation);
    // try default spawn location, if unable to spawn in desired location
    if ( DoshPickup == none )
        DoshPickup = Spawn(class'ScrnZedDoshPickup',,, M.Location + 0.8 * M.CollisionRadius * X - 0.5 * M.CollisionRadius * Y);

    if ( DoshPickup != none ) {
        DoshPickup.CashAmount = Amount * DoshDifficultyMult;
        DoshPickup.RespawnTime = 0;
        DoshPickup.bDroppedCash = True;
        DoshPickup.Velocity = TossVel;
        DoshPickup.DroppedBy = M.Controller;
        DoshPickup.InitDroppedPickupFor(None);
        DoshPickup.bZedPickup = bZedPickupDosh;
        M.ScoringValue -= Amount;
    }
}

exec function KillZeds()
{
    local KFMonster M;
    local array <KFMonster> Monsters;
    local int i;
    local bool bZedDropDoshOriginal;

    bZedDropDoshOriginal = bZedDropDosh;
    bZedDropDosh = false;

    // fill the array first, because direct M killing may screw up DynamicActors() iteration
    // -- PooSH
    foreach DynamicActors(class 'KFMonster', M) {
        if(M.Health > 0 && !M.bDeleteMe)
            Monsters[Monsters.length] = M;
    }
    for ( i=0; i<Monsters.length; ++i ) {
        Monsters[i].Died(Monsters[i].Controller, class'DamageType', Monsters[i].Location);
    }

    bZedDropDosh = bZedDropDoshOriginal;
}

function KillRemainingZeds(bool bForceKill)
{
    local Controller C;
    local array<KFMonster> SuicideSquad;
    local int i;

    for ( C = Level.ControllerList; C != None; C = C.NextController ) {
        if ( KFMonsterController(C)!=None && (bForceKill || KFMonsterController(C).CanKillMeYet()) )
            SuicideSquad[SuicideSquad.length] = KFMonster(C.Pawn);
    }

    for ( i = 0; i < SuicideSquad.length; ++i ) {
        SuicideSquad[i].Suicide();
    }
}


// Force slomo for a longer period of time when the boss dies
function DoBossDeath()
{
    local Controller C, NextC;
    local PlayerController PC;
    local KFMonster DeadBoss;
    local int i;

    bZEDTimeActive =  true;
    bSpeedingBackUp = false;
    LastZedTimeEvent = Level.TimeSeconds;
    CurrentZEDTimeDuration = ZEDTimeDuration*2;
    SetGameSpeed(ZedTimeSlomoScale);

    if (!bWaveBossInProgress)
        return;

    // all bosses must be dead before ending the game
    for ( i = 0; i < Bosses.length; ++i ) {
        if ( Bosses[i] != none ) {
            if ( Bosses[i].Health > 0 )
                return; // boss is still alive
            DeadBoss = Bosses[i];
        }
    }

    for ( C = Level.ControllerList; C != None; C = NextC ) {
        NextC = C.NextController;
        PC = PlayerController(C);
        if( PC != none ) {
            if ( DeadBoss != none ) {
                PC.SetViewTarget(DeadBoss);
                PC.ClientSetViewTarget(DeadBoss);
                PC.bBehindView = true;
                PC.ClientSetBehindView(True);
            }
        }
        else if ( KFMonsterController(C) != none ) {
            C.GotoState('GameEnded');
        }
    }
}

function DisableZombieVolume(ZombieVolume ZVol)
{
    // LastCheckTime = DisabledUntilTime
    ZVol.LastCheckTime = Level.TimeSeconds + fclamp(ZVol.TouchDisableTime, ZVolDisableTime, ZVolDisableTimeMax);
}

function bool IsZombieVolumeDisabled(ZombieVolume ZVol)
{
    return Level.TimeSeconds < ZVol.LastCheckTime;
}

function float RateZombieVolume(ZombieVolume ZVol, Pawn SpawnCloseTo, float MaxUsageTime,
        float wDist, float wUsage, float wDesire)
{
    local float Rating;
    local int i;
    local float PlayerDistScore, UsageScore, f;
    local vector ZVolLoc, LocationXY, TestLocationXY;
    local bool bIgnoreZDist, bBasementDiff;

    if ( ZVol == none )
        return -1;

    // check doors
    for ( i=0; i<ZVol.RoomDoorsList.Length; ++i ) {
        if ( ZVol.RoomDoorsList[i].DoorActor!=None && (ZVol.RoomDoorsList[i].DoorActor.bSealed
                || (!ZVol.RoomDoorsList[i].bOnlyWhenWelded && ZVol.RoomDoorsList[i].DoorActor.KeyNum==0)) )
        {
            DisableZombieVolume(ZVol);
            return -1;
        }
    }

    // Rate how long its been since this spawn was used
    f = Level.TimeSeconds - ZVol.LastSpawnTime;
    if ( f < MaxUsageTime ) {
        UsageScore = f / MaxUsageTime;
    }
    else {
        UsageScore = 1.0;
    }

    // Rate the Volume on how close it is to the player
    f = 0;
    // Use an actual spawn location instead of arbitrary volume location.
    // The latter can be messed up due to prepivot.
    ZVolLoc = ZVol.SpawnPos[0];
    bBasementDiff = BasementZ != 0 && SpawnCloseTo != none
            && ((ZVolLoc.Z < BasementZ) ^^ (SpawnCloseTo.Location.Z < BasementZ));
    bIgnoreZDist = ZVol.bNoZAxisDistPenalty && !bBasementDiff;
    if ( SpawnCloseTo == none ) {
        // distance to the closest player
        f = ZVol.CanRespawnTime;
        bIgnoreZDist = true;
    }
    else if ( ZVol.bHasInitSpawnPoints ) {  // elevated spawn
        if ( ZVolLoc.Z < SpawnCloseTo.Location.Z + ElevatedSpawnMinZ
            || ZVolLoc.Z > SpawnCloseTo.Location.Z + ElevatedSpawnMaxZ )
        {
            f = ZedSpawnMinDist + ZedSpawnMaxDist;  // sets PlayerDistScore = 0
        }
        bIgnoreZDist = true;
    }
    else if ( bHighGround && !bBasementDiff && ZVolLoc.Z + 50 > SpawnCloseTo.Location.Z ) {
        bIgnoreZDist = true;
    }

    if ( f == 0.0 ) {
        LocationXY = ZVolLoc;
        TestLocationXY = SpawnCloseTo.Location;
        if ( bIgnoreZDist ) {
            LocationXY.Z = 0;
            TestLocationXY.Z = 0;
        }
        f = VSize(TestLocationXY-LocationXY);
    }
    if ( f < ZedSpawnMinDist ) {
        // max score for all spawn volumes within 12 meters
        PlayerDistScore = 1.0;
    }
    else {
        // allow going negative for volumes that are too far away
        PlayerDistScore = 1.0  - ((f - ZedSpawnMinDist) / ZedSpawnMaxDist);
    }
    // This gets zombies spawning more on the same level as the player.
    // If the volume is too far away - Z distance does not matter anymore
    if ( !bIgnoreZDist && FloorPenalty > 0 && PlayerDistScore > 0 ) {
        PlayerDistScore *= 1.0 - FloorPenalty;
        if ( !bBasementDiff ) {
            f = abs(SpawnCloseTo.Location.Z - ZVolLoc.Z);
            if ( f < 50 ) {
                // prevents crouching or jumping players to mess up the rating
                PlayerDistScore += FloorPenalty;
            }
            else if ( f < FloorHeight ) {
                PlayerDistScore += FloorPenalty * (1.0 - f / FloorHeight);
            }
        }
    }

    f = fmax(1.0 - wDesire - wDist - wUsage, 0.0) * frand();
    Rating = ZVol.SpawnDesirability * wDesire
            + ZVol.default.SpawnDesirability * (wDist * PlayerDistScore + wUsage * UsageScore + f);

    if ( Rating <= 0 ) {
        // Far away spawns.
        // Negative rating prevents spawning in the volume.
        // We still want to allow spawning here, but as a last resort
        Rating = fmax(1.0, 20.0 + PlayerDistScore);
    }

    return Rating;
}

// returns every alive player in a row
function Controller FindSquadTarget()
{
    local Controller C, FirstC;
    local int i;

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if( C.bIsPlayer && C.Pawn != none && C.Pawn.Health>0 ) {
            if (i == NextSquadTarget[0]) {
                ++NextSquadTarget[0];
                return C;
            }
            ++i;
            if ( FirstC == none ) {
                FirstC = C;
            }
        }
    }

    NextSquadTarget[0] = 1;  // cuz we've return zeroth
    return FirstC;
}

function bool CanSpawnInVolume(class<KFMonster> M, ZombieVolume ZVol)
{
    local int i;

    switch (M.default.ZombieFlag) {
        case 0:
            if (!ZVol.bNormalZeds)
                return false;
            break;
        case 1:
            if (!ZVol.bRangedZeds)
                return false;
            break;
        case 2:
            if (!ZVol.bLeapingZeds)
                return false;
            break;
        case 3:
            if (!ZVol.bMassiveZeds)
                return false;
        break;
    }

    for ( i = 0; i < ZVol.DisallowedZeds.length; ++i ) {
        if( ClassIsChildOf(M, ZVol.DisallowedZeds[i]) ) {
           return false;
        }
    }
    if ( ZVol.OnlyAllowedZeds.Length > 0 ) {
        for ( i = 0; i < ZVol.OnlyAllowedZeds.length; ++i ) {
            if( ClassIsChildOf(M, ZVol.OnlyAllowedZeds[i]) ) {
                return true;
            }
        }
        return false;
    }
    return true;
}

function ZombieVolume FindSpawningVolumeForSquad(out array< class<KFMonster> > Squad,
        optional bool bIgnoreFailedSpawnTime, optional bool bBossSpawning)
{
    local ZombieVolume BestZ, CurZ;
    local float BestScore,tScore;
    local int i, j, total, CanSpawn;
    local Controller C;
    local float ZVolUsageTime, wDist, wUsage, wDesire, BoringDistMult;
    local byte BoringLocal;

    if ( Squad.Length == 0 )
        return none;
    // First pass, pick a random player.
    C = FindSquadTarget();
    if( C == none )
        return none; // This shouldn't happen. Just to be sure...

    if ( ScrnGameLength != none ) {
        // boost boring stage for this squad if number of loaded zeds is big
        if ( ScrnGameLength.LoadedCount >= 16 )
            BoringLocal = 3;
        else if ( ScrnGameLength.LoadedCount >= 8 )
            BoringLocal = 2;
    }
     // do not lower actual boring stage
    BoringLocal = clamp(BoringLocal, BoringStage, BoringStages.length - 1);

    switch (ZedSpawnLoc) {
        case ZSLOC_CLOSER:
            wDist = 0.50;
            wUsage = 0.30;
            wDesire = 0.10;
            break;

        case ZSLOC_RANDOM:
            wDist = 0.15;
            wUsage = 0.30;
            wDesire = 0.15;
            break;

        case ZSLOC_VANILLA:
            wDist = 0.30;
            wUsage = 0.30;
            wDesire = 0.30;
            break;

        case ZSLOC_AUTO:
        default:
            if (BoringLocal < 2 && NumMonsters > 4 + (4 * BaseDifficulty) && TotalMaxMonsters >= 20) {
                // many zeds already spawned, so spawn them more randomly
                wDist = 0.15 * (1 + BoringLocal);
                wUsage = 0.30;
                wDesire = 0.15;
            }
            else {
                wDist = 0.50;
                wUsage = 0.30;
                wDesire = 0.10;
            }
            break;
    }

    ZVolUsageTime = fmax(1.0, BoringStages[BoringLocal].ZVolUsageTime);
    // The higher boring stage, the closer zeds may spawn to the players
    BoringDistMult = 1.0 - 0.20 * BoringLocal;

    // Second pass, figure out best spawning point.
    // Usually, ZombieVolume can fit 4-8 zeds. If volume can spawn 4 zeds, it is already good enough,
    // so do not lower its rating to favor a huge volume 200m away
    total = min(Squad.Length, 4);

    for( i = 0; i < ZedSpawnList.Length; i++ ) {
        CurZ = ZedSpawnList[i];
        if ( CurZ.bObjectiveModeOnly || !CurZ.bVolumeIsEnabled || Level.TimeSeconds < CurZ.LastCheckTime )
            continue;

        if( !bIgnoreFailedSpawnTime ) {
            if ( Level.TimeSeconds < CurZ.LastFailedSpawnTime )
                continue;
            // avoid spawning boss in hidden spots due to BossGrandEntry()
            if ( bBossSpawning && CurZ.bAllowPlainSightSpawns )
                continue;
        }

        CanSpawn = 0;
        for ( j = 0; j < total; ++j ) {
            if ( CanSpawnInVolume(Squad[j], CurZ) ) {
                ++CanSpawn;
            }
        }
        if ( CanSpawn == 0 )
            continue;

        tScore = RateZombieVolume(CurZ, C.Pawn, ZVolUsageTime, wDist, wUsage, wDesire);
        if ( tScore <= 0 )
            continue;

        if ( CanSpawn < total  ) {
            // lower rating to favor volumes that can spawn more zeds.
            tScore *= CanSpawn / total;
        }
        else if ( CurZ.bAllowPlainSightSpawns && ZedSpawnLoc == ZSLOC_RANDOM && !bBossSpawning ) {
            // prefer hidden volumes during random spawns rather than spawning in the middle of a room
            // 450 equals to doubling SpawnDesirability at the given wDesire: 0.15 * 3000
            tScore += 450.0;
        }
        // We reuse CanRespawnTime to store minimal distance to players
        if ( bBossSpawning && CurZ.CanRespawnTime < BossSpawnRecDist )
            tScore*=0.2;
        // Allow spawning closer than MinDistanceToPlayer only if there are no other options
        if ( !CurZ.bAllowPlainSightSpawns && CurZ.CanRespawnTime < CurZ.MinDistanceToPlayer * BoringDistMult )
            tScore *= 0.2 * CurZ.CanRespawnTime / CurZ.MinDistanceToPlayer;
        // Try to prevent spawning in the same volume back to back. Use at least 3 volumes
        if( CurZ == LastSpawningVolume || CurZ == LastZVol )
            tScore*=0.2;

        if( tScore > BestScore ) {
            BestScore = tScore;
            BestZ = CurZ;
        }
    }
    return BestZ;
}

function ZombieVolume FindSpawningVolume(optional bool bIgnoreFailedSpawnTime, optional bool bBossSpawning)
{
    return FindSpawningVolumeForSquad(NextSpawnSquad, bIgnoreFailedSpawnTime, bBossSpawning);
}

static function string ZedSquadToString(out array< class<KFMonster> > Squad)
{
    local string str;
    local int i;

    if ( Squad.length == 0 )
        return "<empty>";
    str = "(" $ string(Squad[0].name);
    for ( i = 1; i < Squad.length; ++i ) {
        str $= "," $ string(Squad[0].name);
    }
    str $= ")";

    return str;
}

function MaximizeDebugLogging()
{
    LogZedSpawnLevel = LOG_DEBUG;
}

function bool LogZedSpawn(int severity, coerce string str)
{
    if ( severity > LogZedSpawnLevel )
        return false;
    log(str, class.name);
    return true;
}

function bool LogZedSquadSpawn(int severity, coerce string str, out array< class<KFMonster> > Squad)
{
    if ( severity > LogZedSpawnLevel )
        return false;

    if ( Squad.length > 0 ) {
        str @= ZedSquadToString(Squad);
    }
    log(str, class.name);
    return true;
}

function bool AddSquad()
{
    if ( bDisableZedSpawning )
        return false;

    if ( ScrnGameLength == none )
        return super.AddSquad();

    if( LastZVol != none && LastZVol != LastSpawningVolume ) {
        LastSpawningVolume = LastZVol;
    }

    if ( NextSpawnSquad.length==0 ) {
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
        if ( NextSpawnSquad.length == 0 )
            return false;

        if ( ScrnGameLength.bLoadedSpecial )
            MaxSpawnAttempts = MaxSpecialSpawnAttempts;
        else
            MaxSpawnAttempts = default.MaxSpawnAttempts;
    }

    LastZVol = FindSpawningVolume();
    if ( LastZVol == none && ScrnGameLength.bLoadedSpecial ) {
        // do not give up on special squads that easy
        LastZVol = FindSpawningVolume(true);
    }
    if ( LastZVol == None ) {
        LogZedSquadSpawn(LOG_WARN, "Could not find a place for Squad", NextSpawnSquad);
        NextSpawnSquad.length = 0;
        return false;
    }

    if ( SpawnSquad(LastZVol, NextSpawnSquad) > 0 ) {
        if ( bDebugZedSpawn ) {
            DebugDrawZVol(LastZVol);
        }
        if ( ScrnGameLength.bLoadedSpecial )
            MaxSpawnAttempts = MaxSpecialSpawnAttempts;
        else
            MaxSpawnAttempts = default.MaxSpawnAttempts;
        return true;
    }

    if ( --MaxSpawnAttempts <= 0 ) {
        LogZedSquadSpawn(LOG_WARN, "Unable to spawn squad", NextSpawnSquad);
        NextSpawnSquad.length = 0;
    }
    return false;
}

function ToggleDebugZedSpawn()
{
    local int i;

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    bDebugZedSpawn = !bDebugZedSpawn;
    if ( !bDebugZedSpawn ) {
        for ( i = 0; i < ARRAYCOUNT(DebugZVols); ++i ) {
            DebugZVols[i].bHidden = true;
        }
    }
    Level.GetLocalPlayerController().ClientMessage("DebugZedSpawn " $ eval(bDebugZedSpawn, "ENABLED", "DISABLED"));
}

function DebugDrawZVol(ZombieVolume ZVol)
{
    if ( !bDebugZedSpawn )
        return;
    if ( DebugZVols[NextDebugZVolIndex] != none ) {
        DebugZVols[NextDebugZVolIndex].bHidden = true;
    }
    DebugZVols[NextDebugZVolIndex] = ZVol;
    ZVol.BrushColor = DebugZVolColors[NextDebugZVolIndex];
    ZVol.bColored = true;
    ZVol.bHidden = false;
    if ( ++NextDebugZVolIndex >= ARRAYCOUNT(DebugZVols) )
        NextDebugZVolIndex = 0;
}


function BuildNextSquad()
{
    if ( ScrnGameLength != none )
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
    else
        super.BuildNextSquad();
}

function AddSpecialSquad()
{
    // ScrnGameLength decides itself when to spawn special or regular squad
    if ( ScrnGameLength != none )
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
    else
        super.AddSpecialSquad();
}

function AddSpecialPatriarchSquad()
{
    if ( ScrnGameLength != none )
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
    else
        super.AddSpecialPatriarchSquad();
}

function AddBossBuddySquad()
{
    if ( ScrnGameLength == none ) {
        super.AddBossBuddySquad();
        return;
    }

    if ( !bWaveBossInProgress )
        return;

    TotalMaxMonsters += ScaleMonsterCount(ScrnGameLength.Wave.Counter, ScrnGameLength.Wave.MaxCounter);
    ScrnGRI.MaxMonsters = TotalMaxMonsters + NumMonsters; // num monsters in wave replicated to clients
    MaxMonsters = Clamp(TotalMaxMonsters, 1, MaxZombiesOnce);
    NextMonsterTime = Level.TimeSeconds;
    FinalSquadNum++;
}

// returns a value in interval [0.0 - 2.0] based on the current game progress
function float WaveSinMod()
{
    return 2.0 * (1.0 - abs(sin(WaveTimeElapsed  * SineWaveFreq)));
}

function bool SetBoringStage(byte stage)
{
    if ( stage < BoringStages.length ) {
        BoringStage = stage;
        ScrnBalanceMut.GameRules.OnBoringStageSet(BoringStage);
        return true;
    }
    else if ( BoringStages.length == 0 ) {
        warn("Broken boring stages");
        BoringStages.insert(0, 1);
        BoringStages[0].MinSpawnTime = 1.5;
        BoringStages[0].SpawnPeriod = 3.0;
        BoringStages[0].ZVolUsageTime = 20.0;
        BoringStage = 0;
    }
    return false;
}

function bool IncBoringStage()
{
    return SetBoringStage(BoringStage + 1);
}

function byte GetBoringStage()
{
    return BoringStage;
}

function bool BoringStageMaxed()
{
    return BoringStage + 1 >= BoringStages.length;
}

function string GetBoringString(byte index)
{
    if ( index < BoringStrings.length ) {
        return BoringStrings[index];
    }
    // shouldn't happen
    return "ZED spawn rate x" $ (index+1);
}

// reserved for TSC
function bool ShouldKillOnTeamChange(Pawn TeamChanger)
{
    return true;
}

function SelectShop()
{
    local array<ShopVolume> TempShopList;
    local int i;
    local int SelectedShop;
    local bool bFound;

    if ( ShopList.length == 0 )
        return;

    if ( ScrnGameLength != none && !ScrnGameLength.bRandomTrader ) {
        bFound = ScrnGRI.CurrentShop == none;
        SelectedShop = -1;
        for ( i = 0; i < ShopList.length; ++i ) {
            if ( bFound ) {
                if ( !ShopList[i].bAlwaysClosed ) {
                    SelectedShop = i;  // next available
                    break;
                }
            }
            else if ( ShopList[i] == ScrnGRI.CurrentShop ) {
                bFound = true;
            }
            else if ( SelectedShop == -1 && !ShopList[i].bAlwaysClosed ) {
                SelectedShop = i;  // first available
            }
        }
        ScrnGRI.CurrentShop = ShopList[SelectedShop];
    }
    else {
        for ( i = 0; i < ShopList.length; ++i ) {
            if ( ShopList[i].bAlwaysClosed || ShopList[i] == ScrnGRI.CurrentShop )
                continue;

            TempShopList[TempShopList.Length] = ShopList[i];
        }

        if ( TempShopList.length == 0 )
            return;
        ScrnGRI.CurrentShop = TempShopList[rand(TempShopList.length)];
    }
}

function bool IsShopTeleporter(ShopVolume Shop, Teleporter Tel)
{
    local int i;

    if ( Shop == none || Tel == none )
        return false;

    for (i = 0; i < Shop.TelList.length; ++i) {
        if ( Tel == Shop.TelList[i] )
            return true;
    }
    return false;
}

function ShopVolume TeamShop(byte TeamIndex)
{
    return ScrnGRI.CurrentShop;
}

function ShowPathTo(PlayerController CI, int DestinationIndex)
{
    local ShopVolume shop;
    local class<WillowWhisp>    WWclass;
    local byte TeamNum;

    // DestinationIndex is used by TSC to show path to base
    if ( bWaveInProgress && DestinationIndex == 0 )
    {
        ScrnPlayerController(CI).ServerShowPathTo(255); // turn off
        return;
    }

    // take TeamNum from PRI, because KFMod hard-codes it to 0
    TeamNum = CI.PlayerReplicationInfo.Team.TeamIndex;
    shop = TeamShop(TeamNum);
    if( shop == none )
        return;

    if ( !shop.bTelsInit )
        shop.InitTeleports();

    if ( shop.TelList[0] != None && CI.FindPathToward(shop.TelList[0], false) != None ) {
        WWclass = class<WillowWhisp>(DynamicLoadObject(PathWhisps[TeamNum], class'Class'));
        Spawn(WWclass, CI,, CI.Pawn.Location);
    }
}

function GetServerInfo( out ServerResponseLine ServerState )
{
    super.GetServerInfo(ServerState);
    // Removed in v9.60.02
    // if ( ScrnBalanceMut.ColoredServerName != "" ) {
    //     ServerState.ServerName = class'ScrnFunctions'.static.ParseColorTags(ScrnBalanceMut.ColoredServerName);
    // }
}

// entire C&CI from parent classes to clear garbage
function GetServerDetails( out ServerResponseLine ServerState )
{
    local int i;

    Super(GameInfo).GetServerDetails( ServerState );

    if ( ScrnBalanceMut != none && !ScrnBalanceMut.bServerInfoVeterancy ) {
        for ( i=0; i<ServerState.ServerInfo.Length; i++ ) {
            if ( ServerState.ServerInfo[i].Key == "Veterancy" )
                ServerState.ServerInfo.remove(i--, 1);
        }
    }

    // skip UnrealMPGameInfo
    // AddServerDetail( ServerState, "MinPlayers", MinPlayers );
    // AddServerDetail( ServerState, "EndTimeDelay", EndTimeDelay );

    // skip DeathMatch
    // AddServerDetail( ServerState, "GoalScore", GoalScore );
    // AddServerDetail( ServerState, "TimeLimit", TimeLimit );
    // AddServerDetail( ServerState, "Translocator", bAllowTrans );
    // AddServerDetail( ServerState, "WeaponStay", bWeaponStay );
    // AddServerDetail( ServerState, "ForceRespawn", bForceRespawn );

    // Invasion
    if ( InitialWave > 0 )
        AddServerDetail( ServerState, "InitialWave", InitialWave );
    // AddServerDetail( ServerState, "FinalWave", FinalWave );

    //KFGameType
    AddServerDetail( ServerState, "Max runtime zombies", MaxZombiesOnce );
    AddServerDetail( ServerState, "Starting cash", StartingCash );

    // ScrnGameType
    if ( TourneyMode != 0 )
        AddServerDetail( ServerState, "ScrN Tourney Mode", TourneyMode );

    if ( ScrnGameLength != none ) {
        AddServerDetail( ServerState, "ScrN Game", ScrnGameLength.GameTitle );
    }
}

// This is the only place where TourneyMode can be changed by descendants.
protected function PreStartTourney(out int TourneyMode)
{
    if ( ScrnGameLength != none && ScrnGameLength.bForceTourney ) {
        TourneyMode = ScrnGameLength.TourneyFlags;
    }
}

function InventoryUpdate(Pawn P)
{
}

// called at the end of InitGame(), when mutators have been spawned already
protected function StartTourney()
{
    log("Starting TOURNEY MODE " $ TourneyMode, 'ScrnBalance');

    TurboScale = 1.0;
    ScrnBalanceMut.SrvTourneyMode = TourneyMode;
    ScrnBalanceMut.bAltBurnMech = true;
    ScrnBalanceMut.bReplacePickups = true;
    ScrnBalanceMut.bNoRequiredEquipment = false;
    ScrnBalanceMut.bDynamicLevelCap = false;
    ScrnBalanceMut.bAllowBehindView = false;

    ScrnBalanceMut.MaxWaveSize = 500;

    ScrnBalanceMut.bUseExpLevelForSpawnInventory = false;
    ScrnBalanceMut.bSpawn0 = true;
    ScrnBalanceMut.bNoStartCashToss = true;
    ScrnBalanceMut.bMedicRewardFromTeam = true;
    ScrnBalanceMut.StartCashHard = 200;
    ScrnBalanceMut.StartCashSui = 200;
    ScrnBalanceMut.StartCashHoE = 200;
    ScrnBalanceMut.MinRespawnCashHard = 100;
    ScrnBalanceMut.MinRespawnCashSui = 100;
    ScrnBalanceMut.MinRespawnCashHoE = 100;

    ScrnBalanceMut.InitSettings();
    ScrnBalanceMut.SetReplicationData();
}

function final bool IsTourney()
{
    return TourneyMode != 0;
}

function final int GetTourneyMode()
{
    return TourneyMode;
}

function final string GetCmdLine()
{
    return CmdLine;
}

// this must be called after ServerPerksMut.SetupRepLink()
function SetupRepLink(ScrnClientPerkRepLink R)
{
    local int i;
    local class<Pickup> PC;
    local bool bVanilla, bSWP, bHMG;
    local bool bAllow;
    local name PackageName;

    if ( R == none )
        return; // wtf?

    if ( ScrnGameLength != none ) {
        R.Zeds.length = ScrnGameLength.AllZeds.length;
        for ( i = 0; i < ScrnGameLength.AllZeds.length; ++i ) {
            R.Zeds[i] = ScrnGameLength.AllZeds[i];
        }
    }

    if ( TourneyMode == 0 )
        return;

    bVanilla = (TourneyMode & TOURNEY_VANILLA) != 0;
    bSWP = (TourneyMode & TOURNEY_SWP) != 0;
    bHMG = (TourneyMode & TOURNEY_HMG) != 0;

    if ( (TourneyMode & TOURNEY_ALL_WEAPONS) == 0 ) {
        // trader inventory filter for tourney mode
        for ( i= R.ShopInventory.length-1; i >= 0; --i ) {
            PC = R.ShopInventory[i].PC;
            if ( PC == none ) {
                // shouldn't happen
                R.ShopInventory.remove(i, 1);
                continue;
            }

            PackageName = PC.outer.name;
            if ( PackageName == 'ScrnBalanceSrv' ) {
                // ZED guns are prohibited in Tourney.
                // While Horzine Armor is inside the core ScrN package, we consider it a part of SWP
                bAllow = PC != class'ScrnCrossbuzzsawPickup'
                        && PC != class'ScrnM99Pickup'
                        && PC != class'ScrnZEDMKIIPickup'
                        && (bSWP || PC != class'ScrnHorzineVestPickup');
            }
            else if ( PackageName == 'KFMod' ) {
                bAllow = bVanilla && PC != class'ZEDGunPickup' && PC != class'ZEDMKIIPickup';
            }
            else if ( PackageName == 'ScrnWeaponPack' ) {
                bAllow = bSWP && PC.name != 'RPGPickup' && PC.name != 'HRLPickup';
            }
            else {
                bAllow = false;
            }

            if ( !bAllow ) {
                R.ShopInventory.remove(i, 1);
            }
        }
    }

    if ( (TourneyMode & TOURNEY_ALL_PERKS) == 0 ) {
        // perk filter for tourney mode
        for ( i = R.CachePerks.length-1; i >= 0; --i ) {
            PackageName = R.CachePerks[i].PerkClass.outer.name;
            bAllow = PackageName == 'ScrnBalanceSrv' || (bHMG && PackageName == 'ScrnHMG');
            if ( !bAllow )
                R.CachePerks.remove(i, 1);
        }
    }
}

// initialize a bot which is associated with a pawn placed in the level
function InitPlacedBot(Controller C, RosterEntry R)
{
    local UnrealTeamInfo BotTeam;

    log("Init placed bot "$C $ ", pawn = "$C.Pawn);

    BotTeam = FindTeamFor(C);
    if ( Bot(C) != None )
    {
        Bot(C).InitializeSkill(AdjustedDifficulty);
        if ( R != None )
            R.InitBot(Bot(C));
    }

    // no team for Breaker Boxes  -- PooSH
    if ( BotTeam != none && C.PlayerReplicationInfo != none )
        BotTeam.AddToTeam(C);

    if ( R != None )
        ChangeName(C, R.PlayerName, false);
}

// overrided to remove team check for spectators-only
function bool CanSpectate( PlayerController Viewer, bool bOnlySpectator, actor ViewTarget )
{
    if ( (ViewTarget == None) )
        return false;

    if ( Controller(ViewTarget) != None ) {
        if ( Controller(ViewTarget).Pawn == None )
            return false;
        return Controller(ViewTarget).PlayerReplicationInfo != None && ViewTarget != Viewer
                && (bOnlySpectator || Controller(ViewTarget).PlayerReplicationInfo.Team == Viewer.PlayerReplicationInfo.Team);
    }

    return Pawn(ViewTarget) != None && Pawn(ViewTarget).IsPlayerPawn()
        && (bOnlySpectator || Pawn(ViewTarget).PlayerReplicationInfo.Team == Viewer.PlayerReplicationInfo.Team);
}

event PostLogin( PlayerController NewPlayer )
{
    super.PostLogin(NewPlayer);
    GiveStartingCash(NewPlayer);
    if ( ScrnPlayerController(NewPlayer) != none )
        ScrnPlayerController(NewPlayer).PostLogin();
}

function LockTeams()
{
    local Controller C;
    local PlayerController PC;

    if ( ScrnBalanceMut.bTeamsLocked )
        return;

    ScrnBalanceMut.bTeamsLocked = true;
    BroadcastLocalizedMessage(class'ScrnGameMessages', 243);
    // auto-invite all current players
    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        PC = PlayerController(C);
        if ( PC != none && PC.PlayerReplicationInfo != none && !PC.PlayerReplicationInfo.bOnlySpectator )
            InvitePlayer(PC);
    }
}

function UnlockTeams()
{
    if ( ScrnBalanceMut.bTeamsLocked ) {
        ScrnBalanceMut.bTeamsLocked = false;
        BroadcastLocalizedMessage(class'ScrnGameMessages', 242);
    }
}

static function string GetPlayerID(PlayerController PC)
{
    local string ID;

    if ( PC != none && PC.PlayerReplicationInfo != none ) {
        ID = PC.GetPlayerIDHash();
        if ( ID == "" )
            ID = PC.PlayerReplicationInfo.PlayerName;
    }
    return ID;
}

function bool IsInvited(PlayerController PC)
{
    return class'ScrnFunctions'.static.SearchStr(InviteList, GetPlayerID(PC)) != -1;
}

function InvitePlayer(PlayerController PC)
{
    local string ID;

    ID = GetPlayerID(PC);
    if ( ID == "" )
        return;

    if (class'ScrnFunctions'.static.SearchStr(InviteList, GetPlayerID(PC)) == -1) {
        InviteList[InviteList.length] = ID;
    }
}

function UninvitePlayer(PlayerController PC)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(InviteList, GetPlayerID(PC));
    if (i != -1) {
        InviteList.remove(i, 1);
    }
}

function InitNavigationPoints()
{
    local NavigationPoint N;
    local PlayerStart P;
    local bool bLookForPlayerStartEvent;

    bLookForPlayerStartEvent = true;
    for ( N = Level.NavigationPointList; N != none; N = N.NextNavigationPoint ) {
        P = PlayerStart(N);
        if ( P != none ) {
            if ( bLookForPlayerStartEvent && P.Event != '' && P.Event != PlayerStartEvent ) {
                if ( PlayerStartEvent == '' ) {
                    // all player starts having the same event. Most-likely it should be triggered on player each spawn
                    PlayerStartEvent = P.Event;
                }
                else {
                    // different events for player starts - those are linked to particular spawn point no the game itself
                    PlayerStartEvent = '';
                    bLookForPlayerStartEvent = false;
                }
            }
        }
    }
}


function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
    local byte TeamIndex;
    local ShopVolume shop;

    TeamIndex = InTeam;
    if ( Player != None && Player.PlayerReplicationInfo != None )
        TeamIndex = Player.PlayerReplicationInfo.Team.TeamIndex;

    if ( ScrnGameLength != none && ScrnGameLength.Wave.bStartAtTrader ) {
        if ( ScrnGameLength.Wave.bOpenTrader ) {
            shop = TeamShop(TeamIndex);
        }
        else {
            shop = ShopList[rand(ShopList.length)];
        }
        if ( shop != none ) {
            if ( !shop.bTelsInit ) {
                shop.InitTeleports();
            }
            if ( shop.TelList.Length > 0 ) {
                if ( PlayerSpawnTraderTeleportIndex >= shop.TelList.Length )
                    PlayerSpawnTraderTeleportIndex = 0;
                return shop.TelList[PlayerSpawnTraderTeleportIndex++];
            }
        }
    }

    return super.FindPlayerStart(Player, TeamIndex, incomingName);
}

function StartMatch()
{
    local Controller C;
    local PlayerReplicationInfo PRI;

    // make sure that all non-spectators can join the game
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        PRI = C.PlayerReplicationInfo;
        if ( PRI != none && !PRI.bOnlySpectator ) {
            PRI.bOutOfLives = false;
            PRI.NumLives = 0;
        }
    }

    super.StartMatch();
}

function bool PlayerCanRestart(PlayerController PC)
{
    local PlayerReplicationInfo PRI;

    PRI = PC.PlayerReplicationInfo;

    if ( ScrnBalanceMut.bTeamsLocked && !IsInvited(PC) ) {
        PC.ReceiveLocalizedMessage(class'ScrnGameMessages', 243);
        if ( !PRI.bOnlySpectator ) {
            PC.BecomeSpectator();
        }
        if ( !PRI.bOnlySpectator ) {
            // Max spectator count reached. Leave player in the team but rejecft respawning
            PRI.bOutOfLives = true;
            PRI.NumLives = 1;
            PC.GoToState('Spectating');
        }
        return false;
    }

    if ( bWaveInProgress )
        return false;

    if ( PC.Pawn != none && PC.Pawn.Health > 0 )
        return false;  // wtf? Already alive.

    if ( ScrnGameLength != none && !ScrnGameLength.Wave.bRespawnDeadPlayers )
        return false;

    // NumLives actually is NumDeaths this wave
    return !PRI.bOutOfLives && PRI.NumLives == 0;
}

function RestartPlayer( Controller aPlayer )
{
    local PlayerController PC;

    PC = PlayerController(aPlayer);
    if ( PC == none ) {
        // bots
        if ( aPlayer.PlayerReplicationInfo.bOutOfLives || aPlayer.PlayerReplicationInfo.NumLives > 0
                || aPlayer.Pawn != None )
            return;
    }
    else if ( !PlayerCanRestart(PC) ) {
        PC.PlayerReplicationInfo.bOutOfLives = true;
        PC.PlayerReplicationInfo.NumLives = 1;
        PC.GoToState('Spectating');
        return;
    }

    super(Invasion).RestartPlayer(aPlayer);

    if ( aPlayer.Pawn != none ) {
        if ( KFHumanPawn(aPlayer.Pawn) != none ) {
            KFHumanPawn(aPlayer.Pawn).VeterancyChanged();
        }

        if ( bTradingDoorsOpen && aPlayer.bIsPlayer ) {
            aPlayer.Pawn.bBlockActors = !bAntiBlocker;
        }

        if ( PlayerStartEvent != '' && aPlayer.Pawn.Anchor.Event != PlayerStartEvent ) {
            // triggers PlayerStart.Event despite is is spawn elsewhere, e.g. at trader
            TriggerEvent(PlayerStartEvent, aPlayer.Pawn.Anchor, aPlayer.Pawn);
        }

        if ( bSuicideTimer ) {
            class'ScrnSuicideBomb'.static.MakeSuicideBomber(aPlayer.Pawn);
        }

        if ( PC != none ) {
            if ( FriendlyFireScale > 0 )
                ScrnBalanceMut.SendFriendlyFireWarning(PC);
        }
        bRestartPlayersTriggered = false;
        InventoryUpdate(aPlayer.Pawn);
    }
}

function bool AllowBecomeActivePlayer(PlayerController CI)
{
    if( CI.PlayerReplicationInfo==None || !CI.PlayerReplicationInfo.bOnlySpectator )
        Return False; // Already is an active player

    if ( ScrnBalanceMut.bTeamsLocked && !IsInvited(CI) ) {
        CI.ReceiveLocalizedMessage(class'ScrnGameMessages', 243);
        return false;
    }

    if ( /*!GameReplicationInfo.bMatchHasBegun ||*/ NumPlayers >= MaxPlayers
        || CI.IsInState('GameEnded') || CI.IsInState('RoundEnded') )
    {
        CI.ReceiveLocalizedMessage(GameMessageClass, 13);

        // debug info
        // if ( !GameReplicationInfo.bMatchHasBegun )
            // CI.ClientMessage("Reason: Match has not begun yet");
        // else
        if ( NumPlayers >= MaxPlayers )
            CI.ClientMessage("Reason: MaxPlayers reached ("$MaxPlayers$")");
        else if ( CI.IsInState('GameEnded') )
            CI.ClientMessage("Reason: You are in GameEnded state");
        else if ( CI.IsInState('RoundEnded') )
            CI.ClientMessage("Reason: You are in RoundEnded state");

        return false;
    }

    if ( (Level.NetMode==NM_Standalone) && (NumBots>InitialBots) )
    {
        RemainingBots--;
        bPlayerBecameActive = true;
    }
    GiveStartingCash(CI);
    return true;
}

function AddSuicideTime(int dt, bool bReset)
{
    local bool bHadTimer;
    local Controller C;

    bHadTimer = bSuicideTimer;
    if ( bReset ) {
        RemainingTime = dt;
    }
    else {
        RemainingTime += dt;
    }
    bSuicideTimer = RemainingTime > 0;
    ScrnGRI.RemainingMinute = RemainingTime;
    ScrnGRI.bStopCountDown = !bSuicideTimer;
    if ( bSuicideTimer && Level.NetMode != NM_DedicatedServer ) {
        ScrnGRI.ShowTimeMsg(true);
    }

    if ( bHadTimer == bSuicideTimer )
        return;  // ho changes in state

    if ( bHadTimer ) {
        class'ScrnSuicideBomb'.static.DisintegrateAll(Level);
    }
    else {
        for( C = Level.ControllerList; C!=None; C = C.NextController ) {
            if ( C.PlayerReplicationInfo != none && C.Pawn != none && C.Pawn.Health > 0 ) {
                class'ScrnSuicideBomb'.static.MakeSuicideBomber(C.Pawn);
            }
        }
    }
}

function SuicideTimer()
{
    if ( RemainingTime > 0 ) {
        RemainingTime--;
        ScrnGRI.RemainingTime = RemainingTime;
    }

    if ( RemainingTime == 0 ) {
        class'ScrnSuicideBomb'.static.ExplodeAll(Level);
        return;
    }

    if ( RemainingTime < 60 ) {
        // sync every second during the last minute
        ScrnGRI.RemainingMinute = RemainingTime;
        if ( Level.Netmode != NM_DedicatedServer ) {
            ScrnGRI.ShowTimeMsg();
        }
        return;
    }

    switch ( class'ScrnF'.static.mod(RemainingTime, 60) ) {
        case 0:
            if ( Level.Netmode != NM_DedicatedServer ) {
                ScrnGRI.ShowTimeMsg();
            }
            break;
        case 1:
            // Once per minute, sync clocks between the server and clients.
            // Do it 1s ahead because client's ScrnGRI.Timer() decrements it on receive.
            ScrnGRI.RemainingMinute = RemainingTime;
            break;
    }
}

function GiveStartingCash(PlayerController PC)
{
    local int cash;

    if (ScrnGameLength != none) {
        cash = ScrnGameLength.CalcStartingCash(PC);
    }
    else {
        cash = StartingCash;
    }

    PC.PlayerReplicationInfo.Score = max(0, cash);
    if ( ScrnPlayerController(PC) != none )
        ScrnPlayerController(PC).StartCash = PC.PlayerReplicationInfo.Score;
}

function bool AllowGameEnd(PlayerReplicationInfo Winner, string Reason)
{
    if ( AlivePlayerCount <= 0 ) {
        if ( IsTestMap() && !bRestartPlayersTriggered ) {
            // allow the test map to respawn dead players. If it doesn't - end game in a second.
            bRestartPlayersTriggered = true;
            TriggerEvent('RestartPlayers', none, none);
            return false;
        }
        ScrnGRI.EndGameType = 1;
        ScrnGRI.Winner = none;
    }
    else if ( WaveNum >= EndWaveNum() ) {
        ScrnGRI.EndGameType = 2;
        if ( AliveTeamPlayerCount[0] > 0 && AliveTeamPlayerCount[1] <= 0 ) {
            ScrnGRI.Winner = Teams[0];
        }
        else if ( AliveTeamPlayerCount[0] <= 0 && AliveTeamPlayerCount[1] > 0 ) {
            ScrnGRI.Winner = Teams[1];
        }
        else {
            ScrnGRI.Winner = none;
        }
    }
    else  {
        return false;
    }
    return true;
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local Controller C, N;
    local PlayerController PC;
    local KFPlayerController KFPC;
    local PlayerReplicationInfo PRI;
    local KFSteamStatsAndAchievements KFAch;

    UpdateMonsterCount();

    if ( !AllowGameEnd(Winner, Reason)
            || (GameRulesModifiers != none && !GameRulesModifiers.CheckEndGame(Winner, Reason)) )
    {
        ScrnGRI.EndGameType = 0;
        ScrnGRI.Winner = none;
        return false;
    }

    // if we reached here, the game must be ended
    EndTime = Level.TimeSeconds + EndTimeDelay;

    if ( ScrnGRI.EndGameType == 2 ) {
        // squad survived - don't let remaining zeds to eat players at end-game screen
        KillZeds();
    }

    for ( C = Level.ControllerList; C != none; C = N ) {
        N = C.nextController;  // save it in case C gets destroyed
        PC = PlayerController(C);
        if ( PC != none ) {
            KFPC = KFPlayerController(PC);
            PRI = PC.PlayerReplicationInfo;
            KFAch = KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements);

            PC.ClientSetBehindView(true);
            PC.ClientGameEnded();

            if ( BaseDifficulty >= DIFF_NORMAL && KFAch != none && PRI != none
                    && (PRI.Team == ScrnGRI.Winner || ScrnGRI.Winner == none) )
            {
                KFAch.WonGame(ScrnBalanceMut.MapName, GameDifficulty, FinalWave >= 10);
            }

            if ( KFPC != none && EngGameSong != "" ) {
                KFPC.NetPlayMusic(EngGameSong, 0.5, 0);
            }
        }
        C.GameHasEnded();
    }

    if ( CurrentGameProfile != none )  {
        // do not set focus on individial player
        CurrentGameProfile.bWonMatch = false;
    }
    return true;
}

// C&CI from Deathmatch strip color tags before name length check
function ChangeName(Controller Other, string S, bool bNameChange)
{
    local Controller APlayer,C, CI;

    if ( S == "" )
        return;

    S = StripColor(s);    // Stip out color codes

    if (Other.PlayerReplicationInfo.playername~=S)
        return;

    if ( len(class'ScrnFunctions'.static.StripColorTags(S)) > 20 )
        S = Left(class'ScrnFunctions'.static.StripColorTags(S), 20 );
    S = Repl(S, " ", "_", true);
    S = Repl(S, "|", "I", true);

    if ( bEpicNames && (Bot(Other) != None) )
    {
        if ( TotalEpic < 21 )
        {
            S = EpicNames[EpicOffset % 21];
            EpicOffset++;
            TotalEpic++;
        }
        else
        {
            S = NamePrefixes[NameNumber%10]$"CliffyB"$NameSuffixes[NameNumber%10];
            NameNumber++;
        }
    }

    for( APlayer=Level.ControllerList; APlayer!=None; APlayer=APlayer.nextController )
        if ( APlayer.bIsPlayer && (APlayer.PlayerReplicationInfo.playername~=S) )
        {
            if ( Other.IsA('PlayerController') )
            {
                PlayerController(Other).ReceiveLocalizedMessage( GameMessageClass, 8 );
                return;
            }
            else
            {
                if ( Other.PlayerReplicationInfo.bIsFemale )
                {
                    S = FemaleBackupNames[FemaleBackupNameOffset%32];
                    FemaleBackupNameOffset++;
                }
                else
                {
                    S = MaleBackupNames[MaleBackupNameOffset%32];
                    MaleBackupNameOffset++;
                }
                for( CI=Level.ControllerList; CI!=None; CI=CI.nextController )
                    if ( CI.bIsPlayer && (CI.PlayerReplicationInfo.playername~=S) )
                    {
                        S = NamePrefixes[NameNumber%10]$S$NameSuffixes[NameNumber%10];
                        NameNumber++;
                        break;
                    }
                break;
            }
            S = NamePrefixes[NameNumber%10]$S$NameSuffixes[NameNumber%10];
            NameNumber++;
            break;
        }

    if( bNameChange )
        GameEvent("NameChange",s,Other.PlayerReplicationInfo);

    if ( S ~= "CliffyB" )
        bEpicNames = true;
    Other.PlayerReplicationInfo.SetPlayerName(S);
    // notify local players
    if  ( bNameChange )
        for ( C=Level.ControllerList; C!=None; C=C.NextController )
            if ( (PlayerController(C) != None) && (Viewport(PlayerController(C).Player) != None) )
                PlayerController(C).ReceiveLocalizedMessage( class'GameMessage', 2, Other.PlayerReplicationInfo );
}

// returns wave number relative to the current game length
function byte RelativeWaveNum(float LongGameWaveNum)
{
    if ( FinalWave == 10 )
        return ceil(LongGameWaveNum);
    return ceil(LongGameWaveNum * FinalWave / 10.0);
}

// returns the wave number at which the game is considered ended (players win)
function int EndWaveNum()
{
    return FinalWave + int(bUseEndGameBoss);
}

function int ScaleMonsterCount(int SoloNormalCounter, optional int MaxCounter)
{
    local int UsedNumPlayers;
    local float DifficultyMod, NumPlayersMod;

    if ( MaxCounter == 0 ) {
        MaxCounter = ScrnBalanceMut.MaxWaveSize;
    }

    // scale number of zombies by difficulty
    if ( BaseDifficulty >= DIFF_HOE )
        DifficultyMod=1.7;
    else if ( BaseDifficulty >= DIFF_SUICIDAL )
        DifficultyMod=1.5;
    else if ( BaseDifficulty >= DIFF_HARD )
        DifficultyMod=1.3;
    else
        DifficultyMod=1.0;

    UsedNumPlayers = max( max(ScrnGRI.FakedPlayers,1), WavePlayerCount );
    // Scale the number of zombies by the number of players. Don't want to
    // do this exactly linear, or it just gets to be too many zombies and too
    // long of waves at higher levels - Ramm
    // Yeah, yeah, then why did you increased that number for 7+ player game, huh? - PooSH
    switch ( UsedNumPlayers )
    {
        case 1:
            NumPlayersMod=1;
            break;
        case 2:
            NumPlayersMod=2;
            break;
        case 3:
            NumPlayersMod=2.75;
            break;
        case 4:
            NumPlayersMod=3.5;
            break;
        case 5:
            NumPlayersMod=4;
            break;
        case 6:
            NumPlayersMod=4.5;
            break;
        default:
            NumPlayersMod = 4.5 + (UsedNumPlayers-6)*0.4; // 7+ player game
    }
    return Clamp(SoloNormalCounter * DifficultyMod * NumPlayersMod, 1, MaxCounter);
}

function SetupWave()
{
    local byte WaveIndex;
    local bool bOneMessage;
    local Controller C;
    local InvasionBot B;

    UpdateMonsterCount();

    bWaveInProgress = true;
    ScrnGRI.bWaveInProgress = true;

    // auto lock teams
    if ( (WaveNum+1) == RelativeWaveNum(ScrnBalanceMut.LockTeamAutoWave) )
        LockTeams();

    NextMonsterTime = Level.TimeSeconds + 2.0 + 2.0 * frand();
    TraderProblemLevel = 0;
    rewardFlag=false;
    ZombiesKilled=0;
    WaveMonsters = 0;
    WaveNumClasses = 0;
    WavePlayerCount = AlivePlayerCount;
    ZedSpawnLoc = ZSLOC_AUTO;
    NextSquadTarget[0] = rand(AliveTeamPlayerCount[0]);
    NextSquadTarget[1] = rand(AliveTeamPlayerCount[1]);
    // reset spawn volumes
    LastZVol = none;
    LastSpawningVolume = none;

    SetupPickups();

    if (ScrnGameLength != none ) {
        ScrnGameLength.RunWave();
    }

    CalcDoshDifficultyMult();

    if( WaveNum == FinalWave && bUseEndGameBoss ) {
        StartWaveBoss();
        return;
    }

    if ( ScrnGameLength != none ) {
        TotalMaxMonsters = ScrnGameLength.GetWaveZedCount();
        WaveEndTime = ScrnGameLength.GetWaveEndTime();
        AdjustedDifficulty = GameDifficulty + lerp(float(WaveNum)/FinalWave, 0.1, 0.3);
    }
    else {
        WaveIndex = min(WaveNum,15);
        TotalMaxMonsters = Waves[WaveIndex].WaveMaxMonsters;
        WaveEndTime = Level.TimeSeconds + Waves[WaveIndex].WaveDuration;
        AdjustedDifficulty = GameDifficulty + Waves[WaveIndex].WaveDifficulty;
        TotalMaxMonsters = max(8, ScaleMonsterCount(TotalMaxMonsters));  // num monsters in wave
    }

    MaxMonsters = min(TotalMaxMonsters + NumMonsters, MaxZombiesOnce); // max monsters that can be spawned
    ScrnGRI.MaxMonsters = TotalMaxMonsters + NumMonsters; // num monsters in wave replicated to clients
    ScrnGRI.MaxMonstersOn = true; // I've no idea what is this for
    ScrnGRI.NetUpdateTime = Level.TimeSeconds - 1;

    //Now build the first squad to use
    SquadsToUse.Length = 0; // force BuildNextSquad() to rebuild squad list
    SpecialListCounter = 0;
    BuildNextSquad();

    // moved here from TraderTimer
    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        B = InvasionBot(C);
        if ( B != none ) {
            B.bDamagedMessage = false;
            B.bInitLifeMessage = false;

            if ( !bOneMessage && (FRand() < 0.65) ) {
                bOneMessage = true;
                if ( B.Squad.SquadLeader != None && B.Squad.CloseToLeader(C.Pawn) ) {
                    B.SendMessage(B.Squad.SquadLeader.PlayerReplicationInfo, 'OTHER', B.GetMessageIndex('INPOSITION'), 20, 'TEAM');
                    B.bInitLifeMessage = false;
                }
            }
        }
        else if ( PlayerController(C) != none ) {
            PlayerController(C).LastPlaySpeech = 0;
            if ( KFPlayerController(C) != none )
                KFPlayerController(C).bHasHeardTraderWelcomeMessage = false;
        }
    }
}

function bool UpdateMonsterCount()
{
    local Controller C;
    local PlayerReplicationInfo PRI;

    AliveTeamPlayerCount[0] = 0;
    AliveTeamPlayerCount[1] = 0;
    NumMonsters = 0;

    for ( C = Level.ControllerList; C != none;  C = C.NextController ) {
        if( C.Pawn == none || C.Pawn.Health <= 0 )
            continue;

        if ( C.bIsPlayer ) {
            PRI = C.PlayerReplicationInfo;
            if ( PRI != none && !PRI.bOnlySpectator && !PRI.bIsSpectator
                    && PRI.Team != none && PRI.Team.TeamIndex <= 1)
            {
                AliveTeamPlayerCount[PRI.Team.TeamIndex]++;
            }
        }
        else if ( Monster(C.Pawn) != none ) {
            NumMonsters++;
        }
    }
    AlivePlayerCount = AliveTeamPlayerCount[0] + AliveTeamPlayerCount[1];
    return AlivePlayerCount > 0;
}

function bool BootShopPlayers()
{
    local int i;
    local bool result;

    for( i=0; i < ShopList.Length; ++i ) {
        if( ShopList[i].BootPlayers() )
            result = true;
    }
    return result;
}

function SetupPickups()
{
    local int i, j;

    // let mutator do the job
    ScrnBalanceMut.SetupPickups(false, ScrnGameLength != none && ScrnGameLength.ShouldBoostAmmo());

    for ( i = 0; i < AmmoPickups.length; ++i ) {
        if ( AmmoPickups[i].bSleeping )
            SleepingAmmo[j++] = AmmoPickups[i];
    }
    SleepingAmmo.length = j;
}

function InitMapWaveCfg()
{
    local KFRandomSpawn RS;

    // do not call NotifyNewWave() on ZombieVolumes as it is bugged

    foreach DynamicActors(Class'KFRandomSpawn',RS) {
        RS.NotifyNewWave(WaveNum, FinalWave-1);
    }
}

function DestroyDroppedPickups()
{
    local Pickup Pickup;

    foreach DynamicActors(class'Pickup', Pickup) {
        if ( Pickup.bDropped ) {
            Pickup.LifeSpan = 3.0;
        }
    }
}

function AmmoPickedUp(KFAmmoPickup PickedUp)
{
    local int i;
    local KFAmmoPickup AmmoBox;

    ScrnBalanceMut.GameRules.WaveAmmoPickups++;

    // CurrentAmmoBoxCount is set in ScrnAmmoPickup
    // DesiredAmmoBoxCount is set in ScrnBalance
    // At this moment, PickedUp is already in the Sleeping state, and CurrentAmmoBoxCount does not include it
    if ( CurrentAmmoBoxCount >= DesiredAmmoBoxCount )
        return;  // already enough ammo on the map

    while ( SleepingAmmo.length > 0 ) {
        i = rand(SleepingAmmo.Length);
        AmmoBox = SleepingAmmo[i];
        SleepingAmmo.remove(i, 1);

        if ( !AmmoBox.bSleeping ) {
            AmmoBox.GotoState('Sleeping', 'DelayedSpawn');
            return;
        }
    }

    if ( SleepingAmmo.length == 0 ) {
        for ( i = 0; i < AmmoPickups.length; ++i ) {
            AmmoBox = AmmoPickups[i];
            if ( AmmoBox != PickedUp && AmmoBox.bSleeping )
                SleepingAmmo[SleepingAmmo.length] = AmmoBox;
        }

        if ( SleepingAmmo.length > 0 ) {
            i = rand(SleepingAmmo.Length);
            SleepingAmmo[i].GotoState('Sleeping', 'DelayedSpawn');
            SleepingAmmo.remove(i, 1);
            return;
        }
    }

    // nothing else to respawn - respawn the same pickup again
    PickedUp.GotoState('Sleeping', 'DelayedSpawn');
}

function StartWaveBoss()
{
    // reset spawn volumes
    ZedSpawnLoc = ZSLOC_RANDOM;
    LastZVol = none;
    LastSpawningVolume = none;
    FinalSquadNum = 0;
    NextMonsterTime = Level.TimeSeconds;
    bBossSpawned = false;

    if ( ScrnGameLength == none ) {
        WaveEndTime = Level.TimeSeconds + 60;
        if( KFGameLength != GL_Custom ) {
            NextSpawnSquad[0] = Class<KFMonster>(DynamicLoadObject(MonsterCollection.default.EndGameBossClass,Class'Class'));
            NextspawnSquad[0].static.PreCacheAssets(Level);
        }
        else {
            NextSpawnSquad[0] = Class<KFMonster>(DynamicLoadObject(EndGameBossClass,Class'Class'));
            NextspawnSquad[0].static.PreCacheAssets(Level);
        }
    }
    else {
        WaveEndTime = ScrnGameLength.GetWaveEndTime();
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
        log("Boss Squad: " $ ZedSquadToString(NextSpawnSquad), class.name);
    }

    if ( NextSpawnSquad.length == 0 ) {
        Broadcast(Self,"Game ended due to lack of bosses");
        DoWaveEnd();
        return;
    }

    ScrnGRI.MaxMonsters = NextSpawnSquad.length;
    TotalMaxMonsters = NextSpawnSquad.length;
    MaxMonsters = NextSpawnSquad.length;
    bWaveBossInProgress = True;
    bHasSetViewYet = False;
}

// removed setting NextSpawnSquad, because it already has been set in StartWaveBoss()
function bool AddBoss()
{
    if ( NextSpawnSquad.length == 0 ) {
        NextMonsterTime = Level.TimeSeconds + 99999; // never
        return false;
    }

    if( LastZVol != none && LastZVol != LastSpawningVolume ) {
        LastSpawningVolume = LastZVol;
    }

    LastZVol = FindSpawningVolume(false, true);
    if( LastZVol == none ) {
        LastZVol = FindSpawningVolume(true, true);
        if( LastZVol == none ) {
            LogZedSquadSpawn(LOG_ERROR, "Could not find a place for the Boss", NextSpawnSquad);
            return false;
        }
    }

    if( SpawnSquadLog(LastZVol, NextSpawnSquad) == 0 ) {
        LogZedSquadSpawn(LOG_ERROR, "Failed to spawn the Boss:", NextSpawnSquad);
        return false;
    }

    WaveEndTime += 120;
    if ( NextSpawnSquad.length == 0 ) {
        bBossSpawned = true;
        NextMonsterTime = Level.TimeSeconds + 99999; // never (wait for AddBossBuddySquad())
        WaveEndTime += 3600;
    }
    else {
        NextMonsterTime =  Level.TimeSeconds + 0.2;
    }
    return true;
}

function int SpawnSquadLog(ZombieVolume ZVol, out array< class<KFMonster> > Squad)
{
    local int NumSpawned;
    local byte OriginalLogZedSpawnLevel;

    OriginalLogZedSpawnLevel = LogZedSpawnLevel;
    LogZedSpawnLevel = LOG_DEBUG;
    NumSpawned = SpawnSquad(ZVol, Squad);
    LogZedSpawnLevel = OriginalLogZedSpawnLevel;
    return NumSpawned;
}

// Override of ZombieVolume.SpawnInHere() fixing a lot of Tripwire's crap.
// Checks (zombies flags etc.) removed because they already have been made in FindSpawningVolume().
function int SpawnSquad(ZombieVolume ZVol, out array< class<KFMonster> > Squad)
{
    local int i, j, t, numspawned;
    local KFMonster M;
    local string s;

    if ( Squad.Length == 0 )
        return 0;

    if ( ZVol == none ) {
        LogZedSpawn(LOG_ERROR, "Unable to spawn squad: ZVol is not set");
        return 0;
    }

    for ( i = 0; i < Squad.Length && NumMonsters < MaxMonsters && TotalMaxMonsters > 0; ++i ) {
        if ( !CanSpawnInVolume(Squad[i], ZVol) )
            continue;
        for ( M = none; j < ZVol.SpawnPos.length; ++j ) {
            if ( !ZVol.bAllowPlainSightSpawns && PlayerCanSeeSpawnPoint(ZVol.SpawnPos[j], Squad[i], t) ) {
                if ( LogZedSpawnLevel >= LOG_DEBUG ) {
                    LogZedSpawn(LOG_DEBUG, "Player " $ Telemetry[i].Pawn.GetHumanReadableName()
                            $ " @ " $ Telemetry[i].Pawn.Location $ " can see " $ ZVol.name $ ".SpawnPos["$j$"] @ "
                            $ ZVol.SpawnPos[j]);
                }
                DisableZombieVolume(ZVol);
                continue;  // invalidate for later but keep using it now for this squad
            }

            M = Spawn(Squad[i],, ZVol.ZombieSpawnTag, ZVol.SpawnPos[j], ZVol.DesiredRotation);
            if ( M == none )
                continue;
            OverrideMonsterHealth(M);
            ScrnBalanceMut.GameRules.ReinitMonster(M, ZVol);

            M.Event = ZVol.ZombieDeathEvent;
            if ( ZVol.ZombieSpawnEvent != '' )
                TriggerEvent(ZVol.ZombieSpawnEvent, ZVol, M);
            ZVol.AddZEDToSpawnList(M);

            --TotalMaxMonsters;
            ++NumMonsters;
            ++WaveMonsters;
            ++numspawned;
            Squad.remove(i--, 1);

            if ( LogZedSpawnLevel >= LOG_DETAIL )
                s @= string(M.class.name);

            break;
        }
    }

    if( numspawned > 0 ) {
        if ( s != "" ) {
            LogZedSpawn(LOG_DETAIL, ScrnBalanceMut.GameTimeStr() @ ZVol.name $ " zed spawn:" $ s);
        }
        ZedLastSpawnTime = Level.TimeSeconds;
        ZVol.LastSpawnTime = Level.TimeSeconds;
        ZVol.LastFailedSpawnTime = 0;
    }
    else {
        LogZedSpawn(LOG_INFO, ScrnBalanceMut.GameTimeStr() @ ZVol.name $ " zed spawn failed ("$Squad.Length$"z)");
        ZVol.LastFailedSpawnTime = Level.TimeSeconds + 2.0;
    }

    if ( Squad.Length > 0 ) {
        LogZedSquadSpawn(LOG_DEBUG, "Remaining:", Squad);
    }

    return numspawned;
}

function float GetPlayerCountForMonsterHealth()
{
    return max(max(AliveTeamPlayerCount[0], AliveTeamPlayerCount[1]), ScrnGRI.FakedAlivePlayers);
}

function OverrideMonsterHealth(KFMonster M)
{
    local float UsedNumPlayers;
    local ZombieBoss Boss;

    Boss = ZombieBoss(M);

    if ( ScrnGameLength != none && ScrnGameLength.PlayerCountOverrideForHealth > 0.9999 ) {
        UsedNumPlayers = ScrnGameLength.PlayerCountOverrideForHealth;
    }
    else {
        UsedNumPlayers = GetPlayerCountForMonsterHealth();
    }

    if ( M.PlayerCountHealthScale > 0 ) {
        M.HealthMax = M.default.HealthMax * M.DifficultyHealthModifer()
            * (1.0 + (UsedNumPlayers-1.0) * M.PlayerCountHealthScale );
        M.Health = M.HealthMax;
    }
    if ( M.IsA('DoomMonster') ) {
        M.HeadHealth = M.Health;
    }
    else if ( M.PlayerNumHeadHealthScale > 0 ) {
        M.HeadHealth = M.default.HeadHealth * M.DifficultyHealthModifer()
            * (1.0 + (UsedNumPlayers-1.0) * M.PlayerNumHeadHealthScale );
    }

    if ( ScrnGameLength != none ) {
        if ( ScrnGameLength.bLoadedSpecial && !(ScrnGameLength.Wave.SpecialSquadHealthMod ~= 1.0) ) {
            M.HealthMax *= ScrnGameLength.Wave.SpecialSquadHealthMod;
            M.Health = M.HealthMax;
            M.HeadHealth *= ScrnGameLength.Wave.SpecialSquadHealthMod;
        }
    }

    if ( Boss != none ) {
        Boss.HealingLevels[0] = Boss.Health * 0.80;
        Boss.HealingLevels[1] = Boss.Health * 0.50;
        Boss.HealingLevels[2] = Boss.Health * 0.31;
        Boss.HealingAmount = Boss.Health * 0.25;
    }
}

function bool PlayerCanSeeSpawnPoint(vector SpawnLoc, class <KFMonster> TestMonster, optional out int t)
{
    local int i;
    local vector Right, Test, PlayerLoc;
    local float ColRadius;
    local Pawn P;

    ColRadius = TestMonster.Default.CollisionRadius * 1.1;
    if (!bVanillaVisibilityCheck) {
        // use the radius of ExtendedZCollision
        ColRadius = fmax(ColRadius, TestMonster.Default.ColRadius);
    }

    // Now make sure no player sees the spawn point.
    for ( i = 0; i < Telemetry.length; ++i ) {
        P = Telemetry[i].Pawn;
        PlayerLoc = P.Location + P.EyePosition();
        if ( VSizeSquared(SpawnLoc - PlayerLoc) > Telemetry[i].VisibleDistSq )
            continue;

        Right = (SpawnLoc - PlayerLoc) cross vect(0.f,0.f,1.f);
        Right = Normal(Right) * ColRadius;
        Test = SpawnLoc;
        Test.Z += TestMonster.Default.CollisionHeight * 1.25;

        // Do three traces, one to the location, and one slightly above left and right of the collision
        // cylinder size so we don't see this zed spawn
        if( FastTrace(SpawnLoc, PlayerLoc)
            || FastTrace(Test + Right, PlayerLoc)
            || FastTrace(Test - Right, PlayerLoc) )
        {
            t = i;
            return true;
        }
    }
    return false;
}

function AdjustBotCount()
{
    if ( NeedPlayers() && AddBot() && RemainingBots > 0 )
        RemainingBots--;

    if (!bNoBots && !bBotsAdded) {
        if(ScrnGRI != none)

        if((NumPlayers + NumBots) < MaxPlayers && ScrnGRI.PendingBots > 0 )
        {
            AddBots(1);
            ScrnGRI.PendingBots --;
        }

        if (ScrnGRI.PendingBots == 0)
        {
            bBotsAdded = true;
            return;
        }
    }

}

function BossGrandEntry()
{
    local Controller C;
    local PlayerController PC;
    local KFMonster M;

    Bosses.length = 0;
    for ( C = Level.ControllerList; C != None; C = C.NextController ) {
        M = KFMonster(C.Pawn);
        if ( M != none && m.Health > 0 && M.MakeGrandEntry() ) {
            Bosses[Bosses.length] = M;
            ScrnBalanceMut.GameRules.InitBoss(M);
        }
    }
    if ( Bosses.length > 0 )
        ViewingBoss = Bosses[0];

    if( ViewingBoss != none ) {
        ViewingBoss.bAlwaysRelevant = True;
        for ( C = Level.ControllerList; C != None; C = C.NextController ) {
            PC = PlayerController(C);
            if( PC == none )
                continue;
            PC.SetViewTarget(ViewingBoss);
            PC.ClientSetViewTarget(ViewingBoss);
            PC.bBehindView = True;
            PC.ClientSetBehindView(True);
            PC.ClientSetMusic(BossBattleSong,MTRAN_FastFade);
            if ( PC.PlayerReplicationInfo!=None && bRespawnOnBoss ) {
                PC.PlayerReplicationInfo.bOutOfLives = false;
                PC.PlayerReplicationInfo.NumLives = 0;
                if ( PC.Pawn == None && !C.PlayerReplicationInfo.bOnlySpectator )
                    PC.GotoState('PlayerWaiting');
            }
            ScrnBalanceMut.MessageEndGameBonus(PC);
        }
    }
}

function BossGrandExit()
{
    local Controller C;
    local PlayerController PC;

    for ( C = Level.ControllerList; C != None; C = C.NextController ) {
        PC = PlayerController(C);
        if( PC == none )
            continue;

        if( PC.Pawn==None && !PC.PlayerReplicationInfo.bOnlySpectator && bRespawnOnBoss )
            PC.ServerReStartPlayer();

        if( PC.Pawn!=None ) {
            PC.SetViewTarget(C.Pawn);
            PC.ClientSetViewTarget(C.Pawn);
        }
        else {
            PC.SetViewTarget(C);
            PC.ClientSetViewTarget(C);
        }
        PC.bBehindView = False;
        PC.ClientSetBehindView(False);
    }
}

// global funciton definitions to prevent crashes during function calls at state transitions
function BattleTimer() {}
function WaveTimer() {}
function BossWaveTimer() {}
function TraderTimer() {}
function float CalcNextSquadSpawnTime() { return 5.0; }
function DoWaveEnd() {}

// ==================================== STATES ===============================
auto State PendingMatch
{
    function RestartPlayer( Controller aPlayer )
    {
        if ( CountDown <= 0 )
            Super(Invasion).RestartPlayer(aPlayer);
    }

    // overrided to require at least 1 player to be ready to start LobbyTimeout
    function Timer()
    {
        local Controller CI;
        local bool bReady;
        local int PlayerCount, ReadyCount;

        Global.Timer();

        if ( Level.NetMode == NM_StandAlone && NumSpectators > 0 ) // Spectating only.
        {
            StartMatch();
            PlayStartupMessage();
            return;
        }

        // first check if there are enough net players, and enough time has elapsed to give people
        // a chance to join
        if ( NumPlayers == 0 )
            bWaitForNetPlayers = true;

        if ( bWaitForNetPlayers && Level.NetMode != NM_Standalone )
        {
            if ( NumPlayers >= MinNetPlayers )
                ElapsedTime++;
            else
                ElapsedTime = 0;

            if ( NumPlayers == MaxPlayers || ElapsedTime > NetWait )
                bWaitForNetPlayers = false;
        }

        if ( Level.NetMode != NM_Standalone && bWaitForNetPlayers || (bTournament && NumPlayers < MaxPlayers) )
        {
            PlayStartupMessage();
            return;
        }

        // check if players are ready
        bReady = true;
        StartupStage = 1;

        for ( CI = Level.ControllerList; CI != None; CI = CI.NextController )
        {
            if ( CI.IsA('PlayerController') && CI.PlayerReplicationInfo != none && CI.bIsPlayer && CI.PlayerReplicationInfo.Team != none &&
                CI.PlayerReplicationInfo.bWaitingPlayer && !CI.PlayerReplicationInfo.bOnlySpectator)
            {
                PlayerCount++;

                if ( !CI.PlayerReplicationInfo.bReadyToPlay )
                    bReady = false;
                else
                    ReadyCount++;
            }
        }

        if ( PlayerCount > 0 && bReady && !bReviewingJumpspots )
            StartMatch();

        PlayStartupMessage();

        if ( NumPlayers>1 )
            ElapsedTime++;

        // added check for ReadyCount > 0  -- PooSH
        if ( (ReadyCount >= PlayerCount * 0.65 || ElapsedTime > 300) && ReadyCount > 0 /* && PlayerCount > 2 */ && LobbyTimeout > 0 )
        {
            if ( LobbyTimeout <= 1 )
            {
                for ( CI = Level.ControllerList; CI != None; CI = CI.NextController )
                {
                    if ( CI.IsA('PlayerController') && CI.PlayerReplicationInfo != none )
                        CI.PlayerReplicationInfo.bReadyToPlay = True;
                }

                LobbyTimeout = 0;
            }
            else
            {
                LobbyTimeout--;
            }

            ScrnGRI.LobbyTimeout = LobbyTimeout;
        }
        else
        {
            ScrnGRI.LobbyTimeout = -1;
        }
    }
}

State MatchInProgress
{
    function BeginState()
    {
        SelectShop(); // shop must be selected in case players need to spawn next to it

        Super.BeginState();

        ElapsedTime = 0;
        AddSuicideTime(0, false);  // refresh timers

        if ( ScrnGameLength != none ) {
            if ( !ScrnGameLength.VersionCheck() ) {
                ScrnBalanceMut.BroadcastMessage("^1BROKEN GAME! Tell admins to check ScrnGames/Waves/Zeds.ini",
                        true);
            }

            if (!ScrnGameLength.LoadWave(WaveNum)) {
                DoWaveEnd();
            }
            else {
                WaveCountDown = max(10, ScrnGameLength.Wave.TraderTime);
                // MaxMonsters will be altered leter in SetupWave(). We need it now for test map.
                MaxMonsters = MaxZombiesOnce;
            }
        }
    }

    function bool UpdateMonsterCount()
    {
        return global.UpdateMonsterCount();
    }

    function SetupPickups()
    {
        global.SetupPickups();
    }

    function InitMapWaveCfg()
    {
        global.InitMapWaveCfg();
    }

    function bool BootShopPlayers()
    {
        return global.BootShopPlayers();
    }

    function SelectShop()
    {
        global.SelectShop();
    }

    function BattleTimer()
    {
        WaveTimeElapsed += 1.0;

        // Close Trader doors
        if (bTradingDoorsOpen) {
            CloseShops();
            TraderProblemLevel = 0;
        }
        if ( TraderProblemLevel < 4 ) {
            if( BootShopPlayers() )
                TraderProblemLevel = 0;
            else
                TraderProblemLevel++;
        }

        if ( ScrnGameLength != none ) {
            ScrnGameLength.WaveTimer();
        }
    }

    function WaveTimer()
    {
        BattleTimer();

        if ( !MusicPlaying )
            StartGameMusic(True);

        if ( TotalMaxMonsters <= 0 ) {
             // all monsters spawned
            if ( ScrnGameLength == none && NumMonsters <= 0 )
                DoWaveEnd();
            else if ( NumMonsters <= 5 && Level.TimeSeconds > ZedLastSpawnTime + KillRemainingZedsCooldown )
                KillRemainingZeds(false);
        }
        else if ( Level.TimeSeconds > NextMonsterTime && NumMonsters + 4 <= MaxMonsters ) {
            if ( AddSquad() ) {
                if ( ScrnGameLength != none )
                    WaveEndTime = ScrnGameLength.GetWaveEndTime();
                else
                    WaveEndTime = Level.TimeSeconds + 60;
            }
            NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime();
        }
    }

    function BossWaveTimer()
    {
        BattleTimer();

        if ( bBossSpawned ) {
            if( !bHasSetViewYet ) {
                bHasSetViewYet = true;
                BossGrandEntry();
            }
            else if( ViewingBoss != none && !ViewingBoss.bShotAnim ) {
                ViewingBoss = None;
                BossGrandExit();
            }
        }

        if( TotalMaxMonsters <= 0 || Level.TimeSeconds > WaveEndTime ) {
            // if everyone's spawned and they're all dead
            if ( NumMonsters <= 0 )
                DoWaveEnd();
        }
        else if ( Level.TimeSeconds > NextMonsterTime ) {
            if ( !bBossSpawned ) {
                AddBoss();
            }
            else {
                AddSquad();
                NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime() * 2.0; // slower squad spawn in boss waves
            }
        }
    }

    function TraderTimer()
    {
        local Controller C;
        local int i;

        WaveCountDown--;
        ScrnGRI.TimeToNextWave = WaveCountDown;

        if ( !CalmMusicPlaying ) {
            InitMapWaveCfg();
            StartGameMusic(False);
        }

        // Select a shop if one isn't open
        if ( ScrnGRI.CurrentShop == none )
            SelectShop();

        // Open Trader doors
        if ( !bTradingDoorsOpen && ((ScrnGameLength != none && ScrnGameLength.Wave.bOpenTrader)
                || (ScrnGameLength == none && WaveNum != InitialWave)) )
        {
            KillZeds(); // make sure that no zeds exist when we are opening trader doors
            OpenShops();
        }

        if ( WaveCountDown == 30 || WaveCountDown == 10 ) {
            if ( WaveCountDown == 30 )
                i = 4; // Have Trader tell players that they've got 30 seconds
            else
                i = 5; // Have Trader tell players that they've got 10 seconds

            for ( C = Level.ControllerList; C != None; C = C.NextController ) {
                if ( KFPlayerController(C) != None )
                    KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', i);
            }
        }
        else if ( (WaveCountDown > 0) && (WaveCountDown <= 5) ) {
            if ( ScrnGameLength != none )
                ScrnGameLength.SetWaveInfo();

            if( WaveNum == FinalWave && bUseEndGameBoss )
                BroadcastLocalizedMessage(class'ScrnWaitingMessage', 3);
            else
                BroadcastLocalizedMessage(class'ScrnWaitingMessage', 1);
        }
        else if ( WaveCountDown <= 1 ) {
            SetupWave();
        }
    }

    function Timer()
    {
        Global.Timer();

        if ( !bFinalStartup ) {
            bFinalStartup = true;
            PlayStartupMessage();
        }

        ElapsedTime++;
        GameReplicationInfo.ElapsedTime = ElapsedTime;
        if( !UpdateMonsterCount() ) {
            EndGame(None,"TimeLimit");
            return;
        }
        if ( bSuicideTimer ) {
            SuicideTimer();
        }

        AdjustBotCount();
        if( bUpdateViewTargs )
            UpdateViews();

        if (ScrnGameLength != none ) {
            if ( bWaveBossInProgress || bWaveInProgress ) {
                if ( ScrnGameLength.CheckWaveEnd() )
                    DoWaveEnd();
                else if ( bWaveBossInProgress )
                    BossWaveTimer();
                else
                    WaveTimer();
            }
            else {
                TraderTimer();
            }
        }
        else {
            if( bWaveBossInProgress ) {
                BossWaveTimer();
            }
            else if( bWaveInProgress ) {
                WaveTimer();
            }
            else if ( TotalMaxMonsters <= 0 && NumMonsters <= 0 ) {
                if ( WaveNum >= EndWaveNum() ) {
                    EndGame(None,"TimeLimit");
                    return;
                }
                TraderTimer();
            }
        }
    }

    event Tick(float dt)
    {
        global.Tick(dt);

        LoadTelemetry();
        if ( Telemetry.length > 0 ) {
            ZVolCheckPlayers(fmax(1.0, ceil(ZedSpawnList.length * dt / ZVolVisibilityCheckPeriod)));
        }

        if ( Level.TimeSeconds > NextMonsterTime && bWaveInProgress && !bWaveBossInProgress
                && TotalMaxMonsters > 0 && NumMonsters < MaxMonsters
                && (NumMonsters + 4 <= MaxMonsters
                    || (NextSpawnSquad.length > 0 && NumMonsters + NextSpawnSquad.length <= MaxMonsters)) )
        {
                AddSquad();
                NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime();
        }
    }

    function float CalcNextSquadSpawnTime()
    {
        local float NextSpawnTime;

        if( NextSpawnSquad.length > 0 ) {
            return 0.25;
        }

        NextSpawnTime = fclamp(KFLRules.WaveSpawnPeriod, 0.2, BoringStages[BoringStage].SpawnPeriod);
        NextSpawnTime /= 1.0 + (AlivePlayerCount - 1) * SpawnRatePlayerMod;
        if ( BaseDifficulty < DIFF_HARD && NumMonsters >= 16 ) {
            // slower spawns on Normal difficulty if there are already many zeds spawned
            NextSpawnTime *= 2.0;
        }

        if ( ScrnGameLength != none ) {
            ScrnGameLength.AdjustNextSpawnTime(NextSpawnTime);
        }
        else {
            if( NumMonsters >= 16 && WavePct >= 70 ) {
                // longer cooldown on later waves if there are already many zeds spawned
                NextSpawnTime *= 1.5;
            }
            // classic sine mod
            NextSpawnTime *= 1.0 + WaveSinMod();
            NextSpawnTime = fmax(NextSpawnTime, BoringStages[BoringStage].MinSpawnTime);
        }
        return NextSpawnTime;
    }

    function DoWaveEnd()
    {
        local Controller C;
        local KFPlayerController KFPC;
        local KFPlayerReplicationInfo KFPRI;
        local bool bRespawnDeadPlayers;

        if ( !rewardFlag ) {
            RewardSurvivingPlayers();
        }

        // Clear Trader Message status
        bDidTraderMovingMessage = false;
        bDidMoveTowardTraderMessage = false;

        Bosses.length = 0;
        WaveNum++;
        WavePct = 100 * (WaveNum + 1) / FinalWave;

        if ( WaveNum >= EndWaveNum() ) {
            EndGame(None, "TimeLimit");
            return;
        }

        ScrnGRI.WaveNumber = WaveNum;
        if ( ScrnGameLength != none ) {
            ScrnGameLength.WaveEnded();
            if ( !ScrnGameLength.LoadWave(WaveNum) ) {
                DoWaveEnd();
                return;
            }
            bRespawnDeadPlayers = ScrnGameLength.Wave.bRespawnDeadPlayers;
            WaveCountDown = ScrnGameLength.Wave.TraderTime;
            if ( WaveCountDown <= 0 ) {
                SetupWave();
                return;
            }
            if ( !ScrnGameLength.Wave.bOpenTrader ) {
                // SelectShop(); // change shop for every wave, even if trader stays closed
                SetupPickups();
                ScrnBalanceMut.SetupPickups(false, true); // no trader = people need more ammo
                ScrnBalanceMut.bPickupSetupReduced = true; // don't let ScrnBalance to reduce pickups again
            }
        }
        else {
            bRespawnDeadPlayers = true;
            WaveCountDown = max(TimeBetweenWaves, 1);
        }

        bWaveInProgress = false;
        bWaveBossInProgress = false;
        bNotifiedLastManStanding = false;
        // replicate to clients
        ScrnGRI.MaxMonstersOn = false;
        ScrnGRI.TimeToNextWave = WaveCountDown;
        ScrnGRI.bWaveInProgress = false;

        for ( C = Level.ControllerList; C != none; C = C.NextController ) {
            if ( C.PlayerReplicationInfo == none )
                continue;

            if ( bRespawnDeadPlayers ) {
                C.PlayerReplicationInfo.bOutOfLives = false;
                C.PlayerReplicationInfo.NumLives = 0;
            }

            KFPC = KFPlayerController(C);
            KFPRI = KFPlayerReplicationInfo(C.PlayerReplicationInfo);
            if ( KFPC != none && KFPRI != none )
            {
                KFPC.bChangedVeterancyThisWave = false;
                if ( KFPRI.ClientVeteranSkill != KFPC.SelectedVeterancy )
                    KFPC.SendSelectedVeterancyToServer();

                if ( bRespawnDeadPlayers && KFPC.Pawn == none && !KFPRI.bOnlySpectator )
                {
                    if (ScrnGameLength == none || !ScrnGameLength.bStartingCashReset) {
                        KFPRI.Score = Max(MinRespawnCash, KFPRI.Score);
                    }
                    KFPC.GotoState('PlayerWaiting');
                    KFPC.SetViewTarget(C);
                    KFPC.ClientSetBehindView(false);
                    KFPC.bBehindView = False;
                    KFPC.ClientSetViewTarget(C.Pawn);
                    KFPC.ServerReStartPlayer();
                }

                if ( KFSteamStatsAndAchievements(KFPC.SteamStatsAndAchievements) != none )
                    KFSteamStatsAndAchievements(KFPC.SteamStatsAndAchievements).WaveEnded();

                KFPC.bSpawnedThisWave = KFPC.Pawn != none && WaveNum > FinalWave;
            }
        }

        bUpdateViewTargs = True;
        if ( WaveNum < FinalWave && (ScrnGameLength == none || ScrnGameLength.Wave.bOpenTrader) ) {
            if ( ScrnGameLength == none && (ScrnBalanceMut.bRespawnDoors || ScrnBalanceMut.bTSCGame) ) {
                ScrnBalanceMut.RespawnDoors();
            }
            BroadcastLocalizedMessage(class'ScrnWaitingMessage', 2);
        }
    }

    function OpenShops()
    {
        local int i;
        local Controller C;
        local KFPlayerController KFPC;
        local int TraderMessageIndex;

        bTradingDoorsOpen = True;

        if ( WaveNum < FinalWave )
            TraderMessageIndex = 2;
        else
            TraderMessageIndex = 3;

        for( i=0; i<ShopList.Length; ++i ) {
            if( ShopList[i].bAlwaysClosed )
                continue;
            if( ShopList[i].bAlwaysEnabled )
                ShopList[i].OpenShop();
        }

        if ( ScrnGRI.CurrentShop == none )
            SelectShop();
        ScrnGRI.CurrentShop.OpenShop();

        // Tell all players to start showing the path to the trader
        for( C=Level.ControllerList; C!=None; C=C.NextController ) {
            if( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health>0 )
            {
                // Disable pawn collision during trader time
                C.Pawn.bBlockActors = !bAntiBlocker;

                KFPC = KFPlayerController(C);
                if( KFPC(C) != none ) {
                    KFPC.SetShowPathToTrader(true);
                    KFPC.ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', TraderMessageIndex);
                }
            }
        }
    }

    // C&P to replace AllActors with DynamicActors - performance tweak
    function CloseShops()
    {
        local int i;
        local Controller C;
        local KFPlayerController KFPC;

        bTradingDoorsOpen = False;
        for( i=0; i<ShopList.Length; i++ ) {
            if( ShopList[i].bCurrentlyOpen )
                ShopList[i].CloseShop();
        }

        SelectShop();
        DestroyDroppedPickups();

        // Tell all players to stop showing the path to the trader
        for ( C = Level.ControllerList; C != none; C = C.NextController ) {
            if ( C.Pawn != none && C.Pawn.Health > 0 ) {
                // Restore pawn collision during trader time
                C.Pawn.bBlockActors = C.Pawn.default.bBlockActors;

                KFPC = KFPlayerController(C);
                if ( KFPC != none ) {
                    KFPC.SetShowPathToTrader(false);
                    KFPC.ClientForceCollectGarbage();

                    if ( WaveNum < FinalWave - 1 ) {
                        // Have Trader tell players that the Shop's Closed
                        KFPC.ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 6);
                    }
                }
            }
        }
    }

    function StartWaveBoss()
    {
        global.StartWaveBoss();
    }
} // MatchInProgress

State MatchOver
{
    function Timer()
    {
        super.Timer();

        if ( EndMessageCounter == 10 ) {
            class'ScrnSuicideBomb'.static.DisintegrateAll(Level);
        }
    }
}

defaultproperties
{
    GameName="ScrN Floor"
    Description="ScrN Edition of Killing Floor game mode (KFGameType)."

    GameReplicationInfoClass=class'ScrnGameReplicationInfo'
    VotingHandlerOverride="KFMapVoteV2.KFVotingHandler"

    PathWhisps(0)="KFMod.RedWhisp"
    PathWhisps(1)="KFMod.RedWhisp"
    HUDType="ScrnBalanceSrv.ScrnHUD"
    ScoreBoardType="ScrnBalanceSrv.ScrnScoreBoard"
    LoginMenuClass="ScrnBalanceSrv.ScrnInvasionLoginMenu"
    PlayerControllerClass=class'ScrnPlayerController'
    PlayerControllerClassName="ScrnBalanceSrv.ScrnPlayerController"

    DefaultGameLength=-1
    bSingleTeamGame=true
    bUseEndGameBoss=true
    bUseZEDThreatAssessment=true
    ZedSpawnLoc=ZSLOC_AUTO
    ZVolVisibilityCheckPeriod=1.0
    ZVolDisableTime=10.0
    ZedSpawnMinDist=600    // 12m
    ZedSpawnMaxDist=2000   // 40m (+12m)
    BossSpawnRecDist=1000  // 20m
    FloorPenalty=0.3
    FloorHeight=256
    ElevatedSpawnMinZ=128
    ElevatedSpawnMaxZ=512
    TurboScale=1.0
    ZEDTimeTransitionTime=0.498
    ZEDTimeTransitionRate=0.100

    DebugZVolColors[0]=(R=255,G=1,B=1,A=255)
    DebugZVolColors[1]=(R=1,G=255,B=1,A=255)
    DebugZVolColors[2]=(R=1,G=1,B=255,A=255)
    DebugZVolColors[3]=(R=255,G=255,B=1,A=255)
    DebugZVolColors[4]=(R=,G=255,B=255,A=255)

    bKillMessages=true
    bZedTimeEnabled=true
    bAntiBlocker=true
    MAX_DIST_SQ=1.0e37

    LogZedSpawnLevel=4  // LOG_INFO
    MaxSpawnAttempts=3
    MaxSpecialSpawnAttempts=10
    SpawnRatePlayerMod=0.25
    KillRemainingZedsCooldown=15.0
    // SpawnPeriod may be further limited by KFLevelRules
    BoringStages[0]=(SpawnPeriod=3.0,MinSpawnTime=1.5,ZVolUsageTime=20)
    BoringStages[1]=(SpawnPeriod=1.0,MinSpawnTime=1.0,ZVolUsageTime=10)
    BoringStages[2]=(SpawnPeriod=0.5,MinSpawnTime=0.5,ZVolUsageTime=5)
    BoringStages[3]=(SpawnPeriod=0.25,MinSpawnTime=0.25,ZVolUsageTime=2.5)
    BoringStrings[0]="Normal ZED spawn rate"
    BoringStrings[1]="DOUBLE ZED spawn rate"
    BoringStrings[2]="QUAD ZED spawn rate"
    BoringStrings[3]="INSANE ZED spawn rate"

    // copied from last two LongWaves
    NormalWaves(5)=(WaveMask=75393519,WaveMaxMonsters=40,WaveDuration=255,WaveDifficulty=0.300000)
    NormalWaves(6)=(WaveMask=90171865,WaveMaxMonsters=45,WaveDuration=255,WaveDifficulty=0.300000)

    KFHints[ 0]="ScrN: You can interrupt reloading by dropping the weapon on the ground"
    KFHints[ 1]="ScrN: Many weapons have Tactical Reload. Reload a non-empty more quickly."
    KFHints[ 2]="ScrN: You can reload a single shell into Boomstick"
    KFHints[ 3]="ScrN: Combat Shotgun is made much better. Give it a try"
    KFHints[ 4]="ScrN: Shotguns, except Combat and Boomstick, penetrate fat bodies worse than small enemies"
    KFHints[ 5]="ScrN: M99 cannot stun Scrake with a body-shot. Crossbow has no fire speed bonus as in the original game before v1035"
    KFHints[ 6]="ScrN: M14EBR has different laser sights."
    KFHints[ 7]="ScrN: Hand grenades can be 'cooked'. Enable/disable that on 'Scrn Features' page in the Main Menu."
    KFHints[ 8]="ScrN: Gunslinger has bonuses both for single and dual pistols. But real Cowboys use only dualies."
    KFHints[ 9]="ScrN: Gunslinger becomes a Cowboy while using dual pistols without wearing heavy armor. Cowboy moves and shoots much faster. On the other hand, he dies faster too."
    KFHints[10]="ScrN: Berserker, while holding non-melee weapons, moves slower than other perks."
    KFHints[11]="ScrN: Chainsaw makes more damage but consumes fuel. Also, the alternate attack stuns Scrakes."
    KFHints[12]="ScrN: Support Spec. may use Chainsaw. Remember Evil Dead? Try the Chainsaw+Boomstick loadout."
    KFHints[13]="ScrN: Medics have regular frag nades. Do not blow yourself up!"
    KFHints[14]="ScrN: Medic, while holding a syringe, runs same fast as while holding a knife."
    KFHints[15]="ScrN: Medics can heal much faster than other perks. If you aren't a Medic, don't screw up the healing process with your lame injection."
    KFHints[16]="ScrN: Medic gets XP for shooting zeds with Medic Guns. But do not forget to heal your teammates!"
    KFHints[17]="ScrN: Medic nades are for healing only. Zeds are not taking damage neither fear them."
    KFHints[18]="ScrN: Combat Medic is more 'combat' than 'medic'"
    KFHints[19]="ScrN: FN-FAL has armor-piercing bullets and 2-round fixed burst mode."
    KFHints[20]="ScrN: MK23 has no bullet penetration but double size of magazine, comparing to .44 Magnum"
    KFHints[21]="ScrN: Your experience and perk bonus levels may be different. If they are, you see two perk icons on the HUD."
    KFHints[22]="ScrN: If you see two perk icons on the HUD, the left one shows your experience level, the right - actual level of perk bonuses that you gain."
    KFHints[23]="ScrN: Husk Gun's secondary fire acts as Napalm Thrower."
    KFHints[24]="ScrN: Flares deal the incremental burn Damage over Time (iDoT). The more you shoot the more damage zeds take from burning."
    KFHints[25]="ScrN: Nailgun can nail enemies to walls... nail them alive! Crucify your ZED!"
    KFHints[26]="ScrN Console Command: MVOTE - access to ScrN Voting. Type MVOTE HELP for more info."
    KFHints[27]="Social Isolation: The Virus gets spread by a close contact. Keep distance!"
    KFHints[28]="Social Isolation: Infected players should keep a distance from other infected as well. Increased Virus concentration in the air leads to severe symptoms."
    KFHints[29]="Social Isolation: Epidemic safety rules prohibit picking up items of infected players, even if you are already infected."
    KFHints[30]="Social Isolation: The Trader keeps her shop clean. Players get charged for coughing in the shop area - to cover the disinfection costs."
    KFHints[31]="Social Isolation: Rumors say that Toilet Paper can protect you from the Virus. At least you will die with a clean butt."
    KFHints[32]="Social Isolation: 'I can feel it coming in the air tonight, oh Lord!' Yes, it is the Virus in the air. And it is gonna kill you!"
    KFHints[33]="Social Isolation: The shop is a high-risk area for spreading the Virus. Keep distance and wait in line for shopping."
}
