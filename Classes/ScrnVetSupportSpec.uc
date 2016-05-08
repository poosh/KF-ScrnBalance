class ScrnVetSupportSpec extends ScrnVeterancyTypes
	abstract;
	
static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  if (ReqNum == 1)
    return StatOther.RShotgunDamageStat;
  // 0 and default
  return StatOther.RWeldingPointsStat;
}

static function int AddCarryMaxWeight(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
		return 0;
	else if ( GetClientVeteranSkillLevel(KFPRI) <= 4 )
		return 1 + GetClientVeteranSkillLevel(KFPRI);
	else if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
		return 8; // 8 more carry slots
	return 3+GetClientVeteranSkillLevel(KFPRI); // 9 more carry slots
}


// Adjust distance of welded door health status
static function float GetDoorHealthVisibilityScaling(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	return 2.0 + 0.5 * GetClientVeteranSkillLevel(KFPRI); //up to 5x longer distance
}

// give support melee speed bonus while holding welder
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
	if ( class'ScrnBalance'.default.Mut.bWeaponFix )
	{
		if ( Welder(Weap) != none )
			return class'ScrnBalanceSrv.ScrnHumanPawn'.default.BaseMeleeIncrease;
	}	
    return 0.0;
}

static function float GetWeldSpeedModifier(KFPlayerReplicationInfo KFPRI)
{
	if ( GetClientVeteranSkillLevel(KFPRI) <= 3 )
		return 1.0 + (0.25 * float(GetClientVeteranSkillLevel(KFPRI)));
	return 2.5; // 150% increase in speed
}

static function float AddExtraAmmoFor(KFPlayerReplicationInfo KFPRI, Class<Ammunition> AmmoType)
{
    if ( GetClientVeteranSkillLevel(KFPRI) > 0 ) {
        if ( AmmoType == class'FragAmmo' )
            // Up to 6 extra Grenades
            return 1.0 + (0.20 * float(GetClientVeteranSkillLevel(KFPRI)));
        else if ( class'ScrnBalance'.default.Mut.bWeaponFix 
                && (ClassIsChildOf(AmmoType, class'AA12Ammo') || ClassIsChildOf(AmmoType, class'KSGAmmo')) ) 
        {
            if ( GetClientVeteranSkillLevel(KFPRI) <= 6)
                return 1.0 + 0.125 * min(4, (GetClientVeteranSkillLevel(KFPRI)+2)/2); //+10 ammo per 2 levels, up to 50% increase in AA12 ammo
            else 
                return 1.5 + 0.05 * float(GetClientVeteranSkillLevel(KFPRI)-6); // +5% ammo above level 6
        }
        else if ( ClassIsChildOf(AmmoType, class'ShotgunAmmo') 
                    || ClassIsChildOf(AmmoType, class'DBShotgunAmmo')
                    || ClassIsChildOf(AmmoType, class'AA12Ammo')
                    || ClassIsChildOf(AmmoType, class'BenelliAmmo')
                    || ClassIsChildOf(AmmoType, class'KSGAmmo') 
                    || ClassIsChildOf(AmmoType, class'NailGunAmmo') 
                    || ClassIsChildOf(AmmoType, class'SPShotgunAmmo') 
                    || ClassIsChildOf(AmmoType, class'ScrnBalanceSrv.ScrnNailGunAmmo') 
                    || ClassIsInArray(default.PerkedAmmo, AmmoType) //v3 - custom weapon support
                ) {
            return 1.0 + (0.05 * float(GetClientVeteranSkillLevel(KFPRI)));    
        }
    }
	return 1.0;
}

