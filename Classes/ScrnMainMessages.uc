class ScrnMainMessages extends KFMainMessages
abstract;

var(Message) localized string msgAmmoFull;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
    switch (Switch) {
        case 10: return default.msgAmmoFull;
    }
    return super.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{
    msgAmmoFull="Ammo Full"
}
