class TSCClanAdmin extends Info
    Config(ScrnClans);

var config array<string> Referees;
var config array<string> Streamers;

var TSCGame TSC;
var array<string> Guests;
var bool bSpecLocked;
var localized string strSpecKickReason;
var localized string strBecameReferee, strBecameStreamer, strBecameGuest, strBecameNobody;

var protected transient bool bSpectatorCheckInProgress;

function PostBeginPlay()
{
    TSC = TSCGame(Level.Game);
    if (TSC == none) {
        warn("ERROR: Wrong GameType ("$Level.Game$") - TSCGame required");
        Destroy();
        return;
    }
}

function bool StartClanGame(TSCClanInfo RedClan, TSCClanInfo BlueClan)
{
    local TSCClanReplicationInfo RedRep, BlueRep;

    RedRep = class'TSCClanReplicationInfo'.static.Create(TSC.TSCTeams[0], RedClan);
    if (RedRep == none) {
        return false;
    }

    BlueRep = class'TSCClanReplicationInfo'.static.Create(TSC.TSCTeams[1], BlueClan);
    if (BlueRep == none) {
        RedRep.Destroy();
        return false;
    }

    TSC.TSCTeams[0].ClanRep = RedRep;
    TSC.TSCTeams[1].ClanRep = BlueRep;

    return true;
}

function StopClanGame()
{
    if (TSC.TSCTeams[0].ClanRep != none) {
        TSC.TSCTeams[0].ClanRep.Destroy();
        TSC.TSCTeams[0].ClanRep = none;
    }
    if (TSC.TSCTeams[1].ClanRep != none) {
        TSC.TSCTeams[1].ClanRep.Destroy();
        TSC.TSCTeams[1].ClanRep = none;
    }
    TSC.bClanGame = false;
}

function GameEnded()
{
    UnlockSpectators();
}

function bool ClanParseCaptain(byte t, ScrnPlayerController PC, out array<ScrnPlayerController> Captains,
        out int Priority)
{
    local int p;

    p = TSC.TSCTeams[t].ClanRep.Clan.CaptainPriority(PC.GetPlayerIDHash());
    if (p < 0)
        return false;


    if (p < Priority) {
        Captains.insert(0, 1);
        Captains[0] = PC;
        Priority = p;
    }
    else {
        // there are clan captains with higher priority on the server
        Captains[Captains.length] = PC;
    }
    return true;
}

function ClanParseMember(ScrnPlayerController PC, out array<ScrnPlayerController> Members)
{
    if (PC.PlayerReplicationInfo.bOnlySpectator) {
        Members[Members.Length] = PC;
    }
    else {
        Members.insert(0, 1);
        Members[0] = PC;
    }
}

function ClanParseEnsureTeamIndex(byte t, out array<ScrnPlayerController> Members)
{
    local int i;
    local ScrnPlayerController PC;

    for (i = 0; i < Members.Length; ++i) {
        PC = Members[i];
        PC.SetSpecTeam(t);
        TSC.InvitePlayer(PC);
        if (PC.PlayerReplicationInfo.Team == TSC.TSCTeams[1-t]) {
            PC.ServerChangeTeam(t);
        }
    }
}

function ClanParseLimitTeamSize(byte t, out array<ScrnPlayerController> Members)
{
    local int i;
    local ScrnPlayerController PC;

    for (i = Members.Length - 1; i >= 0 && TSC.TSCTeams[t].Size > TSC.MaxTeamSize; --i) {
        PC = Members[i];
        if (!PC.PlayerReplicationInfo.bOnlySpectator) {
            PC.BecomeSpectator();
        }
    }
}

function ClanParseTeamWelcome(byte t, out array<ScrnPlayerController> Members)
{
    local int i;
    local ScrnPlayerController PC;
    local PlayerReplicationInfo PRI;

    for (i = 0; i < Members.Length; ++i) {
        PC = Members[i];
        PRI = PC.PlayerReplicationInfo;
        if (PRI.bOnlySpectator && TSC.TSCTeams[t].Size < TSC.MaxTeamSize) {
            PC.BecomeActivePlayer();
        }
        if (!PRI.bOnlySpectator) {
            PC.ServerChangeTeam(t);
            PC.ShowLobbyMenu();
        }
    }
}

function ClanParseTeamCaptain(byte t, out array<ScrnPlayerController> Captains)
{
    local int i;
    local ScrnPlayerController PC;
    local PlayerReplicationInfo PRI;

    for (i = 0; i < Captains.Length; ++i) {
        PC = Captains[i];
        PRI = PC.PlayerReplicationInfo;
        if (!PRI.bOnlySpectator) {
            TSC.SetTeamCaptain(t, PRI);
            return;
        }
    }
}