// Removed frag damage bonus (c) PooSH
static function int AddDamage(KFPlayerReplicationInfo KFPRI, KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType)
{
    if ( DmgType == default.DefaultDamageTypeNoBonus )
        return InDamage;

	if ( DmgType == default.DefaultDamageType
            || ClassIsChildOf(DmgType, class'DamTypeShotgun')
            || ClassIsChildOf(DmgType, class'DamTypeDBShotgun' )
            || ClassIsChildOf(DmgType, class'DamTypeAA12Shotgun')
            || ClassIsChildOf(DmgType, class'DamTypeBenelli')
            || ClassIsChildOf(DmgType, class'DamTypeKSGShotgun') 
            || ClassIsChildOf(DmgType, class'DamTypeNailgun') 
            || ClassIsChildOf(DmgType, class'DamTypeSPShotgun') 
            || ClassIsInArray(default.PerkedDamTypes, DmgType) //v3 - custom weapon support
        )
	{
		if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
			return float(InDamage) * 1.05;
        if ( GetClientVeteranSkillLevel(KFPRI) <= 6 )
            return InDamage * (1.00 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))); // Up to 60% more damage with Shotguns
        return float(InDamage) * (1.30 + (0.05 * GetClientVeteranSkillLevel(KFPRI))); // 5% extra damage for each perk level above 6
	}
	else if ( !class'ScrnBalance'.default.Mut.bWeaponFix && DmgType == class'DamTypeFrag' && GetClientVeteranSkillLevel(KFPRI) > 0 )
	{         // remove nade damage bonus, if bWeaponFix enabled -- by PooSH
		if ( GetClientVeteranSkillLevel(KFPRI) == 1 )
			return float(InDamage) * 1.05;
		return float(InDamage) * (0.90 + (0.10 * float(GetClientVeteranSkillLevel(KFPRI)))); // Up to 50% more damage with Nades
	}
	
	return InDamage;
}


// Modify fire speed
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	if ( class'ScrnBalance'.default.Mut.bHardcore )
        return 0.80; // 20% slower fire rate in hardcore mode
        
	return 1.0;
}

// Support's penetration bonus limited to 60% (down from 90%), 
// but shotgun's base penetration count is increased making them more usefull off the perk
// But I whink community will rape me for this :)
// (c) PooSH 
static function float GetShotgunPenetrationDamageMulti(KFPlayerReplicationInfo KFPRI, float DefaultPenDamageReduction)
{
	local float PenDamageInverse;
    
    if ( !class'ScrnBalance'.default.Mut.bWeaponFix ) {
        PenDamageInverse = (1.0 - FMax(0,DefaultPenDamageReduction)); 

        if ( GetClientVeteranSkillLevel(KFPRI) == 0 )
            return DefaultPenDamageReduction + (PenDamageInverse * 0.05);

        return DefaultPenDamageReduction + (PenDamageInverse * 0.1 * float(Min(GetClientVeteranSkillLevel(KFPRI), 6))); //up to 60% better penetrations
    }
    else {
        PenDamageInverse = 1.0 - FMax(0,DefaultPenDamageReduction);

        if ( KFPRI.ClientVeteranSkillLevel == 0 )
        {
            return DefaultPenDamageReduction + (PenDamageInverse / 10.0);
        }

        return DefaultPenDamageReduction + ((PenDamageInverse / 5.5555) * float(Min(KFPRI.ClientVeteranSkillLevel, 5))); //up to 90% better penetrations
    }
    // shoud never reach here
    return DefaultPenDamageReduction;
}

// Change the cost of particular items
static function float GetCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
    if ( Item == class'ScrnBalanceSrv.ScrnShotgunPickup' )
        return 1.0; // price lowered to $200, no discount needed
        
	if ( ClassIsChildOf(Item, class'ShotgunPickup') 
            || ClassIsChildOf(Item, class'BoomstickPickup') 
            || ClassIsChildOf(Item, class'AA12Pickup') 
            || ClassIsChildOf(Item, class'KSGPickup') 
            || ClassIsChildOf(Item, class'BenelliPickup') 
            || ClassIsChildOf(Item, class'NailGunPickup') 
            || ClassIsChildOf(Item, class'SPShotgunPickup') 
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

// Give Extra Items as Default
// Level 5: Pump Shotgun
// Level 6: Hunting Shotgun
/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super.AddDefaultInventory(KFPRI, P);
	
    if ( class'ScrnBalance'.default.Mut.bWeaponFix ) {
        if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
            KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnShotgun", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnShotgunPickup'));
        else  if ( GetClientVeteranSkillLevel(KFPRI) >= 6 ) {
            KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnBoomStick", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnBoomStickPickup'));
        }
    }
    else {
        if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
            KFHumanPawn(P).CreateInventoryVeterancy("KFMod.Shotgun", GetInitialCostScaling(KFPRI, class'ShotgunPickup'));
        else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 )
            KFHumanPawn(P).CreateInventoryVeterancy("KFMod.BoomStick", GetInitialCostScaling(KFPRI, class'BoomStickPickup'));
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
	ReplaceText(S,"%w",String(30+BonusLevel*3));
	ReplaceText(S,"%b",String(BonusLevel+9));
	ReplaceText(S,"%d",GetPercentStr(0.7 + fmin(0.2, 0.05*BonusLevel)));
    
	return S;
}

