class ScrnHumanPawn extends SRHumanPawn;

var float HealthRestoreRate; // how fast player can be healed (hp/s)
var float HealthToGiveRemainder; // pawn receives integer amount of hp. remainder should be moved to next healing tick
var byte ClientHealthToGive; //required for client replication


var const class<ScrnVestPickup> NoVestClass;            // dummy class that indicates player has no armor
var const class<ScrnVestPickup> StandardVestClass;      // standard KF armor (combat armor)
var const class<ScrnVestPickup> LightVestClass;     // Warning! LightVestClass must have no weight (weight=0)
var private class<ScrnVestPickup> CurrentVestClass;     // Equipped shield class

var private transient class<KFVeterancyTypes> PrevPerkClass;
var private transient int PrevPerkLevel;

var bool bCowboyMode;

var transient ScrnHumanPawn   LastHealedBy; // last player who healed me
var transient ScrnHumanPawn   LastHealed; // last player, who was healed by me
var transient KFMonster       CombatMedicTarget; // "LastHealedBy" must kill this monster to earn an ach
var transient int             HealthBeforeHealing;
var transient float           LastDamageTime;
var transient float           LastExplosionTime;
var transient float           LastExplosionDistance; // distance between player and explosions's epicenter

// Seems like bonus ammo is fixed in v1051 and not needed anymore
// var class<Ammunition> BonusAmmoClass;
// var int BonusAmmoAmount;

var ScrnGameRules GameRules;
var bool bCheckHorzineArmorAch;

// used in AssessThreatTo()
var protected transient KFMonsterController LastThreatMonster;
var protected transient float LastThreatTime, LastThreat;

var localized string strNoSpawnCashToss;


struct SWeaponFlashlight {
    var class<KFWeapon> WeaponClass;
    var int TorchBatteryLife, MaxBatteryLife;
};
var array<SWeaponFlashlight> WeaponFlashlights;

var Sound HeadshotSound;

var transient int HealthBeforeDeath; // in cases when death is not caused by health drop down to 0
var transient float NextEnemyBaseDamageMsg; //reserved for TSC

var() int HealthBonus;

var KFPlayerReplicationInfo KFPRI;
var class<ScrnVeterancyTypes> ScrnPerk;

var transient bool bAmIBaron; // :trollface:

// spectator info
var bool bViewTarget; // somebody spectating me
var class<KFWeapon> SpecWeapon;
var byte AmmoStatus;
var byte SpecWeight, SpecMagAmmo, SpecMags, SpecSecAmmo, SpecNades;

var     transient Frag          PlayerGrenade;

var bool bTraderSpeedBoost;
var float TraderSpeedBoost;
var byte MacheteBoost; // that's one of the most retarded things I've done
var float MacheteResetTime;

var transient KFMeleeGun QuickMeleeWeapon;
var transient KFWeapon WeaponToFixClientState;
var transient bool bQuickMeleeInProgress;

var localized string BlameStrM99;
var localized string BlameStrRPG;

replication
{
    reliable if( bNetOwner && Role == ROLE_Authority )
        ClientSetInventoryGroup;

    reliable if( bNetOwner && Role == ROLE_Authority )
        QuickMeleeWeapon, MacheteBoost;

    reliable if( Role == ROLE_Authority )
        ClientSetVestClass; //send it to all clients, cuz they need to know max health and max shield

    reliable if( bNetDirty && Role == ROLE_Authority )
        ClientHealthToGive, HealthBonus; // all clients  need to know it to properly display it on the hud

    reliable if( bNetDirty && Role == ROLE_Authority )
        SpecWeapon, AmmoStatus;
    reliable if( bNetDirty && bViewTarget && Role == ROLE_Authority )
        SpecWeight, SpecMagAmmo, SpecMags, SpecSecAmmo, SpecNades;

    // seem like that there is no need to replicate bCowboyMode, because it is used only on local player,
    // which can set it himself
    // reliable if( !bNetOwner && bNetDirty && Role == ROLE_Authority )
        // bCowboyMode; // net owner can check cowboy mode himself

    reliable if(Role < ROLE_Authority)
        ServerBuyShield, ServerSellShield;

    reliable if(Role < ROLE_Authority)
        ServerReload, ServerFire;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    FindGameRules();
    ReplaceRequiredEquipment();

    if ( SoundGroupClass == none )
        SoundGroupClass = Class'KFMod.KFMaleSoundGroup';

    HealthMax += HealthBonus;
    Health += HealthBonus;

    bTraderSpeedBoost = class'ScrnBalance'.default.Mut.bTraderSpeedBoost;
}

