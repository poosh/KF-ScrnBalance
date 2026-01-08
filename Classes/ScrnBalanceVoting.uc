class ScrnBalanceVoting extends ScrnVotingOptions;

var ScrnBalance Mut;

const VOTE_PERKLOCK     = 0;
const VOTE_PERKUNLOCK   = 1;
const VOTE_PAUSE        = 2;
const VOTE_ENDTRADE     = 3;
const VOTE_BLAME        = 4;
const VOTE_KICK         = 5;
const VOTE_BORING       = 6;
const VOTE_SPAWN        = 7;  // deprecated
const VOTE_ENDWAVE      = 8;
const VOTE_SPEC         = 9;
const VOTE_READY        = 10;
const VOTE_UNREADY      = 11;
const VOTE_TEAMLOCK     = 12;
const VOTE_TEAMUNLOCK   = 13;
const VOTE_INVITE       = 14;
const VOTE_FF           = 15;
const VOTE_MAPRESTART   = 16;
const VOTE_FAKEDPLAYERS = 17;
const VOTE_FAKEDCOUNT   = 18;
const VOTE_FAKEDHEALTH  = 19;
const VOTE_DIFF         = 20;
const VOTE_MAP          = 22;
const VOTE_RKILL        = 100;

var localized string strCantEndTrade;
var localized string strTooLate;
var localized string strPauseTraderOnly;
var localized string viResume, viEndTrade, viDifficulty;
var localized string strZedSpawnsDoubled;
var localized string strSquadNotFound, strCantSpawnSquadNow, strSquadList;
var localized string strNotInStoryMode, strNotInTSC, strNotDead;
var localized string strCantEndWaveNow, strEndWavePenalty;
var localized string strRCommands;
var localized string strBlamed, strBlamedBaron;
var localized string strWrongPerk;
var localized string strMapNameTooShort, strMapNotFound, strWrongGameConfig;

var transient array< class<ScrnVeterancyTypes> > VotedPerks;
var transient byte VotedDiff;
var transient int VotedGameConfig;
var transient bool bRandomMap;

var string Reason; // reason why voting was started (e.g. kick player for being noob)

var transient float LastBlameVoteTime;


function string GetPlayerName(PlayerReplicationInfo PRI)
{
    return Mut.PlainPlayerName(PRI);
}

    static function ClientPerkRepLink GetPlayerLink(PlayerController Sender)
{
    if ( Sender == none || SRStatsBase(Sender.SteamStatsAndAchievements) == none )
        return none;
    return SRStatsBase(Sender.SteamStatsAndAchievements).Rep;
}

function class<ScrnVeterancyTypes> FindPerkByName(PlayerController Sender, string VeterancyNameOrIndex)
{
    if ( VeterancyNameOrIndex == "" )
        return none;
    return class'ScrnFunctions'.static.FindPerkByName(GetPlayerLink(Sender), VeterancyNameOrIndex);
}

function bool StrToPerks(PlayerController Sender, string str, out array< class<ScrnVeterancyTypes> > Perks,
        out String ErrorStr)
{
    local int i, j, c;
    local ClientPerkRepLink L;
    local class<ScrnVeterancyTypes> Perk;
    local array<string> args;
    local bool bInvert, bFound;

    Perks.Length = 0;
    ErrorStr = "";
    if ( str == "" )
        return false;
    L = GetPlayerLink(Sender);
    if ( L == none )
        return false;

    Split(str, " ", args);
    if ( args.length == 0 )
        return false;

    i = 0;
    if ( args[0] == "!" ) {
        bInvert = true;
        ++i;
    }
    while ( i < args.length ) {
        Perk = class'ScrnFunctions'.static.FindPerkByName(L, args[i]);
        if ( Perk == none ) {
            ErrorStr = args[i];
            return false;
        }
        Perks[Perks.length] = Perk;
        ++i;
    }
    // check for duplicates
    for ( i = 0; i < Perks.length; ++i ) {
        for ( j = i + 1; j < Perks.length; ++j ) {
            if (Perks[j] == Perks[i]) {
                Perks.remove(j--, 1);
            }
        }
    }
    if ( bInvert ) {
        c = Perks.length;
        for ( j = 0; j < L.CachePerks.Length; ++j ) {
            Perk = class<ScrnVeterancyTypes>(L.CachePerks[j].PerkClass);
            if ( Perk == none )
                continue;
            bFound = false;
            for ( i = 0; i < c; ++ i ) {
                if ( Perks[i] == Perk ) {
                    bFound = true;
                    break;
                }
            }
            if ( !bFound ) {
                Perks[Perks.length] = Perk;
            }
        }
        Perks.remove(0, c);
    }
    return true;
}

function String PerksStr(out array<class< ScrnVeterancyTypes> > Perks)
{
    local string s;
    local int i;
    local class<ScrnVeterancyTypes> Perk;

    if ( Perks.length == 1 )
        return Perks[0].default.VeterancyName;

    for ( i = 0; i < Perks.length; ++i ) {
        Perk = Perks[i];
        if ( i > 0 ) {
            s $= " ";
        }
        if ( Perk.default.ShortName != "") {
            s $= Perk.default.ShortName;
        }
        else {
            s $= Perk.default.VeterancyName;
        }
    }
    return s;
}

static function bool TryStrToInt(string str, out int val)
{
    val = int(str);
    return val != 0 || str == "0";
}

function SendGameConfigs(PlayerController Sender, xVotingHandler vh)
{
    local int i;
    local string s;

    for ( i = 0; i < vh.GameConfig.length; ++i ) {
        s = "";
        if ( i == vh.CurrentGameConfig ) {
            s = "^2";
        }
        s $= vh.GameConfig[i].Acronym $ " - " $ vh.GameConfig[i].GameName;
        Sender.ClientMessage(s);
    }
}

