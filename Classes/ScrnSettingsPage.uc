class ScrnSettingsPage extends KFSettingsPage;

var int ControlsTabIndex;

function GotoScrnSettings()
{
    local ScrnTab_Controls tabControls;

    tabControls = ScrnTab_Controls(c_Tabs.TabStack[ControlsTabIndex].myPanel);
    if (tabControls == none)
        return;

    c_Tabs.ActivateTab(c_Tabs.TabStack[ControlsTabIndex], true);
    tabControls.SelectScrnKeyBindings();
}


defaultproperties
{
    ControlsTabIndex = 3;
    PanelClass(3)="ScrnBalanceSrv.ScrnTab_Controls"
}