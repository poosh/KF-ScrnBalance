class ScrnTab_UserSettings extends UT2K4TabPanel;

var localized string strDisabledByServer, strForcedByServer;
var localized string strLock, strUnlock;


// version
var automated GUIImage                img_ScrnLogo;
var automated GUIImage                img_TourneyLogo;
var automated GUILabel                lbl_Version;
var automated GUILabel                lbl_CR;
var automated GUILabel                lbl_TourneyMember;
var automated GUIButton               b_ScrnGroup;
var automated GUIButton               b_GetPrize;


// weapons
var automated GUISectionBackground    bg_Weapons;
var automated moCheckBox              ch_ManualReload;
var automated moCheckBox              ch_CookNade;
var automated moCheckBox              ch_PrioritizePerkedWeapons;
var automated moCheckBox              ch_PrioritizeBoomstick;

var automated GUIButton               b_GunSkin;
var automated GUIButton               b_WeaponLock;
var automated GUIButton               b_PerkProgress;
var automated GUIButton               b_Accuracy;

var localized string strLockWeapons, strUnlockWeapons;
var localized string strBoundToCook, strBoundToThrow, strCantFindNade;


// HUD & Info
var automated GUISectionBackground    bg_HUD;
var automated moCheckBox              ch_ShowDamages;
var automated moCheckBox              ch_ShowSpeed;
var automated moCheckBox              ch_ShowAchProgress;

var automated moComboBox              cbx_BarStyle;
var automated moSlider                sl_BarScale;
var automated moComboBox              cbx_HudStyle;
var automated moSlider                sl_HudScale;
var automated moSlider                sl_HudAmmoScale;
var automated moSlider                sl_HudY;

var automated moSlider                sl_3DScopeSensScale; //I added this

var array<localized string>           BarStyleItems;
var array<localized string>           HudStyleItems;


var automated GUIButton               b_Status;
var automated GUIButton               b_HL;
var automated GUIButton               b_Zeds;


// PLAYERS
var automated GUISectionBackground    bg_Players;
var automated moComboBox              cbx_Player;
var automated GUILabel                lbl_PlayerID;
var automated GUIButton               b_Profile;
var automated GUIButton               b_PlayerList;

var automated moEditBox               txt_Reason;
var automated GUIButton               b_Blame;
var automated GUIButton               b_Spec;
var automated GUIButton               b_Kick;
var automated GUIButton               b_TSC_C;
var automated GUIButton               b_TSC_A;
var automated GUIButton               b_Team_Lock;
var automated GUIButton               b_Team_Unlock;
var automated GUIButton               b_Team_Invite;
var automated GUIButton               b_MVOTE_Yes;
var automated GUIButton               b_MVOTE_No;
var automated GUIButton               b_MVOTE_Boring;
var automated GUIButton               b_MVOTE_EndTrade;

var transient int                     PlayerLocalID;
var transient string                  PlayerSteamID64;

var localized  string strBadReason;

// SERVER INFO
var automated GUILabel                lbl_ServerInfo;
var localized string strServerInfoSeparator;
var localized string strPerkRange, strPerkXPLevel, strPerkBonusLevel;
var localized string strSpawnBalance, strWeaponFix, strAltBurnMech, strBeta, strHardcore, strNoPerkChanges;
var color StatusColor[2];

var transient bool bFillPlayerList;


// event ResolutionChanged( int ResX, int ResY )

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;

    Super.InitComponent(MyController, MyOwner);

    /*
    bg_Weapons.ManageComponent(ch_ManualReload);
    bg_Weapons.ManageComponent(ch_CookNade);
    bg_Weapons.ManageComponent(ch_PrioritizePerkedWeapons);
    bg_Weapons.ManageComponent(ch_PrioritizeBoomstick);
    bg_Weapons.ManageComponent(b_GunSkin);
    bg_Weapons.ManageComponent(b_WeaponLock);
    bg_Weapons.ManageComponent(b_PerkProgress);
    bg_Weapons.ManageComponent(b_Accuracy);
    */

    cbx_BarStyle.ResetComponent();
    for ( i=0; i < BarStyleItems.length; ++i )
        cbx_BarStyle.AddItem(BarStyleItems[i]);

    cbx_HudStyle.ResetComponent();
    for ( i=0; i < HudStyleItems.length; ++i )
        cbx_HudStyle.AddItem(HudStyleItems[i]);
}

function ShowPanel(bool bShow)
{
    local ScrnPlayerController PC;
    local ScrnHUD H;
    local ScrnCustomPRI ScrnPRI;
    local bool b;

    log("ShowPanel("$bShow$")", class.name);
    Super.ShowPanel(bShow);

    if ( !bShow ) {
        SetTimer(0, false);
        return;
    }

    log("ShowPanel: Set button visibility", class.name);
    lbl_Version.Caption = class'ScrnBalance'.default.FriendlyName @ class'ScrnBalance'.static.GetVersionStr();
    lbl_CR.Caption = "Copyright (c) 2012-2018 PU Developing IK, Latvia. All Rights Reserved.";
    ServerStatus();

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return;
    H = ScrnHUD(PC.myHUD);
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PC.PlayerReplicationInfo);


    // tourney member
    b = ScrnPRI != none && ScrnPRI.IsTourneyMember();
    img_TourneyLogo.SetVisibility(b);
    lbl_TourneyMember.SetVisibility(b);
    b_GetPrize.SetVisibility(b && !class'ScrnAchievements'.static.IsAchievementUnlocked(
        Class'ScrnClientPerkRepLink'.Static.FindMe(PC), 'TSCT'));

    // v9.11: team locks are available in regular game too
    b_Team_Lock.SetVisibility(true);
    b_Team_Unlock.SetVisibility(false);
    b_Team_Invite.SetVisibility(true);

    // TSC
    b = TSCGameReplicationInfo(PC.GameReplicationInfo) != none;
    b_TSC_C.SetVisibility(b);
    b_TSC_A.SetVisibility(b);

    sl_BarScale.SetVisibility(H.PlayerInfoVersionNumber >= 80);
    sl_HudScale.SetVisibility(H.bCoolHud);
    sl_HudAmmoScale.SetVisibility(H.bCoolHud);
    sl_HudY.SetVisibility(H.bCoolHud);

    sl_BarScale.SetValue(H.PlayerInfoScale);
    sl_HudScale.SetValue(H.CoolHudScale);
    sl_HudAmmoScale.SetValue(H.CoolHudAmmoScale);
    sl_HudY.SetValue(H.CoolHudAmmoOffsetY);


    RefreshInfo();
    bFillPlayerList = true; // fill player list in 1s

    SetTimer(1, true);
    log("ShowPanel: EOF", class.name);
}


