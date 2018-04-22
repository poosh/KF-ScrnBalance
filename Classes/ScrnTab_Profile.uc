class ScrnTab_Profile extends SRTab_Profile;

var localized string strNotATeamChar;


function bool PickModel(GUIComponent Sender)
{
    if ( Controller.OpenMenu(string(Class'ScrnModelSelect'), PlayerRec.DefaultName, Eval(Controller.CtrlPressed, PlayerRec.Race, "")) )
    {
        Controller.ActivePage.OnClose = ModelSelectClosed;
    }

    return true;
}

function ModelSelectClosed( optional bool bCancelled )
{
    local ScrnPlayerController PC;
    local string str;

    if ( bCancelled )
        return;

    PC = ScrnPlayerController(PlayerOwner());
    str = Controller.ActivePage.GetDataString();
    if ( str != "" ) {
        if ( PC != none && !PC.IsTeamCharacter(str) ) {
            PC.ClientMessage(strNotATeamChar);
            return;
        }
        super.ModelSelectClosed(bCancelled);
    }
}

function OnPerkSelected(GUIComponent Sender)
{
    local ClientPerkRepLink ST;
    local byte Idx;
    local string S;

    ST = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    if ( ST==None || ST.CachePerks.Length==0 )
    {
        if( ST!=None )
            ST.ServerRequestPerks();
        lb_PerkEffects.SetContent("Please wait while your client is loading the perks...");
    }
    else
    {
        Idx = lb_PerkSelect.GetIndex();
        if( ST.CachePerks[Idx].CurrentLevel==0 )
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(0,1);
        else if( ST.CachePerks[Idx].CurrentLevel==ST.MaximumLevel )
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1);
        else
            S = ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel-1,1)
            $ Class'SRTab_MidGamePerks'.Default.NextInfoStr
            $ ST.CachePerks[Idx].PerkClass.Static.GetVetInfoText(ST.CachePerks[Idx].CurrentLevel,11);
        lb_PerkEffects.SetContent(S);
        lb_PerkProgress.List.PerkChanged(KFStatsAndAchievements, Idx);
    }
}


function SaveSettings()
{
    local PlayerController PC;
    local ScrnPlayerController ScrnPC;
    local ClientPerkRepLink L;

    PC = PlayerOwner();
    ScrnPC = ScrnPlayerController(PlayerOwner());
    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PC);

    if ( ChangedCharacter!="" )
    {
        if ( ScrnPC != none && !ScrnPC.IsTeamCharacter(ChangedCharacter) ) {
            ScrnPC.ClientMessage(strNotATeamChar);
        }
        else {
            if ( ScrnPC != none && ScrnPC.PlayerReplicationInfo != none && ScrnPC.PlayerReplicationInfo.Team != none) {
                if ( ScrnPC.PlayerReplicationInfo.Team.TeamIndex == 0 )
                    ScrnPC.RedCharacter = ChangedCharacter;
                else  if ( ScrnPC.PlayerReplicationInfo.Team.TeamIndex == 1 )
                    ScrnPC.BlueCharacter = ChangedCharacter;
                ScrnPC.SaveConfig();
            }

            if( L!=None )
                L.SelectedCharacter(ChangedCharacter);
            else
            {
                PC.ConsoleCommand("ChangeCharacter"@ChangedCharacter);
                if ( !PC.IsA('xPlayer') )
                    PC.UpdateURL("Character", ChangedCharacter, True);

                if ( PlayerRec.Sex ~= "Female" )
                    PC.UpdateURL("Sex", "F", True);
                else PC.UpdateURL("Sex", "M", True);
            }
        }
        ChangedCharacter = "";
    }

    if ( lb_PerkSelect.GetIndex()>=0 && L!=None ) {
        ScrnPC.SelectVeterancy(L.CachePerks[lb_PerkSelect.GetIndex()].PerkClass);
    }
}


defaultproperties
{
    strNotATeamChar="Selected character is not avaliable for your team!"
}