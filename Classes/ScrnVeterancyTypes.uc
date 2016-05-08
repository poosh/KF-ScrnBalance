// Written by .:..: (2009)
// Base class of all server veterancy types
class ScrnVeterancyTypes extends SRVeterancyTypes
    abstract;

#exec OBJ LOAD FILE=ScrnTex.utx

var array<int> progressArray0;
var array<int> progressArray1;

var array< class<Weapon> > PerkedWeapons; // W
var array< class<DamageType> > PerkedDamTypes; // P, S
var array< class<Pickup> > PerkedPickups; // $ 
var array< class<Ammunition> > PerkedAmmo; // A, B
var array< class<Weapon> > SpecialWeapons; // *

var class<KFWeaponDamageType> DefaultDamageType; // used for custom weapons to override damage type, allowing perk progress.
												 // DefaultDamageType must be granted with perk bonuses insed the perk class!
var class<KFWeaponDamageType> DefaultDamageTypeNoBonus; // this damage type should allow perk progress, but not damage bonus. Don't put it to AddDamage()!

var bool bLocked;   

struct PerkIconData {
	var texture PerkIcon;
	var texture StarIcon;
	var color DrawColor;
};   

var array<PerkIconData> OnHUDIcons;                                          
var bool bOldStyleIcons;

struct SDefaultInventory {
	var class<Pickup> 	PickupClass;
	var byte 			MinPerkLevel;
	var byte			MaxPerkLevel;
	var bool			bSetAmmo;		// set weapon's ammo (true) or use initial amount (false)
	var int 			AmmoAmount; 	// initial ammo amount
	var float 			AmmoPerLevel; 	// ammo amount per each perk level above MinPerkLevel (excluding)
	var int 			SellValue;		// sell value of the inventory
    var name            Achievement;    // Achievement that must be unlocked to get this weapon
    var byte            X;              // exclusion index. DefaultInventory[i] is not given if DefaultInventory[i-X] exist in the inventory.
};
var array<SDefaultInventory> DefaultInventory;

var class<HUDOverlay> HUDOverlay;

var Material HighDecMat;

// ==================================================  FUNCTIONS  ==================================================
      
// try to avoid using this function on client-side, except for bNetOwner      
final static function Pawn FindPawn(PlayerReplicationInfo PRI)
{
    local Pawn P;
    
    if ( PRI == none )
        return none;
    
    // Owner is set only on server-side or bNetOwner
    if ( Controller(PRI.Owner) != none )
        return Controller(PRI.Owner).Pawn;
    
    foreach PRI.DynamicActors(class'Pawn', P) {
        if ( P.PlayerReplicationInfo == PRI )
            return P;
    }
        
    return none;    
}
      
// Adds class to array. Doesn't add none or classes, which already are stored in array.
final static function bool ClassAddToArrayUnique( out array <class> AArray, class AClass )
{
    if ( AClass == none || ClassIsInArray(AArray, AClass) )
        return false;

    AArray[AArray.length] = AClass;
    return true;
}

// returns true if an array contains a given class 
final static function bool ClassIsInArray(out array <class> AArray, class AClass)
{
    local int i;
    
    if ( AClass == none )
        return false;
        
    while ( i < AArray.length )    
        if ( AArray[i++] == AClass )
            return true;
    return false;
}

//returns true if class or its parent is in a given array
final static function bool ClassChildIsInArray(out array <class> AArray, class AClass)
{
    local int i;
    
    if ( AClass == none )
        return false;
        
    while ( i < AArray.length )    
        if ( ClassIsChildOf(AClass, AArray[i++]) )
            return true;
    return false;
}

//output array to a log - for debugging
final static function LogArray(out array <class> AArray)
{
    local int i;
    
    if ( AArray.length == 0 )
        Log("Array is empty!");
    else {
        Log("Array elements:");
        while ( i < AArray.length )    
            Log(String(AArray[i++]));
        Log("End of array");
    }
}


//overload this to return perk specific stat values
static function int GetStatValueInt(ClientPerkRepLink StatOther, byte ReqNum)
{
  return 0;
}

static function array<int> GetProgressArray(byte ReqNum, optional out int DoubleScalingBase)
{
    switch (ReqNum) {
        case 1:
            DoubleScalingBase = default.progressArray1[3];
            return default.progressArray1;
    }
    DoubleScalingBase = default.progressArray0[3];
    return default.progressArray0;
}


