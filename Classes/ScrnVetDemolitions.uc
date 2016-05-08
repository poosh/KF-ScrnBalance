class ScrnVetDemolitions extends ScrnVeterancyTypes
	abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RExplosivesDamageStat;
}


static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo') )
        return 1.0; // no extra medic grenades
   
	if ( ClassIsChildOf(AmmoType, class'FragAmmo') ) {
    // Up to 6 extra Grenades
		return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI))); 
    }
    else if ( ClassIsChildOf(AmmoType, class'PipeBombAmmo') ) {
		// Up to 6 extra for a total of 8 Remote Explosive Devices
		return 1.0 + (0.5 * float(GetClientVeteranSkillLevel(KFPRI)));
	}
	else if ( ClassIsChildOf(AmmoType, class'ScrnLAWAmmo')
				|| ClassIsChildOf(AmmoType, class'ScrnHRLAmmo')
				|| ClassIsInArray(default.PerkedAmmo, AmmoType) //v3 - custom weapon support
			) {
		// ScrnLAW has base ammo 16
		// ScrnHRLAmmo has base ammo 20, +2 rockets per perk level
		return 1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)));
	}
	else if ( ClassIsChildOf(AmmoType, class'LAWAmmo') ) {
		// Modified in Balance Round 5 to be up to 100% extra ammo
		return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI)));
	}
    else if ( class'ScrnBalance'.default.Mut.bWeaponFix && ClassIsChildOf(AmmoType, class'M203Ammo') ) {
		return 1.0 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI))); //1 extra nade per level [Aze]
    }
    else if ( GetClientVeteranSkillLevel(KFPRI) > 6 ) {
		if ( ClassIsChildOf(AmmoType, class'M79Ammo') || ClassIsChildOf(AmmoType, class'M32Ammo') 
				|| ClassIsChildOf(AmmoType, class'M203Ammo') )
            return 1.0 + (0.083334 * float(GetClientVeteranSkillLevel(KFPRI)-6)); //+1 M203 or +2 M79 or +3 M32 nades post level 6
    }

	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

	if ( (class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bIsExplosive) 
            || class<DamTypeRocketImpact>(DmgType) != none )
	{
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return float(InDamage) * (1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))); //  Up to 60% extra damage
        return float(InDamage) * (1.30 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
	}

	return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( (class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bIsExplosive) 
            || class<DamTypeRocketImpact>(DmgType) != none )
		return float(InDamage) * fmax(0.75 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI))),0.05f);

    return InDamage;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM79MPickup') )
        return 1.0; //no discount on medic nade launchers
        
    if ( class'ScrnBalance'.default.Mut.bSpawnBalance ) {
        // Applied pipebomb discount to M79 (c) PooSH, 2012
        if ( ClassIsChildOf(Item, class'PipeBombPickup') 
            || (ClassIsChildOf(Item, class'M79Pickup') && !ClassIsChildOf(Item, class'ScrnM79IncPickup')) )
        {
            if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
                return 0.48 - (0.04 * GetClientVeteranSkillLevel(KFPRI)); // Up to 76% discount on M79 to match spawn value [Aze]
            return fmax(0.1, 0.24 - (0.02 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // Up to 76% discount on M79 to match spawn value [Aze]
        }
        else if ( ClassIsChildOf(Item, class 'M32Pickup')
                    || ClassIsChildOf(Item, class 'LawPickup') 
                    || ClassIsChildOf(Item, class 'M4203Pickup') 
                    || ClassIsChildOf(Item, class 'SPGrenadePickup')  
                    || ClassIsChildOf(Item, class 'SealSquealPickup') || ClassIsChildOf(Item, class 'SeekerSixPickup')
                    || ClassIsInArray(default.PerkedPickups, Item) ) 
        {
            if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
                return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
            else 
                return FMax(0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6)),0.1); // 5% post level 6
        }
    }
    else {
        if ( ClassIsChildOf(Item, class'PipeBombPickup') )
        {
            // Todo, this won't need to be so extreme when we set up the system to only allow him to buy it perhaps
            return fmax(0.1, 0.5 - (0.04 * GetClientVeteranSkillLevel(KFPRI))); // Up to 74% discount on PipeBomb(changed to 68% in Balance Round 1, upped to 74% in Round 4)
        }
        else if ( Item == class'M79Pickup' || ClassIsChildOf(Item, class 'M32Pickup')
            || ClassIsChildOf(Item, class 'LawPickup') 
			|| ClassIsChildOf(Item, class 'M4203Pickup')  
			|| ClassIsChildOf(Item, class 'SPGrenadePickup')  
			|| ClassIsChildOf(Item, class 'SealSquealPickup') || ClassIsChildOf(Item, class 'SeekerSixPickup')			
			|| ClassIsInArray(default.PerkedPickups, Item) )
        {
            return fmax(0.1, 0.90 - (0.10 * GetClientVeteranSkillLevel(KFPRI))); // Up to 70% discount on M79/M32
        }
    }

	return 1.0;
}

