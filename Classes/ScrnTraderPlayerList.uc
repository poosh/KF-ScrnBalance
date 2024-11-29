class ScrnTraderPlayerList extends GUIVertList;

#exec OBJ LOAD FILE=ScrnTex.utx
#exec OBJ LOAD FILE=KF_InterfaceArt_tex.utx

var KFGameReplicationInfo KFGRI;

struct SPlayerRec {
    var int PlayerID;
    var byte DoshRequestCounter;
    var bool bMarked;
};
var array<SPlayerRec> Players;

var int ItemSpacing;
var int ItemMarginX, ItemMarginY;
var int IconMargin;
var int PlayersPerPage;

var texture DoshIcon;
var	texture	AvatarBG;
var	texture	ItemBG;
var	texture	HoverItemBG;

var Color TextColorHover, TextColorDoshRequest, TextColorDefault;

var int MouseOverIndex;

delegate OnPlayerSelected(PlayerReplicationInfo PRI);

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);
}

event Opened(GUIComponent Sender)
{
    super.Opened(Sender);

    KFGRI = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);
}

event Closed(GUIComponent Sender, bool bCancelled)
{
    SetIndex(-1);
    SetTimer(0, false);

    super.Closed(Sender, bCancelled);

    KFGRI = none;
    Players.length = 0;
}

event SetVisibility(bool bIsVisible)
{
    super.SetVisibility(bIsVisible);

    if (bVisible) {
        SetTimer(0.1, true);
        Timer();
    }
    else {
        SetTimer(0, false);
        Players.length = 0;
    }
}

function Timer()
{
    if (NeedUpdate()) {
        UpdateList();
    };
}

function bool NeedUpdate()
{
    // local int i;
    if (!bVisible)
        return false;
    if (Players.length == 0)
        return true;
    if (MouseOverIndex != -1 || IsInClientBounds())
        return false;
    return true;
}

function UpdateList()
{
    local int i, j;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;
    local PlayerReplicationInfo myPRI;
    local TeamInfo myTeam;

    myPRI = PlayerOwner().PlayerReplicationInfo;
    Players.length = 0;
    MyTeam = PlayerOwner().PlayerReplicationInfo.Team;

    for (i = 0; i < KFGRI.PRIArray.Length; ++i) {
        KFPRI = KFPlayerReplicationInfo(KFGRI.PRIArray[i]);
        if (KFPRI == none || KFPRI.PlayerID <= 0 || KFPRI.PlayerHealth <= 0 || KFPRI == myPRI || KFPRI.Team != myTeam)
            continue;
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(KFPRI);
        if (ScrnPRI == none) continue;
        if (ScrnPRI.DoshRequestCounter == 0) {
            j = Players.length;
        }
        else {
            for (j = 0; j < Players.length; ++j) {
                if (ScrnPRI.DoshRequestCounter > Players[j].DoshRequestCounter)
                    break;
            }
        }
        Players.insert(j, 1);
        Players[j].PlayerID = KFPRI.PlayerID;
        Players[j].DoshRequestCounter = ScrnPRI.DoshRequestCounter;
    }

    ItemCount = Players.Length;
    if (bNotify) {
        CheckLinkedObjects(Self);
    }

    if (MyScrollBar != none) {
        MyScrollBar.AlignThumb();
    }
}

function bool PreDraw(Canvas Canvas)
{
    local int NewIndex;

    if (IsInClientBounds()) {
        //  Figure out which Item we're clicking on
        NewIndex = Top + ((Controller.MouseY - ClientBounds[1]) / ItemHeight);

        if (NewIndex >= ItemCount) {
            NewIndex = -1;
        }
    }
    else {
        NewIndex = -1;
    }

    if (MouseOverIndex != NewIndex) {
        MouseOverIndex = NewIndex;
        if (MouseOverIndex == -1) {
            OnClickSound = CS_None;
        }
        else {
            Controller.PlayInterfaceSound(CS_Hover);
            OnClickSound = CS_Click;
        }
    }

    return false;
}