static function int GetPerkProgressInt( ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum ) 
{
    local array<int> ProgressArray;
    local int DoubleScalingBase;
    
    ProgressArray = GetProgressArray(ReqNum, DoubleScalingBase);
    if ( CurLevel < ProgressArray.Length ) 
        FinalInt= ProgressArray[curLevel];
    else 
        FinalInt = ProgressArray[ProgressArray.Length-1]+GetDoubleScaling(CurLevel,DoubleScalingBase)*GetPost6RequirementScaling();
    
	return Min(GetStatValueInt(StatOther, ReqNum),FinalInt);
}

static function AddCustomStats( ClientPerkRepLink Other )
{
    // v8: achievement init moved to ScrnBalance.SetupRepLink()
    //class'ScrnBalanceSrv.ScrnAchievements'.static.InitAchievements(Other);    
}    

final static function float GetPost6RequirementScaling()
{
    return class'ScrnBalance'.default.Mut.Post6RequirementScaling;
}


final static function byte GetBonusLevel(int level)
{
    return Clamp(level, class'ScrnBalance'.default.Mut.MinLevel, class'ScrnBalance'.default.Mut.MaxLevel);
}
    
final static function byte GetClientVeteranSkillLevel(KFPlayerReplicationInfo KFPRI)
{
    // c&p from GetBonusLevel() to reduce function calls  -- PooSH
    return Clamp(KFPRI.ClientVeteranSkillLevel, class'ScrnBalance'.default.Mut.MinLevel, class'ScrnBalance'.default.Mut.MaxLevel);
}

final static function bool IsGunslingerEnabled()
{
    return class'ScrnBalance'.default.Mut.bGunslinger;
}

// Change the cost of the weapons player spawn with
// v6.10 - KF1054 - now KFHumanPawn.CreateInventoryVeterancy() requires direct sell value, not the %
static function float GetInitialCostScaling(KFPlayerReplicationInfo KFPRI, class<Pickup> Item)
{
	local byte level;
	
    if ( !class'ScrnBalance'.default.Mut.bSpawn0 ) {
		level = GetClientVeteranSkillLevel(KFPRI);
		if ( level >= 6 )
			return default.StartingWeaponSellPriceLevel6;
		if ( level == 5 )
			return default.StartingWeaponSellPriceLevel5;
	}
		
    return 0;
}

// Adjust visible distance of welded door health status (when holding welder)
static function float GetDoorHealthVisibilityScaling(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    return 1.5;
}


// Adds Amount of nades to player's inventory 
// (c) PooSH, 2012
static function GiveNades(KFHumanPawn P, int Amount)
{
    local inventory inv;
    local Frag aFrag;

    //can't use FindInventoryType, cuz need to search also subclasses (ScrnFrag) 
    //aFrag = Frag(P.FindInventoryType(class'Frag'));
    for ( inv = P.inventory; inv != none && aFrag == none ; inv = inv.Inventory )
        aFrag = Frag(inv);
    
    //if initial inventory doesn't exist yet - create it
    if ( aFrag == none ) {
        P.CreateInventoryVeterancy(P.RequiredEquipment[2], 0); 
        for ( inv = P.inventory; inv != none && aFrag == none ; inv = inv.Inventory )
            aFrag = Frag(inv);    
    }
    
    if ( aFrag != none)
        aFrag.ConsumeAmmo(0, -Amount);
}

//used in Gunslinger perk
// (c) PooSH, 2012
static function bool CheckCowboyMode(KFPlayerReplicationInfo KFPRI, class<Weapon> WeapClass)
{
    return false;
}


// Modify movement speed depending of a specific weapon
// Scaled to KFHumanPawn.GroundSpeed
// 0.5 - moves 50% faster
// -0.2 - moves 20% slower
static function float GetWeaponMovementSpeedBonus(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
	return 0.0;
}

//returns true if perk can "cook" nade, i.e. hold the trigger and throw nade on button release
//Weap indicates current weapon player holds (not the Frag!) 
static function bool CanCookNade(KFPlayerReplicationInfo KFPRI, Weapon Weap)
{
  return true;
}

//Do perk bonuses allow to display progress bar showing current grenade cooking state
static function bool CanShowNadeCookingBar(KFPlayerReplicationInfo KFPRI)
{
  return true;
}

// allows to adjust player's max health
static function float HealthMaxMult(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    return 1.0;
}

