class ScrnBuyMenuSaleListBox extends SRBuyMenuSaleListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner) 
{
    DefaultListClass=string(Class'ScrnBuyMenuSaleList');
    //bypass SRBuyMenuSaleListBox here
    Super(KFBuyMenuSaleListBox).InitComponent(MyController,MyOwner);
}

defaultproperties
{
}