function Timer()
{
    RefreshInfo();
    if ( bFillPlayerList && Controller.bCurMenuInitialized )
    {
        FillPlayerList();
    }
}

function RefreshInfo()
{
    local ScrnPlayerController PC;

    log("RefreshInfo", class.name);
    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return;

    if ( PC.Mut.bAllowWeaponLock ) {
        b_WeaponLock.EnableMe();
        b_WeaponLock.Hint = b_WeaponLock.default.Hint ;

        if ( PC.bWeaponsLocked )
            b_WeaponLock.Caption = strUnlockWeapons;
        else
            b_WeaponLock.Caption = strLockWeapons;
    }
    else {
        b_WeaponLock.DisableMe();
        b_WeaponLock.Hint = PC.strLockDisabled;
    }

    if ( KFGameReplicationInfo(PC.GameReplicationInfo) != none ) {
        b_MVOTE_Boring.SetVisibility(KFGameReplicationInfo(PC.GameReplicationInfo).bWaveInProgress);
        b_MVOTE_EndTrade.SetVisibility(!b_MVOTE_Boring.bVisible);
    }
    else {
        b_MVOTE_Boring.Hide();
        b_MVOTE_EndTrade.Hide();
    }

    b_Team_Unlock.SetVisibility(class'ScrnBalance'.default.Mut.bTeamsLocked);
    b_Team_Lock.SetVisibility(!b_Team_Unlock.bVisible);
}

function ServerStatus()
{
    local ScrnBalance m;
    local string s;
    local color cSpawnBalance, cNoPerkChanges;
    local KFPlayerReplicationInfo KFPRI;

    m = class'ScrnBalance'.default.Mut;
    if ( m == none )
        return; // wtf?

    s = m.ColorStringC(strServerInfoSeparator, lbl_ServerInfo.TextColor);
    if ( m.bNoStartCashToss && m.bMedicRewardFromTeam && m.bSpawn0 )
        cSpawnBalance = StatusColor[1];
    else if ( m.bMedicRewardFromTeam ) {
        cSpawnBalance.R = 255;
        cSpawnBalance.G = 106;
    }
    else {
        cSpawnBalance = StatusColor[0];
    }

    if ( !m.bNoPerkChanges )
        cNoPerkChanges = StatusColor[0];
    else if ( !m.bPerkChangeBoss || !m.bPerkChangeDead )
        cNoPerkChanges = StatusColor[1];
    else {
        cNoPerkChanges.R = 255;
        cNoPerkChanges.G = 106;
    }

    lbl_ServerInfo.Caption =
        strPerkRange$"["
            $ class'ScrnHUD'.static.ColoredPerkLevel(m.SrvMinLevel)
            $ m.ColorStringC("..", lbl_ServerInfo.TextColor)
            $ class'ScrnHUD'.static.ColoredPerkLevel(m.SrvMaxLevel)
            $ m.ColorStringC("]", lbl_ServerInfo.TextColor);

    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        lbl_ServerInfo.Caption $= s $ strPerkXPLevel
            $ class'ScrnHUD'.static.ColoredPerkLevel(KFPRI.ClientVeteranSkillLevel);
        if ( class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill) != none)
            lbl_ServerInfo.Caption $= s $ strPerkBonusLevel
                $ class'ScrnHUD'.static.ColoredPerkLevel(
                    class'ScrnVeterancyTypes'.static.GetBonusLevel(KFPRI.ClientVeteranSkillLevel));
    }

    lbl_ServerInfo.Caption $= "|" $ m.ColorStringC(strSpawnBalance, cSpawnBalance)
        $ s $ m.ColorStringC(strWeaponFix, StatusColor[1])
        $ s $ m.ColorStringC(strAltBurnMech, StatusColor[byte(m.bAltBurnMech)])
        $ s $ m.ColorStringC(strBeta, StatusColor[byte(m.bBeta)])
        $ s $ m.ColorStringC(strHardcore, StatusColor[byte(m.bHardcore)])
        $ s $ m.ColorStringC(strNoPerkChanges, cNoPerkChanges);
}

function string GetPlayerName(PlayerReplicationInfo PRI)
{
    if (PRI == none) {
        return "";
    }
    return class'ScrnBalance'.default.Mut.StripColorTags(PRI.PlayerName);
}

function PlayerReplicationInfo FindPRI(string PlayerName)
{
    local int i;
    local GameReplicationInfo GRI;

    PlayerName = class'ScrnBalance'.default.Mut.StripColorTags(PlayerName);
    if ( PlayerName == "" )
        return none;

    GRI = PlayerOwner().GameReplicationInfo;
    if (GRI == none)
        return none;

    for ( i = 0; i < GRI.PRIArray.Length; ++i ) {
        if ( GetPlayerName(GRI.PRIArray[i]) == PlayerName ) {
            return GRI.PRIArray[i];
        }
    }
    return none;
}

function FillPlayerList()
{
    local int i, idx;
    local KFPlayerReplicationInfo KFPRI;
    local int BlueIndex;
    local GameReplicationInfo GRI;
    local array<KFPlayerReplicationInfo> PRIs;
    local string s;
    local string SelectedPlayerName;


    GRI = PlayerOwner().GameReplicationInfo;
    if ( GRI == none )
        return;
    bFillPlayerList = false;

    log("FillPlayerList", class.name);
    // sort list by Red Players -> Blue Players -> Spectators
    for ( i = 0; i < GRI.PRIArray.Length; i++) {
        log("FillPlayerList: Loading PRI: " $(i+1)$"/"$GRI.PRIArray.Length, class.name);
        KFPRI = KFPlayerReplicationInfo(GRI.PRIArray[i]);
        if ( KFPRI == none || KFPRI.PlayerID == 0 )
            continue;
        log("FillPlayerList: PRI["$(i+1)$"] loaded", class.name);
        if ( KFPRI.bOnlySpectator || KFPRI.Team == none ) {
            PRIs[PRIs.length] = KFPRI; // add to the end
            log("FillPlayerList: PRI["$(i+1)$"] added to spectators", class.name);
        }
        else if ( KFPRI.Team.TeamIndex == 0 ) {
            PRIs.insert(0,1);
            PRIs[0] = KFPRI; // add to the beginning
            BlueIndex++;
            log("FillPlayerList: PRI["$(i+1)$"] added to red team", class.name);
        }
        else {
            PRIs.insert(BlueIndex,1);
            PRIs[BlueIndex] = KFPRI; // add to the beginning of blue team
            log("FillPlayerList: PRI["$(i+1)$"] added to blue team", class.name);
        }
    }

    log("FillPlayerList: Clearing Player List", class.name);
    SelectedPlayerName = cbx_Player.GetText();
    cbx_Player.bIgnoreChange = true;
    cbx_Player.ResetComponent();
    idx = -1;
    log("FillPlayerList: FillingPlayer List", class.name);
    for ( i = 0; i < PRIs.Length; i++) {
        s = GetPlayerName(PRIs[i]);
        cbx_Player.AddItem(s);
        if ( s == SelectedPlayerName )
            idx = i;
    }
    cbx_Player.bIgnoreChange = false;

    log("FillPlayerList: Selected index: " $ (idx+1)$"/"$PRIs.Length, class.name);
    cbx_Player.SilentSetIndex(idx);
    log("FillPlayerList: EOF", class.name);
}