function SendMapList(PlayerController Sender, xVotingHandler vh, String Prefix, optional String Keyword)
{
    local int i;
    local string s, KeywordHighlight;
    local int prefixLen;
    local bool bFilter;

    prefixLen = len(Prefix);
    Prefix = caps(Prefix);
    bFilter = Keyword != "";
    if (bFilter) {
        KeywordHighlight = "^2" $ Keyword $ "^1";
    }

    for ( i = 0; i < vh.MapList.length; ++i ) {
        if ( !vh.MapList[i].bEnabled )
            continue;
        s = caps(vh.MapList[i].MapName);
        if ( Left(s, prefixLen) != prefix )
            continue;
        if ( bFilter ) {
            if ( InStr(s, Keyword) == -1 )
                continue;
            s = Repl(s, Keyword, KeywordHighlight, true);
            s = "^1" $ s;
        }
        Sender.ClientMessage(s);
    }
}

function int MapVote(PlayerController Sender, out string VoteValue, out string VoteInfo)
{
    local xVotingHandler vh;
    local array<string> args;
    local int i, GameIndex, MapIndex;
    local byte diff;
    local string s, prefix, MapKeyword, DiffStr;
    local int prefixLen;
    local VotingHandler.MapHistoryInfo MapInfo;
    local bool bFirstMatch;

    vh = xVotingHandler(Level.Game.VotingHandler);
    if ( vh == none || !vh.bMapVote || vh.MapList.length == 0) {
        Sender.ClientMessage(strOptionDisabled);
        return VOTE_LOCAL;
    }

    VotedDiff = 0;
    VotedGameConfig = -1;
    bRandomMap = false;

    Split(VoteValue, " ", args);
    MapKeyword = args[0];
    if ( MapKeyword != "*" && len(MapKeyword) < 3 ) {
        Sender.ClientMessage(strMapNameTooShort);
        return VOTE_ILLEGAL;
    }

    GameIndex = vh.CurrentGameConfig;
    if ( args.length > 1 && args[1] != "LIST" ) {
        for ( i = 0; i < vh.GameConfig.length; ++i ) {
            if ( vh.GameConfig[i].Acronym ~= args[1] ) {
                GameIndex = i;
                break;
            }
        }
        if (i == vh.GameConfig.length) {
            s = strWrongGameConfig;
            s = Repl(s, "%s", args[1]);
            Sender.ClientMessage(s);
            SendGameConfigs(Sender, vh);
            return VOTE_ILLEGAL;
        }
    }

    if ( MapKeyword == "HELP" || MapKeyword == "LIST" ) {
        SendMapList(Sender, vh, vh.GameConfig[GameIndex].Prefix);
        if ( MapKeyword == "HELP" || (args.length > 1 && args[1] == "LIST" ) ) {
            Sender.ClientMessage("--------------------------------------------------");
            SendGameConfigs(Sender, vh);
        }
        return VOTE_LOCAL;
    }

    if ( args.length > 2 ) {
        DiffStr = args[2];
        diff = GetDifficulty(DiffStr);
        if ( diff < Mut.MinVoteDifficulty || diff > Mut.MaxDifficulty ) {
            return VOTE_ILLEGAL;
        }
    }

    if ( MapKeyword == "RANDOM" || MapKeyword == "*" ) {
        bRandomMap = true;
        i = vh.CurrentGameConfig;
        vh.CurrentGameConfig = GameIndex;
        vh.bDefaultToCurrentGameType = true;
        vh.GetDefaultMap(MapIndex, GameIndex);
        vh.CurrentGameConfig = i;
    }
    else {
        prefix = caps(vh.GameConfig[GameIndex].Prefix);
        prefixLen = len(prefix);
        if ( Right(MapKeyword, 1) == "^" ) {
            bFirstMatch = true;
            MapKeyword = Left(MapKeyword, Len(MapKeyword) - 1);
        }
        MapIndex = -1;
        for ( i = 0; i < vh.MapList.length; ++i ) {
            if ( !vh.MapList[i].bEnabled )
                continue;
            s = caps(vh.MapList[i].MapName);
            if ( Left(s, prefixLen) != prefix )
                continue;

            if ( s == MapKeyword ) {
                // full match
                MapIndex = i;
                break;
            }

            if ( InStr(s, MapKeyword) != -1) {
                if ( MapIndex == -1 ) {
                    MapIndex = i;
                    if ( bFirstMatch )
                        break;
                }
                else {
                    SendMapList(Sender, vh, prefix, MapKeyword);
                    return VOTE_LOCAL;
                }
            }
        }
    }

    if ( MapIndex == -1 ) {
        Sender.ClientMessage(strMapNotFound);
        return VOTE_LOCAL;
    }

    VotedDiff = diff;
    MapInfo = vh.History.PlayMap(vh.MapList[MapIndex].MapName);
    VoteValue = vh.SetupGameMap(vh.MapList[MapIndex], GameIndex, MapInfo);
    if ( GameIndex == vh.CurrentGameConfig && diff == 0 ) {
        VoteInfo = "MAP ";
    }
    else {
        VotedGameConfig = GameIndex;
        VoteInfo = vh.GameConfig[GameIndex].Acronym;
        if ( diff > 0 ) {
            VoteInfo @= DiffStr;
        }
        VoteInfo $= " @ ";
    }
    VoteInfo $= eval(bRandomMap, "RANDOM", vh.MapList[MapIndex].MapName);
    return VOTE_MAP;
}

function ApplyMapVote(string ServerTravelString)
{
    local xVotingHandler vh;

    vh = xVotingHandler(Level.Game.VotingHandler);
    vh.CloseAllVoteWindows();
    vh.History.Save();
    if ( VotedGameConfig >= 0 ) {
        vh.CurrentGameConfig = VotedGameConfig;
    }
    vh.SaveConfig();

    if ( VotedDiff > 0 ) {
        Mut.ChangeGameDifficulty(VotedDiff);
    }

    Mut.Persistence.bRandomMap = bRandomMap;
    Level.ServerTravel(ServerTravelString, false);
}