function ReplaceRequiredEquipment()
{
    local int i;
    local KFLevelRules_Story StoryRules;
    local ScrnBalance Mut;

    Mut = class'ScrnBalance'.static.Myself(Level);

    if ( KFStoryGameInfo(Level.Game) != none ) {
        StoryRules = KFStoryGameInfo(Level.Game).StoryRules;
        for ( i = 0; i < StoryRules.RequiredPlayerEquipment.Length; ++i ) {
            if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Knife' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnBalanceSrv.ScrnKnife';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Single' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnBalanceSrv.ScrnSingle';
            else if ( Mut.bReplaceNades && StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Frag' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnBalanceSrv.ScrnFrag';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Syringe' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnBalanceSrv.ScrnSyringe';
        }
    }
    else if ( Mut.bNoRequiredEquipment ) {
        for ( i=0; i<16; ++i )
            RequiredEquipment[i] = "";
    }
    else {
        RequiredEquipment[0] = String(class'ScrnBalanceSrv.ScrnKnife');
        RequiredEquipment[1] = String(class'ScrnBalanceSrv.ScrnSingle');
        if ( Mut.bReplaceNades ) {
            RequiredEquipment[2] = String(class'ScrnBalanceSrv.ScrnFrag');
        }
        RequiredEquipment[3] = String(class'ScrnBalanceSrv.ScrnSyringe');
    }
}


function RecalcWeight()
{
    local Inventory Inv;
    local KFWeapon Weap;
    local int c;

    CurrentWeight = CurrentVestClass.default.Weight;

    for ( Inv = Inventory; Inv != none && ++c < 1000; Inv = Inv.Inventory ) {
        Weap = KFWeapon(Inv);
        if (Weap == none)
            continue;

        if ( ScrnFrag(Weap) != none )
            Weap.Weight = Weap.default.Weight;

        CurrentWeight +=  Weap.Weight;
    }
}


// Changed MaxCarryWeight to default.MaxCarryWeight, so support with 15/24 weight will move with same speed as other perk 15/15
// Support with 24/24 weight now will move slower
// Other code strings are just copy-pasted
simulated function ModifyVelocity(float DeltaTime, vector OldVelocity)
{
    local float WeightMod, HealthMod, MovementMod;
    local float EncumbrancePercentage;
    local Inventory Inv;
    local KF_StoryInventoryItem StoryInv;
    local int c;

    super(KFPawn).ModifyVelocity(DeltaTime, OldVelocity);

    if ( Controller != none )
    {
        // Calculate encumbrance, but cap it to the maxcarryweight so when we use dev weapon cheats we don't move mega slow
        EncumbrancePercentage = (FMin(CurrentWeight, MaxCarryWeight) / default.MaxCarryWeight); //changed MaxCarryWeight to default.MaxCarryWeight
        // Calculate the weight modifier to speed
        WeightMod = (1.0 - (EncumbrancePercentage * WeightSpeedModifier));
        // Calculate the health modifier to speed
        HealthMod = ((Health/HealthMax) * HealthSpeedModifier) + (1.0 - HealthSpeedModifier);

        // Apply all the modifiers
        GroundSpeed = default.GroundSpeed * HealthMod;
        GroundSpeed *= WeightMod;
        GroundSpeed += InventorySpeedModifier;

        if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
            MovementMod = KFPRI.ClientVeteranSkill.static.GetMovementSpeedModifier(KFPRI, KFGameReplicationInfo(Level.GRI));
        else
            MovementMod = 1.0;
        GroundSpeed *= MovementMod;
        AccelRate = default.AccelRate * MovementMod;


        /* Give the pawn's inventory items a chance to modify his movement speed */
        for( Inv=Inventory; Inv!=None && ++c < 1000; Inv=Inv.Inventory )
        {
            GroundSpeed *= Inv.GetMovementModifierFor(self);

            StoryInv = KF_StoryInventoryItem(Inv);
            if(StoryInv != none && StoryInv.bUseForcedGroundSpeed)
            {
                GroundSpeed = StoryInv.ForcedGroundSpeed;
                return;
            }
        }

        if ( bTraderSpeedBoost && !KFGameReplicationInfo(Level.GRI).bWaveInProgress )
            GroundSpeed *= TraderSpeedBoost;

        GroundSpeed += MacheteBoost;
    }


}


function PossessedBy(Controller C)
{
    Super.PossessedBy(C);

    KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
    ScrnPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
    if ( PlayerController(C) != none )
        bAmIBaron = PlayerController(C).GetPlayerIDHash() == "76561198006289592";
}

function UnPossessed()
{
    super.UnPossessed();

    KFPRI = none;
    ScrnPerk = none;
}


simulated function ClientSetInventoryGroup( class<Inventory> NewInventoryClass, byte NewInventoryGroup )
{
    local Inventory Inv;
    local int c;

    if ( Role < ROLE_Authority ) {
        //need to change default value to, because it is using in some static functions
        NewInventoryClass.default.InventoryGroup = NewInventoryGroup;
        //search the client inventory for the specified class and change its group
        for ( Inv=Inventory; Inv!=None && ++c < 1000 ; Inv=Inv.Inventory ) {
            if ( Inv.class == NewInventoryClass ) {
                Inv.InventoryGroup = NewInventoryGroup;
                return;
            }
        }
    }
}

// handle pickup
// function HandlePickup(Pickup pick)
// {
    // super.HandlePickup()
// }




function bool AddInventory( inventory NewItem )
{
    local KFWeapon weap;
    local bool GroupChanged;
    // local KFAmmunition ammo;

    weap = KFWeapon(NewItem);
    if( weap != none ) {
        //log("AddInventory:" @ weap, 'ScrnBalance');
        if ( Dualies(weap) != none ) {
            if ( (DualDeagle(weap) != none || Dual44Magnum(weap) != none || DualMK23Pistol(weap) != none)
                  && weap.InventoryGroup != 4 ) { //skip special weapons like Laser-44
                // Move dual pistols to slot 3 for Gunslinger perk, so he can easier to cycle them
                if ( KFPRI != none && ClassIsChildOf(KFPRI.ClientVeteranSkill, class'ScrnBalanceSrv.ScrnVetGunslinger') )
                    weap.InventoryGroup = 3;
                else
                    weap.InventoryGroup = 2; //leave dual pistols in slot 2 for other perks
                GroupChanged = true;
            }
        }
        else if ( weap.class == class'Single' ) {
            weap.bKFNeverThrow = false;
        }

        weap.bIsTier3Weapon = true; // hack to set weap.Tier3WeaponGiver for all weapons
    }

    //replicate changes on the client side
    if ( GroupChanged )
        ClientSetInventoryGroup(NewItem.class, NewItem.InventoryGroup);

    if ( super.AddInventory(NewItem) ) {
        if ( weap != none ) {
            if ( weap.bTorchEnabled )
                AddToFlashlightArray(weap.class); // v6.22 - each weapon has own flashlight
            CheckQuickMeleeWeapon(KFMeleeGun(weap));
            if ( class'ScrnBalance'.default.Mut.SrvTourneyMode == 0 && Machete(weap) != none ) {
                if ( MacheteBoost < 250 && VSizeSquared(Velocity) > 10000 ) {
                    if ( MacheteBoost < 50 )
                        MacheteBoost += 3;
                    else if ( MacheteBoost < 100 )
                        MacheteBoost += 2;
                    else
                        MacheteBoost++;
                }
                MacheteResetTime = Level.TimeSeconds + 5.0;
            }
        }
        return true;
    }
    return false;
}

function DeleteInventory( inventory Item )
{
    super.DeleteInventory(Item);
    if ( Item == QuickMeleeWeapon ) {
        QuickMeleeWeapon = none;
        SetBestQuickMeleeWeapon();
        // for machete-walking
        if ( QuickMeleeWeapon != none )
            PendingWeapon = QuickMeleeWeapon;
    }
}

// todo: add support for modded guns
function bool ValidQuickMeleeWeapon(KFMeleeGun W)
{
    if ( W == none )
        return false;

    return ScrnKnife(W) != none || ScrnMachete(W) != none;
}

function bool CheckQuickMeleeWeapon(KFMeleeGun W)
{
    if ( !ValidQuickMeleeWeapon(W) )
        return false;

    if ( QuickMeleeWeapon == none || class<KFMeleeFire>(QuickMeleeWeapon.FireModeClass[1]).default.MeleeDamage <
            class<KFMeleeFire>(W.FireModeClass[1]).default.MeleeDamage )
    {
        QuickMeleeWeapon = W;
        return true;
    }
    return false;
}

function SetBestQuickMeleeWeapon()
{
    local inventory inv;
    local KFMeleeGun W;
    local int c;

    for ( inv = Inventory; inv != none && ++c < 1000; inv = inv.Inventory) {
        W = KFMeleeGun(inv);
        if ( W != none )
            CheckQuickMeleeWeapon(W);
    }
}

// The player wants to switch to weapon group number F.
// Merged code from Pawn and KFHumanPawn + added ability to switch perked weapon first and empty guns last
simulated function SwitchWeapon(byte F)
{
    local Inventory Inv;
    local Weapon W;
    local bool bPerkedFirst;
    local array<Weapon> SortedGroupInv; // perked -> non-perked -> empy
    local int NonPerkedIndex, EmptyIndex, i;
    local class<KFWeaponPickup> WP;

    if ( (Level.Pauser!=None) || (Inventory == None) )
        return;
    if ( PendingWeapon != None && PendingWeapon.bForceSwitch )
        return;
    if ( bQuickMeleeInProgress )
        return;

    bPerkedFirst = ScrnPerk != none && ScrnPlayerController(Controller) != none && ScrnPlayerController(Controller).bPrioritizePerkedWeapons;

    // sort group inventory
    for ( Inv = Inventory; Inv != none && ++i < 1000; Inv = Inv.Inventory ) {
        W = Weapon(Inv);
        if ( W != none && W.InventoryGroup == F && AllowHoldWeapon(W) ) {
            WP = class<KFWeaponPickup>(W.PickupClass);
            if ( !W.HasAmmo() && (KFWeapon(W) == none || (KFWeapon(W).bConsumesPhysicalAmmo && !KFWeapon(W).bMeleeWeapon)) ) {
                // weapon has no ammo
                SortedGroupInv[SortedGroupInv.length] = W;
            }
            else if ( bPerkedFirst && (PipeBombExplosive(W) != none || Knife(W) != none
                    || WP == none
                    || (WP.default.CorrespondingPerkIndex != ScrnPerk.default.PerkIndex
                        && !ScrnPerk.static.OverridePerkIndex(WP))) )
            {
                // non-perked weapon, has ammo
                SortedGroupInv.insert(EmptyIndex, 1);
                SortedGroupInv[EmptyIndex] = W;
                EmptyIndex++;
            }
            else {
                // perked weapon, has ammo
                if ( Boomstick(W) != none && ScrnPlayerController(Controller) != none && ScrnPlayerController(Controller).bPrioritizeBoomstick ) {
                    SortedGroupInv.insert(0, 1);
                    SortedGroupInv[0] = W;
                }
                else {
                    SortedGroupInv.insert(NonPerkedIndex, 1);
                    SortedGroupInv[NonPerkedIndex] = W;
                }
                NonPerkedIndex++;
                EmptyIndex++;
            }
        }
    }

    if ( SortedGroupInv.length == 0 )
        return; // no weapons in current category

    if ( Weapon == none || Weapon.InventoryGroup != F || SortedGroupInv.length == 1 )
        W = SortedGroupInv[0];
    else {
        for ( i=0; i<SortedGroupInv.length; ++i ) {
            if ( Weapon == SortedGroupInv[i] ) {
                i++; // switch to next weapon
                break;
            }
        }
        if ( i < SortedGroupInv.length )
            W = SortedGroupInv[i];
        else
            W = SortedGroupInv[0];
    }

    if ( W != none && W != Weapon ) {
        PendingWeapon = W;
        if ( Weapon != None )
            Weapon.PutDown();
        else
            ChangedWeapon();
    }
}

simulated function ChangedWeapon()
{
    super(KFPawn).ChangedWeapon();

    if (Role < ROLE_Authority) {
        ApplyWeaponStats(Weapon);
    }

    if ( IsLocallyControlled() && ScrnPlayerController(Controller) != none )
        ScrnPlayerController(Controller).LoadGunSkinFromConfig();
}

function ServerChangedWeapon(Weapon OldWeapon, Weapon NewWeapon)
{
    local ScrnPlayerController PC;
    local int i;

    PC = ScrnPlayerController(Controller);
    if ( NewWeapon != none && PC != none) {
        // set skinned attachment class
        for ( i=0; i<PC.WeaponSettings.length; ++i ) {
            if ( NewWeapon.class == PC.WeaponSettings[i].Weapon ) {
                if ( PC.WeaponSettings[i].SkinnedWeapon != none )
                    NewWeapon.AttachmentClass = PC.WeaponSettings[i].SkinnedWeapon.default.AttachmentClass;
                break;
            }
        }
    }

    super(KFPawn).ServerChangedWeapon(OldWeapon,NewWeapon);
    ApplyWeaponStats(NewWeapon);
    ApplyWeaponFlashlight(false);
}

function UpdateSpecInfo()
{
    local KFWeapon Weap;

    SpecWeight = CurrentWeight;
    Weap = KFWeapon(Weapon);
    if ( Weap != none ) {
        SpecWeapon = Weap.class;
        SpecMagAmmo = Weap.MagAmmoRemaining;
        if (  Weap.MagCapacity <= 1 ) {
            SpecMags = Weap.AmmoAmount(0);
        }
        else if ( Weap.bHoldToReload )
            SpecMags = Max(Weap.AmmoAmount(0)-Weap.MagAmmoRemaining,0); // Single rounds reload, just show the true ammo count.
        else if ( Weap.MagCapacity <= 1 )
            SpecMags = Weap.AmmoAmount(0);
        else if ( Weap.AmmoAmount(0) <= Weap.MagAmmoRemaining )
            SpecMags = 0;
        else
            SpecMags = ceil(float(Weap.AmmoAmount(0) - Weap.MagAmmoRemaining)/Weap.MagCapacity);

        if ( Weap.bHasSecondaryAmmo )
            SpecSecAmmo = Weap.AmmoAmount(1);
        else
            SpecSecAmmo = 0;
    }
    else
        SpecWeapon = none;

    if ( FindPlayerGrenade() != none )
        SpecNades = PlayerGrenade.AmmoAmount(0);
    else
        SpecNades = 0;
}

simulated function ApplyWeaponStats(Weapon NewWeapon)
{
    local KFWeapon Weap;
    //local KFShotgunFire SgFire;

    BaseMeleeIncrease = default.BaseMeleeIncrease;
    InventorySpeedModifier = 0;

    Weap = KFWeapon(NewWeapon);

    // check cowboy mode
    if ( Role == ROLE_Authority || IsLocallyControlled() ) {
        bCowboyMode = ScrnPerk != none && Weap != none && ScrnPerk.static.CheckCowboyMode(KFPRI, Weap.class);

        if ( Weap != none ) {
            if ( Weap.class == class'Dualies' || ClassIsChildOf(Weap.class, class'ScrnDualies') ) {
                // Machine Pistols for Cowboy!
                Weap.GetFireMode(0).bWaitForRelease = !bCowboyMode;
                Weap.GetFireMode(0).bNowWaiting = Weap.GetFireMode(0).bWaitForRelease;
            }
        }

        if ( Role == ROLE_Authority ) {
            if ( ScrnPlayerController(Controller) != none )
                ScrnPlayerController(Controller).bCowboyForWave = bCowboyMode && ScrnPlayerController(Controller).bCowboyForWave;
            UpdateSpecInfo();
        }
    }

    SetAmmoStatus();
    if ( KFPRI != none && Weap != none ) {
        Weap.bIsTier3Weapon = Weap.default.bIsTier3Weapon; // restore default value from the hack in AddInventory()

        if ( Weap.bSpeedMeUp ) {
            if ( KFPRI.ClientVeteranSkill != none )
                BaseMeleeIncrease += KFPRI.ClientVeteranSkill.Static.GetMeleeMovementSpeedModifier(KFPRI);
            InventorySpeedModifier = (default.GroundSpeed * BaseMeleeIncrease) - (Weap.Weight * 2);
        }

        if ( ScrnPerk != none ) {
            InventorySpeedModifier +=
                default.GroundSpeed * ScrnPerk.static.GetWeaponMovementSpeedBonus(KFPRI, NewWeapon);
        }
        // ScrN Armor can slow down players (or even boost) -- PooSH
        InventorySpeedModifier -= default.GroundSpeed * CurrentVestClass.default.SpeedModifier;
    }


    //fix spawn offsets for projectile fire modes
    //exclude healing nades, cuz they detonate on instigator too
    // if ( Weap != none && ScrnM79M(Weap) == none && ScrnM4203MMedicGun(Weap) == none) {
        // SgFire = KFShotgunFire(NewWeapon.GetFireMode(0));
        // if ( SgFire != none && SgFire.ProjSpawnOffset.X > 15 ) {
            // SgFire.ProjSpawnOffset.X = 15;
        // }
        // SgFire = KFShotgunFire(NewWeapon.GetFireMode(1));
        // if ( SgFire != none && SgFire.ProjSpawnOffset.X > 15 ) {
            // SgFire.ProjSpawnOffset.X = 15;
        // }
    // }
}

function CheckPerkAchievements()
{
    local ScrnPlayerController ScrnPlayer;
    local ClientPerkRepLink StatRep;
    local int i;

    if ( Role < ROLE_Authority )
        return; // ROLE_AutonomousProxy can execute non-simulated functions too

    ScrnPlayer = ScrnPlayerController(Controller);
    if ( KFPRI == none || KFPRI.ClientVeteranSkill == none || ScrnPlayer == none )
        return;

    if ( KFPRI.ClientVeteranSkill != ScrnPlayer.InitialPerkClass ) {
        if ( KFGameType(Level.Game).WaveNum == 0 && ScrnPlayer.InitialPerkClass == none ) {
            ScrnPlayer.InitialPerkClass = KFPRI.ClientVeteranSkill;
            ScrnPlayer.bChangedPerkDuringGame = false;
        }
        else {
            ScrnPlayer.bChangedPerkDuringGame = true;
        }
    }

    StatRep = SRStatsBase(ScrnPlayer.SteamStatsAndAchievements).Rep;
    if ( StatRep == none )
        return;

    if ( KFPRI.ClientVeteranSkillLevel < 6 )
        return;

    if ( KFPRI.ClientVeteranSkillLevel >= 26 )
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(StatRep, 'PerkOrange', 1);
    else if ( KFPRI.ClientVeteranSkillLevel >= 21 )
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(StatRep, 'PerkPurple', 1);
    else if ( KFPRI.ClientVeteranSkillLevel >= 16 )
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(StatRep, 'PerkBlue', 1);
    else if ( KFPRI.ClientVeteranSkillLevel >= 11 )
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(StatRep, 'PerkGreen', 1);

    // Mr. Perky
    for ( i = 0; i < StatRep.CachePerks.length; ++i ) {
        if ( StatRep.CachePerks[i].CurrentLevel < 6 )
            return;
    }
    class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(StatRep, 'MrPerky', 1);
}

simulated function VeterancyChanged()
{
    local Inventory Inv, NextInv;
    local int c;

    MaxCarryWeight = Default.MaxCarryWeight;

    if ( KFPRI == none )
        return;

    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        MaxCarryWeight += KFPRI.ClientVeteranSkill.Static.AddCarryMaxWeight(KFPRI);

    if ( CurrentWeight > MaxCarryWeight )   {
        // drop extra weight
        for ( Inv = Inventory; Inv != none && CurrentWeight > MaxCarryWeight && ++c < 1000; Inv = NextInv ) {
            NextInv = Inv.Inventory; // save next link before deleting this one
            if ( KFWeapon(Inv) != none && !KFWeapon(Inv).bKFNeverThrow ) {
                Inv.Velocity = Velocity;
                Inv.DropFrom(Location + VRand() * 10);
            }
        }
    }

    ScrnPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
    if ( ScrnPerk != none )
        HealthMax = (default.HealthMax + HealthBonus) * ScrnPerk.static.HealthMaxMult(KFPRI, self);
    ApplyWeaponStats(Weapon);
    RecalcAmmo();
    CheckPerkAchievements();
    PrevPerkClass = KFPRI.ClientVeteranSkill;
    PrevPerkLevel = KFPRI.ClientVeteranSkillLevel;
}

// recalculates ammo bonuses
function RecalcAmmo()
{
    local Inventory CurInv;
    local Ammunition MyAmmo;
    local float ClipPrice, FullRefillPrice;
    local int ClipSize;
    local int c;

    for ( CurInv = Inventory; CurInv != none && ++c < 1000; CurInv = CurInv.Inventory ) {
        if ( KFAmmunition(CurInv) != none ) {
            // just call this function to apply perk bonuses
            CalcAmmoCost(self, Class<Ammunition>(CurInv.class), MyAmmo, ClipPrice, FullRefillPrice, ClipSize);
        }
    }
}

function DestroyMyPipebombs(optional int CountToLeave)
{
    local PipeBombProjectile P;

    foreach DynamicActors(Class'PipeBombProjectile',P)
    {
        if( !P.bHidden && P.Instigator==self )
        {
            if ( CountToLeave > 0 )
                CountToLeave--;
            else
                P.bEnemyDetected = true; // blow me up
        }
    }
}


// ===================================== SHIELD =====================================
simulated function class<ScrnVestPickup> GetVestClass()
{
    if ( CurrentVestClass == NoVestClass ) {
        if ( CanUseVestClass(StandardVestClass) )
            return StandardVestClass;
        else
            return LightVestClass; //this should be always wearable
    }
    return CurrentVestClass;
}

simulated function class<ScrnVestPickup> GetCurrentVestClass()
{
    return CurrentVestClass;
}

simulated function bool CanUseVestClass(class<ScrnVestPickup> NewClass)
{
    if ( NewClass == none )
        return false;

    // always allow to use LightVestClass, no matter of crap modders can do in the future
    if ( CurrentVestClass == NewClass || NewClass == LightVestClass || NewClass == NoVestClass )
        return true;

    return ( CurrentWeight + NewClass.default.Weight - CurrentVestClass.default.Weight < MaxCarryWeight + 0.0001 );
}

function bool SetVestClass(class<ScrnVestPickup> NewClass)
{
    //log("SetVestClass("$NewClass$"), CurrentVestClass = " $ CurrentVestClass, 'ScrnBalance');
    if ( !CanUseVestClass(NewClass) )
        return false;

    // always update ShieldStrengthMax, even if NewClass is already set
    ShieldStrengthMax = NewClass.default.ShieldCapacity;
    if ( ShieldStrength > ShieldStrengthMax )
        ShieldStrength = ShieldStrengthMax;

    if ( NewClass != CurrentVestClass ) {
        CurrentWeight += NewClass.default.Weight - CurrentVestClass.default.Weight;
        CurrentVestClass = NewClass;
        ApplyWeaponStats(Weapon); // update armor speed modifier
        ClientSetVestClass(NewClass);
    }

    return true;
}

simulated function ClientSetVestClass(class<ScrnVestPickup> NewVestClass)
{
    if ( Role < ROLE_Authority ) {
        CurrentVestClass = NewVestClass;
        ShieldStrengthMax = CurrentVestClass.default.ShieldCapacity;
        ApplyWeaponStats(Weapon);
    }
}



simulated function SetShieldWeight()
{
    if ( int(ShieldStrength) <= 0 )
            SetVestClass(NoVestClass);
}


function float GetShieldStrengthMax()
{
    if ( CurrentVestClass == NoVestClass ) {
        if ( CanUseVestClass(StandardVestClass) )
            return StandardVestClass.default.ShieldCapacity;
        else
            return LightVestClass.default.ShieldCapacity;
    }
    return ShieldStrengthMax;
}

function int CanUseShield(int ShieldAmount)
{
    ShieldStrength = Max(ShieldStrength,0);
    if ( ShieldStrength < GetShieldStrengthMax() )
    {
        return (Min(GetShieldStrengthMax(), ShieldStrength + ShieldAmount) - ShieldStrength);
    }
    return 0;
}

function bool AddShieldStrength(int AmountToAdd)
{
    if ( AmountToAdd == 0 )
        return false;

    // this was added to make compatible with current KF shield system
    if ( AmountToAdd > LightVestClass.default.ShieldCapacity && ShieldStrengthMax < StandardVestClass.default.ShieldCapacity )
        SetVestClass(StandardVestClass);
    // if can't wear combat armor, try light armor
    if ( CurrentVestClass == NoVestClass )
        SetVestClass(LightVestClass);

    if ( AmountToAdd > 0 && ShieldStrength >= ShieldStrengthMax )
        return false;

    ShieldStrength = clamp(ShieldStrength + AmountToAdd, 0, ShieldStrengthMax);
    SetShieldWeight();
    if ( ShieldStrength >= 26 ) {
        bCowboyMode = false;
        if ( ScrnPlayerController(Controller) != none )
            ScrnPlayerController(Controller).bHadArmor = true;
    }

    return true;
}


function int ShieldAbsorb( int damage )
{
    local int AbsorbedValue, OldShieldStrength, OriginalDamage;
    local float dmg;

    if ( ShieldStrength == 0 || damage <= 0 )
        return damage;

    OldShieldStrength = ShieldStrength;
    OriginalDamage = damage;

    // I don't get Tripwire's armor protection formula (possibly just a chain of bugs that somehow work together),
    // so I wrote my own one, which is quite simple:
    // Shield > 50%  = 67% protection
    // Shield 26-50% = 50% protection
    // Shield <= 25% = 33% protection
    // (c) PooSH

    dmg = damage;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        if ( KFHumanPawn(LastDamagedBy) != none )
            dmg = fmax(1.0, dmg * fmax(0.6, KFPRI.ClientVeteranSkill.static.GetBodyArmorDamageModifier(KFPRI))); // cap 40% better armor against Human Damage
        else
            dmg = fmax(1.0, dmg * KFPRI.ClientVeteranSkill.static.GetBodyArmorDamageModifier(KFPRI)); // do at least 1 damage point after perk bonus
    }

    if ( dmg < 3 ) {
        // special case for tiny damages
        AbsorbedValue = rand(2);
        ShieldStrength -= AbsorbedValue;
        dmg -= AbsorbedValue;
    }
    else {
        if ( ShieldStrength > 50 ) {
            AbsorbedValue = min(0.67 * dmg, ShieldStrength - 50);
            ShieldStrength -= AbsorbedValue;
            dmg -= AbsorbedValue;
        }
        // don't put "else" here - after lowering the shield this can be executed too
        if ( ShieldStrength > 25 && ShieldStrength <= 50 ) {
            AbsorbedValue = min(0.50 * dmg, ShieldStrength - 25);
            ShieldStrength -= AbsorbedValue;
            dmg -= AbsorbedValue;
        }
        // don't put "else" here - after lowering the shield this can be executed too
        if ( ShieldStrength > 0 && ShieldStrength <= 25 ) {
            AbsorbedValue = clamp(0.33 * dmg, 1, ShieldStrength);
            ShieldStrength -= AbsorbedValue;
            dmg -= AbsorbedValue;
        }
    }
    damage = dmg;

    if ( bCheckHorzineArmorAch && OldShieldStrength > 100 && damage < Health && OriginalDamage > clamp(Health, 50, 80)
                && PlayerController(Controller) != none
                && SRStatsBase(PlayerController(Controller).SteamStatsAndAchievements) != none )
            bCheckHorzineArmorAch = class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
                SRStatsBase(PlayerController(Controller).SteamStatsAndAchievements).Rep, 'HorzineArmor', 1);

    // just to be sure
    if ( ShieldStrength < 0 )
        ShieldStrength = 0;
     if ( damage < 0 )
        damage = 0;

    SetShieldWeight(); //recalculate shield's weight
    //test cowboy mode on loosing armor
    // v7.28 - don't do it because this function isn't executed on client side
    // if ( !bCowboyMode && ShieldStrength < 26 && OldShieldStrength >= 26
            // && ScrnPerk != none )
        // bCowboyMode = ScrnPerk.static.CheckCowboyMode(KFPlayerReplicationInfo(PlayerReplicationInfo), Weapon.class);

    return damage;
}



