// Written by .:..: (2009)
// Base class of all server veterancy types
class ScrnVeterancyTypes extends SRVeterancyTypes
    abstract;

#exec OBJ LOAD FILE=ScrnTex.utx

var byte RelatedPerkIndex;

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
    var class<Pickup>     PickupClass;
    var byte             MinPerkLevel;
    var byte            MaxPerkLevel;
    var bool            bSetAmmo;        // set weapon's ammo (true) or use initial amount (false)
    var int             AmmoAmount;     // initial ammo amount
    var float             AmmoPerLevel;     // ammo amount per each perk level above MinPerkLevel (excluding)
    var int             SellValue;        // sell value of the inventory
    var name            Achievement;    // Achievement that must be unlocked to get this weapon
    var byte            X;              // exclusion index. DefaultInventory[i] is not given if DefaultInventory[i-X] exist in the inventory.
};
var array<SDefaultInventory> DefaultInventory;

var class<HUDOverlay> HUDOverlay;

var Material HighDecMat;
var name SamePerkAch; // achievement to give when game is won by everybody are playing this perk only

var localized string SkillInfo;

var string ShortName;
var bool bHardcoreReady;
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

    for ( i = 0; i < AArray.length; ++i ) {
        if ( AArray[i] == AClass )
            return true;
    }
    return false;
}