function LoadPlayerData(string PlayerName)
{
    local PlayerReplicationInfo PRI;
    local ScrnCustomPRI ScrnPRI;
    local string s;

    log("LoadPlayerData: " $ PlayerName, class.name);
    PlayerLocalID = 0;
    PlayerSteamID64 = "";
    PRI = FindPRI(PlayerName);
    if ( PRI == none ) {
        lbl_PlayerID.Caption = "";
    }
    else {
        PlayerLocalID = PRI.PlayerID;
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);

        s = "ID="$PRI.PlayerID;
        if ( ScrnPRI != none ) {
            PlayerSteamID64 = ScrnPRI.GetSteamID64();
            s $= "  SID64="$ PlayerSteamID64;
        }
        lbl_PlayerID.Caption = s;
        if ( PRI.Team == none || PRI.Team.TeamIndex > 1 )
            lbl_PlayerID.TextColor = lbl_ServerInfo.TextColor;
        else
            lbl_PlayerID.TextColor = class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex];
    }
    log("LoadPlayerData: EOF", class.name);
}


function InternalOnLoadINI(GUIComponent Sender, string s)
{
    local ScrnPlayerController PC;
    local ScrnHUD H;

    PC = ScrnPlayerController(PlayerOwner());
    H = ScrnHUD(PC.myHUD);

    switch (Sender)
    {
        case ch_ManualReload:
            ch_ManualReload.Checked(PC.bManualReload);
            if ( PC.Mut.bForceManualReload ) {
                ch_ManualReload.DisableMe();
                ch_ManualReload.Hint = strForcedByServer;
            }
            else {
                ch_ManualReload.EnableMe();
                ch_ManualReload.Hint = ch_ManualReload.default.Hint;
            }
            break;

        case ch_CookNade:
            if ( PC.Mut.bReplaceNades ) {
                ch_CookNade.Checked(IsCookingSet());
                ch_CookNade.EnableMe();
                ch_CookNade.Hint = strDisabledByServer;
            }
            else {
                ch_CookNade.Checked(false);
                ch_CookNade.DisableMe();
                ch_CookNade.Hint = ch_CookNade.default.Hint;
            }
            break;

        case ch_PrioritizePerkedWeapons:
            ch_PrioritizePerkedWeapons.Checked(PC.bPrioritizePerkedWeapons);
            break;

        case ch_PrioritizeBoomstick:
            ch_PrioritizeBoomstick.Checked(PC.bPrioritizeBoomstick);
            break;


        case ch_ShowDamages:
            if ( !PC.Mut.bShowDamages || H == none ) {
                ch_ShowDamages.Checked(false);
                ch_ShowDamages.DisableMe();
                ch_ShowDamages.Hint = strDisabledByServer;
            }
            else {
                ch_ShowDamages.Checked(H.bShowDamages);
                ch_ShowDamages.EnableMe();
                ch_ShowDamages.Hint = ch_ShowDamages.default.Hint;
            }
            break;

        case ch_ShowSpeed:
            if ( H == none ) {
                ch_ShowSpeed.Checked(false);
                ch_ShowSpeed.DisableMe();
            }
            else {
                ch_ShowSpeed.Checked(H.bShowSpeed);
                ch_ShowSpeed.EnableMe();
            }
            break;

        case ch_ShowAchProgress:
            ch_ShowAchProgress.Checked(PC.bAlwaysDisplayAchProgression);
            break;

        case cbx_BarStyle:
            if ( H == none ) {
                cbx_BarStyle.SetIndex(0);
                cbx_BarStyle.DisableMe();
            }
            else  {
                if ( H.PlayerInfoVersionNumber < 80 )
                    cbx_BarStyle.SetIndex(0);
                else if ( H.PlayerInfoVersionNumber < 90 )
                    cbx_BarStyle.SetIndex(1);
                else
                    cbx_BarStyle.SetIndex(2);
                cbx_BarStyle.EnableMe();
            }
            break;

        case cbx_HudStyle:
            if ( H == none ) {
                if ( class'ScrnVeterancyTypes'.default.bOldStyleIcons )
                    cbx_HudStyle.SetIndex(0);
                else
                    cbx_HudStyle.SetIndex(1);
                cbx_HudStyle.DisableMe();
            }
            else  {
                cbx_HudStyle.EnableMe();
                if ( H.bCoolHud ) {
                    if ( H.bCoolHudLeftAlign )
                        cbx_HudStyle.SetIndex(3);
                    else
                        cbx_HudStyle.SetIndex(2);
                }
                else if ( class'ScrnVeterancyTypes'.default.bOldStyleIcons )
                    cbx_HudStyle.SetIndex(0);
                else
                    cbx_HudStyle.SetIndex(1);
            }
            break;

        case sl_BarScale:
            if ( H == none ) {
                sl_BarScale.DisableMe();
                sl_BarScale.DisableMe();
            }
            else {
                sl_BarScale.EnableMe();
            }
            break;
        case sl_3DScopeSensScale:
            if ( H == none ) {
                sl_3DScopeSensScale.DisableMe();
                sl_3DScopeSensScale.DisableMe();
            }
            else {
                sl_3DScopeSensScale.EnableMe();
            }
            break;
    }
}



