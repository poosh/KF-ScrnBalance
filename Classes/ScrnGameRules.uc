class ScrnGameRules extends GameRules
    Config(ScrnBalance);

var ScrnBalance Mut;
var KFGameType KF;


var bool bShowDamages;

var int HardcoreLevel;
var float HardcoreLevelFloat;
var localized string msgHardcore;
var bool bUseAchievements;

var bool bScrnDoom; // is serrver running ScrN version of Doom3 mutator?
var localized string msgDoom3Monster, msgDoomPercent, msgDoom3Boss;
var transient int WaveTotalKills, WaveDoom3Kills;
var transient int DoomHardcorePointsGained;

// var class<KFMonster> ShiverClass, BruteClass, JasonClass, FemaleFPClass, TeslaHuskClass, GhostClass;
// var class<KFMonster> SuperFPClass, SuperScrakeClass, SuperHuskClass;
var transient bool bHasCustomZeds;

var class<KFMonster> BossClass;
var KFMonster Boss;
var transient bool bSuperPat, bDoomPat, bFemaleFP;
var bool bFinalWave; // is this a final wave


// Damage flags
const DF_STUNNED   = 0x01; // stun shot
const DF_RAGED     = 0x02; // rage shot
const DF_STUPID    = 0x04; // damage shouldn't be done to this zed
const DF_DECAP     = 0x08; // decapitaion shot
const DF_HEADSHOT  = 0x10; // 100% sure that this damage was made by headshot

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
    var int DamageFlags1, DamageFlags2;
    var bool TW_Ach_Failed; //if true, no TeamWork achievements can be earned on this zed
	
	var bool bHeadshot; // was last damage from headshot?
	var int RowHeadshots; // headshots in a row done to this monster. RowHeadshots doesn't reset after decapitation
	var int Headshots; // number of headshots made to this monster
	var int BodyShots; // number of bodyshots made to this monster by weapons, which can score headshots
	var int OtherHits; // number of hits made to this monster by weapons, which can NOT score headshots

	// variables below are set after NetDamage() call
	var float LastHitTime; // time when Monster took last damage
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
var array<MapAlias> MapAliases;

var array< class<KFMonster> > CheckedMonsterClasses;

var array<ScrnAchHandlerBase> AchHandlers;
var ScrnPlayerInfo PlayerInfo;

var class<ScrnAchievements> AchClass;
var class<ScrnMapAchievements> MapAchClass;

var localized string strWeaponLocked, strWeaponLockedOwn;
var localized string strWaveAccuracy;


function PostBeginPlay()
{
    if( Level.Game.GameRulesModifiers==None )
        Level.Game.GameRulesModifiers = Self;
    else Level.Game.GameRulesModifiers.AddGameRules(Self);
    
    Mut = ScrnBalance(Owner);
    KF = KFGameType(Level.Game);
    
    MonsterInfos.Length = Mut.KF.MaxZombiesOnce; //reserve a space that will be required anyway
    
    // Hardcore Level: 4 points on HoE, 2 - on Suicidal
    if ( Level.Game.GameDifficulty >= 7 )
       HardcoreLevel = 4; //hoe
    else if ( Level.Game.GameDifficulty >= 5 )
       HardcoreLevel = 2; //sui
    else if ( Level.Game.GameDifficulty >= 4 )
       HardcoreLevel = -1; //hard
    else 
        HardcoreLevel = -4; // Soft Pussy Mode
		
    if ( Mut.bHardcore )
		HardcoreLevel += 2; // 2 extra hardcore points in hardcore mode
        
	if ( Mut.bStoryMode )
		HardcoreLevel += 3; // 3 extra hardcore points for playing objective mode
    else if ( Mut.bTSCGame )
		HardcoreLevel += 6; // 6 extra hardcore points for playing Team Survival Competition (-2 in v8)
        
    // + 3 points if perk levels are limited to 6, +1 point per each level limited below 6
    if ( Mut.MaxLevel < 9  )
        HardcoreLevel += 9 - Mut.MaxLevel;
        
    HardcoreLevelFloat = HardcoreLevel;
}


function AddGameRules(GameRules GR)
{
    if ( GR!=Self ) //prevent adding same rules more than once
        Super.AddGameRules(GR);
}


