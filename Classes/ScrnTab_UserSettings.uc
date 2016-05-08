class ScrnTab_UserSettings extends Settings_Tabs;

var automated 	moCheckBox    	ch_ManualReload;
var automated 	moCheckBox    	ch_OtherPlayerLasersBlue;
var automated 	moCheckBox    	ch_CookNade;
var automated 	moCheckBox    	ch_ShowDamages;
var automated 	moCheckBox    	ch_ShowSpeed;
var automated 	moCheckBox    	ch_ShowAchProgress;
var automated 	moCheckBox    	ch_OldStyleIcons;
var automated 	moCheckBox    	ch_PrioritizePerkedWeapons;



var automated GUILabel lbl_Version;
var automated GUILabel lbl_CR;


var automated GUISectionBackground i_BG_Settings;
var automated GUISectionBackground i_BG;

var automated GUIButton b_WeaponLock;
var automated GUIButton b_PerkProgress;

var localized string strBoundToCook, strBoundToThrow, strCantFindNade;
var localized string strDisabledByServer, strForcedByServer;
var localized string strLockWeapons, strUnlockWeapons;

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

function InternalOnChange(GUIComponent Sender)
{
    local ScrnPlayerController PC;

    Super.InternalOnChange(Sender);

    PC = ScrnPlayerController(PlayerOwner());
       
    switch (sender)
    {
    	case ch_ManualReload:
                PC.bManualReload = ch_ManualReload.IsChecked();
                PC.SaveConfig();
			break;

        case ch_OtherPlayerLasersBlue:
                PC.bOtherPlayerLasersBlue = ch_OtherPlayerLasersBlue.IsChecked();
                PC.SaveConfig();
			break;

        case ch_CookNade:
            SetCookNade(ch_CookNade.IsChecked());
            break;
            
        case ch_ShowDamages:
                if ( ScrnHUD(PC.myHUD) != none ) {
                    ScrnHUD(PC.myHUD).bShowDamages = ch_ShowDamages.IsChecked();
                    PC.ServerAcknowledgeDamages(ch_ShowDamages.IsChecked());
                    PC.myHUD.SaveConfig();
                }
			break;    
            
        case ch_ShowSpeed:
                if ( ScrnHUD(PC.myHUD) != none ) {
                    ScrnHUD(PC.myHUD).bShowSpeed = ch_ShowSpeed.IsChecked();
                    PC.myHUD.SaveConfig();
                }
			break;  
            
        case ch_ShowAchProgress:
                if ( ScrnHUD(PC.myHUD) != none ) {
                    PC.bAlwaysDisplayAchProgression = ch_ShowAchProgress.IsChecked();
                    PC.SaveConfig();
                }
			break;            
            
        case ch_OldStyleIcons:
				class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = ch_OldStyleIcons.IsChecked();
                if ( ScrnHUD(PC.myHUD) != none ) {
                    ScrnHUD(PC.myHUD).bOldStyleIcons = class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons;
                    PC.myHUD.SaveConfig();
                }
			break;            
            
        case ch_PrioritizePerkedWeapons:
				PC.bPrioritizePerkedWeapons =  ch_PrioritizePerkedWeapons.IsChecked();
			break;            
    }
}

