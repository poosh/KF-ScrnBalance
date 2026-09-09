class ScrnFunctions extends ScrnF
    abstract;


// TODO: Move to ScrnF on the next ScrnShared update

/**
 * @brief Inserts one array into another.
 * @param dst [out] the array to insert into
 * @param src [in] the array to copy objects from. Must not be the same array as dst.
 *        The src is unchanged; it is marked "out" only to pass by reference.
 * @param pos the position in dst for object insertion. Default 0 - insert objects at the beginning of dst.
 *        Allowed range: [0, dst.Length]
 * @param count the number of objects to insert. Default 0 - insert all src objects.
 *        Clamped to the available number of objects.
 * @param skip the number of objects to skip from the beginning of src. Default 0 - no skip.
 * @return the position in dst right after the last inserted object, so that consecutive
 *         calls can chain insertions. Returns pos unchanged if nothing was inserted.
 */
static final function int ObjArrayInsert(out array<Object> dst, out array<Object> src, optional int pos, optional int count,
        optional int skip)
{
    local int i;

    pos = Clamp(pos, 0, dst.Length);
    if (src.Length == 0)
        return pos;

    if (skip < 0)
        skip = 0;
    if (count == 0 || count + skip > src.Length) {
        count = src.Length - skip;
    }

    if (count <= 0)
        return pos;

    dst.insert(pos, count);
    for (i = 0; i < count; ++i) {
        dst[pos++] = src[i + skip];
    }
    return pos;
}

// MOVE SECTION END

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