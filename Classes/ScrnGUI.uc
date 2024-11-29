// Generic GUI Helpers
class ScrnGUI extends Object abstract;


static final function bool IsReady(GUIComponent Item)
{
    return Item.bVisible && Item.MenuState != MSAT_Disabled;
}

static final function ButtonEnable(GUIButton Button, bool bEnable)
{
    if (bEnable) {
        Button.EnableMe();
    }
    else {
        Button.DisableMe();
    }
}

static final function bool ButtonClick(GUIButton Button)
{
    if (!IsReady(Button))
        return false;

    return Button.OnClick(Button);
}