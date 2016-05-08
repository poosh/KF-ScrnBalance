class ScrnVetCommando extends ScrnVeterancyTypes
	abstract;


static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  if (ReqNum == 1)
    return StatOther.RBullpupDamageStat;
  // 0 and default
  return StatOther.RStalkerKillsStat;
}


// Display enemy health bars
static function SpecialHUDInfo(KFPlayerReplicationInfo KFPRI, Canvas C)
{
	local KFMonster KFEnemy;
	local HUDKillingFloor HKF;
	local float MaxDistance;

	if ( GetClientVeteranSkillLevel(KFPRI) > 0 )
	{
		HKF = HUDKillingFloor(C.ViewPort.Actor.myHUD);
		if ( HKF == none || Pawn(C.ViewPort.Actor.ViewTarget)==none || Pawn(C.ViewPort.Actor.ViewTarget).Health<=0 )
			return;

		switch ( GetClientVeteranSkillLevel(KFPRI) )
		{
			case 1:
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
        
        if ( class'ScrnBalance'.default.Mut.bHardcore )
            MaxDistance *= 0.75;        

		foreach C.ViewPort.Actor.VisibleCollidingActors(class'KFMonster',KFEnemy,MaxDistance,C.ViewPort.Actor.CalcViewLocation)
		{
			if ( KFEnemy.Health > 0 && !KFEnemy.Cloaked() )
				HKF.DrawHealthBar(C, KFEnemy, KFEnemy.Health, KFEnemy.HealthMax , 50.0);
		}
	}
}

static function bool ShowStalkers(KFPlayerReplicationInfo KFPRI)
{
	return true;
}

static function float GetStalkerViewDistanceMulti(KFPlayerReplicationInfo KFPRI)
{
    local float result;
    
	switch ( GetClientVeteranSkillLevel(KFPRI) )
	{
		case 0:
			result = 0.0625; // 25%
		case 1:
			result = 0.25; // 50%
		case 2:
			result = 0.36; // 60%
		case 3:
			result = 0.49; // 70%
		case 4:
			result = 0.64; // 80%
        case 5: case 6:
            result = 1.0;  // 100% of Standard Distance(800 units or 16 meters)
        default:
            result = 1.0 + 0.0625 * (GetClientVeteranSkillLevel(KFPRI) - 6); // 1m per each next level
	}
    
    if ( class'ScrnBalance'.default.Mut.bHardcore )
        result *= 0.75;

	return result;
}

static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(Other, class'Bullpup')
				|| ClassIsChildOf(Other, class'AK47AssaultRifle') || ClassIsChildOf(Other, class'MKb42AssaultRifle')
				|| ClassIsChildOf(Other, class'M4AssaultRifle')
				|| ClassIsChildOf(Other, class'SCARMK17AssaultRifle') || ClassIsChildOf(Other, class'FNFAL_ACOG_AssaultRifle')
				|| ClassIsChildOf(Other, class'ThompsonSMG')
                || ClassIsInArray(default.PerkedAmmo, Other.default.FiremodeClass[0].default.AmmoClass)  //v3 - custom weapon support
            ) 
		{
            if ( GetClientVeteranSkillLevel(KFPRI) == 1 )
                return 1.10;
            else if ( GetClientVeteranSkillLevel(KFPRI) == 2 )
                return 1.20;
            return 1.25; // 25% bigger assault rifle magazine
        }
    }
	return 1.0;
}

static function float GetAmmoPickupMod(KFPlayerReplicationInfo KFPRI, KFAmmunition Other)
{
	return AddExtraAmmoFor(KFPRI, Other.class);
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnM203MAmmo') )
        return 1.0; // no extra medic grenades
        
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( ClassIsChildOf(AmmoType, class'BullpupAmmo') 
                || ClassIsChildOf(AmmoType, class'AK47Ammo') 
                || ClassIsChildOf(AmmoType, class'SCARMK17Ammo' )
                || ClassIsChildOf(AmmoType, class'M4Ammo')
                || ClassIsChildOf(AmmoType, class'FNFALAmmo')
                || ClassIsChildOf(AmmoType, class'MKb42Ammo') 
                || ClassIsChildOf(AmmoType, class'ThompsonAmmo')
                || ClassIsChildOf(AmmoType, class'ThompsonDrumAmmo')
                || ClassIsChildOf(AmmoType, class'SPThompsonAmmo')
                || ClassIsInArray(default.PerkedAmmo, AmmoType)  //v3 - custom weapon support
            ) 
		{
            if ( GetClientVeteranSkillLevel(KFPRI) == 1 )
                return 1.10;
            else if ( GetClientVeteranSkillLevel(KFPRI) == 2 )
                return 1.20;
            else if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
                return 1.25; // 25% increase in assault rifle ammo carry
            else 
                return 1.25 + 0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +10% per level above 6
        }
    }
	return 1.0;
}
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

    if ( DmgType == default.DefaultDamageType 
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
        ) {
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return float(InDamage) * (1.00 + (0.10 * float(Min(GetClientVeteranSkillLevel(KFPRI), 5)))); // Up to 50% increase in Damage
        return float(InDamage) * (1.20 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
	}
	return InDamage;
}