function bool IsReferee(PlayerController Sender)
{
    return Sender.PlayerReplicationInfo.bAdmin && Sender.PlayerReplicationInfo.bOnlySpectator
            && Mut.SrvTourneyMode != 0;
}

function bool CheckReferee(PlayerController Sender)
{
    if ( IsReferee(Sender) )
        return true;

    Sender.ClientMessage(strRCommands);
    return false;
}

function bool CanLockTeam()
{
    local int CurWave, MinLockWave;

    if ( Level.GRI.bMatchHasBegun ) {
        CurWave = Mut.ScrnGT.WaveNum + 1;
    }

    if ( Mut.ScrnGT.IsTourney() ) {
        MinLockWave = Mut.LockTeamMinWaveTourney;
    }
    else {
        MinLockWave = Mut.LockTeamMinWave;
    }
    MinLockWave = Mut.ScrnGT.RelativeWaveNum(MinLockWave);
    return CurWave >= MinLockWave;
}

function bool ShouldAutoBlame(ScrnPlayerController BlamedPlayer) {
    return BlamedPlayer != none && BlamedPlayer.BeggingForMoney >= 3;
}

function int GetVoteIndex(PlayerController Sender, string Key, out string Value, out string VoteInfo)
{
    local int result, v, i;
    local string str, errstr;
    local bool b;

    if ( Key == "LOCKPERK" || Key == "UNLOCKPERK") {
        b = (Key == "LOCKPERK");
        if ( !Mut.bAllowLockPerkVote ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_NOEFECT;
        }
        if (!StrToPerks(Sender, Value, VotedPerks, errstr) || VotedPerks.Length == 0) {
            if (errstr != "") {
                str = strWrongPerk;
                str = Repl(str, "%s", errstr);
                Sender.ClientMessage(str);
            }
            class'ScrnFunctions'.static.SendPerkList(Sender);
            return VOTE_LOCAL;
        }
        for ( i = 0; i < VotedPerks.length; ++i ) {
            if ( VotedPerks[i].default.bLocked != b )
                break;
        }
        if ( i == VotedPerks.length )
            return VOTE_NOEFECT;
        VoteInfo = Key @ PerksStr(VotedPerks);
        if (b) {
            result = VOTE_PERKLOCK;
        }
        else {
            result = VOTE_PERKUNLOCK;

        }
    }
    else if ( Key == "PAUSE" || (Level.Pauser != none && Key == "RESUME") ) {
        if ( !Mut.bAllowPauseVote && !Mut.CheckAdmin(Sender) ) {
            return VOTE_NOEFECT;
        }
        if ( Mut.bPauseTraderOnly && !Mut.KF.bTradingDoorsOpen && Mut.KF.IsInState('MatchInProgress')
                && !Mut.IsAdmin(Sender) )
        {
            Sender.ClientMessage(strPauseTraderOnly);
            return VOTE_NOEFECT;
        }
        if (Level.Pauser != none ) {
            VoteInfo = viResume;
        }
        else {
            v = int(Value);
            if ( v <= 0 )
                v = 120;
            if ( !Mut.IsAdmin(Sender) ) {
                v = min(min(v, Mut.MaxPauseTime), Mut.PauseTimeRemaining);
            }
            if ( v <= 0 ) {
                Sender.ClientMessage(strNotAvaliableATM);
                return VOTE_LOCAL;
            }
            Value = string(v);
        }
        result = VOTE_PAUSE;
    }
    else if ( Key == "ENDTRADE" || (Key == "END" && Value == "TRADE") ) {
        if ( Mut.bStoryMode ) {
            Sender.ClientMessage(strNotInStoryMode);
            return VOTE_NOEFECT;
        }
        if ( Mut.KF.bWaveInProgress|| Mut.KF.WaveCountDown < 10 || Mut.SkippedTradeTimeMult < 0 ) {
            Sender.ClientMessage(strCantEndTrade);
            return VOTE_NOEFECT;
        }
        result = VOTE_ENDTRADE;
        Value = "";
        VoteInfo = viEndTrade;
    }
    else if ( Key == "BLAME" ) {
        if ( !Mut.bAllowBlameVote ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_NOEFECT;
        }
        if ( LastBlameVoteTime > 0 && Level.TimeSeconds - LastBlameVoteTime < Mut.BlameVoteCoolDown ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }

        if ( Value == "" ) {
            SendPlayerList(Sender);
            return VOTE_LOCAL;
        }

        Reason = "";
        if ( Left(Value, 1) == "\"" ) {
            // don't look for player in quoted string - just blame it :)
            VotingHandler.VotedPlayer = none;
            Value = Mid(Value, 1);
            Divide(Value, "\"", Value, Reason);
            VotingHandler.VotedPlayer = none;
        }
        else {
            Divide(Value, " ", Value, Reason);
            if ( Value ~= "ALL" || Value ~= "TEAM" ) {
                Value = "TEAM";
                VoteInfo = "Blame Team";
                VotingHandler.VotedPlayer = none;
            }
            else {
                if ( Value ~= "ME" )
                    VotingHandler.VotedPlayer = Sender;
                else
                    VotingHandler.VotedPlayer = FindPlayer(Value, Sender);
                if ( VotingHandler.VotedPlayer == none ) {
                    Sender.ClientMessage(strPlayerNotFound);
                    SendPlayerList(Sender);
                    return VOTE_ILLEGAL;
                }
                Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
                VoteInfo = "Blame " $ Value;
            }
        }
        VotingHandler.bVotedPlayerAutoVote = ShouldAutoBlame(ScrnPlayerController(VotingHandler.VotedPlayer));
        LastBlameVoteTime = Level.TimeSeconds;
        result = VOTE_BLAME;
    }
    else if ( Key == "SPEC" ) {
        if ( Level.Game.AccessControl == none
                || Level.Game.NumSpectators > Level.Game.MaxSpectators
                || (!Mut.bAllowKickVote && !Mut.IsAdmin(Sender)) )
        {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_NOEFECT;
        }

        if ( Value == "" ) {
            SendPlayerList(Sender);
            return VOTE_LOCAL;
        }

        Reason = "";
        Divide(Value, " ", Value, Reason);
        VotingHandler.VotedPlayer = FindPlayer(Value, Sender);
        if ( VotingHandler.VotedPlayer == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendPlayerList(Sender);
            return VOTE_ILLEGAL;
        }
        Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = "Spectate " $ Value;
        result = VOTE_SPEC;
    }
    else if ( Key == "KICK" ) {
        if ( Level.Game.AccessControl == none || (!Mut.bAllowKickVote && !Mut.IsAdmin(Sender)) ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_NOEFECT;
        }

        if ( Value == "" ) {
            SendPlayerList(Sender);
            return VOTE_LOCAL;
        }

        Reason = "";
        Divide(Value, " ", Value, Reason);
        VotingHandler.VotedPlayer = FindPlayer(Value, Sender);
        if ( VotingHandler.VotedPlayer == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendPlayerList(Sender);
            return VOTE_ILLEGAL;
        }
        Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = "Kick " $ Value;
        result = VOTE_KICK;
    }
    else if ( Key == "INVITE" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;

        if ( Value == "" ) {
            SendPlayerList(Sender);
            return VOTE_LOCAL;
        }

        Reason = "";
        Divide(Value, " ", Value, Reason);
        VotingHandler.VotedPlayer = FindPlayer(Value, Sender);
        if ( VotingHandler.VotedPlayer == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendPlayerList(Sender);
            return VOTE_ILLEGAL;
        }
        else if ( Mut.ScrnGT.IsInvited(VotingHandler.VotedPlayer) ) {
            VotingHandler.VotedPlayer = none;
            return VOTE_NOEFECT;
        }
        Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = "Invite " $ Value;
        result = VOTE_INVITE;
    }
    else if ( Key == "BORING" ) {
        if ( Mut.bStoryMode ) {
            Sender.ClientMessage(strNotInStoryMode);
            return VOTE_LOCAL;
        }

        if (!Mut.IsAdmin(Sender)) {
            if (!Mut.bAllowBoringVote) {
                Sender.ClientMessage(strOptionDisabled);
                return VOTE_LOCAL;
            }
            if (Sender.Pawn == none || Sender.Pawn.Health <= 0) {
                Sender.ClientMessage(strNotDead);
                return VOTE_LOCAL;
            }
        }

        if ( Mut.KF.bTradingDoorsOpen || (Mut.ScrnGT != none && Mut.ScrnGT.BoringStageMaxed())
                    || (Mut.ScrnGT == none && Mut.KF.KFLRules.WaveSpawnPeriod < 0.5) )
        {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }

        Value = "";
        VoteInfo = "BORING / BOOST ZEDS";
        result = VOTE_BORING;
    }
    else if ( Key == "ENDWAVE" || (Key == "END" && Value == "WAVE") ) {
        VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team;
        if ( VotingHandler.VotedTeam == none )
            return VOTE_ILLEGAL;

        if (Mut.ScrnGT != none && Mut.ScrnGT.ScrnGRI.WaveEndRule == 10) {
            // RULE_Dialogue
            return VOTE_ENDWAVE;
        }

        if ( Mut.KF.NumMonsters == 0 )
            return VOTE_NOEFECT;

        if ( Mut.MaxVoteKillMonsters == 0 ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_NOEFECT;
        }
        if ( Mut.KF.TotalMaxMonsters > 0 || Mut.KF.NumMonsters > Mut.MaxVoteKillMonsters
                || Mut.GameRules.bFinalWave || !CanEndWave() )
        {
            Sender.ClientMessage(strCantEndWaveNow);
            return VOTE_NOEFECT;
        }
        Value = "";
        VoteInfo = "END WAVE";
        return VOTE_ENDWAVE;
    }
    else if (Key == "SKIP") {
        if (Mut.KF.bTradingDoorsOpen) {
            return GetVoteIndex(Sender, "ENDTRADE", Value, VoteInfo);
        }
        else if (Mut.ScrnGT != none && Mut.ScrnGT.ScrnGRI.WaveEndRule == 10) {
            // skip dialogue
            return GetVoteIndex(Sender, "ENDWAVE", Value, VoteInfo);
        }
        else if (Mut.KF.TotalMaxMonsters > 0) {
            return GetVoteIndex(Sender, "BORING", Value, VoteInfo);
        }
        return GetVoteIndex(Sender, "ENDWAVE", Value, VoteInfo);
    }
    else if ( Key == "READY" ) {
        if ( !Level.Game.bWaitingToStartMatch )
            return VOTE_NOEFECT;

        return VOTE_READY;
    }
    else if ( Key == "UNREADY" ) {
        if ( !Level.Game.bWaitingToStartMatch )
            return VOTE_NOEFECT;

        return VOTE_UNREADY;
    }
    else if ( Key == "LOCKTEAM" || Key == "LOCKTEAMS" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;
        else if ( Mut.bTeamsLocked )
            return VOTE_NOEFECT;
        else if ( !Mut.IsAdmin(Sender) && !CanLockTeam() ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }
        return VOTE_TEAMLOCK;
    }
    else if ( Key == "UNLOCKTEAM" || Key == "UNLOCKTEAMS" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;
        else if ( !Mut.bTeamsLocked )
            return VOTE_NOEFECT;
        return VOTE_TEAMUNLOCK;
    }
    else if ( Key == "FF" ) {
        if ( Mut.bTSCGame ) {
            Sender.ClientMessage(strNotInTSC);
            return VOTE_NOEFECT;
        }
        if ( Level.GRI.bMatchHasBegun && !Mut.bTestMap ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }
        if ( right(Value, 1) == "%" )
            Value = left(Value, len(Value)-1);
        if (!TryStrToInt(Value, v) || v < 0 || (!Mut.bTestMap && (v < Mut.MinVoteFF || v > Mut.MaxVoteFF)))
            return VOTE_ILLEGAL;
        if ( v == int(Mut.KF.FriendlyFireScale*100) )
            return VOTE_NOEFECT;
        if ( v == 0 )
            VoteInfo = "Friendly Fire OFF";
        else
            VoteInfo = "Friendly Fire "$v$"%";
        return VOTE_FF;
    }
    else if ( Key == "MAP" ) {
        if ( Value == "RESTART" ) {
            result = VOTE_MAPRESTART;
        }
        else {
            return MapVote(Sender, Value, VoteInfo);
        }
    }
    else if ( Key == "FAKED" || Key == "FAKEDPLAYERS" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;
        if ( !TryStrToInt(Value, v) || v < 0 || v > 32 )
            return VOTE_ILLEGAL;
        if ( Mut.ScrnGT.ScrnGRI.FakedPlayers == v && Mut.ScrnGT.ScrnGRI.FakedAlivePlayers == v )
            return VOTE_NOEFECT;

        if ( v <= 1 )
            VoteInfo = "Faked Players OFF";
        else
            VoteInfo = v $ " Faked Players";

        return VOTE_FAKEDPLAYERS;
    }
    else if ( Key == "FAKEDCOUNT" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;
        if ( !TryStrToInt(Value, v) || v < 0 || v > 32 )
            return VOTE_ILLEGAL;
        if ( Mut.ScrnGT.ScrnGRI.FakedPlayers == v )
            return VOTE_NOEFECT;

        if ( v <= 1 )
            VoteInfo = "Faked Zed Count OFF";
        else
            VoteInfo = v $ "p Faked Zed Count";

        return VOTE_FAKEDCOUNT;
    }
    else if ( Key == "FAKEDHEALTH" ) {
        if ( !Mut.CheckScrnGT(Sender) )
            return VOTE_LOCAL;
        if ( !TryStrToInt(Value, v) || v < 0 || v > 32 )
            return VOTE_ILLEGAL;
        if ( Mut.ScrnGT.ScrnGRI.FakedAlivePlayers == v )
            return VOTE_NOEFECT;

        if ( v <= 1 )
            VoteInfo = "Faked Zed Health OFF";
        else
            VoteInfo = v $ "p Faked Zed Health";

        return VOTE_FAKEDHEALTH;
    }
    else if ( Key == "DIFF" || Key == "DIFFICULTY" ) {
        if ( Value == "" ) {
            Sender.ClientMessage("Usage: MVOTE DIFF DEFAULT|NORMAL|HARD|SUI|SUI+|HOE|HOE+");
            return VOTE_LOCAL;
        }
        v = GetDifficulty(Value);
        if ( v != 0 && v < Mut.MinVoteDifficulty || v > Mut.MaxDifficulty )
            return VOTE_ILLEGAL;
        if ( v == Mut.Persistence.Difficulty )
            return VOTE_NOEFECT;
        VoteInfo = Value @ viDifficulty;
        VotedDiff = v;
        Value = string(v);
        return VOTE_DIFF;
    }
    else if ( Key == "R_KILL" ) {
        if ( !CheckReferee(Sender) )
            return VOTE_LOCAL;

        if ( Value == "" ) {
            SendPlayerList(Sender);
            return VOTE_LOCAL;
        }

        Reason = "";
        Divide(Value, " ", Value, Reason);
        VotingHandler.VotedPlayer = FindPlayer(Value);
        if ( VotingHandler.VotedPlayer == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendPlayerList(Sender);
            return VOTE_ILLEGAL;
        }
        Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = "Referee KILL " $ Value;
        result = VOTE_RKILL;
    }
    else
        return VOTE_UNKNOWN;

    return result;
}

