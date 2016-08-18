/**
 * Perk designed for using pistols
 */
class ScrnVetGunslinger extends ScrnVeterancyTypes
	abstract;

static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  if (ReqNum == 1)
    return StatOther.GetCustomValueInt(Class'ScrnBalanceSrv.ScrnPistolDamageProgress');
  // 0 and default
  return StatOther.GetCustomValueInt(Class'ScrnBalanceSrv.ScrnPistolKillProgress');
}


static function AddCustomStats( ClientPerkRepLink Other )
{
    super.AddCustomStats(Other); //init achievements
    
	Other.AddCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress');
	Other.AddCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress');
}


static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	if (GetClientVeteranSkillLevel(KFPRI) > 0) {
	
        // 18, 21, 24 magazine ammo on level 1, 3, 5
        if ( ClassIsChildOf(Other, class'ScrnSingle') || ClassIsChildOf(Other, class'ScrnDualies') )
            return 1.0 + 0.20 * ((GetClientVeteranSkillLevel(KFPRI)+1) / 2) ;
    }
	
	return 1.0;
}

/* don't give extra ammo for free
static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{

	if (GetClientVeteranSkillLevel(KFPRI)) == 0 return 1.0;

	if ( (SingleAmmo(Other) != none || DualiesAmmo(Other) != none)
		return 1.0 + 0.20 * ((int((GetClientVeteranSkillLevel(KFPRI)+1) / 2))) // 18, 21, 24 ammo on level 1, 3 and 5

	if (DeagleAmmo(Other) != none ) {
		if (GetClientVeteranSkillLevel(KFPRI) > 3) return 1.5; // 12 ammo for level 4+
		else if (GetClientVeteranSkillLevel(KFPRI) > 1) return 1.25; // 10 ammo for level 2-3
	}
	return 1.0;

}
*/

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
	if ( ClassIsChildOf(AmmoType, class'SingleAmmo') || ClassIsChildOf(AmmoType, class'DualiesAmmo') 
            || ClassIsChildOf(AmmoType, class'Magnum44Ammo') 
            || ClassIsChildOf(AmmoType, class'MK23Ammo')
			|| ClassIsChildOf(AmmoType, class'DeagleAmmo')
            || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
        )
		return 1.0 + (0.10 * GetClientVeteranSkillLevel(KFPRI)); //up to 60% ammo bonus

	return 1.0;
}

static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    // up to 35% damage for 9mm
    // up to 50% damage for other pistols
    // Dual HC and 44 damage types are derived from singles, so no need to specify all of them here
	if (  DmgType == default.DefaultDamageType
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeDeagle') 
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMagnum44Pistol ') 
            || ClassIsChildOf(DmgType, class'KFMod.DamTypeMK23Pistol') 
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        ) {
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return float(InDamage) * (1.00 + (0.10 * float(Min(GetClientVeteranSkillLevel(KFPRI), 5)))); // Up to 50% increase in Damage with Pistols
        return float(InDamage) * (1.20 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
	}

    if ( ClassIsChildOf(DmgType, class'KFMod.DamTypeDualies') ) {
		return float(InDamage) * (1.05 + (0.05 * float(Min(GetClientVeteranSkillLevel(KFPRI), 6)))); // Up to 35% increase in Damage with 9mm
	}
    
	return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( class'ScrnBalance'.default.Mut.bHardcore && ZombieCrawler(Instigator) != none ) {
        return InDamage * 2; // double damage from crawlers in hardcore mode
    }
    
    return InDamage;
}


// v1.51 - weight cap increased  from 10 to 11
// v2.31 - weight cap increased  from 11 to 12
// v8.00 - weight cap increased  from 12 to 15
static function int AddCarryMaxWeight(KFPlayerReplicationInfo KFPRI)
{
    return 0;
    //return -3; // limit Gunslinger weight to 12 blocks
}

static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
	if ( Single(Other.Weapon) != none || Dualies(Other.Weapon) != none
            || Deagle(Other.Weapon) != none || DualDeagle(Other.Weapon) != none
            || MK23Pistol(Other.Weapon) != none || DualMK23Pistol(Other.Weapon) != none
            || Magnum44Pistol(Other.Weapon) != none || Dual44Magnum(Other.Weapon) != none 
            || ClassIsInArray(default.PerkedWeapons, Other.Weapon.Class) //v3 - custom weapon support
        )
        Recoil = 0.9 - (0.1 * Min(6, (GetClientVeteranSkillLevel(KFPRI)))); //up to 70% recoil reduction
	else Recoil = 1.0;

	
	Return Recoil;
}

