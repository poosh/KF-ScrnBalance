// Server-side-only rep link to store global data
class ScrnGlobalRepLink extends Info
dependson(ScrnClientPerkRepLink);

var ScrnBalance Mut;
var bool bLoaded;

const WBONUS_WEAPON           = 0x0001;
const WBONUS_DISCOUNT         = 0x0002;
const WBONUS_FIRE0            = 0x0004;
const WBONUS_FIRE1            = 0x0008;
const WBONUS_AMMO0            = 0x0010;
const WBONUS_AMMO1            = 0x0020;
// const WBONUS_UNUSED           = 0x0040;
// const WBONUS_UNUSED           = 0x0080;
const WBONUS_SPECIAL          = 0x0100;
const WBONUS_DT0              = 0x1000;
const WBONUS_DT1              = 0x2000;
const WBONUSES_DEFAULT = 0x00FF;

var array<ScrnClientPerkRepLink.FPerksListType> CachePerks;
var array<ScrnClientPerkRepLink.SWeaponBonus> WeaponBonuses;
var array<ScrnClientPerkRepLink.FShopCategoryIndex> ShopCategories;
var array<ScrnClientPerkRepLink.FShopItemIndex> ShopInventory;
var array<ScrnClientPerkRepLink.SPickupLock> Locks;
var array< class<KFMonster> > Zeds;
var array<string> CustomChars;
var array<ScrnHUD.SmileyMessageType> SmileyTags;

function LoadDefaults(ScrnClientPerkRepLink R)
{
    CachePerks = R.CachePerks;
    ShopCategories = R.ShopCategories;
    ShopInventory = R.ShopInventory;
    Zeds = R.Zeds;
    CustomChars = R.CustomChars;
    SmileyTags = R.SmileyTags;

    // WeaponBonuses and Locks are not loaded from the ClientPerkRepLink.
    // ScrnBalance loads them directly into this class

    bLoaded = true;
}

function SetupRepLink(ScrnClientPerkRepLink R)
{
    R.CachePerks = CachePerks;
    R.ShopCategories = ShopCategories;
    R.ShopInventory = ShopInventory;
    R.Zeds = Zeds;
    R.CustomChars = CustomChars;
    R.SmileyTags = SmileyTags;

    R.WeaponBonuses = WeaponBonuses;
    R.Locks = Locks;
}

static function AddWeaponBonuses(class<ScrnVeterancyTypes> Perk, class <KFWeapon> Weapon, int BonusMask)
{
    local class<KFWeaponPickup> WP;
    local int ForcePrice;

    if (Perk == none || Weapon == none)
        return;

    ForcePrice = BonusMask >>> 16;
    WP = class<KFWeaponPickup>(Weapon.default.PickupClass);

    if ((BonusMask & WBONUS_WEAPON) != 0)
        Perk.static.ClassAddToArrayUnique(Perk.default.PerkedWeapons, Weapon);
    if ((BonusMask & WBONUS_SPECIAL) != 0)
        Perk.static.ClassAddToArrayUnique(Perk.default.SpecialWeapons, Weapon);
    if ((BonusMask & WBONUS_DISCOUNT) != 0)
        Perk.static.ClassAddToArrayUnique(Perk.default.PerkedPickups, Weapon.default.PickupClass);

    if (ForcePrice > 0 && WP != none)
        WP.default.Cost = ForcePrice;

    AddWeaponFireBonuses(Perk, Weapon, Weapon.default.FireModeClass[0], (BonusMask & WBONUS_FIRE0) != 0,
            (BonusMask & WBONUS_AMMO0) != 0, (BonusMask & WBONUS_DT0) != 0);
    AddWeaponFireBonuses(Perk, Weapon, Weapon.default.FireModeClass[1], (BonusMask & WBONUS_FIRE1) != 0,
            (BonusMask & WBONUS_AMMO1) != 0, (BonusMask & WBONUS_DT1) != 0);

    Log("Load weapon " $ String(Weapon) $ " for " $ String(Perk) $ " BonusMask=" $BonusMask , 'ScrnBalance');
}

static function AddWeaponFireBonuses(class <ScrnVeterancyTypes> Perk, class <KFWeapon> Weapon,
        class <WeaponFire> WF, bool bDamage, bool bAmmo, bool bOverrideDamType)
{
    local class<KFWeaponDamageType> DT;

    if (WF == none || WF == class'NoFire')
        return;

    if (bAmmo) {
        Perk.static.ClassAddToArrayUnique(Perk.default.PerkedAmmo, WF.default.AmmoClass);
    }

    if (bOverrideDamType && Perk.default.DefaultDamageType != none) {
        //replace weapon perk index
        class<KFWeaponPickup>(Weapon.default.PickupClass).default.CorrespondingPerkIndex = Perk.default.PerkIndex;

        if (bDamage || Perk.default.DefaultDamageTypeNoBonus == none)
            DT = Perk.default.DefaultDamageType;
        else
            DT = Perk.default.DefaultDamageTypeNoBonus;

        //overriding damage types to allow leveling up
        if (WF.default.ProjectileClass != none)
            WF.default.ProjectileClass.default.MyDamageType = DT;
        if (class<InstantFire>(WF) != none)
            class<InstantFire>(WF).default.DamageType = DT;
    }
    else if (bDamage) {
        if (WF.default.ProjectileClass != none)
            Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes,
                    WF.default.ProjectileClass.default.MyDamageType);
        if (class<InstantFire>(WF) != none)
            Perk.static.ClassAddToArrayUnique(Perk.default.PerkedDamTypes, class<InstantFire>(WF).default.DamageType);
    }
}


defaultproperties
{
}