function ApplyVoteValue(int VoteIndex, string VoteValue)
{
    local int i;

    switch ( VoteIndex ) {
        case VOTE_PERKLOCK: case VOTE_PERKUNLOCK:
            for ( i = 0; i < VotedPerks.length; ++i ) {
                Mut.LockPerk(VotedPerks[i], VoteIndex == VOTE_PERKLOCK);
            }
            break;
        case VOTE_PAUSE:
            if (Level.Pauser != none ) {
                Mut.ResumeGame();
            }
            else if ( Mut.bPauseTraderOnly && !Mut.KF.bTradingDoorsOpen && Mut.KF.IsInState('MatchInProgress') ) {
                VotingHandler.BroadcastMessage(strPauseTraderOnly);
                return;
            }
            else {
                i = int(VoteValue);
                if (i <= 0) {
                    i = 60;
                }
                Mut.PauseGame(VotingHandler.VoteInitiator.PlayerReplicationInfo, i);
            }
            break;
        case VOTE_ENDTRADE:
            if ( Mut.KF.bWaveInProgress || Mut.KF.WaveCountDown < 6 ) {
                VotingHandler.BroadcastMessage(strTooLate);
                return;
            }
            Mut.TradeTimeAddSeconds = max(float(Mut.KF.WaveCountDown - 5) * Mut.SkippedTradeTimeMult, 0);
            Mut.KF.WaveCountDown = 6; // need to left at least 6 to execute kfgametype.timer() events
            break;
        case VOTE_BLAME:
            Blame(VoteValue);
            break;

        case VOTE_SPEC:
            if ( VotingHandler.VotedPlayer != none && !Mut.IsAdmin(VotingHandler.VotedPlayer) ) {
                if ( Mut.ScrnGT != none )
                    Mut.ScrnGT.UninvitePlayer(VotingHandler.VotedPlayer);
                VotingHandler.VotedPlayer.BecomeSpectator();
            }
            break;

        case VOTE_KICK:
            KickPlayer(VotingHandler.VotedPlayer, Mut.bKickBan, Reason);
            break;

        case VOTE_BORING:
            if ( Mut.ScrnGT != none ) {
                if ( Mut.ScrnGT.IncBoringStage() ) {
                    VotingHandler.BroadcastMessage(Mut.ScrnGT.GetBoringString(Mut.ScrnGT.GetBoringStage()));
                }
            }
            else {
                Mut.KF.KFLRules.WaveSpawnPeriod *= 0.5;
                VotingHandler.BroadcastMessage(strZedSpawnsDoubled $ " ("$Mut.KF.KFLRules.WaveSpawnPeriod$")");
            }
            break;

        case VOTE_SPAWN:
            // deprecated
            break;

        case VOTE_ENDWAVE:
            if (Mut.ScrnGT != none && Mut.ScrnGT.ScrnGRI.WaveEndRule == 10) {
                //RULE_Dialogue
                Mut.ScrnGT.ScrnGameLength.SkipDialogue();
                break;
            }
            if ( Mut.KF.TotalMaxMonsters > 0 || Mut.KF.NumMonsters > Mut.MaxVoteKillMonsters
                    || Mut.GameRules.bFinalWave )
            {
                return;
            }
            DoEndWave();
            break;

        case VOTE_READY:
            SetReady(VotingHandler.VotedTeam.TeamIndex, true);
            break;
        case VOTE_UNREADY:
            SetReady(VotingHandler.VotedTeam.TeamIndex, false);
            break;
        case VOTE_TEAMLOCK:
            Mut.ScrnGT.LockTeams();
            break;
        case VOTE_TEAMUNLOCK:
            Mut.ScrnGT.UnlockTeams();
            break;
        case VOTE_INVITE:
            Mut.ScrnGT.InvitePlayer(VotingHandler.VotedPlayer);
            if (ScrnPlayerController(VotingHandler.VotedPlayer) != none
                    && VotingHandler.VotedPlayer.PlayerReplicationInfo.bOnlySpectator) {
                ScrnPlayerController(VotingHandler.VotedPlayer).ClientInvite();
            }
            break;
        case VOTE_FF:
            Mut.KF.FriendlyFireScale = float(VoteValue)/100.0;
            if ( TSCGame(Mut.KF) != none )
                TSCGame(Mut.KF).HdmgScale = Mut.KF.FriendlyFireScale;
            break;
        case VOTE_MAPRESTART:
            Mut.Persistence.bRandomMap = Mut.bRandomMap;  // restore previous value
            Level.ServerTravel("?restart", false);
            break;
        case VOTE_MAP:
            ApplyMapVote(VoteValue);
            break;
        case VOTE_FAKEDPLAYERS:
            Mut.ScrnGT.ScrnGRI.FakedPlayers = byte(VoteValue);
            Mut.ScrnGT.ScrnGRI.FakedAlivePlayers = byte(VoteValue);
            break;
        case VOTE_FAKEDCOUNT:
            Mut.ScrnGT.ScrnGRI.FakedPlayers = byte(VoteValue);
            break;
        case VOTE_FAKEDHEALTH:
            Mut.ScrnGT.ScrnGRI.FakedAlivePlayers = byte(VoteValue);
            break;
        case VOTE_DIFF:
            // apply new difficulty on-the-fly on a test map or before the game begins
            Mut.ChangeGameDifficulty(VotedDiff, Mut.bTestMap || !Level.GRI.bMatchHasBegun);
            break;

        case VOTE_RKILL:
            if ( VotingHandler.VotedPlayer != none && VotingHandler.VotedPlayer.Pawn != none ) {
                VotingHandler.VotedPlayer.Pawn.Suicide();
                if ( Reason == "" ) {
                    VotingHandler.BroadcastMessage(VoteValue $ " killed by a referee");
                }
                else {
                    VotingHandler.BroadcastMessage(VoteValue $ " killed by a referee for " $Reason);
                }
            }
            break;
    }
}