// more players = faster zed spawn
function AdjustZedSpawnRate()
{
	local int PlayerCount;
	
	if ( Mut.bStoryMode )
		return;
		
	Mut.KF.KFLRules.WaveSpawnPeriod = Mut.OriginalWaveSpawnPeriod;
	
    // TSC adjusts spawn period itself
    if ( !Mut.bTSCGame ) {
        PlayerCount = AlivePlayerCount();
        if ( PlayerCount > 6 ) 
            Mut.KF.KFLRules.WaveSpawnPeriod /= 1.0 + Mut.Post6ZedSpawnInc * (PlayerCount - 6);
    }
}

function SetupWaveSize()
{
	local float NewMaxMonsters;	
	local float DifficultyMod, NumPlayersMod;
	local int UsedNumPlayers;	
	
	NewMaxMonsters = Mut.KF.Waves[min(Mut.KF.WaveNum,15)].WaveMaxMonsters;

    // scale number of zombies by difficulty
    if ( Mut.KF.GameDifficulty >= 7.0 ) // Hell on Earth
    {
    	DifficultyMod=1.7;
    }
    else if ( Mut.KF.GameDifficulty >= 5.0 ) // Suicidal
    {
    	DifficultyMod=1.5;
    }
    else if ( Mut.KF.GameDifficulty >= 4.0 ) // Hard
    {
    	DifficultyMod=1.3;
    }
    else if ( Mut.KF.GameDifficulty >= 2.0 ) // Normal
    {
    	DifficultyMod=1.0;
    }
    else //if ( GameDifficulty == 1.0 ) // Beginner
    {
    	DifficultyMod=0.7;
    }

    UsedNumPlayers = max(max(Mut.FakedPlayers,1), AlivePlayerCount() + Mut.KF.NumBots);

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
            NumPlayersMod = 4.5 + (UsedNumPlayers-6)*Mut.Post6ZedsPerPlayer; // 7+ player game
	}

    NewMaxMonsters = Clamp(NewMaxMonsters * DifficultyMod * NumPlayersMod, 5, Mut.MaxWaveSize); 
	
	Mut.KF.TotalMaxMonsters = NewMaxMonsters;  // num monsters in wave
	KFGameReplicationInfo(Mut.KF.GameReplicationInfo).MaxMonsters = NewMaxMonsters; // num monsters in wave replicated to clients
	Mut.KF.MaxMonsters = Clamp(Mut.KF.TotalMaxMonsters,5,Mut.KF.MaxZombiesOnce); // max monsters that can be spawned
}

function DestroyBuzzsawBlade()
{
    local ScrnCrossbuzzsawBlade Blade;
    
    foreach DynamicActors(class'ScrnCrossbuzzsawBlade', Blade) {
        Blade.ReplicatedDestroy();
    }
}

function WaveStarted()
{
    local int i;
    local Controller P;
    local PlayerController PC;
	local ScrnPlayerInfo SPI;
    
    WaveDoom3Kills = 0;
    WaveTotalKills = 0;   

	bFinalWave = Mut.KF.WaveNum == Mut.KF.FinalWave;
    
	ClearNonePlayerInfos();
    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        PC = PlayerController(P);
        if ( PC != none && PC.Pawn != none && PC.Pawn.Health > 0 ) {
			if ( ScrnPlayerController(PC) != none )
				ScrnPlayerController(PC).ResetWaveStats();
			SPI = CreatePlayerInfo(PC);
			if ( SPI != none ) {
				SPI.WaveStarted(Mut.KF.WaveNum);
				SPI.ProgressAchievement('Welcome', 1);
			}
		}
    }
	
	if ( !Mut.bStoryMode ) {
		AdjustZedSpawnRate();
		if ( Mut.bAlterWaveSize && !bFinalWave )
			SetupWaveSize();
	}

	for ( i=0; i<AchHandlers.length; ++i ) {
		AchHandlers[i].WaveStarted(Mut.KF.WaveNum);
	}

	if ( Mut.bStoryMode )
		log("Wave "$(Mut.KF.WaveNum+1)$" started", class.outer.name);
	else if (bFinalWave)
		log("Final wave started", class.outer.name);
	else 
		log("Wave "$(Mut.KF.WaveNum+1)$"/"$(Mut.KF.FinalWave)$" started", class.outer.name);
        
    DestroyBuzzsawBlade(); // prevent cheating
}


