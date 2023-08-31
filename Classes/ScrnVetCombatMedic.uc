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

static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    return false;
}

static function float GetSyringeChargeRate(KFPlayerReplicationInfo KFPRI)
{
    return 1.50;  // Recharges 50% faster
}

static function float GetHealPotency(KFPlayerReplicationInfo KFPRI)
{
    return 1.30;  // Heals for 30% more
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

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( !DmgType.default.bArmorStops && class'ScrnBalance'.default.Mut.bHardcore ) {
        return InDamage * 1.50;  // extra damage  from Siren Scream in Hardcore mode
    }
    return InDamage;    // no protection from Bloat Bile
}

// Reduce damage when wearing Armor
static function int ShieldReduceDamage(KFPlayerReplicationInfo KFPRI, ScrnHumanPawn Injured, Pawn Instigator,
        int InDamage, class<DamageType> DmgType)
{
    if ( KFHumanPawn(Instigator) != none )
        return InDamage;  // no resistance to human damage

    return super.ShieldReduceDamage(KFPRI, Injured, Instigator, InDamage, DmgType);
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if (KFGameType(KFPRI.Level.Game) != none && KFGameType(KFPRI.Level.Game).bZEDTimeActive) {
        InDamage *= 2;
    }

    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( ClassIsChildOf(DmgType, default.DefaultDamageType)
            || ClassIsInArray(default.PerkedDamTypes, DmgType) )
    {
        // 30% base bonus + 5% per level
        InDamage *= 1.3001 + 0.05 * GetClientVeteranSkillLevel(KFPRI);
    }
    return InDamage;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnM79MAmmo') || ClassIsChildOf(AmmoType, class'ScrnM203MAmmo'))
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
    S = Repl(S,"%L",string(Level), true);
    S = Repl(S,"%x",GetPercentStr(0.30 + 0.05*Level), true);
    S = Repl(S,"%a",GetPercentStr(0.05*Level), true);
    S = Repl(S,"%v",GetPercentStr(fmin(0.60, 0.30 + 0.05*Level)), true);
    S = Repl(S,"%z",string(clamp(Level,1,6)), true);
    S = Repl(S,"%$",GetPercentStr(fmin(0.90, 0.30 + 0.05*Level)), true);
    return S;
}

// Combat Medic cannot see other player health bars
static function bool ShowEnemyHealthBars(KFPlayerReplicationInfo KFPRI, KFPlayerReplicationInfo EnemyPRI)
{
    return false;
}


defaultproperties
{
    SkillInfo="PERK SKILLS:|30% faster healing|50% faster Syringe recharge|20% faster movement speed|100% larger Medic Gun clip|75% faster attacks with Machete/Katana|Double damage in Zed Time"
    CustomLevelInfo="PERK BONUSES (LEVEL %L):|%x more damage with Medic Guns|%a extra Medic ammo|%v better Armor|Up to %z Zed-Time Extensions|%$ discount on Medic Guns/Armor/Katana"

    PerkIndex=9
    RelatedPerkIndex=0  // medic
    OnHUDIcon=              Texture'ScrnTex.Perks.Perk_CombatMedic'
    OnHUDGoldIcon=          Texture'ScrnTex.Perks.Perk_CombatMedic_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gold',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))

    PerkedPickups[0]= class'ScrnKatanaPickup'

    VeterancyName="Combat Medic"
    ShortName="CBT"
    bHardcoreReady=True
    Requirements(0)="Deal %x damage with the Medic Guns"
    progressArray0( 0)=5000
    progressArray0( 1)=25000
    progressArray0( 2)=100000
    progressArray0( 3)=500000
    progressArray0( 4)=1000000
    progressArray0( 5)=2000000
    progressArray0( 6)=3500000
    progressArray0( 7)=5500000
    progressArray0( 8)=8000000
    progressArray0( 9)=11000000
    progressArray0(10)=14500000
    progressArray0(11)=18500000
    progressArray0(12)=23000000
    progressArray0(13)=28000000
    progressArray0(14)=33500000
    progressArray0(15)=39500000
    progressArray0(16)=46000000
    progressArray0(17)=53000000
    progressArray0(18)=60500000
    progressArray0(19)=68500000
    progressArray0(20)=77000000
    progressArray0(21)=96000000
    progressArray0(22)=116000000
    progressArray0(23)=136000000
    progressArray0(24)=156000000
    progressArray0(25)=177000000
    progressArray0(26)=199000000
    progressArray0(27)=221000000
    progressArray0(28)=243000000
    progressArray0(29)=266000000
    progressArray0(30)=290000000
    progressArray0(31)=319000000
    progressArray0(32)=348000000
    progressArray0(33)=378000000
    progressArray0(34)=409000000
    progressArray0(35)=440000000
    progressArray0(36)=471000000
    progressArray0(37)=503000000
    progressArray0(38)=536000000
    progressArray0(39)=569000000
    progressArray0(40)=602000000
    progressArray0(41)=641000000
    progressArray0(42)=681000000
    progressArray0(43)=721000000
    progressArray0(44)=761000000
    progressArray0(45)=802000000
    progressArray0(46)=844000000
    progressArray0(47)=886000000
    progressArray0(48)=928000000
    progressArray0(49)=971000000
    progressArray0(50)=1015000000
    progressArray0(51)=1064000000
    progressArray0(52)=1113000000
    progressArray0(53)=1163000000
    progressArray0(54)=1214000000
    progressArray0(55)=1265000000
    progressArray0(56)=1316000000
    progressArray0(57)=1368000000
    progressArray0(58)=1421000000
    progressArray0(59)=1474000000
    progressArray0(60)=1527000000
    progressArray0(61)=1586000000
    progressArray0(62)=1646000000
    progressArray0(63)=1706000000
    progressArray0(64)=1766000000
    progressArray0(65)=1827000000
    progressArray0(66)=1889000000
    progressArray0(67)=1951000000
    progressArray0(68)=2013000000
    progressArray0(69)=2076000000
    progressArray0(70)=2140000000
}
