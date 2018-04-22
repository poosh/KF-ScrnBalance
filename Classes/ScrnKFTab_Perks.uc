class ScrnKFTab_Perks extends SRKFTab_Perks;

function bool OnSaveButtonClicked(GUIComponent Sender)
{
    local ClientPerkRepLink L;

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
    if ( L!=None && lb_PerkSelect.GetIndex()>=0 ) {
        ScrnPlayerController(PlayerOwner()).SelectVeterancy(L.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
    }

    return true;
}

function OnPerkSelected(GUIComponent Sender)
{
    local ClientPerkRepLink ST;
    local byte Idx;
    local string S;

    ST = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    if ( ST==None || ST.CachePerks.Length==0 )
    {
        if( ST!=None )
            ST.ServerRequestPerks();
        lb_PerkEffects.SetContent("Please wait while your client is loading the perks...");
    }
    else
    {
        Idx = lb_PerkSelect.GetIndex();
        if( ST.CachePerks[Idx].CurrentLevel==0 )
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1);
        else if( ST.CachePerks[Idx].CurrentLevel==ST.MaximumLevel )
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1);
        else
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1)
                    $ Class'SRTab_MidGamePerks'.Default.NextInfoStr
                    $ ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel,11);
        lb_PerkEffects.SetContent(S);
        lb_PerkProgress.List.PerkChanged(KFStatsAndAchievements, Idx);
    }
}

defaultproperties
{
     Begin Object Class=ScrnPerkSelectListBox Name=PerkSelectList
         OnCreateComponent=PerkSelectList.InternalOnCreateComponent
         WinTop=0.091627
         WinLeft=0.029240
         WinWidth=0.437166
         WinHeight=0.742836
     End Object
     lb_PerkSelect=ScrnPerkSelectListBox'ScrnBalanceSrv.ScrnKFTab_Perks.PerkSelectList'
}