function WaveEnded()
{
    local int i;
    local int DoomPct, DoomHP;
    local string s;
	local ScrnPlayerInfo SPI;
	local byte WaveNum;
	local Controller P;
	local PlayerController PC;
    local float Accuracy;
	
	// KF.WaveNum already set to a next wave, when WaveEnded() has been called
	// E.g. KF.WaveNum == 1 means that first wave has been ended (wave with index 0)
	WaveNum = KF.WaveNum-1;
    
    
    // If there are >=5% of Doom3 monsters in wave, give additional 1 hardcore points
    // >=10% - 2 points
    // Do this only once in game and exclude boss wave
    if ( WaveDoom3Kills > 0 && DoomHardcorePointsGained < 4 && WaveNum < Mut.KF.FinalWave ) {
        DoomPct = WaveDoom3Kills * 100 / WaveTotalKills;
        if ( DoomPct >= 10 ) 
            DoomHP = 4;
        else if ( DoomPct >= 5 ) 
            DoomHP = 3;
        if ( DoomHP > DoomHardcorePointsGained ) {
            s = msgDoomPercent;
            ReplaceText(s, "%p", String(DoomPct));
            RaiseHardcoreLevel(DoomHP - DoomHardcorePointsGained, s);
            DoomHardcorePointsGained = DoomHP;
        }
    }
	
    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
		SPI.WaveEnded(WaveNum);
        
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
    return false;
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
        log("Calling CheckEndGame() for already ended game!", class.outer.name);
        return true;
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
        mut.BroadcastMessage("Game WON in " $ Mut.FormatTime(Level.Game.GameReplicationInfo.ElapsedTime)
            $". HL="$HardcoreLevel, true);
		// Map achievements
        MapName = Mut.KF.GetCurrentMapName(Level);
		CheckMapAlias(MapName);
        if ( !IsMapBlackListed(MapName) ) {
			Mut.bNeedToSaveStats = false;
            GiveMapAchievements(MapName);
			for ( i=0; i<AchHandlers.length; ++i )
				AchHandlers[i].GameWon(MapName);
			GiveBonusStats();
            // no need to save stats at this moment, because Level.Game.bGameEnded=False yet, 
            // i.e. ServerPerks hasn't done the final save yet
            Mut.bNeedToSaveStats = false;
			//Mut.SaveStats();
        }
    }  
	else {
        if ( Boss != none && Boss.Health > 0 )
            mut.BroadcastMessage(Boss.MenuName $ "'s HP = " $ Boss.Health $" / " $ int(Boss.HealthMax) 
                $ " ("$100.0*Boss.Health/Boss.HealthMax$"%)");
                
        mut.BroadcastMessage("Game LOST in " $ Mut.FormatTime(Level.Game.GameReplicationInfo.ElapsedTime)
            $ " @ wave "$(Mut.KF.WaveNum+1)
            $", HL="$HardcoreLevel, true);
    }

    return true;
}

function GiveMapAchievements(optional String MapName)
{
    local bool bCustomMap, bGiveHardAch, bGiveSuiAch, bGiveHoeAch;
	local ScrnPlayerInfo SPI;
	local SRStatsBase Stats;
    
	if ( Mut.bStoryMode ) {
		bGiveHardAch = Level.Game.GameDifficulty >= 4;
		bGiveSuiAch = Level.Game.GameDifficulty >= 5;
		bGiveHoeAch = Level.Game.GameDifficulty >= 7; 	
	}
	else {
		bGiveHardAch = HardcoreLevel >= 5 && HasCustomZeds();
		bGiveSuiAch = HardcoreLevel >= 10 && (bDoomPat || bSuperPat);
		bGiveHoeAch = HardcoreLevel >= 15 && DoomHardcorePointsGained > 0;    
	}
    
    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
		if ( SPI.PlayerOwner == none || SPI.PlayerOwner.PlayerReplicationInfo == none )
			continue;
			
		Stats = SRStatsBase(SPI.PlayerOwner.SteamStatsAndAchievements);
		if ( Stats == none )
			continue;
            
        if ( Level.GRI.Winner != none && Level.GRI.Winner != SPI.PlayerOwner.PlayerReplicationInfo 
                && Level.GRI.Winner != SPI.PlayerOwner.PlayerReplicationInfo.Team )
            continue; // skip losers
			
		// additional achievements that are granted only when surviving the game
		if ( ScrnPlayerController(SPI.PlayerOwner) != none && !ScrnPlayerController(SPI.PlayerOwner).bChangedPerkDuringGame )
			SPI.ProgressAchievement('PerkFavorite', 1);  

		//unlock "Normal" achievement and see if the map is found
		bCustomMap = MapAchClass.static.UnlockMapAchievement(Stats.Rep, MapName, 0) == -2;  
		if ( bCustomMap ) {
			//map not found - progress custom map achievements
			if ( bGiveHardAch )
				AchClass.static.ProgressAchievementByID(Stats.Rep, 'WinCustomMapsHard', 1);  
			if ( bGiveSuiAch )
				AchClass.static.ProgressAchievementByID(Stats.Rep, 'WinCustomMapsSui', 1);  
			if ( bGiveHoeAch )
				AchClass.static.ProgressAchievementByID(Stats.Rep, 'WinCustomMapsHoE', 1);  
			AchClass.static.ProgressAchievementByID(Stats.Rep, 'WinCustomMapsNormal', 1);
			AchClass.static.ProgressAchievementByID(Stats.Rep, 'WinCustomMaps', 1);  
		}   
		else {
			//map found - give related achievements
			if ( bGiveHardAch )
				MapAchClass.static.UnlockMapAchievement(Stats.Rep, MapName, 1);   
			if ( bGiveSuiAch )
				MapAchClass.static.UnlockMapAchievement(Stats.Rep, MapName, 2);  
			if ( bGiveHoeAch )
				MapAchClass.static.UnlockMapAchievement(Stats.Rep, MapName, 3);  
		}
    }
}

