class ScrnGuiNetspeedDialog extends ScrnMessageBox;

var localized string strTitle, strText;

static function ScrnGuiNetspeedDialog ShowMe(ScrnPlayerController PC)
{
    // Weird things happen when we display dialogue without any menu opened.
    PC.ShowMenu();
    return ScrnGuiNetspeedDialog(ShowMessage(PC, default.strTitle, repl(repl(default.strText,
            "%c", string(PC.Player.ConfiguredInternetSpeed/1000), true),
            "%s", string(PC.Mut.SrvNetspeed/1000), true)));
}

function ApplyChanges()
{
    local ScrnPlayerController ScrnPC;
    local GUIController guictrl;

    ScrnPC = ScrnPlayerController(PlayerOwner());
    guictrl = GUIController(ScrnPC.Player.GUIController);

    ScrnPC.Player.ConfiguredInternetSpeed = max(ScrnPC.Player.ConfiguredInternetSpeed, ScrnPC.Mut.SrvNetSpeed);
    ScrnPC.Player.ConfiguredLanSpeed = max(ScrnPC.Player.ConfiguredLanSpeed, ScrnPC.Mut.SrvNetSpeed);
    ScrnPC.Player.SaveConfig();

    if (guictrl != none && guictrl.MaxSimultaneousPings == 0) {
        // We need to limit max ping to compensate for the increased netspeed.
        // Otherwise, the Server Browser will hang.
        guictrl.MaxSimultaneousPings = 200;
        guictrl.saveConfig();
    }

    ScrnPC.ConsoleCommand("NETSPEED " $ ScrnPC.Mut.SrvNetSpeed);
}

defaultproperties
{
    strTitle="^r$YOUR NETSPEED IS TOO LOW!"
    strText="^y$The server supports a data rate of up to ^g$%s ^y$kbytes/s, but your netspeed is limited to only ^r$%c ^y$kbytes/s.|Would you like to match the server's netspeed?"

    Begin Object Class=GUIButton Name=OkButton
        Caption="^g$Increase My NetSpeed"
        WinTop=0.55
        WinLeft=0.10
        WinWidth=0.30
        bVisible=true
        TabOrder=0
        OnClick=UT2K4GenericMessageBox.InternalOnClick
        OnKeyEvent=OkButton.InternalOnKeyEvent
    End Object
    b_OK=OkButton

    Begin Object Class=GUIButton Name=CancelButton
        Caption="^r$I'm on Dial-up"
        WinTop=0.55
        WinLeft=0.60
        WinWidth=0.30
        bVisible=true
        TabOrder=1
        OnClick=InternalOnClick
        OnKeyEvent=CancelButton.InternalOnKeyEvent
    End Object
    b_Cancel=CancelButton
}