defaultproperties
{
     DefaultDamageType=Class'KFMod.DamTypeShotgun'
     DefaultDamageTypeNoBonus=Class'ScrnBalanceSrv.ScrnDamTypeDefaultSupportBase'

     progressArray0(0)=1000
     progressArray0(1)=2000
     progressArray0(2)=7000
     progressArray0(3)=33500
     progressArray0(4)=120000
     progressArray0(5)=250000
     progressArray0(6)=370000
	 
     progressArray1(0)=10000
     progressArray1(1)=25000
     progressArray1(2)=100000
     progressArray1(3)=500000
     progressArray1(4)=1500000
     progressArray1(5)=3500000
     progressArray1(6)=5500000

     CustomLevelInfo="*** BONUS LEVEL %L|%s more damage with Shotguns|60% better Shotgun penetration|30% extra shotgun ammo|120% increase in grenade capacity|+%b blocks in carry weight|150% faster welding/unwelding|While holding Welder can see door healths from %wm|%d discount on Shotguns|Spawn with a Hunting Shotgun"
     SRLevelEffects(0)="*** BONUS LEVEL 0|10% more damage with Shotguns|5% better Shotgun penetration|10% faster welding/unwelding|While holding Welder can see door healths from 12m|10% discount on Shotguns"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% more damage with Shotguns|10% better Shotgun penetration|10% extra shotgun ammo|20% increase in grenade capacity|+2 blocks in carry weight|25% faster welding/unwelding|While holding Welder can see door healths from 15m|20% discount on Shotguns"
     SRLevelEffects(2)="*** BONUS LEVEL 2|20% more damage with Shotguns|20% better Shotgun penetration|20% extra shotgun ammo|40% increase in grenade capacity|+3 blocks in carry weight|50% faster welding/unwelding|While holding Welder can see door healths from 18m|30% discount on Shotguns"
     SRLevelEffects(3)="*** BONUS LEVEL 3|30% more damage with Shotguns|30% better Shotgun penetration|25% extra shotgun ammo|60% increase in grenade capacity|+4 blocks in carry weight|75% faster welding/unwelding|While holding Welder can see door healths from 21m|40% discount on Shotguns"
     SRLevelEffects(4)="*** BONUS LEVEL 4|40% more damage with Shotguns|40% better Shotgun penetration|25% extra shotgun ammo|80% increase in grenade capacity|+5 blocks in carry weight|100% faster welding/unwelding|While holding Welder can see door healths from 24m|50% discount on Shotguns"
     SRLevelEffects(5)="*** BONUS LEVEL 5|50% more damage with Shotguns|50% better Shotgun penetration|25% extra shotgun ammo|100% increase in grenade capacity|+8 blocks in carry weight|150% faster welding/unwelding|While holding Welder can see door healths from 27m|60% discount on Shotguns|Spawn with a Shotgun"
     SRLevelEffects(6)="*** BONUS LEVEL 6|60% more damage with Shotguns|60% better Shotgun penetration|30% extra shotgun ammo|120% increase in grenade capacity|+9 blocks in carry weight|150% faster welding/unwelding|While holding Welder can see door healths from 30m|70% discount on Shotguns|Spawn with a Hunting Shotgun"
     NumRequirements=2
     PerkIndex=1
     OnHUDIcon=Texture'KillingFloorHUD.Perks.Perk_Support'
     OnHUDGoldIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Support_Gold'
	 OnHUDIcons(0)=(PerkIcon=Texture'KillingFloorHUD.Perks.Perk_Support',StarIcon=Texture'KillingFloorHUD.HUD.Hud_Perk_Star',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(1)=(PerkIcon=Texture'KillingFloor2HUD.Perk_Icons.Perk_Support_Gold',StarIcon=Texture'KillingFloor2HUD.Perk_Icons.Hud_Perk_Star_Gold',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(2)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Green',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Green',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(3)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Blue',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blue',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(4)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Purple',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Purple',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(5)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Orange',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Orange',DrawColor=(B=255,G=255,R=255,A=255))
	 OnHUDIcons(6)=(PerkIcon=Texture'ScrnTex.Perks.Perk_Support_Blood',StarIcon=Texture'ScrnTex.Perks.Hud_Perk_Star_Blood',DrawColor=(B=255,G=255,R=255,A=255))
     VeterancyName="Support Specialist"
     Requirements(0)="Weld %x door hitpoints"
     Requirements(1)="Deal %x damage with shotguns"
}
