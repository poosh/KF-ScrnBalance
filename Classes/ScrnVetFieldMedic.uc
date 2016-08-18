class ScrnVetFieldMedic extends ScrnVeterancyTypes
	abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RDamageHealedStat;
}

// Give Medic normal hand nades again - he should buy medic nade lauchers for healing nades
static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
	if ( !class'ScrnBalance'.default.Mut.bWeaponFix ) 
        return class'MedicNade'; // Grenade detonations heal nearby teammates, and cause enemies to be poisoned

	return super.GetNadeType(KFPRI);
}
//can't cook medic nades
static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
  return GetNadeType(KFPRI) != class'MedicNade';
}

static function float GetSyringeChargeRate(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
		return 1.10;
	else if ( GetClientVeteranSkillLevel(KFPRI) <= 4 )
		return 1.25 + (0.25 * float(GetClientVeteranSkillLevel(KFPRI)));
	else if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
		return 2.50; // Recharges 150% faster
	return 2.4 + (0.1 * float(GetClientVeteranSkillLevel(KFPRI))); // Level 6 - Recharges 200% faster
}

static function float GetHealPotency(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
		return 1.10;
	else if ( GetClientVeteranSkillLevel(KFPRI) <= 2 )
		return 1.25;
	else if ( GetClientVeteranSkillLevel(KFPRI) <= 5 )
		return 1.5;
	return 1.75;  // Heals for 75% more
}

static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
		if ( ClassIsChildOf(Other, class'Syringe') ) {
			if (  GetClientVeteranSkillLevel(KFPRI) > 6 )
				return 1.3 + (0.05 * fmin(6, GetClientVeteranSkillLevel(KFPRI)));
			return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI)));
		}
	}
	return 1.0;
}

// give medic speed bonus while holding syringe 
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
	if ( class'ScrnBalance'.default.Mut.bWeaponFix )
	{
		if ( Syringe(Weap) != none )
			return class'ScrnBalanceSrv.ScrnHumanPawn'.default.BaseMeleeIncrease;
	}	
    return 0.0;
}

static function float GetMovementSpeedModifier(KFPlayerReplicationInfo KFPRI, KFGameReplicationInfo KFGRI)
{
	// (c) PooSH, 2012
	//if ( class'ScrnBalance'.default.Mut.bWeaponFix ) SetSyringeSpeed(KFHumanPawn(P), true); 

	if ( class'ScrnBalance'.default.Mut.bWeaponFix )
	{
		//reduce speed bonus to 18% max no matter of difficulty
		return 1.0 + fmin(0.3, 0.03 * GetClientVeteranSkillLevel(KFPRI));
	}
	
	// Medic movement speed reduced in Balance Round 2(limited to Suicidal and HoE in Round 7)
	if ( KFGRI.GameDiff >= 5.0 )
	{
		if ( GetClientVeteranSkillLevel(KFPRI) <= 2 )
		{
			return 1.0;
		}

		return 1.05 + FMin(0.05 * float(GetClientVeteranSkillLevel(KFPRI) - 3),0.55); // Moves up to 20% faster
	}

	if ( GetClientVeteranSkillLevel(KFPRI) <= 1 )
		return 1.0;
	return 1.05 + FMin(0.05 * float(GetClientVeteranSkillLevel(KFPRI) - 2),0.55); // Moves up to 25% faster
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( DmgType == class'DamTypeVomit' )
	{
		// Medics don't damage themselves with the bile shooter
        if( Injured == Instigator )
		{
            return 0;
		}
		
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 0.90;
		else if ( GetClientVeteranSkillLevel(KFPRI) == 1 )
			return float(InDamage) * 0.75;
		else if ( GetClientVeteranSkillLevel(KFPRI) <= 4 )
			return float(InDamage) * 0.50;
		return float(InDamage) * 0.25; // 75% decrease in damage from Bloat's Bile
	}
	return InDamage;
}


