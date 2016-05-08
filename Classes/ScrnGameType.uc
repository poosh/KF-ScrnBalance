// made to fix KFStoryGameInfo loading for KFO maps
class ScrnGameType extends KFGameType;

var ScrnBalance ScrnBalanceMut;
var bool bCloserZedSpawns; // if true uses modified RateZombieVolume() function to get closer volumes for zeds
var private string CmdLine;


var private int TourneyMode;


//var const protected array< class<Pickup> > CheatPickups; // disallowed pickups in tourney mode

event InitGame( string Options, out string Error )
{
    local int ConfigMaxPlayers;
    
    CmdLine = Options;
    
    KFGameLength = GetIntOption(Options, "GameLength", KFGameLength);
    if ( KFGameLength < 0 || KFGameLength > 3) {
        log("GameLength must be in [0..3]: 0-short, 1-medium, 2-long, 3-custom");
        KFGameLength = GL_Long;
    }
    
    TourneyMode = GetIntOption(Options, "Tourney", TourneyMode);
    PreStartTourney(TourneyMode);
    
    ConfigMaxPlayers = default.MaxPlayers;
    super.InitGame(Options, Error);
    MaxPlayers = Clamp(GetIntOption( Options, "MaxPlayers", ConfigMaxPlayers ),0,32);
    default.MaxPlayers = Clamp( ConfigMaxPlayers, 0, 32 );
    
    log("MonsterCollection = " $ MonsterCollection);
    
    if ( TourneyMode > 0 )
        StartTourney();
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

function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    local KFPlayerController PC;

    if ( KFPawn(Injured) != none )
    {
        if ( KFPlayerReplicationInfo(Injured.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Injured.PlayerReplicationInfo).ClientVeteranSkill != none )
        {
            Damage = KFPlayerReplicationInfo(Injured.PlayerReplicationInfo).ClientVeteranSkill.Static.ReduceDamage(KFPlayerReplicationInfo(Injured.PlayerReplicationInfo), KFPawn(Injured), instigatedBy, Damage, DamageType);
        }
    }

    if ( instigatedBy == None || DamageType == class'DamTypeVomit' || DamageType == class'DamTypeWelder' || DamageType == class'SirenScreamDamage' )
    {
        return Super(xTeamGame).ReduceDamage( Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
    }

    if ( Monster(Injured) != None )
    {
        if ( instigatedBy != None )
        {
            PC = KFPlayerController(instigatedBy.Controller);
            if ( Class<KFWeaponDamageType>(damageType) != none && PC != none )
            {
                Class<KFWeaponDamageType>(damageType).Static.AwardDamage(KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements), Clamp(Damage, 1, Injured.Health));
            }
        }

        return super(UnrealMPGameInfo).ReduceDamage( Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType );
    }

    if ( KFFriendlyAI(InstigatedBy.Controller) != None && KFHumanPawn(Injured) != none  )
        Damage *= 0.25;
    else if ( injured == instigatedBy )
        Damage = Damage * 0.5;


    if ( InvasionBot(injured.Controller) != None )
    {
        if ( !InvasionBot(injured.controller).bDamagedMessage && (injured.Health - Damage < 50) )
        {
            InvasionBot(injured.controller).bDamagedMessage = true;
            if ( FRand() < 0.5 )
                injured.Controller.SendMessage(None, 'OTHER', 4, 12, 'TEAM');
            else injured.Controller.SendMessage(None, 'OTHER', 13, 12, 'TEAM');
        }
        if ( GameDifficulty <= 3 )
        {
            if ( injured.IsPlayerPawn() && (injured == instigatedby) && (Level.NetMode == NM_Standalone) )
                Damage *= 0.5;

            //skill level modification
            if ( MonsterController(InstigatedBy.Controller) != None )
                Damage = Damage;
        }
    }

    if( injured.InGodMode() )
        return 0;
    if( instigatedBy!=injured && MonsterController(InstigatedBy.Controller)==None && (instigatedBy.Controller==None || instigatedBy.GetTeamNum()==injured.GetTeamNum()) )
    {
        if ( class<WeaponDamageType>(DamageType) != None || class<VehicleDamageType>(DamageType) != None )
            Momentum *= TeammateBoost;
        if ( Bot(injured.Controller) != None )
            Bot(Injured.Controller).YellAt(instigatedBy);

        if ( FriendlyFireScale==0.0 || (Vehicle(injured) != None && Vehicle(injured).bNoFriendlyFire) )
        {
            if ( GameRulesModifiers != None )
                return GameRulesModifiers.NetDamage( Damage, 0,injured,instigatedBy,HitLocation,Momentum,DamageType );
            else return 0;
        }
        Damage *= FriendlyFireScale;
    }

    // Start code from DeathMatch.uc - Had to override this here because it was reducing
    // bite damage (which is 1) down to zero when the skill settings were low

    if ( (instigatedBy != None) && (InstigatedBy != Injured) && (Level.TimeSeconds - injured.SpawnTime < SpawnProtectionTime)
        && (class<WeaponDamageType>(DamageType) != None || class<VehicleDamageType>(DamageType) != None) )
        return 0;

    Damage = super(UnrealMPGameInfo).ReduceDamage( Damage, injured, InstigatedBy, HitLocation, Momentum, DamageType );

    if ( instigatedBy == None)
        return Damage;

    if ( Level.Game.GameDifficulty <= 3 )
    {
        if ( injured.IsPlayerPawn() && (injured == instigatedby) && (Level.NetMode == NM_Standalone) )
            Damage *= 0.5;
    }
    return (Damage * instigatedBy.DamageScaling);
    // End code from DeathMatch.uc
}

