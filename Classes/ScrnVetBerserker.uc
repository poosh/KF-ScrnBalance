class ScrnVetBerserker extends ScrnVeterancyTypes
	abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RMeleeDamageStat;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( class'ScrnBalance'.default.Mut.bWeaponFix && ZombieScrake(Injured) != none 
				&& KFGameReplicationInfo(KFPRI.Level.GRI).GameDiff >= 5.0 ) {
        if ( ClassIsChildOf(DmgType, class'ScrnBalanceSrv.ScrnDamTypeCrossbuzzsaw') )
            InDamage *= 0.8; // 800 * 0.8 = 640
        else if ( DmgType == class'DamTypeCrossbuzzsaw' )
            InDamage *= 0.64; // 100 * 0.64 = 640
    } 
	if( class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bIsMeleeDamage )
	{
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.10;
		if( GetClientVeteranSkillLevel(KFPRI)>6 )
			return float(InDamage) * (1.7 + (0.05 * GetClientVeteranSkillLevel(KFPRI)));

		// Up to 100% increase in Melee Damage
		return float(InDamage) * (1.0 + (0.20 * float(Min(GetClientVeteranSkillLevel(KFPRI), 5))));
	}
 	
	return InDamage;
}

static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	if ( ClassIsChildOf(Other, class'KFMeleeGun') || ClassIsChildOf(Other, class'Crossbuzzsaw') )
	{
		switch ( GetClientVeteranSkillLevel(KFPRI) ) {
            case 0:
				return 1.00;
			case 1:
				return 1.05;
			case 2:
			case 3:
				return 1.10;
			case 4:
				return 1.15;
			case 5:
				return 1.20;
			case 6:
				return 1.25; // 25% increase in wielding Melee Weapon
			default:
				return 1.10 + 0.02 * float(GetClientVeteranSkillLevel(KFPRI));
		}
	}

	return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(Other, class'ScrnChainsaw')
                || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass) )  //v3 - custom weapon support
		{
			if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )    
				return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% larger fuel canister
			return 1.6 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6)); // 5% larger fuel canister for each perk level above 6	
		}
    }
	return 1.0;
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{   
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(AmmoType,  class'ScrnChainsawAmmo') 
                || ClassIsInArray(default.PerkedAmmo, AmmoType) )  //v3 - custom weapon support
        {
			if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
				return 1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 60% in total fuel
			return 1.6 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6)); // +5% in total fuel per each perk level above 6
		}
	}	
	return 1.0;
}

// Make zerker extremely slow while healing
// (c) PooSH, 2012 
// v1.74: 15% speed penalty while holding a non-melee gun
// v1.74: 30% speed penalty while holding a Syringe
// v2.26: 50% of MeleeMovementSpeedModifier is aplied on chansaw too
// v4.39: Test try to give full speed bonus to chainsaw
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
	if ( class'ScrnBalance'.default.Mut.bWeaponFix )
	{
        // Syringe is a child of KFMeleeGun, so need to checkit first!
		if ( Syringe(Weap) != none )
			return -0.15;
		else if ( KFMeleeGun(Weap) == none )
            return -0.15; 
 		else if ( Chainsaw(Weap) != none ) 
			return GetMeleeMovementSpeedModifier(KFPRI); 
	}
	return 0.0;
}


static function float GetMeleeMovementSpeedModifier(KFPlayerReplicationInfo KFPRI)
{
    switch (GetClientVeteranSkillLevel(KFPRI)) {
        case 0:
            return 0.05;
        case 1:
            return 0.10;
        case 2:
            return 0.15;
        case 3:
        case 4:
        case 5:
            return 0.20;
        default:
            return 0.30; // Level 6 - 30% increase in movement speed while wielding Melee Weapon
    }

    //this should never happen
	return 0.3;
}


//fixed post level 6 damage resistance (c) PooSH
static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
    if ( InDamage == 0 )
        return 0;

    // HARDCORE - no damage resistance from Husk's fire damage
    // Except Doom3 Monsters mode, because there is no way to differ Husk damage from Imp or ArchVile damage
	if ( DmgType == class'DamTypeBurned' && class'ScrnBalance'.default.Mut.bHardcore 
            && class'ScrnBalance'.default.Mut.GameRules.GameDoom3Kills == 0 )
        return InDamage;

	if ( DmgType == class'DamTypeVomit' ) {
		switch ( GetClientVeteranSkillLevel(KFPRI) ) {
			case 0:
				InDamage *= 0.90;
                break;
			case 1:
				InDamage *= 0.75;
                break;
			case 2:
				InDamage *= 0.65;
                break;
			case 3:
				InDamage *= 0.50;
                break;
			case 4:
				InDamage *= 0.35;
                break;
			case 5:
				InDamage *= 0.25;
                break;
			default:
				InDamage *= 0.20; // 80% reduced Bloat Bile damage
		}
	}
    else {
        switch ( GetClientVeteranSkillLevel(KFPRI) ) {
            case 0:
                break; // no damage resistance bonus
            case 1:
                InDamage *= 0.95; // was 0.90 in Balance Round 1
                break;
            case 2:
                InDamage *= 0.90; // was 0.85 in Balance Round 1
                break;
            case 3:
                InDamage *= 0.85; // was 0.80 in Balance Round 1
                break;
            case 4:
                InDamage *= 0.80; // was 0.70 in Balance Round 1
                break;
            case 5:
                InDamage *= 0.70; // was 0.60 in Balance Round 1
                break;
            default:
                if ( KFPawn(Instigator) != none )
                    InDamage *= 0.70; // v7.46: player-to-player damage 
                else 
                    InDamage *= 0.60; // 40% reduced Damage(was 50% in Balance Round 1)
        }
    }
    
	return max(1, InDamage); // at least 1 damage must be done
}

