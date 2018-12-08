class TSCGame extends ScrnGameType
    config;

var TSCGameReplicationInfo TSCGRI;
var TSCVotingOptions TSCVotingOptions;
var int OriginalFinalWave;

var localized string RedTeamHumanName, BlueTeamHumanName;

var config byte OvertimeWaves;         // number of Overtime waves
var config byte SudDeathWaves;         // number of Sudden Death waves
var config float OvertimeTeamMoneyPenalty; // team receives less and less money for each subsequent overtime wave
var config int LateJoinerCashBonus; // extra money for late joiners to prevent, for example, joining before wave 100 with only $100 cash
var config string SongRedWin, SongBlueWin, SongBothWin, SongBothWiped;

var float CurrentTeamMoneyPenalty;
var localized string strBudgetCut;

var TSCBaseGuardian TeamBases[2];
var float BaseRadius; // Base radius
var float MinBaseZ, MaxBaseZ; // min and max Z difference between player and base

var transient int BigTeamSize, SmallTeamSize; // number of alive players in biggest team at start of the wave
var transient bool bSingleTeam; // wave started without other team
var transient bool bTeamWiped;  // one of the team was wiped out during the wave. Always true when bSingleTeam=True
var transient bool bWaveEnding;          // indicates end phase of the wave. Always must be checked together with bWaveBossInProgress!
var int WaveEndingCountdown; // if bWaveEnding=True, shows how many seconds left until auto-end wave (auto-kill remaining zeds)
var byte NextSquadTeam;
var bool bCheckSquadTeam; // should NextSquadTeam be checked in FindSquadTarget()?
var array < class<KFMonster> > PendingSpecialSquad;

var TSCTeam TSCTeams[2];
var class<TSCBaseGuardian> BaseGuardianClasses[2];
var ShopVolume TeamShops[2];
var class<WillowWhisp> BaseWhisp;

var bool bPendingShuffle; // shuffle teams at the end of the wave
var protected bool bTeamChanging; // indicates that game changes team members, e.g. doing shuffle

var config bool bLockTeamsOnSuddenDeath;

struct SClanTags {
    var config string Prefix, Postfix;
};
var config array<SClanTags> ClanTags;
var config bool bClanCheck;

var bool bCustomHUD, bCustomScoreboard;

var bool bPvP, bNoBases;
var bool bCtryTags; // indicates if Country Tags mutator is running

var enum EHumanDamageMode
{
    HDMG_None,
    HDMG_NoFF,
    HDMG_NoFF_PvP,
    HDMG_Normal,
    HDMG_PvP,
    HDMG_All,
} HumanDamageMode;

var config bool bVoteHDmg, bVoteHDmgOnlyBeforeStart;
var float HDmgScale;



// this one is called from PreBeginPlay()
function InitGameReplicationInfo()
{
    Super.InitGameReplicationInfo();

    TSCGRI = TSCGameReplicationInfo(GameReplicationInfo);
    if ( TSCGRI == none )
        Warn("Wrong GameReplicationInfo class: " $ GameReplicationInfo);
    else {
        TSCGRI.OvertimeWaves = OvertimeWaves;
        TSCGRI.SudDeathWaves = SudDeathWaves;
        TSCGRI.BaseRadiusSqr = BaseRadius * BaseRadius;
        TSCGRI.MinBaseZ = MinBaseZ;
        TSCGRI.MaxBaseZ = MaxBaseZ;
        TSCGRI.HumanDamageMode = HumanDamageMode;
        TSCGRI.bSingleTeamGame = bSingleTeamGame;
    }
}

event PreBeginPlay()
{
    Super.PreBeginPlay();
    GameReplicationInfo.bNoTeamSkins = bSingleTeamGame;
    GameReplicationInfo.bNoTeamChanges = bSingleTeamGame;
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    TSCTeams[0] = TSCTeam(Teams[0]);
    TSCTeams[1] = TSCTeam(Teams[1]);

    SpawnBaseGuardian(0);
    Teams[0].HomeBase = TeamBases[0];
    Teams[0].ColorNames[0]= RedTeamHumanName;
    Teams[0].ColorNames[1]= BlueTeamHumanName;
    Teams[0].TeamColor=class'Canvas'.static.MakeColor(180, 0, 0, 255);

    SpawnBaseGuardian(1);
    Teams[1].HomeBase = TeamBases[1];
    Teams[1].ColorNames[0]= RedTeamHumanName;
    Teams[1].ColorNames[1]= BlueTeamHumanName;
    Teams[1].TeamColor=class'Canvas'.static.MakeColor(32, 92, 255, 255);
}

event InitGame( string Options, out string Error )
{
    local ScrnVotingHandlerMut VH;
    local Mutator M;

    ScrnBalanceMut.bScrnWaves = true;
    super.InitGame(Options, Error);

    // check loaded mutators
    for (M = BaseMutator; M != None; M = M.NextMutator) {
        bCtryTags = bCtryTags || M.IsA('CtryTags');
    }

    // hard-code some ScrN features
    ScrnBalanceMut.MaxVoteKillMonsters = 0; // no vote end wave since it is auto-ended in 30 seconds
    ScrnBalanceMut.bSpawn0 = true;
    ScrnBalanceMut.bNoStartCashToss = true;
    ScrnBalanceMut.bMedicRewardFromTeam = true;
    if ( ScrnBalanceMut.ForcedMaxPlayers < 12 )
        ScrnBalanceMut.ForcedMaxPlayers = 0;

    VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(self);
    if ( VH != none ) {
        TSCVotingOptions = TSCVotingOptions(VH.AddVotingOptions(class'TSCVotingOptions'));
        if ( TSCVotingOptions != none ) {
            TSCVotingOptions.TSC = self;
        }
        else
            log("!!! Unable to spawn TSCVotingOptions!", 'TSC');
    }
    else
        log("Voting (mvote) disabled.", 'TSC');

    bUseEndGameBoss = false;
    FinalWave = max(GetIntOption(Options, "NWaves", FinalWave), 1);
    OriginalFinalWave = FinalWave;
    OvertimeWaves = max(GetIntOption(Options, "OTWaves", OvertimeWaves), 0);
    SudDeathWaves = max(GetIntOption(Options, "SDWaves", SudDeathWaves), 0);

    // force FriendlyFireScale to 10%
    FriendlyFireScale = HDmgScale;
    default.FriendlyFireScale = HDmgScale;

    // set MaxZombiesOnce to at least 48, unless it is a small map with only 1 trader
    if ( MaxZombiesOnce < 48 && !bSingleTeamGame && ShopList.Length > 1 ) {
        MaxZombiesOnce = 48;
    }

    // todo - allow mutators to alter those settings
    if ( !bCustomHUD )
        HUDType = string(Class'ScrnBalanceSrv.TSCHUD');
    if ( !bCustomScoreboard )
        ScoreBoardType = string(Class'ScrnBalanceSrv.TSCScoreBoard');
}