// Change the cost of particular ammo
// up to 30% discount on hand nades (c) PooSH, 2012
static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM79MPickup') )
        return 1.0; //no discount on medic nade launchers
        
	if ( ClassIsChildOf(Item, class'PipeBombPickup') )
	{
        if ( class'ScrnBalance'.default.Mut.bSpawnBalance )
            return fmax(0.1, 0.48 - (0.04 * GetClientVeteranSkillLevel(KFPRI))); // Up to 76% discount on PipeBomb
        else    
            return fmax(0.1, 0.5 - (0.04 * GetClientVeteranSkillLevel(KFPRI))); // Up to 74% discount on PipeBomb(changed to 68% in Balance Round 3, upped to 74% in Round 4)
	}
	else if ( ClassIsChildOf(Item, class'M79Pickup') || ClassIsChildOf(Item, class'M32Pickup')
            || ClassIsChildOf(Item, class'LAWPickup') || ClassIsChildOf(Item, class'M4203Pickup') 
            || ClassIsChildOf(Item, class'SPGrenadePickup')
            || ClassIsChildOf(Item, class'SealSquealPickup') || ClassIsChildOf(Item, class'SeekerSixPickup') 
            || (class'ScrnBalance'.default.Mut.bSpawnBalance && ClassIsChildOf(Item, class'FragPickup'))
            || ClassIsInArray(default.PerkedPickups, Item)  
        ) {
		return fmax(0.5, 1.0 - (0.05 * GetClientVeteranSkillLevel(KFPRI))); // Up to 30% discount on Grenade Launcher and LAW Ammo(Balance Round 5)
	}

	return 1.0;
}

// Give Extra Items as default
/**
 * v2.45+
 * Level 5: + 5 nades
 * Level 6: M79 + 5 nades
 * @author PooSH
 */
/* 
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	local KFHumanPawn HP;

    super.AddDefaultInventory(KFPRI, P);
	HP = KFHumanPawn(P);
	if ( class'ScrnBalance'.default.Mut.bSpawnBalance ) {

		if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
			GiveNades(HP, 7);
		if ( GetClientVeteranSkillLevel(KFPRI) >= 6) 
			HP.CreateInventoryVeterancy("KFMod.M79GrenadeLauncher", GetInitialCostScaling(KFPRI, class'M79Pickup'));
	}
	else 
	{
		// If Level 5, give them a pipe bomb
		if ( GetClientVeteranSkillLevel(KFPRI) >= 5 ) {
            HP.CreateInventoryVeterancy("KFMod.PipeBombExplosive", GetInitialCostScaling(KFPRI, class'PipeBombPickup'));
        }
		// If Level 6, give them a M79Grenade launcher and pipe bomb
		if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
			HP.CreateInventoryVeterancy("KFMod.M79GrenadeLauncher", GetInitialCostScaling(KFPRI, class'M79Pickup'));
	}
}
*/