function KickPlayer(PlayerController PC, optional bool bBan, optional string Reason)
{
    local string msg, IP, ID, PlayerName;
    local AccessControl AC;

    if (PC == none || Mut.IsAdmin(PC))
        return;

    if (Mut.ScrnGT != none) {
        Mut.ScrnGT.UninvitePlayer(PC);
    }

    IP = PC.GetPlayerNetworkAddress();
    ID = PC.GetPlayerIDHash();
    PlayerName = GetPlayerName(PC.PlayerReplicationInfo);
    AC = Mut.KF.AccessControl;

    if (bBan) {
        if(AC == none || AC.CheckIPPolicy(IP) != 0) {
            bBan = false;
        }
        else {
            IP = Left(IP, InStr(IP, ":"));
            Log("Adding Session Ban for: " $ IP @ ID @ PlayerName);

            if (AC.bBanByID) {
                AC.SessionBannedIDs[AC.SessionBannedIDs.Length] = ID @ PlayerName;
            }
            else {
                AC.SessionIPPolicies[AC.SessionIPPolicies.Length] = "DENY;" $ IP;
            }
            AC.SaveConfig();
        }
    }

    msg = PlayerName @ eval(bBan, "banned", "kicked");
    if (Reason == "") {
        Reason = "Team Vote";
    }
    else {
        msg $= ": " $ Reason;
    }
    VotingHandler.BroadcastMessage(msg);
    PC.ClientNetworkMessage("AC_Kicked", Reason);

    if (PC.Pawn != none && Vehicle(PC.Pawn) == none) {
        PC.Pawn.Destroy();
    }
    if (PC != None) {
        PC.Destroy();
    }
}

