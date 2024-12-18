class ScrnTraderGiveDoshPanel extends GUIPanel;

var ScrnTab_BuyMenu BuyMenu;

var localized string strNoDosh;

var automated GUIButton btnTeamShare;
var automated moCheckBox chkAutoOpen;

var automated ScrnTraderPlayerListBox PlayerListBox;

var localized string Title;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local ScrnPlayerController ScrnPC;

    Super.InitComponent(MyController, MyOwner);

    ScrnPC = ScrnPlayerController(PlayerOwner());
    chkAutoOpen.Checked(ScrnPC.bAutoOpenGiveDosh);

    PlayerListBox.List.OnPlayerSelected = GiveDoshTo;
}

function SettingsChange(GUIComponent Sender)
{
    local ScrnPlayerController ScrnPC;

    ScrnPC = ScrnPlayerController(PlayerOwner());
    ScrnPC.bAutoOpenGiveDosh = chkAutoOpen.IsChecked();
    ScrnPC.SaveConfig();
}

function bool GiveDoshClick(GUIComponent Sender)
{
    GiveDoshTo(none);
    return true;
}

function onGiveDoshDialogClose(ScrnMessageBox msg, bool bCancel)
{
    local ScrnPlayerController ScrnPC;
    local ScrnTraderGiveDoshDialog dialog;

    if (bCancel)
        return;

    ScrnPC = ScrnPlayerController(PlayerOwner());
    dialog = ScrnTraderGiveDoshDialog(msg);
    if (dialog == none)
        return;

    if (ScrnPC.GUI_PRI != none) {
        BuyMenu.SetCustomInfoText(Repl(Repl(ScrnPC.ScrnPawn.strDoshTransferToPlayer,
            "%$", string(dialog.Dosh)),
            "%p", class'ScrnF'.static.ColoredPlayerName(ScrnPC.GUI_PRI))
            , true);
    }
    else {
        BuyMenu.SetCustomInfoText(Repl(ScrnPC.ScrnPawn.strDoshTransferToTeam, "%$", string(dialog.Dosh)), true);
    }
}


function GiveDoshTo(PlayerReplicationInfo PRI)
{
    local ScrnTraderGiveDoshDialog dialog;

    if (int(PlayerOwner().PlayerReplicationInfo.Score) <= 0) {
        BuyMenu.SetCustomInfoText(strNoDosh, true);
    }

    dialog = class'ScrnTraderGiveDoshDialog'.static.ShowMe(ScrnPlayerController(PlayerOwner()), PRI);
    if (dialog != none) {
        dialog.onMsgClose = onGiveDoshDialogClose;
    }
}

event SetVisibility(bool bIsVisible)
{
    super.SetVisibility(bIsVisible);

    if (bVisible) {
        EnableMe();
    }
}


defaultproperties
{
    Title="Digital Dosh Transfer"
    strNoDosh="^r$You have no dosh to spare!"

    Begin Object Class=moCheckBox Name=AutoOpen
        CaptionWidth=0.95
        OnCreateComponent=AutoOpen.InternalOnCreateComponent
        bAutoSizeCaption=True
        Caption="Auto Open"
        Hint="Automatically open the DDT window on a teammate's dosh request"
        WinTop=0.05
        WinLeft=0.05
        WinWidth=0.40
        TabOrder=0
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        IniOption="@Internal"
        OnChange=SettingsChange
        RenderWeight=3
        bBoundToParent=True
        bScaleToParent=True
        bVisible=True
    End Object
    chkAutoOpen=AutoOpen

    Begin Object Class=GUIButton Name=TeamShare
        Caption="Team Share..."
        Hint="Transfer dosh to the Team Waller, where anybody can use it"
        WinTop=0.15
        WinLeft=0.05
        WinWidth=0.90
        WinHeight=0.08
        RenderWeight=0.47
        OnClick=GiveDoshClick
        OnKeyEvent=TeamShare.InternalOnKeyEvent
        TabOrder=2
    End Object
    btnTeamShare=TeamShare

    Begin Object Class=ScrnTraderPlayerListBox Name=PlayerBox
        OnCreateComponent=PlayerBox.InternalOnCreateComponent
        WinTop=0.25
        WinLeft=0.05
        WinWidth=0.90
        WinHeight=0.75
       TabOrder=3
    End Object
    PlayerListBox=PlayerBox
}
