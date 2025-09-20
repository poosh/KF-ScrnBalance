class ScrnMessageBoxCheck extends ScrnMessageBox;

var automated moCheckBox ch;

var protected bool wasChecked;

delegate onCheckChange(ScrnMessageBoxCheck msg);

function bool IsChecked()
{
    return ch.IsChecked();
}

function bool IsChanged()
{
    return IsChecked() != wasChecked;
}

function Close(bool bCancel)
{
    if (!bCancel && IsChanged()) {
        onCheckChange(self);
    }
    super.Close(bCancel);
}


static function ScrnMessageBoxCheck ShowMe(ScrnPlayerController PC, string Title, string Message, optional bool bChecked,
        optional string CheckboxCaption)
{
    local ScrnMessageBoxCheck result;

    result = ScrnMessageBoxCheck(ShowMessage(PC, Title, Message));
    if (result == none)
        return none;

    result.ch.Checked(bChecked);
    result.wasChecked = bChecked;

    if (CheckboxCaption != "") {
        CheckboxCaption = class'ScrnF'.static.ParseColorTags(CheckboxCaption);
        result.ch.SetCaption(CheckboxCaption);
        result.ch.SetHint(CheckboxCaption);
    }
    return result;
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