function SetReady(byte TeamIndex, bool bReady)
{
    local Controller C;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( C.PlayerReplicationInfo != none && C.bIsPlayer && PlayerController(C) != none
                && C.PlayerReplicationInfo.Team != none
                && C.PlayerReplicationInfo.bWaitingPlayer && !C.PlayerReplicationInfo.bOnlySpectator )
        {
            C.PlayerReplicationInfo.bReadyToPlay = bReady;
        }
    }
}

function class<KFMonster> Str2Monster(string MonsterName)
{
    local class<KFMonster> M;

    if ( Mut.ScrnGT != none && Mut.ScrnGT.ScrnGameLength != none ) {
        M = Mut.ScrnGT.ScrnGameLength.FindActiveZedByAlias(MonsterName);
        if ( M != none )
            return M;
    }

    MonsterName = caps(MonsterName);
    if ( MonsterName == "CLOT" )
        return class'ZombieClot';
    if ( MonsterName == "CRAWLER" )
        return class'ZombieCrawler';
    if ( MonsterName == "STALKER" )
        return class'ZombieStalker';
    if ( MonsterName == "BLOAT" )
        return class'ZombieBloat';
    if ( MonsterName == "GOREFAST" )
        return class'ZombieGorefast';
    if ( MonsterName == "SIREN" )
        return class'ZombieSiren';
    if ( MonsterName == "HUSK" )
        return class'ZombieHusk';
    if ( MonsterName == "SCRAKE" || MonsterName == "SC" )
        return class'ZombieScrake';
    if ( MonsterName == "FLESHPOUND" || MonsterName == "FP" )
        return class'ZombieFleshpound';
    if ( MonsterName == "PAT" || MonsterName == "PATRIARCH" || MonsterName == "BOSS" )
        return class'ZombieBoss';

    return none;
}

