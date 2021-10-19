// made to fix KFStoryGameInfo loading for KFO maps
class ScrnGameType extends KFGameType;

var ScrnBalance ScrnBalanceMut;
var ScrnGameReplicationInfo ScrnGRI;

// Min numbers of players to be used in calculation of zed count in wave
// Those values are for configurations only. Set ScrnGRI.FakedPlayers to make in-game effect
var globalconfig protected byte FakedPlayers, FakedAlivePlayers;
var config bool bAntiBlocker;
var config byte LogZedSpawn;

enum EZedSpawnLocation {
    ZSLOC_VANILLA,    // Same as in Vanilla KF
    ZSLOC_CLOSER,     // Spawn zed closer to players (equals to bCloserZedSpawns=True in previous ScrN versions)
    ZSLOC_RANDOM,     // Spawn zeds in random locations no matter of distance to player
    ZSLOC_AUTO        // Auto set the best spawn rating depending from wave stats
};
var EZedSpawnLocation ZedSpawnLoc;
var ScrnGameLength ScrnGameLength;
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

var bool bSingleTeamGame;
var transient int WavePlayerCount; // alive player count at the beginning of the wave
var transient int AlivePlayerCount, AliveTeamPlayerCount[2];
var array<KFMonster> Bosses;
var transient bool bBossSpawned;
var int MaxSpawnAttempts, MaxSpecialSpawnAttempts; // maximum spawn attempts before deleting the squad
var float SpawnRatePlayerMod;  // per-player zed spawn rate increase
var int WavePct;  // Current wave's percentage to the final wave.

