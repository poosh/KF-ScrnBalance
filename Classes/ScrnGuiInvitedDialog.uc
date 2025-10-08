class ScrnGuiInvitedDialog extends ScrnMessageBox;

var localized string strTitle, strText;

static function ScrnGuiInvitedDialog ShowMe(ScrnPlayerController PC)
{
    // Weird things happen when we display dialogue without any menu opened.
    PC.ShowMenu();
    return ScrnGuiInvitedDialog(ShowMessage(PC, default.strTitle, default.strText));
}

function ApplyChanges()
{
    local ScrnPlayerController ScrnPC;

    ScrnPC = ScrnPlayerController(PlayerOwner());
    ScrnPC.Ready();
    ScrnPC.ShowMenu();
}

defaultproperties
{
    strTitle="^S$INVITATION TO PLAY"
    strText="^G$The team invited you to play. Would you like to join the game?"

    Begin Object Class=GUIButton Name=OkButton
        Caption="^g$JOIN"
        WinTop=0.549479
        WinLeft=0.100000
        WinWidth=0.200000
        bVisible=true
        TabOrder=0
        OnClick=UT2K4GenericMessageBox.InternalOnClick
        OnKeyEvent=OkButton.InternalOnKeyEvent
    End Object
    b_OK=OkButton

    Begin Object Class=GUIButton Name=CancelButton
        Caption="SPECTATE"
        WinTop=0.549479
        WinLeft=0.7
        WinWidth=0.20
        bVisible=true
        TabOrder=1
        OnClick=InternalOnClick
        OnKeyEvent=CancelButton.InternalOnKeyEvent
    End Object
    b_Cancel=CancelButton
}