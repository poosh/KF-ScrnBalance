class ScrnPipebombMessage extends CriticalEventPlus;

var Color WarningColor;
var localized string strPipebombCount;

static function string GetString(
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
        )
{
    return repl(repl(default.strPipebombCount, "%c", string(Switch & 0xFF)),
            "%m", string(Switch >> 8));
}

static function color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    if ((Switch & 0xFF) > (Switch >> 8)) {
        return default.WarningColor;
    }
    return default.DrawColor;
}

defaultproperties
{
    strPipebombCount="Armed Pipebombs: %c (%m max)"
    DrawColor=(R=220,G=0,B=0,A=255)
    WarningColor=(R=250,G=160,B=1,A=255)
    FontSize=0
}