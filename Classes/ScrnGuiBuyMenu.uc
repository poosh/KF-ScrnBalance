class ScrnGuiBuyMenu extends SRGUIBuyMenu;

var automated GUIButton ChangePerkButton;
var automated GUIButton SellAllButton;
var automated GUIEditBox SearchEdit;
var automated GUILabel SearchLabel;
var localized string strSellOffperkWeapons, strSellAllWeapons;
var localized string strSellOffperkWeaponsHint, strSellAllWeaponsHint;
var localized string strChangePerk, strCancel;

var ScrnTab_BuyMenu BuyMenuTab;
var ScrnKFTab_Perks PerkTab;
var bool bPlayerHasOffperkWeapons;
var int SearchTicks;

function InitTabs()
{
    BuyMenuTab = ScrnTab_BuyMenu(c_Tabs.AddTab(PanelCaption[0], string(class'ScrnTab_BuyMenu'),, PanelHint[0]));
    PerkTab = ScrnKFTab_Perks(c_Tabs.AddTab(PanelCaption[1], string(class'ScrnKFTab_Perks'),, PanelHint[1]));

    ScrnBuyMenuFilter(BuyMenuFilter).SaleListBox = ScrnBuyMenuSaleList(BuyMenuTab.SaleSelect.List);
    ScrnBuyMenuInvList(BuyMenuTab.InvSelect.List).OnBuyablesLoaded = OnPlayerInventoryLoaded;
}

event Opened(GUIComponent Sender)
{
    super(UT2k4MainPage).Opened(Sender);

    ScrnPlayerController(PlayerOwner()).TraderMenuOpened();
    ActivateShopTab();
	SetTimer(0.05f, true);
}

function KFBuyMenuClosed(optional bool bCanceled)
{
    super(UT2k4MainPage).OnClose(bCanceled);

    ScrnPlayerController(PlayerOwner()).TraderMenuClosed();
}

function Timer()
{
    UpdateHeader();
    UpdateWeightBar();
    if (SearchTicks > 0 && --SearchTicks == 0) {
        ActivateSearch();
    }
}

function OnTabChanged(GUIComponent Sender)
{
    SearchEdit.SetText("");
    SearchEdit.SetVisibility(BuyMenuTab.bVisible);
    SearchLabel.SetVisibility(BuyMenuTab.bVisible);
    BuyMenuFilter.SetVisibility(BuyMenuTab.bVisible);

    SellAllButton.SetVisibility(BuyMenuTab.bVisible);
    ChangePerkButton.Caption = eval(BuyMenuTab.bVisible, strChangePerk, strCancel);
}

function ActivateShopTab()
{
    c_Tabs.ActivateTabByPanel(BuyMenuTab, true);
    ScrnBuyMenuSaleList(BuyMenuTab.SaleSelect.List).SetPerkCategory();
    OnTabChanged(none);
    // for some reason, we cannot focus SearchEdit now, nor on the next tick
    SearchTicks=10;
}

function ActivatePerkTab()
{
    c_Tabs.ActivateTabByPanel(PerkTab, true);
    OnTabChanged(none);
}

function bool ChangePerkClick(GUIComponent Sender)
{
    if (BuyMenuTab.bVisible) {
        ActivatePerkTab();
    }
    else {
        ActivateShopTab();
    }
    return false;
}

function bool SellAllClick(GUIComponent Sender)
{
    ScrnBuyMenuInvList(BuyMenuTab.InvSelect.List).SellAll(bPlayerHasOffperkWeapons);
    return false;
}

function OnPlayerInventoryLoaded(ScrnBuyMenuInvList list)
{
    bPlayerHasOffperkWeapons = list.bHasOffPerkWeapons;
    SellAllButton.Caption = eval(bPlayerHasOffperkWeapons, strSellOffperkWeapons, strSellAllWeapons);
    SellAllButton.SetHint(eval(bPlayerHasOffperkWeapons, strSellOffperkWeaponsHint, strSellAllWeaponsHint));
}

function ActivateSearch()
{
    if (SearchEdit.bVisible) {
        SearchEdit.SetFocus(none);
        SetFocus(SearchEdit);
    }
}

function OnSearchChange(GUIComponent Sender)
{
    local string s;

    s = SearchEdit.GetText();
    ScrnBuyMenuSaleList(BuyMenuTab.SaleSelect.List).QuickSearch(s);
}

