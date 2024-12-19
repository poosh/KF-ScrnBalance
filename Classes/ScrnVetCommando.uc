class ScrnVetCommando extends ScrnVeterancyTypes
    abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
    return StatOther.RBullpupDamageStat + 1000 * StatOther.RStalkerKillsStat;
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
    return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsChildOf(Other, class'Bullpup')
            || ClassIsChildOf(Other, class'AK47AssaultRifle') || ClassIsChildOf(Other, class'MKb42AssaultRifle')
            || ClassIsChildOf(Other, class'M4AssaultRifle')
            || ClassIsChildOf(Other, class'SCARMK17AssaultRifle') || ClassIsChildOf(Other, class'FNFAL_ACOG_AssaultRifle')
            || ClassIsChildOf(Other, class'ThompsonSMG')
            || ClassIsInArray(default.PerkedWeapons, Other)  //v3 - custom weapon support
        )
    {
        return 1.5001; // 50% bigger assault rifle magazine
    }
    return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
    return 1.5001;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    local byte lv;

    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return 1.0; // no extra ammo in Hardcore Mode

    lv = GetClientVeteranSkillLevel(KFPRI);

    if ( ClassIsInArray(default.PerkedAmmo, AmmoType) ) {
        return 1.2501 + 0.05 * lv;
    }
    else if ( lv > 6 ) {
        return 1.0001 + 0.05 * (lv - 6);
    }
    return 1.0;
}
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( ClassIsChildOf(DmgType, default.DefaultDamageType)
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
        // 30% base bonus + 5% per level
        InDamage *= 1.3001 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( class'ScrnBalance'.default.Mut.bHardcore && DmgType == class'DamTypeSlashingAttack' ) {
        return InDamage * 4.0; // quad damage from Stalkers in hardcore mode
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
    return min(6, 2 + GetClientVeteranSkillLevel(KFPRI)/3); // 2 base + 1 extension per 3 levels
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBullpupPickup' )
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
    S = Repl(S, "%L", string(Level), true);
    S = Repl(S, "%x", GetPercentStr(0.30 + 0.05*Level), true);
    S = Repl(S, "%z", string(min(6, 2 + Level/3)), true);
    S = Repl(S, "%$", GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
    return S;
}

static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    return Pickup == class'ScrnM4203Pickup' || super.OverridePerkIndex(Pickup);
}


defaultproperties
{
    DefaultDamageType=Class'ScrnDamTypeCommando'
    DefaultDamageTypeNoBonus=Class'ScrnDamTypeCommandoBase'
    SamePerkAch="OP_Commando"

    SkillInfo="PERK SKILLS:|50% larger Assaut Rifle clip|35% faster reload with all weapons|40% less recoil with all weapons|See cloaked enemies and health"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Assaut Rifles|Up to %z Zed-Time Extensions|%$ discount on Assaut Rifles"

    NumRequirements=1  // v9.65: Stalker kills add XP to Commando damage perk progress
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
    ShortName="CMD"
    bHardcoreReady=True
    Requirements(0)="Deal %x damage with Assault Rifles"
}
