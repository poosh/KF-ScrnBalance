class ScrnVetCommando extends ScrnVeterancyTypes
    abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  if (ReqNum == 1)
    return StatOther.RBullpupDamageStat;
  // 0 and default
  return StatOther.RStalkerKillsStat;
}


// Display enemy health bars
static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
    local KFMonster KFEnemy;
    local HUDKillingFloor HKF;
    local float MaxDistance;

    HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
    if ( HKF == none || Pawn(C.ViewPort.Actor.ViewTarget)==none || Pawn(C.ViewPort.Actor.ViewTarget).Health<=0 )
        return;

    MaxDistance = 800;
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        MaxDistance *= 0.75;

    foreach C.ViewPort.Actor.VisibleCollidingActors(class'KFMonster',KFEnemy,MaxDistance,C.ViewPort.Actor.CalcViewLocation)
    {
        if ( KFEnemy.Health > 0 && !KFEnemy.Cloaked() )
            HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax , 50.0);
    }
}

static function bool ShowStalkers(KFPlayerReplicationInfo KFPRI)
{
    return true;
}

static function float GetStalkerViewDistanceMulti(KFPlayerReplicationInfo KFPRI)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return 0.75;

    return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Bullpup')
            || ClassIsChildOf(Other, class'AK47AssaultRifle') || ClassIsChildOf(Other, class'MKb42AssaultRifle')
            || ClassIsChildOf(Other, class'M4AssaultRifle')
            || ClassIsChildOf(Other, class'SCARMK17AssaultRifle') || ClassIsChildOf(Other, class'FNFAL_ACOG_AssaultRifle')
            || ClassIsChildOf(Other, class'ThompsonSMG')
            || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass)  //v3 - custom weapon support
        )
    {
        return 1.25; // 25% bigger assault rifle magazine
    }
    return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
    return AddExtraAmmoFor(KFPRI, Other.class);
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo') )
        return 1.0; // no extra medic grenades

    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(AmmoType, class'BullpupAmmo')
                || ClassIsChildOf(AmmoType, class'AK47Ammo')
                || ClassIsChildOf(AmmoType, class'SCARMK17Ammo' )
                || ClassIsChildOf(AmmoType, class'M4Ammo')
                || ClassIsChildOf(AmmoType, class'FNFALAmmo')
                || ClassIsChildOf(AmmoType, class'MKb42Ammo')
                || ClassIsChildOf(AmmoType, class'ThompsonAmmo')
                || ClassIsChildOf(AmmoType, class'ThompsonDrumAmmo')
                || ClassIsChildOf(AmmoType, class'SPThompsonAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
            )
        {
            return 1.25 + fmax(0.00, 0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6)); // +10% per level above 6
        }
    }
    return 1.0;
}
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( DmgType == default.DefaultDamageType
            || ClassIsChildOf(DmgType, class'DamTypeBullpup')
            || ClassIsChildOf(DmgType, class'DamTypeAK47AssaultRifle')
            || ClassIsChildOf(DmgType, class'DamTypeSCARMK17AssaultRifle')
            || ClassIsChildOf(DmgType, class'DamTypeM4AssaultRifle')
            || ClassIsChildOf(DmgType, class'DamTypeFNFALAssaultRifle')
            || ClassIsChildOf(DmgType, class'DamTypeMKb42AssaultRifle')
            || ClassIsChildOf(DmgType, class'DamTypeThompson')
            || ClassIsChildOf(DmgType, class'DamTypeThompsonDrum')
            || ClassIsChildOf(DmgType, class'DamTypeSPThompson')
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
    {
        // 20% base bonus + 5% per level
        InDamage *= 1.20 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore && DmgType == class'DamTypeSlashingAttack' ) {
        return InDamage * 3.5; // quad damage from Stalkers in hardcore mode
    }

    return InDamage;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
    Recoil = 0.60;
    return Recoil;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    return 1.35; // Up to 35% faster reload speed for any weapon
}

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
    return min(10, 2 + GetClientVeteranSkillLevel(KFPRI)/3); // 2 base + 1 extention per 3 levels
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnBullpupPickup' )
        return 1.0; // price lowered to $200, no discount needed

    if ( ClassIsChildOf(Item, class'BullpupPickup')
            || ClassIsChildOf(Item, class'AK47Pickup' )
            || ClassIsChildOf(Item, class'SCARMK17Pickup')
            || ClassIsChildOf(Item, class'M4Pickup')
            || ClassIsChildOf(Item, class'FNFAL_ACOG_Pickup')
            || ClassIsChildOf(Item, class'MKb42Pickup')
            || ClassIsChildOf(Item, class'ThompsonPickup')
            || ClassIsChildOf(Item, class'ThompsonDrumPickup')
            || ClassIsChildOf(Item, class'SPThompsonPickup')
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
    ReplaceText(S, "%L", string(Level));
    ReplaceText(S, "%x", GetPercentStr(0.20 + 0.05*Level));
    ReplaceText(S, "%z", string(min(10, 2 + Level/3)));
    ReplaceText(S, "%$", GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

defaultproperties
{
    DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeCommando'
    DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeCommandoBase'
    SamePerkAch="OP_Commando"

    progressArray0(0)=10
    progressArray0(1)=30
    progressArray0(2)=100
    progressArray0(3)=325
    progressArray0(4)=1200
    progressArray0(5)=2400
    progressArray0(6)=3600

    progressArray1(0)=10000
    progressArray1(1)=25000
    progressArray1(2)=100000
    progressArray1(3)=500000
    progressArray1(4)=1500000
    progressArray1(5)=3500000
    progressArray1(6)=5500000

    SkillInfo="PERK SKILLS:|25% larger Assaut Rifle clip|100% faster reload with Tommy Guns|35% faster reload with all weapons|40% less recoil with all weapons|See cloaked enemies and health"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Assaut Rifles|Up to %z Zed-Time Extensions|%$ discount on Assaut Rifles"

    NumRequirements=2
    PerkIndex=3
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Commando'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Commando_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))

    VeterancyName="Commando"
    Requirements(0)="Kill %x Stalkers/Shivers with Assault Rifles"
    Requirements(1)="Deal %x damage with Assault Rifles"
}
