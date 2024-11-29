class ScrnTraderPlayerListBox extends GUIListBoxBase;

var ScrnTraderPlayerList List;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController, MyOwner);

    List = ScrnTraderPlayerList(AddComponent(string(class'ScrnTraderPlayerList')));
    InitBaseList(List);
}

defaultproperties
{
    DefaultListClass="ScrnBalanceSrv.ScrnTraderPlayerList"
}