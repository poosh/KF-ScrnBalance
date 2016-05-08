class ScrnVetSharpshooter extends ScrnVeterancyTypes
	abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return StatOther.RHeadshotKillsStat;
}

static function array<int> GetProgressArray(byte ReqNum, optional out int DoubleScalingBase)
{
    if ( class'ScrnBalance'.default.Mut.ReqBalanceMode == 2 )
        DoubleScalingBase = 2500; // ServerPerks value
    else
        DoubleScalingBase = default.progressArray0[3];
    return default.progressArray0;
}

//add SC and FP same resistance to M99 as Crossbow
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn Instigator, int InDamage, class<DamageType> DmgType)
{
    // v7.57: M99 resistance moved to ScrnM99Bullet
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        return InDamage / 2;
    return InDamage;
}


static function float GetHeadShotDamMulti(KFPlayerReplicationInfo KFPRI, KFPawn P, class<DamageType> DmgType)
{
	local float ret;
    local byte level;
    local bool bNoExtraBonus;
    
    level = GetClientVeteranSkillLevel(KFPRI);
    
    if ( DmgType == default.DefaultDamageTypeNoBonus ) {
        ret = 1.0;
    }
	else if ( class'ScrnBalance'.default.Mut.bGunslinger &&  
			(ClassIsChildOf(DmgType,  class'DamTypeDual44Magnum')
			|| ClassIsChildOf(DmgType,  class'DamTypeDualMK23Pistol')
			|| ClassIsChildOf(DmgType,  class'DamTypeDualDeagle')
			|| ClassIsChildOf(DmgType,  class'ScrnBalanceSrv.ScrnDamTypeDualies')) ) {
		ret = 1.0; // If Gunslinger perk persists, remove damage bonus from dual pistols. 
	}
	else if ( ClassIsChildOf(DmgType, class'DamTypeDualies') && KFPRI.Level.Game.GameDifficulty >= 7.0 ) {
		ret =  1.0 + (0.08 * float(Min(level, 5))); // limit to 40% max HS damage bonus
        bNoExtraBonus = true;
	}
	else if ( DmgType == default.DefaultDamageType
                || ClassIsChildOf(DmgType, class'DamTypeCrossbow')
                || ClassIsChildOf(DmgType,  class'DamTypeM99SniperRifle')
                || ClassIsChildOf(DmgType,  class'DamTypeWinchester')
                || ClassIsChildOf(DmgType,  class'DamTypeM14EBR')
				|| ClassIsChildOf(DmgType,  class'DamTypeSPSniper')
                || ClassChildIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
            ) { 
		// sniper rifles
		if ( level <= 3 )
			ret = 1.05 + (0.05 * float(level));
		else if ( level == 4 )
			ret = 1.30;
		else if ( level == 5 )
			ret = 1.50;
		else if ( level == 6 )
			ret = 1.60; // 60% increase in Crossbow/Winchester/Handcannon damage
		else
			ret = 1.6 + (0.10 * float(max(0,level-6)));
	}
	else if ( ClassIsChildOf(DmgType,  class'DamTypeDeagle') // including dual
                || ClassIsChildOf(DmgType,  class'DamTypeMK23Pistol') // including dual
                || ClassIsChildOf(DmgType,  class'DamTypeMagnum44Pistol') // including dual
                || ClassIsChildOf(DmgType,  class'DamTypeDualies') // including single 
            ) {
		// pistols
		if ( level <= 3 )
			ret = 1.05 + (0.05 * float(level));
		else if ( level == 4 )
			ret = 1.30;
		else if ( level == 5 )
			ret = 1.50;
		else if ( level == 6 )
			ret = 1.60; // 60% increase in Crossbow/Winchester/Handcannon damage
		else
			ret = 1.6 + (0.05 * float(max(0,level-6)));		
	}
	else {
		ret = 1.0; // Fix for oversight in Balance Round 6(which is the reason for the Round 6 second attempt patch)
	}

    if ( !bNoExtraBonus ) {
        if ( level == 0 )
            ret *= 1.05;
        else
            ret *= (1.0 + (0.10 * float(Min(level, 5)))); // 50% increase in Headshot Damage for all weapons
    }
    
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        ret *= 2.0; // to compensate 50% damage reduction in ReduceDamage();
    
    //Log("Headshot multiplier for " $ String(DmgType) $ " is " $ ret);
	return  ret;
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
	// If Gunslinger perk persists, remove bonus from dual pistols. 
	if ( Crossbow(Other.Weapon) != none || Winchester(Other.Weapon) != none
            || Single(Other.Weapon) != none || Deagle(Other.Weapon) != none 
            || Magnum44Pistol(Other.Weapon) != none 
            || M14EBRBattleRifle(Other.Weapon) != none 
            || M99SniperRifle(Other.Weapon) != none
			|| SPSniperRifle(Other.Weapon) != none
            || (!class'ScrnBalance'.default.Mut.bGunslinger && Dualies(Other.Weapon) != none ) //all dual pistols are derived from Dualies
            || ClassIsInArray(default.PerkedWeapons, Other.Weapon.Class) //v3 - custom weapon support
        ) 
	{
		if ( GetClientVeteranSkillLevel(KFPRI) == 1)
		{
			Recoil = 0.75;
		}
		else if ( GetClientVeteranSkillLevel(KFPRI) == 2 )
		{
			Recoil = 0.50;
		}
		else
		{
			Recoil = 0.25; // 75% recoil reduction with Crossbow/Winchester/Handcannon
		}

		return Recoil;
	}

	Recoil = 1.0;
	Return Recoil;
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	if ( ClassIsChildOf(Other, class'Winchester') || ClassIsChildOf(Other, class'SPSniperRifle')
		|| ClassIsInArray(default.SpecialWeapons, Other) )
	{
		return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% faster fire rate with LAR and Special Weapons
	}
	return 1.0;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	// If Gunslinger perk persists, remove bonus from dual pistols. 
	if ( ClassIsChildOf(Other, class'Winchester') || ClassIsChildOf(Other, class'M14EBRBattleRifle')
			|| ClassIsChildOf(Other, class'Single') || ClassIsChildOf(Other, class'Deagle')
			|| ClassIsChildOf(Other, class'Magnum44Pistol') || ClassIsChildOf(Other, class'MK23Pistol')
			|| ClassIsChildOf(Other, class'SPSniperRifle')
            || (!class'ScrnBalance'.default.Mut.bGunslinger && ClassIsChildOf(Other, class'Dualies')) //all dual pistols are derived from Dualies
            || ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
        )
	{
        return 1.0 + (0.10 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% faster reload with Pistols/LAR/M14
	}

	return 1.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    //reduced base price, so no discount on magnums
    if ( Item == class'ScrnBalanceSrv.ScrnMagnum44Pickup' || Item == class'ScrnBalanceSrv.ScrnDual44MagnumPickup' )
        return 1.0;
        
	//leave discount for Dual Pistols even if Gunslinger perk persists to reject possible 
	//buy-sell exploits
	if ( ClassIsChildOf(Item, class'DeaglePickup') || ClassIsChildOf(Item, class'DualDeaglePickup')
            || ClassIsChildOf(Item, class'MK23Pickup') || ClassIsChildOf(Item, class'DualMK23Pickup') 
            || ClassIsChildOf(Item, class'Magnum44Pickup') 
            || (ClassIsChildOf(Item, class'Dual44MagnumPickup') && !ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnDual44MagnumLaserPickup'))
            || ClassIsChildOf(Item, class'M14EBRPickup')
            || ClassIsChildOf(Item, class'M99Pickup')
            || ClassIsChildOf(Item, class'SPSniperPickup')
            || (class'ScrnBalance'.default.Mut.bSpawnBalance && ClassIsChildOf(Item, class'CrossbowPickup')) // Add discount on Crossbow (c) PooSH, 2012
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

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 6 ) {
        if ( ClassIsChildOf(AmmoType, class'CrossbowAmmo')
                || ClassIsChildOf(AmmoType, class'M99Ammo')
                || ClassIsChildOf(AmmoType, class'SPSniperAmmo')
                || ClassIsChildOf(AmmoType, class'WinchesterAmmo')
                || ClassIsChildOf(AmmoType, class'M14EBRAmmo')
                || ClassIsChildOf(AmmoType, class'SingleAmmo')
                || ClassIsChildOf(AmmoType, class'Magnum44Ammo') 
                || ClassIsChildOf(AmmoType, class'MK23Ammo')
                || ClassIsChildOf(AmmoType, class'DeagleAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType) ) 
            return 1.0 + 0.10 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +10% per level above 6
    }
	return 1.0;
}

static function float GetAmmoCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	if ( ClassIsChildOf(Item, class'CrossbowPickup') || ClassIsChildOf(Item, class'M99Pickup') ) {
		return 1.0 - fmin(0.7, (0.07 * GetClientVeteranSkillLevel(KFPRI))); // Up to 42% discount on Crossbow Bolts(Added in Balance Round 4 at 30%, increased to 42% in Balance Round 7)
	}
	return 1.0;
}

// Give Extra Items as Default
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super.AddDefaultInventory(KFPRI, P);

	// If Level 5, give them a  Lever Action Rifle
	if ( GetClientVeteranSkillLevel(KFPRI) == 5 ) {
        if ( class'ScrnBalance'.default.Mut.bWeaponFix ) 
            KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnWinchester", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnWinchesterPickup'));
        else
            KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Winchester", GetInitialCostScaling(KFPRI, class'KFMod.WinchesterPickup'));
    }


	// If Level 6, give them a Crossbow
	if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
		KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Crossbow", GetInitialCostScaling(KFPRI, class'KFMod.CrossbowPickup'));
}
*/

static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;
	
	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(1.5*(1.6 + 0.10*BonusLevel) -1 ));
	ReplaceText(S,"%p",GetPercentStr(1.5*(1.6 + 0.05*BonusLevel) -1 ));
	ReplaceText(S,"%a",GetPercentStr(0.42 + fmin(0.28, 0.07*BonusLevel)));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));
    
	return S;
}