function GiveBonusStats(optional String MapName)
{
	local float mult;
	local ScrnPlayerInfo SPI;
	local int i;
    local TeamInfo WinnerTeam;
	
	mult = Mut.EndGameStatBonus;
	if ( Mut.bStatBonusUsesHL )
		mult *= fmax(0, HardcoreLevel - Mut.StatBonusMinHL);
		
	i = Mut.FindMapInfo();
	if ( i != -1 )
		mult *= 1.0 + Mut.MapInfo[i].Difficulty;
	
	if ( mult < 0.1 )
		return;
        
    WinnerTeam = TeamInfo(Level.Game.GameReplicationInfo.Winner);
    log("Giving bonus xp to winners (x"$mult$")", class.outer.name);
		
    for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
		if ( SPI.PlayerOwner == none )
			continue;
        
        if ( WinnerTeam != none && SPI.PlayerOwner.PlayerReplicationInfo.Team != WinnerTeam )
            continue; // no bonus stats for loosers            
			
		SPI.BonusStats(SPI.GameStartStats, mult);
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
    if ( Game.MonsterCollection != Game.default.MonsterCollection )
        TrimCollectionToDefault(Game.default.MonsterCollection, DefaultCollection);
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
    
    // log("NetDamage: " $ injured $ " took damage from " $ instigatedBy $ " with " $ DamageType, class.outer.name);

    // forward call to next rules
    if ( NextGameRules != None )
        Damage = NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
        
	if ( Damage == 0 )
		return 0;
		
	KFDamType = class<KFWeaponDamageType>(damageType);
    ZedVictim = KFMonster(injured);
	bP2M = ZedVictim != none && KFDamType != none && instigatedBy != none && PlayerController(instigatedBy.Controller) != none;
    if ( instigatedBy != none )
        ScrnPC = ScrnPlayerController(instigatedBy.Controller);
    
	if ( bP2M ) {
		idx = GetMonsterIndex(ZedVictim);
		MonsterInfos[idx].HitCount++;
		if ( MonsterInfos[idx].FirstHitTime == 0 )
			MonsterInfos[idx].FirstHitTime = Level.TimeSeconds;
		
		MonsterInfos[idx].bHeadshot = !MonsterInfos[idx].bWasDecapitated && KFDamType.default.bCheckForHeadShots 
			&& (ZedVictim.bDecapitated || int(ZedVictim.HeadHealth) < MonsterInfos[idx].HeadHealth);
            
            
		if ( MonsterInfos[idx].bHeadshot ) {
			MonsterInfos[idx].RowHeadshots++;
			MonsterInfos[idx].Headshots++;
			
			if ( KFDamType.default.bSniperWeapon && Damage > Mut.SharpProgMinDmg && !ZedVictim.bDecapitated
					&& SRStatsBase(PlayerController(instigatedBy.Controller).SteamStatsAndAchievements) != none )
				SRStatsBase(PlayerController(instigatedBy.Controller).SteamStatsAndAchievements).AddHeadshotKill(false);
		}
		else if ( !ZedVictim.bDecapitated ) {
			MonsterInfos[idx].RowHeadshots = 0;
			if ( KFDamType.default.bCheckForHeadShots )
				MonsterInfos[idx].Bodyshots++;
			else
				MonsterInfos[idx].OtherHits++;
		}
		
		// display damages on the hud   
		if ( bShowDamages && ScrnPC != none && ScrnPC.bDamageAck ) {
			if ( MonsterInfos[idx].bHeadshot )
				DamTypeNum = 1;
			else if ( KFDamType.default.bDealBurningDamage )
				DamTypeNum = 2;
				
			if ( HitLocation == vect(0, 0, 0) ) //DoT
				HitLocation = injured.Location; 
			ScrnPC.DamageMade(Damage, HitLocation, DamTypeNum);
		}		
		
		if ( bUseAchievements ) {
			SPI = GetPlayerInfo(PlayerController(instigatedBy.Controller));
			// SPI.MadeDamage() calls AchHandlers.MonsterDamaged()
			if ( SPI != none ) 
				SPI.MadeDamage(Damage, ZedVictim, KFDamType, MonsterInfos[idx].bHeadshot, MonsterInfos[idx].bWasDecapitated);
		}
	}
	else if ( KFHumanPawn(injured) != none ) {
        if ( KFMonster(instigatedBy) != none ) {
            // M2P damage
            idx = GetMonsterIndex(KFMonster(instigatedBy));
            MonsterInfos[idx].DamageCounter += Damage;
            if ( bUseAchievements ) {
                SPI = GetPlayerInfo(PlayerController(injured.Controller));
                // SPI.TookDamage() calls AchHandlers.PlayerDamaged()
                if ( SPI != none )
                    SPI.TookDamage(Damage, ZedVictim, DamageType);
            }
        }
        else if ( ScrnPC != none ) {
            // P2P damage 
            if ( bShowDamages ) {
                if ( HitLocation == vect(0, 0, 0) ) //DoT
                    HitLocation = injured.Location; 
                ScrnPC.ClientPlayerDamaged(Damage, HitLocation, 10);
            }        
        }
	}
	
	if ( bUseAchievements ) {
		for ( i=0; i<AchHandlers.length; ++i ) {
			AchHandlers[i].NetDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
		}
	}

	if ( bP2M ) {
		MonsterInfos[idx].LastHitTime = Level.TimeSeconds;
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
      
	if ( bUseAchievements ) {
		for ( i=0; i<AchHandlers.length; ++i ) {
			AchHandlers[i].ScoreKill(Killer, Killed);
		}	
	}
    
    if ( Killed.bIsPlayer && Mut.bPlayerZEDTime && Killer != none && Killer != Killed )
        Mut.KF.DramaticEvent(1.0); // always zed time on player death
}


function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local ScrnPlayerInfo SPI;
	local int idx;
	
    if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
        return true;

    WaveTotalKills++;
    if ( Killed.IsA('DoomMonster') )
        WaveDoom3Kills++;

    if ( bUseAchievements ) {
		if ( KFMonster(Killed) != none && PlayerController(Killer) != none && class<KFWeaponDamageType>(DamageType) != none ) {
			SPI = GetPlayerInfo(PlayerController(Killer));
			if ( SPI != none ) 
				SPI.KilledMonster(KFMonster(Killed), class<KFWeaponDamageType>(DamageType));
		}
		else if ( KFHumanPawn(Killed) != none && PlayerController(Killed.Controller) != none ) {
			if ( Killer != none && KFMonster(Killer.Pawn) != none ) {
				idx = GetMonsterIndex(KFMonster(Killer.Pawn));
				MonsterInfos[idx].PlayerKillCounter++;
				MonsterInfos[idx].PlayerKillTime = Level.TimeSeconds;
			}
			// don't count suicide deaths during trader time
			if ( !Mut.KF.bTradingDoorsOpen ) {
				SPI = GetPlayerInfo(PlayerController(Killed.Controller));
				if ( SPI != none ) 
					SPI.Died(Killer, DamageType);		
			}
			if ( Mut.bSpawn0 || Mut.bStoryMode ) {
                idx = Killed.Health;
                Killed.Health = max(Killed.Health, 1); // requires health to spawn second pistol
				class'ScrnHumanPawn'.static.DropAllWeapons(Killed); // toss all weapons after death, if bSpawn0=true or in Story Mode
                Killed.Health = idx;
            }    
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
    MonsterInfos[free_index].HeadHealth = Monster.HeadHealth * Monster.DifficultyHeadHealthModifer() * Monster.NumPlayersHeadHealthModifer();
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
	
	//log("Monster=" $ String(Other) @ "Outer="$String(Other.outer) @ "OuterClass="$String(Other.class.outer), class.outer.name);
	CheckedMonsterClasses[CheckedMonsterClasses.length] = Monster.class;
	CheckNewMonster(Monster);
	
	if ( bUseAchievements )
		for ( i=0; i<AchHandlers.length; ++i )
			AchHandlers[i].MonsterIntroduced(Monster);
}

function CheckNewMonster(KFMonster Monster)
{
    if ( ZombieStalker(Monster) != none ) {
        if ( Monster.IsA('ZombieGhost') ) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(0.5, Monster.MenuName);
        }
        else if ( Monster.IsA('ZombieSuperStalker')) {
            // bHasCustomZeds = true;
            RaiseHardcoreLevel(0.3, Monster.MenuName);
        }
    }
    else if ( ZombieGorefast(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperGorefast')) {
            // bHasCustomZeds = true;
            RaiseHardcoreLevel(0.3, Monster.MenuName);
        }
    }
    else if ( ZombieCrawler(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperCrawler')) {
            // bHasCustomZeds = true;
            RaiseHardcoreLevel(0.3, Monster.MenuName);
        }
    }  
    else if ( ZombieBloat(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperBloat')) {
            // bHasCustomZeds = true;
            RaiseHardcoreLevel(0.3, Monster.MenuName);
        }
    }    
    else if ( ZombieSiren(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperSiren')) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(1.0, Monster.MenuName);
        }
    }     
    else if ( ZombieHusk(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperHusk') ) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(1.4, Monster.MenuName);
        }
		else if ( Monster.IsA('TeslaHusk') ) {
            bHasCustomZeds = true;
			RaiseHardcoreLevel(1.5, Monster.MenuName);
		}	
    }
    else if ( ZombieScrake(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperScrake') ) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(1.4, Monster.MenuName);
        }
        else if ( Monster.IsA('ZombieJason') ) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(1.5, Monster.MenuName);
        }        
    }  
    else if ( ZombieFleshpound(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperFP') ) {
            bHasCustomZeds = true;
            RaiseHardcoreLevel(1, Monster.MenuName);
        }
    }  
    else if ( Monster.IsA('ZombieShiver') ) {
        bHasCustomZeds = true;
        RaiseHardcoreLevel(1, Monster.MenuName);
    }
    else if ( Monster.IsA('ZombieBrute') ) {
        bHasCustomZeds = true;
        RaiseHardcoreLevel(2, Monster.MenuName);
    }
    else if ( Monster.IsA('ZombieJason') ) {
            bHasCustomZeds = true;
        RaiseHardcoreLevel(1.5, Monster.MenuName);
    }
	else if ( Monster.IsA('FemaleFP') ) {
        if ( !bFemaleFP ) {
            bFemaleFP = true;
            bHasCustomZeds = true;
            RaiseHardcoreLevel(2.5, Monster.MenuName);
        }
	}
    else if ( Monster.IsA('DoomMonster') ) {
        if ( DoomHardcorePointsGained == 0 ) {
            log("Doom3 monster package name is " $ String(Monster.class.outer.name), class.outer.name);
            bScrnDoom = left(String(Monster.class.outer.name), 4) ~= "Scrn";
            DoomHardcorePointsGained = 2;
            RaiseHardcoreLevel(2, msgDoom3Monster);
        }
        // + 1 point per boss
        if ( bScrnDoom && Monster.default.Health >= 3000 )
            RaiseHardcoreLevel(1, msgDoom3Boss);
        // + extra 2 hardcore points can be earned if there are are >10% doom monsters is a wave
    }
}

