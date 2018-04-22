class ScrnAchievementsListBox extends GUIListBoxBase;

var ScrnAchievementsList List;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super.InitComponent(MyController,MyOwner);

    if ( DefaultListClass != "" )
    {
        List = ScrnAchievementsList(AddComponent(DefaultListClass));
        if ( List == none )
        {
            log(Class$".InitComponent - Could not create default list ["$DefaultListClass$"]");
            return;
        }
    }

    if ( List == none )
    {
        Warn("Could not initialize list!");
        return;
    }

    InitBaseList(List);
}

defaultproperties
{
     DefaultListClass="ScrnBalanceSrv.ScrnAchievementsList"
}