static function byte PreDrawPerk( Canvas C, byte Level, out Material PerkIcon, out Material StarIcon )
{
	local int idx;
    local byte SPM; // stars per medal
	
    if ( class'ScrnBalance'.default.Mut.b10Stars )
        SPM = 10;
    else
        SPM = 5;
        
	if ( class'ScrnVeterancyTypes'.default.bOldStyleIcons || default.OnHUDIcons.Length <= 2 ) {
		// old system
		if ( Level > (5*SPM) ) {
			PerkIcon = Default.OnHUDIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarMaterial;
			C.SetDrawColor(255, 255, 0, C.DrawColor.A); //orange
			Level-=5*SPM;
		}	
		else if ( Level > (4*SPM) ) {
			PerkIcon = Default.OnHUDGoldIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
			C.SetDrawColor(200, 0, 255, C.DrawColor.A); // purple
			Level-=4*SPM;
		}
		else if ( Level > (3*SPM) ) {
			PerkIcon = Default.OnHUDGoldIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
			Level-=3*SPM;
			C.SetDrawColor(0, 128, 255, C.DrawColor.A); // light blue
		}
		else if ( Level > (2*SPM) ) {
			PerkIcon = Default.OnHUDGoldIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
			Level-=2*SPM;
			C.SetDrawColor(0, 255, 0, C.DrawColor.A); // green
		}
		else if ( Level > SPM )	{
			PerkIcon = Default.OnHUDGoldIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarGoldMaterial;
			Level-=SPM;
			C.SetDrawColor(255, 255, 255, C.DrawColor.A);
		}
		else {
			PerkIcon = Default.OnHUDIcon;
			StarIcon = Class'HUDKillingFloor'.Default.VetStarMaterial;
			C.SetDrawColor(255, 255, 255, C.DrawColor.A);
		}
	}
	else {
		//new system
		if ( Level <= SPM ) {
			idx = 0;
		}
		else {
			idx = min((Level-1)/SPM, default.OnHUDIcons.Length - 1);
			Level -= idx*SPM;
		}
		PerkIcon = default.OnHUDIcons[idx].PerkIcon;
		StarIcon = default.OnHUDIcons[idx].StarIcon;
		C.DrawColor.R = default.OnHUDIcons[idx].DrawColor.R;
		C.DrawColor.G = default.OnHUDIcons[idx].DrawColor.G;
		C.DrawColor.B = default.OnHUDIcons[idx].DrawColor.B;
		C.DrawColor.A = default.OnHUDIcons[idx].DrawColor.A;
	}
	//return Min(Level,15); // max 15 stars to draw
	return Level;
}



static function class<Grenade> GetNadeType(KFPlayerReplicationInfo KFPRI)
{
	if ( class'ScrnBalance'.default.Mut.bReplaceNades ) 
        return class'ScrnBalanceSrv.ScrnNade';

	return super.GetNadeType(KFPRI);
}


static function string GetVetInfoText(byte Level, byte Type, optional byte RequirementNum)
{
    return super.GetVetInfoText(GetBonusLevel(Level), Type, RequirementNum);
}

static function bool IsAdmin(PlayerController Player)
{
    return Player != none && Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.bAdmin;
}
// Return the level of perk that is available, 0 = perk is n/a.
static function byte PerkIsAvailable(ClientPerkRepLink StatOther)
{
    if ( default.bLocked )
        return 0;
        
	return super.PerkIsAvailable(StatOther);
}

static function bool LevelIsFinished(ClientPerkRepLink StatOther, byte CurLevel)
{
    if ( default.bLocked )
        return false;
        
    return super.LevelIsFinished(StatOther, CurLevel);
}

// Reduce damage zombies can deal to you
static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	return InDamage;
}

// checks if inventory already exists and exclusion index
static protected function bool ShouldAddDefaultInventory(int i, KFPlayerReplicationInfo KFPRI, Pawn P)
{
    if ( i < 0 || i >= default.DefaultInventory.length 
            || default.DefaultInventory[i].PickupClass.default.InventoryType == none )
        return false;
    if ( P.FindInventoryType(default.DefaultInventory[i].PickupClass.default.InventoryType) != none )
        return false; // already exist
    if ( default.DefaultInventory[i].X > 0 )
        return ShouldAddDefaultInventory(i - default.DefaultInventory[i].X, KFPRI, P); // check exclusion index
    return true;
}

