class ScrnBuyMenuInvListBox extends SRKFBuyMenuInvListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner) 
{
    DefaultListClass=String(class'ScrnBalanceSrv.ScrnBuyMenuInvList');
    //bypass SRBuyMenuSaleListBox here
    Super(KFBuyMenuInvListBox).InitComponent(MyController,MyOwner); 
}

defaultproperties
{
}
