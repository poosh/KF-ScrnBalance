class ScrnVetBerserker extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RMeleeDamageStat;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( Injured == none || (ZombieScrake(Injured) != none && KFGameReplicationInfo(KFPRI.Level.GRI).GameDiff >= 5.0) ) {
        // lower Buzzsaw damage vs humans and Scrakes on Sui+
        if ( ClassIsChildOf(DmgType, class'ScrnBalanceSrv.ScrnDamTypeCrossbuzzsaw') )
            InDamage *= 0.8; // 800 * 0.8 = 640
        else if ( DmgType == class'DamTypeCrossbuzzsaw' )
            InDamage *= 0.64; // 100 * 0.64 = 640
    }
    if( class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bIsMeleeDamage )
    {
        // 55% base bonus + 7.5% per level
        InDamage *= 1.55 + 0.075 * GetClientVeteranSkillLevel(KFPRI);
    }

    return InDamage;
}

static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( ClassIsChildOf(Other, class'KFMeleeGun') || ClassIsChildOf(Other, class'Crossbuzzsaw') )
    {
        return 1.13 + 0.02 * float(GetClientVeteranSkillLevel(KFPRI));
    }

    return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'ScrnChainsaw')
            || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass) )  //v3 - custom weapon support
    {
        return 1.3 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnChainsawAmmo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType) )  //v3 - custom weapon support
    {
        return 1.3 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return 1.0;
}

// Make zerker extremely slow while healing
// (c) PooSH, 2012
// v1.74: 15% speed penalty while holding a non-melee gun
// v1.74: 30% speed penalty while holding a Syringe
// v2.26: 50% of MeleeMovementSpeedModifier is aplied on chainsaw too
// v4.39: Test try to give full speed bonus to chainsaw
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    // Syringe is a child of KFMeleeGun, so need to check it first!
    if ( Syringe(Weap) != none )
        return -0.15;
    else if ( KFMeleeGun(Weap) == none )
        return -0.15;
    else if ( Chainsaw(Weap) != none )
        return GetMeleeMovementSpeedModifier(KFPRI);
    return 0.0;
}

static function float GetMeleeMovementSpeedModifier(KFPlayerReplicationInfo KFPRI)
{
    return 0.3;
}

//fixed post level 6 damage resistance (c) PooSH
static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( InDamage == 0 )
        return 0;

    // HARDCORE - no damage resistance from Husk's fire damage
    // Except Doom3 Monsters mode, because there is no way to differ Husk damage from Imp or ArchVile damage
    if ( DmgType == class'DamTypeBurned' && class'ScrnBalance'.default.Mut.bHardcore
            && class'ScrnBalance'.default.Mut.GameRules.GameDoom3Kills == 0 )
        return InDamage;

    if ( DmgType == class'DamTypeVomit' ) {
        InDamage *= 0.20; // 80% reduced Bloat Bile damage
    }
    else if ( Instigator != none && Instigator.IsA('DoomMonster') ) {
        InDamage *= 0.40; // 60% reduced damage from Doom Demons
    }
    else {
        if ( KFPawn(Instigator) != none )
            InDamage *= 0.70; // v7.46: player-to-player damage
        else
            InDamage *= 0.60; // 40% reduced Damage
    }
    return max(1, InDamage); // at least 1 damage must be done
}

static function bool CanBeGrabbed(KFPlayerReplicationInfo KFPRI, KFMonster Other)
{
    return false;
}

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
    return 4;
}

static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'CrossbuzzsawPickup') ) {
        return fmax(0.5, 1.0 - (0.05 * GetClientVeteranSkillLevel(KFPRI))); // Up to 30% discount buzzsaw blades - to compensate SC damage resistance
    }
    return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if  ( ClassIsChildOf(Item, class'ChainsawPickup') || ClassIsChildOf(Item, class'KatanaPickup')
            || ClassIsChildOf(Item, class'ClaymoreSwordPickup')
            || ClassIsChildOf(Item, class'DwarfAxePickup')
            || ClassIsChildOf(Item, class'CrossbuzzsawPickup') || ClassIsChildOf(Item, class'ScythePickup')
            || Item == class'KFMod.AxePickup' || Item == class'KFMod.MachetePickup' // only for KFMod, expensive versions
            || ClassIsInArray(default.PerkedPickups, Item) //v3 - custom weapon support
        )
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.55 + 0.075*Level));
    ReplaceText(S,"%s",GetPercentStr(0.1301 + 0.02*Level));
    ReplaceText(S,"%a",GetPercentStr(0.05*Level));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'KFMod.DamTypeMelee'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeZerkerBase'
    SamePerkAch="OP_Berserker"

    SkillInfo="PERK SKILLS:|30% faster movement speed|80% less damage from Bloat Bile|60% less damage from Doom Demons|40% resistance to all damage|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more Melee damage|%s faster melee attacks|%a extra Chainsaw Fuel|%$ discount on Melee Weapons"

    PerkIndex=4
    VeterancyName="Berserker"
    Requirements(0)="Deal %x damage with melee weapons"

    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Berserker'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Berserker_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
}