function InitBoss(KFMonster Monster)
{
	local int i;
    
    Boss = Monster;
    BossClass = Monster.class;
    bSuperPat = false;
    bDoomPat = false;
    
    if ( Monster.IsA('DoomMonster') ) {
        if ( bScrnDoom && Monster.default.Health >= 3000 ) {
            bDoomPat = true;
            RaiseHardcoreLevel(2, Monster.MenuName);
        }
    }
    else if ( ZombieBoss(Monster) != none ) {
        if ( Monster.IsA('ZombieSuperBoss') ) {
            bSuperPat = true;
            RaiseHardcoreLevel(2, Monster.MenuName);
        }
        else if ( Monster.IsA('HardPat') ) {
            bSuperPat = true;
            RaiseHardcoreLevel(2, "HardPat");
        }
    }
	
	for ( i=0; i<AchHandlers.length; ++i )
		AchHandlers[i].BossSpawned(Monster);
}



// called from ScrnNade
function ScrakeNaded(ZombieScrake Scrake)
{
    local int index;
    
    index = GetMonsterIndex(Scrake);
    MonsterInfos[index].DamType2 = class'KFMod.DamTypeFrag'; 
    MonsterInfos[index].DamageFlags2 = DF_RAGED | DF_STUPID; 
}

function RaiseHardcoreLevel(float inc, string reason)
{
    local string s;
    local Controller P;
    local PlayerController Player;
    
    if ( HardcoreLevelFloat < HardcoreLevel )
        HardcoreLevelFloat = HardcoreLevel; // just to be sure

    HardcoreLevelFloat += inc;
    HardcoreLevel = int(HardcoreLevelFloat+0.01);
    
    s = msgHardcore;
    ReplaceText(s, "%a", String(HardcoreLevel));
    ReplaceText(s, "%i", String(inc));
    ReplaceText(s, "%r", reason);


    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = PlayerController(P);
        if ( Player != none ) {
            Player.ClientMessage(s);
        }
    }
}



