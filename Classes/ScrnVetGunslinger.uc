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
        return 1.0001 + (GetClientVeteranSkillLevel(KFPRI) / 12.0); // a magazine per level. Usually pistols have 12 magazines in total

    return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if (  ClassIsChildOf(DmgType, default.DefaultDamageType)
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeDeagle')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMagnum44Pistol ')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMK23Pistol')
            || ClassIsChildOf(DmgType, class'ScrnDamTypeFlareRevolverImpact')
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeWinchester')
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.3001 + 0.05 * GetClientVeteranSkillLevel(KFPRI);

        // Ideally, only headshot damage bonus should be granted, but GetHeadShotDamMulti() does not get Injured, so
        // we cannot check for bloats there. Another option: hack into ScrnGameRules.NetDamage() - too complicated.
        // Anyway, Bloat has much body hp, so it is not a big deal.
        if ( ZombieBloat(Injured) != none ) {
            InDamage *= 1.5;
        }
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
    // local Controller C;

    if ( WeapClass == none )
        return false;

    // C = Controller(KFPRI.Owner);  // server-side
    // if ( C == none ) {
    //     C = KFPRI.Level.GetLocalPlayerController();  // client-side
    // }
    // if ( C == none || C.Pawn == none || int(C.Pawn.ShieldStrength) > 25 ) {
    //     return false;
    // }

    // if custom weapon has "*" bonus switch
    return ClassIsChildOf(WeapClass, class'Dualies') || ClassIsInArray(default.SpecialWeapons, WeapClass );
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( ClassIsChildOf(Other, class'Winchester') ||  Other.name == 'Colt' )
        return 1.6;

    //increase fire only with full-automatic pistols
    if ( (ClassIsChildOf(Other, class'ScrnDualies') || !Other.default.FireModeClass[0].default.bWaitForRelease)
            && CheckCowboyMode(KFPRI, Other) )
    {
        return 1.6;
    }

    return 1.0;
}

// v9.64: Removed Cowboy reload speed bonus for dualies with tactical realod
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Magnum44Pistol') || ClassIsChildOf(Other, class'Dual44Magnum')
            || ClassIsChildOf(Other, class'FlareRevolver') || ClassIsChildOf(Other, class'DualFlareRevolver')
            || Other.name == 'Colt' )
    {
        if ( class'ScrnBalance'.default.Mut.bHardcore )
            return 1.6;
        return 2.0;
    }
    else if ( ClassIsChildOf(Other, class'Dualies') // all dual pistols classes extend this
            || ClassIsChildOf(Other, class'Single') || ClassIsChildOf(Other, class'Deagle')
            || ClassIsChildOf(Other, class'MK23Pistol')
            || ClassIsChildOf(Other, class'Winchester')
            || ClassIsInArray(default.PerkedWeapons, Other) ) //v3 - custom weapon support
    {
        if ( class'ScrnBalance'.default.Mut.bHardcore )
            return 1.3;
        return 1.6; // Up to 60% faster reload with pistols
    }

    return 1.0;
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
    S = Repl(S,"%L",string(Level), true);
    S = Repl(S,"%x",GetPercentStr(0.30 + 0.05*Level), true);
    S = Repl(S,"%a",string(Level), true);
    S = Repl(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslinger'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslingerBase'
    SamePerkAch="OP_Gunslinger"

    SkillInfo="PERK SKILLS:|100% faster reload with Revolvers|60% faster reload with Pistols|50% less recoil with Pistols|+50% damage to Bloats||COWBOY MODE:|20% increase in movement speed|9mm Machine-Pistols"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Pistols|%$ discount on Pistols|%a extra Pistol magazines"

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
    ShortName="GS"
    bHardcoreReady=True
    Requirements(0)="Get %x kills with Pistols"
    progressArray0(0)=15
    progressArray0(1)=60
    progressArray0(2)=250
    progressArray0(3)=1250
    progressArray0(4)=2500
    progressArray0(5)=5000
    progressArray0(6)=8750
    progressArray0(7)=13750
    progressArray0(8)=20000
    progressArray0(9)=27500
    progressArray0(10)=36250
    progressArray0(11)=46250
    progressArray0(12)=57500
    progressArray0(13)=70000
    progressArray0(14)=83750
    progressArray0(15)=99000
    progressArray0(16)=115000
    progressArray0(17)=133000
    progressArray0(18)=151000
    progressArray0(19)=171000
    progressArray0(20)=193000
    progressArray0(21)=240000
    progressArray0(22)=290000
    progressArray0(23)=340000
    progressArray0(24)=390000
    progressArray0(25)=443000
    progressArray0(26)=498000
    progressArray0(27)=553000
    progressArray0(28)=608000
    progressArray0(29)=665000
    progressArray0(30)=725000
    progressArray0(31)=798000
    progressArray0(32)=870000
    progressArray0(33)=945000
    progressArray0(34)=1023000
    progressArray0(35)=1100000
    progressArray0(36)=1178000
    progressArray0(37)=1258000
    progressArray0(38)=1340000
    progressArray0(39)=1423000
    progressArray0(40)=1505000
    progressArray0(41)=1603000
    progressArray0(42)=1703000
    progressArray0(43)=1803000
    progressArray0(44)=1903000
    progressArray0(45)=2005000
    progressArray0(46)=2110000
    progressArray0(47)=2215000
    progressArray0(48)=2320000
    progressArray0(49)=2428000
    progressArray0(50)=2538000
    progressArray0(51)=2660000
    progressArray0(52)=2783000
    progressArray0(53)=2908000
    progressArray0(54)=3035000
    progressArray0(55)=3163000
    progressArray0(56)=3290000
    progressArray0(57)=3420000
    progressArray0(58)=3553000
    progressArray0(59)=3685000
    progressArray0(60)=3818000
    progressArray0(61)=3965000
    progressArray0(62)=4115000
    progressArray0(63)=4265000
    progressArray0(64)=4415000
    progressArray0(65)=4568000
    progressArray0(66)=4723000
    progressArray0(67)=4878000
    progressArray0(68)=5033000
    progressArray0(69)=5190000
    progressArray0(70)=5350000
}