function InternalOnChange(GUIComponent Sender)
{
    local ScrnPlayerController PC;
    local ScrnHUD H;

    PC = ScrnPlayerController(PlayerOwner());
    H = ScrnHUD(PC.myHUD);

    switch (sender)
    {
        case ch_ManualReload:
                PC.bManualReload = ch_ManualReload.IsChecked();
                PC.SaveConfig();
            break;

        case ch_CookNade:
            SetCookNade(ch_CookNade.IsChecked());
            break;

        case ch_PrioritizePerkedWeapons:
                PC.bPrioritizePerkedWeapons =  ch_PrioritizePerkedWeapons.IsChecked();
                PC.SaveConfig();
            break;

        case ch_PrioritizeBoomstick:
                PC.bPrioritizeBoomstick =  ch_PrioritizeBoomstick.IsChecked();
                PC.SaveConfig();
            break;

        case ch_ShowDamages:
                if ( H != none ) {
                    H.bShowDamages = ch_ShowDamages.IsChecked();
                    PC.ServerAcknowledgeDamages(ch_ShowDamages.IsChecked());
                    H.SaveConfig();
                }
            break;

        case ch_ShowSpeed:
                if ( H != none ) {
                    H.bShowSpeed = ch_ShowSpeed.IsChecked();
                    H.SaveConfig();
                }
            break;

        case ch_ShowAchProgress:
                PC.bAlwaysDisplayAchProgression = ch_ShowAchProgress.IsChecked();
                PC.SaveConfig();
            break;


        case cbx_BarStyle:
            switch (cbx_BarStyle.GetIndex()) {
                case 0: PC.ConsoleCommand("PlayerInfoVersion 70"); break;
                case 1: PC.ConsoleCommand("PlayerInfoVersion 83"); break;
                case 2: PC.ConsoleCommand("PlayerInfoVersion 90"); break;
            }
            sl_BarScale.SetVisibility(cbx_BarStyle.GetIndex() > 0);
            PC.myHUD.SaveConfig();
            break;

        case cbx_HudStyle:
            if ( H != none ) {
                switch (cbx_HudStyle.GetIndex()) {
                    case 0:
                        class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = true;
                        H.bCoolHud = false;
                        break;
                    case 1:
                        class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = false;
                        H.bCoolHud = false;
                        break;
                    case 2:
                        class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = false;
                        H.bCoolHud = true;
                        H.bCoolHudLeftAlign = false;
                        break;
                    case 3:
                        class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = false;
                        H.bCoolHud = true;
                        H.bCoolHudLeftAlign = true;
                        break;
                }
                sl_HudScale.SetVisibility(H.bCoolHud);
                sl_HudAmmoScale.SetVisibility(H.bCoolHud);
                sl_HudY.SetVisibility(H.bCoolHud);
                H.SaveConfig();
            }
            break;

        case sl_BarScale:
            if ( H != none ) {
                H.PlayerInfoScale = sl_BarScale.GetValue();
                H.SaveConfig();
            }
            break;


        case sl_HudScale:
            if ( H != none ) {
                H.CoolHudScale = sl_HudScale.GetValue();
                H.SaveConfig();
            }
            break;

        case sl_HudAmmoScale:
            if ( H != none ) {
                H.CoolHudAmmoScale = sl_HudAmmoScale.GetValue();
                H.SaveConfig();
            }
            break;

        case sl_HudY:
            if ( H != none ) {
                H.CoolHudAmmoOffsetY = sl_HudY.GetValue();
                H.SaveConfig();
            }
            break;
            
        case sl_3DScopeSensScale:
                PC.Custom3DScopeSens = sl_3DScopeSensScale.GetValue();
                PC.SaveConfig();
            break;
            
        case cbx_Player:
            LoadPlayerData(cbx_Player.GetText());
            break;
    }
}

function SetCookNade(bool bCook)
{
    local GUIController GC;
    local array<string> BindAliases;
    local array<string> BindKeyNames;
    local array<string> LocalizedBindKeyNames;
    local int i, j;
    local string s, msg;

    GC = GUIController(PlayerOwner().Player.GUIController);

    if (bCook) {
        //retrieve key bindings containing "ThrowGrenade" (command) or "ThrowNade" (alias)
        GC.SearchBinds("ThrowGrenade", BindAliases);
        if ( BindAliases.length == 0 )
            GC.SearchBinds("ThrowNade", BindAliases);
        if ( BindAliases.length == 0 )
            PlayerOwner().ClientMessage(strCantFindNade);
        else {
            for ( i = 0; i < BindAliases.length; i++ ) {
                //get keys that are bound to aliases
                GC.GetAssignedKeys(BindAliases[i], BindKeyNames, LocalizedBindKeyNames);
                //bind keys to cook grenade
                for ( j = 0; j < BindKeyNames.length; j++ ) {
                    s = BindKeyNames[j];
                    GC.SetKeyBind(s, "CookGrenade | ThrowGrenade | OnRelease ThrowCookedGrenade");
                    //inform player what binding has been changed
                    if ( j < LocalizedBindKeyNames.length && LocalizedBindKeyNames[j] != "" )
                        s = LocalizedBindKeyNames[j];
                    msg = strBoundToCook;
                    ReplaceText(msg, "%s", s);
                    PlayerOwner().ClientMessage(msg);
                }
            }
        }
    }
    else {
        GC.SearchBinds("CookGrenade", BindAliases); //retrieve key bindings containing "CookGrenade"
        for ( i = 0; i < BindAliases.length; i++ ) {
            //get keys that are bound to aliases
            GC.GetAssignedKeys(BindAliases[i], BindKeyNames, LocalizedBindKeyNames);
            //bind keys to throw grenade
            for ( j = 0; j < BindKeyNames.length; j++ ) {
                s = BindKeyNames[j];
                GC.SetKeyBind(s, "ThrowGrenade");
                //inform player what binding has been changed
                if ( j < LocalizedBindKeyNames.length && LocalizedBindKeyNames[j] != "" )
                    s = LocalizedBindKeyNames[j];
                msg = strBoundToThrow;
                ReplaceText(msg, "%s", s);
                PlayerOwner().ClientMessage(msg);
            }
        }
    }
}

function bool IsCookingSet()
{
    local array<string> BindAliases;

    GUIController(PlayerOwner().Player.GUIController).SearchBinds("CookGrenade", BindAliases);

    return BindAliases.length > 0;
}



