class TSCSharedMessages extends CriticalEventPlus;

var(Message) localized string strEnemyShop;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch (Switch) {
        case 1:     return default.strEnemyShop;
    }
    return "";
}    

defaultproperties
{
    DrawColor=(R=200,G=64,B=64,A=255)
    PosX=0.500000
    PosY=0.85
    FontSize=3

    strEnemyShop="Can not trade in enemy shop!"
}    
            