static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( class'ScrnBalance'.default.Mut.bHardcore && DmgType == class'DamTypeSlashingAttack' ) {
        return InDamage * 3.5; // quad damage from Stalkers in hardcore mode
    }
    
    return InDamage;
}



static function float ModifyRecoilSpread(KFPlayerReplicationInfo KFPRI, WeaponFire Other, out float Recoil)
{
    Recoil = 1.0;
	if ( Bullpup(Other.Weapon) != none || AK47AssaultRifle(Other.Weapon) != none
            || SCARMK17AssaultRifle(Other.Weapon) != none || M4AssaultRifle(Other.Weapon) != none 
            || FNFAL_ACOG_AssaultRifle(Other.Weapon) != none 
            || MKb42AssaultRifle(Other.Weapon) != none || ThompsonSMG(Other.Weapon) != none
            || ClassIsInArray(default.PerkedWeapons, Other.Weapon.Class) //v3 - custom weapon support
        ) {
		if ( GetClientVeteranSkillLevel(KFPRI) <= 3 )
			Recoil = 0.95 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)));
		else if ( GetClientVeteranSkillLevel(KFPRI) <= 5 )
			Recoil = 0.70;
		else if ( GetClientVeteranSkillLevel(KFPRI) == 6 )
			Recoil = 0.60; // Level 6 - 40% recoil reduction
		else Recoil = FMax(0.9 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI))),0.f);
	}
	return Recoil;
}

//v2.40 raise reload speed for perked weapons
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
    if ( class'ScrnBalance'.default.Mut.bWeaponFix && ClassIsChildOf(Other, class'ThompsonSMG') )
        return 1.0 + (0.1 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 60% faster reload speed for Tommy Guns

	return 1.05 + (0.05 * fmin(6, GetClientVeteranSkillLevel(KFPRI))); // Up to 35% faster reload speed for any weapon
}

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) > 6 )
        return min(10, 4 + GetClientVeteranSkillLevel(KFPRI)/3); // 1 extention per 3 levels above 6
	else if ( GetClientVeteranSkillLevel(KFPRI) >= 3 )
		return GetClientVeteranSkillLevel(KFPRI) - 2; // Up to 4 Zed Time Extensions
	return 1;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnBullpupPickup' )
        return 1.0; // price lowered to $200, no discount needed

    if ( ClassIsChildOf(Item, class'ScrnBalanceSrv.ScrnM4203MPickup') )
        return 1.0; //no discount on medic M4-203

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
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return 0.9 - 0.10 * float(GetClientVeteranSkillLevel(KFPRI)); // 10% perk level up to 6
        else
            return FMax(0.1, 0.3 - (0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6))); // 5% post level 6
    }
	return 1.0;
}

// Give Extra Items as default
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super.AddDefaultInventory(KFPRI, P);
	// If Level 5, give them Bullpup
	// If Level 6, give them an AK47
    if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
		if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
			KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnBullpup", GetInitialCostScaling(KFPRI, class'ScrnBullpupPickup'));
		if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
			KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnAK47AssaultRifle", GetInitialCostScaling(KFPRI, class'ScrnAK47Pickup'));
	}
	else {
		if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
			KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Bullpup", GetInitialCostScaling(KFPRI, class'BullpupPickup'));
		if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
			KFHumanPawn(P).CreateInventoryVeterancy("KFMod.AK47AssaultRifle", GetInitialCostScaling(KFPRI, class'AK47Pickup'));
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
	ReplaceText(S,"%s",GetPercentStr(0.5 + 0.05*BonusLevel));
	//ReplaceText(S,"%a",GetPercentStr(0.5 + 0.05*BonusLevel));
	//ReplaceText(S,"%r",GetPercentStr(0.35 + 0.05*BonusLevel));
	ReplaceText(S,"%c",GetPercentStr(0.4 + fmin(0.5, 0.05*BonusLevel)));
	ReplaceText(S,"%z",string(BonusLevel/3+4));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));    
	ReplaceText(S,"%v",string(BonusLevel+16));
    
	return S;
}

