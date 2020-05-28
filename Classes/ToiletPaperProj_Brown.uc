class ToiletPaperProj_Brown extends ToiletPaperProj;

#exec OBJ LOAD FILE=ScrnTex.utx

var localized string strBlame;

function bool PickBy(Pawn Other)
{
    local bool picked;
    local ScrnPlayerController OtherPC;
    local String reason;

    if ( Other == none )
        return false;
    if ( Other != Instigator )
        OtherPC = ScrnPlayerController(Other.Controller);

    picked = super.PickBy(Other);

    if ( picked && OtherPC != none && Level.TimeSeconds - OtherPC.LastBlamedTime > 60.0 ) {
        reason = strBlame;
        ReplaceText(reason, "%o", Instigator.GetHumanReadableName());
        class'ScrnBalance'.static.Myself(Level).BlamePlayer(OtherPC, reason);
    }

    return picked;
}

defaultproperties
{
    Skins[0]=Texture'ScrnTex.Weapons.TP_side_brown'
    Skins[1]=Texture'ScrnTex.Weapons.TP_top_brown'
    strBlame="%p blamed for touching %o's feces"
}
