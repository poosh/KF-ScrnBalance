class ScrnVetFirebug extends ScrnVeterancyTypes
	abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RFlameThrowerDamageStat;
}


static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(Other, class'Flamethrower') || ClassIsChildOf(Other, class'HuskGun')
				|| ClassIsChildOf(Other, class'MAC10MP') || ClassIsChildOf(Other, class'ScrnThompsonInc')
                || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass)  //v3 - custom weapon support
            )
		return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% larger fuel canister
    }
	return 1.0;
}

// more ammo from ammo boxes
static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
	return AddExtraAmmoFor(KFPRI, Other.class);
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(AmmoType,  class'FlameAmmo')
                || ClassIsChildOf(AmmoType,  class'MAC10Ammo')
                || ClassIsChildOf(AmmoType,  class'ScrnThompsonIncAmmo')
                || ClassIsChildOf(AmmoType, class'HuskGunAmmo')
                || ClassIsChildOf(AmmoType, class'TrenchgunAmmo')
                || ClassIsChildOf(AmmoType, class'FlareRevolverAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
            ) {
			if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
				return 1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 60% larger fuel canister
			return 1.6 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6)); // 5% more total fuel per each perk level above 6
		}
		else if ( class'ScrnBalance'.default.Mut.bSpawnBalance && GetClientVeteranSkillLevel(KFPRI) >= 4
                && AmmoType == class'FragAmmo' ) {
            return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI) - 3)); // 1 extra nade per level starting with level 4
        }
        else if ( GetClientVeteranSkillLevel(KFPRI) > 6 && ClassIsChildOf(AmmoType,  class'ScrnM79IncAmmo') ) {
			return 1.0 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI)-6)); //+2 M79Inc nades post level 6
		}
	}
	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

	if ( class<DamTypeBurned>(DmgType) != none || class<DamTypeFlamethrower>(DmgType) != none
		|| class<ScrnDamTypeTrenchgun>(DmgType) != none // only for SE version, cuz it has reduced base damage
        || (!class'ScrnBalance'.default.Mut.bWeaponFix && (class<DamTypeHuskGunProjectileImpact>(DmgType) != none || class<DamTypeFlareProjectileImpact>(DmgType) != none))
		|| ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
	) {
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return float(InDamage) * (1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))); //  Up to 60% extra damage
        return float(InDamage) * (1.30 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
	}

	// +5% husk gun and flare impact damage above level 6
	if ( GetClientVeteranSkillLevel(KFPRI) > 6 && (
			class<DamTypeHuskGunProjectileImpact>(DmgType) != none
			|| class<DamTypeFlareProjectileImpact>(DmgType) != none ) )
	{
		return float(InDamage) * (0.70 + 0.05 * GetClientVeteranSkillLevel(KFPRI));
	}


    //debug feature
    //PlayerController(DamageTaker.Controller).ClientMessage(String(DmgType) @ InDamage);

	return InDamage;
}

// Change effective range on FlameThrower
static function int ExtraRange(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) <= 2 )
		return 0;
	else if ( GetClientVeteranSkillLevel(KFPRI) <= 4 )
		return 1; // 50% Longer Range
	return 2; // 100% Longer Range
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bDealBurningDamage )
    {
		if ( GetClientVeteranSkillLevel(KFPRI) <= 4 )
			return max(1, float(InDamage) * (0.50 - (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))));

        if ( class'ScrnBalance'.default.Mut.bHardcore )
            return max(1, InDamage * 0.10); // limit fire damage resistance to 90%
		return 0; // 100% reduction in damage from fire
	}
	return InDamage;
}

static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
    return class'ScrnBalanceSrv.ScrnFlameNade'; // Alternate Burning Mechanism
}

//can't cook fire nades
static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    return false;
}

//v2.60: +60% faster charge with Husk Gun
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(Other, class'Flamethrower') || ClassIsChildOf(Other, class'HuskGun')
				|| ClassIsChildOf(Other, class'MAC10MP') || ClassIsChildOf(Other, class'ScrnThompsonInc')
				|| ClassIsChildOf(Other, class'Trenchgun')
				|| ClassIsChildOf(Other, class'FlareRevolver') || ClassIsChildOf(Other, class'DualFlareRevolver')
                || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
            )
            return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% faster reload with Flame weapons / Husk Gun charging
    }
	return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnMAC10Pickup' )
        return 1.0; // price lowered to $200, no discount needed

    //add discount on class descenders as well, e.g. ScrnHuskGun
	if ( ClassIsChildOf(Item,  class'FlameThrowerPickup')
            || ClassIsChildOf(Item,  class'MAC10Pickup')
            || ClassIsChildOf(Item,  class'ScrnThompsonIncPickup')
            || ClassIsChildOf(Item,  class'HuskGunPickup')
            || ClassIsChildOf(Item,  class'ScrnM79IncPickup')
            || ClassIsChildOf(Item,  class'TrenchgunPickup')
            || ClassIsChildOf(Item,  class'FlareRevolverPickup')
            || ClassIsChildOf(Item,  class'DualFlareRevolverPickup')
            || ClassIsInArray(default.PerkedPickups, Item) ) //v3 - custom weapon support
    {
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
        else
            return FMax(0.1, 0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // 5% post level 6
    }
	return 1.0;
}