//v2.55 up to 50% faster reload with MP5/MP7
//v9.17: removed reload bonus; base reloads made faster; short reloads introduced
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( ClassIsInArray(default.PerkedWeapons, Other) )
        return 1.0 + (0.1 * fmin(5, float(GetClientVeteranSkillLevel(KFPRI))));

	return 1.0;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(Other, class'ScrnMP7MMedicGun') || ClassIsChildOf(Other, class'ScrnMP5MMedicGun')
				|| ClassIsChildOf(Other, class'M7A3MMedicGun') || ClassIsChildOf(Other, class'KrissMMedicGun')
				|| ClassIsChildOf(Other, class'ScrnM4203MMedicGun')
                || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass) ) //v3 - custom weapon support
            return 1.0 + (0.20 * FMin(GetClientVeteranSkillLevel(KFPRI), 5.0)); // up to 100% increase in Medic weapon ammo carry
    }        
	return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( MP7MAmmo(Other) != none || MP5MAmmo(Other) != none || M7A3MAmmo(Other) != none
                || KrissMAmmo(Other) != none || BlowerThrowerAmmo(Other) != none
                //|| ScrnM203MAmmo(Other) != none
                || ClassIsInArray(default.PerkedAmmo, Other.class) ) //v3 - custom weapon support
            return 1.0 + (0.20 * FMin(GetClientVeteranSkillLevel(KFPRI), 5.0)); // 100% increase in MP7 Medic weapon ammo carry
    }
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
	if ( Item == class'Vest' || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnVestPickup')
				|| ClassIsChildOf(Item, class'MP7MPickup') 
                || ClassIsChildOf(Item, class'MP5MPickup') 
                || ClassIsChildOf(Item, class'M7A3MPickup')
                || ClassIsChildOf(Item, class'KrissMPickup')
                || ClassIsChildOf(Item, class'BlowerThrowerPickup')
                || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM79MPickup')
                || ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') 
            || ClassIsInArray(default.PerkedPickups, Item) ) 
    {
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
        else
            return FMax(0.1, 0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // 5% post level 6
	}
	return 1.0;
}

// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier(KFPlayerReplicationInfo KFPRI)
{
    local float MinValue;
    
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        MinValue = 0.50; // limit armor mod to 50%
    else 
        MinValue = 0.25; // up to 75% Better Body Armor
        
    if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
        if (GetClientVeteranSkillLevel(KFPRI) <= 6) //
            return  fmax(MinValue, 1.0 - (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))); // Up to 60% improvement of Body Armor
        return fmax(MinValue, 0.70 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI))));
    }

    if ( GetClientVeteranSkillLevel(KFPRI) <= 5 )
        return 1.0 - (0.10 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 50% improvement of Body Armor
	return MinValue; // Level 6 - 75% Better Body Armor
}



// Give Extra Items as Default
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	// If Level 5 or Higher, give them Body Armor
	if ( GetClientVeteranSkillLevel(KFPRI) >= 5 )
		P.AddShieldStrength(100);
	// If Level 6, give them a Medic Gun
	if ( GetClientVeteranSkillLevel(KFPRI) >= 6 ) {
		if ( class'ScrnBalance'.default.Mut.bWeaponFix )
			KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnMP7MMedicGun", GetInitialCostScaling(KFPRI, class'ScrnMP7MPickup'));
		else
            KFHumanPawn(P).CreateInventoryVeterancy("KFMod.MP7MMedicGun", GetInitialCostScaling(KFPRI, class'MP7MPickup'));
    }
    //REMOVE BEFORE RELEASE!!!
    // if ( class'ScrnBalance'.default.bBeta )
        //KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnM79M", 0);
        
    super.AddDefaultInventory(KFPRI, P);
}
*/

static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;
	
	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(2.0 + 0.1*BonusLevel));
	ReplaceText(S,"%m",GetPercentStr(fmin(0.3, 0.18 + 0.03*BonusLevel)));
	ReplaceText(S,"%a",GetPercentStr(fmin(0.75, 0.6 + 0.05*BonusLevel)));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));    
	ReplaceText(S,"%f",GetPercentStr(fmin(0.95, 0.87 + 0.01*BonusLevel)));
	return S;
}

