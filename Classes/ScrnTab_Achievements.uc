class ScrnTab_Achievements extends UT2K4TabPanel;

var    automated GUISectionBackground        i_BGAchievements;
var    automated GUIProgressBar            pb_AchievementProgress;
var    automated GUILabel                    l_AchievementProgress;
var    automated ScrnAchievementsListBox    lb_Achievements;

var automated moComboBox                co_Group;
var automated moCheckBox                ch_OnlyLocked;

var bool bNeedRefresh;


var    localized string    OutOfString;
var    localized string    UnlockedString;

var array<name>         GroupNames;
var array<string>       GroupCaptions;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{

    Super.InitComponent(MyController, MyOwner);
        
    LoadGroups();
    LoadStats();    
}

// function ShowPanel(bool bShow)
// {
    // super.ShowPanel(bShow);
// }

function LoadGroups()
{
    local int i;
    GroupNames[0] = ''; // just in case modders will screw up the achievement groups
    GroupCaptions[0] = "ALL";
    class'ScrnBalanceSrv.ScrnAchievements'.static.RetrieveGroups(Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner()), GroupNames, GroupCaptions);
    
    co_Group.ResetComponent();
    for ( i = 0; i < GroupCaptions.length; ++i )
        co_Group.AddItem(GroupCaptions[i]);
}

function InternalOnLoadINI(GUIComponent Sender, string s)
{
    local ScrnPlayerController PC;

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return; // shouldn't happen

    switch (Sender) {
        case co_Group:
            if ( PC.AchGroupIndex < 0 || PC.AchGroupIndex >= GroupNames.Length )
                PC.AchGroupIndex = 0;
            co_Group.SetIndex(PC.AchGroupIndex);  
            break;
    }
}

function InternalOnChange(GUIComponent Sender)
{
    local ScrnPlayerController PC;

    //Super.InternalOnChange(Sender);

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return; // shouldn't happen

    switch (sender) {
        case co_Group:
            if ( PC.AchGroupIndex != co_Group.GetIndex() ) {
                PC.AchGroupIndex = co_Group.GetIndex();
                PC.SaveConfig();
                LoadStats();
            }
            break;
        case ch_OnlyLocked:
            LoadStats();
            break;
    }
}

function LoadStats()
{
    local ScrnPlayerController PC;
    local ClientPerkRepLink L;
    local int CompletedCount, TotalCount;
    local name GroupName;

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return; // shouldn't happen

    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PC);
    if ( L == none ) 
        return;
        
    if ( PC.AchGroupIndex >= 0 && PC.AchGroupIndex < GroupNames.Length )
        GroupName = GroupNames[PC.AchGroupIndex]; 

    // Initialize Achievement Progress
    class'ScrnBalanceSrv.ScrnAchievements'.static.GetGlobalAchievementStats(L, CompletedCount, TotalCount, 
        class'ScrnBalance'.default.Mut.AchievementFlags, GroupName);
    pb_AchievementProgress.Value = CompletedCount;
    pb_AchievementProgress.High = TotalCount;
    l_AchievementProgress.Caption = CompletedCount @ OutOfString @ TotalCount @ UnlockedString;

    // Initialize the List
    lb_Achievements.List.InitList(L, GroupName, ch_OnlyLocked.IsChecked());
}

/*
function ShowPanel(bool bShow)
{

    if ( bShow ) {
        if ( bNeedRefresh )
            LoadStats();
    }
    super.ShowPanel(bShow);
}
*/

defaultproperties
{
     Begin Object Class=GUISectionBackground Name=BGAchievements
         HeaderBase=Texture'KF_InterfaceArt_tex.Menu.Med_border'
         Caption="My Achievements"
         WinTop=0.018000
         WinLeft=0.005000
         WinWidth=0.990000
         WinHeight=0.960000
         OnPreDraw=BGAchievements.InternalPreDraw
     End Object
     i_BGAchievements=GUISectionBackground'ScrnBalanceSrv.ScrnTab_Achievements.BGAchievements'

     Begin Object Class=GUIProgressBar Name=AchievementProgressBar
         BarBack=Texture'KF_InterfaceArt_tex.Menu.Innerborder'
         BarTop=Texture'InterfaceArt_tex.Menu.progress_bar'
         BarColor=(B=255,G=255)
         CaptionWidth=0.000000
         bShowValue=False
         BorderSize=3.000000
         WinTop=0.130000
         WinLeft=0.100000
         WinWidth=0.800000
         WinHeight=0.030000
         RenderWeight=1.200000
     End Object
     pb_AchievementProgress=GUIProgressBar'ScrnBalanceSrv.ScrnTab_Achievements.AchievementProgressBar'

     Begin Object Class=GUILabel Name=AchievementProgressLabel
         Caption="0 of 0 unlocked"
         TextColor=(B=192,G=192,R=192)
         WinTop=0.160000
         WinLeft=0.100000
         WinWidth=0.400000
         WinHeight=0.030000
     End Object
     l_AchievementProgress=GUILabel'ScrnBalanceSrv.ScrnTab_Achievements.AchievementProgressLabel'

     Begin Object Class=ScrnAchievementsListBox Name=AchievementsList
         OnCreateComponent=AchievementsList.InternalOnCreateComponent
         WinTop=0.187382
         WinLeft=0.020000
         WinWidth=0.960000
         WinHeight=0.777808
     End Object
     lb_Achievements=ScrnAchievementsListBox'ScrnBalanceSrv.ScrnTab_Achievements.AchievementsList'

     Begin Object Class=moComboBox Name=GroupCombo
         ComponentJustification=TXTA_Left
         CaptionWidth=0.200000
         Caption="Group"
         OnCreateComponent=GroupCombo.InternalOnCreateComponent
         IniOption="@Internal"
         Hint="Allows to filter achievements in the list"
         WinTop=0.085000
         WinLeft=0.100000
         WinWidth=0.350000
         TabOrder=0
         bBoundToParent=True
         bScaleToParent=True
         OnChange=ScrnTab_Achievements.InternalOnChange
         OnLoadINI=ScrnTab_Achievements.InternalOnLoadINI
     End Object
     co_Group=moComboBox'ScrnBalanceSrv.ScrnTab_Achievements.GroupCombo'


     Begin Object Class=moCheckBox Name=OnlyLockedCheckBox
         CaptionWidth=0.955000
         Caption="Show Only Locked"
         OnCreateComponent=OnlyLockedCheckBox.InternalOnCreateComponent
         IniOption="@Internal"
         ComponentClassName="ScrnBalanceSrv.ScrnGUICheckBoxButton"
         Hint="Shows only locked achievements"
         WinTop=0.085000
         WinLeft=0.700000
         WinWidth=0.200000
         TabOrder=1
         OnChange=ScrnTab_Achievements.InternalOnChange
         OnLoadINI=ScrnTab_Achievements.InternalOnLoadINI
     End Object
     ch_OnlyLocked=moCheckBox'ScrnBalanceSrv.ScrnTab_Achievements.OnlyLockedCheckBox'

     bNeedRefresh=True
     OutOfString="of"
     UnlockedString="unlocked"
     WinTop=0.150000
     WinHeight=0.720000
}
