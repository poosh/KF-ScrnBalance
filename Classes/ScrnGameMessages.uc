class ScrnGameMessages extends CriticalEventPlus;

var(Message) localized string strTeamLocked;
var(Message) localized string strTeamUnlocked;


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch) {
        case 242:    return default.strTeamUnlocked;
        case 243:    return default.strTeamLocked;
    }
    return "";
}


defaultproperties
{
    DrawColor=(R=255,G=0,B=0,A=255)
    PosX=0.500000
    PosY=0.80
    FontSize=3

    strTeamLocked="Teams locked. New players can join only by invite."
    strTeamUnlocked="Teams unlocked. Everybody can join the game."    
}