// Starting from level 3 Gunslinger can enter Cowboy mode
// Cowboys use only dual-pistols, wears no armor and don't use advanced features like lasers
// Cowboy mode is switched automatically when all the requirements are met
// v2.30 - Allow Cowboy Mode, if Armor depletes below 25%
// v5.05 - Allow Cowboy Mode along with using laser sights
static function bool CheckCowboyMode(KFPlayerReplicationInfo KFPRI, class<Weapon> WeapClass)
{
    local Pawn p;
    
    if ( GetClientVeteranSkillLevel(KFPRI) < 3 )
        return false;
        
    // doesn't work on client side, unless pawn is locally controlled
    if ( Controller(KFPRI.Owner) != none ) {
        p = Controller(KFPRI.Owner).Pawn; 
    }

    // assume that player is not so stupid to trade Cowboy Mode for an armor 
    // Calling FindPawn() is too slow for such minor case
    if ( p != none && p.ShieldStrength >= 26 )
		return false;
    
    if ( WeapClass == none )
        return false;
    
    // if custom weapon has "*" bonus switch
    if ( ClassIsInArray(default.SpecialWeapons, WeapClass ) )
        return true;
	
    return ClassIsChildOf(WeapClass, class'Dualies');
}

// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	//increase fire only with full-automatic pistols
	if ( CheckCowboyMode(KFPRI, Other) && (Other.class == class'Dualies' || ClassIsChildOf(Other, class'ScrnDualies') 
            || !Other.default.FireModeClass[0].default.bWaitForRelease) ) 
	{
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 1.0 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI) - 3)); // Up to 30% faster fire rate with dualies in cowboy mode
        // level 7+
        return 1.3 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI) - 6)); // 
	}
	return 1.0;
}

static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    local float result;
    
    result = 1.0;
	if ( ClassIsChildOf(Other, class'Dualies') // all dual pistols classes extend this
			|| ClassIsChildOf(Other, class'Single') || ClassIsChildOf(Other, class'Deagle')
			|| ClassIsChildOf(Other, class'MK23Pistol') || ClassIsChildOf(Other, class'Magnum44Pistol')
			|| ClassIsInArray(default.PerkedWeapons, Other) //v3 - custom weapon support
		)
		result =  1.3 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI))); // Up to 60% faster reload with pistols
	// Level 6 Cowboys reload dualies in the same time as singles
	if ( CheckCowboyMode(KFPRI, Other) ) 
		result *= 1.05 + 0.10 * clamp(GetClientVeteranSkillLevel(KFPRI)-2, 1, 3); //up to 35% extra bonus for cowboys

	return result;
}

// up to 20% speed bonus in cowboy mode
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
    if ( CheckCowboyMode(KFPRI, Weap.class) )
        return (0.05 * fmin(4, GetClientVeteranSkillLevel(KFPRI)-2));
    return 0.0;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    //reduced base price, so no discount on magnums
    if ( Item == class'ScrnBalanceSrv.ScrnMagnum44Pickup' || Item == class'ScrnBalanceSrv.ScrnDual44MagnumPickup' )
        return 1.0;

    if ( ClassIsChildOf(Item,  class'DeaglePickup') || ClassIsChildOf(Item,  class'DualDeaglePickup')
            || ClassIsChildOf(Item, class'MK23Pickup') || ClassIsChildOf(Item, class'DualMK23Pickup') 
            || Item == class'Magnum44Pickup' || Item == class'Dual44MagnumPickup'
            || ClassIsChildOf(Item, class'ScrnDual44MagnumLaserPickup')
            || ClassIsInArray(default.PerkedPickups, Item)
        )
    {
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
        else
            return FMax(0.1, 0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // 5% post level 6
	}
    return 1.0;
}


// Give Extra Items as Default
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super.AddDefaultInventory(KFPRI, P);

	// If Level 5, give them Dual-9mm
	if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
		KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnDualies", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnDualiesPickup'));

	// If Level 6, give them Dual-Magnum
	if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
		KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnDual44Magnum", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnDual44MagnumPickup'));
		
}
*/

