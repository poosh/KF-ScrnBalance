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

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore && ZombieScrake(Instigator) != none ) {
        return InDamage * 1.5; // 50% more damage from Scrake nad Jason in hardcore mode
    }
    return InDamage;
}

static function float GetHeadShotDamMulti(KFPlayerReplicationInfo KFPRI, KFPawn P, class<DamageType> DmgType)
{
    local float ret;

    if ( DmgType == default.DefaultDamageTypeNoBonus ) {
        ret = 1.0;
    }
    else if ( ClassIsChildOf(DmgType, class'DamTypeDualies') ) {
        return 1.4;  // just 40%, no extra x1.50
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

    ret *= 1.50;

    if ( class'ScrnBalance'.default.Mut.bHardcore )
        ret *= 2.0; // to compensate 50% damage reduction in AddDamage();

    //Log("Headshot multiplier for " $ String(DmgType) $ " is " $ ret);
    return  ret;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
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
    return Recoil;
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( ClassIsChildOf(Other, class'Winchester')
            || ClassIsChildOf(Other, class'SPSniperRifle')
            || ClassIsInArray(default.SpecialWeapons, Other) )
    {
        return 1.6; // 60% faster fire rate with LAR and Special Weapons
    }
    return 1.0;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Winchester')
            || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
        )
    {
        return 1.6;
    }

    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return 1.0;

    if ( ClassIsChildOf(Other, class'Single')
            || ClassIsChildOf(Other, class'Deagle')
            || ClassIsChildOf(Other, class'Magnum44Pistol')
            || ClassIsChildOf(Other, class'MK23Pistol')
            || ClassIsChildOf(Other, class'M14EBRBattleRifle')
            || ClassIsChildOf(Other, class'SPSniperRifle'))
    {
        return 1.3;
    }

    return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    //reduced base price, so no discount on magnums
    if ( Item == class'ScrnMagnum44Pickup' || Item == class'ScrnDual44MagnumPickup' )
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
    S = Repl(S,"%L",string(Level), true);
    S = Repl(S,"%x",GetPercentStr(0.15*Level), true);
    S = Repl(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
    S = Repl(S,"%d",GetPercentStr(fmin(0.70, 0.07*Level)), true);
    return S;
}

static function AddTourneyInventory(ScrnHumanPawn ScrnPawn)
{
    ScrnPawn.CreateWeapon(class'ScrnWinchester', 40);
}

defaultproperties
{
    DefaultDamageType=class'ScrnDamTypeSniper'
    DefaultDamageTypeNoBonus=class'ScrnDamTypeSniperBase'
    SamePerkAch="OP_Sharpshooter"

    SkillInfo="PERK SKILLS:|50% headshot damage with any weapon|75% less recoil with Single Pistols/Sniper Rifles|30% faster reload with Single Pistols/M14/Musket|60% faster reload with LAR/Sniper Rifles"
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
    ShortName="SHA"
    bHardcoreReady=True
    Requirements(0)="Get %x headshot kills with Pistols/Sniper Rifles"
    progressArray0(0)=10
    progressArray0(1)=50
    progressArray0(2)=200
    progressArray0(3)=1000
    progressArray0(4)=2000
    progressArray0(5)=4000
    progressArray0(6)=7000
    progressArray0(7)=11000
    progressArray0(8)=16000
    progressArray0(9)=22000
    progressArray0(10)=29000
    progressArray0(11)=37000
    progressArray0(12)=46000
    progressArray0(13)=56000
    progressArray0(14)=67000
    progressArray0(15)=79000
    progressArray0(16)=92000
    progressArray0(17)=106000
    progressArray0(18)=121000
    progressArray0(19)=137000
    progressArray0(20)=154000
    progressArray0(21)=192000
    progressArray0(22)=232000
    progressArray0(23)=272000
    progressArray0(24)=312000
    progressArray0(25)=354000
    progressArray0(26)=398000
    progressArray0(27)=442000
    progressArray0(28)=486000
    progressArray0(29)=532000
    progressArray0(30)=580000
    progressArray0(31)=638000
    progressArray0(32)=696000
    progressArray0(33)=756000
    progressArray0(34)=818000
    progressArray0(35)=880000
    progressArray0(36)=942000
    progressArray0(37)=1006000
    progressArray0(38)=1072000
    progressArray0(39)=1138000
    progressArray0(40)=1204000
    progressArray0(41)=1282000
    progressArray0(42)=1362000
    progressArray0(43)=1442000
    progressArray0(44)=1522000
    progressArray0(45)=1604000
    progressArray0(46)=1688000
    progressArray0(47)=1772000
    progressArray0(48)=1856000
    progressArray0(49)=1942000
    progressArray0(50)=2030000
    progressArray0(51)=2128000
    progressArray0(52)=2226000
    progressArray0(53)=2326000
    progressArray0(54)=2428000
    progressArray0(55)=2530000
    progressArray0(56)=2632000
    progressArray0(57)=2736000
    progressArray0(58)=2842000
    progressArray0(59)=2948000
    progressArray0(60)=3054000
    progressArray0(61)=3172000
    progressArray0(62)=3292000
    progressArray0(63)=3412000
    progressArray0(64)=3532000
    progressArray0(65)=3654000
    progressArray0(66)=3778000
    progressArray0(67)=3902000
    progressArray0(68)=4026000
    progressArray0(69)=4152000
    progressArray0(70)=4280000
}