// allow medic to see NPC's health
static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
	local KF_StoryNPC_Spawnable NPC;
	local HUDKillingFloor HKF;
	local float MaxDistance;

	if ( GetClientVeteranSkillLevel(KFPRI) > 0 )
	{
		HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
		if ( HKF == none || Pawn(C.ViewPort.Actor.ViewTarget)==none || Pawn(C.ViewPort.Actor.ViewTarget).Health<=0 )
			return;

		switch ( GetClientVeteranSkillLevel(KFPRI) )
		{
			case 0: case 1:
				MaxDistance = 160; // 20% (160 units)
				break;
			case 2:
				MaxDistance = 320; // 40% (320 units)
				break;
			case 3:
				MaxDistance = 480; // 60% (480 units)
				break;
			case 4:
				MaxDistance = 640; // 80% (640 units)
				break;
			default:
				MaxDistance = 800; // 100% (800 units)
				break;
		}

		foreach C.ViewPort.Actor.VisibleCollidingActors(class'KF_StoryNPC_Spawnable',NPC,MaxDistance,C.ViewPort.Actor.CalcViewLocation)
		{
			if ( NPC.Health > 0 /* && NPC.bActive */ && !NPC.bShowHealthBar )
				HKF.DrawHealthBar(C, NPC, NPC.Health, NPC.HealthMax , 50.0);
		}
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

    progressArray0(0)=100
    progressArray0(1)=500
    progressArray0(2)=2000
    progressArray0(3)=10000
    progressArray0(4)=30000
    progressArray0(5)=70000
    progressArray0(6)=110000

    SRLevelEffects(0)="*** BONUS LEVEL 0| 10% faster Syringe recharge|10% more potent medical injections|10% less damage from Bloat Bile|10% discount on Medic Guns and Armor"
    SRLevelEffects(1)="*** BONUS LEVEL 1| 25% faster Syringe recharge|25% more potent medical injections|25% less damage from Bloat Bile| 3% faster movement speed| 20% larger Medic Gun clip|10% better Body Armor|20% discount on Medic Guns and Armor"
    SRLevelEffects(2)="*** BONUS LEVEL 2| 50% faster Syringe recharge|25% more potent medical injections|50% less damage from Bloat Bile| 6% faster movement speed| 40% larger Medic Gun clip|20% better Body Armor|30% discount on Medic Guns and Armor"
    SRLevelEffects(3)="*** BONUS LEVEL 3| 75% faster Syringe recharge|50% more potent medical injections|50% less damage from Bloat Bile| 9% faster movement speed| 60% larger Medic Gun clip|30% better Body Armor|40% discount on Medic Guns and Armor"
    SRLevelEffects(4)="*** BONUS LEVEL 4|100% faster Syringe recharge|50% more potent medical injections|50% less damage from Bloat Bile|12% faster movement speed| 80% larger Medic Gun clip|40% better Body Armor|50% discount on Medic Guns and Armor"
    SRLevelEffects(5)="*** BONUS LEVEL 5|150% faster Syringe recharge|50% more potent medical injections|75% less damage from Bloat Bile|15% faster movement speed|100% larger Medic Gun clip|50% better Body Armor|60% discount on Medic Guns and Armor|Spawn with Body Armor"
    SRLevelEffects(6)="*** BONUS LEVEL 6|200% faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|18% faster movement speed|100% larger Medic Gun clip|60% better Body Armor|70% discount on Medic Guns and Armor|Spawn with Body Armor and MP7M"
    CustomLevelInfo="*** BONUS LEVEL %L|%s faster Syringe recharge|75% more potent medical injections|75% less damage from Bloat Bile|%m faster movement speed|100% larger Medic Gun clip|%a better Body Armor|%d discount on Medic Guns and Armor|Spawn with Body Armor and MP7M"
    PerkIndex=0
    OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Medic'
    OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Medic_Gold'
    OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Medic_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
    OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Medic_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
    VeterancyName="Field Medic"
    Requirements(0)="Heal %x HP on your teammates"
}
