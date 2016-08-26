class TSCSharedMessages extends CriticalEventPlus;

var(Message) localized string strEnemyShop;
var(Message) localized string strGetBackToBase;


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch) {
        case 1:     return default.strEnemyShop;
        case 211:   return default.strGetBackToBase;
    }
    return "";
}

defaultproperties
{
    DrawColor=(R=255,G=128,B=0,A=255)
    PosX=0.500000
    PosY=0.55
    FontSize=3
    Lifetime=5

    strEnemyShop="Can not trade in enemy shop!"
    strGetBackToBase="GET BACK TO THE BASE OR DIE!"
}
