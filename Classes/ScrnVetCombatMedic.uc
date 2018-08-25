class ScrnVetCombatMedic extends ScrnVetFieldMedic
    abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
    return StatOther.RDamageHealedStat * 50;
}

static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
    return super(ScrnVeterancyTypes).GetNadeType(KFPRI); // no healing nades
}

static function float GetSyringeChargeRate(KFPlayerReplicationInfo KFPRI)
{
    return 1.00;  // no better healing
}

static function float GetHealPotency(KFPlayerReplicationInfo KFPRI)
{
    return 1.05; // added 5% to bypass IsMedic() check
}

static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
    if ( class<KFMeleeGun>(Other) != none &&  class<KFMeleeGun>(Other).default.Weight <= 3
        && class<Syringe>(Other) == none && class<Welder>(Other) == none )
    {
        return 1.75;
    }
    return 1.0;
}

static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
    return Min(GetClientVeteranSkillLevel(KFPRI), 6);
}

static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    return 0.0; // no speed bonus with Syringe
}

static function float GetMovementSpeedModifier(KFPlayerReplicationInfo KFPRI, KFGameReplicationInfo KFGRI)
{
    // Level.TimeDilation = 1.1 * GameSpeed
    return 1.20 / fmin(1.0, (KFGRI.Level.TimeDilation / 1.1));
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    return InDamage;    // no protection from Bloat Bile
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if (   ClassIsChildOf(DmgType, default.DefaultDamageType)
            || ClassIsInArray(default.PerkedDamTypes, DmgType) )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.30 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM79MAmmo') || ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo'))
        return 1.0 + (0.20 * GetClientVeteranSkillLevel(KFPRI)); // one extra medic nade per level

    if ( ClassIsChildOf(AmmoType, class'MP7MAmmo')
            || ClassIsChildOf(AmmoType, class'MP5MAmmo')
            || ClassIsChildOf(AmmoType, class'M7A3MAmmo')
            || ClassIsChildOf(AmmoType, class'KrissMAmmo')
            || ClassIsChildOf(AmmoType, class'BlowerThrowerAmmo')
            || ClassIsChildOf(AmmoType, class'M4203Ammo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType) )
    {
        return 1.0 + 0.05 * float(GetClientVeteranSkillLevel(KFPRI)); // +5% per level
    }
    return 1.0;
}

static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'KatanaPickup') )
        return class'ScrnVetBerserker'.static.GetCostScaling(KFPRI, Item);
    return super.GetCostScaling(KFPRI, Item);
}

static function string GetCustomLevelInfo( byte Level )
{
    local string S;

    S = Default.CustomLevelInfo;
    ReplaceText(S,"%L",string(Level));
    ReplaceText(S,"%x",GetPercentStr(0.30 + 0.05*Level));
    ReplaceText(S,"%a",GetPercentStr(0.05*Level));
    ReplaceText(S,"%v",GetPercentStr(fmin(0.60, 0.30 + 0.05*Level)));
    ReplaceText(S,"%z",string(clamp(Level,1,6)));
    ReplaceText(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)));
    return S;
}

static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    // Field Medic and Combat medic share the same iventory
    return Pickup.default.CorrespondingPerkIndex == 0 || super.OverridePerkIndex(Pickup);
}

defaultproperties
{
    progressArray0(0)=5000
    progressArray0(1)=25000
    progressArray0(2)=100000
    progressArray0(3)=500000
    progressArray0(4)=1500000
    progressArray0(5)=3500000
    progressArray0(6)=5500000

    SkillInfo="PERK SKILLS:|20% faster movement speed|100% larger Medic Gun clip|75% faster attacks with Machete/Katana|Moves faster in Zed Time"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Medic Guns|%a extra Medic ammo|%v better Armor|Up to %z Zed-Time Extensions|%$ discount on Medic Guns/Armor/Katana"

    PerkIndex=9
    OnHUDIcon=              Texture'ScrnTex.Perks.Perk_CombatMedic'
    OnHUDGoldIcon=          Texture'ScrnTex.Perks.Perk_CombatMedic_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))

    PerkedPickups[0]= class'ScrnBalanceSrv.ScrnKatanaPickup'

    VeterancyName="Combat Medic"
    Requirements(0)="Deal %x damage with the Medic Guns"
}