simulated function CalcVestCost(class<ScrnVestPickup> VestClass, out int Cost, out int AmountToBuy, out float Price1p)
{
    if ( VestClass == none || VestClass == NoVestClass )
        VestClass = GetVestClass();

    AmountToBuy = VestClass.default.ShieldCapacity;
    Price1p = float(VestClass.default.Cost) / VestClass.default.ShieldCapacity;
    if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none)
        Price1p *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), VestClass);;
    Cost = ceil(AmountToBuy * Price1p);

    // No Refunds, if vest classes differs
    if ( VestClass == CurrentVestClass) {
        if ( ShieldStrength >= AmountToBuy ) {
            Cost = 0;
            AmountToBuy = 0;
        }
        else if ( ShieldStrength > 0 ) {
            // price of repairs
            Cost -= ShieldStrength * Price1p;
            AmountToBuy -= ShieldStrength;
        }
    }
}

function ServerBuyShield(class<ScrnVestPickup> VestClass)
{
    local float Price1p;
    local int Cost, AmountToBuy;

    if ( VestClass == none || VestClass == NoVestClass || !CanUseVestClass(VestClass) )
        return;

    CalcVestCost(VestClass, Cost, AmountToBuy, Price1p);

    // log("ServerBuyShield: Current Vest = " $ GetItemName(String(CurrentVestClass)) $ ", " $ int(ShieldStrength) $"%."
        // @ "Vest to Buy = " $ GetItemName(String(VestClass))
        // @ "Amount to Buy = " $ AmountToBuy $ " * " $ Price1p $ " = $" $ Cost, 'ScrnBalance');

    if ( CanBuyNow() && AmountToBuy > 0 ) {
        if ( PlayerReplicationInfo.Score >= Cost ) {
            if ( SetVestClass(VestClass) && AddShieldStrength(AmountToBuy) )
                PlayerReplicationInfo.Score -= Cost;
        }
        else if ( VestClass == CurrentVestClass && ShieldStrength > 0 ) {
            //repair shield for money players has, if not enough to buy a full shield
            AmountToBuy = PlayerReplicationInfo.Score / Price1p;
            if ( AmountToBuy > 0 && AddShieldStrength(AmountToBuy) ) {
                PlayerReplicationInfo.Score -= ceil(AmountToBuy * Price1p);
                if ( PlayerReplicationInfo.Score < 0 )
                    PlayerReplicationInfo.Score = 0;
                UsedStartCash(ceil(AmountToBuy * Price1p));
            }
        }
    }
    SetShieldWeight();
    SetTraderUpdate();
}

function ServerSellShield()
{
    //Marcus warns you : NO REFUNDS ;)
    SetVestClass(NoVestClass);
    SetTraderUpdate();
}


function ServerBuyKevlar()
{
    if ( CurrentVestClass == NoVestClass ) {
        SetVestClass(GetVestClass());
    }
    ServerBuyShield(CurrentVestClass);
}