//force using DefaultEnemyRosterClass
function UnrealTeamInfo GetBlueTeam(int TeamBots)
{
    local class<UnrealTeamInfo> RosterClass;
    local UnrealTeamInfo Roster;

    if ( DefaultEnemyRosterClass != "" ) {
        RosterClass = class<UnrealTeamInfo>(DynamicLoadObject(DefaultEnemyRosterClass,class'Class'));
        if ( RosterClass != none )
            Roster = spawn(RosterClass);
    }
    if ( Roster == none )
        Roster = super.GetBlueTeam(0);

    return Roster;
}

function UnrealTeamInfo GetRedTeam(int TeamBots)
{
    local class<UnrealTeamInfo> RosterClass;
    local UnrealTeamInfo Roster;

    if ( DefaultEnemyRosterClass != "" ) {
        RosterClass = class<UnrealTeamInfo>(DynamicLoadObject(DefaultEnemyRosterClass,class'Class'));
        if ( RosterClass != none )
            Roster = spawn(RosterClass);
    }
    if ( Roster == none )
        Roster = super.GetRedTeam(0);

    return Roster;
}

// extracts ClanName from PlayerName or returns empty string, if player name
// doesn't contain clan.
function string ClanName(string PlayerName)
{
    local int i, namelen,  pos;
    local string S;

    if ( PlayerName == "" )
        return "";

    PlayerName = ScrnBalanceMut.StripColorTags(PlayerName);
    if ( bCtryTags && Mid(PlayerName,0,1)=="[" ) {
        // do not use country tags as clan names
        if( Mid(PlayerName,4,1)=="]" )
            PlayerName = Mid(PlayerName,5); // 3-char country code
        else if( Mid(PlayerName,3,1)=="]" )
            PlayerName = Mid(PlayerName,4); // 2-char country code
    }
    namelen = len(PlayerName);

    for ( i=0; i<ClanTags.length; ++i ) {
        S = PlayerName;
        if ( ClanTags[i].Prefix != "" ) {
            pos = InStr(PlayerName, ClanTags[i].Prefix);
            if ( pos == -1 )
                continue;
            S = Right(S, namelen - pos - len(ClanTags[i].Prefix));
        }
        if ( S != "" ) {
            if ( ClanTags[i].Postfix == "" )
                return S;

            pos = InStr(S, ClanTags[i].Postfix);
            if ( pos > 0 )
                return Left(S, pos);
        }
    }

    return "";
}

// returns team, were same clan members as MyPRI are playing
// returns none if no same clan memebers are on the server
function UnrealTeamInfo MyClanTeam(PlayerReplicationInfo myPRI)
{
    local int i;
    local PlayerReplicationInfo PRI;
    local string MyClan;

    MyClan = ClanName(myPRI.PlayerName);
    if ( MyClan == "" )
        return none;
    // debug
    Broadcast(Self, ScrnBalanceMut.ColoredPlayerName(myPRI)$" associated with '"$MyClan$"' clan");

    for ( i=0; i<GameReplicationInfo.PRIArray.Length; i++ ) {
        PRI = GameReplicationInfo.PRIArray[i];
        if ( PRI != none && PRI != myPRI && PRI.Team != none && PRI.Team.TeamIndex < 2
                && ClanName(PRI.PlayerName) == MyClan )
        {
            return UnrealTeamInfo(PRI.Team);
        }
    }

    return none;
}

function bool ChangeTeam(Controller Other, int num, bool bNewTeam)
{
    local UnrealTeamInfo NewTeam;
    local TSCBaseGuardian gnome;

    // if (CurrentGameProfile != none)
    // {
        // if (!CurrentGameProfile.CanChangeTeam(Other, num)) return false;
    // }

    if ( Other.PlayerReplicationInfo == none )
        return false; // no PlayerReplicationInfo = no team  -- PooSH

    if ( Other.IsA('PlayerController') && Other.PlayerReplicationInfo.bOnlySpectator )
    {
        Other.PlayerReplicationInfo.Team = None;
        return true;
    }

    if ( bTeamChanging && num < 2 )
        NewTeam = Teams[num];
    else if ( bClanCheck && !bNewTeam
            && !GameReplicationInfo.bMatchHasBegun && Other.PlayerReplicationInfo != none )
        NewTeam = MyClanTeam(Other.PlayerReplicationInfo);

    if ( NewTeam == none )
        NewTeam = Teams[PickTeam(num,Other)];

    // check if already on this team
    if ( Other.PlayerReplicationInfo.Team == NewTeam )
        return false;

    // if player is carrying a Gnome - drop it
    gnome = TSCBaseGuardian(Other.PlayerReplicationInfo.HasFlag);
    if ( gnome != none ) {
        gnome.Drop(vect(0,0,0));
        gnome.GiveToClosestPlayer(Other.Pawn.Location);
    }
    // make sure player will not remain captain for the old team after the switching
    if ( Other.PlayerReplicationInfo.Team != none && Other.PlayerReplicationInfo.Team.TeamIndex < 2 ) {
        if ( TSCGRI.TeamCaptain[Other.PlayerReplicationInfo.Team.TeamIndex] == Other.PlayerReplicationInfo ) {
            SetTeamCaptain(Other.PlayerReplicationInfo.Team.TeamIndex, none);
        }
    }

    Other.StartSpot = None;

    if ( Other.PlayerReplicationInfo.Team != None )
        Other.PlayerReplicationInfo.Team.RemoveFromTeam(Other);

    if ( NewTeam.AddToTeam(Other) )
    {
        BroadcastLocalizedMessage( GameMessageClass, 3, Other.PlayerReplicationInfo, None, NewTeam );

        if ( bNewTeam && PlayerController(Other)!=None ) {
            GameEvent("TeamChange",string(NewTeam.TeamIndex),Other.PlayerReplicationInfo);
            // give starting cash fot team changers
            GiveStartingCash(PlayerController(Other));
        }
    }

    return true;
}

