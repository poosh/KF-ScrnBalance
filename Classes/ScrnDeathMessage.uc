// Extended to strip color tags  -- PooSH
// Must be used only along with ScrnBalance mutator!


//
// A Death Message.
//
// Switch 0: Kill
//    RelatedPRI_1 is the Killer.
//    RelatedPRI_2 is the Victim.
//    OptionalObject is the DamageType Class.
//

class ScrnDeathMessage extends xDeathMessage
    config(user);


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local string KillerName, VictimName;
    local color c;

    if (Class<DamageType>(OptionalObject) == None)
        return "";
        
    c = GetConsoleColor(RelatedPRI_1);

    if (RelatedPRI_2 == None)
        VictimName = Default.SomeoneString;
    else
        VictimName = class'ScrnBalance'.default.Mut.StripColorTags(RelatedPRI_2.PlayerName);

    if ( Switch == 1 )
    {
        // suicide
        return class'GameInfo'.Static.ParseKillMessage(
            KillerName,
            VictimName,
            Class<DamageType>(OptionalObject).Static.SuicideMessage(RelatedPRI_2) );
    }

    if (RelatedPRI_1 == None)
        KillerName = Default.SomeoneString;
    else 
        KillerName =  class'ScrnBalance'.default.Mut.StripColorTags(RelatedPRI_1.PlayerName);

    return class'GameInfo'.Static.ParseKillMessage(
        KillerName,
        VictimName,
        Class<DamageType>(OptionalObject).Static.DeathMessage(RelatedPRI_1, RelatedPRI_2) );
}