function AddDefaultInventory()
{
    local int s;

    super.AddDefaultInventory();

    if ( class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo).GetSteamID32() == 15238764 ) {
        // give Bullpup to [REB]Mike1, because after 1000+ hours of using it he definitely deserves it :)
        CreateInventoryVeterancy(string(class'ScrnBullpup'), 0);
        Weapon(FindInventoryType(class'ScrnBullpup')).AddAmmo(500, 0);
    }

    // make sure players have at least knife, when admin screwed up the config
    if ( Inventory == none && KFSPGameType(Level.Game) == none ) {
        CreateInventory("ScrnBalanceSrv.ScrnKnife");
        if ( Inventory != none ) {
            Inventory.OwnerEvent('LoadOut');
            Controller.ClientSwitchToBestWeapon();
        }
    }

    // update vest class, if ShieldStrength is set directly, not via AddShieldStrength()
    if ( ShieldStrength > 0 ) {
        s = ShieldStrength;
        ShieldStrength = 0;
        AddShieldStrength(s);
    }
}
// ===================================== AMMO =====================================
/**
 * Calculates ammo price form given ammo class
 * @param P                 pawn, which wants to buy ammo
 * @param AClass            ammo class to buy. P must have this ammo in his inventory!
 * @param MyAmmo            [out] Ammunition object in the P inventory
 * @param ClipPrice         [out] cost per magazine/clip
 * @param FullRefillPrice   [out] how much to fully refill ammo?
 * @param ClipSize          [out] how much ammo in one magazine (including perk bonuses)
 * @return false, if calculation can't be made (e.g. no such ammo in P inventory)
 * @author PooSH, 2012
 */
static function bool CalcAmmoCost(Pawn P, Class<Ammunition> AClass,
        out Ammunition MyAmmo,
        out float ClipPrice, out float FullRefillPrice,
        out int ClipSize)
{
    local KFPlayerReplicationInfo KFPRI;
    local class<KFVeterancyTypes> Perk;
    local Inventory Inv;
    local int c;
    local KFWeapon KW;
    local class<KFWeaponPickup> KWPickupClass;
    local bool bSecondaryAmmo; // is this a secondary ammo?

    // reset output arguments to be sure caller won't use old values, if function returns false
    MyAmmo = none;
    ClipPrice = 0;
    FullRefillPrice = 0;
    ClipSize = 0;

    if ( P == none || AClass == none )
        return false;

    KFPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
    if ( KFPRI != none )
        Perk = KFPRI.ClientVeteranSkill;

    for ( Inv = P.Inventory; Inv != none && ++c < 1000 && (MyAmmo == none || KW == none); Inv = Inv.Inventory ) {
        if ( Inv.Class == AClass )
            MyAmmo = Ammunition(Inv);
        else if ( KW == None && KFWeapon(Inv) != None && (KFWeapon(Inv).AmmoClass[0] == AClass || KFWeapon(Inv).AmmoClass[1] == AClass) )
            KW = KFWeapon(Inv);
    }

    if ( KW == none || MyAmmo == none )
        return false;

    KWPickupClass = class<KFWeaponPickup>(KW.PickupClass);
    if ( KWPickupClass == none )
        return false;
    bSecondaryAmmo = KW.bHasSecondaryAmmo
                        && AClass != KW.FireModeClass[0].default.AmmoClass
                        && AClass == KW.FireModeClass[1].default.AmmoClass;

    MyAmmo.MaxAmmo = MyAmmo.default.MaxAmmo;
    if ( bSecondaryAmmo && Perk != none)
        MyAmmo.MaxAmmo = MyAmmo.default.MaxAmmo * Perk.static.AddExtraAmmoFor(KFPRI, AClass);
    else
        MyAmmo.MaxAmmo  = MyAmmo.default.MaxAmmo * KW.GetAmmoMulti(); // allow weapons to hande ammo bonuses
    if ( MyAmmo.AmmoAmount > MyAmmo.MaxAmmo )
        MyAmmo.AmmoAmount = MyAmmo.MaxAmmo;

    // Adding SecondaryAmmoCost variable to KFWeaponPickup would make things much easier,
    // but Tripwire doesn't look for easy ways ;)
    // If weapon has secondary ammo and this isn't secondary ammo, then this is primary ammo,
    // and primary ammo's cost is stored inside PrimaryWeaponPickup class
    if ( KW.bHasSecondaryAmmo && !bSecondaryAmmo && KWPickupClass.default.PrimaryWeaponPickup != none ) {
        ClipPrice = KWPickupClass.default.PrimaryWeaponPickup.default.AmmoCost;
        if( KWPickupClass.default.PrimaryWeaponPickup.default.BuyClipSize > 0 )
            ClipSize = KWPickupClass.default.PrimaryWeaponPickup.default.BuyClipSize;
        else
            ClipSize = KW.default.MagCapacity;
    }
    else {
        ClipPrice = KWPickupClass.default.AmmoCost;
        if( KWPickupClass.default.BuyClipSize > 0 )
            ClipSize = KWPickupClass.default.BuyClipSize;
        else if ( bSecondaryAmmo )
            ClipSize = 1; // Secondary Mags always MUST have a Mag Capacity of 1
        else
            ClipSize = KW.default.MagCapacity;
    }

    if ( Perk != none )
        ClipPrice *= Perk.static.GetAmmoCostScaling(KFPRI, KW.PickupClass);

    if ( !bSecondaryAmmo && Perk != none )
        ClipSize *= Perk.static.GetMagCapacityMod(KFPRI, KW);

    FullRefillPrice = ceil(float(MyAmmo.MaxAmmo-MyAmmo.AmmoAmount) * ClipPrice/ClipSize);

    return true;
}

function UsedStartCash(int UseAmount)
{
    if ( UseAmount != 0 && ScrnPlayerController(Controller) != none )
        ScrnPlayerController(Controller).StartCash = Max(ScrnPlayerController(Controller).StartCash - UseAmount, 0);
}

function bool ServerBuyAmmo( Class<Ammunition> AClass, bool bOnlyClip )
{
    local Ammunition MyAmmo;
    local float ClipPrice, FullRefillPrice;
    local int ClipSize;
    local int AmmoToAdd;
    local float Price;

    if ( !CanBuyNow() || !CalcAmmoCost(self, AClass, MyAmmo, ClipPrice, FullRefillPrice, ClipSize)
            || MyAmmo.AmmoAmount >= MyAmmo.MaxAmmo ) {
        //SetTraderUpdate();
        return false;
    }

    if ( bOnlyClip ) {
        AmmoToAdd = ClipSize;
        Price = ClipPrice;
        if ( AmmoToAdd + MyAmmo.AmmoAmount > MyAmmo.MaxAmmo ) {
            AmmoToAdd = MyAmmo.MaxAmmo - MyAmmo.AmmoAmount;
            Price = ceil(float(AmmoToAdd) * ClipPrice/ClipSize);
        }
    }
    else {
        AmmoToAdd = MyAmmo.MaxAmmo - MyAmmo.AmmoAmount;
        Price = FullRefillPrice;
    }

    if ( PlayerReplicationInfo.Score < Price ) {
        // Not enough CASH (so buy the amount you CAN afford).
        AmmoToAdd *= (PlayerReplicationInfo.Score/Price);
        Price = ceil(float(AmmoToAdd) * ClipPrice/ClipSize);

        if ( AmmoToAdd > 0 ) {
            PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score - Price, 0);
            UsedStartCash(Price);
            MyAmmo.AddAmmo(AmmoToAdd);
        }
    }
    else {
        PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score-Price);
        UsedStartCash(Price);
        MyAmmo.AddAmmo(AmmoToAdd);
    }
    SetTraderUpdate();
    return true;
}

// ===================================== WEAPONS =====================================
//fixed an exploit when player buy perked dualies with discount,
//then change the perk and sell 2-nd pistol as an off-perk weapon for a full price
// (c) PooSH, 2012
function ServerSellWeapon( Class<Weapon> WClass )
{
    local Inventory I;
    local int c;
    local KFWeapon W, SinglePistol;
    local float SellValue;
    local int AmmoCount;

    if ( !CanBuyNow() || Class<KFWeapon>(WClass) == none || Class<KFWeaponPickup>(WClass.Default.PickupClass)==none
        || Class<KFWeapon>(WClass).Default.bKFNeverThrow )
    {
        SetTraderUpdate();
        Return;
    }

    I = Inventory;
    while ( I != none && I.Class != WClass && ++c < 1000 )
        I = I.Inventory;

    if ( I == none || I.Class != WClass )
        return; //no instances of specified class found in inventory

    W = KFWeapon(I);
    //Changed from "!= -1" to ">= 0" to reject negative value possibility (c) PooSH
    if ( W != none && W.SellValue >= 0 ) {
        SellValue = W.SellValue;
    }
    else {
        SellValue = (class<KFWeaponPickup>(WClass.default.PickupClass).default.Cost * 0.75);

        if ( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
            SellValue *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), WClass.Default.PickupClass);
    }

    if ( W != none ) {
        if ( PipeBombExplosive(W) != none ) {
            //give 75% of all pipes, not 2 (even if there is only 1 left)
            // calc price per ammo and multiply by ammo count
            SellValue /= W.default.FireModeClass[0].default.AmmoClass.default.InitialAmount;
            SellValue *= W.AmmoAmount(0);

        }
        else if ( W.class==Class'Dualies' ) {
            SinglePistol = Spawn(class'Single', self);
            SellValue *= 2; //cuz we can't sell 9mm
        }
        else if ( W.class==Class'DualDeagle' )
            SinglePistol = Spawn(class'Deagle', self);
        else if ( W.class==Class'Dual44Magnum' )
            SinglePistol = Spawn(class'Magnum44Pistol', self);
        else if ( W.class==Class'DualMK23Pistol' )
            SinglePistol = Spawn(class'MK23Pistol', self);
        else if ( W.class==Class'DualFlareRevolver' )
            SinglePistol = Spawn(class'FlareRevolver', self);
        else if( Weapon(I).DemoReplacement!=None )
            SinglePistol = KFWeapon(Spawn(W.DemoReplacement, self));

        if( SinglePistol!=None )
        {
            AmmoCount = W.AmmoAmount(0);

            SellValue /= 2;
            //fixed an exploit when player buys perked dualies with discount,
            //then changes the perk and sells 2-nd pistol as an off-perk weapon for a full SellValue
            // (c) PooSH, 2012
            SinglePistol.SellValue = SellValue;

            SinglePistol.GiveTo(self);
            //restore ammo count to it previous value
            SinglePistol.ConsumeAmmo(0, SinglePistol.AmmoAmount(0) - min(AmmoCount, SinglePistol.MaxAmmo(0)));
        }
    }

    if ( I==Weapon || I==PendingWeapon )
    {
        ClientCurrentWeaponSold();
    }

    PlayerReplicationInfo.Score += int(SellValue);

    I.Destroy();

    SetTraderUpdate();

    if ( KFGameType(Level.Game)!=none )
        KFGameType(Level.Game).WeaponDestroyed(WClass);
}

// Searches for a weapon in the player's invenotry. If finds - sets outputs and returns true
final function bool HasWeaponClassToSell( class<KFWeapon> Weap, out float SellValue, out float Weight )
{
    local Inventory I;
    local int c;
    local KFWeapon W;

    for ( I=Inventory; I!=None && ++c < 1000; I=I.Inventory ) {
        W = KFWeapon(I);
        if (W != none && I.Class == Weap ) {
            SellValue = W.SellValue;
            Weight = W.Weight;
            return true;
        }
    }
    return false;
}

