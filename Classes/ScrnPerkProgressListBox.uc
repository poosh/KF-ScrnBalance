class ScrnPerkProgressListBox extends SRPerkProgressListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(Class'ScrnPerkProgressList');
	Super(KFPerkProgressListBox).InitComponent(MyController,MyOwner);
}

defaultproperties
{
	 DefaultListClass="ScrnBalanceSrv.ScrnPerkProgressList"
}
