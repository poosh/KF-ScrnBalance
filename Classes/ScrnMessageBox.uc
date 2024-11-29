class ScrnMessageBox extends UT2K4GenericMessageBox;

var automated GUIButton b_Cancel;

delegate onMsgClose(ScrnMessageBox msg, bool bCancel);

static function ScrnMessageBox ShowMessage(ScrnPlayerController PC, string Title, string Message)
{
    local GUIController guictrl;

    if (PC == none || PC.Player == none)
        return none;

    guictrl = GUIController(PC.Player.GUIController);
    if (guictrl == none)
        return none;

    guictrl.OpenMenu(string(default.class), Title, Message);
    return ScrnMessageBox(guictrl.FindMenuByClass(default.class));
}

function Close(bool bCancel)
{
    onMsgClose(self, bCancel);
    Controller.CloseMenu(bCancel);
}

function bool InternalOnClick(GUIComponent Sender)
{
    switch (Sender) {
        case b_OK:
            Close(false);
            return true;
        case b_Cancel:
            Close(true);
            return true;
    }
    return false;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if (State != 1)
        return false;

    switch (Key) {
        case 0x0D:  // IK_Enter
            class'ScrnGUI'.static.ButtonClick(b_OK);
            return true;

        case 0x1B:  // IK_Escape
            class'ScrnGUI'.static.ButtonClick(b_Cancel);
            return true;
    }
    return false;
}

defaultproperties
{
    Begin Object Class=GUIButton Name=CancelButton
        Caption="Cancel"
        WinTop=0.549479
        WinLeft=0.1
        WinWidth=0.20
        bVisible=false
        OnClick=InternalOnClick
        OnKeyEvent=CancelButton.InternalOnKeyEvent
    End Object
    b_Cancel=CancelButton
}