function byte PickTeam(byte num, Controller C)
{
    local UnrealTeamInfo SmallTeam, BigTeam, NewTeam;
    //local Controller B;
    //local int BigTeamBots, SmallTeamBots;

    if ( bSingleTeamGame && PlayerController(C) != None )
        return 1; // all players go to Steampunk Team

    if ( bPlayersVsBots && (Level.NetMode != NM_Standalone) )
    {
        if ( PlayerController(C) != None )
            return 1;
        return 0;
    }

    SmallTeam = Teams[0];
    BigTeam = Teams[1];

    if ( Teams[0].Size < Teams[1].Size )  {
        SmallTeam = Teams[0];
        BigTeam = Teams[1];
    }
    else {
        SmallTeam = Teams[1];
        BigTeam = Teams[0];
    }

    if ( SmallTeam.Size == BigTeam.Size && SmallTeam.Score > BigTeam.Score ) {
        SmallTeam = BigTeam;
        BigTeam = Teams[1-SmallTeam.TeamIndex];
    }

    if ( num < 2 )
        NewTeam = Teams[num];
    else
        NewTeam = SmallTeam;

    if ( bPlayersBalanceTeams && (Level.NetMode != NM_Standalone) && (PlayerController(C) != None) )
    {
        if ( SmallTeam.Size < BigTeam.Size )
            NewTeam = SmallTeam;
    }

    return NewTeam.TeamIndex;
}

// shuffling only human players, without touching bots
// todo: or not to do? Bot support.
function ShuffleTeams()
{
    local PlayerReplicationInfo PRI;
    local array<PlayerReplicationInfo> RedPlayers, BluePlayers;
    local int ConstantReds, ConstantBlues; // amount of player which can't change the team, e.g. because of carrying the gnome
    local int i, RedTeamSize;

    if ( bSingleTeamGame )
        return; // no team game = no shuffle

    if ( GameReplicationInfo.bMatchHasBegun ) {
        if ( bWaveInProgress ) {
            bPendingShuffle = true;
            BroadcastLocalizedMessage(class'TSCMessages', 240);
            return;
        }
        else if ( WaveCountDown < 10 ) {
            return;
        }
        else if ( WaveCountDown < 30 ) {
            WaveCountDown += 30;
            TSCGRI.TimeToNextWave = WaveCountDown;
        }
    }

    bPendingShuffle = false;

    for ( i = 0; i < GameReplicationInfo.PRIArray.Length; ++i ) {
        PRI = GameReplicationInfo.PRIArray[i];
        if ( PRI != none && !PRI.bOnlySpectator && PRI.Team != none && PRI.Team.TeamIndex < 2
                && PlayerController(PRI.Owner) != none  )
        {
            if ( PRI.HasFlag == none )
                RedPlayers[RedPlayers.Length] = PRI;
            else if ( PRI.Team.TeamIndex == 0 )
                ++ConstantReds; // can't move red gnome carrier
            else
                ++ConstantBlues; // can't move blue gnome carrier
        }
    }

    // now all players are in RedPlayers array. Move half to blue.
    RedTeamSize = RedPlayers.length - ConstantReds + ConstantBlues;
    RedTeamSize = max(0, RedTeamSize/2 +  (RedTeamSize%2) * rand(2));

    //Broadcast(Self, "TotalPlayers="$RedPlayers.length @ "RedTeamSize="$RedTeamSize);
    //Broadcast(Self, "ConstantReds="$ConstantReds @ "ConstantBlues="$ConstantBlues);

    while ( RedPlayers.length > RedTeamSize ) {
        i = rand(RedPlayers.length);
        BluePlayers[BluePlayers.length] = RedPlayers[i];
        RedPlayers.remove(i, 1);
    }

    //Broadcast(Self, "RedPlayers="$RedPlayers.length @ "BluePlayers="$BluePlayers.length);

    bTeamChanging = true;
    for ( i=0; i < RedPlayers.length; ++i ) {
        if ( RedPlayers[i].Team.TeamIndex != 0 )
            PlayerController(RedPlayers[i].Owner).ServerChangeTeam(0);
    }
    for ( i=0; i < BluePlayers.length; ++i ) {
        if ( BluePlayers[i].Team.TeamIndex != 1 )
            PlayerController(BluePlayers[i].Owner).ServerChangeTeam(1);
    }
    bTeamChanging = false;

    BroadcastLocalizedMessage(class'TSCMessages', 241);
}

function SetTeamCaptain(byte TeamIndex, PlayerReplicationInfo NewCaptainPRI)
{
    if ( TeamIndex > 1 )
        return;
    if ( NewCaptainPRI != none && (NewCaptainPRI.Team == none || NewCaptainPRI.Team.TeamIndex != TeamIndex) )
        return;

    TSCGRI.TeamCaptain[TeamIndex] = NewCaptainPRI;
    if ( NewCaptainPRI == none )
        TSCVotingOptions.VotingHandler.TeamCaptains[TeamIndex] = none;
    else
        TSCVotingOptions.VotingHandler.TeamCaptains[TeamIndex] = PlayerController(NewCaptainPRI.Owner);
}

function bool ShouldKillOnTeamChange(Pawn TeamChanger)
{
    if ( bTeamChanging )
        return false;

    // do not kill pawn, if changing to a smaller team
    if ( !bWaveInProgress && TeamChanger.PlayerReplicationInfo != none
            && TeamChanger.PlayerReplicationInfo.Team != none
            && TeamChanger.PlayerReplicationInfo.Team.TeamIndex < 2
            && TeamChanger.PlayerReplicationInfo.Team.Size <= Teams[1-TeamChanger.PlayerReplicationInfo.Team.TeamIndex].Size )
    {
        return false;
    }

    return true;
}

function int CalcStartingCashBonus(PlayerController PC)
{
    local int result;

    result = super.CalcStartingCashBonus(PC);
    if ( WaveNum > 0 && LateJoinerCashBonus > 0
            && !PC.PlayerReplicationInfo.bOnlySpectator
            && PC.PlayerReplicationInfo.Team != none
            && PC.PlayerReplicationInfo.Team.TeamIndex < 2
            && PC.PlayerReplicationInfo.Team.Size <= BigTeamSize
            && PC.PlayerReplicationInfo.Team.Size <= Teams[1-PC.PlayerReplicationInfo.Team.TeamIndex].Size
        )
    {
        result += WaveNum * LateJoinerCashBonus/OriginalFinalWave * (1.0 - CurrentTeamMoneyPenalty);
    }
    return result;
}

