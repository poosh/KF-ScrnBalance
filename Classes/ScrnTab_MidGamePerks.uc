class ScrnTab_MidGamePerks extends SRTab_MidGamePerks;

var ScrnClientPerkRepLink PerkLink;

function ShowPanel(bool bShow)
{
    Super.ShowPanel(bShow);

    if ( bShow ) {
        PerkLink = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
        if ( PerkLink != none ) {
            // Initialize the List
            lb_PerkSelect.List.InitList(None);
            lb_PerkProgress.List.InitList();
        }
    }
}

function OnPerkSelected(GUIComponent Sender)
{
    local byte Idx;

    if ( PerkLink==None || PerkLink.CachePerks.Length==0 )
    {
        if( PerkLink!=None )
            PerkLink.ServerRequestPerks();
        lb_PerkEffects.SetContent(PleaseWaitStr);
    }
    else
    {
        Idx = lb_PerkSelect.GetIndex();
        if( PerkLink.CachePerks[Idx].CurrentLevel==0 )
            lb_PerkEffects.SetContent(PerkLink.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1));
        else if( PerkLink.CachePerks[Idx].CurrentLevel==PerkLink.MaximumLevel )
            lb_PerkEffects.SetContent(PerkLink.CachePerks[Idx].PerkClass.Static.GetVetInfoText(PerkLink.CachePerks[Idx].CurrentLevel-1,1));
        else
            lb_PerkEffects.SetContent(
                PerkLink.CachePerks[Idx].PerkClass.Static.GetVetInfoText(PerkLink.CachePerks[Idx].CurrentLevel-1, 1)
                $ NextInfoStr $ PerkLink.CachePerks[Idx].PerkClass.Static.GetVetInfoText(PerkLink.CachePerks[Idx].CurrentLevel,11));
        lb_PerkProgress.List.PerkChanged(None, Idx);
    }
}

function bool OnSaveButtonClicked(GUIComponent Sender)
{
    if ( PerkLink!=None && lb_PerkSelect.GetIndex()>=0 ) {
        ScrnPlayerController(PlayerOwner()).SelectVeterancy(PerkLink.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
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