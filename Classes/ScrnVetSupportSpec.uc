class ScrnVetSupportSpec extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
    if (ReqNum == 1)
        return StatOther.RWeldingPointsStat;
    // 0 and default
    return StatOther.RShotgunDamageStat;
}

static function int AddCarryMaxWeight(KFPlayerReplicationInfo KFPRI)
{
    return 10;
}

// Adjust distance of welded door health status
static function float GetDoorHealthVisibilityScaling(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    return 5.0; //5x longer distance
}

// give support melee speed bonus while holding welder
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    if ( Welder(Weap) != none )
        return class'ScrnBalanceSrv.ScrnHumanPawn'.default.BaseMeleeIncrease;
    return 0.0;
}

static function float GetWeldSpeedModifier(KFPlayerReplicationInfo KFPRI)
{
    return 2.5; // 150% increase in speed
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( AmmoType == class'FragAmmo' )
        // Up to 6 extra Grenades
        return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI)));
    else if ( ClassIsChildOf(AmmoType, class'AA12Ammo') || ClassIsChildOf(AmmoType, class'KSGAmmo') )
    {
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6)
            return 1.0 + 0.125 * min(4, (GetClientVeteranSkillLevel(KFPRI)+2)/2); //+10 ammo per 2 levels, up to 50% increase in AA12 ammo
        else
            return 1.5 + 0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +5% ammo above level 6
    }
    else {
        return 1.0 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)));
    }
    return 1.0;
}

// Removed frag damage bonus (c) PooSH
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus || class<KFWeaponDamageType>(DmgType) == none )
        return InDamage;

    if ( DmgType == default.DefaultDamageType
            || class<KFWeaponDamageType>(DmgType).default.bIsPowerWeapon
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}


// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return 0.80; // 20% slower fire rate in hardcore mode

    return 1.0;
}

// Support's penetration bonus limited to 60% (down from 90%),
// but shotgun's base penetration count is increased making them more usefull off the perk
// But I whink community will rape me for this :)
// (c) PooSH
static function float GetShotgunPenetrationDamageMulti(KFPlayerReplicationInfo KFPRI, float DefaultPenDamageReduction)
{
    local float PenDamageInverse;

    if ( DefaultPenDamageReduction < 0.0001 )
        return 0.0; // do not enhance penetration if that is disabled
    else if ( DefaultPenDamageReduction > 0.9999 )
        return DefaultPenDamageReduction; // do not enhance penetration if there is no damage reduction

    PenDamageInverse = 1.0 - DefaultPenDamageReduction;
    return DefaultPenDamageReduction + fmin(PenDamageInverse, DefaultPenDamageReduction) * 0.6; // 60% better penetration
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnShotgunPickup' )
        return 1.0; // price lowered to $200, no discount needed

    if ( ClassIsChildOf(Item, class'ShotgunPickup')
            || ClassIsChildOf(Item, class'BoomstickPickup')
            || ClassIsChildOf(Item, class'AA12Pickup')
            || ClassIsChildOf(Item, class'KSGPickup')
            || ClassIsChildOf(Item, class'BenelliPickup')
            || ClassIsChildOf(Item, class'NailGunPickup')
            || ClassIsChildOf(Item, class'SPShotgunPickup')
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
    ReplaceText(S,"%x",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%a",GetPercentStr(0.05*Level));
    ReplaceText(S,"%g",string(Level));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'KFMod.DamTypeShotgun'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultSupportBase'
    SamePerkAch="OP_Support"

    progressArray1(0)=1000
    progressArray1(1)=2000
    progressArray1(2)=7000
    progressArray1(3)=33500
    progressArray1(4)=120000
    progressArray1(5)=250000
    progressArray1(6)=370000

    progressArray0(0)=10000
    progressArray0(1)=25000
    progressArray0(2)=100000
    progressArray0(3)=500000
    progressArray0(4)=1500000
    progressArray0(5)=3500000
    progressArray0(6)=5500000

    SkillInfo="PERK SKILLS:|60% better Shotgun penetration|+10 blocks in carry weight|150% faster welding/unwelding|Welder can detect door healths from 30m"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Shotguns|%a extra ammo|+%g extra grenades|%$ discount on Shotguns"

    NumRequirements=1 // removed welding req. in v9.50
    PerkIndex=1
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Support'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Support_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Support Specialist"
    Requirements(0)="Deal %x damage with shotguns"
    Requirements(1)="Weld %x door hitpoints"
}