function bool BecomeSpectator(PlayerController P)
{
    if ( super.BecomeSpectator(P) ) {
        // check if player is a team captain
        if ( P.PlayerReplicationInfo.Team != none && P.PlayerReplicationInfo.Team.TeamIndex < 2 ) {
            if ( TSCGRI.TeamCaptain[P.PlayerReplicationInfo.Team.TeamIndex] == P.PlayerReplicationInfo ) {
                SetTeamCaptain(P.PlayerReplicationInfo.Team.TeamIndex, none);
            }
        }
        return true;
    }

    return false;
}

function SetHumanDamage(EHumanDamageMode Hdmg)
{
    HumanDamageMode = Hdmg;
    TSCGRI.HumanDamageMode = Hdmg;
}

/**
 * Returns true, if friendly fire is disabled. To be precise, FFDisabled() always returns true,
 * if Victim can not be hurt by other player, even from other team.
 *
 * @param instigatedBy  player pawn, which made damage to Victim
 * @param Victim        player pawn, which is hurt by instigatedBy
 * @return true, if Victim shouldn't take damage from other player
*/
function bool FFDisabled(pawn instigatedBy, pawn Victim)
{
    if ( bTradingDoorsOpen || WaveNum == 0 || HumanDamageMode == HDMG_None
            || (!bWaveBossInProgress && TotalMaxMonsters<=0 && NumMonsters < 10) )
        return true;

    if ( HumanDamageMode == HDMG_All )
        return false;

    if ( instigatedBy.GetTeamNum() == Victim.GetTeamNum() ) {
        return HumanDamageMode < HDMG_Normal || TSCGRI.AtOwnBase(Victim);
    }
    return HumanDamageMode < HDMG_PvP && TSCGRI.AtOwnBase(Victim);
}


function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if ( Damage == 0 )
        return 0;

    if( instigatedBy!=injured && KFHumanPawn(injured) != none && instigatedBy != none && MonsterController(InstigatedBy.Controller)==None ) {
        // player to player damage
        if ( FFDisabled(instigatedBy, injured) )
            return 0;

        // same team friendly fire damage will be reduced in KFGameType
        if ( instigatedBy.GetTeamNum()!=injured.GetTeamNum() )
            Damage = max(1, round( Damage * FriendlyFireScale ) );
    }
    return super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local TeamInfo KilledTeam;
    local bool bHadMonsters;
    local byte Ping; // ping is multiplied by 4 in KF!
    local int HealthBeforeDeath;
    local bool bSuicide;

    bHadMonsters = NumMonsters > 0;
    // save team here in cases when Killed destroyed by parent function
    if ( Killed.bIsPlayer && Killed.PlayerReplicationInfo != none ) {
        KilledTeam = Killed.PlayerReplicationInfo.Team;
        Ping = Killed.PlayerReplicationInfo.Ping;
        bSuicide = Killer == Killed && (damageType == class'Suicided' || damageType == class'DamageType');
        if ( ScrnHumanPawn(KilledPawn) != none )
            HealthBeforeDeath = ScrnHumanPawn(KilledPawn).HealthBeforeDeath;
    }

    super.Killed(Killer, Killed, KilledPawn, damageType);


    if ( KilledTeam != none ) {
        AliveTeamPlayerCount[KilledTeam.TeamIndex]--;
        //Broadcast(Self, "HealthBeforeDeath="$HealthBeforeDeath);
        // During Sudden Death wipe team after player's death, unless:
        // - he isn't fully joined yet or lost the connection (ping == 255)
        // - he isn't suicided/disconnected. To prevent cheating, only players with full health are allowed to suicide
        if ( bWaveInProgress && Ping < 255 && damageType != class'DamTypeSudDeath'
                && (!bSuicide || HealthBeforeDeath < 80 ) )
        {
            TSCTeam(KilledTeam).Deaths++;
            if ( TSCGRI.bSuddenDeath )
                WipeTeam(KilledTeam);
        }

        if ( !bTeamWiped && AliveTeamPlayerCount[KilledTeam.TeamIndex] == 0) {
            bTeamWiped = true;
            // lower amount of remaining but not-spawned zeds twice
            if ( TotalMaxMonsters > 1) {
                TotalMaxMonsters /= 2;
                TSCGRI.MaxMonsters = Max(TotalMaxMonsters + NumMonsters,0);
            }
            BroadcastLocalizedMessage(class'TSCMessages', 10+KilledTeam.TeamIndex*100);
            TeamBases[KilledTeam.TeamIndex].SendHome();

        }
    }
    else if  ( NumMonsters == 0 && bHadMonsters && !bSingleTeam && damageType != class'Suicided' ) {
        if ( AliveTeamPlayerCount[0] == 0 ^^ AliveTeamPlayerCount[1] == 0 )
            DramaticEvent(1.0); // do ZED time on winner's kill
    }
}

function ScoreKill(Controller Killer, Controller Other)
{
    super.ScoreKill(Killer, Other);

    if ( KFMonsterController(Other) != none && Killer != none && Killer.PlayerReplicationInfo != None && TSCTeam(killer.PlayerReplicationInfo.Team) != none ) {
        TSCTeam(Killer.PlayerReplicationInfo.Team).ZedKills++;
    }
}

function WipeTeam(TeamInfo Team, optional class<DamageType> DamageType)
{
    local Controller C;
    local Vector NullVector;

    if ( DamageType == none )
        DamageType = class'DamTypeSudDeath';
    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( C.bIsPlayer && C.Pawn != none && C.Pawn.Health > 0
                && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team == Team )
        {
            C.Pawn.Died(none, DamageType, NullVector);
        }
    }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local Controller P;
    local PlayerController Player;
    local bool bSetAchievement;
    local string MapName;
    local String EndSong;

    if ( Reason == "TeamScoreLimit" ) {
        if ( AliveTeamPlayerCount[0] > 0 && AliveTeamPlayerCount[1] == 0 ) {
            TSCGRI.Winner = Teams[0];
            EndSong = SongRedWin;
        }
        else if ( AliveTeamPlayerCount[0] == 0 && AliveTeamPlayerCount[1] > 0 ) {
            TSCGRI.Winner = Teams[1];
            EndSong = SongBlueWin;
        }
        else
            return false;
        TSCGRI.EndGameType = 2;
        ScrnBalanceMut.BroadcastMessage(TeamInfo(TSCGRI.Winner).GetHumanReadableName() $ " team won the game on wave " $ string(WaveNum+1), true);
    }
    else {
        if ( WaveNum >= OriginalFinalWave + OvertimeWaves + SudDeathWaves ) {
            TSCGRI.Winner = none;
            TSCGRI.EndGameType = 2;
            EndSong = SongBothWin;

            if ( GameDifficulty >= 2.0 )
            {
                bSetAchievement = true;

                // Get the MapName out of the URL
                MapName = GetCurrentMapName(Level);
            }
        }
        else {
            TSCGRI.EndGameType = 1;
            EndSong = SongBothWiped;
        }
    }

    if ( (GameRulesModifiers != None) && !GameRulesModifiers.CheckEndGame(Winner, Reason) ) {
        TSCGRI.EndGameType = 0;
        TSCGRI.Winner = none;
        return false;
    }

    // if we reached here, game must be ended
    EndTime = Level.TimeSeconds + EndTimeDelay;

    for ( P = Level.ControllerList; P != none; P = P.nextController )
    {
        Player = PlayerController(P);
        if ( Player != none ) {
            Player.ClientSetBehindView(true);
            Player.ClientGameEnded();

            if ( bSetAchievement && Player.PlayerReplicationInfo != none && KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements) != none
                    && (Player.PlayerReplicationInfo.Team == GameReplicationInfo.Winner || GameReplicationInfo.Winner == none) )
            {
                KFSteamStatsAndAchievements(Player.SteamStatsAndAchievements).WonGame(MapName, GameDifficulty, KFGameLength == GL_Long);
            }

            if (KFPlayerController(Player)!= none)
                KFPlayerController(Player).NetPlayMusic(EndSong, 0.5, 0);
        }

        P.GameHasEnded();
    }

    if ( CurrentGameProfile != none )
        CurrentGameProfile.bWonMatch = false;

    return true;
}

