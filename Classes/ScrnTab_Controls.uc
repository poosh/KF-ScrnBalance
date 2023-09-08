class ScrnTab_Controls extends KFTab_Controls;

var class<GUIUserKeyBinding> ScrnKeyBindingClass;
var bool bCustomBindingsLoaded;

protected function LoadCustomBindings()
{
    if (bCustomBindingsLoaded)
        return;

    super.LoadCustomBindings();
    FindScrnKeyBindings(true);  // make sure that ScrN Key bindings are loaded
    bCustomBindingsLoaded = true;
}

function ClearBindings()
{
    super.ClearBindings();
    bCustomBindingsLoaded = false;
}

function int FindScrnKeyBindings(optional bool bCreate)
{
    local int i;

    for (i = 0; i < Bindings.Length; ++i) {
        if (Bindings[i].bIsSectionLabel && Bindings[i].KeyLabel == ScrnKeyBindingClass.default.KeyData[0].KeyLabel) {
            return i;
        }
    }
    if (bCreate) {
        log("Add ScrN Key Bindings");
        AddCustomBindings(ScrnKeyBindingClass.default.KeyData);
        MapBindings();
        return FindScrnKeyBindings(false);
    }
    return -1;
}

function bool SelectScrnKeyBindings()
{
    local int i;

    i = FindScrnKeyBindings();
    if (i == -1)
        return false;

    lb_Binds.MyList.SetTopItem(i);
    lb_Binds.MyList.SetIndex(i + 1);
    return true;
}


defaultproperties
{
    ScrnKeyBindingClass=class'ScrnKeyBinding'
}
