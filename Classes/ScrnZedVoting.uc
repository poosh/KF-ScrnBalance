class ScrnZedVoting extends ScrnVotingOptions;

var ScrnGameLength GL;


const VOTE_ZED     = 0;

var string ZedVote;

// returns :
//  0 - vote is on
//  1 - vote is off
//  2 - partially on (some are on and some are off)
// -1 - vote not found
function int VoteState(string vote)
{
    local int i, j, result, value;

    result = -1;
    for ( i = 0; i < GL.ZedInfos.length; ++i ) {
        for ( j = 0; j < GL.ZedInfos[i].Zeds.length; ++j ) {
            if ( GL.ZedInfos[i].Zeds[j].Vote ~= vote ) {
                value = int((!GL.ZedInfos[i].Zeds[j].bDisabled) ^^ GL.ZedInfos[i].Zeds[j].bVoteInvert);
                if ( result == -1 )
                    result = value;
                else if ( result != value )
                    return 2;
            }
        }
    }
    return result;
}

function int GetGroupVoteIndex(PlayerController Sender, string Group, string Key, out string Value, out string VoteInfo)
{
    local int VoteValue, BoolValue;

    VoteValue = VoteState(Key);
    BoolValue = TryStrToBool(Value);
    if ( VoteValue == -1 )
        return VOTE_UNKNOWN;
    else if ( BoolValue == -1 )
        return VOTE_ILLEGAL;
    else if ( BoolValue == VoteValue )
            return VOTE_NOEFECT;
    ZedVote = Key;
    return VOTE_ZED;
}

function ApplyVoteValue(int VoteIndex, string VoteValue)
{
    local int i, j;
    local int BoolValue;
    local bool bDisabled, bChanged;

    BoolValue = TryStrToBool(VoteValue);
    bDisabled = !bool(BoolValue);

    for ( i = 0; i < GL.ZedInfos.length; ++i ) {
        bChanged = false;
        for ( j = 0; j < GL.ZedInfos[i].Zeds.length; ++j ) {
            if ( GL.ZedInfos[i].Zeds[j].Vote ~= ZedVote ) {
                GL.ZedInfos[i].Zeds[j].bDisabled = bDisabled ^^ GL.ZedInfos[i].Zeds[j].bVoteInvert;
                bChanged = true;
            }
        }
        if ( bChanged )
            GL.ZedInfos[i].SaveConfig();
    }
}

function SendGroupHelp(PlayerController Sender, string Group)
{
    local string s;
    local int i;
    local int ln;

    ln = 1;
    for ( i = 0; i < GL.ZedVotes.length; ++i ) {

        switch (VoteState(GL.ZedVotes[i])) {
            case 0:     s @= "%r"; break;
            case 1:     s @= "%g"; break;
            case 2:     s @= "%y"; break;
            default:    s @= "%k"; break; // shouldn't happen
        }
        s $= GL.ZedVotes[i];
        if ( len(s) > 60 ) {
            // move to new line
            GroupInfo[ln++] = VotingHandler.ParseHelpLine(default.GroupInfo[1] @ s);
            s = "";
        }
    }
    if ( s != "" )
        GroupInfo[ln++] = VotingHandler.ParseHelpLine(default.GroupInfo[1] @ s);

    super.SendGroupHelp(Sender, Group);
}

defaultproperties
{
    DefaultGroup="ZED"

    HelpInfo(0)="%pZED %y<zed_vote> %gON%w|%rOFF %w Add|Remove zeds from the game. Type %bMVOTE ZED HELP %w for more info."

    GroupInfo(0)="%pZED %y<zed_vote> %gON%w|%rOFF %w Add or remove zeds from the game. Map restart required."
    GroupInfo(1)="%wZed votes:"
}