/* No need in extra discount, because firebug already receives ammo bonus for free
//Firebug gets extra ammo bonus (for free), so no need in discount
// Change the cost of particular ammo
// up to 30% discount on Husk gun ammo (c) PooSH, 2012
static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( class'ScrnBalance'.default.Mut.bSpawnBalance )
	{
		if ( ClassIsChildOf(Item, class'HuskGunPickup') )
		{
			return 1.0 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 30% discount on Husk Gun ammo
		}
	}
	return 1.0;
}
*/


// Give Extra Items as default
// v2.55: Level 5 spawns with MAC10, Level6: Flamer
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	local KFHumanPawn HP;

    super.AddDefaultInventory(KFPRI, P);
	HP = KFHumanPawn(P);

    if ( class'ScrnBalance'.default.Mut.bSpawnBalance ) {
        if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
            HP.CreateInventoryVeterancy("ScrnBalanceSrv.ScrnMAC10MP", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnMAC10Pickup'));
        else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 ) {
            HP.CreateInventoryVeterancy("ScrnBalanceSrv.ScrnFlameThrower", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnFlamethrowerPickup'));
        }

    }
    else {
        // If Level 5 or 6, give them a Flame Thrower
        if ( GetClientVeteranSkillLevel(KFPRI) >= 5 )
            HP.CreateInventoryVeterancy("KFMod.FlameThrower", GetInitialCostScaling(KFPRI, class'FlamethrowerPickup'));

        if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
            P.AddShieldStrength(100); //If Level 6, give them Body Armor
    }
}
*/

static function class<DamageType> GetMAC10DamageType(KFPlayerReplicationInfo KFPRI)
{
	return class'DamTypeMAC10MPInc';
}

static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;

	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(0.6 + 0.05*BonusLevel));
	ReplaceText(S,"%m",GetPercentStr(0.6 + 0.10*BonusLevel));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));
	return S;
}

defaultproperties
{
     DefaultDamageType=Class'KFMod.DamTypeBurned'
     DefaultDamageTypeNoBonus=Class'KFMod.DamTypeMAC10MPInc'
    SamePerkAch="OP_Firebug"


     CustomLevelInfo="*** BONUS LEVEL %L|%s extra flame weapon damage|%m faster fire weapon reload|%m faster Husk Gun charging|%s more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|%d discount on flame weapons|Spawn with a Flamethrower"
     SRLevelEffects(0)="*** BONUS LEVEL 0|5% extra flame weapon damage|50% resistance to fire|10% discount on the flame weapons"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% extra flame weapon damage|10% faster fire weapon reload|10% faster Husk Gun charging|10% more flame weapon ammo|60% resistance to fire|20% discount on flame weapons"
     SRLevelEffects(2)="*** BONUS LEVEL 2|20% extra flame weapon damage|20% faster fire weapon reload|20% faster Husk Gun charging|20% more flame weapon ammo|70% resistance to fire|30% discount on flame weapons"
     SRLevelEffects(3)="*** BONUS LEVEL 3|30% extra flame weapon damage|30% faster fire weapon reload|30% faster Husk Gun charging|30% more flame weapon ammo|80% resistance to fire|50% extra Flamethrower range|Grenades set enemies on fire|40% discount on flame weapons"
     SRLevelEffects(4)="*** BONUS LEVEL 4|40% extra flame weapon damage|40% faster fire weapon reload|40% faster Husk Gun charging|40% more flame weapon ammo|90% resistance to fire|50% extra Flamethrower range|Grenades set enemies on fire|50% discount on flame weapons"
     SRLevelEffects(5)="*** BONUS LEVEL 5|50% extra flame weapon damage|50% faster fire weapon reload|50% faster Husk Gun charging|50% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|60% discount on flame weapons|Spawn with a MAC10"
     SRLevelEffects(6)="*** BONUS LEVEL 6|60% extra flame weapon damage|60% faster fire weapon reload|60% faster Husk Gun charging|60% more flame weapon ammo|100% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|70% discount on flame weapons|Spawn with a Flamethrower"
     PerkIndex=5
     OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Firebug'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Firebug_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Firebug_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Firebug_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
     VeterancyName="Firebug"
     Requirements(0)="Deal %x damage with the Flamethrower"
}