function InternalOnLoadINI(GUIComponent Sender, string s)
{
    local ScrnPlayerController PC;
    
    PC = ScrnPlayerController(PlayerOwner());

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
            
        case ch_OtherPlayerLasersBlue:
            if ( PC.Mut.bHardcore ) {
                ch_OtherPlayerLasersBlue.Checked(false);
                ch_OtherPlayerLasersBlue.DisableMe();
                ch_OtherPlayerLasersBlue.Hint = strDisabledByServer;
            }
            else {
                ch_OtherPlayerLasersBlue.Checked(PC.bOtherPlayerLasersBlue);
                ch_OtherPlayerLasersBlue.EnableMe();
                ch_OtherPlayerLasersBlue.Hint = ch_OtherPlayerLasersBlue.default.Hint;
            }        
            
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
            
        case ch_ShowDamages:
            if ( !PC.Mut.bShowDamages || ScrnHUD(PC.myHUD) == none ) {
                ch_ShowDamages.Checked(false);
                ch_ShowDamages.DisableMe();
                ch_ShowDamages.Hint = strDisabledByServer;
            }
            else {
                ch_ShowDamages.Checked(ScrnHUD(PC.myHUD).bShowDamages);
                ch_ShowDamages.EnableMe();
                ch_ShowDamages.Hint = ch_ShowDamages.default.Hint;
            }        
            break;            
             
        case ch_ShowSpeed:
            if ( ScrnHUD(PC.myHUD) == none ) {
                ch_ShowSpeed.Checked(false);
                ch_ShowSpeed.DisableMe();
            }
            else {
                ch_ShowSpeed.Checked(ScrnHUD(PC.myHUD).bShowSpeed);
                ch_ShowSpeed.EnableMe();
            }        
            break;               

        case ch_ShowAchProgress:
            ch_ShowAchProgress.Checked(PC.bAlwaysDisplayAchProgression);
            break;               
			
        case ch_OldStyleIcons:
            ch_OldStyleIcons.Checked(class'ScrnVeterancyTypes'.default.bOldStyleIcons);
            break;          
		
		case ch_PrioritizePerkedWeapons:
            ch_PrioritizePerkedWeapons.Checked(PC.bPrioritizePerkedWeapons);
            break;  
    }
}

function ShowPanel(bool bShow)
{
	Super.ShowPanel(bShow);

	if ( bShow ) {
        lbl_Version.Caption = class'ScrnBalance'.default.FriendlyName @ class'ScrnBalance'.static.GetVersionStr();
		RefreshInfo();
	}
}

function RefreshInfo()
{
	local ScrnPlayerController PC;
	
	PC = ScrnPlayerController(PlayerOwner());
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
}

function bool WeaponLockButtonClicked(GUIComponent Sender)
{
	ScrnPlayerController(PlayerOwner()).ToggleWeaponLock();
	RefreshInfo();
	return true;
}

function bool PerkProgressButtonClicked(GUIComponent Sender)
{
	PlayerOwner().Mutate("PERKSTATS");
	return true;
}

