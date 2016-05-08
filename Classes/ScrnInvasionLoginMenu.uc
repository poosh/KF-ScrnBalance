class ScrnInvasionLoginMenu extends SRInvasionLoginMenu;

var automated   GUIButton               b_TeamSwitch;

// copy-pasted from SRInvasionLoginMenu to change SRTab_MidGamePerks with ScrnTab_MidGamePerks
function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;
    local string s;
    local eFontScale FS;
	local SRMenuAddition M;

	// Setup panel classes.
	Panels[0].ClassName = string(Class'SRTab_ServerNews');
	Panels[1].ClassName = string(Class'ScrnTab_MidGamePerks');
	Panels[2].ClassName = string(Class'SRTab_MidGameVoiceChat');
	Panels[3].ClassName = string(Class'SRTab_MidGameHelp');
	Panels[4].ClassName = string(Class'SRTab_MidGameStats');

	// Setup localization.
	Panels[1].Caption = Class'KFInvasionLoginMenu'.Default.Panels[1].Caption;
	Panels[2].Caption = Class'KFInvasionLoginMenu'.Default.Panels[2].Caption;
	Panels[3].Caption = Class'KFInvasionLoginMenu'.Default.Panels[3].Caption;
	Panels[1].Hint = Class'KFInvasionLoginMenu'.Default.Panels[1].Hint;
	Panels[2].Hint = Class'KFInvasionLoginMenu'.Default.Panels[2].Hint;
	Panels[3].Hint = Class'KFInvasionLoginMenu'.Default.Panels[3].Hint;
	b_Spec.Caption=class'KFTab_MidGamePerks'.default.b_Spec.Caption;
	b_MatchSetup.Caption=class'KFTab_MidGamePerks'.default.b_MatchSetup.Caption;
	b_KickVote.Caption=class'KFTab_MidGamePerks'.default.b_KickVote.Caption;
	b_MapVote.Caption=class'KFTab_MidGamePerks'.default.b_MapVote.Caption;
	b_Quit.Caption=class'KFTab_MidGamePerks'.default.b_Quit.Caption;
	b_Favs.Caption=class'KFTab_MidGamePerks'.default.b_Favs.Caption;
	b_Favs.Hint=class'KFTab_MidGamePerks'.default.b_Favs.Hint;
	b_Settings.Caption=class'KFTab_MidGamePerks'.default.b_Settings.Caption;
	b_Browser.Caption=class'KFTab_MidGamePerks'.default.b_Browser.Caption;

 	Super(UT2K4PlayerLoginMenu).InitComponent(MyController, MyOwner);

	// Mod menus
	foreach MyController.ViewportOwner.Actor.DynamicActors(class'SRMenuAddition',M)
		if( M.bHasInit )
		{
			AddOnList[AddOnList.Length] = M;
			M.NotifyMenuOpen(Self,MyController);
		}

   	s = GetSizingCaption();

	for ( i = 0; i < Controls.Length; i++ )
    {
    	if ( GUIButton(Controls[i]) != None )
        {
            GUIButton(Controls[i]).bAutoSize = true;
            GUIButton(Controls[i]).SizingCaption = s;
            GUIButton(Controls[i]).AutoSizePadding.HorzPerc = 0.04;
            GUIButton(Controls[i]).AutoSizePadding.VertPerc = 0.5;
        }
    }
    s = class'KFTab_MidGamePerks'.default.PlayerStyleName;
    PlayerStyle = MyController.GetStyle(s, fs);
	InitGRI();
}

function InitGRI()
{
    super.InitGRI();
    
    if ( TSCGameReplicationInfoBase(GetGRI()) != none ) {
        // TSC Mode
        b_TeamSwitch.bVisible = true;
    }
    else {
        b_TeamSwitch.bVisible = false;
    }
}

function bool ButtonClicked(GUIComponent Sender)
{
	switch( Sender ) {
        case b_Profile:
            if (ScrnPlayerController(PlayerOwner()) != none )
                Controller.OpenMenu(ScrnPlayerController(PlayerOwner()).ProfilePageClassString);
            else
                Controller.OpenMenu(string(Class'ScrnProfilePage'));
            break;
            
        case b_TeamSwitch:
            PlayerOwner().SwitchTeam();
            break;
            
        default:
            return super.ButtonClicked(Sender);
	}
}



defaultproperties
{
    Panels(5)=(ClassName="ScrnBalanceSrv.ScrnTab_Achievements",Caption="Achievements",Hint="Achievements")
    Panels(6)=(ClassName="ScrnBalanceSrv.ScrnTab_UserSettings",Caption="ScrN Settings",Hint="ScrN Balance Settings")

    Begin Object Class=GUIButton Name=TeamSwitchButton
        Caption="Switch Team"
        bAutoSize=True
        WinTop=0.870000
        WinLeft=0.725000
        WinWidth=0.200000
        WinHeight=0.050000
        TabOrder=30
        bBoundToParent=True
        bScaleToParent=True
        OnClick=ScrnInvasionLoginMenu.ButtonClicked
        OnKeyEvent=TeamSwitchButton.InternalOnKeyEvent
    End Object
    b_TeamSwitch=GUIButton'ScrnBalanceSrv.ScrnInvasionLoginMenu.TeamSwitchButton'     
}