static function bool CanBeGrabbed(KFPlayerReplicationInfo KFPRI, KFMonster Other)
{
	return !Other.IsA('ZombieClot');
}

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
	return Min(GetClientVeteranSkillLevel(KFPRI), 4);
}


static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( class'ScrnBalance'.default.Mut.bWeaponFix && ClassIsChildOf(Item, class'CrossbuzzsawPickup') ) {
		return fmax(0.5, 1.0 - (0.05 * GetClientVeteranSkillLevel(KFPRI))); // Up to 30% discount buzzsaw blades - to compensate SC damage resistance
	}

	return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if  ( ClassIsChildOf(Item, class'ChainsawPickup') || ClassIsChildOf(Item, class'KatanaPickup') 
            || ClassIsChildOf(Item, class'ClaymoreSwordPickup') 
            || ClassIsChildOf(Item, class'DwarfAxePickup') 
            || ClassIsChildOf(Item, class'CrossbuzzsawPickup') || ClassIsChildOf(Item, class'ScythePickup') 
			|| Item == class'KFMod.AxePickup' || Item == class'KFMod.MachetePickup' // only for KFMod, expensive versions
            || ClassIsInArray(default.PerkedPickups, Item) //v3 - custom weapon support
        ) 
    {
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
        else
            return FMax(0.1, 0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // 5% post level 6
    }
	return 1.0;
}


/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super.AddDefaultInventory(KFPRI, P);
	if ( class'ScrnBalance'.default.Mut.bSpawnBalance ) 
	{
		//(c) PooSH, 2012-2013
		//Level 5 spawns with Axe
		//Level 6 spawns with Chainsaw
        if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
			if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
				KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnAxe", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnAxePickup'));
			else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
                KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnChainsaw", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnChainsawPickup'));
		}
		else {
			if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
				KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Axe", GetInitialCostScaling(KFPRI, class'KFMod.AxePickup'));
			else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
                KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Chainsaw", GetInitialCostScaling(KFPRI, class'KFMod.ChainsawPickup'));
		}
	}
	else
	{
        if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
			if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
				KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnMachete", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnMachetePickup'));	
			else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
				KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnAxe", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnAxePickup'));		
		}
		else {
			if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
				KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Machete", GetInitialCostScaling(KFPRI, class'KFMod.MachetePickup'));	
			else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
				KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Axe", GetInitialCostScaling(KFPRI, class'KFMod.AxePickup'));
		}
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
	ReplaceText(S,"%s",GetPercentStr(1.0 + 0.05*BonusLevel));
	ReplaceText(S,"%m",GetPercentStr(0.25 + 0.02*BonusLevel));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));

	return S;
}

defaultproperties
{
     DefaultDamageType=Class'KFMod.DamTypeMelee'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeZerkerBase'
     
     SRLevelEffects(0)="*** BONUS LEVEL 0|10% extra melee damage|5% faster melee movement|10% less damage from Bloat Bile|10% discount on Melee Weapons|Can't be grabbed by Clots"
     SRLevelEffects(1)="*** BONUS LEVEL 1|20% extra melee damage|5% faster melee attacks|10% faster melee movement|25% less damage from Bloat Bile|5% resistance to all damage|20% discount on Melee Weapons|Can't be grabbed by Clots"
     SRLevelEffects(2)="*** BONUS LEVEL 2|40% extra melee damage|10% faster melee attacks|15% faster melee movement|35% less damage from Bloat Bile|10% resistance to all damage|30% discount on Melee Weapons|Can't be grabbed by Clots|Zed-Time can be extended by killing an enemy while in slow motion"
     SRLevelEffects(3)="*** BONUS LEVEL 3|60% extra melee damage|10% faster melee attacks|20% faster melee movement|50% less damage from Bloat Bile|15% resistance to all damage|40% discount on Melee Weapons|Can't be grabbed by Clots|Up to 2 Zed-Time Extensions"
     SRLevelEffects(4)="*** BONUS LEVEL 4|80% extra melee damage|15% faster melee attacks|20% faster melee movement|65% less damage from Bloat Bile|20% resistance to all damage|50% discount on Melee Weapons|Can't be grabbed by Clots|Up to 3 Zed-Time Extensions"
     SRLevelEffects(5)="*** BONUS LEVEL 5|100% extra melee damage|20% faster melee attacks|20% faster melee movement|75% less damage from Bloat Bile|30% resistance to all damage|60% discount on Melee Weapons|Spawn with an Axe|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     SRLevelEffects(6)="*** BONUS LEVEL 6|100% extra melee damage|25% faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|70% discount on Melee Weapons|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     CustomLevelInfo="*** BONUS LEVEL %L|%s extra melee damage|%m faster melee attacks|30% faster melee movement|80% less damage from Bloat Bile|40% resistance to all damage|%d discount on Melee Weapons|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     PerkIndex=4
     VeterancyName="Berserker"
     Requirements(0)="Deal %x damage with melee weapons"
	 
     OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Berserker'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Berserker_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'KillingFloorHUD.Perks.Perk_Berserker',StarIcon=Texture'KillingFloorHUD.HUD.Hud_Perk_Star',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Berserker_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Berserker_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
}
