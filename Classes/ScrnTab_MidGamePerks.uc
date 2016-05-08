class ScrnTab_MidGamePerks extends SRTab_MidGamePerks;

function bool OnSaveButtonClicked(GUIComponent Sender)
{
	local ClientPerkRepLink L;

	L = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
	if ( L!=None && lb_PerkSelect.GetIndex()>=0 ) {
        ScrnPlayerController(PlayerOwner()).SelectVeterancy(L.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
    }
        
	return true;
}

defaultproperties
{
     Begin Object Class=ScrnPerkSelectListBox Name=PerkSelectList
         OnCreateComponent=PerkSelectList.InternalOnCreateComponent
         WinTop=0.057760
         WinLeft=0.029240
         WinWidth=0.437166
         WinHeight=0.742836
     End Object
     lb_PerkSelect=ScrnPerkSelectListBox'ScrnBalanceSrv.ScrnTab_MidGamePerks.PerkSelectList'
}