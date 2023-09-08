class ScrnMessageBoxCheck extends UT2K4GenericMessageBox;

var automated moCheckBox ch;

var protected bool wasChecked;

delegate onCheckChange(ScrnMessageBoxCheck msg);
delegate onMsgClose(ScrnMessageBoxCheck msg);

function bool IsChecked()
{
    return ch.IsChecked();
}

function bool IsChanged()
{
    return IsChecked() != wasChecked;
}

static function ScrnMessageBoxCheck ShowMe(ScrnPlayerController PC, string Title, string Message, optional bool bChecked,
        optional string CheckboxCaption)
{
    local ScrnMessageBoxCheck result;
    local GUIController guictrl;

    if (PC == none || PC.Player == none)
        return none;

    guictrl = GUIController(PC.Player.GUIController);
    if (guictrl == none)
        return none;

    guictrl.OpenMenu(string(default.class), Title, Message);
    result = ScrnMessageBoxCheck(guictrl.FindMenuByClass(default.class));
    if (result == none)
        return none;

    result.ch.Checked(bChecked);
    result.wasChecked = bChecked;

    if (CheckboxCaption != "") {
        result.ch.SetCaption(CheckboxCaption);
        result.ch.SetHint(CheckboxCaption);
    }
    return result;
}

function bool InternalOnClick(GUIComponent Sender)
{
    if (IsChanged()) {
        onCheckChange(self);
    }
    onMsgClose(self);
    return super.InternalOnClick(Sender);
}

defaultproperties
{
    Begin Object Class=moCheckBox Name=MyCheckBox
        Caption="Do not show this again"
        Hint="Do not show this message again"
        bFlipped=false
        LabelJustification=TXTA_Right
        ComponentJustification=TXTA_Right
        CaptionWidth=0.90
        bAutoSizeCaption=true
        WinTop=0.555
        WinLeft=0.05
        WinWidth=0.30
        TabOrder=0
        RenderWeight=0.5
        ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
        IniOption="@Internal"
    End Object
    ch=MyCheckBox
}
