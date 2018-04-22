// supports Color Tags. Must be used only along with ScrnBalance mutator!
class ScrnSayMessagePlus extends SayMessagePlus;

static function RenderComplexMessage(
        Canvas Canvas,
        out float XL,
        out float YL,
        optional string MessageString,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
    )
{
    if (RelatedPRI_1 == None)
        return;
    
    Canvas.SetDrawColor(0,255,0);
    Canvas.DrawText(class'ScrnBalance'.default.Mut.ColoredPlayerName(RelatedPRI_1), false);
    Canvas.SetPos( Canvas.CurX, Canvas.CurY - YL );
    Canvas.SetDrawColor(0,128,0);
    Canvas.DrawText(": " $ MessageString, False );
}

static function string AssembleString(
        HUD myHUD,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional String MessageString
    )
{
    local color c;
    
    if ( RelatedPRI_1 == None || RelatedPRI_1.PlayerName == "" )
        return "";
        
    c = GetConsoleColor(RelatedPRI_1);  
    return class'ScrnBalance'.default.Mut.ColoredPlayerName(RelatedPRI_1)
        $ class'ScrnBalance'.static.ColorString(": ", c.R, c.G, c.B)
        $ MessageString;
}


defaultproperties
{
     RedTeamColor=(B=205,G=237,R=244,A=255)
     BlueTeamColor=(B=205,G=237,R=244,A=255)
     bBeep=True
     Lifetime=6
     DrawColor=(B=205,G=237,R=244)
}
