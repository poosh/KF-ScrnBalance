class TSCGame extends ScrnGameType
    config;

var TSCGameReplicationInfo TSCGRI;
var TSCVotingOptions TSCVotingOptions;
var TSCClanVoting ClanVoting;
var int OriginalFinalWave;

// use Teams[t].GetHumanReadableName() instead
var deprecated string RedTeamHumanName, BlueTeamHumanName;

var config byte OvertimeWaves;         // number of Overtime waves
var config byte SudDeathWaves;         // number of Sudden Death waves
var config string SongRedWin, SongBlueWin, SongBothWin, SongBothWiped;

var localized string strBudgetCut;

var TSCBaseGuardian TeamBases[2];
var float BaseRadius; // Base radius
var float MinBaseZ, MaxBaseZ; // min and max Z difference between player and base
var float BaseInvulTime; // for how long Base Guardians cannot be damage after the wave start

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
var byte WaveMinuteTimer;
var float WaveKillReqPct; // min kills per team in each wave (fraction of TotalMaxMonsters)

var bool bPendingShuffle; // shuffle teams at the end of the wave
var protected bool bTeamChanging; // indicates that game changes team members, e.g. doing shuffle

var config bool bLockTeamsOnSuddenDeath;

struct SClanTags {
    var config string Prefix, Postfix;
};
var config array<SClanTags> ClanTags;
var config bool bClanCheck;
var bool bClanGame; // mvote clan game

var deprecated bool bCustomHUD, bCustomScoreboard;

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

var transient bool bRecalcInventory;

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
    if ( OriginalFinalWave > 0 ) {
        TSCGRI.FinalWave = OriginalFinalWave;
    }
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    TSCTeams[0] = TSCTeam(Teams[0]);
    TSCTeams[1] = TSCTeam(Teams[1]);

    SpawnBaseGuardian(0);
    Teams[0].HomeBase = TeamBases[0];
    Teams[0].TeamColor=class'Canvas'.static.MakeColor(180, 0, 0, 255);

    SpawnBaseGuardian(1);
    Teams[1].HomeBase = TeamBases[1];
    Teams[1].TeamColor=class'Canvas'.static.MakeColor(32, 92, 255, 255);
}

// InitGame() gets called before PreBeginPlay()! Therefore, GameReplicationInfo does not exist yet.
event InitGame( string Options, out string Error )
{
    local ScrnVotingHandlerMut VH;
    local Mutator M;

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
        TSCVotingOptions.TSC = self;

        if (!bSingleTeamGame) {
            ClanVoting = TSCClanVoting(VH.AddVotingOptions(class'TSCClanVoting'));
            ClanVoting.TSC = self;
        }
    }
    else {
        log("Voting (mvote) disabled.", class.name);
    }

    if ( bSingleTeamGame ) {
        OvertimeWaves = 0;
        SudDeathWaves = 0;
    }
    else {
        bUseEndGameBoss = false;
        if ( ScrnGameLength != none ) {
            OvertimeWaves = ScrnGameLength.OTWaves;
            SudDeathWaves = ScrnGameLength.SDWaves;
            if ( ScrnGameLength.NWaves + OvertimeWaves + SudDeathWaves > 0 ) {
                FinalWave = ScrnGameLength.NWaves;
            }
            else {
                FinalWave = max(1, ScrnGameLength.Waves.length - OvertimeWaves - SudDeathWaves);
            }
        }
        else {
            FinalWave = max(GetIntOption(Options, "NWaves", FinalWave), 1);
            OvertimeWaves = max(GetIntOption(Options, "OTWaves", OvertimeWaves), 0);
            SudDeathWaves = max(GetIntOption(Options, "SDWaves", SudDeathWaves), 0);
        }
    }
    OriginalFinalWave = FinalWave;
    if ( FinalWave == 0 ) {
        FinalWave = OvertimeWaves + SudDeathWaves;
    }

    // force FriendlyFireScale to 10%
    FriendlyFireScale = HDmgScale;
    default.FriendlyFireScale = HDmgScale;

    // set MaxZombiesOnce to at least 48, unless it is a small map with only 1 trader
    if ( MaxZombiesOnce < default.MaxZombiesOnce && !bSingleTeamGame && ShopList.Length > 1 ) {
        MaxZombiesOnce = default.MaxZombiesOnce;
        StandardMaxZombiesOnce = MaxZombiesOnce;
    }
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