function ForceClanTeams()
{
    local int i;
    local ScrnPlayerController PC;
    local PlayerReplicationInfo PRI;
    local string id;
    local int RedPriority, BluePriority;
    local array<ScrnPlayerController> RedCaptains, BlueCaptains, RedPlayers, BluePlayers, ReservePlayers;
    local TSCClanInfo Clans[2];

    Clans[0] = TSC.TSCTeams[0].ClanRep.Clan;
    Clans[1] = TSC.TSCTeams[1].ClanRep.Clan;

    TSC.SetTeamCaptain(0, none);
    TSC.SetTeamCaptain(1, none);
    TSC.InviteList.length = 0;
    TSC.ScrnBalanceMut.bTeamsLocked = false;

    RedPriority = 255;
    BluePriority = 255;

    // Sort players by teams. Move non-clan members to spectators.
    for ( i = 0; i < TSC.TSCGRI.PRIArray.Length; ++i ) {
        PRI = TSC.TSCGRI.PRIArray[i];
        if (PRI == none)
            continue;  // is this possible?
        PC = ScrnPlayerController(PRI.Owner);
        if (PC == none)
            continue;

        id = PC.GetPlayerIDHash();

        if (ClanParseCaptain(0, PC, RedCaptains, RedPriority))
            continue;
        if (ClanParseCaptain(1, PC, BlueCaptains, BluePriority))
            continue;

        if (Clans[0].IsPlayer(id)) {
            if (Clans[1].IsPlayer(id)) {
                // The player is a member of both clans - mote to reserve.
                ClanParseMember(PC, ReservePlayers);
            }
            else {
                ClanParseMember(PC, RedPlayers);
            }
        }
        else if (Clans[1].IsPlayer(id)) {
            ClanParseMember(PC, BluePlayers);
        }
        else {
            PC.SetSpecTeam(200);
            if (!PRI.bOnlySpectator) {
                PC.BecomeSpectator();
            }
        }
    }

    // Merge captain into the player list for convenience.
    class'ScrnFunctions'.static.ObjArrayInsert(RedPlayers, RedCaptains);
    class'ScrnFunctions'.static.ObjArrayInsert(BluePlayers, BlueCaptains);

    // Fill the gap with reserve players (if needed)
    for (i = 0; i < ReservePlayers.Length; ++i) {
        if (RedPlayers.Length <= BluePlayers.Length) {
            if (RedPlayers.Length < TSC.MaxTeamSize)
                RedPlayers[RedPlayers.Length] = ReservePlayers[i];
            else
                break;
        }
        else if (BluePlayers.Length < TSC.MaxTeamSize) {
            BluePlayers[BluePlayers.Length] = ReservePlayers[i];
        }
        else {
            break;
        }
    }
    if (i > 0) {
        ReservePlayers.remove(0, i);
    }

    // Ensure players are on the right team. Don't touch spectators yet.
    ClanParseEnsureTeamIndex(0, RedPlayers);
    ClanParseEnsureTeamIndex(1, BluePlayers);

    // if there are too many players, move the bottom of the list to spectators.
    ClanParseLimitTeamSize(0, RedPlayers);
    ClanParseLimitTeamSize(1, BluePlayers);

    // if there are not enough players, move the top of the list to active players. Welcome team members.
    ClanParseTeamWelcome(0, RedPlayers);
    ClanParseTeamWelcome(1, BluePlayers);

    // Promote the top Clan Captain to the Team Captain
    ClanParseTeamCaptain(0, RedCaptains);
    ClanParseTeamCaptain(1, BlueCaptains);
}

function CheckSpectators()
{
    local int i;
    local PlayerReplicationInfo PRI;

    if (!TSC.bClanGame)
        return;

    if (bSpectatorCheckInProgress)
        return;

    bSpectatorCheckInProgress = true;
    for ( i = 0; i < TSC.TSCGRI.PRIArray.Length; ++i ) {
        PRI = TSC.TSCGRI.PRIArray[i];
        if (PRI == none || !PRI.bOnlySpectator)
            continue;

        CheckSpectator(ScrnPlayerController(PRI.Owner));
    }
    bSpectatorCheckInProgress = false;
}