function TSCBaseGuardian SpawnBaseGuardian(byte TeamIndex)
{
    local NavigationPoint N;
    local TSCBaseGuardian gnome;

    if ( TeamIndex >= 2 )
        return none;

    if ( TeamBases[TeamIndex] != none )
        return TeamBases[TeamIndex]; // already spawned

    gnome = spawn(BaseGuardianClasses[TeamIndex], TSCGRI);
    if ( gnome == none ) {
        // if unable to spawn at zero point, try player spawn
        N = FindPlayerStart(none, TeamIndex);
        if ( N != none )
            gnome = spawn(BaseGuardianClasses[TeamIndex], TSCGRI, '', N.Location);
    }
    if ( gnome == none ) {
        // realy? can't spawn gnome at player spawn?!
        N = Level.NavigationPointList;
        while ( gnome == none && N != none ) {
            gnome = spawn(BaseGuardianClasses[TeamIndex], TSCGRI, '', N.Location);
            N = N.nextNavigationPoint;
        }
    }
    if ( gnome == none ) {
        // map is totally fucked up
        log("Unable to spawn Base Guardian for team " $ TeamIndex, 'TSC');
        return none;
    }

    gnome.Team = Teams[TeamIndex];
    gnome.TSCGRI = TSCGRI;
    TeamBases[TeamIndex] = gnome;

    return gnome;
}

// balances the team referenced by SmallTeamIndex
// BalanceMult shows the relatice amount of bonus that must be given to small team
// Usually BalanceMult=BigTeam.Size / SmallTeam.Size
// callint BalanceTeam(2, 1.0) removes any previously given bonuses
function BalanceTeams(byte SmallTeamIndex, float BalanceMult)
{
    local Controller C;
    local Inventory Inv;
    local Syringe S;
    local ScrnHumanPawn ScrnPawn;
    local bool bInSmallTeam;

    if ( bSingleTeamGame )
        return;

    for ( C = Level.ControllerList; C != none; C = C.nextController ) {
        if ( !C.bIsPlayer || C.PlayerReplicationInfo == none || C.Pawn == none )
            continue;
        ScrnPawn = ScrnHumanPawn(C.Pawn);
        if ( ScrnPawn == none )
            continue;

        bInSmallTeam = C.PlayerReplicationInfo.Team != none
                        && C.PlayerReplicationInfo.Team.TeamIndex == SmallTeamIndex;
        ScrnPawn.HealthBonus = 0;
        if ( bInSmallTeam )
            ScrnPawn.HealthBonus *= BalanceMult; // increases max health
        ScrnPawn.GiveHealth(0, 100); // updates max health
        for ( Inv = ScrnPawn.Inventory; Inv != none; Inv = Inv.Inventory ) {
            S = Syringe(Inv);
            if ( S != none ) {
                S.HealBoostAmount = S.default.HealBoostAmount;
                // give more healing points to smaller team
                if ( bInSmallTeam )
                    S.HealBoostAmount *= BalanceMult;
            }
        }
    }
}

// returns wave number relative to the current game length
function byte RelativeWaveNum(float LongGameWaveNum)
{
    if ( OriginalFinalWave == 10 )
        return ceil(LongGameWaveNum);
    return ceil(LongGameWaveNum * OriginalFinalWave / 10.0);
}