defaultproperties
{
     DefaultDamageType=Class'ScrnBalanceSrv.ScrnDamTypeCommando'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeCommandoBase'

     progressArray0(0)=10
     progressArray0(1)=30
     progressArray0(2)=100
     progressArray0(3)=325
     progressArray0(4)=1200
     progressArray0(5)=2400
     progressArray0(6)=3600
	 
     progressArray1(0)=10000
     progressArray1(1)=25000
     progressArray1(2)=100000
     progressArray1(3)=500000
     progressArray1(4)=1500000
     progressArray1(5)=3500000
     progressArray1(6)=5500000
	 
     CustomLevelInfo="*** BONUS LEVEL %L|%s more damage with Assaut Rifles|%c less recoil with Assaut Rifles|25% larger Assaut Rifles clip|60% faster reload with Tommy Guns|35% faster reload with all weapons|%d discount on Assaut Rifles|Can see cloaked Stalkers from %vm|Can see enemy health from 16m|Up to %z Zed-Time Extensions|Spawn with an AK47"
     SRLevelEffects(0)="*** BONUS LEVEL 0|5% more damage with Assaut Rifles|5% less recoil with Assaut Rifles|5% faster reload with all weapons|10% discount on Assaut Rifles|Can see cloaked Stalkers from 4 meters"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% more damage with Assaut Rifles|10% less recoil with Assaut Rifles|10% larger Assaut Rifles clip|10% faster reload with Tommy Guns|10% faster reload with all weapons|20% discount on Assaut Rifles|Can see cloaked Stalkers from 8m|Can see enemy health from 4m"
     SRLevelEffects(2)="*** BONUS LEVEL 2|20% more damage with Assaut Rifles|15% less recoil with Assaut Rifles|20% larger Assaut Rifles clip|20% faster reload with Tommy Guns|15% faster reload with all weapons|30% discount on Assaut Rifles|Can see cloaked Stalkers from 10m|Can see enemy health from 7m"
     SRLevelEffects(3)="*** BONUS LEVEL 3|30% more damage with Assaut Rifles|20% less recoil with Assaut Rifles|25% larger Assaut Rifles clip|30% faster reload with Tommy Guns|20% faster reload with all weapons|40% discount on Assaut Rifles|Can see cloaked Stalkers from 12m|Can see enemy health from 10m|Zed-Time can be extended by killing an enemy while in slow motion"
     SRLevelEffects(4)="*** BONUS LEVEL 4|40% more damage with Assaut Rifles|30% less recoil with Assaut Rifles|25% larger Assaut Rifles clip|40% faster reload with Tommy Guns|25% faster reload with all weapons|50% discount on Assaut Rifles|Can see cloaked Stalkers from 14m|Can see enemy health from 13m|Up to 2 Zed-Time Extensions"
     SRLevelEffects(5)="*** BONUS LEVEL 5|50% more damage with Assaut Rifles|30% less recoil with Assaut Rifles|25% larger Assaut Rifles clip|50% faster reload with Tommy Guns|30% faster reload with all weapons|60% discount on Assaut Rifles|Can see cloaked Stalkers from 16m|Can see enemy health from 16m|Up to 3 Zed-Time Extensions|Spawn with a Bullpup"
     SRLevelEffects(6)="*** BONUS LEVEL 6|50% more damage with Assaut Rifles|40% less recoil with Assaut Rifles|25% larger Assaut Rifles clip|60% faster reload with Tommy Guns|35% faster reload with all weapons|70% discount on Assaut Rifles|Can see cloaked Stalkers from 16m|Can see enemy health from 16m|Up to 4 Zed-Time Extensions|Spawn with an AK47"
     NumRequirements=2
     PerkIndex=3
     OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Commando'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Commando_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'KillingFloorHUD.Perks.Perk_Commando',StarIcon=Texture'KillingFloorHUD.HUD.Hud_Perk_Star',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Commando_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Commando_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
	 
     VeterancyName="Commando"
     Requirements(0)="Kill %x Stalkers/Shivers with Assault Rifles"
     Requirements(1)="Deal %x damage with Assault Rifles"
}