// removed checks for steam achievements
function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local KFPlayerReplicationInfo KFPRI;
    local KFSteamStatsAndAchievements StatsAndAchievements;

    if ( PlayerController(Killer) != none ) {
        KFPRI = KFPlayerReplicationInfo(Killer.PlayerReplicationInfo);
        if ( KFMonster(KilledPawn) != None && Killed != Killer ) {
            if ( bZEDTimeActive && KFPRI != none && KFPRI.ClientVeteranSkill != none 
                    && KFPRI.ClientVeteranSkill.static.ZedTimeExtensions(KFPRI) > ZedTimeExtensionsUsed )
            {
                // Force Zed Time extension for every kill as long as the Player's Perk has Extensions left
                DramaticEvent(1.0);

                ZedTimeExtensionsUsed++;
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
                if ( class<KFWeaponDamageType>(damageType) != none ) {
                    class<KFWeaponDamageType>(damageType).Static.AwardKill(StatsAndAchievements,KFPlayerController(Killer),KFMonster(KilledPawn));
                }
                
                StatsAndAchievements.AddKill(false, false, false, false, false, false, false, false, false, "");
            }

        }
    }

    if ( (MonsterController(Killed) != None) || (Monster(KilledPawn) != None) )
    {
        ZombiesKilled++;
        KFGameReplicationInfo(GameReplicationInfo).MaxMonsters = Max(TotalMaxMonsters + NumMonsters - 1,0);
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
                    if ( Level.NetMode != NM_Standalone || Killer.Pawn == none || KFGameReplicationInfo(GameReplicationInfo).CurrentShop == none ||
                         VSizeSquared(Killer.Pawn.Location - KFGameReplicationInfo(GameReplicationInfo).CurrentShop.Location) > 2250000 ) // 30 meters
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

exec function KillZeds()
{
    local KFMonster M;
    local array <KFMonster> Monsters;
    local Controller PC;
    local int i;

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
    
    PC = Level.GetLocalPlayerController();
    for ( i=0; i<Monsters.length; ++i )
        Monsters[i].Died(PC, class'DamageType', M.Location);
}


// Calculate spawning cost.
// Bug Fixes by PooSH:
// - Dead players do not lower distance score
function float RateZombieVolume(ZombieVolume ZVol, Controller SpawnCloseTo, optional bool bIgnoreFailedSpawnTime, optional bool bBossSpawning)
{
	local Controller C;
	local float Score;
	local float DistSquared, MinDistanceToPlayerSquared;
	local byte i;
	local float PlayerDistScoreZ, PlayerDistScoreXY, TotalPlayerDistScore, UsageScore;
	local vector LocationXY, TestLocationXY;
	local bool bTooCloseToPlayer;

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
    
    // can this volume spawn this squad?
	if( !ZVol.CanSpawnInHere(NextSpawnSquad) )
    	return -1;


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
    
    // Start score with Spawn desirability
	Score = ZVol.SpawnDesirability;
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
    
	// Tripwire: Spawning score is 30% SpawnDesirability, 30% Distance from players, 30% when the spawn was last used, 10% random
    // PooSH: Distance now is more important than time to prevent far spawns as much as possible
    // PooSH: and somebody should learn basic math...
    Score *= 0.30 + 0.35*TotalPlayerDistScore + 0.25*UsageScore + 0.1*frand();
    
    if( bTooCloseToPlayer )
        Score*=0.2;

	// Try and prevent spawning in the same volume back to back
    if( LastSpawningVolume == ZVol )
		Score*=0.2;

	// if we get here, return at least a 1
	return fmax(Score,1);
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

// added ZombieFlag check  -- PooSH
function ZombieVolume FindSpawningVolume(optional bool bIgnoreFailedSpawnTime, optional bool bBossSpawning)
{
    local ZombieVolume BestZ, CurZ;
    local float BestScore,tScore;
    local int i,j;
    local Controller C;
    local bool bCanSpawnAll;
    local byte ZombieFlag;

    // First pass, pick a random player.
    C = FindSquadTarget();
    if( C==None )
        return None; // This shouldn't happen. Just to be sure...

    // Second pass, figure out best spawning point.
    for( i=0; i<ZedSpawnList.Length; i++ ) {
        CurZ = ZedSpawnList[i];
        // check if it can spawn all zeds in the squad  -- PooSH
        if ( !CurZ.bNormalZeds || !CurZ.bRangedZeds || !CurZ.bLeapingZeds || !CurZ.bMassiveZeds ) {
            bCanSpawnAll = true;
            for ( j=0; bCanSpawnAll && j<NextSpawnSquad.length; ++j ) {
                ZombieFlag = NextSpawnSquad[j].default.ZombieFlag; 
                if( (!CurZ.bNormalZeds && ZombieFlag==0) 
                    || (!CurZ.bRangedZeds && ZombieFlag==1) 
                    || (!CurZ.bLeapingZeds && ZombieFlag==2) 
                    || (!CurZ.bMassiveZeds && ZombieFlag==3) )
                {
                    bCanSpawnAll = false;
                }
            }
            if ( !bCanSpawnAll )
                continue;
        }
        
        if ( bCloserZedSpawns )
            tScore = RateZombieVolume(CurZ,C,bIgnoreFailedSpawnTime, bBossSpawning);
        else
            tScore = CurZ.RateZombieVolume(Self,LastSpawningVolume,C,bIgnoreFailedSpawnTime, bBossSpawning);
            
        if( tScore > BestScore || (BestZ == None && tScore > 0) ) {
            BestScore = tScore;
            BestZ = CurZ;
        }
    }
    // just in case when map contains only zed-specific volumes  -- PooSH
    if ( BestZ == none )
        return super.FindSpawningVolume(bIgnoreFailedSpawnTime, bBossSpawning);
    
    return BestZ;
}

// reserved for TSC
function bool ShouldKillOnTeamChange(Pawn TeamChanger)
{
    return true;
}

function ShowPathTo(PlayerController P, int TeamNum)
{
    local ShopVolume shop;
    local class<WillowWhisp>	WWclass;
    
    if ( TSCGameReplicationInfoBase(GameReplicationInfo) != none )
        shop = TSCGameReplicationInfoBase(GameReplicationInfo).GetPlayerShop(P.PlayerReplicationInfo);
    else 
        shop = KFGameReplicationInfo(GameReplicationInfo).CurrentShop;
        
    if( shop == none )
        return;

    if ( !shop.bTelsInit )
        shop.InitTeleports();
    
    // take TeamNum from PRI, because KFMod hard-codes it to 0
    TeamNum = P.PlayerReplicationInfo.Team.TeamIndex;
        
    if ( shop.TelList[0] != None && P.FindPathToward(shop.TelList[0], false) != None ) {
		WWclass = class<WillowWhisp>(DynamicLoadObject(PathWhisps[TeamNum], class'Class'));
		Spawn(WWclass, P,, P.Pawn.Location);    
    }
}

// entire C&P from parent classes to clear garbage
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
    if ( TourneyMode > 0 )
        AddServerDetail( ServerState, "ScrN Tourney Mode", TourneyMode );
}

// Called before spawning mutators.
// This is the only place where TourneyMode can be changed by descendants.
protected function PreStartTourney(out int TourneyMode) 
{
}

// called at the end of InitGame(), when mutators have been spawned already
protected function StartTourney() 
{ 
    local bool bVanilla, bNoStartCash;

    log("Starting TOURNEY MODE " $ TourneyMode, 'ScrnBalance');
    bVanilla = (TourneyMode&2) > 0;
    bNoStartCash = (TourneyMode&4) > 0;
    
    if ( GameDifficulty < 4 ) {
        // hard difficulty at least
        GameDifficulty = 4; 
        KFGameReplicationInfo(GameReplicationInfo).GameDiff = GameDifficulty;
        ScrnBalanceMut.SetLevels();
    }
    ScrnBalanceMut.SrvTourneyMode = TourneyMode;
    ScrnBalanceMut.bSpawnBalance = !bVanilla;
    ScrnBalanceMut.bWeaponFix = !bVanilla;
    ScrnBalanceMut.bAltBurnMech = !bVanilla;
    ScrnBalanceMut.bReplacePickups = !bVanilla;
    ScrnBalanceMut.bNoRequiredEquipment = false;
    ScrnBalanceMut.bForceManualReload = false;
    ScrnBalanceMut.bDynamicLevelCap = false;

    ScrnBalanceMut.bAlterWaveSize = true;
    ScrnBalanceMut.MaxWaveSize = 500;
    ScrnBalanceMut.Post6ZedsPerPlayer = 0.4;
    ScrnBalanceMut.Post6ZedSpawnInc=0.25;
    ScrnBalanceMut.Post6AmmoSpawnInc=0.20;
    //ScrnBalanceMut.FakedPlayers = 6;
    
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
    return TourneyMode > 0;
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
    local bool bVanillaTourney;
    local class<Pickup> PC;
    
    if ( R == none )
        return; // wtf?
    
    if ( TourneyMode > 0 ) {
        bVanillaTourney = (TourneyMode&2)  > 0;
        // allow only stock or SE weapons in tourney mode
        for ( i=R.ShopInventory.length-1; i>=0; --i ) {
            PC = R.ShopInventory[i].PC;
            if ( PC == none || PC == class'ScrnHorzineVestPickup' || PC == class'ZEDMKIIPickup'
                    || (PC.outer.name != 'KFMod' && (bVanillaTourney || PC.outer.name != 'ScrnBalanceSrv')) )
                R.ShopInventory.remove(i, 1);
        }
        // allow only ScrN Perks
        for ( i=R.CachePerks.length-1; i>=0; --i ) {
            if ( R.CachePerks[i].PerkClass.outer.name != 'ScrnBalanceSrv' )
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
    
    if ( ScrnPlayerController(NewPlayer) != none )
        ScrnPlayerController(NewPlayer).PostLogin();
}


// STATES


auto State PendingMatch
{
    // overrided to require at least 1 player to be ready to start LobbyTimeout
    function Timer()
    {
        local Controller P;
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

        for ( P = Level.ControllerList; P != None; P = P.NextController )
        {
            if ( P.IsA('PlayerController') && P.PlayerReplicationInfo != none && P.bIsPlayer && P.PlayerReplicationInfo.Team != none &&
                P.PlayerReplicationInfo.bWaitingPlayer && !P.PlayerReplicationInfo.bOnlySpectator)
            {
                PlayerCount++;

                if ( !P.PlayerReplicationInfo.bReadyToPlay )
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
                for ( P = Level.ControllerList; P != None; P = P.NextController )
                {
                    if ( P.IsA('PlayerController') && P.PlayerReplicationInfo != none )
                        P.PlayerReplicationInfo.bReadyToPlay = True;
                }

                LobbyTimeout = 0;
            }
            else
            {
                LobbyTimeout--;
            }

            KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = LobbyTimeout;
        }
        else
        {
            KFGameReplicationInfo(GameReplicationInfo).LobbyTimeout = -1;
        }
    }
}

defaultproperties
{
    GameName="ScrN Floor"
    
    Description="ScrN Edition of Killing Floor game mode (KFGameType)."
    
    PathWhisps(0)="KFMod.RedWhisp"
    PathWhisps(1)="KFMod.RedWhisp"
    
    bCloserZedSpawns=True
    
    
    KFHints[0]="ScrN Balance: You can reload a single shell into Hunting Shotgun."
    KFHints[1]="ScrN Balance: You can't skip Hunting Shotgun's reload. So use it with caution."
    KFHints[2]="ScrN Balance: Combat Shotgun is made much better. Give it a try."
    KFHints[3]="ScrN Balance: Shotguns, except Combat and Hunting, penetrate fat bodies worse than small enemies."
    KFHints[4]="ScrN Balance: M99 can't stun Scrake with a body-shot. Crossbow has no fire speed bonus as in original game before v1035."
    KFHints[5]="ScrN Balance: M14EBR has different laser sights. Choose the color you like!"
    KFHints[6]="ScrN Balance: Hand grenades can be 'cooked'. You can enable this on 'Scrn Balance' settings page in the Main Menu."
    KFHints[7]="ScrN Balance: Husk Gun's secondary fire acts as Napalm Thrower. You should definitely try it out!"
    KFHints[8]="ScrN Balance: Gunslinger has bonuses both for single and dual pistols. But real Cowboys use only dualies."
    KFHints[9]="ScrN Balance: Gunslinger becomes a Cowboy while using dual pistols without wearing an armor (except jacket). Cowboy moves, shoots and reloads his pistols much faster. From the other side, he dies faster too.."
    KFHints[10]="ScrN Balance: Berserker, while holding non-melee weapons, moves slower than other perks."
    KFHints[11]="ScrN Balance: Chaisaw's secondary fire can stun Scrakes the same way as an Axe."
    KFHints[12]="ScrN Balance: Chainsaw consumes fuel. Raised power makes it a beast... until you need to refill"
    KFHints[13]="ScrN Balance: Medic, while holding a syringe, runs same fast as while holding a knife."
    KFHints[14]="ScrN Balance: Medics can heal much faster than other perks. If you aren't a Medic, don't screw up the healing process with your lame injection."
    KFHints[15]="ScrN Balance: FN-FAL has bullet penetration and 2-bullet fixed burst mode."
    KFHints[16]="ScrN Balance: MK23 has no bullet penetration but double size of magazine, comparing to Magnum .44"
    KFHints[17]="ScrN Balance: Your experience and perk bonus levels can be different. If they are, you'll see 2 perk icons on your HUD."
    KFHints[18]="ScrN Balance: If you see two perk icons on your HUD, left one shows your experience level, right - actual level of perk bonuses you gain."
    KFHints[19]="ScrN Balance: Flare pistol has an incremental burn DoT (iDoT). The more you shoot the more damage zeds take from burning."
    KFHints[20]="ScrN Balance: Medic nades are for healing only. Zeds are not taking damage neither fear them"
    KFHints[21]="ScrN Balance: If you have just joined the game and got blamed - maybe it is just a welcome gift. Don't worry - shit happens."
    KFHints[22]="ScrN Balance: Nailgun can nail enemies to walls... nail them alive! Crucify your ZED!"
    KFHints[23]="ScrN Console Command: TOGGLEPLAYERINFO - hides health bars while keeping the rest of the HUD."
    KFHints[24]="ScrN Console Command: MVOTE - access to ScrN Voting. Type MVOTE HELP for more info."
    KFHints[25]="ScrN Console Command: DROPALLWEAPONS - drops all your weapons to the ground. What else did you expected?"
    KFHints[26]="ScrN Console Command: TOGGLEWEAPONLOCK - lock/unlocks your weapons on the ground."
}