function SetupWave()
{
    local int i;

    bWaveInProgress = true;
    TSCGRI.bWaveInProgress = true;

    if ( (WaveNum+1) == RelativeWaveNum(ScrnBalanceMut.LockTeamAutoWave) )
        LockTeams();

    NextMonsterTime = Level.TimeSeconds + 5.0;
    TraderProblemLevel = 0;
    rewardFlag=false;
    ZombiesKilled=0;
    WaveMonsters = 0;
    WaveNumClasses = 0;
    bWaveEnding = false;

    SetupPickups();

    i = rand(2);
    TeamBases[i].ScoreOrHome();
    TeamBases[1-i].ScoreOrHome();

    WavePlayerCount = AlivePlayerCount;
    BigTeamSize = max(AliveTeamPlayerCount[0], AliveTeamPlayerCount[1]);
    SmallTeamSize = min(AliveTeamPlayerCount[0], AliveTeamPlayerCount[1]);
    bSingleTeam = AliveTeamPlayerCount[0] == 0 || AliveTeamPlayerCount[1] == 0;
    bTeamWiped = bSingleTeam;

    if ( bSingleTeam || AliveTeamPlayerCount[0] == AliveTeamPlayerCount[1] ) {
        BalanceTeams(2, 1.0); // remove bonuses
        SmallTeamSize = BigTeamSize;
    }
    else if ( AliveTeamPlayerCount[0] < AliveTeamPlayerCount[1] )
        BalanceTeams(0, float(AliveTeamPlayerCount[1])/AliveTeamPlayerCount[0]);
    else if ( AliveTeamPlayerCount[0] > AliveTeamPlayerCount[1] )
        BalanceTeams(1, float(AliveTeamPlayerCount[0])/AliveTeamPlayerCount[1]);

    ScrnGameLength.RunWave();

    CalcDoshDifficultyMult();

    if( WaveNum == FinalWave && bUseEndGameBoss ) {
        StartWaveBoss();
        return;
    }

    if ( WaveNum == 0 ) {
        BroadcastLocalizedMessage(class'TSCMessages', 230); // human damage disabled
    }
    else if ( WaveNum >= OriginalFinalWave ) {
        if ( WaveNum >= OriginalFinalWave + OvertimeWaves ) {
            TSCGRI.bSuddenDeath = true;
            BroadcastLocalizedMessage(class'TSCMessages', 302); // sudden death
            // if one of the team do not have a base - wipe it
        }
        else {
            BroadcastLocalizedMessage(class'TSCMessages', 201); // overtime
            // lock teams one wave before Sudden Death
            if ( bLockTeamsOnSuddenDeath && SudDeathWaves > 0 && WaveNum+1 == OriginalFinalWave + OvertimeWaves )
                LockTeams();
        }
    }
    else if ( HumanDamageMode > HDMG_None ) {
        if ( HumanDamageMode >= HDMG_Normal )
            BroadcastLocalizedMessage(class'TSCMessages', 231); // human damage enabled
        else
            BroadcastLocalizedMessage(class'TSCMessages', 232); // enemy fire enabled
    }

    TotalMaxMonsters = ScrnGameLength.GetWaveZedCount() + NumMonsters;
    WaveEndTime = ScrnGameLength.GetWaveEndTime();
    AdjustedDifficulty = GameDifficulty + lerp(float(WaveNum)/FinalWave, 0.1, 0.3);

    MaxMonsters = min(TotalMaxMonsters, MaxZombiesOnce); // max monsters that can be spawned
    TSCGRI.MaxMonsters = TotalMaxMonsters; // num monsters in wave replicated to clients
    TSCGRI.MaxMonstersOn = true; // I've no idea what is this for

    NextSquadTeam = rand(2); // pickup random team for the next special squad
    for( i=0; i<ZedSpawnList.Length; ++i )
        ZedSpawnList[i].Reset();

    //Now build the first squad to use
    SquadsToUse.Length = 0; // force BuildNextSquad() to rebuild squad list
    SpecialListCounter = 0;
    BuildNextSquad();

    TSCTeams[0].WaveKills = TSCTeams[0].ZedKills;
    TSCTeams[1].WaveKills = TSCTeams[1].ZedKills;
    TSCTeams[0].PrevMinKills = TSCTeams[0].ZedKills;
    TSCTeams[1].PrevMinKills = TSCTeams[1].ZedKills;
    TSCTeams[0].LastMinKills = TSCTeams[0].ZedKills;
    TSCTeams[1].LastMinKills = TSCTeams[1].ZedKills;
}

function bool AddSquad()
{
    if ( NextSpawnSquad.length == 0 ) {
        NextSquadTeam = 1 - NextSquadTeam;
        LastZVol = none;

        if ( PendingSpecialSquad.length != 0 ) {
            // spawn the same special squad for another team
            NextSpawnSquad = PendingSpecialSquad;
            PendingSpecialSquad.length = 0;
        }
        else {
            ScrnGameLength.LoadNextSpawnSquad(NextSpawnSquad);
            if ( NextSpawnSquad.length == 0 )
                return false;

            if ( ScrnGameLength.bLoadedSpecial ) {
                if (!bTeamWiped)
                    PendingSpecialSquad = NextSpawnSquad; // backup for another team
                bCheckSquadTeam = true; // One special squad per each team
                ZedSpawnLoc = ZSLOC_CLOSER; // spawn close to the designated team
            }
            else {
                // Check teams only when they are equal in number.
                // If teams are uneven, then just pick up random player as squad's target
                bCheckSquadTeam = BigTeamSize == SmallTeamSize;
               ZedSpawnLoc = ZSLOC_RANDOM; // make zeds spawn more random on the map
            }
        }
    }
    return super.AddSquad();
}

// returns random alive player
function Controller FindSquadTarget()
{
    local array<Controller> CL;
    local Controller C;

    for( C=Level.ControllerList; C!=None; C=C.NextController ) {
        if ( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health>0
                && (bTeamWiped || !bCheckSquadTeam || C.GetTeamNum() == NextSquadTeam) )
            CL[CL.Length] = C;
    }
    if( CL.Length>0 )
        return CL[Rand(CL.Length)];

    return super.FindSquadTarget(); // in case when there are no team players alive
}

protected function StartTourney()
{
    super.StartTourney();

    GameReplicationInfo.bNoTeamSkins = bSingleTeamGame;

    OvertimeTeamMoneyPenalty = 0.50;
    LateJoinerCashBonus = 0;
    bAntiBlocker = true;
    bVoteHDmg = false;
}

function bool RewardSurvivingPlayers()
{
    // At this WaveNum isn't increased yet
    if ( OvertimeTeamMoneyPenalty > 0 && WaveNum+1 >= OriginalFinalWave ) {
        CurrentTeamMoneyPenalty = fmin(CurrentTeamMoneyPenalty + OvertimeTeamMoneyPenalty, 1);
        Teams[0].Score = int(Teams[0].Score * (1.0 - CurrentTeamMoneyPenalty));
        Teams[1].Score = int(Teams[1].Score * (1.0 - CurrentTeamMoneyPenalty));
        Broadcast(Self, strBudgetCut @ int(100*(CurrentTeamMoneyPenalty)) $ "%");
    }

    return super.RewardSurvivingPlayers();
}

function ShowPathTo(PlayerController P, int DestinationIndex)
{
    if ( DestinationIndex == 1 )
        ShowPathToBase(P);
    else
        super.ShowPathTo(P, DestinationIndex); // show path to shop
}

function ShowPathToBase(PlayerController P)
{
    local TSCBaseGuardian gnome;
    local byte TeamNum;

    TeamNum = P.PlayerReplicationInfo.Team.TeamIndex;
    gnome = TeamBases[TeamNum];
    if ( gnome == none || !gnome.bActive || TSCGRI.AtOwnBase(P.Pawn) )
    {
        ScrnPlayerController(P).ServerShowPathTo(255); // turn off
        return;
    }

    if ( P.FindPathToward(gnome, false) != None ) {
        Spawn(BaseWhisp, P,, P.Pawn.Location);
    }
}

function ShopVolume TeamShop(byte TeamIndex)
{
    switch (TeamIndex) {
        case 0: return TSCGRI.CurrentShop;
        case 1: return TSCGRI.BlueShop;
    }
    return none;
}

