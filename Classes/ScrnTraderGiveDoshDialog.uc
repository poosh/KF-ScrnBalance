class ScrnTraderGiveDoshDialog extends ScrnMessageBox;

var ScrnPlayerController ScrnPC;

var localized string strTitle;
var localized string strTeam;
var localized string strGive;

var transient int Dosh, MaxDosh;
var int BarToDoshScale;
var int IconMargin;

var Material TeamIcon;

var automated GUIImage IconBG;
var automated GUIImage Icon;
var automated GUIImage TextBG;
var automated GUIEditBox Input;
var automated ScrnGUIHorzScrollBar Bar;

var protected bool bDoshSetting;

var automated GUIHorzGripButton BarGrip;
var automated GUIHorzScrollButton BarIncButton, BarDecButton;

var Color PlayerNameColor;


static function ScrnTraderGiveDoshDialog ShowMe(ScrnPlayerController PC, PlayerReplicationInfo DoshReceiver)
{
    local ScrnTraderGiveDoshDialog myself;
    local string msg;

    if (int(PC.PlayerReplicationInfo.Score) <= 0)
        return none;

    if (DoshReceiver == none) {
        msg = default.strTeam;
    }
    else {
        msg = class'ScrnF'.static.ColoredPlayerName(DoshReceiver);
    }

    myself = ScrnTraderGiveDoshDialog(ShowMessage(PC, default.strTitle, msg));
    if (myself == none)
        return none;

    PC.GUI_PRI = DoshReceiver;
    myself.ScrnPC = PC;
    myself.Prepare();
    return myself;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

}

function Prepare()
{
    local ScrnCustomPRI ScrnPRI;
    local float x2y, x, y;

    x2y = float(Controller.ResX) / float(Controller.ResY);

    if (ScrnPC.GUI_PRI == none) {
        Icon.Image = TeamIcon;
    }
    else {
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(ScrnPC.GUI_PRI);
        if (ScrnPRI != none && ScrnPRI.GetSpecialIcon() != none) {
            Icon.Image = ScrnPRI.GetSpecialIcon();
        }
        else {
            Icon.Image = ScrnPC.GUI_PRI.GetPortrait();
            x2y *= 1.5;  // Character protraits are taller
        }
    }

    IconBG.WinHeight = IconBG.WinWidth * x2y;

    x = float(IconMargin) / Controller.ResX;
    y = float(IconMargin) / Controller.ResY;
    Icon.WinLeft = IconBG.WinLeft + x;
    Icon.WinTop = IconBG.WinTop + y;
    Icon.WinWidth = IconBG.WinWidth - 2*x;
    Icon.WinHeight = IconBG.WinHeight - 2*y;

    MaxDosh = min(99999, ScrnPC.PlayerReplicationInfo.Score);
    Bar.ItemCount = ((MaxDosh + BarToDoshScale - 1) / BarToDoshScale) + 1;
    SetDosh(0);
}

function SetDosh(int value, optional GUIComponent Sender)
{
    if (bDoshSetting)
        return;
    bDoshSetting = true;

    Dosh = clamp(value, 0, MaxDosh);
    if (Sender != Input) {
        Input.SetText(string(Dosh));
    }
    if (Sender != Bar) {
        Bar.CurPos = Dosh / BarToDoshScale;
        Bar.AlignThumb();
    }
    b_OK.Caption = strGive @ class'ScrnUnicode'.default.Dosh @ Dosh;
    class'ScrnGUI'.static.ButtonEnable(b_OK, Dosh > 0);

    bDoshSetting = false;
}

function bool OnDoshEditKey(out byte Key, out byte State, float delta)
{
    // PlayerOwner().ClientMessage("OnSearchKeyType Key="$Key @ "State="$State);
    if (State != 1)
        return false;  // not a key press

    switch (Key) {
        case 0x0D: // IK_Enter
            class'ScrnGUI'.static.ButtonClick(b_OK);
            return true;
        case 0x21: // IK_PageUp
            if (Controller.CtrlPressed) {
                SetDosh(MaxDosh);
            }
            else {
                Bar.MoveGripBy(Bar.BigStep);
            }
            return true;
        case 0x22: // IK_PageDown
            if (Controller.CtrlPressed) {
                SetDosh(0);
            }
            else {
                Bar.MoveGripBy(-Bar.BigStep);
            }
            return true;
        case 0x26: // IK_Up
            if (Controller.CtrlPressed) {
                Bar.MoveGripBy(Bar.BigStep);
            }
            else {
                Bar.MoveGripBy(Bar.Step);
            }
            return true;
        case 0x28: // IK_Down
            if (Controller.CtrlPressed) {
                Bar.MoveGripBy(-Bar.BigStep);
            }
            else {
                Bar.MoveGripBy(-Bar.Step);
            }
            return true;
    }
    return Input.InternalOnKeyEvent(Key, State, delta);
}

function OnDoshEditChange(GUIComponent Sender)
{
    SetDosh(int(Input.GetText()), Input);
}

function OnDoshScroll(int Position)
{
    Bar.MyGripButton.ImageIndex = Position-1;
    SetDosh(Position * BarToDoshScale, Bar);
}

function TransferDosh()
{
    if (Dosh > 0) {
        ScrnPC.ScrnPawn.ServerDoshTransfer(Dosh, ScrnPC.GUI_PRI);
    }
}