function Blame(string VoteValue)
{
    local Controller C;
    local ScrnPlayerController Blamer, BlamedPlayer;
    local String str;

    Blamer = ScrnPlayerController(VotingHandler.VoteInitiator);
    BlamedPlayer = ScrnPlayerController(VotingHandler.VotedPlayer);

    LastBlameVoteTime = Level.TimeSeconds;

    str = strBlamed;
    str = Repl(str, "%r", Reason);
    if ( BlamedPlayer == none ) {
        str = Repl(str, "%p", VoteValue);
        VotingHandler.BroadcastMessage(str);
    }

    //achievement
    if ( IsGoodReason(Reason) && Blamer != none ) {
        class'ScrnAchCtrl'.static.Ach2Player(Blamer, 'Blame55p', 1);
        if ( Blamer == BlamedPlayer ) {
            class'ScrnAchCtrl'.static.Ach2Player(Blamer, 'BlameMe', 1);
        }
        else if ( BlamedPlayer != none && BlamedPlayer.BeggingForMoney >= 3 ) {
            class'ScrnAchCtrl'.static.Ach2Player(Blamer, 'SellCrap', 1);
            BlamedPlayer.ReceiveLocalizedMessage(class'ScrnFakedAchMsg', 1);
            BlamedPlayer.BeggingForMoney = 0;
        }
    }

    if ( BlamedPlayer != none ) {
        Mut.BlamePlayer(BlamedPlayer, str);
        if ( BlamedPlayer.GetPlayerIDHash() == "76561198006289592" ) {
            Mut.BroadcastFakedAchievement(0); // blame Baron :)
            if ( Blamer != BlamedPlayer ) {
                // blame the one who blamed baron
                Mut.BlamePlayer(Blamer, strBlamedBaron);
            }
        }
    }
    else if ( VoteValue ~= "TEAM" || VoteValue ~= "ALL" ) {
        for ( C = Level.ControllerList; C != none; C = C.nextController ) {
            BlamedPlayer = ScrnPlayerController(C);
            if ( BlamedPlayer != none ) {
                Mut.BlamePlayer(BlamedPlayer, "");
            }
        }
        //achievement
        if ( IsGoodReason(Reason) )
            class'ScrnAchCtrl'.static.Ach2Player(Blamer, 'BlameTeam', 1);
    }
    else if ( VoteValue ~= "Baron" ) {
        Mut.BroadcastFakedAchievement(0);
        if ( Blamer != none ) {
            // blame the one who blamed baron
            Mut.BlamePlayer(Blamer, strBlamedBaron);
        }
    }
    else if ( VoteValue ~= "TWI" || VoteValue ~= "Tripwire" ) {
        Mut.BroadcastFakedAchievement(3); // blame Tripwire :)
    }
    else {
        BlameMonster(VoteValue);
    }
}

// returns false if monster not found or can't be blamed
function bool BlameMonster(String MonsterName)
{
    local class<KFMonster> MC;
    local Controller P;
    local ScrnPlayerController Player;

    MC = Str2Monster(MonsterName);
    // don't blame Stalkers and Patriarch, because shit on their head could reveal
    // their positions
    if ( MC == none || MC == class'ZombieStalker' ||  MC == class'ZombieBoss' )
        return false;

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = ScrnPlayerController(P);
        if ( Player != none ) {
            Player.ClientMonsterBlamed(MC);
        }
    }
    return true;
}

static function bool IsGoodReason(string Reason)
{
    local string a, b;

    // good reason contains from at least 2 words, one of them is at least 6 character long
    // "n00b" and "screw you" aren't good reasons :)
    return Divide(Reason, " ", a, b) && ( len(a) >= 6 || len(b) >= 6);
}