defaultproperties
{
     DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeSniper'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeSniperBase'

     progressArray0(0)=10
     progressArray0(1)=30
     progressArray0(2)=100
     progressArray0(3)=800
     progressArray0(4)=2500
     progressArray0(5)=5500
     progressArray0(6)=8500
     CustomLevelInfo="*** BONUS LEVEL %L|+%s Headshot dmg. with Sniper Rifles|+%p Headshot dmg. with Pistols|+50% Headshot damage with other weapons|75% less recoil with Pistols/Sniper Rifles|60% faster reload with Pistols/Sniper Rifles|%d discount on Pistols/Sniper Rifles|%a discount on Crossbow/M99 ammo|Spawn with a Crossbow"
     SRLevelEffects(0)="*** BONUS LEVEL 0|+10% Headshot dmg. with Pistols/Sniper Rifles|+5% Headshot damage with other weapons|10% discount on Pistols/Sniper Rifles"
     SRLevelEffects(1)="*** BONUS LEVEL 1|+21% Headshot dmg. with Pistols/Sniper Rifles|+10% Headshot damage with other weapons|25% less recoil with Pistols/Sniper Rifles|10% faster reload with Pistols/Sniper Rifles|20% discount on Pistols/Sniper Rifles|7% discount on Crossbow/M99 ammo"
     SRLevelEffects(2)="*** BONUS LEVEL 2|+38% Headshot dmg. with Pistols/Sniper Rifles|+20% Headshot damage with other weapons|50% less recoil with Pistols/Sniper Rifles|20% faster reload with Pistols/Sniper Rifles|30% discount on Pistols/Sniper Rifles|14% discount on Crossbow/M99 ammo"
     SRLevelEffects(3)="*** BONUS LEVEL 3|+56% Headshot dmg. with Pistols/Sniper Rifles|+30% Headshot damage with other weapons|75% less recoil with Pistols/Sniper Rifles|30% faster reload with Pistols/Sniper Rifles|40% discount on Pistols/Sniper Rifles|21% discount on Crossbow/M99 ammo"
     SRLevelEffects(4)="*** BONUS LEVEL 4|+82% Headshot dmg. with Pistols/Sniper Rifles|+40% Headshot damage with other weapons|75% less recoil with Pistols/Sniper Rifles|40% faster reload with Pistols/Sniper Rifles|50% discount on Pistols/Sniper Rifles|28% discount on Crossbow/M99 ammo"
     SRLevelEffects(5)="*** BONUS LEVEL 5|+125% Headshot dmg. with Pistols/Sniper Rifles|+50% Headshot damage with other weapons|75% less recoil with Pistols/Sniper Rifles|50% faster reload with Pistols/Sniper Rifles|60% discount on Pistols/Sniper Rifles|35% discount on Crossbow/M99 ammo|Spawn with a Lever Action Rifle"
     SRLevelEffects(6)="*** BONUS LEVEL 6|+140% Headshot dmg. with Pistols/Sniper Rifles|+50% Headshot damage with other weapons|75% less recoil with Pistols/Sniper Rifles|60% faster reload with Pistols/Sniper Rifles|70% discount on Pistols/Sniper Rifles|42% discount on Crossbow/M99 ammo|Spawn with a Crossbow"
     PerkIndex=2
     OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_SharpShooter'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_SharpShooter_Gold'
   	 OnHUDIcons(0)=(PerkIcon=Texture'KillingFloorHUD.Perks.Perk_SharpShooter',StarIcon=Texture'KillingFloorHUD.HUD.Hud_Perk_Star',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_SharpShooter_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_SharpShooter_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	VeterancyName="Sharpshooter"
     Requirements(0)="Get %x headshot kills with Pistols/LAR/M14/Crossbow/M99"
}