//returns true if class or its parent is in a given array
final static function bool ClassChildIsInArray(out array <class> AArray, class AClass)
{
    local int i;

    if ( AClass == none )
        return false;

    for ( i = 0; i < AArray.length; ++i ) {
        if ( ClassIsChildOf(AClass, AArray[i]) )
            return true;
    }
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

// ProgressArray actually is not out, we use the keyword to pass array by reference instead of copying
static function int GetPerkProgressFromArray(ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum,
        out array<int> ProgressArray)
{
    local int result;

    if ( CurLevel < ProgressArray.Length ) {
        FinalInt = ProgressArray[curLevel];
    }
    else if ( CurLevel > 70 ) {
        // this should not happen
        FinalInt = 0x7FFFFFFF; // max signed int32
    }
    else {
        // legacy calculation. Not used anymore.
        FinalInt = ProgressArray[ProgressArray.Length-1] + GetDoubleScaling(CurLevel, ProgressArray[3]);
    }

    result = GetStatValueInt(StatOther, ReqNum);
    if ( result < 0 ) {
        result = 0x7FFFFFFF;
    }
    return min(result, FinalInt);
}

static function int GetPerkProgressInt(ClientPerkRepLink StatOther, out int FinalInt, byte CurLevel, byte ReqNum)
{
    if ( ReqNum == 1 && default.progressArray1.length > 3 ) {
        return GetPerkProgressFromArray(StatOther, FinalInt, CurLevel, ReqNum, default.progressArray1);
    }
    return GetPerkProgressFromArray(StatOther, FinalInt, CurLevel, ReqNum, default.progressArray0);
}

// Return 0-1 % of how much of the progress is done to gain this individual task (for menu GUI).
static function float GetPerkProgress( ClientPerkRepLink StatOther, byte CurLevel, byte ReqNum,
        out int Numerator, out int Denominator )
{
    local byte Minimum;
    local int Reduced,Cur,Fin;
    local bool bScale;

    bScale = !(StatOther.RequirementScaling ~= 1.0);

    if( CurLevel == StatOther.MaximumLevel ) {
        Denominator = 1;
        Numerator = 1;
        return 1.f;
    }

    if( StatOther.bMinimalRequirements ) {
        Minimum = 0;
        CurLevel = Max(CurLevel - StatOther.MinimumLevel, 0);
    }
    else {
        Minimum = StatOther.MinimumLevel;
    }
    Numerator = GetPerkProgressInt(StatOther, Denominator, CurLevel, ReqNum);
    if( bScale )
        Denominator*=StatOther.RequirementScaling;
    if( CurLevel > Minimum ) {
        GetPerkProgressInt(StatOther, Reduced, CurLevel-1, ReqNum);
        if( bScale )
            Reduced*=StatOther.RequirementScaling;
        Cur = Max(Numerator - Reduced,0);
        Fin = Max(Denominator - Reduced,0);
    }
    else {
        Cur = Numerator;
        Fin = Denominator;
    }

    log("GetPerkProgress CurLevel="$CurLevel $ " Numerator="$Numerator $ " Denominator="$Denominator);
    if( Fin<=0 ) // Avoid division by zero.
        return 1.f;
    return FMin(float(Cur)/float(Fin),1.f);
}

static function AddCustomStats( ClientPerkRepLink Other )
{
    // v8: achievement init moved to ScrnBalance.SetupRepLink()
    //class'ScrnAchievements'.static.InitAchievements(Other);
}

final static function byte GetBonusLevel(int level)
{
    if ( class'ScrnBalance'.default.Mut == none )
        return level; // happens at the end of the game (after ServerTravel)
    return Clamp(level, class'ScrnBalance'.default.Mut.MinLevel, class'ScrnBalance'.default.Mut.MaxLevel);
}

final static function byte GetClientVeteranSkillLevel(KFPlayerReplicationInfo KFPRI)
{
    if ( KFPRI == none )
        return 0;
    return GetBonusLevel(KFPRI.ClientVeteranSkillLevel);
}

static function bool CanBeGrabbed(KFPlayerReplicationInfo KFPRI, KFMonster Other)
{
    return KFGameReplicationInfo(KFPRI.Level.GRI).BaseDifficulty >= 4; // Can't be grabbed on Normal and below
}

final static function bool IsGunslingerEnabled()
{
    return true;
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
        else if ( Level > SPM )    {
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
        return class'ScrnNade';

    return super.GetNadeType(KFPRI);
}


static function string GetVetInfoText(byte Level, byte Type, optional byte RequirementNum)
{
    local byte BonusLevel;
    local string s;

    BonusLevel = GetBonusLevel(Level);
    switch( Type )
    {
        case 0:
            return default.LevelNames[Min(Level,ArrayCount(default.LevelNames)-1)]; // This was left in the void of unused...
        case 1:
            s = GetSkillInfo(BonusLevel);
            if ( s != "" )
                S $= "||";
            if( BonusLevel >= default.SRLevelEffects.Length )
                s $= GetCustomLevelInfo(BonusLevel);
            else
                s $= default.SRLevelEffects[BonusLevel];
            return s;
        case 2:
            return default.Requirements[RequirementNum];
        case 10:
            return GetSkillInfo(BonusLevel);
        case 11:
            if( BonusLevel >= default.SRLevelEffects.Length )
                return GetCustomLevelInfo(BonusLevel);
            else
                return default.SRLevelEffects[BonusLevel];
        default:
            return default.VeterancyName;
    }
}

static function string GetSkillInfo(byte Level)
{
    return default.SkillInfo;
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
static protected function bool ShouldExcludeDefaultInventory(int i, KFPlayerReplicationInfo KFPRI, Pawn P)
{
    if ( i < 0 || i >= default.DefaultInventory.length
            || default.DefaultInventory[i].PickupClass.default.InventoryType == none )
        return false;  // DefaultInventory item does not exist, therefore, it cannot exist in the inventory
    if ( P.FindInventoryType(default.DefaultInventory[i].PickupClass.default.InventoryType) != none )
        return true; // already exist
    if ( default.DefaultInventory[i].X > 0 )
        return ShouldExcludeDefaultInventory(i - default.DefaultInventory[i].X, KFPRI, P); // check exclusion index
    return false;
}

static protected function bool ShouldAddDefaultInventory(int i, KFPlayerReplicationInfo KFPRI, Pawn P)
{
    if ( i < 0 || i >= default.DefaultInventory.length
            || default.DefaultInventory[i].PickupClass.default.InventoryType == none )
        return false;  // DefaultInventory item does not exist, therefore, it cannot exist in the inventory
    if ( P.FindInventoryType(default.DefaultInventory[i].PickupClass.default.InventoryType) != none )
        return false; // already exist
    if ( default.DefaultInventory[i].X > 0 )
        return !ShouldExcludeDefaultInventory(i - default.DefaultInventory[i].X, KFPRI, P); // check exclusion index
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
    local ScrnBalance Mut;
    local bool bBalance;

    Mut = class'ScrnBalance'.default.Mut;
    bBalance = Mut.SpawnBalanceRequired();

    if ( Mut.bUseExpLevelForSpawnInventory && !bBalance )
        level = KFPRI.ClientVeteranSkillLevel;
    else
        level = GetBonusLevel(KFPRI.ClientVeteranSkillLevel);

    KFP = KFHumanPawn(P);
    if ( KFP == none )
        return; // OMG, some Stinky Clots are trying to use our perks!!! :O
    ScrnPawn = ScrnHumanPawn(P);
    L = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerController(KFP.Controller));

    for ( i=0; i<default.DefaultInventory.length; ++i ) {
        if ( default.DefaultInventory[i].PickupClass != none
                && level >= default.DefaultInventory[i].MinPerkLevel
                && level <= default.DefaultInventory[i].MaxPerkLevel
                && (default.DefaultInventory[i].Achievement == '' || (!bBalance
                    && class'ScrnAchCtrl'.static.IsAchievementUnlocked(L, default.DefaultInventory[i].Achievement))) )
        {
            ExtraAmmo = max(0, default.DefaultInventory[i].AmmoPerLevel * (level - default.DefaultInventory[i].MinPerkLevel));
            if ( !Mut.bSpawn0 )
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

// Set number times Zed Time can be extended
static function int ZedTimeExtensions(KFPlayerReplicationInfo KFPRI)
{
    return 1;
}

// TSC features (Team Survival Competition)
static function bool ShowEnemyHealthBars(KFPlayerReplicationInfo KFPRI, KFPlayerReplicationInfo EnemyPRI)
{
    return false;
}

/** Allows armor to reduce incoming damage.
 * @param KFPRI Injured's PRI
 * @param Injured pawn that takes damage
 * @param Instigator pawn that deals damage
 * @param InDamage incoming damage value
 * @param DmgType incoming damage type
 * @return Output damage
 */
static function int ShieldReduceDamage(KFPlayerReplicationInfo KFPRI, ScrnHumanPawn Injured, Pawn Instigator,
        int InDamage, class<DamageType> DmgType)
{
    return InDamage * GetBodyArmorDamageModifier(KFPRI);
}

/** Allows overriding item's corresponding perk index with perk's index.
 *  This can be used for  multi-perk items.
 *  By default perk index is overriden if a given pickup is in perked weapons or pickups arrays.
 *  @param Pickup : pickup class to check (must not be none!)
 *  @return true if Pickup.CorrespondingPerkIndex should be overrided with PerkIndex.
 *          false if Pickup.CorrespondingPerkIndex should stay intact.
 */
static function bool OverridePerkIndex( class<KFWeaponPickup> Pickup )
{
    return Pickup.default.CorrespondingPerkIndex == default.PerkIndex
            || Pickup.default.CorrespondingPerkIndex == default.RelatedPerkIndex
            || ClassIsInArray(default.PerkedWeapons, Pickup.default.InventoryType)
            || ClassIsInArray(default.PerkedPickups, Pickup);
}


defaultproperties
{
    PerkIndex=255
    RelatedPerkIndex=255
    progressArray0( 0)=5000
    progressArray0( 1)=25000
    progressArray0( 2)=100000
    progressArray0( 3)=500000
    progressArray0( 4)=1000000
    progressArray0( 5)=2000000
    progressArray0( 6)=3500000
    progressArray0( 7)=5500000
    progressArray0( 8)=8000000
    progressArray0( 9)=11000000
    progressArray0(10)=14500000
    progressArray0(11)=18500000
    progressArray0(12)=23000000
    progressArray0(13)=28000000
    progressArray0(14)=33500000
    progressArray0(15)=39500000
    progressArray0(16)=46000000
    progressArray0(17)=53000000
    progressArray0(18)=60500000
    progressArray0(19)=68500000
    progressArray0(20)=77000000
    progressArray0(21)=96000000
    progressArray0(22)=116000000
    progressArray0(23)=136000000
    progressArray0(24)=156000000
    progressArray0(25)=177000000
    progressArray0(26)=199000000
    progressArray0(27)=221000000
    progressArray0(28)=243000000
    progressArray0(29)=266000000
    progressArray0(30)=290000000
    progressArray0(31)=319000000
    progressArray0(32)=348000000
    progressArray0(33)=378000000
    progressArray0(34)=409000000
    progressArray0(35)=440000000
    progressArray0(36)=471000000
    progressArray0(37)=503000000
    progressArray0(38)=536000000
    progressArray0(39)=569000000
    progressArray0(40)=602000000
    progressArray0(41)=641000000
    progressArray0(42)=681000000
    progressArray0(43)=721000000
    progressArray0(44)=761000000
    progressArray0(45)=802000000
    progressArray0(46)=844000000
    progressArray0(47)=886000000
    progressArray0(48)=928000000
    progressArray0(49)=971000000
    progressArray0(50)=1015000000
    progressArray0(51)=1064000000
    progressArray0(52)=1113000000
    progressArray0(53)=1163000000
    progressArray0(54)=1214000000
    progressArray0(55)=1265000000
    progressArray0(56)=1316000000
    progressArray0(57)=1368000000
    progressArray0(58)=1421000000
    progressArray0(59)=1474000000
    progressArray0(60)=1527000000
    progressArray0(61)=1586000000
    progressArray0(62)=1646000000
    progressArray0(63)=1706000000
    progressArray0(64)=1766000000
    progressArray0(65)=1827000000
    progressArray0(66)=1889000000
    progressArray0(67)=1951000000
    progressArray0(68)=2013000000
    progressArray0(69)=2076000000
    progressArray0(70)=2140000000
    // max signed int32 value is 2 147 483 647 (0x7FFFFFFF). Progress array cannot exceed that.
}
