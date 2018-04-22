class ScrnPerkSelectListBox extends SRPerkSelectListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    DefaultListClass = string(Class'ScrnPerkSelectList');
    Super(KFPerkSelectListBox).InitComponent(MyController,MyOwner);
}

defaultproperties
{
}