function DrawPlayerItem(Canvas C, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;
    local float XL, YL, TempX, IconSize;
    local string s;
    local bool bDoshRequest, bHover;
    local Material M;
    local Color TextColor;

    if (CurIndex < 0 || CurIndex >= Players.length)
        return;

    KFPRI = KFPlayerReplicationInfo(KFGRI.FindPlayerByID(Players[CurIndex].PlayerID));
    if (KFPRI == none)
        return;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(KFPRI);

    bDoshRequest = Players[CurIndex].DoshRequestCounter > 0;
    bHover = CurIndex == MouseOverIndex;

    if (bHover) {
        TextColor = TextColorHover;
    }
    else if (bDoshRequest) {
        TextColor = TextColorDoshRequest;
    }
    else {
        TextColor = TextColorDefault;
    }

    C.Style = 1;

    // Avatar
    C.SetDrawColor(255, 255, 255, 255);
    C.SetPos(X, Y);
    C.DrawTileStretched(AvatarBG, Height, Height);
    if (ScrnPRI != none) {
        M = ScrnPRI.GetSpecialIcon();
        bDoshRequest= ScrnPRI.DoshRequestCounter > 0;
    }
    if (M == none) {
        M = KFPRI.GetPortrait();
    }
    if (M != none) {
        // Character portraits have 1:2 ratio. Cut in half by using USize for both width and height.
        XL = M.MaterialUSize();
        YL = M.MaterialVSize();
        C.SetPos(X + IconMargin, Y + IconMargin);
        C.DrawTile(M, Height - 2*IconMargin, Height - 2*IconMargin, 0, 0, XL, YL);
    }

    X += Height;
    Y += ItemSpacing;
    Width -= Height;
    Height -= 2*ItemSpacing;

    // Background
    C.SetDrawColor(255, 255, 255, 255);
    if (bHover) {
        M = HoverItemBG;
    }
    else {
        M = ItemBG;
    }
    C.SetPos(X, Y);
    C.DrawTileStretched(M, Width, Height);

    // Player Name
    C.DrawColor = TextColor;
    class'ScrnScoreboard'.static.TextSizeCountrySE(C, KFPRI, XL, YL);
    class'ScrnScoreboard'.static.DrawCountryNameSE(C, KFPRI, X + ItemMarginX, Y + (Height - YL)/2);

    // Dosh Amount
    C.DrawColor = TextColor;
    s = class'ScrnUnicode'.default.Dosh @ int(KFPRI.Score);
    C.TextSize(s, XL, YL);
    TempX = X + Width - XL - ItemMarginX;
    C.SetPos(TempX, Y + (Height - YL)/2);
    C.DrawTextClipped(S,false);

    // Dosh Request Icon
    if (bDoshRequest) {
        // Position on the right side, left from the dosh text.
        // Align left; shift only if dosh >=100k
        C.TextSize("$ 99999", IconSize, YL);
        XL = fmax(IconSize, XL);
        IconSize = Height - 2*ItemMarginY;
        TempX -= IconSize + ItemMarginX;
        C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(TempX, Y + ItemMarginY);
        C.DrawTile(DoshIcon, IconSize, IconSize, 0, 0, DoshIcon.MaterialUSize(), DoshIcon.MaterialVSize());
    }
}

function float PlayerItemHeight(Canvas c)
{
    return MenuOwner.ActualHeight() / PlayersPerPage - 1;
}

function bool InternalOnClick(GUIComponent Sender)
{
    local int NewIndex;

    if (!IsInClientBounds() || Players.length == 0)
        return false;

    NewIndex = CalculateIndex();
    if (NewIndex == -1 || NewIndex >= Players.length)
        return false;

    SetIndex(NewIndex);
    OnPlayerSelected(KFGRI.FindPlayerByID(Players[NewIndex].PlayerID));
    return true;
}

defaultproperties
{
    MouseOverIndex=-1
    PlayersPerPage=5
    ItemSpacing=8
    ItemMarginX=8
    ItemMarginY=4
    IconMargin=3
    GetItemHeight=PlayerItemHeight
    OnPreDraw=PreDraw
    OnDrawItem=DrawPlayerItem;
    DoshIcon=Texture'ScrnTex.Players.Dosh'
    AvatarBG=Texture'KF_InterfaceArt_tex.Menu.Item_box_box'
    ItemBG=Texture'KF_InterfaceArt_tex.Menu.Item_box_bar'
    HoverItemBG=Texture'KF_InterfaceArt_tex.Menu.Item_box_bar_Highlighted'
    TextColorHover=(R=255,G=255,B=255,A=255)
    TextColorDoshRequest=(R=0,G=64,B=0,A=255)
    TextColorDefault=(R=0,G=0,B=0,A=255)
}