function bool IsInvited(PlayerController PC)
{
    if (super.IsInvited(PC))
        return true;

    // auto-invite clan members during the lobby
    if (bClanGame && !GameReplicationInfo.bMatchHasBegun
            && (TSCTeams[0].ClanRep.Clan.IsMember(PC.GetPlayerIDHash())
                || TSCTeams[1].ClanRep.Clan.IsMember(PC.GetPlayerIDHash()))) {
        InvitePlayer(PC);
        return true;
    }
    return false;
}

function bool StartClanGame(TSCClanInfo RedClan, TSCClanInfo BlueClan)
{
    return false;
}

// extracts ClanName from PlayerName or returns empty string, if player name
// doesn't contain clan.
function string ClanName(string PlayerName)
{
    local int i, namelen,  pos;
    local string S;

    if ( PlayerName == "" )
        return "";

    PlayerName = class'ScrnFunctions'.static.StripColorTags(PlayerName);
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
    Broadcast(Self, ScrnBalanceMut.ColoredPlayerName(myPRI)$" associated with ["$MyClan$"] clan");

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
    local PlayerController PC;
    local UnrealTeamInfo NewTeam;
    local TSCBaseGuardian gnome;
    local bool b;

    // if (CurrentGameProfile != none)
    // {
        // if (!CurrentGameProfile.CanChangeTeam(Other, num)) return false;
    // }

    if ( Other.PlayerReplicationInfo == none )
        return false; // no PlayerReplicationInfo = no team  -- PooSH

    PC = PlayerController(Other);
    if ( PC != none && Other.PlayerReplicationInfo.bOnlySpectator ) {
        Other.PlayerReplicationInfo.Team = None;
        return true;
    }

    if ( !bSingleTeamGame ) {
        if ( bTeamChanging && num < 2 ) {
            NewTeam = Teams[num];
        }
        else if (bClanGame && PC != none && PC.bIsPlayer) {
            b = TSCTeams[0].ClanRep.Clan.IsMember(PC.GetPlayerIDHash());
            if (b != TSCTeams[1].ClanRep.Clan.IsMember(PC.GetPlayerIDHash())) {
                // member of one and only one clan
                if (b) {
                    NewTeam = TSCTeams[0];
                }
                else {
                    NewTeam = TSCTeams[1];
                }
            }
        }

        if ( NewTeam == None && bClanCheck && !bNewTeam
                && !GameReplicationInfo.bMatchHasBegun && Other.PlayerReplicationInfo != none ) {
            NewTeam = MyClanTeam(Other.PlayerReplicationInfo);
        }
    }

    if ( NewTeam == none ) {
        NewTeam = Teams[PickTeam(num,Other)];
    }

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

    if ( NewTeam.AddToTeam(Other) ) {
        BroadcastLocalizedMessage( GameMessageClass, 3, Other.PlayerReplicationInfo, None, NewTeam );

        if ( bNewTeam && PlayerController(Other)!=None ) {
            GameEvent("TeamChange",string(NewTeam.TeamIndex),Other.PlayerReplicationInfo);
            // give starting cash fot team changers
            GiveStartingCash(PlayerController(Other));
        }

        if (bClanGame && NewTeam.TeamIndex < 2 && TSCGRI.TeamCaptain[NewTeam.TeamIndex] == none
                && TSCTeam(NewTeam).ClanRep.Clan.IsCaptain(PC.GetPlayerIDHash())) {
            // clan captain joined the party
            SetTeamCaptain(NewTeam.TeamIndex, Other.PlayerReplicationInfo);

        }
    }

    return true;
}

