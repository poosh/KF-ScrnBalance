class ScrnVetFieldMedic extends ScrnVeterancyTypes
    abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RDamageHealedStat;
}

static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
    if (class'ScrnBalance'.default.Mut.bMedicNades)
        return class'ScrnMedicNade';

    return super.GetNadeType(KFPRI);
}

//cannot cook medic nades
static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    return !class'ScrnBalance'.default.Mut.bMedicNades;
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
        return class'ScrnHumanPawn'.default.BaseMeleeIncrease;
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
    else if ( !DmgType.default.bArmorStops && class'ScrnBalance'.default.Mut.bHardcore ) {
        return InDamage * 1.50;  // extra damage  from Siren Scream in Hardcore mode
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
    if ( ClassIsChildOf(AmmoType, class'ScrnM79MAmmo') || ClassIsChildOf(AmmoType, class'ScrnM203MAmmo'))
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
// v9.62 - no more discount on MP7M
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnMP7MPickup' )
        return 1.0;  // v9.62 - no more discount on MP7M

    if ( Item == class'Vest' || ClassIsChildOf(Item, class'ScrnVestPickup')
                || ClassIsChildOf(Item, class'MedicGunPickup')
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
static function int ShieldReduceDamage(KFPlayerReplicationInfo KFPRI, ScrnHumanPawn Injured, Pawn Instigator,
        int InDamage, class<DamageType> DmgType)
{
    local int AbsorbedDamage;

    if ( KFHumanPawn(Instigator) != none ) {
        // armor reduces up to 30% human damage
        AbsorbedDamage = InDamage * 0.30;
    }
    else {
        // armor reduces up to 60% damage
        AbsorbedDamage = InDamage * fmin(0.60, 0.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI));
    }

    // Armor may reduce damage up to twice of its remaining shield strength.
    // This prevents cases like medic with 1% armor reducing FP attack by 70hp
    AbsorbedDamage = min(AbsorbedDamage, Injured.ShieldStrength * 2);

    return InDamage - AbsorbedDamage;
}

// unused
static function float GetBodyArmorDamageModifier(KFPlayerReplicationInfo KFPRI)
{
    return fmax(0.40, 0.70 - 0.05 * GetClientVeteranSkillLevel(KFPRI)); // up to 60% improvement of Body Armor
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    S = Repl(S,"%L",string(Level), true);
    S = Repl(S,"%s",GetPercentStr(2.40 + 0.10*Level), true);
    S = Repl(S,"%v",GetPercentStr(fmin(0.60, 0.30 + 0.05*Level)), true);
    S = Repl(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
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
    DefaultDamageType=class'ScrnDamTypeMedic'
    DefaultDamageTypeNoBonus=class'ScrnDamTypeMedicBase'
    SamePerkAch="OP_Medic"

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
    ShortName="MED"
    bHardcoreReady=True
    Requirements(0)="Heal %x HP on your teammates"
    progressArray0(0)=100
    progressArray0(1)=500
    progressArray0(2)=2000
    progressArray0(3)=10000
    progressArray0(4)=20000
    progressArray0(5)=40000
    progressArray0(6)=70000
    progressArray0(7)=110000
    progressArray0(8)=160000
    progressArray0(9)=220000
    progressArray0(10)=290000
    progressArray0(11)=370000
    progressArray0(12)=460000
    progressArray0(13)=560000
    progressArray0(14)=670000
    progressArray0(15)=790000
    progressArray0(16)=920000
    progressArray0(17)=1060000
    progressArray0(18)=1210000
    progressArray0(19)=1370000
    progressArray0(20)=1540000
    progressArray0(21)=1920000
    progressArray0(22)=2320000
    progressArray0(23)=2720000
    progressArray0(24)=3120000
    progressArray0(25)=3540000
    progressArray0(26)=3980000
    progressArray0(27)=4420000
    progressArray0(28)=4860000
    progressArray0(29)=5320000
    progressArray0(30)=5800000
    progressArray0(31)=6380000
    progressArray0(32)=6960000
    progressArray0(33)=7560000
    progressArray0(34)=8180000
    progressArray0(35)=8800000
    progressArray0(36)=9420000
    progressArray0(37)=10060000
    progressArray0(38)=10720000
    progressArray0(39)=11380000
    progressArray0(40)=12040000
    progressArray0(41)=12820000
    progressArray0(42)=13620000
    progressArray0(43)=14420000
    progressArray0(44)=15220000
    progressArray0(45)=16040000
    progressArray0(46)=16880000
    progressArray0(47)=17720000
    progressArray0(48)=18560000
    progressArray0(49)=19420000
    progressArray0(50)=20300000
    progressArray0(51)=21280000
    progressArray0(52)=22260000
    progressArray0(53)=23260000
    progressArray0(54)=24280000
    progressArray0(55)=25300000
    progressArray0(56)=26320000
    progressArray0(57)=27360000
    progressArray0(58)=28420000
    progressArray0(59)=29480000
    progressArray0(60)=30540000
    progressArray0(61)=31720000
    progressArray0(62)=32920000
    progressArray0(63)=34120000
    progressArray0(64)=35320000
    progressArray0(65)=36540000
    progressArray0(66)=37780000
    progressArray0(67)=39020000
    progressArray0(68)=40260000
    progressArray0(69)=41520000
    progressArray0(70)=42800000
}
