class ScrnBuyMenuInvListBox extends SRKFBuyMenuInvListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    DefaultListClass=String(class'ScrnBalanceSrv.ScrnBuyMenuInvList');
    //bypass SRBuyMenuSaleListBox here
    Super(KFBuyMenuInvListBox).InitComponent(MyController,MyOwner);
}

function GUIBuyable GetSelectedBuyable()
{
    return ScrnBuyMenuInvList(List).GetSelectedBuyable();
}

defaultproperties
{
}
