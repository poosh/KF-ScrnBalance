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
function PositionButtons (Canvas C)
{
    local int i, j;
    local GUIButton b;
    local array<GUIButton> buttons;
    local float x;

    // sort buttons by tab order
    for ( i = 0; i < Controls.Length; i++ ) {
        b = GUIButton(Controls[i]);
        if ( b != None)    {
            for ( j=0; j<buttons.length; ++j ) {
                if ( buttons[j].TabOrder >= b.TabOrder )
                    break;
            }
            buttons.insert(j, 1);
            buttons[j] = b;
        }
    }
    
    // position buttons
    for ( j=0; j<buttons.length; ++j ) {
        b = buttons[j];
        if ( x == 0 )
            x = ButtonLeft;
        else x += GetSpacer();
        b.WinLeft = b.RelativeLeft( x, True );
        x += b.ActualWidth();    
    }
}

function bool OnFooterClick(GUIComponent Sender)
{
    if ( Sender == b_Perks ) {
        PlayerOwner().ClientOpenMenu(string(Class'ScrnBalanceSrv.ScrnInvasionLoginMenu'), false);
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
    
    Begin Object Class=GUIButton Name=ViewMap
        Caption="View Map"
        Hint="Spectate the map while waiting for players to get ready"
        WinTop=0.966146
        WinLeft=0.16
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=4
        bBoundToParent=True
        ToolTip=None

        OnClick=LobbyFooter.OnFooterClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_ViewMap=GUIButton'ScrnBalanceSrv.ScrnLobbyFooter.ViewMap'    
}