static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
	local KFHumanPawn KFP;
	local ScrnHumanPawn ScrnPawn;
    local ClientPerkRepLink L;
	local int i;
	local byte level;
	local Weapon W;
    local Ammunition AmmoInv;
	local class<ScrnVestPickup> ScrnVest;
	local int ExtraAmmo;
	local float SellValue;
	
	if ( class'ScrnBalance'.default.Mut.bUseExpLevelForSpawnInventory )
		level = KFPRI.ClientVeteranSkillLevel;
	else
		level = GetBonusLevel(KFPRI.ClientVeteranSkillLevel);
	
	KFP = KFHumanPawn(P);
	if ( KFP == none )
		return; // OMG, some Stinky Clots are trying to use our perks!!! :O
	ScrnPawn = ScrnHumanPawn(P);
    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerController(KFP.Controller));
		
	for ( i=0; i<default.DefaultInventory.length; ++i ) {
		if ( level >= default.DefaultInventory[i].MinPerkLevel && level <= default.DefaultInventory[i].MaxPerkLevel 
                && (default.DefaultInventory[i].Achievement == '' 
                    || class'ScrnAchievements'.static.IsAchievementUnlocked(L, default.DefaultInventory[i].Achievement)) ) 
        {
			ExtraAmmo = max(0, default.DefaultInventory[i].AmmoPerLevel * (level - default.DefaultInventory[i].MinPerkLevel));
			if ( !class'ScrnBalance'.default.Mut.bSpawn0 )
				SellValue = default.DefaultInventory[i].SellValue;
			ScrnVest = class<ScrnVestPickup>(default.DefaultInventory[i].PickupClass);
			if ( ScrnVest != none || class<ShieldPickup>(default.DefaultInventory[i].PickupClass) != none ) {
				if ( ScrnVest != none && ScrnPawn != none )
					ScrnPawn.SetVestClass(ScrnVest);
				// make sure we call AddShieldStrength() instead of simple value changing
				// to set ShieldStrengthMax and Weight
				KFP.AddShieldStrength(default.DefaultInventory[i].AmmoAmount + ExtraAmmo);
			}
			else if ( class<CashPickup>(default.DefaultInventory[i].PickupClass) != none ) {
				if ( KFP.PlayerReplicationInfo != none )
					KFP.PlayerReplicationInfo.Score += default.DefaultInventory[i].AmmoAmount + ExtraAmmo;
			}
            else if ( class<Ammo>(default.DefaultInventory[i].PickupClass) != none ) {
                AmmoInv = Ammunition(KFP.FindInventoryType(default.DefaultInventory[i].PickupClass.default.InventoryType));
                if ( AmmoInv != none )
                    AmmoInv.AddAmmo(default.DefaultInventory[i].AmmoAmount + ExtraAmmo);
            }
			else if ( ShouldAddDefaultInventory(i, KFPRI, P) ) {
				KFP.CreateInventoryVeterancy(string(default.DefaultInventory[i].PickupClass.default.InventoryType), SellValue);
				if (  default.DefaultInventory[i].bSetAmmo ) {
					W = Weapon(KFP.FindInventoryType(default.DefaultInventory[i].PickupClass.default.InventoryType));
					if ( W != none )
						W.AddAmmo(default.DefaultInventory[i].AmmoAmount + ExtraAmmo - W.AmmoAmount(0), 0);
				}
			}
		}
	}
}

static function float GetMagCapacityMod(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	return GetMagCapacityModStatic(KFPRI, Other.class);
}
static function float GetMagCapacityModStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	return 1.0;
}

// Modify weapon reload speed
static function float GetReloadSpeedModifier(KFPlayerReplicationInfo KFPRI, KFWeapon Other)
{
	return GetReloadSpeedModifierStatic(KFPRI, Other.class);
}
static function float GetReloadSpeedModifierStatic(KFPlayerReplicationInfo KFPRI, class<KFWeapon> Other)
{
	return 1.0;
}

// Modify fire speed
static function float GetFireSpeedMod(KFPlayerReplicationInfo KFPRI, Weapon Other)
{
	return GetFireSpeedModStatic(KFPRI, Other.class);
}
static function float GetFireSpeedModStatic(KFPlayerReplicationInfo KFPRI, class<Weapon> Other)
{
	return 1.0;
}


// TSC featurs (Team Survival Competition)
static function bool ShowEnemyHealthBars(KFPlayerReplicationInfo KFPRI, KFPlayerReplicationInfo EnemyPRI)
{
    return false;
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
}
