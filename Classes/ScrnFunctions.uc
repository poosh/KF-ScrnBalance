class ScrnFunctions extends ScrnF
    abstract;

// TODO: move to ScrnF on the next ScrnShared version update

/**
  * @return true if TestStr contains all Keywords
  * @pre Keywords must not be empty
  */
static function bool MatchKeywords(string TestStr, out array<string> Keywords) {
    local int k;

    for (k = 0; k < Keywords.Length; ++k) {
        if (InStr(TestStr, Keywords[k]) == -1) {
            return false;
        }
    }
    return true;
}

static function bool SearchKeywords(out array<string> Items, out array<string> Keywords, out array<int> MatchIndexes) {
    local int i;

    MatchIndexes.Length = 0;
    if (Items.Length == 0 || Keywords.Length == 0)
        return false;

    for (i = 0; i < Items.Length; ++i) {
        if (MatchKeywords(items[i], Keywords)) {
            MatchIndexes[MatchIndexes.Length] = i;
        }
    }
    return MatchIndexes.Length > 0;
}

static function bool SearchKeywordsStr(out array<string> Items, string KeywordStr, out array<int> MatchIndexes) {
    local array<string> Keywords;

    Split(KeywordStr, " ", Keywords);
    return SearchKeywords(Items, Keywords, MatchIndexes);
}

static function byte GetNumKeyIndex(byte Key) {
    if (Key >= 0x60 && Key <= 0x69) {
        // convert IK_NumPadX to IK_X
        Key -= 0x30;
    }
    if (Key >= 0x30 && Key <= 0x39) {
        // IK_0 .. IK_9
        if (Key == 0x30)
            return 9;
        return Key - 0x31;
    }
    return 255;
}

static final function int SearchObj(out array<Object> arr, Object val)
{
    local int i;

    if (val == none || arr.length == 0)
        return -1;

    for (i = 0; i < arr.length; ++i) {
        if (arr[i] == val)
            return i;
    }
    return -1;
}

static final function bool ObjAddUnique(out array<Object> arr, Object val)
{
    if (val == none)
        return false;

    if (SearchObj(arr, val) != -1)
        return false;

    arr[arr.length] = val;
    return true;
}

// Returns true of float is not a real number (NaN, -INF, or +INF)
static final function bool IsNaN(float f)
{
    return !(f < 0 || f >= 0);
}


static function class<ScrnVeterancyTypes> FindPerkByName(ClientPerkRepLink L, string VeterancyNameOrIndex)
{
    local int i;
    local class<ScrnVeterancyTypes> Perk;
    local string s1, s2;

    if ( L == none )
        return none;

    i = int(VeterancyNameOrIndex);
    if ( i > 0 && i <= L.CachePerks.Length )
        return class<ScrnVeterancyTypes>(L.CachePerks[i-1].PerkClass);
    // log("CachePerks.Length="$L.CachePerks.Length, 'ScrnBalance');
    for ( i = 0; i < L.CachePerks.Length; ++i ) {
        Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
        if ( Perk != none ) {
            // log(GetItemName(String(Perk.class)) @ Perk.default.VeterancyNameOrIndex, 'ScrnBalance');
            if ( Perk.default.ShortName ~= VeterancyNameOrIndex || Perk.default.VeterancyName ~= VeterancyNameOrIndex
                    || (Divide(Perk.default.VeterancyName, " ", s1, s2)
                        && (VeterancyNameOrIndex ~= s1 || VeterancyNameOrIndex ~= s2)) )
                return Perk;
        }
    }
    return none;
}

static function SendPerkList(PlayerController PC)
{
    local ScrnClientPerkRepLink L;
    local class<ScrnVeterancyTypes> Perk;
    local KFPlayerReplicationInfo KFPRI;
    local int i;
    local string s;

    L = class'ScrnClientPerkRepLink'.Static.FindMe(PC);
    if ( L == none )
        return;
    KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if ( KFPRI == none )
        return;

    for ( i = 0; i < L.CachePerks.Length; ++i ) {
        Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
        if ( Perk == none )
            continue;

        if ( Perk.default.bLocked ) {
            s = "^9[LOCKED] ";
        }
        else if (KFPRI.ClientVeteranSkill == Perk) {
            s = "^2*** ";
        }
        else {
            s = "";
        }
        s $= string(i + 1) $ ". " $ Perk.default.ShortName $ " - " $ Perk.default.VeterancyName;
        PC.ClientMessage(s);
    }
}

static function bool AddGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup) {
    local int i;

    if (BasePickup == none || SkinnedPickup == none) {
        return false;
    }

    for (i = 0; i < BasePickup.default.VariantClasses.length; ++i) {
        if (BasePickup.default.VariantClasses[i] == SkinnedPickup) {
            return false;
        }
    }

    BasePickup.default.VariantClasses[i] = SkinnedPickup;
    return true;
}

static function RemoveGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup) {
    local int i;

    if (BasePickup == none) {
        return;
    }

    for (i = 0; i < BasePickup.default.VariantClasses.length; ++i) {
        if (BasePickup.default.VariantClasses[i] == SkinnedPickup) {
            BasePickup.default.VariantClasses.remove(i--, 1);
        }
    }
}


defaultproperties
{

}