State MatchInProgress
{
    function WaveTimer()
    {
        super.WaveTimer();

        if ( TotalMaxMonsters <= 0 ) {
            if ( NumMonsters > 0 && NumMonsters < 10 ) {
                if ( bWaveEnding ) {
                    if ( --WaveEndingCountDown <= 0) {
                        KillRemainingZeds(true);
                        bWaveEnding = false;
                    }
                    // tell about disabling Human Damage 3 seconds after auto-end message
                    if ( HumanDamageMode > HDMG_None && WaveEndingCountDown == default.WaveEndingCountDown-3 )
                        BroadcastLocalizedMessage(class'TSCMessages', 230);
                }
                else {
                    bWaveEnding = true;
                    WaveEndingCountDown = default.WaveEndingCountDown; // force end wave in 30 seconds
                    BroadcastLocalizedMessage(class'TSCMessages', 200); // tell about auto-end
                }
            }
        }
        if ( (int(WaveTimeElapsed)%60) == 0 ) {
                TSCTeams[0].PrevMinKills = TSCTeams[0].LastMinKills;
                TSCTeams[0].LastMinKills = TSCTeams[0].ZedKills;
                TSCTeams[1].PrevMinKills = TSCTeams[1].LastMinKills;
                TSCTeams[1].LastMinKills = TSCTeams[1].ZedKills;
        }
    }

    function DoWaveEnd()
    {
        local int NextWave;

        NextWave = WaveNum + 1;
        if ( !bSingleTeam && (AliveTeamPlayerCount[0] == 0 ^^ AliveTeamPlayerCount[1] == 0) ) {
            EndGame(None,"TeamScoreLimit");
        }
        else if ( AlivePlayerCount > 0 && NextWave >= OriginalFinalWave ) {
            if ( NextWave >= OriginalFinalWave + OvertimeWaves + SudDeathWaves ) {
                WaveNum++;
                EndGame(None,"TimeLimit");
                return;
            }
            if ( OvertimeWaves > 0 && NextWave == OriginalFinalWave ) {
                BroadcastLocalizedMessage(class'TSCMessages', 201);
            }
            else if ( NextWave >= OriginalFinalWave + OvertimeWaves ) {
                TSCGRI.bSuddenDeath = true;
                BroadcastLocalizedMessage(class'TSCMessages', 202);
            }
            FinalWave++;
        }

        if ( !bSingleTeamGame ) {
            if ( TeamBases[0] == none )
                SpawnBaseGuardian(0); // just in case
            // don't check for none here making warning message appear in server log
            // to point on indicated bad map design
            TeamBases[0].SendHome();
        }
        if ( TeamBases[1] == none )
            SpawnBaseGuardian(1);
        TeamBases[1].SendHome();

        if ( ScrnGameLength != none && NextWave >= ScrnGameLength.Waves.length ) {
            // if there are not enough waves in ScrnGameLength, then just re-load the last one again
            WaveNum = ScrnGameLength.Waves.length - 2;
        }
        super.DoWaveEnd();
        if ( !bGameEnded ) {
            WaveNum = NextWave;
        }
        TSCGRI.WaveNumber = WaveNum;

        if ( bPendingShuffle ) {
            ShuffleTeams();
            WaveCountDown += 30;
            TSCGRI.TimeToNextWave = WaveCountDown;
        }
    }

    function SelectShop()
    {
        local array<ShopVolume> TempShopList;
        local int i, t;

        // Can't select a shop if there aren't any
        if ( ShopList.Length == 0 )
            return;

        for ( i = 0; i < ShopList.Length; i++ ) {
            if ( !ShopList[i].bAlwaysClosed )
                TempShopList[TempShopList.Length] = ShopList[i];
        }
        if ( TempShopList.Length == 1 ) {
            // just to avoid deadends, but TSC games shouldn't be played on maps with only 1 shop
            TSCGRI.CurrentShop = TempShopList[0];
            TSCGRI.BlueShop = TempShopList[0];
            return;
        }

        // select random shop for random team
        i = Rand(TempShopList.Length);
        if ( TempShopList[i] == TSCGRI.CurrentShop )
            t = 1; // can't be the same shop twice for the red team, so set it for blue
        else if ( TempShopList[i] == TSCGRI.BlueShop )
            t = 0; // can't be the same shop twice for the blue team, so set it for red
        else
            t = rand(2); // set shop for random team
        TeamShops[t] = TempShopList[i];
        TempShopList.remove(i, 1);

        // select shop for the other team
        t = 1 - t;
        i = Rand(TempShopList.Length);
        if ( TempShopList[i] == TSCGRI.GetTeamShop(t) ) {
            // can't use the same shop twice
            TempShopList.remove(i, 1);
            i = Rand(TempShopList.Length);
        }
        TeamShops[t] = TempShopList[i];

        // write shops to GRI
        TSCGRI.CurrentShop = TeamShops[0];
        TSCGRI.BlueShop = TeamShops[1];
    }

    function OpenShops()
    {
        local int i;
        local Controller C;

        bTradingDoorsOpen = True;

        for( i=0; i<ShopList.Length; i++ ) {
            if( !ShopList[i].bAlwaysClosed && ShopList[i].bAlwaysEnabled )
                ShopList[i].OpenShop();
        }

        if ( TSCGRI.CurrentShop == none || TSCGRI.BlueShop == none )
            SelectShop();

        if ( !bSingleTeamGame )
            TSCGRI.CurrentShop.OpenShop();
        TSCGRI.BlueShop.OpenShop();

        if ( !bNoBases ) {
            if ( !bSingleTeamGame )
                TeamBases[0].MoveToShop(TSCGRI.CurrentShop);
            TeamBases[1].MoveToShop(TSCGRI.BlueShop);
        }

        // Tell all players to start showing the path to the trader
        For( C=Level.ControllerList; C!=None; C=C.NextController )
        {
            if( C.Pawn!=None && C.Pawn.Health>0 )
            {
                // Disable pawn collision during trader time
                C.Pawn.bBlockActors = !bAntiBlocker;

                if( KFPlayerController(C) !=None )
                {
                    KFPlayerController(C).SetShowPathToTrader(true);
                    KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 2);
                }
            }
        }
    }

    // function float GetMinSpawnDelay()
    // {
        // local float result;

        // result = super.GetMinSpawnDelay();
        // if ( !bTeamWiped )
            // result *= 0.5; // up to twice faster spawns
        // return result;
    // }
} //MatchInProgress



