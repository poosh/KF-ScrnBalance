class ScrnVetSupportSpec extends ScrnVeterancyTypes
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
    return StatOther.RShotgunDamageStat + 10 * StatOther.RWeldingPointsStat;
}

static function int AddCarryMaxWeight(KFPlayerReplicationInfo KFPRI)
{
    return 9;
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
        return class'ScrnHumanPawn'.default.BaseMeleeIncrease;
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
    else if ( !ClassIsChildOf(AmmoType, class'WelderAmmo') ) {
        return 1.0 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)));
    }
    return 1.0;
}

// Removed frag damage bonus (c) PooSH
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    local class<KFWeaponDamageType> KFDamType;

    KFDamType = class<KFWeaponDamageType>(DmgType);
    if ( DmgType == default.DefaultDamageTypeNoBonus || KFDamType == none )
        return InDamage;

    if ( KFDamType == default.DefaultDamageType
            || KFDamType.default.bIsPowerWeapon
            || KFDamType == class'ScrnDamTypeChainsawAlt'
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.3001 + 0.05 * GetClientVeteranSkillLevel(KFPRI);

        if (ZombieGorefast(Injured) != none) {
            InDamage *= 1.65;
        }
    }

    return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( InDamage == 0 )
        return 0;

    if ( class'ScrnBalance'.default.Mut.bHardcore && ZombieGorefast(Instigator) != none ) {
        InDamage *= 1.5; // x1.5 damage from gorefasts in hardcore mode
    }

    if ( ScrnChainsaw(Injured.Weapon) != none ) {
        InDamage *= 0.60; // 40% reduced Damage while holding Chainsaw
    }

    return max(1, InDamage); // at least 1 damage must be done
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
    if ( Item == class'ScrnShotgunPickup' )
        return 1.0; // price lowered to $200, no discount needed

    if ( ClassIsChildOf(Item, class'ShotgunPickup')
            || ClassIsChildOf(Item, class'BoomstickPickup')
            || ClassIsChildOf(Item, class'ScrnChainsawPickup')
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
    S = Repl(S,"%L",string(Level), true);
    S = Repl(S,"%x",GetPercentStr(0.30 + 0.05*Level), true);
    S = Repl(S,"%a",GetPercentStr(0.05*Level), true);
    S = Repl(S,"%g",string(Level), true);
    S = Repl(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
    return S;
}

static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    return Pickup == class'ScrnChainsawPickup' || super.OverridePerkIndex(Pickup);
}

defaultproperties
{
    DefaultDamageType=Class'KFMod.DamTypeShotgun'
    DefaultDamageTypeNoBonus=class'ScrnDamTypeDefaultSupportBase'
    SamePerkAch="OP_Support"

    SkillInfo="PERK SKILLS:|60% better Shotgun penetration|40% damage resistance while holding Chainsaw|+9 blocks in carry weight|150% faster welding/unwelding|Welder see door status from 30m|+65% damage to Gorefasts"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Shotguns/Chainsaw|%a extra ammo|+%g extra grenades|%$ discount on Shotguns"

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
    ShortName="SUP"
    bHardcoreReady=True
    Requirements(0)="Deal %x damage with shotguns"
}
