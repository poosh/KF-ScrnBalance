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
		return 1.0 + fmin(0.75, 0.15 * float(GetClientVeteranSkillLevel(KFPRI)));
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
    return (1.0 + fmin(0.18, 0.03 * GetClientVeteranSkillLevel(KFPRI))) / fmin(1.0, (KFGRI.Level.TimeDilation / 1.1));
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    return InDamage;    // no protection from Bloat Bile
}

static function float GetBodyArmorDamageModifier(KFPlayerReplicationInfo KFPRI)
{
    return 1.0 - fmin(0.6, 0.10 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 50% improvement of Body Armor
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;
        
    if (   ClassIsChildOf(DmgType, default.DefaultDamageType) 
        || ClassIsInArray(default.PerkedDamTypes, DmgType) )
    {
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return float(InDamage) * (1.00 + (0.10 * float(Min(GetClientVeteranSkillLevel(KFPRI), 5)))); // Up to 50% increase in Damage with Pistols
        return float(InDamage) * (1.20 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
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
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;
	
	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(0.5 + 0.05*BonusLevel));
	ReplaceText(S,"%a",GetPercentStr(1.0 + 0.05*BonusLevel));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));    
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
    
    SRLevelEffects(0)="*** BONUS LEVEL 0|5% more damage with Medic Guns|Moves faster in Zed Time|10% discount on Medic Guns and Armor"
    SRLevelEffects(1)="*** BONUS LEVEL 1|10% more damage with Medic Guns| 20% larger Medic Gun clip| 5% more Medic ammo| 3% faster movement speed|15% faster attacks with Machete/Katana|Up to 1 Zed-Time Extension|Moves faster in Zed Time|10% better Body Armor|20% discount on Medic Guns/Armor/Katana"
    SRLevelEffects(2)="*** BONUS LEVEL 2|20% more damage with Medic Guns| 40% larger Medic Gun clip|10% more Medic ammo| 6% faster movement speed|30% faster attacks with Machete/Katana|Up to 2 Zed-Time Extensions|Moves faster in Zed Time|20% better Body Armor|30% discount on Medic Guns/Armor/Katana"
    SRLevelEffects(3)="*** BONUS LEVEL 3|30% more damage with Medic Guns| 60% larger Medic Gun clip|15% more Medic ammo| 9% faster movement speed|45% faster attacks with Machete/Katana|Up to 3 Zed-Time Extensions|Moves faster in Zed Time|30% better Body Armor|40% discount on Medic Guns/Armor/Katana"
    SRLevelEffects(4)="*** BONUS LEVEL 4|40% more damage with Medic Guns| 80% larger Medic Gun clip|20% more Medic ammo|12% faster movement speed|60% faster attacks with Machete/Katana|Up to 4 Zed-Time Extensions|Moves faster in Zed Time|40% better Body Armor|50% discount on Medic Guns/Armor/Katana"
    SRLevelEffects(5)="*** BONUS LEVEL 5|50% more damage with Medic Guns|100% larger Medic Gun clip|25% more Medic ammo|15% faster movement speed|75% faster attacks with Machete/Katana|Up to 5 Zed-Time Extensions|Moves faster in Zed Time|50% better Body Armor|60% discount on Medic Guns/Armor/Katana|Spawn with MP7M"
    SRLevelEffects(6)="*** BONUS LEVEL 6|50% more damage with Medic Guns|100% larger Medic Gun clip|30% more Medic ammo|18% faster movement speed|75% faster attacks with Machete/Katana|Up to 6 Zed-Time Extensions|Moves faster in Zed Time|60% better Body Armor|70% discount on Medic Guns/Armor/Katana|Spawn with MP7M and Katana"
    CustomLevelInfo="*** BONUS LEVEL %L|%s more damage with Medic Guns|18% faster movement speed|100% larger Medic Gun clip|%a more Medic ammo|7% faster attacks with Machete/Katana|Up to 6 Zed-Time Extensions|Moves faster in Zed Time|60% better Body Armor|%d discount on Medic Guns and Armor|Spawn with MP7M and Katana"
    
    PerkIndex=9
    OnHUDIcon=              Texture'ScrnTex.Perks.Perk_CombatMedic'
    OnHUDGoldIcon=          Texture'ScrnTex.Perks.Perk_CombatMedic_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_CombatMedic_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    
    PerkedPickups[0]= class'ScrnBalanceSrv.ScrnKatanaPickup'
    
    VeterancyName="Combat Medic"
    Requirements(0)="Deal %x damage with the Medic Guns"    
}