class ScrnVetFirebug extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RFlameThrowerDamageStat;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Flamethrower') || ClassIsChildOf(Other, class'HuskGun')
            || ClassIsChildOf(Other, class'MAC10MP') || ClassIsChildOf(Other, class'ScrnThompsonInc')
            || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass)  //v3 - custom weapon support
        )
        return 1.301 + 0.05 * fmin(6, GetClientVeteranSkillLevel(KFPRI));
    return 1.0;
}

// more ammo from ammo boxes
static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
    return AddExtraAmmoFor(KFPRI, Other.class);
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType,  class'FlameAmmo')
            || ClassIsChildOf(AmmoType,  class'MAC10Ammo')
            || ClassIsChildOf(AmmoType,  class'ScrnThompsonIncAmmo')
            || ClassIsChildOf(AmmoType, class'HuskGunAmmo')
            || ClassIsChildOf(AmmoType, class'TrenchgunAmmo')
            || ClassIsChildOf(AmmoType, class'FlareRevolverAmmo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
        ) {
        return 1.301 + 0.05 * GetClientVeteranSkillLevel(KFPRI); // +30% base + 5% more total fuel per each perk level
    }
    else if ( AmmoType == class'FragAmmo' ) {
        return 1.001 + 0.20 * GetClientVeteranSkillLevel(KFPRI)/2; // 1 extra nade per 2 levels
    }
    else if ( GetClientVeteranSkillLevel(KFPRI) > 6 && ClassIsChildOf(AmmoType, class'ScrnM79IncAmmo') ) {
        return 1.001 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI)-6)); //+2 M79Inc nades post level 6
    }
    return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus || class<KFWeaponDamageType>(DmgType) == none )
        return InDamage;

    if ( class<DamTypeBurned>(DmgType) != none || class<DamTypeFlamethrower>(DmgType) != none
        || class<ScrnDamTypeTrenchgun>(DmgType) != none // only for SE version, cuz it has reduced base damage
        || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }

    // +5% husk gun and flare impact damage above level 6
    if ( GetClientVeteranSkillLevel(KFPRI) > 6 && (
            class<DamTypeHuskGunProjectileImpact>(DmgType) != none
            || class<DamTypeFlareProjectileImpact>(DmgType) != none ) )
    {
        InDamage *= 0.70 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }

    return InDamage;
}

// Change effective range on FlameThrower
static function int ExtraRange(KFPlayerReplicationInfo KFPRI)
{
    return 2; // 100% Longer Range
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bDealBurningDamage )
    {
        if ( class'ScrnBalance'.default.Mut.bHardcore )
            return max(1, InDamage * 0.20); // limit fire damage resistance to 80%
        return 0; // no damage from fire
    }
    return InDamage;
}

static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
    return class'ScrnBalanceSrv.ScrnFlameNade'; // Alternate Burning Mechanism
}

//can't cook fire nades
static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    return false;
}

//v2.60: +60% faster charge with Husk Gun
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Flamethrower') || ClassIsChildOf(Other, class'HuskGun')
            || ClassIsChildOf(Other, class'MAC10MP') || ClassIsChildOf(Other, class'ScrnThompsonInc')
            || ClassIsChildOf(Other, class'Trenchgun')
            || ClassIsChildOf(Other, class'FlareRevolver') || ClassIsChildOf(Other, class'DualFlareRevolver')
            || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
        )
        return 1.60;
    return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnMAC10Pickup' )
        return 1.0; // price lowered to $200, no discount needed

    //add discount on class descenders as well, e.g. ScrnHuskGun
    if ( ClassIsChildOf(Item,  class'FlameThrowerPickup')
            || ClassIsChildOf(Item,  class'MAC10Pickup')
            || ClassIsChildOf(Item,  class'ScrnThompsonIncPickup')
            || ClassIsChildOf(Item,  class'HuskGunPickup')
            || ClassIsChildOf(Item,  class'ScrnM79IncPickup')
            || ClassIsChildOf(Item,  class'TrenchgunPickup')
            || ClassIsChildOf(Item,  class'FlareRevolverPickup')
            || ClassIsChildOf(Item,  class'DualFlareRevolverPickup')
            || ClassIsInArray(default.PerkedPickups, Item) ) //v3 - custom weapon support
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

static function class<DamageType> GetMAC10DamageType(KFPlayerReplicationInfo KFPRI)
{
    return class'DamTypeMAC10MPInc';
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%a",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%g",string(Level/2));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'KFMod.DamTypeBurned'
    DefaultDamageTypeNoBonus=Class'KFMod.DamTypeMAC10MPInc'
    SamePerkAch="OP_Firebug"

    SkillInfo="PERK SKILLS:|Immune to fire|100% extra Flamethrower range|60% faster Incendiary Weapon reload/charging|Incendiary Grenades"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x extra burn damage|%a extra fuel|+%g extra grenades|%$ discount on Incendiary Weapons"

    PerkIndex=5
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Firebug'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Firebug_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Firebug"
    Requirements(0)="Deal %x damage with the Flamethrower"
}
