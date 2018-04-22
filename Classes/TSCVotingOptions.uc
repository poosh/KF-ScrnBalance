class TSCVotingOptions extends ScrnVotingOptions
dependson(TSCGame);

var TSCGame TSC;

const VOTE_SHUFFLE              =  0;
const VOTE_ABORTSHUFFLE         =  1;
const VOTE_LOCK                 =  2;
const VOTE_UNLOCK               =  3;
const VOTE_INVITE               =  4;
const VOTE_CAPTAIN              =  5;
const VOTE_CARRIER              =  6;
const VOTE_HDMG                 =  7;
const VOTE_READY                =  8;
const VOTE_UNREADY              =  9;

var protected TSCGame.EHumanDamageMode HDmg;
var protected bool bHDmgHelpPrepared;
var array<localized string> HDmgHelp, HDmgValues;

var localized string strCaptain, strCarrier, strHumanDamage, strInvite;

function int GetGroupVoteIndex(PlayerController Sender, string Group, string Key, out string Value, out string VoteInfo)
{
    if ( Key == "SHUFFLE" ) {
        if ( TSC.IsTourney() ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_LOCAL;
        }
        if ( TSC.bPendingShuffle )
            return VOTE_NOEFECT;

        return VOTE_SHUFFLE;
    }
    else if ( Key == "ABORTSHUFFLE" ) {
        if ( !TSC.bPendingShuffle )
            return VOTE_NOEFECT;

        return VOTE_ABORTSHUFFLE;
    }
    else if ( Key == "LOCK" ) {
        // ScrnBalance v9.11+ handles team locks itself
        Sender.ServerMutate("VOTE LOCKTEAMS");
        return VOTE_LOCAL;
    }
    else if ( Key == "UNLOCK" ) {
        // ScrnBalance v9.11+ handles team locks itself
        Sender.ServerMutate("VOTE UNLOCKTEAMS");
        return VOTE_LOCAL;
    }
    else if ( Key == "INVITE" ) {
        // ScrnBalance v9.11+ handles team locks itself
        Sender.ServerMutate("VOTE INVITE " $ Value);
        return VOTE_LOCAL;
    }
    else if ( Key == "HDMG" ) {
        if ( !TSC.bVoteHDmg || TSC.IsTourney() || (TSC.bVoteHDmgOnlyBeforeStart && TSC.GameReplicationInfo.bMatchHasBegun) ) {
            Sender.ClientMessage(strOptionDisabled);
            return VOTE_LOCAL;
        }
        switch ( Value ) {
            case "OFF":
                HDmg = HDMG_None;
                break;
            case "NOFF":
                HDmg = HDMG_NoFF;
                break;
            case "NORMAL":
                HDmg = HDMG_Normal;
                break;
            case "PVP":
                HDmg = HDMG_PvP;
                break;
            case "HELP":
                SendHdmgHelp(Sender);
                return VOTE_LOCAL;
            default:
                SendHdmgHelp(Sender);
                return VOTE_ILLEGAL;
        }
        if ( HDmg == TSC.HumanDamageMode )
            return VOTE_NOEFECT;

        VoteInfo = strHumanDamage $ ": " $ Value;
        return VOTE_HDMG;
    }
    else if ( Key == "CAPTAIN" || Key == "C" ) {
        if ( !Sender.PlayerReplicationInfo.bAdmin && Sender.PlayerReplicationInfo.Team == none || Sender.PlayerReplicationInfo.Team.Size < 3 ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }
        if ( Value == "" ) {
            SendTeamPlayerList(Sender);
            return VOTE_LOCAL;
        }
        else if ( Value ~= "ME" )
            VotingHandler.VotedPlayer = Sender;
        else
            VotingHandler.VotedPlayer = FindPlayer(Value);

        if ( VotingHandler.VotedPlayer == none || VotingHandler.VotedPlayer.PlayerReplicationInfo.Team == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendTeamPlayerList(Sender);
            return VOTE_ILLEGAL;
        }

        if ( TSC.TSCGRI.TeamCaptain[VotingHandler.VotedPlayer.PlayerReplicationInfo.Team.TeamIndex] == VotingHandler.VotedPlayer )
            return VOTE_NOEFECT;
        else if ( !Sender.PlayerReplicationInfo.bAdmin && VotingHandler.VotedPlayer.PlayerReplicationInfo.Team != Sender.PlayerReplicationInfo.Team )
            return VOTE_ILLEGAL;

        VotingHandler.VotedTeam = VotingHandler.VotedPlayer.PlayerReplicationInfo.Team; // mark as team vote
        Value = TSC.ScrnBalanceMut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = strCaptain @ Value;
        return VOTE_CAPTAIN;
    }
    else if ( Key == "CARRIER" || Key == "A" ) {
        if ( Sender.PlayerReplicationInfo.Team == none || Sender.PlayerReplicationInfo.Team.Size < 3 ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }
        if ( Value == "" ) {
            SendTeamPlayerList(Sender);
            return VOTE_LOCAL;
        }
        else if ( Value ~= "ME" )
            VotingHandler.VotedPlayer = Sender;
        else
            VotingHandler.VotedPlayer = FindPlayer(Value);

        if ( VotingHandler.VotedPlayer == none ) {
            Sender.ClientMessage(strPlayerNotFound);
            SendTeamPlayerList(Sender);
            return VOTE_ILLEGAL;
        }
        if ( TSC.TSCGRI.TeamCarrier[Sender.PlayerReplicationInfo.Team.TeamIndex] == VotingHandler.VotedPlayer )
            return VOTE_NOEFECT;
        else if ( VotingHandler.VotedPlayer.PlayerReplicationInfo.Team != Sender.PlayerReplicationInfo.Team )
            return VOTE_ILLEGAL;

        VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team; // mark as team vote
        Value = TSC.ScrnBalanceMut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
        VoteInfo = strCarrier @ Value;
        return VOTE_CARRIER;
    }
    else if ( Key == "READY" ) {
        if ( !TSC.bWaitingToStartMatch )
            return VOTE_NOEFECT;

        VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team; // mark as team vote
        return VOTE_READY;
    }
    else if ( Key == "UNREADY" ) {
        if ( !TSC.bWaitingToStartMatch )
            return VOTE_NOEFECT;

        VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team; // mark as team vote
        return VOTE_UNREADY;
    }

    return VOTE_UNKNOWN;
}