function bool ButtonClicked(GUIComponent Sender)
{
    local ScrnPlayerController PC;

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return true;

    switch ( Sender ) {
        case b_ScrnGroup:
            LaunchURLPage("http://steamcommunity.com/groups/ScrNBalance");
            break;
        case b_GetPrize:
            PC.Mutate("GIMMECOOKIES");
            b_GetPrize.Hide();
            break;

        case b_GunSkin:
            PC.GunSkin(0, true);
            break;
        case b_WeaponLock:
            PC.ToggleWeaponLock();
            RefreshInfo();
            break;
        case b_PerkProgress:
            PC.Mutate("PERKSTATS");
            break;
        case b_Accuracy:
            PC.Mutate("ACCURACY");
            break;

        case b_Status:
            PC.Mutate("STATUS");
            break;
        case b_HL:
            PC.Mutate("HL");
            break;
        case b_Zeds:
            PC.Mutate("ZEDLIST");
            break;

        case b_Profile:
            if ( PlayerSteamID64 != "" )
                LaunchURLPage("http://steamcommunity.com/profiles/"$PlayerSteamID64);
            break;
        case b_MVOTE_Yes:
            PC.Mutate("VOTE YES");
            break;
        case b_MVOTE_No:
            PC.Mutate("VOTE NO");
            break;
        case b_MVOTE_Boring:
            PC.Mutate("VOTE BORING");
            break;
        case b_MVOTE_EndTrade:
            PC.Mutate("VOTE ENDTRADE");
            break;
        case b_Team_Lock:
            PC.Mutate("VOTE LOCKTEAM");
            break;
        case b_Team_Unlock:
            PC.Mutate("VOTE UNLOCKTEAM");
            break;
    }

    return true;
}

function bool PlayerVoteButtonClicked(GUIComponent Sender)
{
    local bool bNeedReason;
    local string cmd;

    if ( PlayerLocalID <= 0 )
        return true;

    switch (Sender) {
        case b_Blame:
            cmd = "BLAME";
            bNeedReason = true;
            break;
        case b_Spec:
            cmd = "SPEC";
            bNeedReason = true;
            break;
        case b_Kick:
            cmd = "KICK";
            bNeedReason = true;
            break;
        case b_TSC_C:
            cmd = "TEAM C";
            break;
        case b_TSC_A:
            cmd = "TEAM A";
            break;
        case b_Team_Invite:
            cmd = "INVITE";
            break;
    }

    cmd = "VOTE" @ cmd @ PlayerLocalID;
    if ( bNeedReason ) {
        if ( !class'ScrnBalanceVoting'.static.IsGoodReason(txt_Reason.GetText()) ) {
            txt_Reason.SetFocus(none);
            PlayerOwner().ClientMessage(strBadReason);
            return true;
        }
        cmd @= txt_Reason.GetText();
    }
    PlayerOwner().Mutate(cmd);
    return true;
}


function LaunchURLPage( string URL )
{
    PlayerOwner().Player.Console.DelayedConsoleCommand("START "$URL);
}