function bool CanEndWave()
{
    local Controller C;
    local MonsterController MC;
    local Monster M;
    local KFHumanPawn P;

    for ( C = Level.ControllerList; C != None; C = C.NextController ) {
        MC = MonsterController(C);
        M = Monster(C.Pawn);
        if (MC==none || M == none || M.Health <= 0)
            continue;

        if (M.ScoringValue > Mut.MaxVoteKillBounty)
            return false;

        if ( Mut.bVoteKillCheckVisibility ) {
            foreach M.VisibleCollidingActors(class'KFHumanPawn', P, 1000, M.Location) {
                if (P.Health > 0 && PlayerController(P.Controller) != none && P.Controller.CanSee(M))
                    return false;
            }
        }
    }
    return true;
}

function DoEndWave()
{
    local Monster M;
    local int Penalty, TotalPenalty;

    foreach DynamicActors(class'Monster', M) {
        Penalty = max(M.ScoringValue * Mut.VoteKillPenaltyMult, 0);
        VotingHandler.VotedTeam.Score -= Penalty;
        TotalPenalty += Penalty;
        M.KilledBy(M);
    }
    if ( TotalPenalty > 0 )
        VotingHandler.BroadcastMessage(strEndWavePenalty $ TotalPenalty);
}

function byte GetDifficulty(out string DiffStr)
{
    if ( DiffStr == "0" || DiffStr == "DEFAULT" || DiffStr == "OFF" ) {
        DiffStr = "Default";
        return 0;
    }
    else if ( DiffStr == "2" || DiffStr == "NORMAL" ) {
        DiffStr = "Normal";
        return 2;
    }
    else if ( DiffStr == "4" || DiffStr == "HARD" ) {
        DiffStr = "Hard";
        return 4;
    }
    else if ( DiffStr == "5" || DiffStr == "SUICIDAL" || DiffStr == "SUI" ) {
        DiffStr = "Suicidal";
        return 5;
    }
    else if ( DiffStr == "6" || DiffStr == "SUICIDAL+" || DiffStr == "SUI+" ) {
        DiffStr = "Suicidal+";
        return 6;
    }
    else if ( DiffStr == "7" || DiffStr == "HELLONEARTH" || DiffStr == "HOE" ) {
        DiffStr = "HoE";
        return 7;
    }
    else if ( DiffStr == "8" || DiffStr == "HELLONEARTH+" || DiffStr == "HOE+" ) {
        DiffStr = "HoE+";
        return 8;
    }
    return 255;
}

defaultproperties
{
    HelpInfo(00)="%gLOCKPERK%w|%gUNLOCKPERK %y[!] <perk1> [<perk2> ...]%w Disables/Enables perk at the end of the wave"
    HelpInfo(01)="%gLOCKTEAM%w|%gUNLOCKTEAM %w Locks/Unlocks teams. Only invited players may join locked team."
    HelpInfo(02)="%gPAUSE %yX %w Pause the game for X seconds"
    HelpInfo(03)="%gEND TRADE %w Immediately end current trader time and start next wave"
    HelpInfo(04)="%gEND WAVE %w Kills last stuck zeds to end the wave"
    HelpInfo(05)="%gBLAME %y<player_name> %b[<reason>] %w Blame player [for the <reason>]"
    HelpInfo(06)="%gSPEC %y<player_name> %b[<reason>] %w Move player to spectators"
    HelpInfo(07)="%gKICK %y<player_name> %b[<reason>] %w Kick player [for the <reason>]"
    HelpInfo(08)="%gINVITE %y<player_name> %w Invite player to join locked team."
    HelpInfo(09)="%gBORING %w Doubles ZED spawn rate"
    HelpInfo(10)="%gREADY%w|%gUNREADY %w Makes everybody ready/unready to play"
    HelpInfo(11)="%gFF %yX %w Set Friendly Fire to X%"
    HelpInfo(12)="%gMAP RESTART %w Restart current map"
    HelpInfo(13)="%gMAP RANDOM %w Switch to a random map"
    HelpInfo(14)="%gMAP %y<mapname> %b[<game>] [<diff>] %w Switch map/gamemode/difficulty"
    HelpInfo(15)="%gFAKED %yX %w Set Faked Players to X (FAKEDCOUNT+FAKEDHEALTH)"
    HelpInfo(16)="%gFAKEDCOUNT %yX %w Set Faked Players for zed count calculation"
    HelpInfo(17)="%gFAKEDHEALTH %yX %w Set Faked Players for zed health calculation"
    HelpInfo(18)="%gDIFF %yX %w Changes map difficulty (2-8) for the next map"

    strCantEndTrade="Can not end trade time at the current moment"
    strTooLate="Too late"
    strPauseTraderOnly="Game can be paused only during trader time!"
    strZedSpawnsDoubled="ZED spawn rate doubled!"
    strSquadNotFound="Monster squad with a given name not found"
    strCantSpawnSquadNow="Can not spawn monsters at this moment"
    strSquadList="Avaliable Squads:"
    strNotInStoryMode="Not avaliable in Story Mode"
    strNotInTSC="Not avaliable in TSC"
    strNotDead="Dead players cannot initial this vote"
    strCantEndWaveNow="Can't end the wave now"
    strEndWavePenalty="Team charged for premature wave end with $"
    strRCommands="R_* commands can be executed only by Referee (Spectator + Admin rights + Tourney Mode)"
    strBlamed="%p blamed %r"
    strBlamedBaron="%p blamed for blaming Baron"
    strWrongPerk="Wrong perk (%s)"
    strMapNameTooShort="Enter at least 3 letters for map name to search or HELP|LIST|RESTART|RANDOM"
    strMapNotFound="Map not found"
    strWrongGameConfig="Wrong game config code: %s"

    viResume="RESUME GAME"
    viEndTrade="END TRADER TIME"
    viDifficulty="Difficulty"
}
