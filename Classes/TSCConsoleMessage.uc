class TSCConsoleMessage extends LocalMessage;

var localized string strBaseStunnedByPlayer[2];
var localized string strBaseStunnedBy[2];

static function string GetObjectName(Object obj)
{
    if (obj == none)
        return "";

    if (class<KFMonster>(obj) != none)
        return class<KFMonster>(obj).default.MenuName;
    if (class<WeaponDamageType>(obj) != none)
        return class<WeaponDamageType>(obj).default.WeaponClass.default.ItemName;

    return "";
}

static function string GetString(
    optional int sw,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local byte t;

    if (sw < 200) {
        // per-team messages
        if (sw >= 100) {
            t = 1;
            sw -= 100;
        }

        switch (sw) {
            case   0:   return repl(repl(default.strBaseStunnedByPlayer[t],
                            "%k", class'ScrnF'.static.ColoredPlayerName(RelatedPRI_1), true),
                            "%w", GetObjectName(OptionalObject), true);
            case   1:   return repl(default.strBaseStunnedBy[t],
                            "%k", GetObjectName(OptionalObject), true);
        }
    }

    return "";
}

defaultproperties
{
    bIsConsoleMessage=true
    bIsSpecial=false
    bIsUnique=true
    PosX=0.50
    PosY=0.65
    FontSize=5
    Lifetime=5

    strBaseStunnedByPlayer[0]="^r$British Guardian stunned by ^w$%k ^r$(^y$%w^r$)"
    strBaseStunnedByPlayer[1]="^s$Steampunk Guardian stunned by ^w$%k ^s$(^y$%w^s$)"
    strBaseStunnedBy[0]="^r$British Guardian stunned by ^y$%k"
    strBaseStunnedBy[1]="^s$Steampunk Guardian stunned by ^y$%k"
}