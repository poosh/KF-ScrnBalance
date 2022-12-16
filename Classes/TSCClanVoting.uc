class TSCClanVoting extends ScrnVotingOptions
dependson(TSCGame);

var TSCGame TSC;

const VOTE_GAME                 =  0;
const VOTE_CREATE               =  1;
const VOTE_ADD                  =  2;
const VOTE_REMOVE               =  3;
const VOTE_CAPTAIN              =  4;
const VOTE_LEAVE                =  5;

var TSCClanInfo VotedRedClan, VotedBlueClan;
var array<TSCClanInfo> Clans;

var string strNoClan, strNoClanPlayers, strClanAlreadyExists, strAdminOrCaptain;

function int GetGroupVoteIndex(PlayerController Sender, string Group, string Key, out string Value, out string VoteInfo)
{
    local string s1, s2;
    local TSCClanInfo Clan;

    if (Key == "GAME") {
        return VoteGame(Sender, Value, VoteInfo);
    }
    else if (Key == "CREATE") {
        if (!TSC.ScrnBalanceMut.CheckAdmin(Sender)) {
            return VOTE_LOCAL;
        }
        if (!Divide(Value, " ", s1, s2)) {
            return VOTE_ILLEGAL;
        }
        Clan = FindClan(s1, true);
        if (Clan.Exists()) {
            Sender.ClientMessage(strClanAlreadyExists);
            return VOTE_LOCAL;
        }
        Clan.ClanName = s2;
        VotedRedClan = Clan;
        VoteInfo = "CLAN CREATE [" $ s1 $ "] - " $ s2;
        return VOTE_CREATE;
    }
    else if (Key == "ADD") {
        return VotePlayerMod(Sender, VOTE_ADD, Value, VoteInfo);
    }
    else if (Key == "REMOVE") {
        return VotePlayerMod(Sender, VOTE_REMOVE, Value, VoteInfo);
    }
    else if (Key == "CAPTAIN") {
        return VotePlayerMod(Sender, VOTE_CAPTAIN, Value, VoteInfo);
    }
    else if (Key == "LEAVE") {
        Clan = FindTeamClan(Sender);
        if (Clan == none) {
            return VOTE_NOEFECT;
        }
        if (Clan.IsCaptain(Sender.GetPlayerIDHash())) {
            if (!TSC.ScrnBalanceMut.CheckAdmin(Sender)) {
                return VOTE_LOCAL;
            }
            else {
                Clan.RemoveCaptain(Sender.GetPlayerIDHash());
            }
        }
        else if (!Clan.RemovePlayer(Sender.GetPlayerIDHash())) {
            return VOTE_NOEFECT;
        }
        VotingHandler.VotedPlayer = Sender;
        Value = TSC.ScrnBalanceMut.ColoredPlayerName(Sender.PlayerReplicationInfo);
        VoteInfo = "CLAN [" $  Clan.Acronym $ "] LEAVE " $ Value;
        GotoState('AutoPass');
        return VOTE_LEAVE;
    }

    return VOTE_UNKNOWN;
}

function ApplyVoteValue(int VoteIndex, string VoteValue)
{
    switch ( VoteIndex ) {
        case VOTE_GAME:
            TSC.StartClanGame(VotedRedClan, VotedBlueClan);
            break;
        case VOTE_CREATE:
            VotedRedClan.Create();
            break;
    }

    VotedRedClan = none;
    VotedBlueClan = none;
}

function int VoteGame(PlayerController Sender, out string Value, out string VoteInfo)
{
    local string r, b;
    local TSCClanInfo RedClan, BlueClan;
    local bool bRedPlayers, bBluePlayers;
    local int i;
    local PlayerController PC;
    local PlayerReplicationInfo PRI;
    local string id;

    if (!TSC.bWaitingToStartMatch) {
        Sender.ClientMessage(strNotAvaliableATM);
        return VOTE_LOCAL;
    }
    if (!Divide(Value, " ", r, b) || InStr(b, " ") != -1) {
        return VOTE_ILLEGAL;
    }
    RedClan = FindClan(r);
    if (RedClan == none) {
        Sender.ClientMessage(repl(strNoClan, "%c", r));
        return VOTE_LOCAL;
    }
    BlueClan = FindClan(b);
    if (BlueClan == none) {
        Sender.ClientMessage(repl(strNoClan, "%c", b));
        return VOTE_LOCAL;
    }

    if (!TSC.ScrnBalanceMut.IsAdmin(Sender)) {
        for ( i = 0; i < TSC.TSCGRI.PRIArray.Length && (!bRedPlayers || !bBluePlayers); ++i ) {
            PRI = TSC.TSCGRI.PRIArray[i];
            if (PRI == none)
                continue;  // is this possible?
            PC = PlayerController(PRI.Owner);
            if (PC == none)
                continue;
            id = PC.GetPlayerIDHash();
            bRedPlayers = bRedPlayers || RedClan.IsMember(id);
            bBluePlayers = bBluePlayers || BlueClan.IsMember(id);
        }
        if (!bRedPlayers) {
            Sender.ClientMessage(repl(strNoClanPlayers, "%c", r));
            return VOTE_LOCAL;
        }
        if (!bBluePlayers) {
            Sender.ClientMessage(repl(strNoClanPlayers, "%c", b));
            return VOTE_LOCAL;
        }
    }

    // if reached here, the clan game is possible
    VotedRedClan = RedClan;
    VotedBlueClan = BlueClan;
    VoteInfo = "CLAN GAME: " $ RedClan.Acronym $ " vs. " $ BlueClan.Acronym;
    return VOTE_GAME;
}

