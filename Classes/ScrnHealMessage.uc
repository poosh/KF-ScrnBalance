class ScrnHealMessage extends CriticalEventPlus;

var localized string strHeal, strHealedBy;

static function string GetString(
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
        )
{
    local string s;

    switch (Switch) {
        case 0: s = default.strHeal; break;
        case 1: s = default.strHealedBy; break;
    }

    s = repl(s, "%p", class'ScrnF'.static.ColoredPlayerName(RelatedPRI_1));
    return s;
}

defaultproperties
{
    strHeal="You healed %p"
    strHealedBy="Healed by %p"
    DrawColor=(R=0,G=200,B=0,A=255)
    FontSize=0
    Lifetime=5

    DrawPivot=DP_MiddleMiddle
    PosX=0.50
    PosY=0.75
}