defaultproperties
{
    strDisabledByServer="Disable on the Server side"
    strForcedByServer="Forced by the Server"
    strLock="Lock"
    strUnlock="Unlock"

    // VERSION -------------------------------------------------------------------------
    Begin Object Class=GUIImage Name=LogoStandard
        Image=texture'ScrnTex.HUD.ScrNBalanceLogo256'
        ImageColor=(B=255,G=255,R=255,A=255)
        ImageStyle=ISTY_Scaled
        WinTop=0.005
        WinLeft=0.005
        WinWidth=0.09
        WinHeight=0.16
        bBoundToParent=True
        bScaleToParent=True
        RenderWeight=0.9
    End Object
    img_ScrnLogo=GUIImage'ScrnBalanceSrv.ScrnTab_UserSettings.LogoStandard'

    Begin Object Class=GUILabel Name=VersionLabel
        TextAlign=TXTA_Center
        TextFont="UT2LargeFont"
        FontScale=FNS_Small
        TextColor=(R=160,G=0,B=0)
        ShadowOffsetX=2
        ShadowOffsetY=2
        WinTop=0.01
        WinLeft=0.100000
        WinWidth=0.800000
        WinHeight=0.05
    End Object
    lbl_Version=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.VersionLabel'

    Begin Object Class=GUILabel Name=CRLabel
        Caption=""
        TextFont="UT2SmallFont"
        FontScale=FNS_Small
        TextAlign=TXTA_Center
        TextColor=(R=128,G=128,B=128,A=255)
        WinTop=0.055
        WinLeft=0.100000
        WinWidth=0.800000
        WinHeight=0.05
    End Object
    lbl_CR=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.CRLabel'

    Begin Object Class=GUIButton Name=SteamGroupButton
        Caption="Group..."
        Hint="Opens up ScrN Balance Fans - Official Steam Group in Web Browser (minimizes KF)."
        CaptionAlign=TXTA_Center
        FontScale=FNS_Medium
        WinTop=0.115
        WinLeft=0.10
        WinWidth=0.095
        WinHeight=0.045
        TabOrder=0
        bAutoSize=True
        bAutoShrink=False
        bWrapCaption=False
        bBoundToParent=True
        bScaleToParent=True
        RenderWeight=2.0
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=SteamGroupButton.InternalOnKeyEvent
    End Object
    b_ScrnGroup=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.SteamGroupButton'

    // TSC TOURNEY ---------------------------------------------------------------------
    Begin Object Class=GUIImage Name=LogoTourney
        Image=Texture'ScrnTex.Tourney.TourneyMember'
        ImageColor=(B=255,G=255,R=255,A=255)
        ImageStyle=ISTY_Scaled
        WinTop=0.005
        WinLeft=0.905
        WinWidth=0.09
        WinHeight=0.16
        bBoundToParent=True
        bScaleToParent=True
        RenderWeight=0.9
        bVisible=False
    End Object
    img_TourneyLogo=GUIImage'ScrnBalanceSrv.ScrnTab_UserSettings.LogoTourney'

    Begin Object Class=GUILabel Name=TourneyLabel
        Caption="Congratulations on getting into TSC Tournament Playoffs!"
        TextAlign=TXTA_Center
        TextColor=(R=0,G=255,B=0,A=255)
        ShadowOffsetX=1
        ShadowOffsetY=1
        WinTop=0.115
        WinLeft=0.100000
        WinWidth=0.800000
        WinHeight=0.045
        bVisible=False
    End Object
    lbl_TourneyMember=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.TourneyLabel'

    Begin Object Class=GUIButton Name=PrizeButton
        Caption="Get Prize"
        Hint="Grants xp boost for all ScrN official perks"
        CaptionAlign=TXTA_Center
        FontScale=FNS_Medium
        WinTop=0.115
        WinLeft=0.775
        WinWidth=0.12
        WinHeight=0.045
        TabOrder=1
        bAutoSize=True
        bAutoShrink=False
        bWrapCaption=False
        bVisible=False
        bBoundToParent=True
        bScaleToParent=True
        RenderWeight=2.0
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=PrizeButton.InternalOnKeyEvent
    End Object
    b_GetPrize=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.PrizeButton'


    // WEAPONS -------------------------------------------------------------------------
    Begin Object Class=GUISectionBackground Name=WeaponsBG
        Caption="Weapons"
        WinTop=0.175000
        WinLeft=0.005
        WinWidth=0.49
        WinHeight=0.315
        RenderWeight=0.100100
        OnPreDraw=WeaponsBG.InternalPreDraw
    End Object
    bg_Weapons=GUISectionBackground'ScrnBalanceSrv.ScrnTab_UserSettings.WeaponsBG'

    Begin Object Class=moCheckBox Name=ManualReload
        Caption="Manual Reload"
        Hint="Check this to disable automatic reloading when firing with an empty gun"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.23
        WinLeft=0.015
        WinWidth=0.288
        TabOrder=10
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=ManualReload.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_ManualReload=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ManualReload'

    Begin Object Class=moCheckBox Name=CookNade
        Caption="Enable Grenade 'Cooking'"
        Hint="If checked, armed grenade will remain in your hands while key is being held. Nade cooking slows down toss rate!"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.28
        WinLeft=0.015
        WinWidth=0.288
        TabOrder=11
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=CookNade.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_CookNade=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.CookNade'
    strBoundToCook="'%s' key bound to 'Cook' grenade"
    strBoundToThrow="'%s' key bound to Throw grenade"
    strCantFindNade="Can't find a key set for throwing grenades. Please assign it in Settings->Controls."

    Begin Object Class=moCheckBox Name=PrioritizePerkedWeapons
        Caption="Perked Weapons First"
        Hint="If checked, perked weapons will be switched first in the inventory group"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.33
        WinLeft=0.015
        WinWidth=0.288
        TabOrder=12
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=PrioritizePerkedWeapons.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_PrioritizePerkedWeapons=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.PrioritizePerkedWeapons'

    Begin Object Class=moCheckBox Name=PrioritizeBoomstick
        Caption="Boomstick before AA12"
        Hint="If checked, when pressing '4' Boomstick (Hunting Shotgun) will be switched before AA12"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.38
        WinLeft=0.015
        WinWidth=0.288
        TabOrder=13
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=PrioritizeBoomstick.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_PrioritizeBoomstick=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.PrioritizeBoomstick'


    Begin Object Class=GUIButton Name=GunSkinButton
        Caption="Gun Skin"
        Hint="Toggles current weapon skin: normal / gold / camo / neon. Requires appropriate DLC(-s)."
        bAutoSize=False
        WinTop=0.2275
        WinLeft=0.31
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=14
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_GunSkin=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.GunSkinButton'

    Begin Object Class=GUIButton Name=WeaponLockButton
        Caption="Lock Weapons"
        Hint="Locks/Unlocks dropped weapons, so they can not be picked up by other players"
        bAutoSize=False
        WinTop=0.2775
        WinLeft=0.31
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=15
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_WeaponLock=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.WeaponLockButton'
    strLockWeapons="Lock Weapons"
    strUnlockWeapons="Unlock Weapons"

    Begin Object Class=GUIButton Name=PerkProgressButton
        Caption="Perk Progress"
        Hint="Prints perk progress and gained xp during this game to the console"
        bAutoSize=False
        WinTop=0.3275
        WinLeft=0.31
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=16
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_PerkProgress=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.PerkProgressButton'


    Begin Object Class=GUIButton Name=AccuracyButton
        Caption="Show Accuracy"
        Hint="Prints player accuracy to the console"
        bAutoSize=False
        WinTop=0.3775
        WinLeft=0.31
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        bBoundToParent=True
        bScaleToParent=True
        TabOrder=17
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_Accuracy=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.AccuracyButton'

    Begin Object Class=moSlider Name=Custom3DScopeSens
        MinValue=5
        MaxValue=75
        bIntSlider=True
        LabelJustification=TXTA_Center
        ComponentJustification=TXTA_Left
        CaptionWidth=0 //0
        Caption=""
        LabelColor=(B=255,G=255,R=255)
        Hint="Adjust mouse sensitivity scale when using 3D scopes (Value in FOV, 24 for vanilla behaviour)"
        WinTop=0.43 //0.38 + 0.05
        WinLeft=0.31 //0.31
        WinWidth=0.175 //0.175 //        WinLeft=0.015        WinWidth=0.288
        WinHeight=0.045
        //RenderWeight=1.0
        TabOrder=18
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=Custom3DScopeSens.InternalOnCreateComponent
    End Object
    sl_3DScopeSensScale=moSlider'ScrnBalanceSrv.ScrnTab_UserSettings.Custom3DScopeSens'
    
    // HUD & INFO ----------------------------------------------------------------------
    Begin Object Class=GUISectionBackground Name=HUDBG
        Caption="HUD & Info"
        WinTop=0.175000
        WinLeft=0.505
        WinWidth=0.49
        WinHeight=0.315
        RenderWeight=0.100100
        OnPreDraw=WeaponsBG.InternalPreDraw
    End Object
    bg_HUD=GUISectionBackground'ScrnBalanceSrv.ScrnTab_UserSettings.HUDBG'

    Begin Object Class=moCheckBox Name=ShowDamages
        Caption="Show Damages"
        Hint="If checked, damage you're doing will popup on your screen"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.23
        WinLeft=0.515
        WinWidth=0.288
        TabOrder=20
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=ShowDamages.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_ShowDamages=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowDamages'

    Begin Object Class=moCheckBox Name=ShowSpeed
        Caption="Show Speed"
        Hint="Toggles drawing of your movement speed on the HUD"
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.28
        WinLeft=0.515
        WinWidth=0.288
        TabOrder=21
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        OnCreateComponent=ShowSpeed.InternalOnCreateComponent
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_ShowSpeed=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowSpeed'

    Begin Object Class=moCheckBox Name=ShowAchProgress
        Caption="Achievement Progress"
        Hint="If checked, you will always receive notification message on any achievement progress. If not, game will automatically decide when to show a notification."
        bFlipped=False
        CaptionWidth=0.955000
        WinTop=0.33
        WinLeft=0.515
        WinWidth=0.288
        TabOrder=22
        RenderWeight=0.5
        OnCreateComponent=ShowAchProgress.InternalOnCreateComponent
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        IniOption="@Internal"
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
    End Object
    ch_ShowAchProgress=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowAchProgress'

    Begin Object Class=GUIButton Name=StatusButton
        Caption="Server Status"
        Hint="Prints ScrN server settings"
        bAutoSize=False
        WinTop=0.2275
        WinLeft=0.81
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=23
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_Status=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.StatusButton'

    Begin Object Class=GUIButton Name=HLButton
        Caption="HL"
        Hint="Prints Hardcore Level"
        bAutoSize=False
        WinTop=0.2775
        WinLeft=0.81
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=24
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_HL=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.HLButton'

    Begin Object Class=GUIButton Name=ZedsButton
        Caption="Zeds"
        Hint="Prints current monster collection"
        bAutoSize=False
        WinTop=0.3275
        WinLeft=0.81
        WinWidth=0.175
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=25
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
    End Object
    b_Zeds=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.ZedsButton'

    Begin Object Class=moComboBox Name=BarStyleList
        bReadOnly=True
        CaptionWidth=0
        Caption=""
        IniOption="@Internal"
        Hint="Player Info Bar Style (Beacons above teammates)"
        WinTop=0.38
        WinLeft=0.515
        WinWidth=0.218
        TabOrder=26
        RenderWeight=1.0
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=BarStyleList.InternalOnCreateComponent
    End Object
    cbx_BarStyle=moComboBox'ScrnBalanceSrv.ScrnTab_UserSettings.BarStyleList'
    BarStyleItems(0)="Classic Bars"
    BarStyleItems(1)="Modern Bars"
    BarStyleItems(2)="Cool Bars"

    Begin Object Class=moSlider Name=BarScale
        MinValue=0.5
        MaxValue=2.0
        bIntSlider=false
        LabelJustification=TXTA_Center
        ComponentJustification=TXTA_Left
        CaptionWidth=0
        Caption=""
        LabelColor=(B=255,G=255,R=255)
        Hint="Adjust size of the Player Bars"
        WinTop=0.38
        WinLeft=0.76
        WinWidth=0.10
        TabOrder=27
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=BarScale.InternalOnCreateComponent
    End Object
    sl_BarScale=moSlider'ScrnBalanceSrv.ScrnTab_UserSettings.BarScale'

    Begin Object Class=moComboBox Name=HudStyleList
        bReadOnly=True
        CaptionWidth=0
        Caption=""
        IniOption="@Internal"
        Hint="HUD Style"
        WinTop=0.43
        WinLeft=0.515
        WinWidth=0.218
        TabOrder=29
        RenderWeight=1.0
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=HudStyleList.InternalOnCreateComponent
    End Object
    cbx_HudStyle=moComboBox'ScrnBalanceSrv.ScrnTab_UserSettings.HudStyleList'
    HudStyleItems(0)="Classic HUD, old icons"
    HudStyleItems(1)="Classic HUD, new icons"
    HudStyleItems(2)="Cool HUD (center)"
    HudStyleItems(3)="Cool HUD (left)"

    Begin Object Class=moSlider Name=HudScale
        MinValue=1.5
        MaxValue=3.0
        bIntSlider=False
        LabelJustification=TXTA_Center
        ComponentJustification=TXTA_Left
        CaptionWidth=0
        Caption=""
        LabelColor=(B=255,G=255,R=255)
        Hint="Adjust size of the Cool HUD"
        WinTop=0.43
        WinLeft=0.76
        WinWidth=0.10
        TabOrder=30
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=HudScale.InternalOnCreateComponent
    End Object
    sl_HudScale=moSlider'ScrnBalanceSrv.ScrnTab_UserSettings.HudScale'

    Begin Object Class=moSlider Name=HudAmmoScale
        MinValue=0.25
        MaxValue=1.50
        bIntSlider=False
        LabelJustification=TXTA_Center
        ComponentJustification=TXTA_Left
        CaptionWidth=0
        Caption=""
        LabelColor=(B=255,G=255,R=255)
        Hint="Adjust size of Ammo Counter"
        WinTop=0.415
        WinLeft=0.87
        WinWidth=0.10
        TabOrder=31
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=HudAmmoScale.InternalOnCreateComponent
    End Object
    sl_HudAmmoScale=moSlider'ScrnBalanceSrv.ScrnTab_UserSettings.HudAmmoScale'

    Begin Object Class=moSlider Name=HudY
        MinValue=0.2
        MaxValue=1.0
        bIntSlider=False
        LabelJustification=TXTA_Center
        ComponentJustification=TXTA_Left
        CaptionWidth=0
        Caption=""
        LabelColor=(B=255,G=255,R=255)
        Hint="Adjust vertical position of Ammo Counter"
        WinTop=0.445
        WinLeft=0.87
        WinWidth=0.10
        TabOrder=32
        OnChange=ScrnTab_UserSettings.InternalOnChange
        OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
        OnCreateComponent=HudY.InternalOnCreateComponent
    End Object
    sl_HudY=moSlider'ScrnBalanceSrv.ScrnTab_UserSettings.HudY'

    // MVOTE ---------------------------------------------------------------------------
    Begin Object Class=GUISectionBackground Name=PlayerBG
        Caption="MVote"
        WinTop=0.510
        WinLeft=0.005
        WinWidth=0.99
        WinHeight=0.235
        RenderWeight=0.100100
        OnPreDraw=WeaponsBG.InternalPreDraw
    End Object
    bg_Players=GUISectionBackground'ScrnBalanceSrv.ScrnTab_UserSettings.PlayerBG'

     Begin Object Class=moComboBox Name=PlayerList
         bReadOnly=True
         CaptionWidth=0.18
         Caption="Player:"
         IniOption="@Internal"
         Hint="Select a player from the list"
         WinTop=0.575
         WinLeft=0.015
         WinWidth=0.46
         TabOrder=50
         RenderWeight=1.0
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
         OnCreateComponent=PlayerList.InternalOnCreateComponent
     End Object
     cbx_Player=moComboBox'ScrnBalanceSrv.ScrnTab_UserSettings.PlayerList'

    Begin Object Class=GUILabel Name=PlayerLabel
        Caption=""
        TextFont="UT2SmallFont"
        FontScale=FNS_Small
        TextAlign=TXTA_Left
        TextColor=(R=200,G=200,B=200,A=255)
        WinTop=0.570
        WinLeft=0.49
        WinWidth=0.800000
        WinHeight=0.05
        RenderWeight=0.2
    End Object
    lbl_PlayerID=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.PlayerLabel'

    Begin Object Class=GUIButton Name=ProfileButton
        Caption="Profile..."
        Hint="Opens player's Steam profile in web browser (minimizes KF)"
        bAutoSize=False
        WinTop=0.58
        WinLeft=0.79
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=51
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=ProfileButton.InternalOnKeyEvent
    End Object
    b_Profile=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.ProfileButton'

    Begin Object Class=GUIButton Name=PlayerListButton
        Caption="List"
        Hint="Writes player list into the console and KillingFloor.log"
        bAutoSize=False
        WinTop=0.58
        WinLeft=0.89
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=52
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=PlayerListButton.InternalOnKeyEvent
    End Object
    b_PlayerList=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.PlayerListButton'

    Begin Object Class=moEditBox Name=ReasonTextBox
        ComponentWidth=0.82
        Caption="Reason:"
        OnCreateComponent=ebName.InternalOnCreateComponent
        WinTop=0.63
        WinLeft=0.015
        WinWidth=0.46
        TabOrder=60
    End Object
    txt_Reason=moEditBox'ScrnBalanceSrv.ScrnTab_UserSettings.ReasonTextBox'
    strBadReason="Write a good reason"

    Begin Object Class=GUIButton Name=BlameButton
        Caption="Blame"
        Hint="Click to start a Blame-vote on selected player for a 'Reason'"
        bAutoSize=False
        WinTop=0.63
        WinLeft=0.49
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=61
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=BlameButton.InternalOnKeyEvent
    End Object
    b_Blame=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.BlameButton'

    Begin Object Class=GUIButton Name=SpecButton
        Caption="Spec"
        Hint="Click to start a vote to move selected player to spectators for a 'Reason'."
        bAutoSize=False
        WinTop=0.63
        WinLeft=0.59
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=62
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=SpecButton.InternalOnKeyEvent
    End Object
    b_Spec=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.SpecButton'

    Begin Object Class=GUIButton Name=KickButton
        Caption="Kick"
        Hint="Click to start a kick-vote selected player for a 'Reason'."
        bAutoSize=False
        WinTop=0.63
        WinLeft=0.69
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=63
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=KickButton.InternalOnKeyEvent
    End Object
    b_Kick=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.KickButton'

    Begin Object Class=GUIButton Name=TSC_C_Button
        Caption="Captain"
        Hint="Vote selected player to be a Team Captain"
        bAutoSize=False
        WinTop=0.63
        WinLeft=0.79
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=64
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=TSC_C_Button.InternalOnKeyEvent
    End Object
    b_TSC_C=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.TSC_C_Button'

    Begin Object Class=GUIButton Name=TSC_A_Button
        Caption="Carrier"
        Hint="Vote selected player to be a Gnome Carrier. If voted, nobody but carrier or captain can pick up the Gnome."
        bAutoSize=False
        WinTop=0.63
        WinLeft=0.89
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=65
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=TSC_A_Button.InternalOnKeyEvent
    End Object
    b_TSC_A=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.TSC_A_Button'

    Begin Object Class=GUIButton Name=VoteYesButton
        Caption="Vote YES"
        Hint="Accept current vote in progress"
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.015
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=70
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=VoteYesButton.InternalOnKeyEvent
    End Object
    b_MVOTE_Yes=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.VoteYesButton'

    Begin Object Class=GUIButton Name=VoteNoButton
        Caption="Vote NO"
        Hint="Decline current vote in progress"
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.115
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=71
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=VoteNoButton.InternalOnKeyEvent
    End Object
    b_MVOTE_No=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.VoteNoButton'

    Begin Object Class=GUIButton Name=BoringButton
        Caption="Boring"
        Hint="Boosts zed spawn rates, making game faster."
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.28
        WinWidth=0.195
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=72
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=BoringButton.InternalOnKeyEvent
    End Object
    b_MVOTE_Boring=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.BoringButton'

    Begin Object Class=GUIButton Name=EndTradeButton
        Caption="End Trade"
        Hint="Skips Trader Time and starts next wave."
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.28
        WinWidth=0.195
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=72
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=EndTradeButton.InternalOnKeyEvent
    End Object
    b_MVOTE_EndTrade=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.EndTradeButton'

    Begin Object Class=GUIButton Name=TeamLockButton
        Caption="Lock Team"
        Hint="Locks teams, preventing uninvited players to join."
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.69
        WinWidth=0.195
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=73
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=TeamLockButton.InternalOnKeyEvent
    End Object
    b_Team_Lock=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.TeamLockButton'

    Begin Object Class=GUIButton Name=TeamUnlockButton
        Caption="Unlock Team"
        Hint="Unlocks teams, allowing everybody to join."
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.69
        WinWidth=0.195
        WinHeight=0.045
        RenderWeight=2.0
        TabOrder=73
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.ButtonClicked
        OnKeyEvent=TeamUnlockButton.InternalOnKeyEvent
    End Object
    b_Team_Unlock=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.TeamUnlockButton'

    Begin Object Class=GUIButton Name=TeamInviteButton
        Caption="Invite"
        Hint="Invite player to the team (bypasses lock)."
        bAutoSize=False
        WinTop=0.68
        WinLeft=0.89
        WinWidth=0.095
        WinHeight=0.045
        RenderWeight=1.0
        TabOrder=74
        bBoundToParent=True
        bScaleToParent=True
        bVisible = false
        OnClick=ScrnTab_UserSettings.PlayerVoteButtonClicked
        OnKeyEvent=TeamInviteButton.InternalOnKeyEvent
    End Object
    b_Team_Invite=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.TeamInviteButton'


    // SERVER INFO ---------------------------------------------------------------------
    Begin Object Class=GUILabel Name=ServerInfoLabel
        Caption="Server status unavailable"
        TextAlign=TXTA_Center
        VertAlign=TSTA_Left
        bMultiLine=True
        TextColor=(R=192,G=192,B=192,A=255)
        WinTop=0.755
        WinLeft=0.01
        WinWidth=0.98
        WinHeight=0.24
        bVisible=True
    End Object
    lbl_ServerInfo=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.ServerInfoLabel'
    strServerInfoSeparator = "   "
    strPerkRange="Perk Bonus Range: "
    strPerkXPLevel="Your Perk Level = "
    strPerkBonusLevel="Bonus Level = "
    strSpawnBalance="Money Balance"
    strWeaponFix="Weapon Balance"
    strAltBurnMech="Alt.Burn"
    strBeta="Beta"
    strHardcore="Hardcore"
    strNoPerkChanges="No Perk Changes"
    StatusColor[0]=(R=100,A=255)
    StatusColor[1]=(G=255,A=255)
}
