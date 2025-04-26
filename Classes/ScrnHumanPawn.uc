class ScrnHumanPawn extends SRHumanPawn;

/**
 * When controlled by a player, the Controller's class MUST be ScrnPlayerController or a descendant.
 * Using other playercontrollers (e.g. KFPlayerController) causes undefined behavior.
 * Controllers exist only on the server, with exception of the local PlayerController - the one that player controls on
 * the client side. Hence, (ScrnPC != none) check tells that:
 * 1. This pawn is either locally controlled or the code is executing on the server.
 * 2. And the pawn is controlled by a player (not bot).
 * On the client side, PlayerController's pawn has bNetOwner && ROLE_AutonomousProxy. Autonomous proxy allows executing
 * non-simulated functions. Other player pawns have ROLE_SimulatedProxy and unable to execute non-simulated functions.
 * Function calls (e.g. ClientSetVestClass()) can be replicated only to/from net owner.
 * Having "simulated" functions inside controller classes does not make any sense since controllers are not replitated.
 * But the local player controllers has ROLE_AutonomousProxy and can execute non-simulated functions.
 *
 * Theoretically, bots can control ScrnHumanPawn instances too. Actually, properly implemented bots should use the same
 * pawns as players. The problem in KF1 code is that the single-responsibility principle is totally messed up, and there
 * where many controller functions implemented inside pawns or even weapons. For instance, KFWeapon, when controlled by
 * a bot, decides when it needs to reload itself, rather than the bot's controller. Maybe one day I will write proper
 * bot AI.
 */
var ScrnPlayerController ScrnPC;

var float HealthRestoreRate; // how fast player can be healed (hp/s)
var float HealthToGiveRemainder; // pawn receives integer amount of hp. remainder should be moved to next healing tick
var byte ClientHealthToGive; //required for client replication
var int ClientHealthBonus;
var() int HealthBonus;
var float DoshPerHeal;  // how much dosh medic receives for healing me

var const class<ScrnVestPickup> NoVestClass;            // dummy class that indicates player has no armor
var const class<ScrnVestPickup> StandardVestClass;      // standard KF armor (combat armor)
var const class<ScrnVestPickup> LightVestClass;     // Warning! LightVestClass must have no weight (weight=0)
var private class<ScrnVestPickup> CurrentVestClass;     // Equipped shield class

var private transient class<KFVeterancyTypes> PrevPerkClass;
var private int PrevPerkLevel;

var bool bCowboyMode;

var transient ScrnHumanPawn   LastHealedBy; // last player who healed me
var transient ScrnHumanPawn   LastHealed; // last player, who was healed by me
var transient int             LastHealAmount;
var transient KFMonster       CombatMedicTarget; // "LastHealedBy" must kill this monster to earn an ach
var transient int             HealthBeforeHealing;
var transient float           LastDamageTime;
var transient float           LastExplosionTime;
var transient float           LastExplosionDistance; // distance between player and explosions's epicenter
var float                     FallingDamageMod;

// Seems like bonus ammo is fixed in v1051 and not needed anymore
// var class<Ammunition> BonusAmmoClass;
// var int BonusAmmoAmount;

var ScrnGameRules GameRules;
var bool bCheckHorzineArmorAch;

// used in AssessThreatTo()
var protected transient KFMonsterController LastThreatMonster;
var protected transient float LastThreatTime, LastThreat;

// allows forrcing threat level until the given time
var transient float ForcedThreatLevel;
var transient float ForcedThreatLevelTime;

var class<ScrnCashPickup> TossedCashClass;
var localized string strNoSpawnCashToss;
var localized string strDoshTransferToPlayer;
var localized string strDoshTransferToTeam;
var localized string strDoshReceivedFromPlayer;

struct SWeaponFlashlight {
    var class<KFWeapon> WeaponClass;
    var int TorchBatteryLife, MaxBatteryLife;
};
var array<SWeaponFlashlight> WeaponFlashlights;

var Sound HeadshotSound;

var transient int HealthBeforeDeath; // in cases when death is not caused by health drop down to 0
var transient float NextEnemyBaseDamageMsg; //reserved for TSC

var KFPlayerReplicationInfo KFPRI;
var class<ScrnVeterancyTypes> ScrnPerk;

var transient bool bAmIBaron; // :trollface:

// spectator info
var bool bViewTarget; // somebody spectating me
var class<KFWeapon> SpecWeapon;
var byte AmmoStatus;
var byte SpecWeight, SpecMagAmmo, SpecMags, SpecSecAmmo, SpecNades;

var transient Frag PlayerGrenade;

var float TraderSpeedBoost;
var bool bAllowMacheteBoost;
var byte MacheteBoost; // that's one of the most retarded things I've done
var float MacheteResetTime;
var bool bMacheteDamageBoost;
var float CarriedInventorySpeed;        // allows items in the inventory to modify the movement speed
var bool bForceCarriedInventorySpeed;  // if true, force speed to CarriedInventorySpeed. Otherwise CarriedInventorySpeed is a multiplier.
var float MeleeWeightSpeedReduction;  // speed reduction per current weapon weight (kg*uups) for melee weapons
var float WeaponWeightSpeedReduction;  // speed reduction per current weapon weight (kg*uups) for non-melee weapons
var transient bool bWasMovementDisabled;
var transient bool bWantsZoom;
var bool bOnlyRequiredEquipment;  // Spawn only with 9mm, knife, syringe and welder

var transient KFMeleeGun QuickMeleeWeapon;
var transient KFWeapon WeaponToFixClientState;
var transient bool bQuickMeleeInProgress;
var transient float QuickMeleeFinishTime;
// available only client-side (owner-side)
var transient KFWeapon SprintWeapon;
var transient KFWeapon BeforeSprintWeapon;

// indicates that the player is buying something at the current moment. Server-side only.
var transient bool bServerShopping;
var transient byte ShopUpdateCounter;  // if changed, need to update shop inventory
var transient float NextBrownCrapTime;
var Sound FartSound;

var(Display) FadeColor GlowColor;
var(Display) Combiner GlowCmb;
var float GlowCheckTime;
var transient bool bGlowInited;

struct SZedInfo {
    var KFMonster Zed;
    var float ThreatRating;
    var float ThreatValidTime;
};
var array<SZedInfo> ZedInfo;
var class<ScrnPawnFunc> MyFunc;

replication
{
    reliable if( bNetOwner && bNetDirty && Role == ROLE_Authority )
        QuickMeleeWeapon, MacheteBoost, CarriedInventorySpeed, bForceCarriedInventorySpeed, ShopUpdateCounter;

    reliable if( Role == ROLE_Authority )
        ClientSetVestClass; //send it to all clients, cuz they need to know max health and max shield

    reliable if( bNetDirty && Role == ROLE_Authority )
        ClientHealthToGive, ClientHealthBonus; // all clients need to know it to properly display health on the hud

    reliable if( bNetDirty && Role == ROLE_Authority )
        SpecWeapon, AmmoStatus;
    reliable if( bNetDirty && bViewTarget && Role == ROLE_Authority )
        SpecWeight, SpecMagAmmo, SpecMags, SpecSecAmmo, SpecNades;

    // seem like that there is no need to replicate bCowboyMode, because it is used only on local player,
    // which can set it himself
    // reliable if( !bNetOwner && bNetDirty && Role == ROLE_Authority )
        // bCowboyMode; // net owner can check cowboy mode himself

    reliable if(Role < ROLE_Authority)
        ServerBuyShield, ServerSellShield, ServerDoshTransfer;

    reliable if(Role < ROLE_Authority)
        ServerReload, ServerFire, ServerRequestAutoReload;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( Role == ROLE_Authority ) {
        FindGameRules();
        ReplaceRequiredEquipment();
    }

    if ( SoundGroupClass == none )
        SoundGroupClass = Class'KFMod.KFMaleSoundGroup';

}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    CalcHealthMax();
}

simulated function Destroyed()
{
    if (GlowCmb != none) {
        Level.ObjectPool.FreeObject(GlowCmb);
        GlowCmb = none;
    }
    if (GlowColor != none) {
        Level.ObjectPool.FreeObject(GlowColor);
        GlowColor = none;
    }
    super.Destroyed();
}

// WARNING! Returns false if called on the client side for non-owned pawn
simulated function bool IsHumanControlled()
{
    return ScrnPC != none;
}