static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	S = Default.CustomLevelInfo;
	BonusLevel = GetBonusLevel(Level)-6;
	
	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%s",GetPercentStr(0.5 + 0.05*BonusLevel));
	ReplaceText(S,"%r",GetPercentStr(0.6 + 0.05*BonusLevel));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));
	ReplaceText(S,"%f",GetPercentStr(0.3 + 0.05*BonusLevel));
    
	return S;
}

defaultproperties
{
     DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslinger'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultGunslingerBase'

     progressArray0(0)=20
     progressArray0(1)=50
     progressArray0(2)=200
     progressArray0(3)=1000
     progressArray0(4)=3000
     progressArray0(5)=7000
     progressArray0(6)=11000
	 
     progressArray1(0)=10000
     progressArray1(1)=25000
     progressArray1(2)=100000
     progressArray1(3)=500000
     progressArray1(4)=1500000
     progressArray1(5)=3500000
     progressArray1(6)=5500000

     CustomLevelInfo="*** BONUS LEVEL %L|35% more damage with 9mm|%s more damage with HC/44/MK23|70% less recoil with Pistols|%r faster reload with Pistols|60% larger 9mm magazine|%d discount on HC/44/MK23|Spawn with Dual 44 Magnums||Cowboy Mode (holding Dual Pistols, light armor max):|35% extra reload with Dual Pistols|20% movement speed bonus|%f faster fire rate with 9mm"
     SRLevelEffects(0)="*** BONUS LEVEL 0|5% more damage with 9mm|10% less recoil with Pistols|30% faster reload with Pistols|10% discount on HC/44/MK23"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% more damage with 9mm|10% more damage with HC/44/MK23|20% less recoil with Pistols|35% faster reload with Pistols|20% larger 9mm magazine|20% discount on HC/44/MK23"
     SRLevelEffects(2)="*** BONUS LEVEL 2|15% more damage with 9mm|20% more damage with HC/44/MK23|30% less recoil with Pistols|40% faster reload with Pistols|20% larger 9mm magazine|30% discount on HC/44/MK23"
     SRLevelEffects(3)="*** BONUS LEVEL 3|20% more damage with 9mm|30% more damage with HC/44/MK23|40% less recoil with Pistols|45% faster reload with Pistols|40% larger 9mm magazine|40% discount on HC/44/MK23||Cowboy Mode (holding Dual Pistols, light armor max):|15% faster reload with Dual Pistols|5% movement speed bonus|"
     SRLevelEffects(4)="*** BONUS LEVEL 4|25% more damage with 9mm|40% more damage with HC/44/MK23|50% less recoil with Pistols|50% faster reload with Pistols|40% larger 9mm magazine|50% discount on HC/44/MK23||Cowboy Mode (holding Dual Pistols, light armor max):|25% extra reload with Dual Pistols|10% movement speed bonus|10% faster fire rate with 9mm"
     SRLevelEffects(5)="*** BONUS LEVEL 5|30% more damage with 9mm|50% more damage with HC/44/MK23|60% less recoil with Pistols|55% faster reload with Pistols|60% larger 9mm magazine|60% discount on HC/44/MK23|Spawn with Dual 9mm||Cowboy Mode (holding Dual Pistols, light armor max):|35% extra reload with Dual Pistols|15% movement speed bonus|20% faster fire rate with 9mm"
     SRLevelEffects(6)="*** BONUS LEVEL 6|35% more damage with 9mm|50% more damage with HC/44/MK23|70% less recoil with Pistols|60% faster reload with Pistols|60% larger 9mm magazine|70% discount on HC/44/MK23|Spawn with Dual 44 Magnums||Cowboy Mode (holding Dual Pistols, light armor max):|35% extra reload with Dual Pistols|20% movement speed bonus|30% faster fire rate with 9mm"
     NumRequirements=1 // removed damage req. in v5.30 Beta 18
     PerkIndex=8
     OnHUDIcon=Texture'ScrnTex.Perks.Perk_Gunslinger'
     OnHUDGoldIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gray',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Gray',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Gunslinger_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
	 
     VeterancyName="Gunslinger"
     Requirements(0)="Get %x kills with Pistols"
     Requirements(1)="Deal %x damage with Pistols"
}
