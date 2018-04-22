// supports Color Tags. Must be used only along with ScrnBalance mutator!
class ScrnTeamSayMessagePlus extends TeamSayMessagePlus;

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
    local string LocationName;

    if (RelatedPRI_1 == None)
        return;

    Canvas.SetDrawColor(0,255,0);
    Canvas.DrawText(class'ScrnBalance'.default.Mut.ColoredPlayerName(RelatedPRI_1), false);
    Canvas.SetPos( Canvas.CurX, Canvas.CurY - YL );
    LocationName = RelatedPRI_1.GetLocationName();

    if (LocationName != "")
    {
        Canvas.SetDrawColor(0,128,255);
        Canvas.DrawText( "  ("$LocationName$"):", False );
    }
    else
        Canvas.DrawText( ": ", False );
    Canvas.SetPos( Canvas.CurX, Canvas.CurY - YL );
    Canvas.SetDrawColor(0,128,0);
    Canvas.DrawText( MessageString, False );
}

static function string AssembleString(
        HUD myHUD,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1, 
        optional String MessageString
    )
{
    local string LocationName, s, d;
    local color c;

    if (RelatedPRI_1 == None)
        return "";
        
    c = GetConsoleColor(RelatedPRI_1);  
    d = class'ScrnBalance'.static.ColorString("", c.R, c.G, c.B);
    
    s = class'ScrnBalance'.default.Mut.ColoredPlayerName(RelatedPRI_1) $ d; 
    LocationName = RelatedPRI_1.GetLocationName();
    if ( LocationName != "" )
        s $= "  ("$LocationName$"): ";
    else 
        s $= ": ";
        
    return s $ MessageString;
}