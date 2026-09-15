class ScrnFunctions extends ScrnF
    abstract;


// TODO: Move to ScrnF on the next ScrnShared update

// MOVE SECTION END

static final function class<ScrnVeterancyTypes> FindPerkByName(ClientPerkRepLink L, string VeterancyNameOrIndex)
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

static final function SendPerkList(PlayerController PC)
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

static final function bool AddGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup)
{
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

static final function RemoveGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup)
{
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

// Optimization hint:
// static final functions in UnrealScript are still functions. They are NOT inline, unlike C++.
// While calling a final static function is cheaper than a regular (virtual) function, there is still a significant
// overhead. Don't call this function in a time-critical section. Don't call it on a KFMeleeGun - simply check it
// against Syringe and Welder instead.
// Read Gotchas.md
static final function bool IsMeleeWeapon(Weapon W)
{
    return KFMeleeGun(W) != none && Syringe(W) == none && Welder(W) == none;
}


defaultproperties
{

}