function WeaponReloaded(PlayerController Owner, KFWeapon W)
{
	local ScrnPlayerInfo SPI;
	
	SPI = GetPlayerInfo(Owner);
	if ( SPI != none )
		SPI.WeaponReloaded(W);
}

function WeaponFire(PlayerController Owner, KFWeapon W, byte FireMode)
{
	local ScrnPlayerInfo SPI;
	
	SPI = GetPlayerInfo(Owner);
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
	local ScrnPlayerInfo SPI;
	local int count;
	
	for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
		if ( SPI.PlayerOwner != none && !SPI.bDied )
			count++;
	}
	return count;
}

function int PlayerCountInWave()
{
	local ScrnPlayerInfo SPI;
	local int count;
	
	for ( SPI=PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
		count++;
	}
	return count;
}

/**
 * Increments achievement progress for all players who have PlayerInfo object, except ExcludeSPI. 
 * @param AchID 		Achievement ID
 * @param Inc 			Achievement progress. Usually 1.
 * @param bOnlyAlive	if true, then achievement will not be granted for dead players (SPI.bDied = true)
 * @param ExcludeSPI	player to exclude from achievement progress.
 */
// if bOnlyAlive=true, then achievment will not be granted for dead players (bDied = true)
function ProgressAchievementForAllPlayers(name AchID, int Inc, optional bool bOnlyAlive, optional ScrnPlayerInfo ExcludeSPI, optional TeamInfo Team)
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