// fixed exploit then player buys perked dualies, drops them, changes perk and picks them
// with the full sell price
// (c) PooSH, 2012
function ServerBuyWeapon( Class<Weapon> WClass, float ItemWeight )
{
    local float Price,Weight, SellValue, SingleSellValue, SingleWeight;
    local Inventory I;
    local int c;
    local KFWeapon KFW;
    local Class<KFWeaponPickup> WP;
    local ScrnBalance Mut;

    if( !CanBuyNow() || Class<KFWeapon>(WClass)==None || HasWeaponClass(WClass) )
        Return;

    WP = Class<KFWeaponPickup>(WClass.Default.PickupClass);
    if ( WP == none )
        return;

    // Validate if allowed to buy that weapon.
    if( PerkLink==None )
        PerkLink = FindStats();
    if( PerkLink!=None && !PerkLink.CanBuyPickup(WP) )
        return;

    Mut = class'ScrnBalance'.default.Mut;

    Price = WP.Default.Cost;
    if ( ScrnPerk != none ) {
        Price *= ScrnPerk.static.GetCostScaling(KFPRI, WP);
        if  (Mut.bBuyPerkedWeaponsOnly
                && WP.default.CorrespondingPerkIndex != 7
                && WP.default.CorrespondingPerkIndex != ScrnPerk.default.PerkIndex
                && !ScrnPerk.static.OverridePerkIndex(WP) )
            return;
    }
    SellValue = Price * 0.75;
    Weight = Class<KFWeapon>(WClass).Default.Weight;

    if ( (WClass==class'Magnum44Pistol' || WClass==class'ScrnMagnum44Pistol'
                || WClass==class'Dual44Magnum' || WClass==class'ScrnDual44Magnum')
            && HasWeaponClass(class'ScrnDual44MagnumLaser') )
        return;
    else if ( (WClass==class'MK23Pistol' || WClass==class'ScrnMK23Pistol'
                || WClass==class'DualMK23Pistol' || WClass==class'ScrnDualMK23Pistol')
            && HasWeaponClass(class'ScrnDualMK23Laser') )
        return;
    else if( WClass==class'DualDeagle' || WClass==class'Dual44Magnum'
            || WClass==class'DualMK23Pistol' || WClass==class'DualFlareRevolver'
            || WClass.Default.DemoReplacement!=None )
    {
        if ( (WClass==class'DualDeagle' && HasWeaponClassToSell(class'Deagle', SingleSellValue, SingleWeight))
             || (WClass==class'GoldenDualDeagle' && HasWeaponClassToSell(class'GoldenDeagle', SingleSellValue, SingleWeight))
             || (WClass==class'Dual44Magnum' && HasWeaponClassToSell(class'Magnum44Pistol', SingleSellValue, SingleWeight))
             || (WClass==class'DualMK23Pistol' && HasWeaponClassToSell(class'MK23Pistol', SingleSellValue, SingleWeight))
             || (WClass==class'DualFlareRevolver' && HasWeaponClassToSell(class'FlareRevolver', SingleSellValue, SingleWeight))
             || (WClass.Default.DemoReplacement!=None && HasWeaponClassToSell(class<KFWeapon>(WClass.Default.DemoReplacement), SingleSellValue, SingleWeight)) )
        {
            Weight -= SingleWeight;
            Price*=0.5;
            //if one gun is perked, but other isn't - give lowest sell value to fix exploits
            SellValue =  fmin(SellValue, SingleSellValue*2);
        }
    }
    else if( WClass==class'Single' || WClass==class'Deagle' || WClass==class'GoldenDeagle' || WClass==class'Magnum44Pistol'
        || WClass==class'MK23Pistol' || WClass==class'FlareRevolver' )
    {
        if ( (WClass==class'Deagle' && HasWeaponClass(class'DualDeagle'))
                || (WClass==class'GoldenDeagle' && HasWeaponClass(class'GoldenDualDeagle'))
                || (WClass==class'Magnum44Pistol' && HasWeaponClass(class'Dual44Magnum'))
                || (WClass==class'Dualies' && HasWeaponClass(class'Single'))
                || (WClass==class'DualMK23Pistol' && HasWeaponClass(class'MK23Pistol'))
                || (WClass==class'DualFlareRevolver' && HasWeaponClass(class'FlareRevolver'))
            )
            return; // Has the dual weapon.
    }
    else // Check for custom dual weapon mode
    {
        for ( I=Inventory; I!=None && ++c < 1000; I=I.Inventory )
            if( Weapon(I)!=None && Weapon(I).DemoReplacement==WClass )
                return;
    }

    Price = int(Price); // Truncuate price.

    if ( (Weight>0 && !CanCarry(Weight)) || PlayerReplicationInfo.Score<Price )
        Return;

    I = Spawn(WClass, self);
    if ( I != none )
    {
        KFW = KFWeapon(I);

        if ( KFW != none ) {
            Mut.KF.WeaponSpawned(KFW);
            KFW.UpdateMagCapacity(PlayerReplicationInfo);
            KFW.FillToInitialAmmo();
            KFW.SellValue = SellValue;
            CheckBlame(KFW);
        }

        I.GiveTo(self);
        PlayerReplicationInfo.Score -= Price;
        UsedStartCash(Price);
        ClientForceChangeWeapon(I);
    }
    else ClientMessage("Error: Weapon failed to spawn.");

    SetTraderUpdate();
}

// blames the player for buying particular guns
function CheckBlame(KFWeapon GunToBlameFor)
{
    local string BlameStr;
    local ScrnBalance Mut;

    Mut = class'ScrnBalance'.default.Mut;

    if ( M99SniperRifle(GunToBlameFor) != none )
        BlameStr = BlameStrM99;
    else if ( Mut.ScrnGT != none && Mut.ScrnGT.bUseEndGameBoss && Mut.ScrnGT.WaveNum >= Mut.ScrnGT.FinalWave ) {
        // buying guns for boss wave
        if ( GunToBlameFor.IsA('RPG') )
            BlameStr = BlameStrRPG;
    }

    if ( BlameStr != "" )
        Mut.BlamePlayer(ScrnPlayerController(Controller), BlameStr);
}

// allows to adjust player's health
function bool GiveHealth(int HealAmount, int HealMax)
{
    if (ScrnPerk != none )
        HealthMax = (default.HealthMax + HealthBonus) * ScrnPerk.static.HealthMaxMult(KFPRI, self);

    if( BurnDown > 0 ) {
        if( BurnDown > 1 )
            BurnDown *= 0.5;
        LastBurnDamage *= 0.5;
    }

    // Don't let them heal more than the max health
    if( HealAmount + HealthToGive + Health  > HealthMax ) {
        healAmount = HealthMax - (Health + HealthToGive);

        if( healAmount == 0 )
            return false;
    }

    if( Health < HealMax ) {
        HealthToGive+=HealAmount;
        ClientHealthToGive = HealthToGive;
        lastHealTime = level.timeSeconds;
        return true;
    }
    return false;
}

// returns true, if player is using medic perk
simulated function bool IsMedic()
{
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        return KFPRI.ClientVeteranSkill.static.GetHealPotency(KFPRI) > 1.01;

    return false;
}

function TakeHealing(ScrnHumanPawn Healer, int HealAmount, float HealPotency, optional KFWeapon MedicGun)
{
    local ScrnPlayerInfo SPI;

    if ( HealthToGive <= 0 || HealthBeforeHealing == 0 || Health < HealthBeforeHealing )
        HealthBeforeHealing = Health;

    if ( GiveHealth(HealAmount, HealthMax) ) {
        HealthRestoreRate = fmax(default.HealthRestoreRate * HealPotency, 1);

        if ( LastHealedBy != Healer ) {
            LastHealedBy = Healer;
            HealthBeforeHealing = Health;
        }

        if ( Healer != none ) {
            Healer.LastHealed = self;
            if ( PlayerController(Healer.Controller) != none &&  GameRules != none) {
                SPI = GameRules.GetPlayerInfo(PlayerController(Healer.Controller));
                if ( SPI != none )
                    SPI.Healed(HealAmount, self, MedicGun);
            }
            if ( KFMonster(LastDamagedBy) != none && Healer.IsMedic() ) {
                CombatMedicTarget = KFMonster(LastDamagedBy);
            }
        }
    }
    ClientHealthToGive = HealthToGive;
}


//overrided to add HealthRestoreRate
simulated function AddHealth()
{
    local int TempHeal;
    local float TempHealReal;

    if( (level.TimeSeconds - lastHealTime) >= 0.1 ) {
        if( Health < HealthMax ) {
            TempHealReal = HealthRestoreRate * (level.TimeSeconds - lastHealTime) + HealthToGiveRemainder;
            TempHeal = int(TempHealReal);

            if( TempHeal > 0 ) {
                HealthToGiveRemainder = TempHealReal - TempHeal; // move remainder to the next healing tick
                HealthToGive -= TempHeal;

                // don't leave last hp for the next tick
                if ( HealthToGive < 1.0 ) {
                    if ( HealthToGive > 0 )
                        TempHeal++;
                    HealthToGive = 0;
                    HealthToGiveRemainder = 0;
                }
                Health += TempHeal;
                if ( Health >= HealthMax) {
                    Health = HealthMax;
                    HealthToGive = 0;
                    HealthToGiveRemainder = 0;
                }
                lastHealTime = level.TimeSeconds;
                ClientHealthToGive = HealthToGive;
            }
        }
        else {
            lastHealTime = level.timeSeconds;
            // if we are all healed, there's no more healing gonna be
            HealthToGive = 0;
            ClientHealthToGive = 0;
            HealthToGiveRemainder = 0;
        }
    }
}

function Timer()
{
    if ( BurnDown > 0 && BurnInstigator != self && KFPawn(BurnInstigator) != none )
        LastBurnDamage *= 1.8; // prevent lowering player-to-player burn damage in KFHumanPawn.Timer()

    super.Timer();
    // tick down health if it's greater than max
    if ( Health > HealthMax ) {
        if ( Health > 250 )
            Health = 250;
        else if (Health > 200)
            Health-=5;
        else
            Health-=2;
        if (Health < HealthMax)
            Health = HealthMax;
    }
    SetAmmoStatus();
    ApplyWeaponFlashlight(true);
}

function SetAmmoStatus()
{
    if ( KFWeapon(Weapon) == none ) {
        SpecWeapon = none;
        AmmoStatus = 0;
    }
    else {
        SpecWeapon = KFWeapon(Weapon).class;
        if (Weapon.MaxAmmo(0) <= 0)
            AmmoStatus = 0;
        else
            AmmoStatus = clamp(255 * Weapon.AmmoAmount(0) / Weapon.MaxAmmo(0), 1, 255);
    }
}

simulated function Tick(float DeltaTime)
{
    if ( PlayerReplicationInfo == none )
        KFPRI = none;
    else if ( KFPRI == none )
        KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);

    if( HealthToGive < 0 ) {
        HealthToGive = 0;
        ClientHealthToGive = 0;
    }

    if ( WeaponToFixClientState != none ) {
        // make sure that we don't hide current weapon (in case when QuickMelee didn't worked)
        if ( WeaponToFixClientState != Weapon && WeaponToFixClientState.ClientState == WS_ReadyToFire ) {
            WeaponToFixClientState.ClientState = WS_Hidden;
            WeaponToFixClientState.ClientGrenadeState = GN_None;
            WeaponToFixClientState.SetTimer(0, false);
        }
        WeaponToFixClientState = none;
    }

    AlphaAmount = 255; // hack to avoid KFHumanPawn of updating KFPRI.ThreeSecondScore
    super.Tick(DeltaTime);

    bCowboyMode = bCowboyMode && ShieldStrength < 26;

    if ( Role == ROLE_Authority ) {
        if ( MacheteBoost > 0 && Level.TimeSeconds > MacheteResetTime ) {
            MacheteBoost = 0;
            ModifyVelocity(0, Velocity);
        }
    }

    if ( KFPRI != none && ( PrevPerkClass != KFPRI.ClientVeteranSkill || PrevPerkLevel != KFPRI.ClientVeteranSkillLevel) )
        VeterancyChanged();

    if ( bViewTarget )
        UpdateSpecInfo();
}



// each weapon has own light battery
function ApplyWeaponFlashlight(bool bDrainBattery)
{
    local int i;
    local KFWeapon CurWeap;

    CurWeap = KFWeapon(Weapon);
    for ( i=0; i<WeaponFlashlights.Length; ++i ) {
        if ( CurWeap != none && WeaponFlashlights[i].WeaponClass == CurWeap.class ) {
            if ( bDrainBattery ) {
                if ( CurWeap.FlashLight != none && CurWeap.FlashLight.bHasLight )
                    WeaponFlashlights[i].TorchBatteryLife -= 10;
                else
                    WeaponFlashlights[i].TorchBatteryLife += 20;
            }
            WeaponFlashlights[i].TorchBatteryLife = clamp(WeaponFlashlights[i].TorchBatteryLife, 0, WeaponFlashlights[i].MaxBatteryLife);
            TorchBatteryLife = WeaponFlashlights[i].TorchBatteryLife;
        }
        else if (bDrainBattery && WeaponFlashlights[i].TorchBatteryLife < WeaponFlashlights[i].MaxBatteryLife)
            WeaponFlashlights[i].TorchBatteryLife += 20;
    }
}

