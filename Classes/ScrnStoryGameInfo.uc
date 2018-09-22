class ScrnStoryGameInfo extends KFStoryGameInfo;

var ScrnBalance ScrnBalanceMut;
var protected transient int ObjTraderIndex;

event InitGame( string Options, out string Error )
{
    local int ConfigMaxPlayers;

    ObjTraderIndex = -1;
    ConfigMaxPlayers = default.MaxPlayers;

    super.InitGame(Options, Error);
    CheckScrnBalance();

    MaxPlayers = Clamp(GetIntOption( Options, "MaxPlayers", MaxPlayers ),0,32);
    default.MaxPlayers = Clamp( ConfigMaxPlayers, 0, 32 );

    log("MonsterCollection = " $ MonsterCollection);
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

event PostLogin( PlayerController NewPlayer )
{
    super.PostLogin(NewPlayer);

    if ( ScrnPlayerController(NewPlayer) != none )
        ScrnPlayerController(NewPlayer).PostLogin();
}

function RestartPlayer( Controller aPlayer )
{
    super.RestartPlayer(aPlayer);

    if ( FriendlyFireScale > 0 && aPlayer.Pawn != none && PlayerController(aPlayer) != none ) {
        ScrnBalanceMut.SendFriendlyFireWarning(PlayerController(aPlayer));
    }
}

// C&P from Deathmatch strip color tags before name length check
function ChangeName(Controller Other, string S, bool bNameChange)
{
    local Controller APlayer,C, P;

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
                for( P=Level.ControllerList; P!=None; P=P.nextController )
                    if ( P.bIsPlayer && (P.PlayerReplicationInfo.playername~=S) )
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

// fixed GameRules.NetDamage() call
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

    if ( instigatedBy == None || DamageType == class'DamTypeVomit' || DamageType == class'DamTypeWelder' || DamageType == class'SirenScreamDamage')
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

        // fixed GameRules.NetDamage() call  -- PooSH
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



// Fixed Spawn rate for >6 players  -- PooSH
function float GetAdjustedSpawnInterval(float BaseInterval, float UsedWaveTimeElapsed, bool bIgnoreSineMod)
{
    local float SineMod;
    local float FinalInterval;
    local int TotalNumPlayers;
    local float PlayerCountMultiplier;
    local float DifficultyMultiplier;

    PlayerCountMultiplier  = 1.f;
    SineMod                = 1.0 - Abs(sin(UsedWaveTimeElapsed * SineWaveFreq));
    DifficultyMultiplier   = 1.f;


    /* Scale the spawn interval by the number of players */
    TotalnumPlayers = NumPlayers + NumBots ;

    /* We're gonna pull the difficulty / player count multipliers from the editor from now on instead of hard-coding them*/
    if(StoryRules != none)
    {
        switch(TotalnumPlayers)
        {
            case 1  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_1P;       break;
            case 2  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_2P;       break;
            case 3  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_3P;       break;
            case 4  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_4P;       break;
            case 5  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_5P;       break;
            case 6  :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_6P;       break;
            // >6 players: +0.25 per each next player  -- PooSH
            default :   PlayerCountMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_PlayerCount.Scale_6P + (TotalnumPlayers-6)*0.25;
        };

        // Set difficulty based values
        if ( GameDifficulty >= 7.0 ) // Hell on Earth
        {
            DifficultyMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_GameDifficulty.Scale_HellOnEarth;
        }
        else if ( GameDifficulty >= 5.0 ) // Suicidal
        {
            DifficultyMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_GameDifficulty.Scale_Suicidal;
        }
        else if ( GameDifficulty >= 4.0 ) // Hard
        {
            DifficultyMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_GameDifficulty.Scale_Hard;
        }
        else if ( GameDifficulty >= 2.0 ) // Normal
        {
        }
        else  // Beginner
        {
            DifficultyMultiplier = StoryRules.Spawn_Difficulty_Scaling.EnemySpawnRate.Scale_GameDifficulty.Scale_Beginner;
        }
    }

    DifficultyMultiplier = 1.f / DifficultyMultiplier;
    PlayerCountMultiplier  = 1.f / PlayerCountMultiplier;

    //log("Base Spawn Interval    : "@BaseInterval,'Story_Debug');
    if( bIgnoreSineMod )
    {
        //log("Sine Multiplier        : Ignored",'Story_Debug');
        FinalInterval = FMax(BaseInterval * PlayerCountMultiplier * DifficultyMultiplier,0.1);
    }
    else
    {
        //log("Sine Multiplier        : "@SineMod,'Story_Debug');
        FinalInterval = FMax((BaseInterval +  (SineMod * (BaseInterval*2))) * PlayerCountMultiplier * DifficultyMultiplier,0.1) ;
    }

    /*log("Player Multiplier      : "@PlayerCountMultiplier,'Story_Debug');
    log("Difficulty Multiplier  : "@DifficultyMultiplier,'Story_Debug');
    log("Final Interval         : "@FinalInterval);
    log("UsedWaveTimeElapsed    : "@UsedWaveTimeElapsed);*/

    return FinalInterval;

}

// added check for Scorer==none  -- PooSH
function bool CheckMaxLives(PlayerReplicationInfo Scorer)
{
    local KF_StoryCheckPointVolume    RespawnPoint;
    local Controller Failer;


    /* Team respawn is already taking place .. Don't bother checking anything else*/
    if(bPendingTeamRespawn)
    {
        return false;
    }

    if(WholeTeamIsWipedOut())
    {
        if(CurrentObjective != none)
        {
            // added to prevent "Accessed None" warnings  -- PooSH
            if ( Scorer != none )
                Failer = Controller(Scorer.Owner);
            CurrentObjective.ObjectiveFailed(Failer,true);
        }

        if(    CurrentCheckPoint != none &&
            CurrentCheckPoint.GrantASecondChance(RespawnPoint) )
        {
            bPendingTeamRespawn = true;

            ResetGameState();

            /* Make sure the checkpoint is active so that it can respawn everyone */
            if( !RespawnPoint.bIsActive )
            {
                RespawnPoint.CheckPointActivated(RespawnPoint.Instigator,true,false);
            }

            BroadcastLocalizedMessage( CheckPointMessageClass, 1, none , None, RespawnPoint );

            return    false ;
        }
    }

    return Super(KFGameType).CheckMaxLives(Scorer);
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    if ( bGameEnded )
        return true; // this shouldn't happen, but you know TWIs coding style ;)

    // Set EndGameType and Winner before calling GameRules
    switch(Reason) {
        case "LoseAction" :
            KFGameReplicationInfo(GameReplicationInfo).EndGameType = 1;
            break;
        case "WinAction" :
            GameReplicationInfo.Winner = Teams[0];
            KFGameReplicationInfo(GameReplicationInfo).EndGameType = 2;
            break;
        case "LastMan" :
            KFGameReplicationInfo(GameReplicationInfo).EndGameType = 1;
            break;
    }

    if ( !super(TeamGame).CheckEndGame(Winner,Reason) ) {
        GameReplicationInfo.Winner = none;
        KFGameReplicationInfo(GameReplicationInfo).EndGameType = 0;
        return false;
    }

    return true;
}

// function EndGame(PlayerReplicationInfo  Winner, string  Reason)
// {
    // if ( bGameEnded )
        // return; // this shouldn't happen...

    // super.EndGame(Winner, Reason);
// }

static event class<GameInfo> SetGameType( string MapName )
{
    local string prefix;

    prefix = Caps(Left(MapName, InStr(MapName, "-")));
    if ( prefix == "KFO")
        return default.class;
    else if ( prefix == "KF" )
        return Class'ScrnBalanceSrv.ScrnGameType';

    return super.SetGameType( MapName );
}

// overrided to set bWaveInProgress
// NumMonsters check replaced with bTradingDoorsOpen
function bool IsTraderTime()
{
    bWaveInProgress = !bTradingDoorsOpen && NumMonsters > 0 && ObjTraderIndex == -1;
        //&& CurrentObjective != none && !CurrentObjective.IsTraderObj();
    KFGameReplicationInfo(Level.GRI).bWaveInProgress = bWaveInProgress;
    return !bWaveInProgress;
}

function SetActiveObjective( KF_StoryObjective NewObjective, optional pawn ObjInstigator)
{
    local int i;

    super.SetActiveObjective(NewObjective, ObjInstigator);

    ObjTraderIndex = -1;
    if ( CurrentObjective != none ) {
        for(i = 0 ; i < CurrentObjective.SuccessConditions.length ; ++i) {
            if( ObjCondition_TraderTime(CurrentObjective.SuccessConditions[i]) != none ) {
                ObjTraderIndex = i;
                break;
            }
        }
    }
}

function AmmoPickedUp(KFAmmoPickup PickedUp)
{
    super.AmmoPickedUp(PickedUp);
    ScrnBalanceMut.GameRules.WaveAmmoPickups++;
}

State MatchInProgress
{
    function Timer()
    {
        super.Timer();
        if ( CurrentObjective != none && ObjTraderIndex != -1 ) {
            KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave =
                ObjCondition_Timed(CurrentObjective.SuccessConditions[ObjTraderIndex]).RemainingSeconds;
        }
    }
}


defaultproperties
{
    GameName="ScrN Objective Mode"
}
