class ScrnKFTab_Perks extends SRKFTab_Perks;

function ShowPanel(bool bShow)
{
    super.ShowPanel(bShow);

    if (bShow) {
        // For some reason, the perk list cannot receive focus on panel show, so we have to delay it.
        SetTimer(0.1, false);
    }
    else {
        SetTimer(0, false);
    }
}

function Timer()
{
    FocusFirst(none);
}

function bool OnSaveButtonClicked(GUIComponent Sender)
{
    local ClientPerkRepLink L;

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
    if ( L!=None && lb_PerkSelect.GetIndex()>=0 ) {
        ScrnPlayerController(PlayerOwner()).SelectVeterancy(L.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
    }
    return OnDoneClick(Sender);
}

function bool OnDoneClick(GUIComponent Sender)
{
    ScrnGUIBuyMenu(OwnerPage()).ActivateShopTab();
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

function bool PerkListKeyEvent(out byte Key, out byte State, float delta)
{
    if (State != 1 )
        return false;  // not a key press

    switch (Key) {
        case 0x0D: // IK_Enter
            OnSaveButtonClicked(none);
            return true;
    }
    return false;
}

function bool MyKeyEvent(out byte Key, out byte State, float delta)
{
    if (State != 1 )
        return false;  // not a key press

    switch (Key) {
        case 0x1B: // IK_Escape
        case 0x75: // IK_F6
            OnDoneClick(none);
            return true;
    }
    return false;
}


defaultproperties
{
    OnKeyEvent=MyKeyEvent
    bAcceptsInput=false

    Begin Object Class=ScrnPerkSelectListBox Name=PerkSelectList
        OnCreateComponent=PerkSelectList.InternalOnCreateComponent
        OnKeyEvent=PerkListKeyEvent
        OnDblClick=OnSaveButtonClicked
        WinTop=0.07
        WinLeft=0.029240
        WinWidth=0.437166
        WinHeight=0.742836
        TabOrder=1
        bTabStop=true
    End Object
    lb_PerkSelect=PerkSelectList

    Begin Object Class=GUIScrollTextBox Name=PerkEffectsScroll
        CharDelay=0.002500
        EOLDelay=0.100000
        OnCreateComponent=PerkEffectsScroll.InternalOnCreateComponent
        WinTop=0.07
        WinLeft=0.500554
        WinWidth=0.465143
        WinHeight=0.323477
        TabOrder=2
        bTabStop=false
    End Object
    lb_PerkEffects=GUIScrollTextBox'PerkEffectsScroll'

    Begin Object class=ScrnPerkProgressListBox Name=PerkProgressList
        WinWidth=0.463858
        WinHeight=0.341256
        WinLeft=0.499269
        WinTop=0.476850
        TabOrder=3
        bTabStop=false
    End Object
    lb_PerkProgress=PerkProgressList

    Begin Object Class=GUIButton Name=SaveButton
        Caption="Select Perk"
        Hint="Use Selected Perk"
        WinTop=0.852604
        WinLeft=0.302670
        WinWidth=0.363829
        WinHeight=0.042757
        TabOrder=10
        bBoundToParent=True
        OnClick=OnSaveButtonClicked
        OnKeyEvent=SaveButton.InternalOnKeyEvent
    End Object
    b_Save=GUIButton'SaveButton'

    Begin Object Class=GUIButton Name=Done
        Caption="[ESC] Back to Shop"
        WinTop=0.941472
        WinLeft=0.790508
        WinWidth=0.207213
        WinHeight=0.035000
        TabOrder=20
        OnClick=OnDoneClick
        OnKeyEvent=Cancel.InternalOnKeyEvent
    End Object
    b_Done=GUIButton'Done'
}