function CheckSpectator(ScrnPlayerController PC)
{
    local PlayerReplicationInfo PRI;
    local string id;

    if (PC == none || PC.GetSpecTeam() < 100)
        return;

    PRI = PC.PlayerReplicationInfo;
    id = PC.GetPlayerIDHash();

    if (PRI.bAdmin) {
        // Ensure admins are referees, so they can safely reconnect without getting banned befor adminlogin.
        AddReferee(id);
        PC.SetSpecTeam(255);
    }
    else if (IsReferee(id)) {
        if (PC.SetSpecTeam(250)) {
            TSC.ScrnBalanceMut.BroadcastMessage(Repl(strBecameReferee, "%p", class'ScrnF'.static.PlainPlayerName(PRI),
                    true));
        }
    }
    else if (IsStreamer(id)) {
        if (PC.SetSpecTeam(220)) {
            TSC.ScrnBalanceMut.BroadcastMessage(Repl(strBecameStreamer, "%p", class'ScrnF'.static.PlainPlayerName(PRI),
                    true));
        }
    }
    else if (IsGuest(id)) {
        if (PC.SetSpecTeam(210)) {
            TSC.ScrnBalanceMut.BroadcastMessage(Repl(strBecameGuest, "%p", class'ScrnF'.static.PlainPlayerName(PRI),
                    true));
        }
    }
    else if (PC.GetSpecTeam() >= 200) {
        if (PC.SetSpecTeam(200)) {
            TSC.ScrnBalanceMut.BroadcastMessage(Repl(strBecameNobody, "%p", class'ScrnF'.static.PlainPlayerName(PRI),
                    true));
        }
        if (bSpecLocked) {
            TSC.ScrnBalanceMut.KickPlayer(PC, false, strSpecKickReason);
        }
    }
}

function LockSpectators()
{
    if (!TSC.bClanGame)
        return;

    bSpecLocked = true;
    CheckSpectators();
}

function UnlockSpectators()
{
    bSpecLocked = false;
}

function bool IsReferee(string PlayerID)
{
    return class'ScrnFunctions'.static.SearchStr(Referees, PlayerID) != -1;
}

function bool IsStreamer(string PlayerID)
{
    return class'ScrnFunctions'.static.SearchStr(Streamers, PlayerID) != -1;
}

function bool IsGuest(string PlayerID)
{
    return class'ScrnFunctions'.static.SearchStr(Guests, PlayerID) != -1;
}

function bool AddReferee(string PlayerID)
{
    if (IsReferee(PlayerID))
        return false;

    Referees[Referees.length] = PlayerID;
    SaveConfig();
    CheckSpectators();
    return true;
}

function bool AddStreamer(string PlayerID)
{
    if (IsStreamer(PlayerID))
        return false;

    Streamers[Streamers.length] = PlayerID;
    SaveConfig();
    CheckSpectators();
    return true;
}

function bool AddGuest(string PlayerID)
{
    if (IsGuest(PlayerID))
        return false;

    Guests[Guests.length] = PlayerID;
    CheckSpectators();
    return true;
}

function bool RemoveReferee(string PlayerID)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(Referees, PlayerID);
    if (i == -1)
        return false;

    Referees.remove(i, 1);
    SaveConfig();
    CheckSpectators();
    return true;
}

function bool RemoveStreamer(string PlayerID)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(Streamers, PlayerID);
    if (i == -1)
        return false;

    Streamers.remove(i, 1);
    SaveConfig();
    CheckSpectators();
    return true;
}

function bool RemoveGuest(string PlayerID)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(Guests, PlayerID);
    if (i == -1)
        return false;

    Guests.remove(i, 1);
    CheckSpectators();
    return true;
}

function bool BelongsToGame(string PlayerID)
{
    return TSC.TSCTeams[0].ClanRep.Clan.IsMember(PlayerID)
            || TSC.TSCTeams[1].ClanRep.Clan.IsMember(PlayerID)
            || IsReferee(PlayerID)
            || IsStreamer(PlayerID)
            || IsGuest(PlayerID);
}

function PreLogin(string Options, string Address, string PlayerID, out string Error, out string FailCode)
{
    if (bSpecLocked && !BelongsToGame(PlayerID)) {
        FailCode = "AC_SessionBan";
        Error = strSpecKickReason;
    }
}


defaultproperties
{
    strSpecKickReason="Not allowed to spectate a private clan game"
    strBecameReferee="^u$%p is a REFEREE"
    strBecameStreamer="^g$%p is a STREAMER"
    strBecameGuest="^g$%p is a GUEST"
    strBecameNobody="^o$%p is a RANDOM SPECTATOR"
}