simulated function bool IsLocallyControlled()
{
    if ( ScrnPC != none )
        return Viewport(ScrnPC.Player) != none;
    else
        return Controller != none;  // in case of a bot (AIController)
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
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnKnife';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Single' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnSingle';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Frag' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnFrag';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Syringe' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnSyringe';
            else if ( StoryRules.RequiredPlayerEquipment[i] == Class'KFMod.Welder' )
                StoryRules.RequiredPlayerEquipment[i] = class'ScrnWelder';
        }
    }
    else if ( Mut.bNoRequiredEquipment ) {
        for ( i=0; i<16; ++i ) {
            RequiredEquipment[i] = "";
        }
    }
    else {
        for ( i=0; i<16; ++i ) {
            RequiredEquipment[i] = default.RequiredEquipment[i];
        }
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

simulated function ModifyVelocity(float DeltaTime, vector OldVelocity)
{
    if ( bMovementDisabled ) {
        if( Role == ROLE_Authority && Level.TimeSeconds > StopDisabledTime) {
            bMovementDisabled = false;
            ModifyVelocity(DeltaTime, OldVelocity);
            return;
        }

        bWasMovementDisabled = true;
        if ( Physics == PHYS_Walking ) {
            Velocity.X = 0;
            Velocity.Y = 0;
            Velocity.Z = 0;
        }
        else if ( Velocity.Z > 0 ) {
            Velocity.Z = 0;
        }
    }
    else if (bWasMovementDisabled) {
        bWasMovementDisabled = false;
        CalcGroundSpeed();
    }
}

function CalcGroundSpeed()
{
    local float WeightMod, MovementMod;
    local KFGameReplicationInfo KFGRI;
    local ScrnBalance Mut;

    if (Role < ROLE_Authority) {
        // let the server calculate GroundSpeed and replicate it to us
        return;
    }

    KFGRI = KFGameReplicationInfo(Level.GRI);
    Mut = class'ScrnBalance'.default.Mut;

    if ( bForceCarriedInventorySpeed ) {
        GroundSpeed = CarriedInventorySpeed;
        return;
    }

    WeightMod = WeightSpeedModifier;
    if (CurrentWeight <= default.MaxCarryWeight) {
        WeightMod *= CurrentWeight / default.MaxCarryWeight;
    }

    // Apply all the modifiers
    GroundSpeed = default.GroundSpeed;
    if (Health < 100) {
        GroundSpeed *= (HealthSpeedModifier * Health/100.0) + (1.0 - HealthSpeedModifier);
    }
    GroundSpeed *= (1.0 - WeightMod);
    GroundSpeed += InventorySpeedModifier;

    MovementMod = CarriedInventorySpeed;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        MovementMod *= KFPRI.ClientVeteranSkill.static.GetMovementSpeedModifier(KFPRI, KFGRI);
    GroundSpeed *= MovementMod;

    if ( Mut.bTraderSpeedBoost && Mut.KF.bTradingDoorsOpen )
        GroundSpeed *= TraderSpeedBoost;

    GroundSpeed += MacheteBoost;
}

function PossessedBy(Controller C)
{
    Super.PossessedBy(C);

    ScrnPC = ScrnPlayerController(Controller);
    KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
    ScrnPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
    if ( ScrnPC != none )
        bAmIBaron = ScrnPC.GetPlayerIDHash() == "76561198006289592";
}

function UnPossessed()
{
    super.UnPossessed();

    ScrnPC = none;
    KFPRI = none;
    ScrnPerk = none;
}

function CalcCarriedInventorySpeed()
{
    local Inventory Inv;
    local KF_StoryInventoryItem StoryInv;
    local int c;
    local float SpeedMod;

    SpeedMod = 1.0;
    for( Inv=Inventory; Inv!=None && ++c < 1000; Inv=Inv.Inventory ) {
        StoryInv = KF_StoryInventoryItem(Inv);
        if ( StoryInv != none && StoryInv.bUseForcedGroundSpeed ) {
            CarriedInventorySpeed = StoryInv.ForcedGroundSpeed;
            bForceCarriedInventorySpeed = true;
            return;
        }
        SpeedMod *= Inv.GetMovementModifierFor(self);
    }
    // if reached here, then no story inventory forces our speed
    CarriedInventorySpeed = SpeedMod;
    bForceCarriedInventorySpeed = false;

    if (ScrnGameType(Level.Game) != none) {
        ScrnGameType(Level.Game).InventoryUpdate(self);
    }
}

// Machete-sprinting. Available only in casual survival game modes (not TSC, Tourney, or Story)
function DoMacheteBoost()
{
    local ScrnBalance mut;

    mut = class'ScrnBalance'.default.Mut;
    if (mut == none || mut.SrvTourneyMode != 0 || mut.bTSCGame || mut.bStoryMode)
        return;

    if (bAllowMacheteBoost && MacheteBoost < 120 && VSizeSquared(Velocity) > 10000) {
        if ( MacheteBoost < 60 )
            MacheteBoost += 3;
        else if ( MacheteBoost < 100 )
            MacheteBoost += 2;
        else
            MacheteBoost++;
    }
    MacheteResetTime = Level.TimeSeconds + 3.0;
    bMacheteDamageBoost = true;
}

// executes only server-side
function bool AddInventory( inventory NewItem )
{
    local KFWeapon weap;

    weap = KFWeapon(NewItem);
    if( weap != none ) {
        // hack to set weap.Tier3WeaponGiver for all weapons
        weap.bPreviouslyDropped = false;
        weap.bIsTier3Weapon = true;
    }

    if (!super.AddInventory(NewItem)) {
        // log("!FAILED! ScrnHumanPawn.AddInventory " $ NewItem.name);
        return false;
    }
    // log("ScrnHumanPawn.AddInventory " $ NewItem.name);

    if ( weap != none ) {
        if ( weap.bTorchEnabled ) {
            AddToFlashlightArray(weap.class); // v6.22 - each weapon has own flashlight
        }

        if ( CheckQuickMeleeWeapon(KFMeleeGun(weap)) && ScrnMachete(weap) != none ) {
            DoMacheteBoost();
        }
    }
    CalcCarriedInventorySpeed();
    CalcGroundSpeed();
    ++ShopUpdateCounter;
    return true;
}

// executes on server-side and owner client
function DeleteInventory( inventory Item )
{
    // log("ScrnHumanPawn.DeleteInventory " $ Item.name);
    super.DeleteInventory(Item);
    if ( Item == QuickMeleeWeapon ) {
        QuickMeleeWeapon = none;
        SetBestQuickMeleeWeapon(Item);
        // for machete-walking
        if ( QuickMeleeWeapon != none )
            PendingWeapon = QuickMeleeWeapon;
    }
    CalcCarriedInventorySpeed();
    CalcGroundSpeed();
    ++ShopUpdateCounter;
}

simulated function SetWeaponAttachment(WeaponAttachment NewAtt)
{
    super.SetWeaponAttachment(NewAtt);

    // fixes bug in DualiesAttachment
    if ( HitAnims[0] == 'HitF_Dual9mmm') {
        HitAnims[0] = 'HitF_Dual9mm';
    }
    else if ( HitAnims[0] == 'HitF_M14' ) {
        HitAnims[0] = 'HitF_M14_EBR';
    }

    if ( HitAnims[1] == 'HitB_M14' ) {
        HitAnims[1] = 'HitB_M14_EBR';
    }

    if ( HitAnims[2] == 'HitL_M14' ) {
        HitAnims[2] = 'HitL_M14_EBR';
    }

    if ( HitAnims[3] == 'HitR_M14' ) {
        HitAnims[3] = 'HitR_M14_EBR';
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
    }
    return true;
}

function SetBestQuickMeleeWeapon(optional Inventory IgnoreItem)
{
    local inventory inv;
    local KFMeleeGun W;
    local int c;

    for ( inv = Inventory; inv != none && ++c < 1000; inv = inv.Inventory) {
        if (inv == IgnoreItem)
            continue;

        W = KFMeleeGun(inv);
        if ( W != none )
            CheckQuickMeleeWeapon(W);
    }
}

simulated function bool IsPerkedWeaponPickup(class<KFWeaponPickup> KFWP)
{
    return ScrnPerk != none && KFWP != none && (KFWP.default.CorrespondingPerkIndex == ScrnPerk.default.PerkIndex
            || ScrnPerk.static.OverridePerkIndex(KFWP));
}

simulated function bool IsPerkedWeapon(KFWeapon KFWeap)
{
    return KFWeap != none && IsPerkedWeaponPickup(class<KFWeaponPickup>(KFWeap.PickupClass));
}

// The player wants to switch to weapon group number F.
// Merged code from Pawn and KFHumanPawn + added ability to switch perked weapon first and empty guns last
simulated function SwitchWeapon(byte F)
{
    local Inventory Inv;
    local Weapon W;
    local KFWeapon KFWeap;
    local bool bPerkedFirst;
    local array<Weapon> SortedGroupInv; // perked -> non-perked -> empy
    local int NonPerkedIndex, EmptyIndex, i;

    if ( (Level.Pauser!=None) || (Inventory == None) )
        return;
    if ( PendingWeapon != None && PendingWeapon.bForceSwitch )
        return;
    if ( bQuickMeleeInProgress )
        return;

    bPerkedFirst = ScrnPerk != none && ScrnPC != none && ScrnPC.bPrioritizePerkedWeapons;

    // sort group inventory
    for ( Inv = Inventory; Inv != none && ++i < 1000; Inv = Inv.Inventory ) {
        W = Weapon(Inv);
        if ( W != none && W.InventoryGroup == F && AllowHoldWeapon(W) ) {
            KFWeap = KFWeapon(W);
            if ( !W.HasAmmo() && (KFWeap == none || (KFWeap.bConsumesPhysicalAmmo && !KFWeap.bMeleeWeapon)) ) {
                // weapon has no ammo
                SortedGroupInv[SortedGroupInv.length] = W;
            }
            else if ( bPerkedFirst && (PipeBombExplosive(W) != none || Knife(W) != none || !IsPerkedWeapon(KFWeap)) ) {
                // non-perked weapon, has ammo
                SortedGroupInv.insert(EmptyIndex, 1);
                SortedGroupInv[EmptyIndex] = W;
                EmptyIndex++;
            }
            else {
                // perked weapon, has ammo
                if ( Boomstick(W) != none && ScrnPC != none && ScrnPC.bPrioritizeBoomstick ) {
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

    if ( ScrnPC != none && IsLocallyControlled() )
        ScrnPC.LoadGunSkinFromConfig();
}

function ServerChangedWeapon(Weapon OldWeapon, Weapon NewWeapon)
{
    local int i;

    if ( NewWeapon != none && ScrnPC != none) {
        // set skinned attachment class
        for ( i=0; i<ScrnPC.WeaponSettings.length; ++i ) {
            if ( NewWeapon.class == ScrnPC.WeaponSettings[i].Weapon ) {
                if ( ScrnPC.WeaponSettings[i].SkinnedWeapon != none )
                    NewWeapon.AttachmentClass = ScrnPC.WeaponSettings[i].SkinnedWeapon.default.AttachmentClass;
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

    BaseMeleeIncrease = default.BaseMeleeIncrease;
    InventorySpeedModifier = 0;

    Weap = KFWeapon(NewWeapon);

    // check cowboy mode
    if ( ScrnPC != none ) {
        bCowboyMode = ScrnPerk != none && Weap != none && ScrnPerk.static.CheckCowboyMode(KFPRI, Weap.class);

        if ( Weap != none ) {
            if ( Weap.class == class'Dualies' || ClassIsChildOf(Weap.class, class'ScrnDualies') ) {
                // Machine Pistols for Cowboy!
                Weap.GetFireMode(0).bWaitForRelease = !bCowboyMode;
                Weap.GetFireMode(0).bNowWaiting = Weap.GetFireMode(0).bWaitForRelease;
            }
        }

        if ( Role == ROLE_Authority ) {
            ScrnPC.bHadArmor = ScrnPC.bHadArmor || ShieldStrength >= 26;
            ScrnPC.bCowboyForWave = ScrnPC.bCowboyForWave && bCowboyMode;
            UpdateSpecInfo();
        }
    }

    SetAmmoStatus();
    if ( KFPRI != none && Weap != none ) {
        Weap.UpdateMagCapacity(KFPRI);
        Weap.bIsTier3Weapon = Weap.default.bIsTier3Weapon; // restore default value from the hack in AddInventory()

        if ( Weap.bSpeedMeUp ) {
            if ( KFPRI.ClientVeteranSkill != none )
                BaseMeleeIncrease += KFPRI.ClientVeteranSkill.Static.GetMeleeMovementSpeedModifier(KFPRI);
            InventorySpeedModifier += default.GroundSpeed * BaseMeleeIncrease - Weap.Weight * MeleeWeightSpeedReduction;
        }
        else {
            InventorySpeedModifier -= Weap.Weight * WeaponWeightSpeedReduction;
        }

        if ( ScrnPerk != none ) {
            InventorySpeedModifier +=
                default.GroundSpeed * ScrnPerk.static.GetWeaponMovementSpeedBonus(KFPRI, NewWeapon);
        }
        // ScrN Armor can slow down players (or even boost) -- PooSH
        InventorySpeedModifier -= default.GroundSpeed * CurrentVestClass.default.SpeedModifier;

        if (QuickMeleeWeapon == none) {
            CheckQuickMeleeWeapon(KFMeleeGun(Weap));
        }
    }
    CalcGroundSpeed();
}

function CheckPerkAchievements()
{
    local ClientPerkRepLink StatRep;
    local int i;
    local int StarsPerMedal;

    if ( Role < ROLE_Authority )
        return; // ROLE_AutonomousProxy can execute non-simulated functions too

    if ( KFPRI == none || KFPRI.ClientVeteranSkill == none || ScrnPC == none )
        return;

    if ( KFPRI.ClientVeteranSkill != ScrnPC.InitialPerkClass ) {
        if ( KFGameType(Level.Game).WaveNum == 0 && ScrnPC.InitialPerkClass == none ) {
            ScrnPC.InitialPerkClass = KFPRI.ClientVeteranSkill;
            ScrnPC.bChangedPerkDuringGame = false;
        }
        else {
            ScrnPC.bChangedPerkDuringGame = true;
        }
    }

    if (SRStatsBase(ScrnPC.SteamStatsAndAchievements) == none)
        return;
    StatRep = SRStatsBase(ScrnPC.SteamStatsAndAchievements).Rep;
    if ( StatRep == none )
        return;

    if ( class'ScrnBalance'.default.Mut.b10Stars )
        StarsPerMedal = 10;
    else
        StarsPerMedal = 5;

    if ( KFPRI.ClientVeteranSkillLevel <= StarsPerMedal )
        return;

    if ( KFPRI.ClientVeteranSkillLevel > 5*StarsPerMedal )
        class'ScrnAchCtrl'.static.ProgressAchievementByID(StatRep, 'PerkOrange', 1);
    if ( KFPRI.ClientVeteranSkillLevel > 4*StarsPerMedal )
        class'ScrnAchCtrl'.static.ProgressAchievementByID(StatRep, 'PerkPurple', 1);
    if ( KFPRI.ClientVeteranSkillLevel > 3*StarsPerMedal )
        class'ScrnAchCtrl'.static.ProgressAchievementByID(StatRep, 'PerkBlue', 1);
    if ( KFPRI.ClientVeteranSkillLevel > 2*StarsPerMedal )
        class'ScrnAchCtrl'.static.ProgressAchievementByID(StatRep, 'PerkGreen', 1);

    // Mr. Golden Perky
    for ( i = 0; i < StatRep.CachePerks.length; ++i ) {
        if ( StatRep.CachePerks[i].CurrentLevel <= StarsPerMedal )
            break;
    }
    if ( i == StatRep.CachePerks.length )
        class'ScrnAchCtrl'.static.ProgressAchievementByID(StatRep, 'MrPerky', 1);
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
    CalcHealthMax();
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
    local ScrnPipeBombProjectile P;

    foreach DynamicActors(Class'ScrnPipeBombProjectile',P) {
        if( !P.bHidden && P.Instigator==self && P.bDetectEnemies ) {
            if ( CountToLeave > 0 )
                CountToLeave--;
            else
                P.bEnemyDetected = true; // blow me up
        }
    }
}

function bool CheckOutOfAmmo(optional bool bSpeech)
{
    local Inventory Inv;
    local int c;
    local KFWeapon KFWeap;

    for ( Inv = Instigator.Inventory; Inv != none && ++c < 1000; Inv = Inv.Inventory ) {
        KFWeap = KFWeapon(Inv);

        if ( Inv.InventoryGroup > 0 && KFWeap != none && !KFWeap.bMeleeWeapon && KFWeap.bConsumesPhysicalAmmo
                && KFWeap.HasAmmo() )
        {
            return false;
        }
    }

    if (bSpeech) {
        PlayerController(Controller).Speech('AUTO', 3, "");
    }
    return true;
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
    local int OldShieldStrength;

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

    OldShieldStrength = ShieldStrength;
    ShieldStrength = clamp(ShieldStrength + AmountToAdd, 0, ShieldStrengthMax);
    SetShieldWeight();
    if ( int(ShieldStrength) > 25 ) {
        // re-check Cowboy Mode
        if ( OldShieldStrength <= 25 ) {
            ApplyWeaponStats(Weapon);
            ClientSetVestClass(CurrentVestClass);
        }
    }

    return true;
}

function int ShieldAbsorb( int damage )
{
    local int AbsorbedValue, OldShieldStrength, OriginalDamage;

    if ( ShieldStrength == 0 || damage <= 0 )
        return damage;

    OldShieldStrength = ShieldStrength;
    OriginalDamage = damage;

    // I don't get Tripwire's armor protection formula (possibly just a chain of bugs that somehow work together),
    // so I wrote my own one, which is quite simple:
    // Shield >100%  = 67% protection
    // Shield 26-100% = 50% protection
    // Shield <= 25% = 33% protection
    // (c) PooSH

    if ( damage >= 62 ) {
        // makes sure that a player with 100hp and 25 armor always survives a raged FP hit.
        // FP damage on HoE is 61 +/-5% = 57..64. Raged hit does double damage: 114..128
        // By reducing damage of each of two hits by 2, we get 114..124 damage
        damage -= 2;
    }

    if ( ScrnPerk != none ) {
        damage = max(1, ScrnPerk.static.ShieldReduceDamage(KFPRI, self, LastDamagedBy, damage, LastHitDamType));
    }

    if ( damage <= 2 ) {
        // a special case for tiny damages
        AbsorbedValue = rand(2);
        ShieldStrength -= AbsorbedValue;
        damage -= AbsorbedValue;
    }
    else {
        if ( ShieldStrength > 100 ) {
            AbsorbedValue = min(0.67 * damage, ShieldStrength - 100);
            ShieldStrength -= AbsorbedValue;
            damage -= AbsorbedValue;
        }
        // don't put "else" here - after lowering the shield this can be executed too
        if ( ShieldStrength > 25 && ShieldStrength <= 100 ) {
            AbsorbedValue = min(0.50 * damage, ShieldStrength - 25);
            ShieldStrength -= AbsorbedValue;
            damage -= AbsorbedValue;
        }
        // don't put "else" here - after lowering the shield this can be executed too
        if ( ShieldStrength > 0 && ShieldStrength <= 25 ) {
            AbsorbedValue = clamp(0.33 * damage, 1, ShieldStrength);
            ShieldStrength -= AbsorbedValue;
            damage -= AbsorbedValue;
        }
    }

    if ( bCheckHorzineArmorAch && OldShieldStrength > 100 && damage < Health && OriginalDamage > clamp(Health, 50, 80) )
        bCheckHorzineArmorAch = class'ScrnAchCtrl'.static.Ach2Pawn(self, 'HorzineArmor', 1);

    // just to be sure
    if ( ShieldStrength < 0 )
        ShieldStrength = 0;
     if ( damage < 0 )
        damage = 0;

    SetShieldWeight(); //recalculate shield's weight

    // re-check Cowboy Mode
    if ( ShieldStrength < 26 && OldShieldStrength >= 26 ) {
        ApplyWeaponStats(Weapon);
        ClientSetVestClass(CurrentVestClass);
    }

    return damage;
}

simulated function CalcVestCost(class<ScrnVestPickup> VestClass, out int Cost, out int AmountToBuy, out float Price1p)
{
    if ( VestClass == none || VestClass == NoVestClass )
        VestClass = GetVestClass();

    AmountToBuy = VestClass.default.ShieldCapacity;
    Price1p = float(VestClass.default.Cost) / VestClass.default.ShieldCapacity;
    if ( KFPRI.ClientVeteranSkill != none)
        Price1p *= KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, VestClass);
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
    else if ( ShieldStrength >= AmountToBuy ) {
        // free downgrade
        Cost = 0;
        AmountToBuy = 0;
        Price1p = 0;  // indicates downgrade
    }
}

function ServerBuyShield(class<ScrnVestPickup> VestClass)
{
    local float Price1p;
    local int Cost, AmountToBuy, Dosh;

    if ( VestClass == none || VestClass == NoVestClass || !CanUseVestClass(VestClass) )
        return;

    CalcVestCost(VestClass, Cost, AmountToBuy, Price1p);

    // log("ServerBuyShield: Current Vest = " $ GetItemName(String(CurrentVestClass)) $ ", " $ int(ShieldStrength) $"%."
        // @ "Vest to Buy = " $ GetItemName(String(VestClass))
        // @ "Amount to Buy = " $ AmountToBuy $ " * " $ Price1p $ " = $" $ Cost, 'ScrnBalance');

    if (CanBuyNow() && (AmountToBuy > 0 || Price1p == 0)) {
        Dosh = GetAvailableDosh();
        bServerShopping = true;
        if (Dosh >= Cost) {
            if (SetVestClass(VestClass) && AddShieldStrength(AmountToBuy)) {
                TraderChargeDosh(Cost);
            }
        }
        else if (VestClass == CurrentVestClass && ShieldStrength > 0) {
            //repair shield for money players has, if not enough to buy a full shield
            AmountToBuy = Dosh / Price1p;
            if (AmountToBuy > 0 && AddShieldStrength(AmountToBuy)) {
                TraderChargeDosh(ceil(AmountToBuy * Price1p));
            }
        }
        bServerShopping = false;
    }
    SetShieldWeight();
    SetTraderUpdate();
}

function ServerSellShield()
{
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

    // make sure players have at least knife, when admin screwed up the config
    if ( Inventory == none && KFSPGameType(Level.Game) == none ) {
        CreateInventory(string(class'ScrnKnife'));
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

simulated function SetTraderUpdate()
{
    ScrnPC.DoTraderUpdate();
    bServerShopping = false;
    ++ShopUpdateCounter;
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
    local KFWeapon KW, KW2;
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
        if ( Inv.Class == AClass ) {
            MyAmmo = Ammunition(Inv);
        }
        else if ( KW == none ) {
            KW = KFWeapon(Inv);
            if ( KW != none ) {
                if ( KW.AmmoClass[1] == AClass )
                    KW2 = KW;  // found alternate ammo
                if ( KW.AmmoClass[0] != AClass )
                    KW = none; // not a primary ammo
            }
        }
        else if ( KW2 == none ) {
            KW2 = KFWeapon(Inv);
            if ( KW2 != none && KW2.AmmoClass[1] != AClass )
                KW2 = none;  // not a primary ammo
        }
    }

    if ( KW == none )
        KW = KW2;
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

function FixAmmo(Class<Ammunition> AClass)
{
    local Ammunition MyAmmo;
    local float ClipPrice, FullRefillPrice;
    local int ClipSize;

    CalcAmmoCost(self, AClass, MyAmmo, ClipPrice, FullRefillPrice, ClipSize);
}

/*deprecated*/ function UsedStartCash(int UseAmount);

function bool ServerBuyAmmo( Class<Ammunition> AClass, bool bOnlyClip )
{
    local Ammunition MyAmmo;
    local float ClipPrice, FullRefillPrice;
    local int ClipSize;
    local int AmmoToAdd;
    local int Price;
    local int Dosh;

    if ( !CanBuyNow() || !CalcAmmoCost(self, AClass, MyAmmo, ClipPrice, FullRefillPrice, ClipSize)
            || MyAmmo.AmmoAmount >= MyAmmo.MaxAmmo ) {
        //SetTraderUpdate();
        return false;
    }

    Dosh = GetAvailableDosh();

    if (bOnlyClip) {
        AmmoToAdd = ClipSize;
        Price = ClipPrice;
        if (AmmoToAdd + MyAmmo.AmmoAmount > MyAmmo.MaxAmmo) {
            AmmoToAdd = MyAmmo.MaxAmmo - MyAmmo.AmmoAmount;
            Price = ceil(float(AmmoToAdd) * ClipPrice/ClipSize);
        }
    }
    else {
        AmmoToAdd = MyAmmo.MaxAmmo - MyAmmo.AmmoAmount;
        Price = FullRefillPrice;
    }

    bServerShopping = true;
    if (Dosh < Price) {
        // Not enough CASH (so buy the amount you CAN afford).
        AmmoToAdd = AmmoToAdd * Dosh / Price;
        Price = ceil(float(AmmoToAdd) * ClipPrice / ClipSize);

        if (AmmoToAdd > 0) {
            TraderChargeDosh(Price);
            MyAmmo.AddAmmo(AmmoToAdd);
        }
    }
    else {
        TraderChargeDosh(Price);
        MyAmmo.AddAmmo(AmmoToAdd);
    }
    bServerShopping = false;
    SetTraderUpdate();
    return true;
}

// ===================================== WEAPONS =====================================

static function ForceAmmoAmount(KFWeapon W, int AmmoAmount, optional int mode)
{
    local float MaxAmmo, CurAmmo;
    local Ammunition Ammo;

    if ( W == none || !W.bNoAmmoInstances )
        return;

    W.UpdateMagCapacity(W.Instigator.PlayerReplicationInfo);
    if (mode == 0) {
        W.GetAmmoCount(MaxAmmo, CurAmmo);
    }
    else {
        W.GetSecondaryAmmoCount(MaxAmmo, CurAmmo);
    }

    AmmoAmount = min(AmmoAmount, MaxAmmo);
    if (CurAmmo == AmmoAmount)
        return;

    Ammo = Ammunition(W.Instigator.FindInventoryType(W.GetAmmoClass(mode)));
    if ( Ammo != none ) {
        Ammo.AmmoAmount = AmmoAmount;
        Ammo.NetUpdateTime = Ammo.Level.TimeSeconds - 1;
    }
}

simulated function int CalcSellValue(KFWeapon W)
{
    local int SellValue;

    if (W == none || W.bKFNeverThrow)
        return 0;

    if (W.SellValue >= 0) {
        SellValue = W.SellValue;
    }
    else {
        SellValue = ceil(class<KFWeaponPickup>(W.PickupClass).default.Cost * 0.75);
        if (SellValue != 0 && KFPRI != none && KFPRI.ClientVeteranSkill != none)
            SellValue = ceil(SellValue * KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, W.PickupClass));
    }

    if (W.IsA('PipeBombExplosive')) {
        //give 75% of all pipes, not 2 (even if there is only 1 left)
        SellValue /= W.default.FireModeClass[0].default.AmmoClass.default.InitialAmount;
        SellValue *= W.AmmoAmount(0);
    }

    return SellValue;
}

// return total sell value of all items in the inventory
simulated function int CalcTotalSellValue()
{
    local int result;
    local Inventory I;
    local int c;

    I = Inventory;
    for (I = Inventory; I != none && ++c < 1000; I = I.Inventory) {
        result += CalcSellValue(KFWeapon(I));
    }
    return result;
}

//fixed an exploit when player buy perked dualies with discount,
//then change the perk and sell 2-nd pistol as an off-perk weapon for a full price
// (c) PooSH, 2012
function ServerSellWeapon( Class<Weapon> WClass )
{
    local Inventory I;
    local int c;
    local KFWeapon W, SinglePistol;
    local int SellValue;
    local int AmmoAmount;
    local bool bCurrent;

    if (!CanBuyNow() || Class<KFWeapon>(WClass) == none || Class<KFWeaponPickup>(WClass.Default.PickupClass)==none
            || Class<KFWeapon>(WClass).Default.bKFNeverThrow)
    {
        SetTraderUpdate();
        return;
    }

    I = Inventory;
    while (I != none && I.Class != WClass && ++c < 1000) {
        I = I.Inventory;
    }

    if (I == none || I.Class != WClass)
        return; //no instances of specified class found in inventory

    W = KFWeapon(I);
    SellValue = CalcSellValue(W);

    if (Dualies(W) != none) {
        AmmoAmount = W.AmmoAmount(0);

        if (W.class == class'Dualies') {
            SinglePistol = Spawn(class'Single', self);
        }
        else if (W.class == class'ScrnDualies') {
            SinglePistol = Spawn(class'ScrnSingle', self);
        }
        else if (W.DemoReplacement != none) {
            // ScrN dualies
            if (ScrnDualDeagle(W) != none) {
                SinglePistol = ScrnDualDeagle(W).DetachSingle();
            }
            else if (ScrnDualMK23Pistol(W) != none) {
                SinglePistol = ScrnDualMK23Pistol(W).DetachSingle();
            }
            else if (ScrnDual44Magnum(W) != none) {
                SinglePistol = ScrnDual44Magnum(W).DetachSingle();
            }
            else if (ScrnDualFlareRevolver(W) != none) {
                SinglePistol = ScrnDualFlareRevolver(W).DetachSingle();
            }

            if (SinglePistol != none) {
                // the player has both single and dualies in the inventory - delete both
                if (SinglePistol == Weapon || SinglePistol == PendingWeapon) {
                    bCurrent = true;
                }
                SinglePistol.Destroy();
                SinglePistol = none;
            }
        }

        if (SinglePistol != none ) {
            SinglePistol.SellValue = 0;
            SinglePistol.GiveTo(self);
            //restore ammo count to its previous value
            ForceAmmoAmount(SinglePistol, AmmoAmount);
        }
    }

    bCurrent = bCurrent || I == Weapon || I == PendingWeapon;
    if (bCurrent) {
        ClientCurrentWeaponSold();
    }
    PlayerReplicationInfo.Score += SellValue;
    PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1.0;
    I.Destroy();
    SetTraderUpdate();

    if (KFGameType(Level.Game) !=none) {
        KFGameType(Level.Game).WeaponDestroyed(WClass);
    }
}

// Searches for a weapon in the player's inventory. If finds - sets outputs and returns true
final function bool HasWeaponClassToSellInt( class<KFWeapon> Weap, out int SellValue, out int Weight )
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

// deprecated
final function bool HasWeaponClassToSell( class<KFWeapon> Weap, out float SellValue, out float Weight )
{
    local int iSellValue, iWeight;

    if (HasWeaponClassToSellInt(Weap, iSellValue, iWeight)) {
        SellValue = iSellValue;
        Weight = iWeight;
        return true;
    }
    return false;
}

// fixed exploit then player buys perked dualies, drops them, changes perk and picks them
// with the full sell price
// (c) PooSH, 2012
function ServerBuyWeapon( Class<Weapon> WClass, float ItemWeight )
{
    local int Price, Weight, SellValue, SingleSellValue, SingleWeight;
    local Inventory I;
    local int c;
    local KFWeapon KFW;
    local class<KFWeaponPickup> WP;
    local ScrnBalance Mut;

    if( !CanBuyNow() || Class<KFWeapon>(WClass)==None || HasWeaponClass(WClass) )
        Return;

    WP = Class<KFWeaponPickup>(WClass.Default.PickupClass);
    if ( WP == none )
        return;

    Mut = class'ScrnBalance'.default.Mut;

    Price = WP.Default.Cost;
    if ( ScrnPerk != none ) {
        Price = ceil(Price * ScrnPerk.static.GetCostScaling(KFPRI, WP));
        if  (Mut.bBuyPerkedWeaponsOnly
                && WP.default.CorrespondingPerkIndex != 7
                && WP.default.CorrespondingPerkIndex != ScrnPerk.default.PerkIndex
                && !ScrnPerk.static.OverridePerkIndex(WP) )
            return;
    }
    SellValue = Price * 3 / 4;
    Weight = Class<KFWeapon>(WClass).Default.Weight;

    if (WClass.Outer.Name == 'KFMod') {
        // legacy crap
        if ((WClass==class'Deagle' && HasWeaponClass(class'DualDeagle'))
                ||  (WClass==class'GoldenDeagle' && HasWeaponClass(class'GoldenDualDeagle'))
                ||  (WClass==class'Magnum44Pistol' && HasWeaponClass(class'Dual44Magnum'))
                ||  (WClass==class'Dualies' && HasWeaponClass(class'Single'))
                ||  (WClass==class'DualMK23Pistol' && HasWeaponClass(class'MK23Pistol'))
                ||  (WClass==class'DualFlareRevolver' && HasWeaponClass(class'FlareRevolver')))
            return; // Has the dual weapon.

        if ((WClass==class'DualDeagle' && HasWeaponClassToSellInt(class'Deagle', SingleSellValue, SingleWeight))
                || (WClass==class'GoldenDualDeagle' && HasWeaponClassToSellInt(class'GoldenDeagle', SingleSellValue, SingleWeight))
                || (WClass==class'Dual44Magnum' && HasWeaponClassToSellInt(class'Magnum44Pistol', SingleSellValue, SingleWeight))
                || (WClass==class'DualMK23Pistol' && HasWeaponClassToSellInt(class'MK23Pistol', SingleSellValue, SingleWeight))
                || (WClass==class'DualFlareRevolver' && HasWeaponClassToSellInt(class'FlareRevolver', SingleSellValue, SingleWeight)))
        {
            Weight -= SingleWeight;
            Price /= 2;
            SellValue = Price * 3 / 4 + SingleSellValue;
        }
    }
    else if (WClass.Default.DemoReplacement != none) {
        if (HasWeaponClassToSellInt(class<KFWeapon>(WClass.Default.DemoReplacement), SingleSellValue, SingleWeight)) {
            // Twice cheaper dual guns when having the single one
            Weight -= SingleWeight;
            Price /= 2;
            SellValue = Price * 3 / 4 + SingleSellValue;
        }
    }
    else {
        for (I=Inventory; I!=None && ++c < 1000; I=I.Inventory) {
            if (Weapon(I) != none && Weapon(I).DemoReplacement == WClass)
                return;  // cannot buy single when having duals
        }
    }

    if ((Weight > 0 && !CanCarry(Weight)) || GetAvailableDosh() < Price)
        return;

    if (!Mut.GameRules.CanBuyWeapon(self, WP))
        return;

    bServerShopping = true;
    I = Spawn(WClass, self);
    if (I != none) {
        KFW = KFWeapon(I);

        if ( KFW != none ) {
            Mut.KF.WeaponSpawned(KFW);
            KFW.UpdateMagCapacity(PlayerReplicationInfo);
            KFW.FillToInitialAmmo();
            KFW.SellValue = SellValue;
        }

        I.GiveTo(self);
        if (KFW != none && KFW.AmmoClass[0] != none) {
            // fixes a bug in KFWeapon.GiveAmmo() which applies AddExtraAmmoFor() twice if both fire modes share
            // the same ammo
            FixAmmo(KFW.AmmoClass[0]);
        }
        TraderChargeDosh(Price);
        ClientForceChangeWeapon(I);
    }
    else {
        ClientMessage("Error: Weapon" $ WClass $ "failed to spawn.");
    }
    bServerShopping = false;
    SetTraderUpdate();
}

function SetHealthBonus(int bonus) {
    HealthBonus = bonus;
    CalcHealthMax();
    Health = min(HealthMax, Health + HealthBonus);
    ClientHealthBonus = HealthBonus;
    NetUpdateTime = Level.TimeSeconds - 1;
}

simulated function CalcHealthMax()
{
    HealthMax = default.HealthMax + HealthBonus;
    if (ScrnPerk != none ) {
        HealthMax *= ScrnPerk.static.HealthMaxMult(KFPRI, self);
    }
}

// allows to adjust player's health
function bool GiveHealth(int HealAmount, int _unused_HealMax)
{
    CalcHealthMax();

    if( BurnDown > 0 ) {
        if( BurnDown > 1 )
            BurnDown /= 2;
        LastBurnDamage /= 2;
    }

    HealAmount = min(HealAmount, HealthMax - Health - HealthToGive);
    if (HealAmount <= 0)
        return false;

    HealthToGive += HealAmount;
    ClientHealthToGive = HealthToGive;
    lastHealTime = level.timeSeconds;
    LastHealAmount = HealAmount;
    return true;
}

// returns true, if player is using medic perk
simulated function bool IsMedic()
{
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        return KFPRI.ClientVeteranSkill.static.GetHealPotency(KFPRI) > 1.01;

    return false;
}

function bool TakeHealing(ScrnHumanPawn Healer, int HealAmount, float HealPotency, optional KFWeapon MedicGun)
{
    local ScrnPlayerInfo SPI;
    local int MedicReward;
    local KFSteamStatsAndAchievements HealerStats;

    if ( HealthToGive <= 0 || HealthBeforeHealing == 0 || Health < HealthBeforeHealing )
        HealthBeforeHealing = Health;

    if (!GiveHealth(HealAmount, HealthMax))
        return false;

    HealthRestoreRate = fmax(default.HealthRestoreRate * HealPotency, 1);

    if ( LastHealedBy != Healer ) {
        LastHealedBy = Healer;
        HealthBeforeHealing = Health;
    }

    if (Healer == none || Healer == self)
        return true;

    HealerStats = KFSteamStatsAndAchievements(Healer.PlayerReplicationInfo.SteamStatsAndAchievements);
    if (HealerStats != none) {
        HealerStats.AddDamageHealed(LastHealAmount, false, false);
    }
    MedicReward = LastHealAmount * DoshPerHeal;
    // Give the Healer dosh from our Team Wallet
    if (KFPRI != none && KFPRI.Team != none) {
        MedicReward = min(MedicReward, KFPRI.Team.Score);
        if (MedicReward > 0) {
            KFPRI.Team.Score -= MedicReward;
            Healer.PlayerReplicationInfo.Score += MedicReward;
            Healer.AlphaAmount = 255;

        }
    }

    Healer.LastHealed = self;
    if ( PlayerController(Healer.Controller) != none &&  GameRules != none) {
        SPI = GameRules.GetPlayerInfo(PlayerController(Healer.Controller));
        if ( SPI != none )
            SPI.Healed(LastHealAmount, self, MedicGun);
    }
    if ( KFMonster(LastDamagedBy) != none && Healer.IsMedic() ) {
        CombatMedicTarget = KFMonster(LastDamagedBy);
    }
    return true;
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
                CalcGroundSpeed();
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
    // C&P + Fixed from KFHumanPawn
    if (BurnDown > 0) {
        if ( BurnInstigator == self || KFPawn(BurnInstigator) == none ) {
            // lower damage each burn tick unless it is PvP damage
            LastBurnDamage /= 2;
        }
        TakeFireDamage(LastBurnDamage, BurnInstigator);
    }
    else if ( bBurnApplied ) {
        StopBurnFX();
    }

    if( ScrnPC != none ) {
        bOnDrugs = false;
        if ( Health <= 0 ) {
            PlaySound(MiscSound,SLOT_Talk);
        }
        else if ( Health < 25 ) {
            PlaySound(BreathingSound, SLOT_Talk, ((50-Health)/5)*TransientSoundVolume,,TransientSoundRadius,, false);
        }

        // Accuracy vs. Movement tweakage!  - Alex
        // Timer is executed once per 1.5s. Replication is also messed up. Removing it  -- PooSH
        // if ( KFWeap != none )
        //     KFWeap.AccuracyUpdate(VSize(Velocity));
    }

    // TODO: WTF? central here
    // Instantly set the animation to arms at sides Idle if we've got no weapon (rather than Pointing an invisible gun!)
    if ( Weapon == none || (Weapon.ThirdPersonActor == none && VSizeSquared(Velocity) == 0) )
        IdleWeaponAnim = IdleRestAnim;


    // tick down health if it's greater than max
    if ( Health > HealthMax ) {
        if ( Health > HealthMax + 150 )
            Health = HealthMax + 150;
        else if ( Health > HealthMax + 100 )
            Health -= 5;
        else
            Health -= 2;
        // make sure not to overshoot
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

simulated function FixZedTimeAim()
{
    local int i;
    local KFFire f;

    for (i = 0; i < 2; ++ i) {
        f = KFFire(Weapon.GetFireMode(i));
        if (f != none && f.NumShotsInBurst != -1) {
            f.NumShotsInBurst = -1; // gets +1 in KFFire.GetSpread()
        }
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

    if ( bQuickMeleeInProgress && Level.TimeSeconds > QuickMeleeFinishTime ) {
        log('Fixing QuickMelee', 'ScrnBalance');
        QuickMeleeFinished();
    }

    if ( WeaponToFixClientState != none ) {
        // make sure that we don't hide current weapon (in case when QuickMelee didn't worked)
        if ( bQuickMeleeInProgress && WeaponToFixClientState != Weapon
                && WeaponToFixClientState.ClientState == WS_ReadyToFire )
        {
            WeaponToFixClientState.ClientState = WS_Hidden;
            WeaponToFixClientState.ClientGrenadeState = GN_None;
            WeaponToFixClientState.SetTimer(0, false);
        }
        WeaponToFixClientState = none;
    }

    AlphaAmount = 255; // hack to avoid KFHumanPawn of updating KFPRI.ThreeSecondScore
    super.Tick(DeltaTime);

    if (ScrnPC != none && ScrnPC.bZEDTimeActive && Weapon != none) {
        // there is a bug KFFire.GetSpread() that does not take into account zed time and keeps stacking NumShotsInBurst,
        // drastically increasing spread even for single shots.
        FixZedTimeAim();
    }

    if ( Role == ROLE_Authority ) {
        if ( MacheteBoost > 0 && Level.TimeSeconds > MacheteResetTime ) {
            MacheteBoost = MacheteBoost >> 1;
            MacheteResetTime = Level.TimeSeconds + 2.0;
            CalcGroundSpeed();
        }
    }
    else {
        if ( HealthBonus != ClientHealthBonus ) {
            HealthBonus = ClientHealthBonus;
            CalcHealthMax();
        }
        if (ScrnPC != none && !bThrowingNade && Frag(Weapon) != none) {
            // Frag should not be equipped
            ScrnPC.ClientSwitchToBestWeapon();
        }
    }

    if ( KFPRI != none && ( PrevPerkClass != KFPRI.ClientVeteranSkill || PrevPerkLevel != KFPRI.ClientVeteranSkillLevel) )
        VeterancyChanged();

    if ( bViewTarget )
        UpdateSpecInfo();

    if (bWantsZoom) {
        CheckZoom();
    }
}

simulated function TickFX(float DeltaTime)
{
    super.TickFX(DeltaTime);

    if (Level.TimeSeconds > GlowCheckTime && !bInvis) {
        CheckGlow();
    }
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

simulated exec function ToggleFlashlight()
{
    local Inventory inv;
    local int c;
    local KFWeapon w, best;
    local byte bestGroup;

    if (Controller == none)
        return;

    w = KFWeapon(Weapon);
    if (w != none && w.bTorchEnabled) {
        Weapon.ClientStartFire(1);
        return;
    }

    for (inv = Inventory; inv != none && ++c < 1000; inv = inv.Inventory) {
        w = KFWeapon(inv);
        if (w != none && w.bTorchEnabled && ((w.HasAmmo() && w.InventoryGroup > bestgroup) || best == none)) {
            best = w;
            if (w.HasAmmo()) {
                bestGroup = w.InventoryGroup;
            }
        }
    }

    if (best != none) {
        best.bPendingFlashlight = true;
        PendingWeapon = best;
        if (Weapon != none) {
            Weapon.PutDown();
        }
        else {
            ChangedWeapon();
        }
        return;
    }
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
    local KFWeapon KFW;

    if (Level.Pauser != none || SecondaryItem != none)
        return;

    KFW = KFWeapon(Weapon);
    if ( ScrnPerk == none || KFW == none || !ScrnPerk.static.CanCookNade(KFPRI, Weapon) )
        return;


    aFrag = ScrnFrag(FindPlayerGrenade());
    if ( aFrag == none || !aFrag.CanCook())
        return;

    if ( aFrag.HasAmmo() && !bThrowingNade
            && !aFrag.bCooking && !aFrag.bThrowingCooked
            && Level.TimeSeconds - aFrag.CookExplodeTimer > 0.1 )
    {
        if ( KFW.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
                || (KFW.bIsReloading && !KFW.InterruptReload()) )
            return;

        aFrag.CookNade();

        KFW.ClientGrenadeState = GN_TempDown;
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
    local WeaponFire NadeFire;

    if ( bThrowingNade || SecondaryItem != none )
        return;

    KFW = KFWeapon(Weapon);
    PlayerGrenade = FindPlayerGrenade();
    if ( PlayerGrenade != none && PlayerGrenade.HasAmmo() ) {
        NadeFire = PlayerGrenade.GetFireMode(0);
        if ( KFW == none || KFW.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
                || (KFW.bIsReloading && !KFW.InterruptReload())
                || NadeFire.NextFireTime - Level.TimeSeconds > 0.1 )
            return;

        KFW.ClientGrenadeState = GN_TempDown;
        KFW.PutDown();
        // put here because we need it on the client side
        NadeFire.NextFireTime = Level.TimeSeconds + NadeFire.FireRate;
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
            // || KFW.GetFireMode(1).NextFireTime - Level.TimeSeconds > 0.1
            || KFW.ClientState == WS_PutDown
            || KFW.ClientGrenadeState != GN_None
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
        // QuickMeleeFinishTime is a last resort to make sure we don't stuck in quick melee
        QuickMeleeFinishTime = Level.TimeSeconds + QuickMeleeWeapon.GetFireMode(1).FireRate + 1.0;
        KFW.SetTimer(0, false);
        KFW.ClientGrenadeState = GN_TempDown;
        KFW.PutDown();
    }
}

function QuickMeleeFinished()
{
    local KFWeapon KFW;

    KFW = KFWeapon(Weapon);
    if ( KFW != none ) {
        KFW.ClientGrenadeState = GN_None;
    }
    bQuickMeleeInProgress = false;
    SecondaryItem = none;
    WeaponToFixClientState = none;
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

function ServerRequestAutoReload()
{
    local KFWeapon W;

    W = KFWeapon(Weapon);
    if (W != none && W.MagAmmoRemaining < W.GetFireMode(0).AmmoPerFire && W.AllowReload()) {
        W.ReloadMeNow();
    }
}

// disable automatic reloading
simulated function Fire( optional float F )
{
    local KFWeapon W;

    if ( Weapon == none )
        return;

    W = KFWeapon(Weapon);
    if (W != none && !W.bMeleeWeapon && W.MagAmmoRemaining < W.GetFireMode(0).AmmoPerFire
            && W.MagCapacity > 1 && W.bConsumesPhysicalAmmo && !W.bIsReloading && !W.bHoldToReload)
    {
        if (ScrnPC != none && ScrnPC.bManualReload) {
            if ( W.AmmoAmount(0) == 0 )
                ScrnPC.ReceiveLocalizedMessage(class'ScrnPlayerWarningMessage',1);
            else
                ScrnPC.ReceiveLocalizedMessage(class'ScrnPlayerWarningMessage',0);
            W.PlayOwnedSound(W.GetFireMode(0).NoAmmoSound, SLOT_None,2.0,,,,false); //play weapon's no ammo sound
            W.GetFireMode(0).ModeDoFire(); //force weapon's mode do fire
        }
        else {
            ServerRequestAutoReload();
        }
        return;
    }

    Weapon.Fire(F);

    if ( W != none && W.FireModeClass[0] != class'KFMod.NoFire' )
        ServerFire(0);
}

simulated function AltFire( optional float F )
{
    local KFWeapon W;

    if ( Weapon == none )
        return;
    W = KFWeapon(Weapon);
    if ( ScrnPC != none && ScrnPC.bManualReload && W != none && !W.bMeleeWeapon && W.bConsumesPhysicalAmmo
            && W.bReduceMagAmmoOnSecondaryFire && KFMedicGun(W) == none
            && !W.bIsReloading && !W.bHoldToReload
            && W.MagCapacity > 2 && W.MagAmmoRemaining < W.GetFireMode(1).AmmoPerFire ) {
        if ( W.AmmoAmount(0) == 0 )
            ScrnPC.ReceiveLocalizedMessage(class'ScrnPlayerWarningMessage',1);
        else
            ScrnPC.ReceiveLocalizedMessage(class'ScrnPlayerWarningMessage',0);
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

function KFWeapon FindSprintWeapon()
{
    if (SprintWeapon == none) {
        SprintWeapon = KFWeapon(FindInventoryType(class'Knife'));
    }
    return SprintWeapon;
}

function StartSprint()
{
    if (SprintWeapon == none && FindSprintWeapon() == none)
        return;
    if (Weapon == SprintWeapon)
        return;

    BeforeSprintWeapon = KFWeapon(Weapon);
    if (BeforeSprintWeapon != none) {
        PendingWeapon = SprintWeapon;
        BeforeSprintWeapon.ClientGrenadeState = GN_TempDown;  // faster switching
        BeforeSprintWeapon.PutDown();
    }
}

function StopSprint()
{
    if (Weapon != SprintWeapon || BeforeSprintWeapon == none)
        return;

    PendingWeapon = BeforeSprintWeapon;
    BeforeSprintWeapon.ClientGrenadeState = GN_BringUp;  // faster switching
    SprintWeapon.PutDown();
    BeforeSprintWeapon = none;
}


// made p2p damage more like p2m, not like in RO  -- PooSH
function ProcessLocationalDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType, array<int> PointsHit )
{
    local int i;
    local bool bHeadShot;
    local float KFHeadshotMult;
    local class<KFWeaponDamageType> KFDamType;
    local KFPlayerReplicationInfo InstigatorPRI;

    if ( instigatedBy != none  )
        InstigatorPRI = KFPlayerReplicationInfo( instigatedBy.PlayerReplicationInfo );

    // If someone else has killed this player , return
    if( bDeleteMe || PointsHit.Length < 1 || Health <= 0 || Damage <= 0 )
        return;

    // Don't process locational damage if we're not going to damage a friendly anyway
    if( instigatedBy != none && instigatedBy != self
            && TeamGame(Level.Game) != none && TeamGame(Level.Game).FriendlyFireScale ~= 0
            && instigatedBy.GetTeamNum() == GetTeamNum() )
        return;

    // ignore all the hitpoint crap from RO that does not make much sense in KF.
    // Simply determine is this a headshot or not
    KFDamType = class<KFWeaponDamageType>(damageType);
    if ( KFDamType != none && KFDamType.default.bCheckForHeadShots && InstigatorPRI != none ) {
        for( i = 0; i < PointsHit.Length; ++i) {
            if ( Hitpoints[PointsHit[i]].HitPointType == PHP_Head ) {
                bHeadShot = true;
                break;
            }
        }

        if ( bHeadShot ) {
            if ( KFDamType.default.bIsPowerWeapon ) {
                KFHeadshotMult = 1.0;
            }
            else {
                KFHeadshotMult = 2.0;
            }
            KFHeadshotMult = fmax(KFHeadshotMult, KFDamType.default.HeadShotDamageMult);
            if ( !KFDamType.default.bIsMeleeDamage && InstigatorPRI.ClientVeteranSkill != none ) {
                KFHeadshotMult *= fmin(2.0, InstigatorPRI.ClientVeteranSkill.Static.GetHeadShotDamMulti(
                        InstigatorPRI, KFPawn(instigatedBy), DamageType));
            }
            Damage *= KFHeadshotMult;
            PlaySound(HeadshotSound, SLOT_None,2.0,true,500);
        }
    }

    TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
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

    if (damageType == class'Fell') {
        Damage *= FallingDamageMod;
    }

    KFDamType = class<KFWeaponDamageType>(damageType);
    if ( InstigatedBy == none ) {
        // Player received non-zombie KF damage from unknown source.
        // Let's assume that it is friendly damage, e.g. from just disconnected/crashed/cheating teammate and ignore it.
        if ( KFDamType != none && class<DamTypeZombieAttack>(KFDamType) == none
                && (!bBurnified || KFDamType != class'DamTypeBurned') )
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
            Damage = InstigatorPRI.ClientVeteranSkill.Static.AddDamage(InstigatorPRI, none, KFHumanPawn(instigatedBy),
                    Damage, DamageType);
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
    Damage = OldHealth - Health;
    if (Damage == 0)
        return;

    if( class<DamTypeVomit>(DamageType)!=none ) {
        BileCount=7;
        BileInstigator = instigatedBy;
        LastBileDamagedByType=class<DamTypeVomit>(DamageType);
        if(NextBileTime< Level.TimeSeconds )
            NextBileTime = Level.TimeSeconds+BileFrequency;

        // ScrnPC.bVomittedOn is for vanilla achievement only. No need it in ScrN
        // if ( Level.Game != none && Level.Game.GameDifficulty >= 4.0 && ScrnPC != none && !ScrnPC.bVomittedOn ) {
        //     ScrnPC.bVomittedOn = true;
        //     ScrnPC.VomittedOnTime = Level.TimeSeconds;
        //
        //     if ( Controller.TimerRate == 0.0 )
        //         Controller.SetTimer(10.0, false);
        // }
    }

    //Bloody Overlays
    if ( Health <= 50 )
        SetOverlayMaterial(InjuredOverlay,0, true);

    // SERVER-SIDE ONLY
    if ( Role < ROLE_Authority )
        return;

    if ( HealthToGive > 0 ) {
        HealthToGive = max(HealthToGive - 5, 0);
        ClientHealthToGive = HealthToGive;
    }

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
                    bBurnified = true;
                }
            }
        }
    }

    if (Health > 0 && (Health + HealthToGive) < 50 && Level.Game.NumPlayers > 1 && ScrnPC != none
            && Level.TimeSeconds > LastDyingMessageTime + DyingMessageDelay/2) {
        if (Health <= 25 || Level.TimeSeconds > LastDyingMessageTime + DyingMessageDelay) {
            ScrnPC.Speech('SUPPORT', 0, "");  // MEDIC!
        }
        else {
            ScrnPC.Speech('AUTO', 6, "");  // I'm dying!
        }
        LastDyingMessageTime = Level.TimeSeconds;
    }

    // ScrN stuff
    if ( Health > 0 && HealthBeforeHealing > 0 && (level.TimeSeconds - LastHealTime) < 1.0 ) {
        if ( (HealthBeforeHealing - Damage) <= 0 && LastHealedBy != none && LastHealedBy != self ) {
            class'ScrnAchCtrl'.static.Ach2Pawn(LastHealedBy, 'TouchOfSavior', 1);
            HealthBeforeHealing = 0; //don't give this achievement anymore until next healing will be received
        }
        else if ( Health < HealthBeforeHealing )
            HealthBeforeHealing = Health;
    }
    CalcGroundSpeed();
}

function Suicide()
{
    local ScrnSuicideBomb bomb;

    foreach Level.DynamicActors(class'ScrnSuicideBomb', bomb) {
        if ( bomb.Instigator == self ) {
            bomb.ActivateExplosion();
            return;
        }
    }

    super.Suicide();
}

simulated function bool CanThrowWeapon()
{
    local KFWeapon KFWeap;
    local bool bWasReloading;

    if ( Weapon == none || !Level.Game.bAllowWeaponThrowing )
        return false;

    KFWeap = KFWeapon(Weapon);
    if ( KFWeap != none ) {
        bWasReloading = KFWeap.bIsReloading;
        // reloading does not prevent weapon from throwing
        KFWeap.bIsReloading = false;
    }

    if ( Weapon.CanThrow() ) {
        return true;
    }

    if ( KFWeap != none ) {
        // restore the original value
        KFWeap.bIsReloading = bWasReloading;
    }
    return false;
}

// fixes Tripwire's achievement crap
static function OnWeaponDrop(KFWeapon w)
{
    if ( w == none )
        return;

    w.bPreviouslyDropped = false;  // needed to set Tier3WeaponGiver
    w.bIsTier2Weapon = false; // This hack is needed because KFWeaponPickup.DroppedBy isn't set for tier 2 weapons.
    w.bIsTier3Weapon = w.default.bIsTier3Weapon; // restore default value from the hack in AddInventory()
}

function TossWeapon(Vector TossVel)
{
    OnWeaponDrop(KFWeapon(Weapon));
    super.TossWeapon(TossVel);
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

    * @param    Monster         Monster's controller, for which we are calculating the threat level
    * @param    CheckDistance   Not used!
    * @return   threat level between 0 and 100, where 100 is the max threat level.
    *
    * @author   PooSH
*/
function  float AssessThreatTo(KFMonsterController MC, optional bool CheckDistance)
{
    local KFMonster Zed;
    local int i, miIndex;

    Zed = KFMonster(MC.Pawn);
    if( bHidden || bDeleteMe || Health <= 0
            || MC == none || Zed == none)
    {
        return -1.f;
    }

    if ( Level.TimeSeconds - SpawnTime < 10 )
        return 0.01; // very minor chance to attack players who just spawned

    if ( Level.TimeSeconds < ForcedThreatLevelTime )
        return ForcedThreatLevel;

    // Gorefasts love Baron :D
    // https://www.youtube.com/watch?v=vytEYKpFAwk
    if ( bAmIBaron && ZombieGorefast(MC.Pawn) != none && TSCGameReplicationInfo(Level.GRI) == none ) {
        if ( class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo).BlameCounter >= 5 )
            return 100.f;
    }

    if (LastThreatMonster == MC && Level.TimeSeconds - LastThreatTime < 2.0)
        return LastThreat;

    miIndex = ZedInfo.Length;
    for (i = 0; i < ZedInfo.Length; ++i) {
        if (ZedInfo[i].Zed == Zed) {
            if (Level.TimeSeconds < ZedInfo[i].ThreatValidTime) {
                return ZedInfo[i].ThreatRating;
            }
            miIndex = i;
            break;
        }
        else if (miIndex == ZedInfo.Length && ZedInfo[i].Zed == none) {
            miIndex = i;  // reuse an emty entry
        }
    }
    if (miIndex == ZedInfo.length) {
        ZedInfo.insert(miIndex, 1);
    }

    // save threat level for this tick
    LastThreatMonster = MC;
    LastThreatTime = Level.TimeSeconds;
    LastThreat = MyFunc.static.AssessThreatTo(self, MC);
    // less chance to attach just-spawned players
    if ( Level.TimeSeconds - SpawnTime < 30 )
        LastThreat *= lerp( (Level.TimeSeconds - SpawnTime) / 30.0, 1.0, 0.01 );

    if ( KFStoryGameInfo(Level.Game) != none )
        LastThreat *= InventoryThreatModifier();

    ZedInfo[miIndex].Zed = Zed;
    ZedInfo[miIndex].ThreatRating = LastThreat;
    ZedInfo[miIndex].ThreatValidTime = 2.0 + 2.0*frand();
    return LastThreat;
}

function ForceThreatLevel(float ThreatLevel, float ThreatTime)
{
    ForcedThreatLevel = ThreatLevel;
    ForcedThreatLevelTime = Level.TimeSeconds + ThreatTime;
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

static function DropAllWeapons(Pawn P, optional bool bOnlyValuable)
{
    local Inventory Inv, NextInv;
    local KFWeapon Weap, CurWeap;
    local int i, c;
    local rotator r;
    local Vector X,Y,Z, TossVel;

    if ( P == none || (P.DrivenVehicle != None && !P.DrivenVehicle.bAllowWeaponToss) )
        return;

    CurWeap = KFWeapon(P.Weapon);
    r = P.Rotation;
    r.pitch = 0;
    // two passes because dropping a weapon may add another one (e.g. dual pistols / single pistol)
    for ( i = 0; i < 2; ++i ) {
        for ( Inv = P.Inventory; Inv != none && ++c < 1000; Inv = NextInv ) {
            NextInv = Inv.Inventory;
            Weap = KFWeapon(Inv);
            if (Weap != none && Weap.bCanThrow && !Weap.bKFNeverThrow
                    && (!bOnlyValuable || Weap == CurWeap || Weap.SellValue > 0)) {
                //PlayerController(P.Controller).ClientMessage("Dropping " $ GetItemName(String(Weap.class)) $ "...");
                OnWeaponDrop(Weap);
                r.yaw += 4096 + 8192.0 * frand(); // 45 +/- 22.5 degrees
                P.GetAxes(r,X,Y,Z);
                TossVel = Vector(r);
                Weap.Velocity = TossVel * ((P.Velocity Dot TossVel) + 200) + Vect(0,0,200);
                Weap.DropFrom(P.Location + 0.8 * P.CollisionRadius * X - 0.5 * P.CollisionRadius * Y);
                NextInv = P.Inventory; // start from beginning again
            }
            else if ( ToiletPaperAmmo(Inv) != none ) {
                DropAllTPStatic(ToiletPaperAmmo(Inv));
            }
        }
    }
    if ( P.Weapon == None && P.Controller != None )
        P.Controller.SwitchToBestWeapon();
}

static function DropAllTPStatic(ToiletPaperAmmo TPAmmo)
{
    local int c, load;
    local ToiletPaperProj tp;

    load = 10;
    c = TPAmmo.AmmoAmount / load;
    if ( c > 10 ) {
        c = 10;
        load = TPAmmo.AmmoAmount / c;
    }

    while ( --c >= 0 ) {
        tp = TPAmmo.Instigator.spawn(class'ToiletPaperProj', TPAmmo.Instigator,, TPAmmo.Instigator.Location, RotRand());
        if ( tp != none ) {
            tp.Damage = 0;  // prevent destroying other TP rolls
            if ( c == 0 ) {
                tp.Load = TPAmmo.AmmoAmount;
            }
            else {
                tp.Load = load;
            }
            TPAmmo.AmmoAmount -= tp.Load;
            tp.Speed = 200 + 300*frand();
            tp.MaxSpeed = 300 + 500*frand();
            tp.Velocity = tp.Speed * Vector(tp.Rotation);
            tp.Velocity.Z = 100 + 300*frand();
        }
    }
}

function DropAllTP()
{
    local ToiletPaperAmmo TPAmmo;

    TPAmmo = ToiletPaperAmmo(FindInventoryType(class'ToiletPaperAmmo'));
    if ( TPAmmo != none )
        DropAllTPStatic(TPAmmo);
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
    local ScrnCustomPRI ScrnPRI;

    // To fix cash tossing exploit.
    if( Level.TimeSeconds < CashTossTimer || (Level.TimeSeconds < LongTossCashTimer && LongTossCashCount>=20) )
        return;

    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo);
    if (ScrnPRI != none && ScrnPRI.DoshRequestCounter > 0) {
        // if the player shares the dosh, they don't need it anymore
        // Reset it even if the player doesn't have any dosh, allowing the player to reset the counter
        ScrnPRI.DoshRequestCounter = 0;
        ScrnPRI.NetUpdateTime = Level.TimeSeconds - 1;
    }

    if (Amount <= 0) {
        Amount = 100;
    }
    Amount = min(Amount, PlayerReplicationInfo.Score);
    if (Amount <= 0)
        return;

    GetAxes(Rotation,X,Y,Z);
    TossVel = Vector(GetViewRotation());
    TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);
    CashPickup = Spawn(TossedCashClass,,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);
    if (CashPickup != none) {
        CashPickup.CashAmount = Amount;
        CashPickup.bDroppedCash = true;
        CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
        CashPickup.Velocity = TossVel;
        CashPickup.DroppedBy = Controller;
        CashPickup.InitDroppedPickupFor(None);
        PlayerReplicationInfo.Score -= Amount;

        if (ScrnPC != none && Level.Game.NumPlayers > 1
                && Level.TimeSeconds - LastDropCashMessageTime > DropCashMessageDelay) {
            ScrnPC.Speech('AUTO', 4, "");
        }

        // Hack to get actors to accept dosh that's thrown inside their collision cylinder.
        // TODO: Check if bCollideWhenPlacing natively does the same.
        foreach CashPickup.TouchingActors(class 'Actor', A) {
            if (A.IsA('ScrnCashPickup') || A.IsA('KF_Slot_Machine')) {
                A.Touch(CashPickup);
            }
        }
    }

    CashTossTimer = Level.TimeSeconds + 0.1;
    if (LongTossCashTimer<Level.TimeSeconds) {
        LongTossCashTimer = Level.TimeSeconds+5.f;
        LongTossCashCount = 0;
    }
    else {
        ++LongTossCashCount;
    }
}

function ServerDoshTransfer(int Amount, optional PlayerReplicationInfo Receiver)
{
    local ScrnCustomPRI ScrnPRI;
    local KFSteamStatsAndAchievements SteamStats;

    if (PlayerReplicationInfo == Receiver)
        return;  // wtf? Transfering dosh to ourselves?

    Amount = min(Amount, PlayerReplicationInfo.Score);
    if (Amount <= 0)
        return;

    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PlayerReplicationInfo);
    SteamStats = KFSteamStatsAndAchievements(ScrnPC.SteamStatsAndAchievements);

    if (Receiver != none) {
        if (!ScrnPC.Mut.GameRules.AllowDoshTransfer(self, Receiver, Amount)) {
            return;
        }
        Receiver.Score += Amount;
        PlayerReplicationInfo.Score -= Amount;
        Receiver.NetUpdateTime = Level.TimeSeconds - 1;
        ClientMessage(Repl(Repl(strDoshTransferToPlayer,
                "%$", string(Amount)),
                "%p", class'ScrnF'.static.ColoredPlayerName(Receiver)));

        if (PlayerController(Receiver.Owner) != none) {
            PlayerController(Receiver.Owner).TeamMessage(PlayerReplicationInfo, Repl(strDoshReceivedFromPlayer,
                    "%$", string(Amount)), 'TeamSay');
        }

        if (SteamStats != none) {
            SteamStats.AddDonatedCash(Amount);
        }
    }
    else if (PlayerReplicationInfo.Team != none) {
        PlayerReplicationInfo.Team.Score += Amount;
        PlayerReplicationInfo.Score -= Amount;
        ClientMessage(Repl(strDoshTransferToTeam, "%$", string(Amount)));
        PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
        if (SteamStats != none &&  PlayerReplicationInfo.Team.Size > 1) {
            SteamStats.AddDonatedCash(Amount);
        }
    }
    PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
    if (ScrnPRI != none && ScrnPRI.DoshRequestCounter > 0) {
        // if the player shares the dosh, they don't need it anymore
        ScrnPRI.DoshRequestCounter = 0;
        ScrnPRI.NetUpdateTime = Level.TimeSeconds - 1;
    }
}

simulated function int GetAvailableDosh()
{
    local int dosh;

    dosh = PlayerReplicationInfo.Score;
    if (PlayerReplicationInfo.Team != none) {
        dosh += PlayerReplicationInfo.Team.Score;
    }
    return dosh;
}

// NB! Ensure the player has enough dosh before calling this function!
function TraderChargeDosh(int Amount)
{
    if (Amount <= 0)
        return;

    PlayerReplicationInfo.Score -= Amount;

    // There is a special place in hell for people who store financial data in float.
    if (PlayerReplicationInfo.Score < 1.0) {
        if (PlayerReplicationInfo.Score < 0 && PlayerReplicationInfo.Team != none) {
            PlayerReplicationInfo.Team.Score += PlayerReplicationInfo.Score;
            if ( PlayerReplicationInfo.Team.Score < 1.0) {
                 PlayerReplicationInfo.Team.Score = 0;
            }
             PlayerReplicationInfo.Team.NetUpdateTime = Level.TimeSeconds - 1;
        }
        PlayerReplicationInfo.Score = 0;
    }
    PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
}

simulated function DoHitCamEffects(vector HitDirection, float JarrScale, float BlurDuration, float JarDurationScale )
{
    if( ScrnPC!=none && Viewport(ScrnPC.Player)!=None )
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
    if ( ScrnPC != none && !ScrnPC.bDestroying ) {
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
    local string CN;

    if ( ScrnPC != none && IsLocallyControlled() ) {
        // check this only on player side, because it stores
        // RedCharacter & BlueCharacter in the config
        CN = rec.DefaultName;
        if ( !ScrnPC.ValidateCharacter(CN) ) {
            // character invalid, change it valid one, which was set up in ValidateCharacter()
            rec = class'xUtil'.static.FindPlayerRecord(CN);
            ScrnPC.ChangeCharacter(CN);
        }
    }

    super.Setup(rec, bLoadNow);
}

// disable shopping at enemy trader
function bool CanBuyNow()
{
    local ShopVolume Shop, MyShop, EnemyShop;
    local KFGameReplicationInfo KFGRI;
    local TSCGameReplicationInfo TSCGRI;
    local bool bAtEnemyShop;

    KFGRI = KFGameReplicationInfo(Level.GRI);
    TSCGRI = TSCGameReplicationInfo(Level.GRI);

    if (KFGRI == none || KFGRI.bWaveInProgress || PlayerReplicationInfo==None || PlayerReplicationInfo.Team==None)
        return False;

    if ( TSCGRI == none ) {
        MyShop = KFGRI.CurrentShop;
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
            ScrnPC.bShoppedThisWave = true;
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

    // push crawlers away
    crawler = ZombieCrawler(Other);
    if ( crawler != none && crawler.health > 0 && !crawler.bPouncing ) {
        crawler.Velocity = GroundSpeed * 2 * normal(Acceleration);
        crawler.Acceleration = crawler.Velocity;
    }
}

simulated function GetAss(out Vector AssLocation, out Rotator AssRotation)
{
    local Vector x,y,z;

    GetAxes(Rotation, x, y, z);
    AssRotation = Rotation;
    AssLocation = GetBoneCoords(RootBone).origin;
    AssLocation -= 20 * z;
    if ( Controller != none && Controller.bDuck == 0 ) {
        AssRotation.Pitch = -24576;
    }
    else {
        AssRotation.Pitch = -32768;
    }
}

exec function Fart(optional byte Scale)
{
    local ScrnFart MyFart;
    local Rotator r;
    local Vector loc;

    GetAss(loc, r);
    PlaySound(FartSound, SLOT_Talk, 2.0, false, 1000 + 500 * Scale);
    MyFart = spawn(class'ScrnFart',,, loc, r);
    if ( MyFart != none ) {
        MyFart.SetScale(Scale);
    }
}

function Crap(optional int Amount)
{
    local class<ToiletPaperProj> ProjClass;
    local ToiletPaperProj TP;
    local ToiletPaperAmmo TPAmmo;
    local Rotator r;
    local Vector loc;

    if ( Amount <= 0 )
        Amount = 1;

    TPAmmo = ToiletPaperAmmo(FindInventoryType(class'ToiletPaperAmmo'));
    if ( TPAmmo == none || !TPAmmo.UseAmmo(Amount, false) ) {
        return;
    }

    if ( Level.TimeSeconds > NextBrownCrapTime ) {
        ProjClass = class'ToiletPaperProj_Brown';
        NextBrownCrapTime = Level.TimeSeconds + 60.0;
    }
    else {
        ProjClass = class'ToiletPaperProj';
    }
    GetAss(loc, r);

    TP = spawn(ProjClass, self, 'Crap', loc, r);
    if ( TP == none ) {
        ClientMessage("Failed to crap");
        return;
    }
    TP.Load = Amount;
    TP.Speed = 100;
    TP.MaxSpeed = 200;
    TP.bBounce = false;
    TP.Velocity = TP.Speed * Vector(r);
    TP.SetRotation(r);
}

exec function IronSightZoomIn()
{
    local KFWeapon W;

    bWantsZoom = true;
    W = KFWeapon(Weapon);
    if (W != none) {
        W.IronSightZoomIn();
    }
}

exec function IronSightZoomOut()
{
    local KFWeapon W;

    bWantsZoom = false;
    W = KFWeapon(Weapon);
    if (W != none) {
        W.IronSightZoomOut();
    }
}

function CheckZoom()
{
    local KFWeapon W;

    if (!bWantsZoom)
        return;

    W = KFWeapon(Weapon);
    if (W != none && W.bHasAimingMode && !W.bAimingRifle && !W.bZoomingIn) {
        W.IronSightZoomIn();
    }
}

simulated function CheckGlow()
{
    local TSCGameReplicationInfo TSCGRI;

    if (Level.NetMode == NM_DedicatedServer || IsLocallyControlled()) {
        GlowCheckTime = Level.TimeSeconds + 999999;
        return;
    }

    TSCGRI = TSCGameReplicationInfo(Level.GRI);
    if ( TSCGRI == none ) {
        GlowCheckTime = Level.TimeSeconds + 999999;
        return;
    }

    GlowCheckTime = Level.TimeSeconds + default.GlowCheckTime;
    if (Health > 0 && TSCGRI.bHumanDamageEnabled && !TSCGRI.AtOwnBase(self)) {
        EnableGlow();
    }
    else {
        DisableGlow();
    }
}

simulated function Texture FindSkinTexture()
{
    local Texture tex;
    local Combiner cmb;
    local Shader shd;
    local int i;
    // local String s;

    // for (i = 0; i < Skins.Length; ++i) {
    //     s = PlayerReplicationInfo.CharacterName $ ".Skins: {" $ Skins[0];
    //     for (i = 1; i < Skins.Length; ++i) {
    //         s $= ", " $ Skins[i];
    //     }
    //     s $= "}";
    //     log(s, 'ScrnBalance');
    // }

    // first pass - look for a shader or combiner
    for (i = 0; i < Skins.Length; ++i) {
        shd = Shader(Skins[i]);
        if (shd != none) {
            tex = Texture(shd.Diffuse);
            if (tex != none)
                return tex;
            cmb = Combiner(shd.Diffuse);
        }
        else {
            cmb = Combiner(Skins[i]);
        }

        if (cmb == none)
            continue;
        tex = Texture(cmb.Material1);
        if (tex != none)
            return tex;
        tex = Texture(cmb.Material2);
        if (tex != none)
            return tex;
    }
    // second pass - look for any texture
    for (i = 0; i < Skins.Length; ++i) {
        tex = Texture(Skins[i]);
        if (tex != none) {
            return tex;
        }
    }
    return none;
}

simulated function Color GetGlowColor()
{
    local TSCGameReplicationInfo TSCGRI;
    local ScrnPlayerController LocalPC;

    LocalPC = ScrnPlayerController(Level.GetLocalPlayerController());
    if (LocalPC == none) {
        return class'ScrnPlayerController'.default.GlowColorSingleTeam; // wtf?
    }

    TSCGRI = TSCGameReplicationInfo(Level.GRI);
    if (TSCGRI == none || TSCGRI.bSingleTeamGame) {
        return LocalPC.GlowColorSingleTeam;
    }

    if (GetTeamNum() == 0) {
        return LocalPC.GlowColorRed;
    }
    return LocalPC.GlowColorBlue;
}

simulated function Combiner AllocateGlowCombiner(Material OriginalMat)
{
    local Combiner cmb;

    cmb = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
    cmb.CombineOperation = CO_Add;
    cmb.AlphaOperation = AO_Use_Alpha_From_Material1;
    cmb.Material1 = OriginalMat;
    cmb.Material2 = GlowColor;
    cmb.InvertMask = false;
    cmb.Modulate2X = false;
    cmb.Modulate4X = false;
    return cmb;
}

simulated function InitGlow()
{
    local Texture OriginalTex;

    if (bGlowInited)
        return;
    bGlowInited = true;

    if (Skins.Length == 0)
        return;

    if (GlowColor == none) {
        GlowColor = FadeColor(Level.ObjectPool.AllocateObject(class'FadeColor'));
        GlowColor.Color1.R = 0;
        GlowColor.Color1.G = 0;
        GlowColor.Color1.B = 0;
        GlowColor.Color1.A = 0;
        GlowColor.FadePeriod = 0.35;
        GlowColor.ColorFadeType = FC_Linear;
    }

    if (GlowCmb == none) {
        // find the original skin texture to apply GlowColor on top of
        OriginalTex = FindSkinTexture();
        if (OriginalTex != none) {
            GlowCmb = AllocateGlowCombiner(OriginalTex);
            GlowCmb.FallbackMaterial = Skins[0];
        }
    }
}

simulated function EnableGlow()
{
    local int i, NumSkins;

    if (!bGlowInited)
        InitGlow();

    if (GlowCmb == none || Skins[0] == GlowCmb)
        return;

    // in case the pawn changed the team
    GlowColor.Color2 = GetGlowColor();

    // A player pawn must have at least two skins: #0 - body, #1 - face.
    // The same sking can be used for body and face. In this case, Skins[0] = Skins[1]
    NumSkins = Clamp(Skins.Length, 2, 4);
    for (i = 0; i < NumSkins; ++i) {
        RealSkins[i] = Skins[i];
        Skins[i] = GlowCmb;
    }
    bUnlit = true;
}

simulated function DisableGlow()
{
    local int i, NumSkins;

    if (GlowCmb == none || Skins[0] != GlowCmb)
        return;

    NumSkins = Clamp(Skins.Length, 2, 4);
    for (i = 0; i < NumSkins; ++i) {
        Skins[i] = RealSkins[i];
    }
    bUnlit = false;
}


defaultproperties
{
    MyFunc=class'ScrnPawnFunc'
    DoshPerHeal=0.6  // the same as in vanilla
    HealthRestoreRate=7.0  // 10
    HealthSpeedModifier=0.15
    NoVestClass=class'ScrnNoVestPickup'
    StandardVestClass=class'ScrnCombatVestPickup'
    LightVestClass=class'ScrnLightVestPickup'
    CurrentVestClass=class'ScrnNoVestPickup'
    ShieldStrengthMax=0.000000
    bCheckHorzineArmorAch=true
    strNoSpawnCashToss="Can not drop starting cash"
    strDoshTransferToPlayer="^y$$%$ ^w$transfered to ^g$%p"
    strDoshTransferToTeam="^y$$%$ ^w$transfered to the ^g$Team Wallet"
    strDoshReceivedFromPlayer="transfered to you ^g$$%$"
    TossedCashClass=class'ScrnCashPickup'
    HeadshotSound=sound'ProjectileSounds.impact_metal09'
    AccelRate=1500
    TraderSpeedBoost=1.5
    CarriedInventorySpeed=1.0
    MeleeWeightSpeedReduction=2
    WeaponWeightSpeedReduction=0
    bAllowMacheteBoost=true
    PrevPerkLevel=-1
    MaxFallSpeed=750
    FallingDamageMod=1.0
    FartSound=SoundGroup'ScrnSnd.Fart'
    RequiredEquipment(0)="ScrnBalanceSrv.ScrnKnife"
    RequiredEquipment(1)="ScrnBalanceSrv.ScrnSingle"
    RequiredEquipment(2)="ScrnBalanceSrv.ScrnFrag"
    RequiredEquipment(3)="ScrnBalanceSrv.ScrnSyringe"
    RequiredEquipment(4)="ScrnBalanceSrv.ScrnWelder"
    GlowCheckTime=0.35
    DyingMessageDelay=8.0
    bBlockHitPointTraces=true
    RagdollLifeSpan=120
}