static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;

	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(0.6 + 0.05*BonusLevel));
	ReplaceText(S,"%r",GetPercentStr(fmin(0.95, 0.55 + 0.05*BonusLevel)));
	ReplaceText(S,"%g",string(BonusLevel+6));
	ReplaceText(S,"%x",string(8+BonusLevel));
	ReplaceText(S,"%y",GetPercentStr(0.76 + fmin(0.14, 0.02*BonusLevel)));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));

	return S;
}

/*
// explosive rounds
// adding P, S switches to bonuses makes zed explode when die from that weapon
static function bool KilledShouldExplode(KFPlayerReplicationInfo KFPRI, KFPawn P)
{
    local class<KFWeaponDamageType> DT;
    
    if ( ScrnHumanPawn(P) != none )
        DT = class<KFWeaponDamageType>(ScrnHumanPawn(P).LastDamageTypeMade);
                       // explosions can't cause another explosion
    if ( DT != none && !DT.default.bIsExplosive && ClassIsInArray(default.PerkedDamTypes, DT) )
        return true;

    return super.KilledShouldExplode(KFPRI, P);
}
*/

defaultproperties
{
     DefaultDamageType=Class'KFMod.DamTypeLAW'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultDemoBase'
     
     CustomLevelInfo="*** BONUS LEVEL %L|%s extra Explosives damage|%r resistance to Explosives|+%g Rocket, M203 and Hand Grenade capacity|Can carry %x Remote Explosives|%y discount on Explosives|%d off Remote Explosives|30% discount on Grenades and Rockets|Spawn with a M79"
     SRLevelEffects(0)="*** BONUS LEVEL 0|5% extra Explosives damage|25% resistance to Explosives|10% discount on Explosives|50% off Remote Explosives"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% extra Explosives damage|30% resistance to Explosives|+1 Rocket, M203 and Hand Grenade capacity|Can carry 3 Remote Explosives|20% discount on Explosives|54% off Remote Explosives and M79|5% discount on Grenades and Rockets"
     SRLevelEffects(2)="*** BONUS LEVEL 2|20% extra Explosives damage|35% resistance to Explosives|+2 Rocket, M203 and Hand Grenade capacity|Can carry 4 Remote Explosives|30% discount on Explosives|58% off Remote Explosives and M79|10% discount on Grenades and Rockets"
     SRLevelEffects(3)="*** BONUS LEVEL 3|30% extra Explosives damage|40% resistance to Explosives|+3 Rocket, M203 and Hand Grenade capacity|Can carry 5 Remote Explosives|40% discount on Explosives|62% off Remote Explosives and M79|15% discount on Grenades and Rockets"
     SRLevelEffects(4)="*** BONUS LEVEL 4|40% extra Explosives damage|45% resistance to Explosives|+4 Rocket, M203 and Hand Grenade capacity|Can carry 6 Remote Explosives|50% discount on Explosives|66% off Remote Explosives and M79|20% discount on Grenades and Rockets"
     SRLevelEffects(5)="*** BONUS LEVEL 5|50% extra Explosives damage|50% resistance to Explosives|+5 Rocket, M203 and Hand Grenade capacity|Can carry 7 Remote Explosives|60% discount on Explosives|70% off Remote Explosives|25% discount on Grenades and Rockets|Spawn with extra hand grenades"
     SRLevelEffects(6)="*** BONUS LEVEL 6|60% extra Explosives damage|55% resistance to Explosives|+6 Rocket, M203 and Hand Grenade capacity|Can carry 8 Remote Explosives|70% discount on Explosives|74% off Remote Explosives|30% discount on Grenades and Rockets|Spawn with a M79"
     PerkIndex=6
     OnHUDIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition',StarIcon=Texture'KillingFloorHUD.HUD.Hud_Perk_Star',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Demolition_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Demolition_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
     VeterancyName="Demolitions"
     Requirements(0)="Deal %x damage with the Explosives"
}
