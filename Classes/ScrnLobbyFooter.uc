class ScrnLobbyFooter extends SRLobbyFooter;

var automated GUIButton b_ViewMap;

function bool InternalOnPreDraw(Canvas C)
{
    // disable View Map button in story more
    if ( !PlayerOwner().GameReplicationInfo.bMatchHasBegun && KF_StoryGRI(PlayerOwner().Level.GRI) == none )
        b_ViewMap.EnableMe();
    else
        b_ViewMap.DisableMe();

    return super.InternalOnPreDraw(C);
}

// overrided to position buttons by TabOrder
function PositionButtons(Canvas C)
{
    local int i, j;
    local GUIButton b;
    local array<GUIButton> buttons;
    local float x, s, m;

    // sort buttons by tab order
    for ( i = 0; i < Controls.Length; ++i ) {
        b = GUIButton(Controls[i]);
        if ( b != none && b != b_Cancel && b.bVisible ) {
            for ( j=0; j<buttons.length; ++j ) {
                if ( buttons[j].TabOrder >= b.TabOrder )
                    break;
            }
            buttons.insert(j, 1);
            buttons[j] = b;
        }
    }

    s = GetSpacer();
    m = GetMargin() / 2;
    x = ActualLeft() + ActualWidth() - m;
    // position the Disconnect button on the left, others on the right
    b_Cancel.WinLeft = b.RelativeLeft(m, true);
    for ( j = buttons.length - 1; j >= 0; --j ) {
        b = buttons[j];
        x -= b.ActualWidth();
        b.WinLeft = b.RelativeLeft(x, true);
        x -= s;
    }
}

function bool OnFooterClick(GUIComponent Sender)
{
    if ( Sender == b_Perks ) {
        PlayerOwner().ClientOpenMenu(string(class'ScrnInvasionLoginMenu'), false);
        return false;
    }
    else if ( Sender == b_ViewMap ) {
        if( KF_StoryGRI(PlayerOwner().Level.GRI) == none ) {
            LobbyMenu(PageOwner).bAllowClose = true;
            PlayerOwner().ClientCloseMenu(true, false);
            LobbyMenu(PageOwner).bAllowClose = false;
        }
    }
    else if(Sender == b_Ready) {
        return super(LobbyFooter).OnFooterClick(Sender); // bypass serverperks
    }
    else
        return super.OnFooterClick(Sender);
}

defaultproperties
{
    UnreadyString="Unready"

    Begin Object Class=GUIButton Name=Cancel
        Caption="Disconnect"
        Hint="Disconnect From This Server"
        WinTop=0.966146
        WinLeft=0.009000
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=0
        bBoundToParent=True
        ToolTip=None

        OnClick=LobbyFooter.OnFooterClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_Cancel=GUIButton'ScrnBalanceSrv.ScrnLobbyFooter.Cancel'

    Begin Object Class=GUIButton Name=ViewMap
        Caption="View Map"
        Hint="Spectate the map while waiting for players to get ready"
        WinTop=0.966146
        WinLeft=0.16
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=5
        bBoundToParent=True
        ToolTip=None

        OnClick=LobbyFooter.OnFooterClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_ViewMap=GUIButton'ScrnBalanceSrv.ScrnLobbyFooter.ViewMap'
}
