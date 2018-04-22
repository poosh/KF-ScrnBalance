class ScrnGuiBuyMenu extends SRGUIBuyMenu;

function InitTabs() 
{
    local SRKFTab_BuyMenu B;
    
    B = ScrnTab_BuyMenu(c_Tabs.AddTab(PanelCaption[0], string(Class'ScrnBalanceSrv.ScrnTab_BuyMenu'),, PanelHint[0]));
    c_Tabs.AddTab(PanelCaption[1], string(Class'ScrnBalanceSrv.ScrnKFTab_Perks'),, PanelHint[1]);
    
    SRBuyMenuFilter(BuyMenuFilter).SaleListBox = SRBuyMenuSaleList(B.SaleSelect.List);
}

event Opened(GUIComponent Sender)
{
    super.Opened(Sender);
    ScrnPlayerController(PlayerOwner()).TraderMenuOpened();
}

function KFBuyMenuClosed(optional bool bCanceled)
{
    super.KFBuyMenuClosed(bCanceled);
    ScrnPlayerController(PlayerOwner()).TraderMenuClosed();
}

defaultproperties
{
     Begin Object Class=ScrnKFQuickPerkSelect Name=QS
         WinTop=0.011906
         WinLeft=0.008008
         WinWidth=0.316601
         WinHeight=0.082460
         OnDraw=QS.MyOnDraw
     End Object
     QuickPerkSelect=ScrnKFQuickPerkSelect'ScrnBalanceSrv.ScrnGuiBuyMenu.QS'
}