function int VotePlayerMod(PlayerController Sender, int VoteIndex, out string Value, out string VoteInfo)
{
    local string PlayerName, ClanAcronym;
    local PlayerController Player;
    local TSCClanInfo Clan;
    local bool bAdmin;
    local bool b;
    local string id, cmd;

    bAdmin = TSC.ScrnBalanceMut.IsAdmin(Sender);
    if (!bAdmin && VoteIndex == VOTE_CAPTAIN) {
        Sender.ClientMessage(TSC.ScrnBalanceMut.strOnlyAdmin);
        return VOTE_LOCAL;
    }

    if (!Divide(Value, " ", PlayerName, ClanAcronym)) {
        PlayerName = Value;
    }

    Clan = FindTeamClan(Sender);
    if (Clan == none || !(Clan.Acronym ~= ClanAcronym)) {
        if (!bAdmin) {
            Sender.ClientMessage(strAdminOrCaptain);
            return VOTE_LOCAL;
        }
        else {
            Clan = FindClan(ClanAcronym);
            if (Clan == none) {
                Sender.ClientMessage(repl(strNoClan, "%c", ClanAcronym));
                return VOTE_LOCAL;
            }
        }
    }

    if (!bAdmin && !Clan.IsCaptain(Sender.GetPlayerIDHash())) {
        Sender.ClientMessage(strAdminOrCaptain);
        return VOTE_LOCAL;
    }

    Player = FindPlayer(PlayerName, Sender);
    if ( Player == none ) {
        Sender.ClientMessage(strPlayerNotFound);
        SendPlayerList(Sender);
        return VOTE_ILLEGAL;
    }
    id = Player.GetPlayerIDHash();

    switch (VoteIndex) {
        case VOTE_ADD:
            b = Clan.AddPlayer(id);
            cmd = "ADD";
            break;
        case VOTE_REMOVE:
            b = Clan.RemovePlayer(id) || (bAdmin && Clan.RemoveCaptain(id));
            cmd = "REMOVE";
            break;
        case VOTE_CAPTAIN:
            b = Clan.AddCaptain(id);
            cmd = "CAPTAIN";
            break;
        default:
            return VOTE_UNKNOWN;
    }

    if (!b) {
        return VOTE_NOEFECT;
    }
    if (!bAdmin) {
        VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team; // mark as team vote
    }
    VotingHandler.VotedPlayer = Player;
    Value = TSC.ScrnBalanceMut.ColoredPlayerName(Player.PlayerReplicationInfo);
    VoteInfo = "CLAN [" $ Clan.Acronym $ "] " $ cmd @ Value;

    // actually it is not a vote but a forced command. We just reusing features of Voting Handler
    // If we reached here, the vote must be passed.
    GotoState('AutoPass');
    return VoteIndex;
}

// Return clan of the player's team in a clan game. The player does not necessary is a clan member (can play by invite).
function TSCClanInfo FindTeamClan(PlayerController Player)
{
    local TSCTeam Team;

    if (!TSC.bClanGame || Player.PlayerReplicationInfo == none)
        return none;

    Team = TSCTeam(Player.PlayerReplicationInfo.Team);
    if (Team == none || Team.ClanRep == none)
        return none;

    return Team.ClanRep.Clan;
}

function TSCClanInfo FindClan(string Acronym, optional bool bCreate)
{
    local TscClanInfo Clan;

    if (Acronym == "" || InStr(Acronym, " ") != -1) {
        return none;
    }

    Clan = FindLoadedClan(Acronym);
    if (Clan != none) {
        return Clan;
    }

    Clan = new(none, Acronym) class'TSCClanInfo';
    if (Clan.Exists()) {
        Clans[Clans.length] = Clan;
        return Clan;
    }
    if (bCreate) {
        Clan.Acronym = Acronym;
        Clans[Clans.length] = Clan;
        return Clan;
    }
    return none;
}

function TSCClanInfo FindLoadedClan(string Acronym)
{
    local int i;

    for (i = 0; i < Clans.length; ++i) {
        if (Clans[i].Acronym ~= Acronym) {
            return Clans[i];
        }
    }
    return none;
}

state AutoPass
{
Begin:
    sleep(0.01);
    VotingHandler.VotePassed(VotingHandler.VoteInitiator.PlayerReplicationInfo.PlayerName);
    GotoState('');
}

defaultproperties
{
    DefaultGroup="CLAN"

    strNoClan="No such clan: [%c]";
    strNoClanPlayers="There are no clan [%c] members in the game";
    strClanAlreadyExists="Clan already exists"
    strAdminOrCaptain="Required ADMIN or CLAN CAPTAIN privileges"

    HelpInfo(0)="%pCLAN %y<options> %w Clan votes. Type %bMVOTE CLAN HELP %wfor more details."

    GroupInfo(0)="%pCLAN %gGAME %r<clan1> %b<clan2> %w Start a clan1 vs. clan2 game"
    GroupInfo(1)="%pCLAN %gCREATE %y<clan_acronym> <clan_name> %w Creates a new clan"
    GroupInfo(2)="%pCLAN %gADD %y<player_name> [<clan>] %w Add the player to the clan"
    GroupInfo(3)="%pCLAN %gREMOVE %y<player_name> [<clan>] %w Remove the player to the clan"
    GroupInfo(4)="%pCLAN %gCAPTAIN %y<player_name> [<clan>] %w Make the player a clan captain"
    GroupInfo(5)="%pCLAN %gLEAVE %w Leave the current clan"

}
