class ScrnUserMapInfo extends ScrnMapInfo
    PerObjectConfig
    Config(ScrnUserMapInfo);

var const string PREFIX;

var config bool bEnabled;

static function ScrnUserMapInfo LoadMap(string MapName)
{
    local ScrnUserMapInfo m;

    m = new(none, default.PREFIX $ MapName) class'ScrnUserMapInfo';
    if (m.bEnabled)
        return m;

    return none;
}


defaultproperties
{
    PREFIX="USER_";
}