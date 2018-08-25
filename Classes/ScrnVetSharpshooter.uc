class ScrnVetSharpshooter extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RHeadshotKillsStat;
}

//add SC and FP same resistance to M99 as Crossbow
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn Instigator, int InDamage, class<DamageType> DmgType)
{
    // v7.57: M99 resistance moved to ScrnM99Bullet
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return InDamage / 2;
    return InDamage;
}


static function float GetHeadShotDamMulti(KFPlayerReplicationInfo KFPRI, KFPawn P, class<DamageType> DmgType)
{
    local float ret;
    local bool bNoExtraBonus;

    if ( DmgType == default.DefaultDamageTypeNoBonus ) {
        ret = 1.0;
    }
    else if ( ClassIsChildOf(DmgType, class'DamTypeDualies') && KFPRI.Level.Game.GameDifficulty >= 7.0 ) {
        ret = 1.40; // limit to 40% max HS damage bonus
        bNoExtraBonus = true;
    }
    else if ( DmgType == default.DefaultDamageType
            || class<KFWeaponDamageType>(DmgType).default.bSniperWeapon
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
            )
    {
        ret = 1.0 + 0.10 * GetClientVeteranSkillLevel(KFPRI);
    }
    else {
        ret = 1.0; // Fix for oversight in Balance Round 6(which is the reason for the Round 6 second attempt patch)
    }

    if ( !bNoExtraBonus ) {
        ret *= 1.50;
    }

    if ( class'ScrnBalance'.default.Mut.bHardcore )
        ret *= 2.0; // to compensate 50% damage reduction in ReduceDamage();

    //Log("Headshot multiplier for " $ String(DmgType) $ " is " $ ret);
    return  ret;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
    // If Gunslinger perk persists, remove bonus from dual pistols.
    if ( Crossbow(Other.Weapon) != none || Winchester(Other.Weapon) != none
            || Single(Other.Weapon) != none || Deagle(Other.Weapon) != none
            || Magnum44Pistol(Other.Weapon) != none
            || M14EBRBattleRifle(Other.Weapon) != none
            || M99SniperRifle(Other.Weapon) != none
            || SPSniperRifle(Other.Weapon) != none
            || ClassIsInArray(default.PerkedWeapons, Other.Weapon.Class) //v3 - custom weapon support
        )
    {
        Recoil = 0.25;
    }
    else
        Recoil = 1.0;
    Return Recoil;
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( ClassIsChildOf(Other, class'Winchester') || ClassIsChildOf(Other, class'SPSniperRifle')
        || ClassIsInArray(default.SpecialWeapons, Other) )
    {
        return 1.6; // 60% faster fire rate with LAR and Special Weapons
    }
    return 1.0;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    // If Gunslinger perk persists, remove bonus from dual pistols.
    if ( ClassIsChildOf(Other, class'Winchester') || ClassIsChildOf(Other, class'M14EBRBattleRifle')
            || ClassIsChildOf(Other, class'Single') || ClassIsChildOf(Other, class'Deagle')
            || ClassIsChildOf(Other, class'Magnum44Pistol') || ClassIsChildOf(Other, class'MK23Pistol')
            || ClassIsChildOf(Other, class'SPSniperRifle')
            || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
        )
    {
        return 1.6; // 60% faster reload with Pistols and Sniper Weapons
    }

    return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    //reduced base price, so no discount on magnums
    if ( Item == class'ScrnBalanceSrv.ScrnMagnum44Pickup' || Item == class'ScrnBalanceSrv.ScrnDual44MagnumPickup' )
        return 1.0;

    //leave discount for Dual Pistols even if Gunslinger perk persists to reject possible
    //buy-sell exploits
    if ( ClassIsChildOf(Item, class'DeaglePickup') || ClassIsChildOf(Item, class'DualDeaglePickup')
            || ClassIsChildOf(Item, class'MK23Pickup') || ClassIsChildOf(Item, class'DualMK23Pickup')
            || Item == class'Magnum44Pickup' || Item == class'Dual44MagnumPickup'
            || ClassIsChildOf(Item, class'M14EBRPickup')
            || ClassIsChildOf(Item, class'M99Pickup')
            || ClassIsChildOf(Item, class'SPSniperPickup')
            || ClassIsChildOf(Item, class'CrossbowPickup') // Add discount on Crossbow (c) PooSH, 2012
            || ClassIsInArray(default.PerkedPickups, Item) //v3 - custom weapon support
        )
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 6 ) {
        if ( ClassIsChildOf(AmmoType, class'CrossbowAmmo')
                || ClassIsChildOf(AmmoType, class'M99Ammo')
                || ClassIsChildOf(AmmoType, class'SPSniperAmmo')
                || ClassIsChildOf(AmmoType, class'WinchesterAmmo')
                || ClassIsChildOf(AmmoType, class'M14EBRAmmo')
                || ClassIsChildOf(AmmoType, class'SingleAmmo')
                || ClassIsChildOf(AmmoType, class'Magnum44Ammo')
                || ClassIsChildOf(AmmoType, class'MK23Ammo')
                || ClassIsChildOf(AmmoType, class'DeagleAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType) )
            return 1.0 + 0.10 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +10% per level above 6
    }
    return 1.0;
}

static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'CrossbowPickup') || ClassIsChildOf(Item, class'M99Pickup') ) {
        return 1.0 - fmin(0.7, (0.07 * GetClientVeteranSkillLevel(KFPRI))); // Up to 42% discount on Crossbow Bolts(Added in Balance Round 4 at 30%, increased to 42% in Balance Round 7)
    }
    return 1.0;
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.15*Level));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    ReplaceText(S,"%d",GetPercentStr(fmin(0.70, 0.07*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeSniper'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeSniperBase'
    SamePerkAch="OP_Sharpshooter"

    progressArray0(0)=10
    progressArray0(1)=30
    progressArray0(2)=100
    progressArray0(3)=775
    progressArray0(4)=2500
    progressArray0(5)=5500
    progressArray0(6)=8500

    SkillInfo="PERK SKILLS:|50% headshot damage with any weapon|75% less recoil with Single Pistols/Sniper Rifles|60% faster reload with Single Pistols/Sniper Rifles"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|+%x extra headshot damage with Pistols/Sniper Rifles|%$ discount on Pistols/Sniper Rifles|%d discount on Crossbow/M99 ammo"

    PerkIndex=2
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_SharpShooter'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_SharpShooter_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Sharpshooter_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Sharpshooter"
    Requirements(0)="Get %x headshot kills with Pistols/LAR/M14/Crossbow/M99"
}