// destoroys player infos without PlayerOwner
function ClearNonePlayerInfos() 
{
	local ScrnPlayerInfo SPI, PrevSPI;
	
	while ( PlayerInfo!=none && (PlayerInfo.PlayerOwner == none || PlayerInfo.PlayerOwner.Pawn == none) )
	{
		PrevSPI = PlayerInfo;
		PlayerInfo = PrevSPI.NextPlayerInfo;
		PrevSPI.Destroy();
	}
	
	if ( PlayerInfo == none )
		return;
		
	PrevSPI = PlayerInfo;
	// we already know that PlayerInfo has PlayerOwner, otherwise we won't reach here
	SPI = PrevSPI.NextPlayerInfo; 
	while ( SPI != none ) {
		if ( SPI.PlayerOwner == none || PlayerInfo.PlayerOwner.Pawn == none ) {
			PrevSPI.NextPlayerInfo = SPI.NextPlayerInfo;
			SPI.Destroy();
		}
		else {		
			PrevSPI = SPI;
		}
		SPI = PrevSPI.NextPlayerInfo;
	}
}

function ScrnPlayerInfo CreatePlayerInfo(PlayerController PlayerOwner) 
{
	local ScrnPlayerInfo SPI;
	
	if ( PlayerOwner == none )
		return none;
	
	SPI = GetPlayerInfo(PlayerOwner);
	if ( SPI == none ) {
		SPI = spawn(class'ScrnPlayerInfo');
		if ( SPI == none ) {
			log("Unable to spawn ScrnPlayerInfo!", class.outer.name);
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
		SPI.BackupStats(SPI.GameStartStats);
		SPI.StartWave = Mut.KF.WaveNum;
	}
	return SPI;
}


/* OverridePickupQuery()
when pawn wants to pickup something, gamerules given a chance to modify it.  If this function 
returns true, bAllowPickup will determine if the object can be picked up.
*/
function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	local bool result;
	local KFWeaponPickup WP;
	local ScrnPlayerInfo SPI;
	local string str;
	
	if ( Other.Health <= 0 ) {
		bAllowPickup = 0; // prevent dying bodies of picking up items
		return true;
	}	
	
	Mut.ReplacePickup(item);	// replace pickup's inventory with ScrN version
	
	if ( NextGameRules != None )
		result = NextGameRules.OverridePickupQuery(Other, item, bAllowPickup);
	
	if ( !result || bAllowPickup == 1 )	{
		WP = KFWeaponPickup(item);
		if ( WP != none ) {
			// weapon lock and broadcast
			if ( WP.SellValue > 0 && WP.DroppedBy != Other.Controller
					&& WP.DroppedBy != none && WP.DroppedBy.PlayerReplicationInfo != none ) 
			{
                // ScrN Players can lock weapons from picking up by teammates
				if ( ScrnPlayerController(WP.DroppedBy) != none && ScrnPlayerController(WP.DroppedBy).bWeaponsLocked 
                        && (Other.PlayerReplicationInfo == none || WP.DroppedBy.PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team) ) 
                {
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
					result = true;
					bAllowPickup = 0;
					if ( Level.TimeSeconds > ScrnPlayerController(Other.Controller).LastLockMsgTime + 1.0 ) {
						ScrnPlayerController(Other.Controller).ClientMessage(Mut.ColorString(strWeaponLockedOwn,192,128,1));
						ScrnPlayerController(Other.Controller).LastLockMsgTime = Level.TimeSeconds; 
					}				
				}
				else if ( Mut.bBroadcastPickups && !HasInventoryClass(Other, WP.InventoryType) )
					Mut.StolenWeapon(Other, WP);
			}
		}
		
		// achievements
		if ( bUseAchievements && (!result || bAllowPickup == 1) )	{
			SPI = GetPlayerInfo(PlayerController(Other.Controller));
			if ( SPI != none ) {
				if ( WP != none )
					SPI.PickedWeapon(WP);
				else if ( CashPickup(item) != none )
					SPI.PickedCash(CashPickup(item));
				else 
					SPI.PickedItem(item);
			}
		}
	}
	return result;
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

/*
// from time to time monster becomes frustrated with enemy and finds a new one
function MonsterFrustration()
{
	local int i;
	local KFMonsterController MC;
	local ScrnHumanPawn ScrnPawn;
	
	for ( i=0; i<MonsterInfos.length; ++i ) {
		if ( MonsterInfos[i].Monster == none 
				|| MonsterInfos[i].Monster.Health <= 0 || MonsterInfos[i].Monster.bDecapitated
				|| MonsterInfos[i].DamageCounter > 0
				|| Level.TimeSeconds - MonsterInfos[i].SpawnTime < 30.0
				|| Level.TimeSeconds - MonsterInfos[i].LastHitTime < 15.0 ) 
			continue;
			
		MC = KFMonsterController(MonsterInfos[i].Monster.Controller);
		if ( MC == none )
			continue;
		
		ScrnPawn = ScrnHumanPawn(MC.Enemy);
		if ( ScrnPawn == none )
			continue;
			
		if ( ScrnPawn.GroundSpeed > fmax(220, MonsterInfos[i].Monster.GroundSpeed) ) {
			// make ScrnPawn.AssessThreatTo() return 0.1 (it will be called by FindNewEnemy())
			ScrnPawn.LastThreatMonster = MC;
			ScrnPawn.LastThreatTime = Level.TimeSeconds;
			ScrnPawn.LastThreat = 0.1;
			MC.FindNewEnemy();
			// todo - the next FindNewEnemy() will probably reset this enemy again
		}
	}
}
*/



defaultproperties
{
	msgHardcore="Hardcore level raised to %a (+%i for %r)"
	msgDoom3Monster="Doom3 monsters"
	msgDoom3Boss="Doom Boss"
	msgDoomPercent="Doom3 monster count in wave = %p%"
	strWeaponLocked="%w locked by %o"
	strWeaponLockedOwn="Can not pickup another's weapons while own are locked"
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
}