function ApplyVoteValue(int VoteIndex, string VoteValue)
{
    switch ( VoteIndex ) {
        case VOTE_SHUFFLE:
            TSC.ShuffleTeams();
            break;
        case VOTE_ABORTSHUFFLE:
            TSC.bPendingShuffle = false;
            break;
        case VOTE_LOCK:
            TSC.LockTeams();
            break;
        case VOTE_UNLOCK:
            TSC.UnlockTeams();
            break;
        case VOTE_INVITE:
            TSC.InvitePlayer(VotingHandler.VotedPlayer);
            break;
        case VOTE_HDMG:
            TSC.SetHumanDamage(HDmg);
            break;
        case VOTE_CAPTAIN:
            TSC.SetTeamCaptain(VotingHandler.VotedTeam.TeamIndex, VotingHandler.VotedPlayer.PlayerReplicationInfo);
            break;
        case VOTE_CARRIER:
            TSC.TSCGRI.TeamCarrier[VotingHandler.VotedTeam.TeamIndex] = VotingHandler.VotedPlayer.PlayerReplicationInfo;
            break;
        case VOTE_READY:
            SetTeamReady(VotingHandler.VotedTeam.TeamIndex, true);
            break;
        case VOTE_UNREADY:
            SetTeamReady(VotingHandler.VotedTeam.TeamIndex, false);
            break;
    }
}

function SetTeamReady(byte TeamIndex, bool bReady)
{
    local Controller C;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( C.PlayerReplicationInfo != none && C.bIsPlayer && PlayerController(C) != none
                && C.PlayerReplicationInfo.Team != none && C.PlayerReplicationInfo.Team.TeamIndex == TeamIndex
                && C.PlayerReplicationInfo.bWaitingPlayer && !C.PlayerReplicationInfo.bOnlySpectator )
        {
            C.PlayerReplicationInfo.bReadyToPlay = bReady;
        }
    }
}