defaultproperties
{
     Begin Object Class=moCheckBox Name=ManualReload
         CaptionWidth=0.955000
         Caption="Manual Reload"
         OnCreateComponent=ManualReload.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Check this to disable automatic reloading when firing with an empty gun"
         WinTop=0.200000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=0
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_ManualReload=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ManualReload'

     Begin Object Class=moCheckBox Name=OtherPlayerLasersBlue
         CaptionWidth=0.955000
         Caption="Blue lasers for teammates"
         OnCreateComponent=OtherPlayerLasersBlue.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Draw teammates' lasers in blue color"
         WinTop=0.250000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=1
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_OtherPlayerLasersBlue=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.OtherPlayerLasersBlue'

     Begin Object Class=moCheckBox Name=CookNade
         CaptionWidth=0.955000
         Caption="Enable Grenade 'Cooking'"
         OnCreateComponent=CookNade.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="If checked, armed grenade will remain in player's hands while he is holding the key"
         WinTop=0.300000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=2
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_CookNade=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.CookNade'

     Begin Object Class=moCheckBox Name=ShowDamages
         CaptionWidth=0.955000
         Caption="Show Damages"
         OnCreateComponent=ShowDamages.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="If checked, damage you're doing to zeds will popup on your screen"
         WinTop=0.350000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=3
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_ShowDamages=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowDamages'

     Begin Object Class=moCheckBox Name=ShowSpeed
         CaptionWidth=0.955000
         Caption="Show Speed"
         OnCreateComponent=ShowSpeed.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Shows your current movement speed on the HUD"
         WinTop=0.400000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=4
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_ShowSpeed=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowSpeed'
     
     Begin Object Class=moCheckBox Name=ShowAchProgress
         CaptionWidth=0.955000
         Caption="Always Show Achievement Progress"
         OnCreateComponent=ShowSpeed.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="If checked, you will always receive norification message on any achievement progress. If not, game will automatically decide when to show a notification."
         WinTop=0.450000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=5
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_ShowAchProgress=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.ShowAchProgress'
     
     Begin Object Class=moCheckBox Name=OldStyleIcons
         CaptionWidth=0.955000
         Caption="Old Style Icons"
         OnCreateComponent=ShowSpeed.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Toggles style of perk icons for levels 11+"
         WinTop=0.500000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=6
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_OldStyleIcons=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.OldStyleIcons'
	 
     Begin Object Class=moCheckBox Name=PrioritizePerkedWeapons
         CaptionWidth=0.955000
         Caption="Switch Perked Weapons First"
         OnCreateComponent=ShowSpeed.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="If checked, perked weapons will be switched first in the inventory group"
         WinTop=0.550000
         WinLeft=0.300000
         WinWidth=0.400000
         TabOrder=6
         OnChange=ScrnTab_UserSettings.InternalOnChange
         OnLoadINI=ScrnTab_UserSettings.InternalOnLoadINI
     End Object
     ch_PrioritizePerkedWeapons=moCheckBox'ScrnBalanceSrv.ScrnTab_UserSettings.PrioritizePerkedWeapons'	 

     Begin Object Class=GUILabel Name=VersionLabel
         TextAlign=TXTA_Center
         TextColor=(B=0,G=206)
         WinTop=0.030000
         WinLeft=0.100000
         WinWidth=0.800000
         WinHeight=0.10
     End Object
     lbl_Version=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.VersionLabel'
     
     Begin Object Class=GUILabel Name=CRLabel
         Caption="Copyright (c) 2012-2014 PU Developing IK, All Rights Reserved."
         TextAlign=TXTA_Center
         TextColor=(R=192,G=192,B=192,A=255)
         WinTop=0.950000
         WinLeft=0.100000
         WinWidth=0.800000
         WinHeight=0.05
     End Object
     lbl_CR=GUILabel'ScrnBalanceSrv.ScrnTab_UserSettings.CRLabel'     

     Begin Object Class=GUISectionBackground Name=SettingsBG
         Caption="Settings"
         WinTop=0.150000
         WinLeft=0.250000
         WinWidth=0.500000
         WinHeight=0.450000
         RenderWeight=0.100100
         OnPreDraw=SettingsBG.InternalPreDraw
     End Object
     i_BG_Settings=GUISectionBackground'ScrnBalanceSrv.ScrnTab_UserSettings.SettingsBG'

     Begin Object Class=GUISectionBackground Name=BG
         WinTop=0.015000
         WinLeft=0.250000
         WinWidth=0.500000
         WinHeight=0.110000
         RenderWeight=0.100100
         OnPreDraw=BG.InternalPreDraw
     End Object
     i_BG=GUISectionBackground'ScrnBalanceSrv.ScrnTab_UserSettings.BG'
	 
     Begin Object Class=GUIButton Name=PerkProgressButton
         Caption="Perk Progress"
		 Hint="Outputs perk progress and gained xp during this game to the console"
         bAutoSize=False
         WinTop=0.20
         WinLeft=0.77
         WinWidth=0.21
         WinHeight=0.045
         TabOrder=7
         OnClick=ScrnTab_UserSettings.PerkProgressButtonClicked
         OnKeyEvent=ProfileButton.InternalOnKeyEvent
     End Object
     b_PerkProgress=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.PerkProgressButton'	
	 
     Begin Object Class=GUIButton Name=WeaponLockButton
         Caption="Lock Weapons"
		 Hint="Locks/Unlocks dropped weapons, so they can not be picked up by other players"
         bAutoSize=False
         WinTop=0.25
         WinLeft=0.77
         WinWidth=0.21
         WinHeight=0.045
         TabOrder=8
         OnClick=ScrnTab_UserSettings.WeaponLockButtonClicked
         OnKeyEvent=ProfileButton.InternalOnKeyEvent
     End Object
     b_WeaponLock=GUIButton'ScrnBalanceSrv.ScrnTab_UserSettings.WeaponLockButton'	
	strLockWeapons="Lock Weapons"
	strUnlockWeapons="Unlock Weapons"
	
	
	

     strBoundToCook="'%s' key bound to 'Cook' grenade"
     strBoundToThrow="'%s' key bound to Throw grenade"
     strCantFindNade="Can't find a key set for throwing grenades. Please assign it in Settings->Controls."
     strDisabledByServer="Disable on the Server side"
     strForcedByServer="Forced by the Server"
}