// looks for a weapon class in WeaponFlashlights array.
// Creates a new record, if weapon class not found.
// Returns array index of a given weapon.
function int AddToFlashlightArray(class<KFWeapon> WeaponClass)
{
    local int i;

    for ( i=0; i<WeaponFlashlights.Length; ++i )
        if ( WeaponFlashlights[i].WeaponClass == WeaponClass )
            return i;

    WeaponFlashlights.insert(i, 1);
    WeaponFlashlights[i].WeaponClass = WeaponClass;
    WeaponFlashlights[i].TorchBatteryLife = default.TorchBatteryLife;
    WeaponFlashlights[i].MaxBatteryLife = default.TorchBatteryLife;
    return i;
}


simulated function Frag FindPlayerGrenade()
{
    local inventory inv;
    local int c;

    if ( PlayerGrenade == none ) {
        for ( inv = Inventory; inv != none && ++c < 1000 && PlayerGrenade == none ; inv = inv.Inventory)
            PlayerGrenade = Frag(inv);
    }

    return PlayerGrenade;
}

function CookGrenade()
{
    local ScrnFrag aFrag;

    if (SecondaryItem != none)
        return;

    if ( ScrnPerk == none || !ScrnPerk.static.CanCookNade(KFPRI, Weapon) )
        return;

    aFrag = ScrnFrag(FindPlayerGrenade());
    if ( aFrag == none )
        return;

    if ( aFrag.HasAmmo() && !bThrowingNade
            && !aFrag.bCooking && !aFrag.bThrowingCooked
            && Level.TimeSeconds - aFrag.CookExplodeTimer > 0.1 )
    {
        if ( KFWeapon(Weapon) == none || Weapon.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
                || (KFWeapon(Weapon).bIsReloading && !KFWeapon(Weapon).InterruptReload()) )
            return;

        aFrag.CookNade();

        KFWeapon(Weapon).ClientGrenadeState = GN_TempDown;
        Weapon.PutDown();
    }
}

function ThrowCookedGrenade()
{
    local ScrnFrag aFrag;

    aFrag = ScrnFrag(SecondaryItem);
    if ( aFrag != none && aFrag.bCooking && !aFrag.bThrowingCooked )
        aFrag.ClientThrowCooked();
}

function ThrowGrenade()
{
    local KFWeapon KFW;

    if ( bThrowingNade || SecondaryItem != none )
        return;

    KFW = KFWeapon(Weapon);
    if ( KFW == none || KFW.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
            || (KFW.bIsReloading && !KFW.InterruptReload()) )
        return;


    if ( PlayerGrenade == none )
        PlayerGrenade = FindPlayerGrenade();
    if ( PlayerGrenade != none && PlayerGrenade.HasAmmo() ) {
        KFW.ClientGrenadeState = GN_TempDown;
        KFW.PutDown();
    }
}

function QuickMelee()
{
    local KFWeapon KFW;

    KFW = KFWeapon(Weapon);
    if ( KFW == none ) {
        Controller.bAltFire = 0; // avoid accidental firing with the current weapon
        return;
    }

    if ( Weapon == QuickMeleeWeapon && QuickMeleeWeapon.IsInState('QuickMelee') ) {
        QuickMeleeWeapon.GotoState('');
        return;
    }

    if ( bThrowingNade
            || KFW.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
            || KFW.GetFireMode(1).NextFireTime - Level.TimeSeconds > 0.1
            // || KFW.ClientState != WS_ReadyToFire
            || (KFW.bIsReloading && !KFW.InterruptReload()) )
    {
        Controller.bAltFire = 0; // avoid accidental firing with the current weapon
        return;
    }

    if ( Weapon == QuickMeleeWeapon ) {
        AltFire(); // already equipped quick melee gun - simply do alt fire
    }
    else if ( SecondaryItem == none && QuickMeleeWeapon != none ) {
        bQuickMeleeInProgress = true;
        SecondaryItem = QuickMeleeWeapon;
        KFW.SetTimer(0, false);
        KFW.ClientGrenadeState = GN_TempDown;
        KFW.PutDown();
    }
}

function QuickMeleeFinished()
{
    bQuickMeleeInProgress = false;
    SecondaryItem = none;
}

function WeaponDown()
{
    local KFWeapon W;
    local byte Mode;

    W = KFWeapon(Weapon);
    if ( SecondaryItem == QuickMeleeWeapon && QuickMeleeWeapon != none ) {
        // quick melee
        //copied from weapon's putdown timer
        W.SetTimer(0, false);
        W.ClientState = WS_Hidden;
        W.ClientGrenadeState = GN_None;
        if( W.FlashLight!=none )
                W.Tacshine.Destroy();

        QuickMeleeWeapon.GotoState('QuickMelee');
        PendingWeapon = QuickMeleeWeapon;
        ChangedWeapon(); // sets Weapon=PendingWeapon and calls BringUp

         //copied from weapon's putdown timer
        for( Mode = 0; Mode < W.NUM_FIRE_MODES; Mode++ )
            W.GetFireMode(Mode).DestroyEffects();

        // after calling this function W.ClientSet will be set back to WS_ReadyToFire in KFWeapon.Timer()
        // That's why QuickMeleeWeapon must reset it to WS_Hidden again
        WeaponToFixClientState = W;
    }
    else if (SecondaryItem == none && PlayerGrenade != none ) {
        //Can't throw nade when secondary item is in use (e.g. for nade cooking)
        SecondaryItem = PlayerGrenade;
        PlayerGrenade.StartThrow();
    }
}

simulated function ThrowGrenadeFinished()
{
    local ScrnFrag aFrag;

    aFrag = ScrnFrag(SecondaryItem);
    if (aFrag != none) {
        aFrag.bCooking = false;
        aFrag.bThrowingCooked = false;
    }
    SecondaryItem = none;
    if ( Weapon != none ) {
        if ( KFWeapon(Weapon) != none )
            KFWeapon(Weapon).ClientGrenadeState = GN_BringUp;
        Weapon.BringUp();
    }
    bThrowingNade = false;
}

// disable automatic reloading
simulated function Fire( optional float F )
{
    local KFWeapon W;
    local ScrnPlayerController PC;

    if ( Weapon == none )
        return;

    PC = ScrnPlayerController(Controller);
    W = KFWeapon(Weapon);
    if ( PC != none && PC.bManualReload && W != none && !W.bMeleeWeapon && W.bConsumesPhysicalAmmo
            && !W.bIsReloading && !W.bHoldToReload
            && W.MagCapacity > 1 && W.MagAmmoRemaining < W.GetFireMode(0).AmmoPerFire ) {
        if ( W.AmmoAmount(0) == 0 )
            PC.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnPlayerWarningMessage',1);
        else
            PC.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnPlayerWarningMessage',0);
        W.PlayOwnedSound(W.GetFireMode(0).NoAmmoSound, SLOT_None,2.0,,,,false); //play weapon's no ammo sound
        W.GetFireMode(0).ModeDoFire(); //force weapon's mode do fire
        return;
    }

    Weapon.Fire(F);

    if ( W != none && W.FireModeClass[0] != class'KFMod.NoFire' )
        ServerFire(0);
}

simulated function AltFire( optional float F )
{
    local KFWeapon W;
    local ScrnPlayerController PC;

    if ( Weapon == none )
        return;


    PC = ScrnPlayerController(Controller);
    W = KFWeapon(Weapon);
    if ( PC != none && PC.bManualReload && W != none && !W.bMeleeWeapon && W.bConsumesPhysicalAmmo
            && W.bReduceMagAmmoOnSecondaryFire && KFMedicGun(W) == none
            && !W.bIsReloading && !W.bHoldToReload
            && W.MagCapacity > 2 && W.MagAmmoRemaining < W.GetFireMode(1).AmmoPerFire ) {
        if ( W.AmmoAmount(0) == 0 )
            PC.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnPlayerWarningMessage',1);
        else
            PC.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnPlayerWarningMessage',0);
        W.PlayOwnedSound(W.GetFireMode(0).NoAmmoSound, SLOT_None,2.0,,,,false);
        return;
    }

    Weapon.AltFire(F);

    if ( W != none  && W.FireModeClass[1] != class'KFMod.NoFire')
        ServerFire(1);
}

// simulated function StopFiring()
// {
    // super.StopFiring();
    // ServerStopFiring();
// }


// made p2p damage more like p2m, not like in RO  -- PooSH
function ProcessLocationalDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType, array<int> PointsHit )
{
    local int actualDamage, i;
    local int HighestDamagePoint, HighestDamageAmount;
    local bool bHeadShot;
    local class<KFWeaponDamageType> KFDamType;
    local float KFHeadshotMult;
    local KFPlayerReplicationInfo InstigatorPRI;

    if ( instigatedBy != none  )
        InstigatorPRI = KFPlayerReplicationInfo( instigatedBy.PlayerReplicationInfo );

    // If someone else has killed this player , return
    if( bDeleteMe || PointsHit.Length < 1 || Health <= 0 )
        return;

    // Don't process locational damage if we're not going to damage a friendly anyway
    if( TeamGame(Level.Game)!=None && TeamGame(Level.Game).FriendlyFireScale==0 && instigatedBy!=None && instigatedBy!=Self
            && instigatedBy.GetTeamNum()==GetTeamNum() )
        Return;

    KFHeadshotMult = 1.0;
    KFDamType = class<KFWeaponDamageType>(damageType);

    // do only highest damage
    for(i=0; i<PointsHit.Length; i++)  {
        actualDamage = Damage;

        // use KFWeaponDamageType.HeadShotDamageMult instead of Hitpoints.DamageMultiplier
        // -- PooSH
        if ( Hitpoints[PointsHit[i]].HitPointType == PHP_Head ) {
            bHeadShot = KFDamType != none && KFDamType.default.bCheckForHeadShots;

            if ( bHeadShot ) {
                if ( KFDamType.default.bIsPowerWeapon )
                    KFHeadshotMult = 1.0;
                else
                    KFHeadshotMult = 2.0;
                KFHeadshotMult = fmax(KFHeadshotMult, KFDamType.default.HeadShotDamageMult);
                if ( !KFDamType.default.bIsMeleeDamage && InstigatorPRI != none && InstigatorPRI.ClientVeteranSkill != none )
                    KFHeadshotMult *= fmin(2.0, InstigatorPRI.ClientVeteranSkill.Static.GetHeadShotDamMulti(InstigatorPRI, KFPawn(instigatedBy), DamageType));
            }

            actualDamage *= KFHeadshotMult;
        }
        else
            actualDamage *= Hitpoints[PointsHit[i]].DamageMultiplier;

        //actualDamage = Level.Game.ReduceDamage(actualDamage, self, instigatedBy, HitLocation, Momentum, DamageType);

        if( actualDamage > HighestDamageAmount )
        {
            HighestDamageAmount = actualDamage;
            HighestDamagePoint = PointsHit[i];
            if ( bHeadShot )
                break; // headshot does max damage - no need to look for more
        }
    }

    if( HighestDamageAmount > 0 ) {
        if( bHeadShot ) {
            // Play a sound when someone gets a headshot - KFTODO: Replace this with a better bullet hitting a helmet sound
            PlaySound(HeadshotSound, SLOT_None,2.0,true,500);
        }
        TakeDamage(HighestDamageAmount, instigatedBy, hitlocation, momentum, damageType, HighestDamagePoint);
    }
}

// this is used by explosive projectiles to scale damage
function float GetExposureTo(vector TestLocation)
{
    local float PercentExposed;

    if( FastTrace(GetBoneCoords(HeadBone).Origin,TestLocation))
        PercentExposed += 0.5;

    if( FastTrace(GetBoneCoords(RootBone).Origin,TestLocation))
        PercentExposed += 0.5;

    LastExplosionTime = Level.TimeSeconds;
    LastExplosionDistance = VSize( TestLocation - Location ) - CollisionRadius;

    return PercentExposed;
}

simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    local int OldHealth, OriginalDamage;
    local class<KFWeaponDamageType> KFDamType;
    local KFPlayerReplicationInfo InstigatorPRI;

    if ( Damage <= 0 )
        return; // just in case
    // copy-pasted from KFHumanPawn to check for nones
    if( Controller!=None && Controller.bGodMode )
        return;

    KFDamType = class<KFWeaponDamageType>(damageType);
    if ( InstigatedBy == none ) {
        // Player received non-zombie KF damage from unknown source.
        // Let's assume that it is friendly damage, e.g. from just disconnected/crashed/cheating teammate
        // and ignore it.
        if ( KFDamType != none && class<DamTypeZombieAttack>(KFDamType) == none )
            return;
    }
    else {
        if ( KFMonster(InstigatedBy) != none )
        {
            KFMonster(InstigatedBy).bDamagedAPlayer = true;
        }
        else if( KFHumanPawn(InstigatedBy) != none ) {
            InstigatorPRI = KFPlayerReplicationInfo(InstigatedBy.PlayerReplicationInfo);
             // Don't allow momentum from a player shooting a player
            Momentum = vect(0,0,0);
            // no damage from spectators (i.e. fire missile -> spectate -> missile hits player
            if ( InstigatorPRI != none && InstigatorPRI.bOnlySpectator )
                return;
        }
    }

    OriginalDamage = Damage;
    OldHealth = Health;
    // copied from KFPawn to adjust player-to-player damage -- PooSH
    LastHitDamType = damageType;
    LastDamagedBy = instigatedBy;
    LastDamageTime = Level.TimeSeconds;

    if ( KFDamType != none && KFHumanPawn(InstigatedBy) != none ) {
        // HDMG
        if ( InstigatorPRI != none && InstigatorPRI.ClientVeteranSkill != none )
            Damage = InstigatorPRI.ClientVeteranSkill.Static.AddDamage(InstigatorPRI, none, KFHumanPawn(instigatedBy), Damage, DamageType);
        if ( LastExplosionTime == Level.TimeSeconds && LastExplosionDistance > 50 )
            Damage *= (1.0 - lerp( LastExplosionDistance / 200, 0.0, 1.00, true ));

        if ( KFDamType.default.bDealBurningDamage ) {
            if ( class<DamTypeMAC10MPInc>(KFDamType) == none )
                Damage *= 1.50; // Increase burn damage 1.5 times, except MAC10.
        }
        else if ( KFDamType.default.bIsExplosive ) {
            if ( KFDamType != class'DamTypeFrag' )
                Damage *= 0.70;
        }
        else if ( KFDamType.default.bIsMeleeDamage ) {
            if ( ClassIsChildOf(KFDamType, class'DamTypeCrossbuzzsaw') )
                Damage *= 0.80;
        }
    }

    super(xPawn).TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);

    if( class<DamTypeVomit>(DamageType)!=none ) {
        BileCount=7;
        BileInstigator = instigatedBy;
        LastBileDamagedByType=class<DamTypeVomit>(DamageType);
        if(NextBileTime< Level.TimeSeconds )
            NextBileTime = Level.TimeSeconds+BileFrequency;

        if ( Level.Game != none && Level.Game.GameDifficulty >= 4.0 && KFPlayerController(Controller) != none &&
             !KFPlayerController(Controller).bVomittedOn)
        {
            KFPlayerController(Controller).bVomittedOn = true;
            KFPlayerController(Controller).VomittedOnTime = Level.TimeSeconds;

            if ( Controller.TimerRate == 0.0 )
                Controller.SetTimer(10.0, false);
        }
    }
    else if ( class<SirenScreamDamage>(DamageType) != none ) {
        if ( Level.Game != none && Level.Game.GameDifficulty >= 4.0 && KFPlayerController(Controller) != none &&
             !KFPlayerController(Controller).bScreamedAt)
        {
            KFPlayerController(Controller).bScreamedAt = true;
            KFPlayerController(Controller).ScreamTime = Level.TimeSeconds;

            if ( Controller.TimerRate == 0.0 )
                Controller.SetTimer(10.0, false);
        }
    }

    //Bloody Overlays
    if ( Health <= 50 )
        SetOverlayMaterial(InjuredOverlay,0, true);


    // SERVER-SIDE ONLY
    if ( Role < ROLE_Authority )
        return;

    // pawn didn't took any damage, probably due to resistance or disabled friendly fire
    // do not lower HealthToGive in such cases
    if ( Health >= OldHealth )
        return;

    HealthToGive -= 5;
    ClientHealthToGive = HealthToGive;

    if ( KFDamType != none ) {
        if ( KFDamType.default.bDealBurningDamage ) {
            // Do burn damage if the damage was significant enough
            if( Damage > 2 ) {
                // If we are already burning, and this damage is more than our current burn amount, add more burn time
                if( BurnDown == 0 || OriginalDamage > LastBurnDamage ) {
                    if ( InstigatedBy != self && KFPawn(InstigatedBy) != none )
                        BurnDown = 8;
                    else
                        BurnDown = 5;
                    BurnInstigator = InstigatedBy;
                    LastBurnDamage = OriginalDamage;
                    bBurnified  = true;
                }
            }
        }
    }

    // added null check for Instigator  -- PooSH
    if ( Level.Game.NumPlayers > 1 && Instigator != none && PlayerController(Instigator.Controller) != none
        && Health < 25 && Level.TimeSeconds - LastDyingMessageTime > DyingMessageDelay )
    {
        // Tell everyone we're dying
        PlayerController(Instigator.Controller).Speech('AUTO', 6, "");

        LastDyingMessageTime = Level.TimeSeconds;
    }

    // ScrN stuff
    if ( Health > 0 && HealthBeforeHealing > 0 && (level.TimeSeconds - LastHealTime) < 1.0 ) {
        if (  (HealthBeforeHealing - Damage) <= 0
                && LastHealedBy != none && LastHealedBy != self
                && ScrnPlayerController(LastHealedBy.Controller) != none
                && SRStatsBase(ScrnPlayerController(LastHealedBy.Controller).SteamStatsAndAchievements) != none )
        {
            class'ScrnAchievements'.static.ProgressAchievementByID(SRStatsBase(ScrnPlayerController(LastHealedBy.Controller).SteamStatsAndAchievements).Rep, 'TouchOfSavior', 1);
            HealthBeforeHealing = 0; //don't give this achievement anymore until next healing will be received
        }
        else if ( Health < HealthBeforeHealing )
            HealthBeforeHealing = Health;
    }
    // ScrN 9.15: allow weapon handle damage
    if ( Weapon != none )
        Weapon.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, damageType, HitIndex);
}


// store bonus ammo in pawn's class
function TossWeapon(Vector TossVel)
{
    // local int a;
    // local class<Ammunition> ac;
    // local class<KFWeaponPickup> wpc;
    local KFWeapon w;
    // local KFWeaponPickup wp;
    // local Actor other;

    w = KFWeapon(Weapon);
    if ( w != none ) {
        w.bIsTier2Weapon = false; // This hack is needed because KFWeaponPickup.DroppedBy isn't set for tier 2 weapons.
        w.bIsTier3Weapon = w.default.bIsTier3Weapon; // restore default value from the hack in AddInventory()
    }


    // if ( w != none && w.FireModeClass[0] != none && w.FireModeClass[0] != class'KFMod.NoFire' ) {
        // wpc = class<KFWeaponPickup>(w.PickupClass);
        // ac =  w.FireModeClass[0].default.AmmoClass;
        // if ( ac != none )
            // a = max(0, w.AmmoAmount(0) - ac.default.MaxAmmo); // bonus ammo
    // }

    super.TossWeapon(TossVel);

    // if ( Health > 0 && a > 0 ) {
        // foreach DynamicActors(wpc, other) {
            // wp = KFWeaponPickup(other);
            // if ( wp != none && wp.Inventory == w ) {
                // wp.AmmoAmount[0] = ac.default.MaxAmmo; // remove bonus ammo from pickup (it will be lost anyway)
                // BonusAmmoClass = ac;
                // BonusAmmoAmount = a;
                // return;
            // }
        // }
    // }
}

exec function SwitchToLastWeapon()
{
    if ( bQuickMeleeInProgress )
        return;
    super.SwitchToLastWeapon();
}


/**
    Monster threat assessment functionality
    Tripwire's new AssessThreatTo() is a bull crap. No, it is even worse:
    it is a bull crap eaten by Bloat and vomited back again.
    a)  No randomization at all. If players are camping the spot, then all zeds spawned at once
        place will attack the same player all the time.
    b)  EnemyThreatChanged() always returns false. That means zed always will [try to] attack the
        same player, no matter how far it is and is he doing damage to zed or not.
    c)  SetEnemy() always returns false in story game mode


    Changes by PooSH:
    1)  KFGameType.bUseZEDThreatAssessment set to true, i.e. in regular game new AssessThreatTo()
        function will be used too.
    2)  Distance between monster and player will always be in place.
    3)  AssessThreatTo will always return value > 0. Because zeds should not ignore players.
    4)  Added randomization - zeds can choose different targets in the same circumstances.
    5)  Blood smell. Wounded players will attract zeds slightly more than their healthy teammates.

    * @param    Monster         Monster's controller, for which we are calculating the threat level
    * @param    CheckDistance   Not used!
    * @return   threat level between 0 and 100, where 100 is the max threat level.
    *
    * @author   PooSH
*/
function  float AssessThreatTo(KFMonsterController  Monster, optional bool CheckDistance)
{
    local float DistancePart, RandomPart, TacticalPart;
    local float DistanceSquared; // squared distance is calculated faster
    local bool bAttacker, bSeeMe; // this player attacks zed
    local int i;

    if( bHidden || bDeleteMe || Health <= 0
            || Monster == none || KFMonster(Monster.Pawn) == none)
    {
        return -1.f;
    }

    if ( Level.TimeSeconds - SpawnTime < 10 )
        return 0.01; // very minor chance to attack players who just spawned

    // Gorefasts love Baron :D
    // https://www.youtube.com/watch?v=vytEYKpFAwk
    if ( bAmIBaron && ZombieGorefast(Monster.Pawn) != none && TSCGameReplicationInfo(Level.GRI) == none ) {
        if ( class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo).BlameCounter >= 5 )
            return 100.f;
    }

    if ( LastThreatMonster == Monster && Level.TimeSeconds - LastThreatTime < 2.0 )
        return LastThreat; // keep threat level for next 2 seconds


    DistanceSquared = VSizeSquared(Monster.Pawn.Location - Location);
    bSeeMe = DistanceSquared < 1562500 && Monster.LineOfSightTo(self); // check line of sight only withing 25 meters
    // v7.52: if monster is on different floor (5+ meters), then give additional 20 meters of distance
    if ( abs(Monster.Pawn.Location.Z - Location.Z) > 250 && !bSeeMe )
        DistanceSquared += 1000000;
    // v7.52: check KillAssistants instead of LastDamagedBy
    for ( i=0; i<Monster.KillAssistants.length; ++i ) {
        if ( Monster.KillAssistants[i].PC == Controller ) {
            bAttacker = Monster.KillAssistants[i].Damage > 100;
            break;
        }
    }

    DistancePart = 50.0;
    RandomPart = 100.0 - DistancePart;
    // let zeds smell blood within 15m radius - wounded players attract more zeds
    if ( Health < 80 && DistanceSquared < 562500.0 )
        TacticalPart += RandomPart * 0.30 * (1.0 - Health/100.0);
    // more chance to attack the same enemy multiple times
    if ( Monster.Enemy == self || Monster.Target == self ) {
        if ( bAttacker )
            TacticalPart += RandomPart * 0.80;
        else if ( bSeeMe )
            TacticalPart += RandomPart * 0.70;
        else
            TacticalPart += RandomPart * 0.60;
    }
    else if ( bAttacker )
        TacticalPart += RandomPart * 0.50; // more chance to focus on the player, who are attacking the monster
    else if ( bSeeMe )
        TacticalPart += RandomPart * 0.30; // zed can see player
    RandomPart -= TacticalPart;


    // If target is closer than 1 meter, max DistancePart value will be used,
    // otherwise DistancePart is lowering by 10% per meter
    // 1 meter = 50 ups (2500 squared)
    if ( DistanceSquared > 2500.0 )
        DistancePart /= 1.0 + DistanceSquared / 250000.0;
    RandomPart *= frand();

    // save threat level for this tick
    LastThreatMonster = Monster;
    LastThreatTime = Level.TimeSeconds;
    LastThreat = DistancePart + TacticalPart + RandomPart;
    // less chance to attach jsut-spawned players
    if ( Level.TimeSeconds - SpawnTime < 30 )
        LastThreat *= lerp( (Level.TimeSeconds - SpawnTime) / 30.0, 1.0, 0.01 );

    if ( KFStoryGameInfo(Level.Game) != none )
        LastThreat *= InventoryThreatModifier();
    return LastThreat;
}

