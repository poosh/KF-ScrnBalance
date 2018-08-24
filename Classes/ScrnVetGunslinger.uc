/**
 * Perk designed for using pistols
 */
class ScrnVetGunslinger extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  if (ReqNum == 1)
    return StatOther.GetCustomValueInt(Class'ScrnBalanceSrv.ScrnPistolDamageProgress');
  // 0 and default
  return StatOther.GetCustomValueInt(Class'ScrnBalanceSrv.ScrnPistolKillProgress');
}


static function AddCustomStats( ClientPerkRepLink Other )
{
    super.AddCustomStats(Other); //init achievements

    Other.AddCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress');
    Other.AddCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress');
}


static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    // 18, 21, 24 magazine ammo on level 1, 3, 5
    if ( ClassIsChildOf(Other, class'ScrnSingle') || ClassIsChildOf(Other, class'ScrnDualies') )
        return 1.0 + 0.20 * ((GetClientVeteranSkillLevel(KFPRI)+1) / 2) ;
    return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'SingleAmmo') || ClassIsChildOf(AmmoType, class'DualiesAmmo')
            || ClassIsChildOf(AmmoType, class'Magnum44Ammo')
            || ClassIsChildOf(AmmoType, class'MK23Ammo')
            || ClassIsChildOf(AmmoType, class'DeagleAmmo')
            || ClassIsChildOf(AmmoType, class'FlareRevolverAmmo')
            || ClassIsChildOf(AmmoType, class'WinchesterAmmo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
        )
        return 1.0 + (0.10 * GetClientVeteranSkillLevel(KFPRI)); //up to 60% ammo bonus

    return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if (  DmgType == default.DefaultDamageType
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeDeagle')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMagnum44Pistol ')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMK23Pistol')
            || ClassIsChildOf(DmgType, class'ScrnDamTypeFlareRevolverImpact')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeWinchester')
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    else if ( ClassIsChildOf(DmgType, class'KFMod.DamTypeDualies') ) {
        InDamage *= 1.05 + 0.05 * GetClientVeteranSkillLevel(KFPRI); // Up to 35% increase in Damage with 9mm
    }
    return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore && ZombieCrawler(Instigator) != none ) {
        return InDamage * 2; // double damage from crawlers in hardcore mode
    }
    return InDamage;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
    if ( Single(Other.Weapon) != none || Dualies(Other.Weapon) != none
            || Deagle(Other.Weapon) != none
            || MK23Pistol(Other.Weapon) != none
            || Magnum44Pistol(Other.Weapon) != none
            || FlareRevolver(Other.Weapon) != none
            || Winchester(Other.Weapon) != none
            || ClassIsInArray(default.PerkedWeapons, Other.Weapon.Class) //v3 - custom weapon support
        )
    {
        Recoil = 0.5; //up to 50% recoil reduction
    }
    else
        Recoil = 1.0;
    Return Recoil;
}

// Starting from level 3 Gunslinger can enter Cowboy mode
// Cowboys use only dual-pistols, wears no armor and don't use advanced features like lasers
// Cowboy mode is switched automatically when all the requirements are met
// v2.30 - Allow Cowboy Mode, if Armor depletes below 25%
// v5.05 - Allow Cowboy Mode along with using laser sights
static function bool CheckCowboyMode(KFPlayerReplicationInfo KFPRI, class<Weapon> WeapClass)
{
    local Pawn p;

    // doesn't work on client side, unless pawn is locally controlled
    if ( Controller(KFPRI.Owner) != none ) {
        p = Controller(KFPRI.Owner).Pawn;
    }

    // assume that player is not so stupid to trade Cowboy Mode for an armor
    // Calling FindPawn() is too slow for such minor case
    if ( p != none && p.ShieldStrength >= 26 )
        return false;

    if ( WeapClass == none )
        return false;

    // if custom weapon has "*" bonus switch
    if ( ClassIsInArray(default.SpecialWeapons, WeapClass ) )
        return true;

    return ClassIsChildOf(WeapClass, class'Dualies');
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    //increase fire only with full-automatic pistols
    if ( CheckCowboyMode(KFPRI, Other) && (Other.class == class'Dualies' || ClassIsChildOf(Other, class'ScrnDualies')
            || !Other.default.FireModeClass[0].default.bWaitForRelease) )
    {
        return 1.6;
    }

    if ( ClassIsChildOf(Other, class'Winchester') )
        return 1.6;

    return 1.0;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    local float result;

    result = 1.0;
    if ( ClassIsChildOf(Other, class'Dualies') // all dual pistols classes extend this
            || ClassIsChildOf(Other, class'Single') || ClassIsChildOf(Other, class'Deagle')
            || ClassIsChildOf(Other, class'MK23Pistol') || ClassIsChildOf(Other, class'Magnum44Pistol')
            || ClassIsChildOf(Other, class'FlareRevolver')
            || ClassIsChildOf(Other, class'Winchester')
            || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
        )
        result = 1.6; // Up to 60% faster reload with pistols
    // Level 6 Cowboys reload dualies in the same time as singles
    if ( CheckCowboyMode(KFPRI, Other) )
        result *= 1.35; // 35% extra bonus for cowboys

    return result;
}

static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    if ( CheckCowboyMode(KFPRI, Weap.class) )
        return 0.20;
    return 0.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    //reduced base price, so no discount on magnums
    if ( Item == class'ScrnBalanceSrv.ScrnMagnum44Pickup' || Item == class'ScrnBalanceSrv.ScrnDual44MagnumPickup' )
        return 1.0;

    if ( ClassIsChildOf(Item,  class'DeaglePickup') || ClassIsChildOf(Item,  class'DualDeaglePickup')
            || ClassIsChildOf(Item, class'MK23Pickup') || ClassIsChildOf(Item, class'DualMK23Pickup')
            || Item == class'Magnum44Pickup' || Item == class'Dual44MagnumPickup'
            || ClassIsChildOf(Item, class'ScrnDual44MagnumLaserPickup')
            || ClassIsChildOf(Item, class'FlareRevolverPickup') || ClassIsChildOf(Item, class'DualFlareRevolverPickup')
            || ClassIsInArray(default.PerkedPickups, Item)
        )
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    return Pickup == class'ScrnWinchesterPickup' || Pickup == class'ScrnDualFlareRevolverPickup'
            || super.OverridePerkIndex(Pickup);
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%a",GetPercentStr(0.10*Level));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslinger'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslingerBase'
    SamePerkAch="OP_Gunslinger"

    progressArray0(0)=20
    progressArray0(1)=50
    progressArray0(2)=200
    progressArray0(3)=1000
    progressArray0(4)=3000
    progressArray0(5)=7000
    progressArray0(6)=11000

    progressArray1(0)=10000
    progressArray1(1)=25000
    progressArray1(2)=100000
    progressArray1(3)=500000
    progressArray1(4)=1500000
    progressArray1(5)=3500000
    progressArray1(6)=5500000

    SkillInfo="PERK SKILLS:|60% faster reload with Pistols|50% less recoil with Pistols||COWBOY MODE:|35% extra reload speed|20% increase in movement speed|9mm Machine-Pistols"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Pistols|%a extra Pistol ammo|%$ discount on Pistols"

    NumRequirements=1 // removed damage req. in v5.30 Beta 18
    PerkIndex=8
    OnHUDIcon=Texture'ScrnTex.Perks.Perk_Gunslinger'
    OnHUDGoldIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))

    VeterancyName="Gunslinger"
    Requirements(0)="Get %x kills with Pistols"
    Requirements(1)="Deal %x damage with Pistols"
}
