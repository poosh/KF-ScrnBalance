class ScrnVetFieldMedic extends ScrnVeterancyTypes
    abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RDamageHealedStat;
}

static function float GetSyringeChargeRate(KFPlayerReplicationInfo KFPRI)
{
    return 2.4 + (0.1 * float(GetClientVeteranSkillLevel(KFPRI))); // Level 6 - Recharges 200% faster
}

static function float GetHealPotency(KFPlayerReplicationInfo KFPRI)
{
    return 1.75;  // Heals for 75% more
}

static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( ClassIsChildOf(Other, class'Syringe') ) {
        return 1.6;
    }
    return 1.0;
}

// give medic speed bonus while holding syringe
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    if ( Syringe(Weap) != none )
        return class'ScrnBalanceSrv.ScrnHumanPawn'.default.BaseMeleeIncrease;
    return 0.0;
}

static function float GetMovementSpeedModifier(KFPlayerReplicationInfo KFPRI, KFGameReplicationInfo KFGRI)
{
    // 20% max no matter of difficulty
    return 1.20;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == class'DamTypeVomit' )
    {
        // Medics don't damage themselves with the bile shooter
        if( Injured == Instigator )
            return 0;

        return InDamage * 0.25; // 75% decrease in damage from Bloat's Bile
    }
    return InDamage;
}


//v2.55 up to 50% faster reload with MP5/MP7
//v9.17: removed reload bonus; base reloads made faster; short reloads introduced
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsInArray(default.SpecialWeapons, Other) )
        return 1.5;

    return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'ScrnMP7MMedicGun') || ClassIsChildOf(Other, class'ScrnMP5MMedicGun')
            || ClassIsChildOf(Other, class'M7A3MMedicGun') || ClassIsChildOf(Other, class'KrissMMedicGun')
            || ClassIsChildOf(Other, class'ScrnM4203MMedicGun')
            || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass) ) //v3 - custom weapon support
        return 2.0; // up to 100% increase in Medic weapon ammo carry
    return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
    if ( MP7MAmmo(Other) != none || MP5MAmmo(Other) != none || M7A3MAmmo(Other) != none
            || KrissMAmmo(Other) != none || BlowerThrowerAmmo(Other) != none
            //|| ScrnM203MAmmo(Other) != none
            || ClassIsInArray(default.PerkedAmmo, Other.class) ) //v3 - custom weapon support
        return 2.0; // 100% increase in MP7 Medic weapon ammo carry
    return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM79MAmmo') || ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo'))
        return 1.0 + (0.20 * GetClientVeteranSkillLevel(KFPRI)); // one extra medic nade per level

    if ( GetClientVeteranSkillLevel(KFPRI) > 6 &&
            (  ClassIsChildOf(AmmoType, class'MP7MAmmo')
            || ClassIsChildOf(AmmoType, class'MP5MAmmo')
            || ClassIsChildOf(AmmoType, class'M7A3MAmmo')
            || ClassIsChildOf(AmmoType, class'KrissMAmmo')
            || ClassIsChildOf(AmmoType, class'BlowerThrowerAmmo')
            || ClassIsChildOf(AmmoType, class'M4203Ammo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType) ))
    {
        return 1.0 + 0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +5% per level above 6
    }

    return 1.0;
}

// Change the cost of particular items
// v6.10 - all medic guns have regular discount rate
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'Vest' || ClassIsChildOf(Item, class'ScrnVestPickup')
                || ClassIsChildOf(Item, class'MP7MPickup')
                || ClassIsChildOf(Item, class'MP5MPickup')
                || ClassIsChildOf(Item, class'M7A3MPickup')
                || ClassIsChildOf(Item, class'KrissMPickup')
                || ClassIsChildOf(Item, class'BlowerThrowerPickup')
                || ClassIsChildOf(Item, class'ScrnM4203MPickup')
            || ClassIsInArray(default.PerkedPickups, Item) )
    {
        // 30% base discount + 5% extra per level
        return fmax(0.10, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }
    return 1.0;
}

// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier(KFPlayerReplicationInfo KFPRI)
{
    return fmax(0.40, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI)); // up to 60% improvement of Body Armor
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%s",GetPercentStr(2.40 + 0.10*Level));
    ReplaceText(S,"%v",GetPercentStr(fmin(0.60, 0.30 + 0.05*Level)));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

// allow medic to see NPC's health
static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
    local KF_StoryNPC_Spawnable NPC;
    local HUDKillingFloor HKF;

    HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
    if ( HKF == none || Pawn(C.ViewPort.Actor.ViewTarget)==none || Pawn(C.ViewPort.Actor.ViewTarget).Health<=0 )
        return;

    foreach C.ViewPort.Actor.VisibleCollidingActors(class'KF_StoryNPC_Spawnable',NPC,800,C.ViewPort.Actor.CalcViewLocation)
    {
        if ( NPC.Health > 0 /* && NPC.bActive */ && !NPC.bShowHealthBar )
            HKF.DrawHealthBar(C, NPC, NPC.Health, NPC.HealthMax , 50.0);
    }
}

// Medics can see other player health bars
static function bool ShowEnemyHealthBars(KFPlayerReplicationInfo KFPRI, KFPlayerReplicationInfo EnemyPRI)
{
    return true;
}

static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    // Field Medic and Combat medic share the same iventory
    return Pickup.default.CorrespondingPerkIndex == 9 || super.OverridePerkIndex(Pickup);
}

defaultproperties
{
    DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeMedic'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeMedicBase'
    SamePerkAch="OP_Medic"

    progressArray0(0)=100
    progressArray0(1)=500
    progressArray0(2)=2000
    progressArray0(3)=10000
    progressArray0(4)=30000
    progressArray0(5)=70000
    progressArray0(6)=110000

    SkillInfo="PERK SKILLS:|75% faster healing|75% less damage from Bloat Bile|20% faster movement speed|100% larger Medic Gun clip"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%s faster Syringe recharge|%v better Armor|%$ discount on Medic Guns and Armor"

    PerkIndex=0
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Medic'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Medic_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Field Medic"
    Requirements(0)="Heal %x HP on your teammates"
}