function SendTeamPlayerList(PlayerController Sender)
{
    local array<PlayerReplicationInfo> AllPRI;
    local PlayerController PC;
    local int i;

    Level.Game.GameReplicationInfo.GetPRIArray(AllPRI);
    for (i = 0; i<AllPRI.Length; i++) {
        if ( AllPRI[i].Team != Sender.PlayerReplicationInfo.Team )
            continue;

        PC = PlayerController(AllPRI[i].Owner);
        if( PC != none && AllPRI[i].PlayerName != "WebAdmin")
            Sender.ClientMessage(Right("   "$AllPRI[i].PlayerID, 3)$")"
                //@ PC.GetPlayerIDHash()
                @ AllPRI[i].PlayerName);
    }
}

function SendHdmgHelp(PlayerController Sender)
{
    local int i;

    if ( !bHDmgHelpPrepared ) {
        bHDmgHelpPrepared = true;
        for ( i=0; i<HDmgHelp.length; ++i )
            HDmgHelp[i] = VotingHandler.ParseHelpLine(HDmgHelp[i]);
    }
    // current setting
    HDmgHelp[2] = VotingHandler.ParseHelpLine(default.HDmgHelp[2] $ HDmgValues[TSC.HumanDamageMode]);

    for ( i=0; i<HDmgHelp.length; ++i ) {
        Sender.ClientMessage(HDmgHelp[i]);
    }
}

defaultproperties
{
    DefaultGroup="TEAM"

    strCaptain="Team Captain"
    strCarrier="Gnome Carrier"
    strHumanDamage="Human Damage"
    strInvite="Invite"

    HelpInfo(0)="%pTEAM %y<options> %w Team votes. Type %bMVOTE TEAM HELP %wfor more details."

    GroupInfo(0)="%pTEAM %gHDMG %yPVP%w|%yNORMAL%w|%yNOFF%w|%yOFF %w Set the rules for Human Damage"
    GroupInfo(1)="%pTEAM %gSHUFFLE %w Shuffle the teams by randomly moving players between them"
    GroupInfo(2)="%pTEAM %gABORTSHUFFLE %w Abort pending team shuffle"
    GroupInfo(3)="%pTEAM %gLOCK %w Lock teams, preventing new players to join"
    GroupInfo(4)="%pTEAM %gUNLOCK %w Unlock teams"
    GroupInfo(5)="%pTEAM %gINVITE %y<player_name> %w Allow player to bypass team lock"
    GroupInfo(6)="%pTEAM %bCAPTAIN %y<player_name> %w Choose your team's captain"
    GroupInfo(7)="%pTEAM %bCARRIER %y<player_name> %w If chosen, only Captain or Carrier can take the Base Guardian"
    GroupInfo(8)="%pTEAM %gREADY%w|%gUNREADY %w makes your team ready/unready to play"

    HDmgValues(0)="OFF"
    HDmgValues(1)="NOFF"
    HDmgValues(2)="NOFF_PVP"
    HDmgValues(3)="NORMAL"
    HDmgValues(4)="PVP"
    HDmgValues(5)="ALL"

    HDmgHelp(0)="Rules for Human Damage (player-to-player) damage."
    HDmgHelp(1)="mvote %pTEAM %gHDMG %yPVP%w|%yNORMAL%w|%yNOFF%w|%yOFF"
    HDmgHelp(2)="Current Rule: %g"
    HDmgHelp(3)="%yOFF %w Human Damage completely disabled. Players can not hurt each other."
    HDmgHelp(4)="%yNOFF %w NO Fiendly Fire. Players can not hurt teammates even outside the Base."
    HDmgHelp(5)="%yNORMAL %w Default setting. Players are immune to Human Damage while staying at own Base."
    HDmgHelp(6)="%yPVP %w Player-vs-Player Mode. Base protects only from Friendly Fire. Enemy damage is always in place."
}