function byte PickTeam(byte num, Controller C)
{
    local UnrealTeamInfo SmallTeam, BigTeam, NewTeam;
    //local Controller B;
    //local int BigTeamBots, SmallTeamBots;

    if ( bSingleTeamGame )
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

    if ( bSingleTeamGame || bClanGame ) {
        bPendingShuffle = false;
        return;
    }

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

function ForceClanTeams()
{
    local byte t;
    local int i, p;
    local PlayerController PC;
    local PlayerReplicationInfo PRI;
    local string id;
    local int CaptainPriority[2];

    if (!bClanGame)
        return;

    SetTeamCaptain(0, none);
    SetTeamCaptain(1, none);
    CaptainPriority[0] = 255;
    CaptainPriority[1] = 255;

    InviteList.length = 0;
    ScrnBalanceMut.bTeamsLocked = false;
    bTeamChanging = true;
    for ( i = 0; i < TSCGRI.PRIArray.Length; ++i ) {
        PRI = TSCGRI.PRIArray[i];
        if (PRI == none)
            continue;  // is this possible?
        PC = PlayerController(PRI.Owner);
        if (PC == none)
            continue;
        id = PC.GetPlayerIDHash();
        for (t = 0; t < 2; ++t) {
            p = TSCTeams[t].ClanRep.Clan.CaptainPriority(id);
            if (p >= 0) {
                PC.ServerChangeTeam(t);
                if (p < CaptainPriority[t]) {
                    SetTeamCaptain(t, PRI);
                    CaptainPriority[t] = p;
                }
                break;
            }
            else if (TSCTeams[t].ClanRep.Clan.IsPlayer(id)) {
                PC.ServerChangeTeam(t);
                break;
            }
            else if (PRI.Team == TSCTeams[t]) {
                PC.BecomeSpectator();
                UninvitePlayer(PC);
            }
        }
    }
    bTeamChanging = false;
    LockTeams();
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
        return HumanDamageMode < HDMG_Normal || TSCGRI.AtOwnBase(Victim, true);
    }
    return HumanDamageMode < HDMG_PvP && TSCGRI.AtOwnBase(Victim, true);
}