function Close(bool bCancel)
{
    if (!bCancel) {
        if (Dosh > 0) {
            ScrnPC.ScrnPawn.ServerDoshTransfer(Dosh, ScrnPC.GUI_PRI);
        }
        else {
            bCancel = true;  // wtf?
        }
    }
    super.Close(bCancel);
    ScrnPC.GUI_PRI = none;
}

function bool PlayerNameDraw(Canvas C)
{
    local GUIComponent me;
    local float X, Y, W, H, XL, YL;

    if (ScrnPC.GUI_PRI == none)
        return false;  // native draw of the team name

    me = l_Text2;
    C.DrawColor = PlayerNameColor;
    X = me.WinLeft * C.ClipX;
    Y = me.WinTop * C.ClipY;
    W = me.WinWidth * C.ClipX;
    H = me.WinHeight * C.ClipY;
    class'ScrnScoreboard'.static.TextSizeCountrySE(C, ScrnPC.GUI_PRI, XL, YL);
    class'ScrnScoreboard'.static.DrawCountryNameSE(C, ScrnPC.GUI_PRI, X + (W - XL)/2, Y + (H - YL)/2);
    return true;
}


defaultproperties
{
    // these are coordinates of the frame, now the window.
    // GUI elements must use absolute coordinates withing the frame.
    WinLeft=0.28
    WinWidth=0.44
    WinTop=0.27
    WinHeight=0.36

    Begin Object Class=GUILabel Name=DialogTitle
        Caption="Give dosh to:"
        TextAlign=TXTA_Center
        TextColor=(R=255,G=255,B=255,A=255)
        VertAlign=TXTA_Left
        FontScale=FNS_Large
        WinLeft=0.28
        WinWidth=0.44
        WinTop=0.270
        WinHeight=0.03
    End Object
    l_Text=DialogTitle
    strTitle="Give Dosh To:"

    Begin Object Class=GUIImage Name=IconBGImage
        Image=Texture'KF_InterfaceArt_tex.Menu.Item_box_box'
        ImageStyle=ISTY_Stretched
        WinLeft=0.30
        WinWidth=0.045
        WinTop=0.31
        WinHeight=0.09
        RenderWeight=0.20
    End Object
    IconBG=IconBGImage

    TeamIcon=Texture'ScrnTex.Players.Dosh'
    Begin Object Class=GUIImage Name=IconImage
        Image=Texture'ScrnTex.Players.Dosh'
        ImageStyle=ISTY_Scaled
        WinLeft=0.305
        WinWidth=0.035
        WinTop=0.315
        WinHeight=0.080
        RenderWeight=0.21
    End Object
    Icon=IconImage
    IconMargin=3  // px

    Begin Object Class=GUIImage Name=TextBackground
        Image=Texture'KF_InterfaceArt_tex.Menu.Item_box_bar'
        ImageStyle=ISTY_Stretched
        WinLeft=0.345
        WinWidth=0.355
        WinTop=0.325
        WinHeight=0.05
    End Object
    TextBG=TextBackground

    // Player Name / Team Wallet
    Begin Object Class=GUILabel Name=DialogText
        TextAlign=TXTA_Center
        VertAlign=TXTA_Center
        FontScale=Font_VeryLarge
        TextColor=(R=0,G=64,B=0,A=255)
        bMultiLine=False
        WinLeft=0.30
        WinWidth=0.40
        WinTop=0.325
        WinHeight=0.05
        OnDraw=PlayerNameDraw
    End Object
    l_Text2=DialogText
    PlayerNameColor=(R=0,G=0,B=0,A=255)
    strTeam="<TEAM WALLET>"

    Begin Object Class=GUIEditBox Name=DoshEdit
        FontScale=Font_VeryLarge
        WinTop=0.40
        WinLeft=0.47
        WinWidth=0.06
        WinHeight=0.05
        bIntOnly=true
        bIncludeSign=false
        MaxWidth=5
        bReadOnly=false
        TabOrder=0
        bTabStop=true
        OnKeyEvent=OnDoshEditKey
        OnChange=OnDoshEditChange
    End Object
    Input=DoshEdit

    Begin Object Class=ScrnGUIHorzScrollBar Name=DoshScrollBar
        WinLeft=0.30
        WinWidth=0.40
        WinTop=0.47
        WinHeight=0.045
        Step=1
        BigStep=10
        ItemsPerPage=1
        MinGripPixels=100
        TabOrder=1
        bTabStop=false
        PositionChanged=OnDoshScroll
    End Object
    Bar=DoshScrollBar
    BarToDoshScale=100

    Begin Object Class=GUIButton Name=CancelButton
        Caption="Cancel"
        WinTop=0.54
        WinLeft=0.30
        WinWidth=0.15
        WinHeight=0.05
        bVisible=true
        TabOrder=3
        bTabStop=true
        OnClick=InternalOnClick
        OnKeyEvent=CancelButton.InternalOnKeyEvent
    End Object
    b_Cancel=CancelButton

    Begin Object Class=GUIButton Name=OkButton
        Caption="OK"
        WinTop=0.54
        WinLeft=0.55
        WinWidth=0.15
        WinHeight=0.05
        bVisible=true
        TabOrder=4
        bTabStop=true
        OnClick=InternalOnClick
        OnKeyEvent=OkButton.InternalOnKeyEvent
    End Object
    b_OK=OkButton
    strGive="Give"
}