function bool OnSearchKey(out byte Key, out byte State, float delta)
{
    // PlayerOwner().ClientMessage("OnSearchKeyType Key="$Key @ "State="$State);
    if (State != 1)
        return false;  // not a key press


    // redirect Fn keys to BuyMenuTab
    if (Key >= 0x70 && Key < 0x7C) {
        if (BuyMenuTab.bVisible) {
            return BuyMenuTab.InternalOnKeyEvent(Key, State, delta);
        }
        return false;
    }

    switch (Key) {
        case 0x08: // IK_Backspace
            if (Controller.CtrlPressed) {
                SearchEdit.SetText("");
                Key = 0;
                return true;
            }
            break;
        case 0x0D: // IK_Enter
            BuyMenuTab.SaleDblClick(none);
            SearchEdit.SetText("");
            return true;
        case 0x26: // IK_Up
            ScrnBuyMenuSaleList(BuyMenuTab.SaleSelect.List).GotoPrevItemInCategory();
            return true;
        case 0x28: // IK_Down
            ScrnBuyMenuSaleList(BuyMenuTab.SaleSelect.List).GotoNextItemInCategory();
            return true;
    }
    return SearchEdit.InternalOnKeyEvent(Key, State, delta);
}

function bool OnSearchKeyType(out byte Key, optional string Unicode)
{
    // PlayerOwner().ClientMessage("OnSearchKeyType Key="$Key @ "Unicode="$Unicode);
    if (Key == 127) {
        return true;  // control characters
    }
    if (Unicode == "`" || Unicode == "~") {
        // ignore console key input
        return true;
    }
    return SearchEdit.InternalOnKeyType(Key, Unicode);
}


defaultproperties
{
    Begin Object Class=GUITabControl Name=PageTabs
        bDockPanels=True
        TabHeight=0.025000
        BackgroundStyleName="TabBackground"
        WinTop=0.078000
        WinLeft=0.005000
        WinWidth=0.990000
        WinHeight=0.025000
        RenderWeight=0.490000
        TabOrder=0
        bTabStop=false
        bAcceptsInput=false
        OnActivate=PageTabs.InternalOnActivate
        OnChange=OnTabChanged
    End Object
    c_Tabs=PageTabs

    Begin Object Class=ScrnKFQuickPerkSelect Name=QS
        WinTop=0.011906
        WinLeft=0.008008
        WinWidth=0.316601
        WinHeight=0.082460
        bTabStop=false
        OnDraw=QS.MyOnDraw
    End Object
    QuickPerkSelect=QS

    Begin Object Class=GUILabel Name=Perk
        TextAlign=TXTA_Left
        TextColor=(B=158,G=176,R=175)
        WinTop=0.005
        WinLeft=0.065
        WinWidth=0.25
        WinHeight=0.05
    End Object
    CurrentPerkLabel=Perk

    Begin Object Class=GUIButton Name=ChangePerkB
        Caption="Change Perk..."
        Hint="Toggle perk selection menu [F9]"
        WinTop=0.055
        WinLeft=0.065
        WinWidth=0.12
        WinHeight=35.000000
        RenderWeight=0.450000
        bTabStop=False
        OnClick=ScrnGuiBuyMenu.ChangePerkClick
    End Object
    ChangePerkButton=ChangePerkB
    strChangePerk="Change Perk..."
    strCancel="Cancel"

    Begin Object Class=GUIButton Name=SellAllB
        Caption="Sell ALL"
        Hint="Sells everything but starting equipment"
        WinTop=0.055
        WinLeft=0.195
        WinWidth=0.12
        WinHeight=35.000000
        RenderWeight=0.450000
        bTabStop=False
        OnClick=ScrnGuiBuyMenu.SellAllClick
    End Object
    SellAllButton=SellAllB
    strSellOffperkWeapons="Sell Off-Perk"
    strSellOffperkWeaponsHint="Sells all off-perk weapons, excluding starting equipment, Machete, and Pipe Bombs [Ctrl+F9]"
    strSellAllWeapons="Sell ALL"
    strSellAllWeaponsHint="Sells everything but starting equipment [Ctrl+Shift+F9]"

    Begin Object Class=GUILabel Name=HBGLL
        bVisible=false
    End Object
    HeaderBG_Left_Label=HBGLL

    Begin Object Class=GUIButton Name=StoreTabB
        bVisible=false
    End Object
    StoreTabButton=StoreTabB

    Begin Object Class=GUIButton Name=PerkTabB
        bVisible=false
    End Object
    PerkTabButton=PerkTabB

    Begin Object class=ScrnBuyMenuFilter Name=ScrnFilter
        WinTop=0.051
        WinLeft=0.67
        WinWidth=0.305
        WinHeight=0.082460
        RenderWeight=0.5
        bTabStop=false
    End Object
    BuyMenuFilter=ScrnFilter

    Begin Object Class=GUILabel Name=SearchL
        Caption="[F3] Search:"
        TextAlign=TXTA_Right
        TextColor=(B=158,G=176,R=175)
        WinTop=0.005
        WinLeft=0.680
        WinWidth=0.10
        WinHeight=0.03
    End Object
    SearchLabel=SearchL

    Begin Object Class=GUIEditBox Name=SearchE
        WinTop=0.005
        WinLeft=0.78
        WinWidth=0.20
        WinHeight=0.03
        TabOrder=0
        bTabStop=true
        FriendlyLabel=SearchL
        OnChange=OnSearchChange
        OnKeyEvent=OnSearchKey
        OnKeyType=OnSearchKeyType
    End Object
    SearchEdit=SearchE
}