function int ReduceDamage(int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if ( Damage == 0 )
        return 0;

    if( instigatedBy!=injured && KFHumanPawn(injured) != none && instigatedBy != none && MonsterController(InstigatedBy.Controller)==None ) {
        // player to player damage
        if ( FFDisabled(instigatedBy, injured) )
            return 0;

        // same team friendly fire damage will be reduced in ScrnGameType
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

    if ( KFMonsterController(Other) != none && Killer != none && Killer.PlayerReplicationInfo != None
            && TSCTeam(killer.PlayerReplicationInfo.Team) != none ) {
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

function bool AllowGameEnd(PlayerReplicationInfo WinnerPRI, string Reason)
{
    local TSCTeam WinnerTeam, LoserTeam;

    if ( !bSingleTeam && Reason == "TeamScoreLimit" ) {
        if ( AliveTeamPlayerCount[0] == 0 ^^ AliveTeamPlayerCount[1] == 0 ) {
            if ( AliveTeamPlayerCount[1] == 0 ) {
                WinnerTeam = TSCTeams[0];
                LoserTeam = TSCTeams[1];
                EngGameSong = SongRedWin;
            }
            else {
                WinnerTeam = TSCTeams[1];
                LoserTeam = TSCTeams[0];
                EngGameSong = SongBlueWin;
            }
        }
        else if ( TotalMaxMonsters <= 0 && NumMonsters <= 0 && (TSCTeams[0].GetCurWaveKills() < TSCGRI.WaveKillReq
                ^^ TSCTeams[1].GetCurWaveKills() < TSCGRI.WaveKillReq) ) {
            if ( TSCTeams[1].GetCurWaveKills() < TSCGRI.WaveKillReq ) {
                WinnerTeam = TSCTeams[0];
                LoserTeam = TSCTeams[1];
                EngGameSong = SongRedWin;
            }
            else {
                WinnerTeam = TSCTeams[1];
                LoserTeam = TSCTeams[0];
                EngGameSong = SongBlueWin;
            }
            ScrnBalanceMut.BroadcastMessage(LoserTeam.GetHumanReadableName() $ " team did NOT killed enough zeds ("
                    $ LoserTeam.GetCurWaveKills() $ " / " $ TSCGRI.WaveKillReq $ ")", true);
        }
        else {
            return false;
        }
        TSCGRI.EndGameType = 2;
        TSCGRI.Winner = WinnerTeam;
        ScrnBalanceMut.BroadcastMessage(WinnerTeam.GetHumanReadableName() $ " team won the game on wave "
                $ string(WaveNum+1), true);
    }
    else if ( AlivePlayerCount <= 0 ) {
        TSCGRI.EndGameType = 1;
        TSCGRI.Winner = none;
        EngGameSong = SongBothWiped;
    }
    else if ( WaveNum >= EndWaveNum() ) {
        TSCGRI.Winner = none;
        TSCGRI.EndGameType = 2;
        EngGameSong = SongBothWin;
    }
    else {
        return false;
    }
    return true;
}

function TSCBaseGuardian SpawnBaseGuardian(byte TeamIndex)
{
    local NavigationPoint N;
    local TSCBaseGuardian gnome;
    local byte CustomHue;

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
        log("Unable to spawn Base Guardian for team " $ TeamIndex, class.name);
        return none;
    }

    gnome.Team = Teams[TeamIndex];
    gnome.TSCGRI = TSCGRI;
    TeamBases[TeamIndex] = gnome;

    if ( ScrnBalanceMut.MapInfo.GuardianLight > 0 ) {
        gnome.GuardianBrightness = ScrnBalanceMut.MapInfo.GuardianLight;
        gnome.LightBrightness = gnome.GuardianBrightness;
    }

    switch (TeamIndex) {
        case 0:
            CustomHue = ScrnBalanceMut.MapInfo.GuardianHueRed;
            break;
        case 1:
            CustomHue = ScrnBalanceMut.MapInfo.GuardianHueBlue;
            break;
    }
    if (CustomHue != 0) {
        gnome.GuardianHue = CustomHue;
        gnome.LightHue = CustomHue;
    }

    return gnome;
}

// balances the team referenced by SmallTeamIndex
// BalanceMult shows the relatice amount of bonus that must be given to small team
// Usually BalanceMult=BigTeam.Size / SmallTeam.Size
// calling BalanceTeams(2, 1.0) removes any previously given bonuses
function BalanceTeams(byte SmallTeamIndex, float BalanceMult)
{
    local Controller C;
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
        if ( bInSmallTeam ) {
            // increases max health
            ScrnPawn.SetHealthBonus(ScrnPawn.default.HealthMax * (BalanceMult - 1.0));
        }
        else {
            ScrnPawn.SetHealthBonus(0);
        }

        S = Syringe(ScrnPawn.FindInventoryType(class'Syringe'));
        if ( S != none ) {
            S.HealBoostAmount = S.default.HealBoostAmount;
            if ( bInSmallTeam ) {
                // syringe healths faster the smaller team
                S.HealBoostAmount *= (BalanceMult - 1.0);
            }
        }
    }
}

// returns wave number relative to the current game length
function byte RelativeWaveNum(float LongGameWaveNum)
{
    local int w;

    if ( OriginalFinalWave == 0 )
        w = OvertimeWaves;
    if ( OriginalFinalWave == 0 )
        w = SudDeathWaves;

    if ( w == 10 )
        return ceil(LongGameWaveNum);
    return min(10, ceil(LongGameWaveNum * w / 10.0));
}

function int EndWaveNum()
{
    return OriginalFinalWave + OvertimeWaves + SudDeathWaves + int(bUseEndGameBoss);
}

function SetupWave()
{
    local int i;

    UpdateMonsterCount();

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
    NextSquadTarget[0] = rand(AliveTeamPlayerCount[0]);
    NextSquadTarget[1] = rand(AliveTeamPlayerCount[1]);
    // reset spawn volumes
    LastZVol = none;
    LastSpawningVolume = none;

    SetupPickups();

    i = rand(2);
    TeamBases[i].ScoreOrHome();
    TeamBases[1-i].ScoreOrHome();
    if (TeamBases[0].StunThreshold > 0) {
        BaseInvulTime = Level.TimeSeconds + default.BaseInvulTime;
        TeamBases[0].bInvul = true;
        TeamBases[1].bInvul = true;
    }
    else {
        BaseInvulTime = Level.TimeSeconds + 100000; // never trigger
    }


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

    if ( WaveNum >= OriginalFinalWave ) {
        TSCGRI.bOverTime = true;
        if ( bLockTeamsOnSuddenDeath )
            LockTeams();

        if ( WaveNum >= OriginalFinalWave + OvertimeWaves ) {
            TSCGRI.bSuddenDeath = true;
            BroadcastLocalizedMessage(class'TSCMessages', 302); // sudden death
        }
        else {
            BroadcastLocalizedMessage(class'TSCMessages', 201); // overtime
        }
    }
    else if ( WaveNum == 0 ) {
        BroadcastLocalizedMessage(class'TSCMessages', 230); // human damage disabled
    }
    else if ( HumanDamageMode > HDMG_None ) {
        if ( HumanDamageMode >= HDMG_Normal )
            BroadcastLocalizedMessage(class'TSCMessages', 231); // human damage enabled
        else
            BroadcastLocalizedMessage(class'TSCMessages', 232); // enemy fire enabled
    }

    TotalMaxMonsters = ScrnGameLength.GetWaveZedCount() + NumMonsters;
    WaveEndTime = ScrnGameLength.GetWaveEndTime();
    AdjustedDifficulty = GameDifficulty + 0.3 * RelativeWaveNum(WaveNum);

    MaxMonsters = min(TotalMaxMonsters, MaxZombiesOnce); // max monsters that can be spawned
    TSCGRI.MaxMonsters = TotalMaxMonsters; // num monsters in wave replicated to clients
    TSCGRI.MaxMonstersOn = true; // I've no idea what is this for
    if (bSingleTeam) {
        TSCGRI.WaveKillReq = 0;
    }
    else {
        TSCGRI.WaveKillReq = TSCGRI.MaxMonsters * WaveKillReqPct;
    }

    NextSquadTeam = rand(2); // pickup random team for the next special squad

    //Now build the first squad to use
    SquadsToUse.Length = 0; // force BuildNextSquad() to rebuild squad list
    SpecialListCounter = 0;
    BuildNextSquad();

    WaveMinuteTimer = 0;
    TSCTeams[0].WaveKills = TSCTeams[0].ZedKills;
    TSCTeams[1].WaveKills = TSCTeams[1].ZedKills;
    TSCTeams[0].PrevMinKills = TSCTeams[0].ZedKills;
    TSCTeams[1].PrevMinKills = TSCTeams[1].ZedKills;
    TSCTeams[0].LastMinKills = TSCTeams[0].ZedKills;
    TSCTeams[1].LastMinKills = TSCTeams[1].ZedKills;
}

function bool AddSquad()
{
    if ( !bSingleTeamGame && NextSpawnSquad.length == 0 ) {
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

// returns every alive player in a row
function Controller FindSquadTarget()
{
    local Controller C, FirstC;
    local int i;

    if ( bTeamWiped || !bCheckSquadTeam || NextSquadTeam > 1 ) {
        return super.FindSquadTarget();
    }

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        if ( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health>0  && C.GetTeamNum() == NextSquadTeam ) {
            if (i == NextSquadTarget[NextSquadTeam]) {
                ++NextSquadTarget[NextSquadTeam];
                return C;
            }
            ++i;
            if ( FirstC == none ) {
                FirstC = C;
            }
        }
    }

    NextSquadTarget[NextSquadTeam] = 1;  // cuz we return zeroth
    return FirstC;
}

protected function StartTourney()
{
    super.StartTourney();

    bAntiBlocker = true;
    bVoteHDmg = false;
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

function InventoryUpdate(Pawn P)
{
    // we cannot recalc sell values now because those may not be set by the pickups yet
    bRecalcInventory = true;
}

auto State PendingMatch
{
    function bool StartClanGame(TSCClanInfo RedClan, TSCClanInfo BlueClan)
    {
        local TSCClanReplicationInfo RedRep, BlueRep;

        if (bSingleTeamGame) {
            return false;
        }

        RedRep = class'TSCClanReplicationInfo'.static.Create(TSCTeams[0], RedClan);
        if (RedRep == none) {
            return false;
        }

        BlueRep = class'TSCClanReplicationInfo'.static.Create(TSCTeams[1], BlueClan);
        if (BlueRep == none) {
            return false;
        }
        TSCTeams[0].ClanRep = RedRep;
        TSCTeams[1].ClanRep = BlueRep;
        bClanGame = true;
        ForceClanTeams();
        return true;
    }
}

State MatchInProgress
{
    function Timer()
    {
        super.Timer();

        if (bRecalcInventory) {
            bRecalcInventory = false;
            TSCTeams[0].CalcInventorySellValue();
            TSCTeams[1].CalcInventorySellValue();
        }
    }

    function BattleTimer()
    {
        super.BattleTimer();

        if ( TSCGRI.bOverTime && bTeamWiped && !bSingleTeam ) {
            KillZeds();
            EndGame(none, "TeamScoreLimit");
        }
    }

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

        if ( ++WaveMinuteTimer >= 60 ) {
            WaveMinuteTimer = 0;
            TSCTeams[0].PrevMinKills = TSCTeams[0].LastMinKills;
            TSCTeams[0].LastMinKills = TSCTeams[0].ZedKills;
            TSCTeams[1].PrevMinKills = TSCTeams[1].LastMinKills;
            TSCTeams[1].LastMinKills = TSCTeams[1].ZedKills;
            InventoryUpdate(none);
        }

        if (Level.TimeSeconds > BaseInvulTime) {
            // BaseInvulTime will be reset at the start of the next wave.
            // For now, simply increase it by big-anough number
            BaseInvulTime += 3600;
            if ((TeamBases[0].bInvul || TeamBases[1].bInvul) && (TeamBases[0].bActive || TeamBases[1].bActive)) {
                BroadcastLocalizedMessage(class'TSCMessages', 233); // tell about auto-end
            }
            TeamBases[0].bInvul = false;
            TeamBases[1].bInvul = false;
        }

    }

    function DoWaveEnd()
    {
        local int NextWave;

        // WaveNum will be increased in ScrnGameType. Use NextWave here instead.
        NextWave = WaveNum + 1;

        if ( NextWave >= EndWaveNum() ) {
            WaveNum++;
            EndGame(None, "TimeLimit");
            if ( bGameEnded )
                return;
            // something has prevented end game. Restore the previous WaveNum value.
            WaveNum--;
        }

        if ( !bSingleTeam ) {
            if ( AliveTeamPlayerCount[0] == 0 ^^ AliveTeamPlayerCount[1] == 0 ) {
                EndGame(none, "TeamScoreLimit");
            }
            else if ( TSCTeams[0].GetCurWaveKills() < TSCGRI.WaveKillReq
                    ^^  TSCTeams[1].GetCurWaveKills() < TSCGRI.WaveKillReq ) {
                EndGame(none, "TeamScoreLimit");
            }
        }
        if ( bGameEnded )
            return;

        if ( AlivePlayerCount > 0 && NextWave >= OriginalFinalWave && NextWave < EndWaveNum() ) {
            if ( OvertimeWaves > 0 && NextWave == OriginalFinalWave ) {
                TSCGRI.bOverTime = true;
                BroadcastLocalizedMessage(class'TSCMessages', 201);
                // legacy config name - now locking teams on overtime too
                if ( bLockTeamsOnSuddenDeath )
                    LockTeams();
            }
            else if ( NextWave >= OriginalFinalWave + OvertimeWaves ) {
                TSCGRI.bSuddenDeath = true;
                BroadcastLocalizedMessage(class'TSCMessages', 202);
            }
            if ( NextWave >= FinalWave ) {
                FinalWave = OriginalFinalWave + OvertimeWaves + SudDeathWaves;
            }
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
        if ( bGameEnded )
            return;

        WaveNum = NextWave;
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
            TeamShops[0] = TempShopList[0];
            TeamShops[1] = TempShopList[0];
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
} //MatchInProgress



defaultproperties
{
    GameName="Team Survival Competition"
    Description="Two Teams, One Floor. Killing Floor. There are two teams competing in surviving specimen invasion on the same map and at the same time. Both teams can cooperate, fight against each other, or just stay each in their own corner of the map - the choice is up to you..."

    KFHints[0]="Each team has its own Trader. A team can not get the same Trader two times in a row."
    KFHints[1]="When the Trader opens her doors, she drops the Base Guardian nearby. Take it to your Base!"
    KFHints[2]="Pick up the Base Guardian next to the Trader, bring it where you want your Base to be, and press the SETUPBASE or CROUCH button."
    KFHints[3]="The Base can be established only once per wave. Once set up, it can not be moved."
    KFHints[4]="If nobody stays at the Base, the Guardian gets frustrated and disappears. No Guardian = No Base."
    KFHints[5]="Base Guardian has two cool features: it protects you from the Friendly Fire and damages enemy squad members."
    KFHints[6]="Base Guardian hurts enemy players within the range of the Base no matter of the Friendly Fire setting."
    KFHints[7]="Base Guardian can be stunned with nades or 500+ cumulative damage."
    KFHints[8]="Base Guardian is invulnerable while waking up or for the first 10 seconds of a wave."
    KFHints[9]="The Base can be established during the Trader Time only. So hurry up!"
    KFHints[10]="The other squad cannot stay at your Base."
    KFHints[11]="You can play without the Base too, but who will protect you from the Friendly Fire then?"
    KFHints[12]="Setting up the Base in a strategic map point is the key to success."
    KFHints[13]="You cannot set up your own Base at the Enemy Base. However, the Bases may intersect."
    KFHints[14]="While carrying Base Guardian, you can pass it to another player by pressing the same key as throwing a weapon."
    KFHints[15]="Best camping spots in the standard KF game are not necessarily the best spots in TSC."
    KFHints[16]="The team gets wiped if ANY its member dies during the SUDDEN DEATH wave."
    KFHints[17]="Wiping the enemy squad doesn't grant you a win. You still have to survive till the end of the wave."
    KFHints[18]="TSC isn't Versus or Team Deathmatch game. You don't have to fight the enemy team. Leave that job to ZEDs."
    KFHints[19]="You can wait until ZEDs wipe out the enemy squad or help them. Help who? ZEDs or the other squad? The choice is up to you..."
    KFHints[20]="There are 4 Human Damage rules in TSC: OFF, No Friendly Fire, Normal, and PvP. Type MVOTE TEAM HDMG for the info."
    KFHints[21]="When Human Damage is OFF, you can not damage the other squad's members. The Base Guardian can, though."
    KFHints[22]="Human Damage is OFF during the first wave, Trader Time, and when there are less than 10 zeds left in the wave."
    KFHints[23]="Human Damage is ON during waves (except the first one). Staying at your own Base protects you from it."
    KFHints[24]="You can switch team during the Trader Time. Type SWITCHTEAM in the console or bind it to a key."
    KFHints[25]="Switching the team during the game kills you first. Then restarts you as an another squad member."
    KFHints[26]="You cannot switch a team during a wave."
    KFHints[27]="Medics, and only medics, can see the health and armor of enemy players."
    KFHints[28]="TSC, same as KF, is not about winning or losing. It is all about surviving."
    KFHints[29]="TSC doesn't force you to play against the other squad. You can cooperate and survive together. But nobody said that the other team thinks the same..."
    KFHints[30]="During the Trader Time, if the other squad has 2+ players less than yours, you can switch to it on-the-fly (without dying)."

    DefaultEnemyRosterClass="ScrnBalanceSrv.TSCTeam"
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
    DefaultGameLength=40
    WaveKillReqPct=0.20

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
    BaseWhisp=class'GreenWhisp'
    BaseRadius=1250 // 25 m
    MinBaseZ=-60
    MaxBaseZ=200
    BaseInvulTime=30
    HumanDamageMode=HDMG_Normal
    bVoteHDmg=True
    bVoteHDmgOnlyBeforeStart=False

    OvertimeWaves=1 // if both teams survived regular waves, add an OverTime wave
    SudDeathWaves=1 // if both team survived overtime waves, add a Sudden Death wave
    strBudgetCut="Team wallets were cut off by"

    SongRedWin="KF_WPrevention"
    SongBlueWin="KFh6_Launch"
    SongBothWin="KF_Containment"
    SongBothWiped="KF_Hunger"

    GameReplicationInfoClass=class'TSCGameReplicationInfo'
    HUDType="ScrnBalanceSrv.TSCHUD"
    ScoreBoardType="ScrnBalanceSrv.TSCScoreBoard"
    BaseGuardianClasses(0)=class'TSCGuardianRed'
    BaseGuardianClasses(1)=class'TSCGuardianBlue'

    ScreenShotName="TSC_T.Team.TSC"
}