// used in story game mode to attract zeds when holding some mission items
function float InventoryThreatModifier()
{
    local float ThreatRating;
    local Inventory CurInv;
    local int c;
    local KF_StoryInventoryItem StoryInv;

    ThreatRating = 1.0;

    /* Factor in story Items which adjust your desirability to ZEDs */
    for ( CurInv = Inventory; CurInv != none && ++c < 1000; CurInv = CurInv.Inventory )  {
        StoryInv = KF_StoryInventoryItem(CurInv);
        if(StoryInv != none)
            ThreatRating *= StoryInv.AIThreatModifier ;
    }

    return ThreatRating;
}

// C&P to check for SoundGroupClass - in cases when player joins with a custom skin, with isn't
// supported by the server
function Sound GetSound(xPawnSoundGroup.ESoundType soundType)
{
    local int SurfaceTypeID;
    local actor A;
    local vector HL,HN,Start,End;
    local material FloorMat;

    // added this in case when player joins using a custom skin with a custom SoundGroupClass,
    // which not present on the server
    if ( SoundGroupClass == none )
        SoundGroupClass = Class'KFMod.KFMaleSoundGroup';

    if( soundType == EST_Land || soundType == EST_Jump )
    {
        if ( (Base!=None) && (!Base.IsA('LevelInfo')) && (Base.SurfaceType!=0) )
        {
            SurfaceTypeID = Base.SurfaceType;
        }
        else
        {
            Start = Location - Vect(0,0,1)*CollisionHeight;
            End = Start - Vect(0,0,16);
            A = Trace(hl,hn,End,Start,false,,FloorMat);
            if (FloorMat !=None)
                SurfaceTypeID = FloorMat.SurfaceType;
        }
    }

    return SoundGroupClass.static.GetSound(soundType, SurfaceTypeID);
}


simulated event SetAnimAction(name NewAction)
{
    local KFWeapon W;


    super.SetAnimAction(NewAction);

    W = KFWeapon(Weapon);
    if ( W != none && InStr(Caps(String(AnimAction)), "RELOAD") != -1 ) {
        ServerReload();
    }
}

function ServerReload()
{
    if ( KFWeapon(Weapon) != none ) {
        GameRules.WeaponReloaded(PlayerController(Controller), KFWeapon(Weapon));
    }
}

function ServerFire(byte FireMode)
{
    if ( KFWeapon(Weapon) != none ) {
        GameRules.WeaponFire(PlayerController(Controller), KFWeapon(Weapon), FireMode);
    }
}


// function ServerStopFiring()
// {
        // GameRules.WeaponStoppedFire(PlayerController(Controller), Weapon);
// }

static function DropAllWeapons(Pawn P)
{
    local Inventory Inv, NextInv;
    local KFWeapon Weap;
    local int c;
    local rotator r;
    local Vector X,Y,Z, TossVel;

    if ( P != none && (P.DrivenVehicle == None || P.DrivenVehicle.bAllowWeaponToss) )
    {
        r = P.Rotation;
        r.pitch = 0;
        for ( Inv = P.Inventory; Inv != none && ++c < 1000; Inv = NextInv ) {
            NextInv = Inv.Inventory;
            Weap = KFWeapon(Inv);
            if (Weap != none && Weap.bCanThrow && !Weap.bKFNeverThrow /* && Weap.SellValue > 0 */ ) {
                //PlayerController(P.Controller).ClientMessage("Dropping " $ GetItemName(String(Weap.class)) $ "...");
                r.yaw += 4096 + 8192.0 * frand(); // 45 +/- 22.5 degrees
                P.GetAxes(r,X,Y,Z);
                TossVel = Vector(r);
                Weap.Velocity = TossVel * ((P.Velocity Dot TossVel) + 200) + Vect(0,0,200);
                Weap.DropFrom(P.Location + 0.8 * P.CollisionRadius * X - 0.5 * P.CollisionRadius * Y);
                NextInv = P.Inventory; // start from beginning again
            }
        }
        if ( P.Weapon == None && P.Controller != None )
            P.Controller.SwitchToBestWeapon();
    }
}


function FindGameRules()
{
    local GameRules G;

    if ( GameRules != none )
        return;

    for ( G=Level.Game.GameRulesModifiers; GameRules == none && G!=None; G=G.NextGameRules ) {
        GameRules = ScrnGameRules(G);
    }
}

// overrided to allow tossing amount below 50
exec function TossCash( int Amount )
{
    local Vector X,Y,Z;
    local ScrnCashPickup CashPickup;
    local Vector TossVel;
    local Actor A;
    local int StartCash;

    // To fix cash tossing exploit.
    if( Level.TimeSeconds < CashTossTimer || (Level.TimeSeconds < LongTossCashTimer && LongTossCashCount>=20) )
        return;

    PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score); // why it is defined as float in a first place?
    if ( PlayerReplicationInfo.Score <= 0 )
        return;

    if ( ScrnPlayerController(Controller) != none )
        StartCash = ScrnPlayerController(Controller).StartCash;
    if ( Amount <= 0 )
        Amount = 50;
    if ( Amount > PlayerReplicationInfo.Score )
        Amount = PlayerReplicationInfo.Score;

    // don't use bNoStartCashToss in story mode
    if ( class'ScrnBalance'.default.Mut.bNoStartCashToss && KF_StoryGRI(Level.GRI) == none ) {
        if ( PlayerReplicationInfo.Score <= ScrnPlayerController(Controller).StartCash ) {
            PlayerController(Controller).ClientMessage(strNoSpawnCashToss);
            CashTossTimer = Level.TimeSeconds+1.0;
            return;
        }
        Amount = Min(Amount, PlayerReplicationInfo.Score - ScrnPlayerController(Controller).StartCash);
    }

    // copied from KFPawn to override dosh class
    GetAxes(Rotation,X,Y,Z);
    TossVel = Vector(GetViewRotation());
    TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);
    CashPickup = Spawn(class'ScrnCashPickup',,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);
    if(CashPickup != none) {
        CashPickup.CashAmount = Amount;
        CashPickup.bDroppedCash = true;
        CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
        CashPickup.Velocity = TossVel;
        CashPickup.DroppedBy = Controller;
        CashPickup.InitDroppedPickupFor(None);
        PlayerReplicationInfo.Score -= Amount;

        if ( Level.Game.NumPlayers > 1 && Level.TimeSeconds - LastDropCashMessageTime > DropCashMessageDelay )
            PlayerController(Controller).Speech('AUTO', 4, "");
        // Hack to get Slot machines to accept dosh that's thrown inside their collision cylinder.
        ForEach CashPickup.TouchingActors(class 'Actor', A) {
            if( A.IsA('KF_Slot_Machine') )
                A.Touch(Cashpickup);
        }
    }
    // end of copy

    CashTossTimer = Level.TimeSeconds+0.1f;
    if( LongTossCashTimer<Level.TimeSeconds ){
        LongTossCashTimer = Level.TimeSeconds+5.f;
        LongTossCashCount = 0;
    }
    else
        ++LongTossCashCount;
}

simulated function DoHitCamEffects(vector HitDirection, float JarrScale, float BlurDuration, float JarDurationScale )
{
    if( KFPC!=none && Viewport(KFPC.Player)!=None )
        Super(KFHumanPawn_Story).DoHitCamEffects(HitDirection,JarrScale, BlurDuration, JarDurationScale);
}


// fixes critical bug:
// Assertion failed: inst->KPhysRootIndex != INDEX_NONE && inst->KPhysLastIndex != INDEX_NONE [File:.\KSkeletal.cpp] [Line: 595]
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
    if ( DamageType.default.bSkeletize )
        DamageType.default.bSkeletize = false;

    super.PlayDying(DamageType, HitLoc);
}


simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    if ( ScrnPlayerController(Controller) != none && !ScrnPlayerController(Controller).bDestroying ) {
        HealthBeforeDeath = Health;
    }
    super.Died(Killer, damageType, HitLocation);
}

function PlayerChangedTeam()
{
    if ( ScrngameType(Level.Game) != none && !ScrngameType(Level.Game).ShouldKillOnTeamChange(self) )
        return;

    Died( None, class'DamageType', Location );
}

simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow)
{
    local ScrnPlayerController PC;
    local string CN;

    PC = ScrnPlayerController(Controller);
    if ( PC != none && IsLocallyControlled() ) {
        // check this only on player side, because it stores
        // RedCharacter & BlueCharacter in the config
        CN = rec.DefaultName;
        if ( !PC.ValidateCharacter(CN) ) {
            // character invalid, change it valid one, which was set up in ValidateCharacter()
            rec = class'xUtil'.static.FindPlayerRecord(CN);
            PC.ChangeCharacter(CN);
        }
    }

    super.Setup(rec, bLoadNow);
}

// disable shopping at enemy trader
function bool CanBuyNow()
{
    local ShopVolume Shop, MyShop, EnemyShop;
    local TSCGameReplicationInfo TSCGRI;
    local bool bAtEnemyShop;

    if( KFGameType(Level.Game)==None || KFGameType(Level.Game).bWaveInProgress
            || PlayerReplicationInfo==None || PlayerReplicationInfo.Team==None )
        return False;

    TSCGRI = TSCGameReplicationInfo(Level.GRI);
    if ( TSCGRI == none ) {
        MyShop = KFGameReplicationInfo(Level.GRI).CurrentShop;
        EnemyShop = none;
    }
    else if ( PlayerReplicationInfo.Team.TeamIndex == 0 ) {
        MyShop = TSCGRI.CurrentShop;
        EnemyShop = TSCGRI.BlueShop;
    }
    else {
        MyShop = TSCGRI.BlueShop;
        EnemyShop = TSCGRI.CurrentShop;
    }

    foreach TouchingActors(Class'ShopVolume',Shop) {
        if ( Shop == MyShop || (Shop.bAlwaysEnabled && Shop != EnemyShop) ) {
            ScrnPlayerController(Controller).bShoppedThisWave = true;
            return True;
        }
        bAtEnemyShop = bAtEnemyShop || Shop == EnemyShop;
    }

    if ( bAtEnemyShop ) {
        PlayerController(Controller).ReceiveLocalizedMessage(class'TSCMessages', 300);
        // throw player outside of enemy shop
        if ( !EnemyShop.bTelsInit )
            EnemyShop.InitTeleports();
        if ( EnemyShop.TelList.Length > 0 )
            EnemyShop.TelList[EnemyShop.TelList.Length-1].Accept(self, EnemyShop);
    }

    Return False;
}

event Bump(actor Other)
{
    local ZombieCrawler crawler;

    super.Bump(Other);

    if ( class'ScrnBalance'.default.Mut.bBeta ) {
        // push crawlers away
        crawler = ZombieCrawler(Other);
        if ( crawler != none && crawler.health > 0 && !crawler.bPouncing //&& !crawler.bShotAnim
                && (LastDamagedBy != crawler || Level.TimeSeconds - LastDamageTime > 0.2) )
        {
            crawler.Velocity = GroundSpeed * 0.5 * normal(Velocity);
        }
    }
}

defaultproperties
{
     HealthRestoreRate=7.0
     NoVestClass=Class'ScrnBalanceSrv.ScrnNoVestPickup'
     StandardVestClass=Class'ScrnBalanceSrv.ScrnCombatVestPickup'
     LightVestClass=Class'ScrnBalanceSrv.ScrnLightVestPickup'
     CurrentVestClass=Class'ScrnBalanceSrv.ScrnNoVestPickup'
     ShieldStrengthMax=0.000000
     bCheckHorzineArmorAch=true
     strNoSpawnCashToss="Can not drop starting cash"
     HeadshotSound=sound'ProjectileSounds.impact_metal09'
     TraderSpeedBoost=1.5
     PrevPerkLevel=-1
     MaxFallSpeed=750
     BlameStrM99="%p blamed for using a Noobgun"
     BlameStrRPG="%p blamed for buying an RPG on Boss wave"
}
