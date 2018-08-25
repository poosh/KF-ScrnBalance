class ScrnVetDemolitions extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RExplosivesDamageStat;
}


static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo') )
        return 1.0; // no extra medic grenades

    if ( ClassIsChildOf(AmmoType, class'FragAmmo') ) {
        return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI))); // +1 nade per level
    }
    else if ( ClassIsChildOf(AmmoType, class'PipeBombAmmo') ) {
        return 1.0 + (0.5 * float(GetClientVeteranSkillLevel(KFPRI)));  // +1 pipe per level
    }
    else if ( ClassIsChildOf(AmmoType, class'ScrnLAWAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType) //v3 - custom weapon support
            )
    {
        // ScrnLAW has base ammo 16
        // ScrnHRLAmmo has base ammo 20, +2 rockets per perk level
        return 1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)));
    }
    else if ( ClassIsChildOf(AmmoType, class'LAWAmmo') ) {
        // Modified in Balance Round 5 to be up to 100% extra ammo
        return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI)));
    }
    else if ( ClassIsChildOf(AmmoType, class'M203Ammo') ) {
        return 1.0 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI))); //1 extra nade per level [Aze]
    }
    else if ( GetClientVeteranSkillLevel(KFPRI) > 6 ) {
        if ( ClassIsChildOf(AmmoType, class'M79Ammo') || ClassIsChildOf(AmmoType, class'M32Ammo') )
            return 1.0 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI)-6)); //+1 M203 or +2 M79 or +3 M32 nades post level 6
    }

    return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus || class<KFWeaponDamageType>(DmgType) == none )
        return InDamage;

    if ( class<KFWeaponDamageType>(DmgType).default.bIsExplosive || class<DamTypeRocketImpact>(DmgType) != none )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( InDamage == 0 )
        return 0;

    if ( (class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bIsExplosive)
            || class<DamTypeRocketImpact>(DmgType) != none )
        InDamage *= 0.20; // 80% damage resistance to explosives

    return max(1, InDamage); // at least 1 damage must be done
}


// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM79MPickup') )
        return 1.0; //no discount on medic nade launchers

    if ( ClassIsChildOf(Item, class'PipeBombPickup')
        || (ClassIsChildOf(Item, class'M79Pickup') && !ClassIsChildOf(Item, class'ScrnM79IncPickup')) )
    {
        // Applied pipebomb discount to M79 (c) PooSH, 2012
        return fmax(0.10, 0.48 - 0.04 * GetClientVeteranSkillLevel(KFPRI)); // Up to 76% discount on M79 to match spawn value [Aze]
    }
    else if ( ClassIsChildOf(Item, class 'M32Pickup')
                || ClassIsChildOf(Item, class 'LawPickup')
                || ClassIsChildOf(Item, class 'M4203Pickup')
                || ClassIsChildOf(Item, class 'SPGrenadePickup')
                || ClassIsChildOf(Item, class 'SealSquealPickup') || ClassIsChildOf(Item, class 'SeekerSixPickup')
                || ClassIsInArray(default.PerkedPickups, Item) )
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

// Change the cost of particular ammo
// up to 30% discount on hand nades (c) PooSH, 2012
static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM79MPickup') )
        return 1.0; //no discount on medic nade launchers

    if ( ClassIsChildOf(Item, class'PipeBombPickup') )
    {
        return fmax(0.1, 0.48 - (0.04 * GetClientVeteranSkillLevel(KFPRI))); // Up to 76% discount on PipeBomb
    }
    else if ( ClassIsChildOf(Item, class'M79Pickup') || ClassIsChildOf(Item, class'M32Pickup')
            || ClassIsChildOf(Item, class'LAWPickup') || ClassIsChildOf(Item, class'M4203Pickup')
            || ClassIsChildOf(Item, class'SPGrenadePickup')
            || ClassIsChildOf(Item, class'SealSquealPickup') || ClassIsChildOf(Item, class'SeekerSixPickup')
            || ClassIsChildOf(Item, class'FragPickup')
            || ClassIsInArray(default.PerkedPickups, Item)
        )
    {
        return fmax(0.5, 1.0 - (0.05 * GetClientVeteranSkillLevel(KFPRI))); // Up to 30% discount on Grenade Launcher and LAW Ammo(Balance Round 5)
    }

    return 1.0;
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%a",GetPercentStr(0.10*Level));
    ReplaceText(S,"%g",string(Level));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    ReplaceText(S,"%p",GetPercentStr(fmin(0.90, 0.52 + 0.04*Level)));
    ReplaceText(S,"%d",GetPercentStr(fmin(0.50, 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'KFMod.DamTypeLAW'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultDemoBase'
    SamePerkAch="OP_Demo"

    SkillInfo="PERK SKILLS:|80% resistance to explosions"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x extra Explosive damage|%a extra Rockets|+%g extra Pipebombs, M203 and Hand Grenades|%$ discount on Explosives|%d discount on explosive ammo|%p discount on Pipebombs"

    PerkIndex=6
    OnHUDIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Demolitions"
    Requirements(0)="Deal %x damage with the Explosives"
}