defaultproperties
{
    GameName="Team Survival Competition"
    Description="Two Teams, One Floor. Killing Floor. There are two teams competing in surviving specimen invasion on the same map and at the same time. Both teams can cooperate, fight against each other or just stay each in own corner of the map - choice is up to you..."

    KFHints[0]="Each team has own Trader. Team can not get the same Trader two times in a row."
    KFHints[1]="When the Trader opens her doors, she drops Base Guardian nearby. Take it to your base!"
    KFHints[2]="Pick up a Base Guardian next to the Trader, bring it where you want your Base to be and press SETUPBASE(ALTFIRE) button."
    KFHints[3]="Base can be established only once per wave. Once set up, it can not be moved."
    KFHints[4]="If nobody stays at a Base, then the Guardian gets frustrated and disappears. No Guardian = No Base."
    KFHints[5]="Base Guardian has 2 cool features: it protects you from the Friendly Fire and damages enemy squad members."
    KFHints[6]="Base Guardian hurts enemy players withing the range of the Base no matter of Friendly Fire setting."
    KFHints[7]="Base can be established during the Trader Time only. So hurry up!"
    KFHints[8]="Other squad cannot stay at your Base."
    KFHints[9]="You can play without a Base too, but who is going to protect you from the Friendly Fire then?.."
    KFHints[10]="Setting up a Base in a strategical map point is a key to success."
    KFHints[11]="You can not set up own Base at Enemy Base. However, Bases may intersect."
    KFHints[12]="While carrying Base Guardian you can pass it to other player by pressing the same key as throwing a weapon."
    KFHints[13]="Best camping spots in standard KF game are not necessarily the best spots in TSC."
    KFHints[14]="Team gets wiped if ANY its member dies during SUDDEN DEATH wave."
    KFHints[15]="Wiping enemy squad doesn't grant you a win. You still have to survive till the end of the wave."
    KFHints[16]="TSC isn't Versus or Team Deathmatch game. You don't have to fight the enemy team. Leave that job to ZEDs."
    KFHints[17]="You can wait until ZEDs wipe out enemy squad or help them. Help who? ZEDs or the other squad? Thr choice is up to you..."
    KFHints[18]="There are 4 Human Damage rules in TSC: OFF, No Friendly Fire, Normal and PvP. Type MVOTE TEAM HDMG for the info."
    KFHints[19]="When Human Damage is OFF, you can not damage other squad's members. Your Guardian can though."
    KFHints[20]="Human Damage is OFF during the first wave, Trader Time and when there are less than 10 zeds left in a wave."
    KFHints[21]="Human Damage is ON during waves (except first one). Staying at own Base protects you from it."
    KFHints[22]="You can switch team during the Trader Time. Type SWITCHTEAM in the console or bind it to key."
    KFHints[23]="Switching the team during the game kills you first. Then restarts you as other squad's member."
    KFHints[24]="You can not switch a team during a wave."
    KFHints[25]="Medics and medics only can see health and armor of enemy players"
    KFHints[26]="TSC, same as KF, is not about winning or losing. It is all about surviving."
    KFHints[27]="TSC doesn't force you to play against the other squad. You can cooperate and survive together. But nobody said that the other squad thinks the same..."
    KFHints[28]="During the Trader Time, if other squad has 2 players less than yours, you can switch to it on-the-fly (without dying)."

    DefaultEnemyRosterClass="ScrnBalanceSrv.TSCTeam"
    RedTeamHumanName="British"
    BlueTeamHumanName="Steampunk"
    bNoLateJoiners=False
    bPlayersVsBots=False
    bSingleTeamGame=False
    bUseEndGameBoss=False
    MinNetPlayers=2
    MaxPlayers=12
    MaxZombiesOnce=48
    StandardMaxZombiesOnce=48
    HDmgScale=0.10
    FriendlyFireScale=0.10
    KFGameLength=1
    FinalWave=7
    WaveEndingCountDown=30 // 30 seconds until auto killing zeds at the ending of the wave ( <10 zeds remaining)
    bLockTeamsOnSuddenDeath=true
    bAntiBlocker=True

    bClanCheck=True
    ClanTags(0)=(Prefix="[",Postfix="]")
    ClanTags(1)=(Prefix="(",Postfix=")")
    ClanTags(2)=(Prefix="-=",Postfix="=-")
    ClanTags(3)=(Prefix="{",Postfix="}")
    ClanTags(4)=(Prefix="<",Postfix=">")
    ClanTags(5)=(Prefix=".:",Postfix=":.")
    ClanTags(6)=(Prefix="*",Postfix="*")
    ClanTags(7)=(Prefix="",Postfix="-")
    ClanTags(8)=(Prefix=".",Postfix="")


    PathWhisps(0)="KFMod.RedWhisp"
    PathWhisps(1)="ScrnBalanceSrv.BlueWhisp"
    BaseWhisp=class'ScrnBalanceSrv.GreenWhisp'
    BaseRadius=1250 // 25 m
    MinBaseZ=-60
    MaxBaseZ=200
    HumanDamageMode=HDMG_Normal
    bVoteHDmg=True
    bVoteHDmgOnlyBeforeStart=False

    OvertimeWaves=2 // if both teams survived regular waves, add 2 overtime waves
    SudDeathWaves=1 // if both team survived overtime waves, add a Sudden Death wave
    OvertimeTeamMoneyPenalty=0.33 // 33% less money each wave
    LateJoinerCashBonus=700 // $700 will be given before final wave. Cash bonus is proportionally smaller in earlier waves.
    strBudgetCut="Team wallets were cut off by"

    SongRedWin="KF_WPrevention"
    SongBlueWin="KFh6_Launch"
    SongBothWin="KF_Containment"
    SongBothWiped="KF_Hunger"

    //GameMessageClass=Class'ScrnBalanceSrv.TSCGameMessages'
    GameReplicationInfoClass=Class'ScrnBalanceSrv.TSCGameReplicationInfo'
    //PlayerControllerClass=class'ScrnBalanceSrv.TSCPlayerController'
    //PlayerControllerClassName="ScrnBalanceSrv.TSCPlayerController"
    //HUDType="ScrnBalanceSrv.TSCHUD" // set it in InitGame() after ServerPerksMut loading to enable chat smiles
    //LoginMenuClass="ScrnBalanceSrv.TSCInvasionLoginMenu"
    BaseGuardianClasses(0)=class'ScrnBalanceSrv.TSCGuardianRed'
    BaseGuardianClasses(1)=class'ScrnBalanceSrv.TSCGuardianBlue'

    ScreenShotName="TSC_T.Team.TSC"
}