struct SBoringStage {
    var float SpawnPeriod;
    var float MinSpawnTime;
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

var bool bZedTimeEnabled;  // set it to false to completely disable the Zed Time in the game
var transient byte PlayerSpawnTraderTeleportIndex;
var name PlayerStartEvent;
var int SuicideTime;


// InitGame() gets called before PreBeginPlay()! Therefore, GameReplicationInfo does not exist yet.
event InitGame( string Options, out string Error )
{
    local int ConfigMaxPlayers;
    local GameRules g;

    CmdLine = Options;

    KFGameLength = GetIntOption(Options, "GameLength", KFGameLength);

    ConfigMaxPlayers = default.MaxPlayers;
    super.InitGame(Options, Error);
    MaxPlayers = Clamp(GetIntOption( Options, "MaxPlayers", ConfigMaxPlayers ),0,32);
    default.MaxPlayers = Clamp( ConfigMaxPlayers, 0, 32 );

    CheckScrnBalance();
    if ( ScrnBalanceMut.bScrnWaves ) {
        if (ScrnGameLength == none ) // mutators might already load this
            ScrnGameLength = new(none, string(KFGameLength)) class'ScrnGameLength';
        ScrnGameLength.LoadGame(self);
    }
    else {
        if ( KFGameLength < 0 || KFGameLength > 3) {
            log("GameLength must be in [0..3]: 0-short, 1-medium, 2-long, 3-custom", class.name);
            KFGameLength = GL_Long;
        }
        log("MonsterCollection = " $ MonsterCollection, class.name);
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
        ScrnGRI.GameTitle = ScrnGameLength.GameTitle;
        ScrnGRI.GameAuthor = ScrnGameLength.Author;
        ScrnGRI.FakedPlayers = FakedPlayers;
        ScrnGRI.FakedAlivePlayers = FakedAlivePlayers;
        ScrnGRI.SuicideTime = SuicideTime;
    }
}

static event class<GameInfo> SetGameType( string MapName )
{
    local string prefix;

    prefix = Caps(Left(MapName, InStr(MapName, "-")));
    if ( prefix == "KFO")
        return Class'ScrnBalanceSrv.ScrnStoryGameInfo';
    else if ( prefix == "KF" )
        return default.class;

    return super.SetGameType( MapName );
}

function bool IsTestMap()
{
    local string MapName;

    MapName = caps(GetCurrentMapName(Level));
    return InStr(MapName, "TESTMAP") != -1 || InStr(MapName, "TESTGROUNDS") != -1;
}

protected function CheckScrnBalance()
{
    if ( ScrnBalanceMut == none ) {
        log("ScrnBalance is not loaded! Loading it now...", class.name);
        AddMutator(class.outer.name $ ".ScrnBalance", false);
        if ( ScrnBalanceMut == none )
            log("Unable to spawn ScrnBalance!", class.name);
    }
}

// is called in the first tick from ScrnBalance.Tick()
function CheckZedSpawnList()
{
    local int i;
    local ZombieVolume ZVol;

    for (i = 0; i < ZedSpawnList.Length; ++i ) {
        ZVol = ZedSpawnList[i];
        if ( ZVol.SpawnPos.length == 0 ) {
            ZVol.InitSpawnPoints();
            if ( ZVol.SpawnPos.length == 0 ) {
                log("Unable to init Zombie Volume "$ZVol.name$". Removing it from the list", class.name);
                ZedSpawnList.remove(i--, 1);
            }
        }
    }
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
        log("Invalid Path Target: " $ PathTarget, class.name);
        InvalidPathTargets[InvalidPathTargets.length] = PathTarget;
    }
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
event Tick(float DeltaTime)
{
    local float TrueTimeFactor;
    local Controller C;

    if( bZEDTimeActive ) {
        TrueTimeFactor = 1.1/Level.TimeDilation;
        CurrentZEDTimeDuration -= DeltaTime * TrueTimeFactor;

        if( CurrentZEDTimeDuration <= 0 )
        {
            bZEDTimeActive = false;
            bSpeedingBackUp = false;
            SetGameSpeed(TurboScale);
            ZedTimeExtensionsUsed = 0;
        }
        else if( CurrentZEDTimeDuration < (ZEDTimeDuration*0.166) ) {
            if( !bSpeedingBackUp ) {
                bSpeedingBackUp = true;
                for( C=Level.ControllerList;C!=None;C=C.NextController ) {
                    if (KFPlayerController(C)!= none)
                        KFPlayerController(C).ClientExitZedTime();
                }
            }
            SetGameSpeed(Lerp( (TurboScale * CurrentZEDTimeDuration/(ZEDTimeDuration*0.166)),TurboScale, ZedTimeSlomoScale ));
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
        if ( GameDifficulty <= 3 )
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
    if (bZedTimeEnabled) {
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
    if ( GameDifficulty >= 5.0 ) {
        DoshDifficultyMult = 0.65;   // Suicidal and Hell on Earth
    }
    else if ( GameDifficulty >= 4.0 ) {
        DoshDifficultyMult = 0.85;  // Hard
    }
    else if ( GameDifficulty <= 1.0 ) {
        DoshDifficultyMult = 2.0;  // Beginner
    }
    else {
        DoshDifficultyMult = 1.0; // Normal
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
    local Controller PC;
    local int i;
    local bool bZedDropDoshOriginal;

    bZedDropDoshOriginal = bZedDropDosh;
    bZedDropDosh = false;

    for ( PC = Level.ControllerList; PC != none; PC = PC.NextController )
    {
        if ( PC.PlayerReplicationInfo != none && PC.PlayerReplicationInfo.SteamStatsAndAchievements != none )
        {
            PC.PlayerReplicationInfo.SteamStatsAndAchievements.bUsedCheats = true;
        }
    }

    // fill the array first, because direct M killing may screw up DynamicActors() iteration
    // -- PooSH
    foreach DynamicActors(class 'KFMonster', M) {
        if(M.Health > 0 && !M.bDeleteMe)
            Monsters[Monsters.length] = M;
    }

    for ( i=0; i<Monsters.length; ++i )
        Monsters[i].Died(Monsters[i].Controller, class'DamageType', Monsters[i].Location);
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

// Calculate spawning cost.
// Bug Fixes by PooSH:
// - Dead players do not lower distance score
function float RateZombieVolume(ZombieVolume ZVol, Controller SpawnCloseTo, optional bool bIgnoreFailedSpawnTime, optional bool bBossSpawning)
{
    local Controller C;
    local float Rating;
    local float DistSquared, MinDistanceToPlayerSquared;
    local byte i;
    local float PlayerDistScoreZ, PlayerDistScoreXY, TotalPlayerDistScore, UsageScore;
    local vector LocationXY, TestLocationXY;
    local bool bTooCloseToPlayer;
    local float wDesire, wDist, wUsage, wRand;

    if ( ZVol == none )
        return -1;

    if( !bIgnoreFailedSpawnTime && Level.TimeSeconds - ZVol.LastFailedSpawnTime < 5.0 )
        return -1;

    // check doors
    for( i=0; i<ZVol.RoomDoorsList.Length; ++i ) {
        if ( ZVol.RoomDoorsList[i].DoorActor!=None && (ZVol.RoomDoorsList[i].DoorActor.bSealed
                || (!ZVol.RoomDoorsList[i].bOnlyWhenWelded && ZVol.RoomDoorsList[i].DoorActor.KeyNum==0)) )
            return -1;
    }

    // Now make sure no player sees the spawn point.
    MinDistanceToPlayerSquared = ZVol.MinDistanceToPlayer**2;
    for ( C=Level.ControllerList; C!=None; C=C.NextController ) {
        if( C.bIsPlayer && C.Pawn!=none && C.Pawn.Health>0 ) {
            if( ZVol.Encompasses(C.Pawn) )
                return -1; // player inside this volume

            DistSquared = VSizeSquared(ZVol.Location - C.Pawn.Location);
            if( DistSquared < MinDistanceToPlayerSquared )
                return -1;
            // If the zone is too close to a boss character, reduce its desirability
            if( bBossSpawning && DistSquared < 1000000.0 )
                bTooCloseToPlayer = true;
            // Do individual checks for spawn locations now, maybe add this back in later as an optimization
            // if fog doesn't hide spawn & lineofsight possible
            if( !ZVol.bAllowPlainSightSpawns
                    && (!C.Pawn.Region.Zone.bDistanceFog || (DistSquared < C.Pawn.Region.Zone.DistanceFogEnd**2))
                    && FastTrace(ZVol.Location, C.Pawn.Location + C.Pawn.EyePosition()) )
                return -1; // can be seen by player
        }
    }

    // Start Rating with Spawn desirability
    Rating = ZVol.SpawnDesirability;
    // Rate how long its been since this spawn was used
    UsageScore = fmin(Level.TimeSeconds - ZVol.LastSpawnTime, 30.0) / 30.0;

    // Rate the Volume on how close it is to the player
    LocationXY = ZVol.Location;
    LocationXY.Z = 0;
    TestLocationXY = SpawnCloseTo.Pawn.Location;
    TestLocationXY.Z = 0;
    // 250 = 5 meters
    // 4000000 = 2000^2 = 40 meters
    PlayerDistScoreZ = fmax(1.0 - abs(SpawnCloseTo.Pawn.Location.Z - ZVol.Location.Z)/250.0, 0.0);
    PlayerDistScoreXY = fmax(1.0 - VSizeSquared(TestLocationXY-LocationXY)/4000000.0, 0.0);
    // Weight the XY distance much higher than the Z dist.
    // This gets zombies spawning more on the same level as the player.
    if( ZVol.bNoZAxisDistPenalty )
        TotalPlayerDistScore = PlayerDistScoreXY;
    else
        TotalPlayerDistScore = 0.3*PlayerDistScoreZ + 0.7*PlayerDistScoreXY;

    wDesire = 0.30;
    switch (ZedSpawnLoc) {
        case ZSLOC_CLOSER:
            wDist = 0.35;
            wUsage = 0.25;
            break;

        case ZSLOC_RANDOM:
            wDist = 0.10;
            wUsage = 0.30;
            wDesire = 0.15;
            break;

        case ZSLOC_AUTO:
            if (NumMonsters >= 20 && TotalMaxMonsters >= 20) {
                // many zeds already spawned, so spawn them more randomly
                wDist = 0.15;
                wUsage = 0.30;
            }
            else {
                // closer spawns
                wDist = 0.35;
                wUsage = 0.25;
            }
            if (GameDifficulty < 3) {
                wDist *= 0.7; // more random spawns on Normal difficulty
            }
            break;

        case ZSLOC_VANILLA:
        default:
            wDist = 0.30;
            wUsage = 0.30;
    }
    wRand = 1.0 - wDesire - wDist - wUsage;
    Rating *= wDesire + wDist * TotalPlayerDistScore + wUsage * UsageScore + wRand * frand();

    if( bTooCloseToPlayer )
        Rating*=0.2;

    // Try and prevent spawning in the same volume back to back
    if( LastSpawningVolume == ZVol )
        Rating*=0.2;

    // if we get here, return at least a 1
    return fmax(Rating,1);
}

// returns random alive player
function Controller FindSquadTarget()
{
    local array<Controller> CL;
    local Controller C;

    for( C=Level.ControllerList; C!=None; C=C.NextController ) {
        if( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health>0 )
            CL[CL.Length] = C;
    }
    if( CL.Length>0 )
        return CL[Rand(CL.Length)];

    return none;
}

function bool CanSpawnInVolume(class<KFMonster> M, ZombieVolume ZVol)
{
    local int i;
    local byte ZombieFlag;

    ZombieFlag = M.default.ZombieFlag;
    if( (!ZVol.bNormalZeds && ZombieFlag==0)
        || (!ZVol.bRangedZeds && ZombieFlag==1)
        || (!ZVol.bLeapingZeds && ZombieFlag==2)
        || (!ZVol.bMassiveZeds && ZombieFlag==3) )
    {
        return false;
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

    // First pass, pick a random player.
    C = FindSquadTarget();
    if( C==None )
        return None; // This shouldn't happen. Just to be sure...

    // Second pass, figure out best spawning point.
    // Usually, ZombieVolume can fit 4-8 zeds. If volume can spawn 6 zeds, it is already good enough,
    // so do not lower its rating to favor a huge volume 200m away
    total = min(Squad.Length, 6);

    for( i = 0; i < ZedSpawnList.Length; i++ ) {
        CurZ = ZedSpawnList[i];
        if ( CurZ.bObjectiveModeOnly || !CurZ.bVolumeIsEnabled )
            continue;

        CanSpawn = 0;
        for ( j = 0; j < total; ++j ) {
            if ( CanSpawnInVolume(Squad[j], CurZ) ) {
                ++CanSpawn;
            }
        }
        if ( CanSpawn == 0 )
            continue;

        tScore = RateZombieVolume(CurZ, C, bIgnoreFailedSpawnTime, bBossSpawning);

        if ( CanSpawn < total && Squad.Length <= 8 ) {
            // lower rating to favor volumes that can spawn more zeds.
            // However, if squads is bigger that 8 zeds, it supposed to be split.
            tScore *= CanSpawn / total;
        }

        if( tScore > BestScore || (BestZ == None && tScore > 0) ) {
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
    str = "(" $ GetItemName(string(Squad[0].name));
    for ( i = 1; i < Squad.length; ++i ) {
        str $= "," $ GetItemName(string(Squad[i].name));
    }
    str $= ")";

    return str;
}

function bool AddSquad()
{
    if ( ScrnGameLength == none )
        return super.AddSquad();

    if ( NextSpawnSquad.length==0 ) {
        LastZVol = none;
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
        if ( NextSpawnSquad.length == 0 )
            return false;
    }

    if ( LastZVol==none ) {
        LastZVol = FindSpawningVolume();
        if ( LastZVol == none && ScrnGameLength.bLoadedSpecial ) {
            // do not give up on special squads that easy
            LastZVol = FindSpawningVolume(true);
            if ( LastZVol == none && LogZedSpawn >= 2) {
                 log("Couldn't find a place for Special Squad "$ZedSquadToString(NextSpawnSquad), class.name);
            }
        }
        if( LastZVol!=None ) {
            LastSpawningVolume = LastZVol;
        }
    }

    if ( LastZVol == None && LogZedSpawn >= 1 ) {
        log("Unable to find a spawn volume for " $ ZedSquadToString(NextSpawnSquad), class.name);
        NextSpawnSquad.length = 0;
        return false;
    }

    //Log("Spawn on"@LastZVol.Name);
    if ( SpawnSquad(LastZVol, NextSpawnSquad) > 0 ) {
        if ( ScrnGameLength.bLoadedSpecial )
            MaxSpawnAttempts = MaxSpecialSpawnAttempts;
        else
            MaxSpawnAttempts = default.MaxSpawnAttempts;
        return true;
    }
    else if ( --MaxSpawnAttempts > 0 ) {
        TryToSpawnInAnotherVolume();
    }
    else {
        if ( LogZedSpawn >= 2 ) {
            log("Unable to spawn squad " $ ZedSquadToString(NextSpawnSquad), class.name);
        }
        NextSpawnSquad.length = 0;
    }
    return false;
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

    TotalMaxMonsters += ScaleMonsterCount(ScrnGameLength.Wave.Counter); // num monsters in wave
    ScrnGRI.MaxMonsters = TotalMaxMonsters + NumMonsters; // num monsters in wave replicated to clients
    MaxMonsters = Clamp(TotalMaxMonsters,1,16); // max monsters that can be spawned - limit to 16 in boss waves
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
    //     ServerState.ServerName = ScrnBalanceMut.ParseColorTags(ScrnBalanceMut.ColoredServerName);
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

// called at the end of InitGame(), when mutators have been spawned already
protected function StartTourney()
{
    local bool bNoStartCash;

    log("Starting TOURNEY MODE " $ TourneyMode, 'ScrnBalance');

    if ( GameDifficulty < 4 ) {
        // hard difficulty at least
        GameDifficulty = 4;
        ScrnGRI.GameDiff = GameDifficulty;
        ScrnBalanceMut.SetLevels();
    }
    TurboScale = 1.0;
    ScrnBalanceMut.SrvTourneyMode = TourneyMode;
    ScrnBalanceMut.bAltBurnMech = true;
    ScrnBalanceMut.bReplacePickups = true;
    ScrnBalanceMut.bNoRequiredEquipment = false;
    ScrnBalanceMut.bForceManualReload = false;
    ScrnBalanceMut.bDynamicLevelCap = false;
    ScrnBalanceMut.bAllowBehindView = false;

    ScrnBalanceMut.MaxWaveSize = 500;

    ScrnBalanceMut.bUseExpLevelForSpawnInventory = false;
    ScrnBalanceMut.bSpawn0 = true;
    ScrnBalanceMut.bNoStartCashToss = true;
    ScrnBalanceMut.bMedicRewardFromTeam = true;
    if ( bNoStartCash ) {
        ScrnBalanceMut.StartCashHard = 0;
        ScrnBalanceMut.StartCashSui = 0;
        ScrnBalanceMut.StartCashHoE = 0;
        ScrnBalanceMut.MinRespawnCashHard = 0;
        ScrnBalanceMut.MinRespawnCashSui = 0;
        ScrnBalanceMut.MinRespawnCashHoE = 0;
    }
    else {
        ScrnBalanceMut.StartCashHard = 200;
        ScrnBalanceMut.StartCashSui = 200;
        ScrnBalanceMut.StartCashHoE = 200;
        ScrnBalanceMut.MinRespawnCashHard = 100;
        ScrnBalanceMut.MinRespawnCashSui = 100;
        ScrnBalanceMut.MinRespawnCashHoE = 100;
    }

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
function SetupRepLink(ClientPerkRepLink R)
{
    local int i;
    local class<Pickup> PC;
    local bool bVanilla, bSWP, bHMG;
    local bool bAllow;
    local name PackageName;

    if ( R == none )
        return; // wtf?

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
                bAllow = PC != class'ScrnZEDMKIIPickup' && (bSWP || PC != class'ScrnHorzineVestPickup');
            }
            else if ( PackageName == 'KFMod' ) {
                bAllow = bVanilla && PC != class'ZEDGunPickup' && PC != class'ZEDMKIIPickup';
            }
            else if ( PackageName == 'ScrnWeaponPack' ) {
                bAllow = bSWP;
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
    local int i;
    local string ID;

    if ( InviteList.length == 0 )
        return false;

    ID = GetPlayerID(PC);
    if ( ID == "" )
        return false;

    for ( i=0; i<InviteList.length; ++i ) {
        if ( InviteList[i] == ID )
            return true;
    }
    return false;
}

function InvitePlayer(PlayerController PC)
{
    local string ID;
    local int i;

    ID = GetPlayerID(PC);
    if ( ID == "" )
        return;
    for ( i=0; i<InviteList.length; ++i ) {
        if ( InviteList[i] == ID )
            return; // already invited
    }
    InviteList[InviteList.length] = ID;
}

function UninvitePlayer(PlayerController PC)
{
    local string ID;
    local int i;

    ID = GetPlayerID(PC);
    if ( ID == "" )
        return;
    for ( i=0; i<InviteList.length; ++i ) {
        if ( InviteList[i] == ID ) {
            InviteList.remove(i, 1);
            return;
        }
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

function bool PlayerCanRestart(PlayerController PC)
{
    if ( ScrnBalanceMut.bTeamsLocked && !IsInvited(PC) ) {
        PC.ReceiveLocalizedMessage(class'ScrnGameMessages', 243);
        if ( !PC.PlayerReplicationInfo.bOnlySpectator ) {
            PC.BecomeSpectator();
        }
        if ( !PC.PlayerReplicationInfo.bOnlySpectator ) {
            // Max spectator count reached. Leave player in the team but rejecft respawning
            PC.PlayerReplicationInfo.bOutOfLives = true;
            PC.PlayerReplicationInfo.NumLives = 1;
            PC.GoToState('Spectating');
        }
        return false;
    }

    if ( bWaveInProgress )
        return false;

    if ( ScrnGameLength != none && !ScrnGameLength.Wave.bRespawnDeadPlayers )
        return false;

    // NumLives actually is NumDeaths this wave
    return !PC.PlayerReplicationInfo.bOutOfLives && PC.PlayerReplicationInfo.NumLives == 0;
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

        if ( HasSuicideTimer() ) {
            class'ScrnSuicideBomb'.static.MakeSuicideBomber(aPlayer.Pawn);
        }

        if ( PC != none ) {
            if ( FriendlyFireScale > 0 )
                ScrnBalanceMut.SendFriendlyFireWarning(PC);
        }
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

    bHadTimer = HasSuicideTimer();
    if ( bReset ) {
        SuicideTime = ElapsedTime + dt;
    }
    else {
        SuicideTime += dt;
    }
    ScrnGRI.SuicideTime = SuicideTime;

    if ( bHadTimer == HasSuicideTimer() )
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

function bool HasSuicideTimer()
{
    return SuicideTime > 0;
}

function GiveStartingCash(PlayerController PC)
{
    PC.PlayerReplicationInfo.Score = max(0, StartingCash + CalcStartingCashBonus(PC));
    if ( ScrnPlayerController(PC) != none )
        ScrnPlayerController(PC).StartCash = PC.PlayerReplicationInfo.Score; // prevent tossing bonus too
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local Controller P;
    local PlayerController Player;
    local KFSteamStatsAndAchievements KFAch;
    local bool bSetAchievement;
    local string MapName;

    EndTime = Level.TimeSeconds + EndTimeDelay;

    if ( WaveNum > FinalWave || (!bUseEndGameBoss && WaveNum == FinalWave) ) {
        GameReplicationInfo.Winner = Teams[0];
        ScrnGRI.EndGameType = 2;

        if ( GameDifficulty >= 2.0 ) {
            bSetAchievement = true;
            // Get the MapName out of the URL
            MapName = GetCurrentMapName(Level);
        }
    }
    else  {
        ScrnGRI.EndGameType = 1;
    }

    if ( (GameRulesModifiers != None) && !GameRulesModifiers.CheckEndGame(Winner, Reason) ) {
        ScrnGRI.EndGameType = 0;
        return false;
    }

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = PlayerController(P);
        if ( Player != none ) {
            Player.ClientSetBehindView(true);
            Player.ClientGameEnded();

            if ( bSetAchievement ) {
                KFAch = KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements);
                if ( KFAch != none ) {
                    KFAch.WonGame(MapName, GameDifficulty, FinalWave >= 10);
                }
            }
        }

        P.GameHasEnded();
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

    if ( len(ScrnBalanceMut.StripColorTags(S)) > 20 )
        S = Left( ScrnBalanceMut.StripColorTags(S), 20 );
    ReplaceText(S, " ", "_");
    ReplaceText(S, "|", "I");

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

function int CalcStartingCashBonus(PlayerController PC)
{
    if ( ScrnGameLength != none )
        return ScrnGameLength.StartingCashBonus;
    return 0;
}

// returns wave number relative to the current game length
function byte RelativeWaveNum(float LongGameWaveNum)
{
    if ( FinalWave == 10 )
        return ceil(LongGameWaveNum);
    return ceil(LongGameWaveNum * FinalWave / 10.0);
}

function int ScaleMonsterCount(int SoloNormalCounter)
{
    local int UsedNumPlayers;
    local float DifficultyMod, NumPlayersMod;

    // scale number of zombies by difficulty
    if ( GameDifficulty >= 7.0 ) // Hell on Earth
        DifficultyMod=1.7;
    else if ( GameDifficulty >= 5.0 ) // Suicidal
        DifficultyMod=1.5;
    else if ( GameDifficulty >= 4.0 ) // Hard
        DifficultyMod=1.3;
    else
        DifficultyMod=1.0;            // Normal and below

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
    return Clamp(SoloNormalCounter * DifficultyMod * NumPlayersMod, 1, ScrnBalanceMut.MaxWaveSize);
}

function SetupWave()
{
    local byte WaveIndex;
    local int i;
    local bool bOneMessage;
    local Controller C;
    local InvasionBot B;

    UpdateMonsterCount();

    bWaveInProgress = true;
    ScrnGRI.bWaveInProgress = true;

    // auto lock teams
    if ( (WaveNum+1) == RelativeWaveNum(ScrnBalanceMut.LockTeamAutoWave) )
        LockTeams();

    NextMonsterTime = Level.TimeSeconds + 5.0 + 3.0 * frand();
    TraderProblemLevel = 0;
    rewardFlag=false;
    ZombiesKilled=0;
    WaveMonsters = 0;
    WaveNumClasses = 0;
    WavePlayerCount = AlivePlayerCount;
    ZedSpawnLoc = ZSLOC_AUTO;

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
        TotalMaxMonsters = ScrnGameLength.GetWaveZedCount() + NumMonsters;
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

    for( i = 0; i < ZedSpawnList.Length; ++i )
        ZedSpawnList[i].Reset();

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
    local int i;

    // reset spawn volumes
    LastZVol = none;
    LastSpawningVolume = none;
    FinalSquadNum = 0;
    NextMonsterTime = Level.TimeSeconds;
    bBossSpawned = false;

    for( i = 0; i < ZedSpawnList.Length; ++i )
        ZedSpawnList[i].Reset();
    WaveEndTime = Level.TimeSeconds+60;

    if ( ScrnGameLength == none ) {
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
        ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
        log("Boss Squad: " $ ZedSquadToString(NextSpawnSquad), class.name);
    }

    if ( NextSpawnSquad.length == 0 ) {
        Broadcast(Self,"Game ended due to lack of bosses");
        EndGame(None,"TimeLimit");
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

    if( LastZVol == none )
    {
        LastZVol = FindSpawningVolume(false, true);
        if( LastZVol == none ) {
            LastZVol = FindSpawningVolume(true, true);
            if( LastZVol == none ) {
                log("Couldn't find a place for the Boss "$ZedSquadToString(NextSpawnSquad)$" after 2 tries, trying again later!", class.name);
                TryToSpawnInAnotherVolume(true);
                return false;
            }
        }
    }
    LastSpawningVolume = LastZVol;
    if( SpawnSquad(LastZVol, NextSpawnSquad, true) > 0 ) {
        WaveEndTime += 120;
        if ( NextSpawnSquad.length == 0 ) {
            bBossSpawned = true;
            NextMonsterTime = Level.TimeSeconds + 99999; // never (wait for AddBossBuddySquad)
            WaveEndTime += 3600;
        }
        else {
            NextMonsterTime =  Level.TimeSeconds + 0.2;
        }
        return true;
    }
    else {
        log("Failed to spawn the Boss: "$ZedSquadToString(NextSpawnSquad), class.name);
        TryToSpawnInAnotherVolume(true);
        return false;
    }
}

// Override of ZombieVolume.SpawnInHere() fixing a lot of Tripwire's crap.
// Checks (zombies flags etc.) removed because they already have been made in FindSpawningVolume().
// Function assumes that entire NextSpawnSquad can be spawned here
function int SpawnSquad(ZombieVolume ZVol, out array< class<KFMonster> > Squad, optional bool bLogSpawned )
{
    local int i, j, numspawned;
    local rotator RandRot;
    local KFMonster M;

    if ( ZVol == none ) {
        log("Unable to spawn squad: Zombie volume is not set", class.name);
        return 0;
    }
    if ( ZVol.SpawnPos.length == 0 ) {
        log("Zombie volume is not set: "$ZVol.name$" has no spawn points", class.name);
        return 0;
    }

    for ( i = 0; i < Squad.Length && NumMonsters < MaxMonsters && TotalMaxMonsters > 0; ++i ) {
        if ( !CanSpawnInVolume(Squad[i], ZVol) )
            continue;
        RandRot.Yaw = Rand(65536);
        for ( M = none; M == none && j < ZVol.SpawnPos.length; ++j ) {
            if ( !ZVol.bAllowPlainSightSpawns && PlayerCanSeeSpawnPoint(ZVol.SpawnPos[j], Squad[i]) )
                continue;

            M = Spawn(Squad[i],,ZVol.ZombieSpawnTag,ZVol.SpawnPos[j],RandRot);
            if ( M == none )
                continue;
            OverrideMonsterHealth(M);
            ScrnBalanceMut.GameRules.ReinitMonster(M);

            M.Event = ZVol.ZombieDeathEvent;
            if ( ZVol.ZombieSpawnEvent != '' )
                TriggerEvent(ZVol.ZombieSpawnEvent, ZVol, M);
            ZVol.AddZEDToSpawnList(M);

            --TotalMaxMonsters;
            ++NumMonsters;
            ++WaveMonsters;
            ++numspawned;
            Squad.remove(i--, 1);

            if ( bLogSpawned || LogZedSpawn >= 7 )
                log("Zed spawned: "$M.class, class.name);
        }
    }

    if ( LogZedSpawn >= 3 && Squad.Length > 0 ) {
        log("Spawned " $ numspawned $ " of " $ string(numspawned + Squad.Length) $ " in " $ ZVol.name, class.name);
        if ( LogZedSpawn >= 7 || (LogZedSpawn >= 4 && Squad.Length <= 8) ) {
            log("Remaining: " $ ZedSquadToString(Squad), class.name);
        }
    }

    if( numspawned>0 ) {
        ZVol.LastSpawnTime = Level.TimeSeconds;
        ZVol.LastFailedSpawnTime = 0;
    }
    else {
        ZVol.LastFailedSpawnTime = Level.TimeSeconds;
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

function bool PlayerCanSeeSpawnPoint(vector SpawnLoc, class <KFMonster> TestMonster)
{
    local Controller C;
    local vector Right, Test, PlayerLoc;

    // Now make sure no player sees the spawn point.
    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if( C.Pawn != none && C.bIsPlayer && C.Pawn.Health > 0 ) {
            PlayerLoc = C.Pawn.Location + C.Pawn.EyePosition();
            if ( C.Pawn.Region.Zone.bDistanceFog && VSize(SpawnLoc - PlayerLoc) > C.Pawn.Region.Zone.DistanceFogEnd )
                continue; // SpawnLoc is in fog

            Right = ((SpawnLoc - C.Pawn.Location) cross vect(0.f,0.f,1.f));
            Right = Normal(Right) * TestMonster.Default.CollisionRadius * 1.1;
            Test = SpawnLoc;
            Test.Z += TestMonster.Default.CollisionHeight * 1.25;

            // Do three traces, one to the location, and one slightly above left and right of the collision
            // cylinder size so we don't see this zed spawn
            if( FastTrace(SpawnLoc, PlayerLoc)
                || FastTrace(Test + Right, PlayerLoc)
                || FastTrace(Test - Right, PlayerLoc) )
            {
                return true;
            }
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

// ==================================== STATES ===============================
auto State PendingMatch
{
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

        if ( ScrnGameLength != none ) {
            if (!ScrnGameLength.LoadWave(WaveNum)) {
                DoWaveEnd();
            }
            else {
                WaveCountDown = max(10, ScrnGameLength.Wave.TraderTime);
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

        if ( TotalMaxMonsters<=0 ) {
             // all monsters spawned
            if ( ScrnGameLength == none && NumMonsters <= 0 )
                DoWaveEnd();
            else if ( NumMonsters <= 5 )
                KillRemainingZeds(false);
        }
        else if ( Level.TimeSeconds > NextMonsterTime
                && NumMonsters < MaxMonsters
                && (NumMonsters+NextSpawnSquad.Length <= MaxMonsters || MaxMonsters <= 10) )
        {
            if ( ScrnGameLength != none )
                WaveEndTime = ScrnGameLength.WaveEndTime;
            else
                WaveEndTime = Level.TimeSeconds + 60;

            if( !bDisableZedSpawning )
                AddSquad();

            if( NextSpawnSquad.length > 0 )
                NextMonsterTime = Level.TimeSeconds + 0.2;
            else
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
            if ( !bBossSpawned )
                AddBoss();
            else if ( !bDisableZedSpawning ) {
                AddSquad();
                if ( NextSpawnSquad.length > 0 )
                    NextMonsterTime = Level.TimeSeconds + 0.2;
                else
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
                BroadcastLocalizedMessage(class'ScrnBalanceSrv.ScrnWaitingMessage', 3);
            else
                BroadcastLocalizedMessage(class'ScrnBalanceSrv.ScrnWaitingMessage', 1);
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
            Return;
        }
        if ( SuicideTime > 0 && ElapsedTime > SuicideTime ) {
            class'ScrnSuicideBomb'.static.ExplodeAll(Level);
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
            else if ( TotalMaxMonsters <= 0 && NumMonsters <= 0 )
            {
                if ( WaveNum > FinalWave || (!bUseEndGameBoss && WaveNum == FinalWave) ) {
                    EndGame(None,"TimeLimit");
                    return;
                }
                TraderTimer();
            }
        }
    }

    event Tick(float DeltaTime)
    {
        global.Tick(DeltaTime);

        if ( bWaveInProgress && !bWaveBossInProgress
                && !bDisableZedSpawning && TotalMaxMonsters > 0
                && Level.TimeSeconds > NextMonsterTime
                && NumMonsters+NextSpawnSquad.Length <= MaxMonsters )
        {
                AddSquad();
                if( NextSpawnSquad.length > 0 )
                    NextMonsterTime = Level.TimeSeconds + 0.2;
                else
                    NextMonsterTime = Level.TimeSeconds + CalcNextSquadSpawnTime();
        }
    }

    function float CalcNextSquadSpawnTime()
    {
        local float NextSpawnTime;

        NextSpawnTime = fclamp(KFLRules.WaveSpawnPeriod, 0.2, BoringStages[BoringStage].SpawnPeriod);
        NextSpawnTime /= 1.0 + (AlivePlayerCount - 1) * SpawnRatePlayerMod;
        if ( GameDifficulty < 4 && NumMonsters >= 16 ) {
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
        }

        return fmax(NextSpawnTime, GetMinSpawnDelay());
    }

    function float GetMinSpawnDelay()
    {
        local float result;

        result = BoringStages[BoringStage].MinSpawnTime;
        if ( ScrnGameLength != none )
            result /= ScrnGameLength.Wave.SpawnRateMod;
        return result;
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

        if ( WaveNum > FinalWave || (!bUseEndGameBoss && WaveNum == FinalWave) ) {
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
                    KFPRI.Score = Max(MinRespawnCash, KFPRI.Score);
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
            BroadcastLocalizedMessage(class'ScrnBalanceSrv.ScrnWaitingMessage', 2);
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
}

defaultproperties
{
    GameName="ScrN Floor"
    Description="ScrN Edition of Killing Floor game mode (KFGameType)."

    GameReplicationInfoClass=Class'ScrnBalanceSrv.ScrnGameReplicationInfo'

    PathWhisps(0)="KFMod.RedWhisp"
    PathWhisps(1)="KFMod.RedWhisp"

    bSingleTeamGame=True
    bUseEndGameBoss=True
    ZedSpawnLoc=ZSLOC_AUTO
    TurboScale=1.0
    bKillMessages=true
    bZedTimeEnabled=true
    bAntiBlocker=true

    LogZedSpawn=2  // log errors and warnings by default
    MaxSpawnAttempts=3
    MaxSpecialSpawnAttempts=10
    SpawnRatePlayerMod=0.25
    BoringStages[0]=(SpawnPeriod=3.0,MinSpawnTime=1.5)  // SpawnPeriod may be further limited by KFLevelRules
    BoringStages[1]=(SpawnPeriod=1.0,MinSpawnTime=1.0)
    BoringStages[2]=(SpawnPeriod=0.5,MinSpawnTime=0.5)
    BoringStages[3]=(SpawnPeriod=0.25,MinSpawnTime=0.25)
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
