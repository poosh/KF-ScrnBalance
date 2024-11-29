class ScrnMK23Pistol extends MK23Pistol;

var transient ScrnDualMK23Pistol DualGuns;

var transient bool bBotControlled;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload

var bool bFiringLastRound;
var protected bool bDoubleAmmo;

replication
{
    reliable if ( Role == ROLE_Authority )
        bDoubleAmmo;

    reliable if ( Role == ROLE_Authority )
        ClientReplicateAmmo;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( MagAmmoRemaining == 0 && !bIsReloading ) {
            LockSlideBack();
        }
    }
}

simulated function Destroyed()
{
    if (bDoubleAmmo) {
        // this code triggers only when selling weapon at the trader
        bDoubleAmmo = class'ScrnDualMK23Laser'.static.CheckDoubleAmmo(Instigator, self);
    }

    super.Destroyed();
}


simulated function Fire(float F)
{
    bFiringLastRound = MagAmmoRemaining == 1;
    super.Fire(f);
}

simulated function AltFire(float F)
{
    DoToggle();
}

exec function SwitchModes()
{
    DoToggle();
}

simulated function DoToggle()
{
    if ( DualGuns == none )
        return;

    Instigator.PendingWeapon = DualGuns;
    PutDown();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    if ( Role == ROLE_Authority && DualGuns != none ) {
        DualGuns.SyncSingleFromDual();
        ReplicateAmmo();
    }

    Super.BringUp(PrevWeapon);

    if ( Instigator.IsLocallyControlled() ) {
        SetSlidePositions();
    }
}

simulated function bool PutDown()
{
    if ( super(KFWeapon).PutDown() ) {
        if ( DualGuns != none ) {
            DualGuns.SyncDualFromSingle();
        }
        return true;
    }
    return false;
}

simulated function SetSlidePositions()
{
    if (MagAmmoRemaining == 0)
        LockSlideBack();
    else
        ResetSlidePosition();
}

simulated function ResetSlidePosition()
{
    SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset slide position
}

simulated function LockSlideBack()
{
    SetBoneLocation( 'Slide', -PistolSlideOffset, 100 ); //lock slide back
}

//only called by clients
simulated function HandleSlideMovement()
{
    if (TweenEndTime > Level.TimeSeconds) {
        SetBoneLocation( 'Slide', PistolSlideOffset, (TweenEndTime - Level.TimeSeconds)*500 ); //
    }
    else {
        ResetSlidePosition();
        TweenEndTime = 0;
        bTweeningSlide = false;
    }
}

// compensates reload animation to keep slide in place
simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start slide tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
    HandleSlideMovement();
}

simulated function WeaponTick(float dt)
{
    //client side only
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (bTweeningSlide)
        {
            HandleSlideMovement();
        }
    }

    // C&P from KFWepon to cut the crap out of it
    // WARNING! The code is stripped to remove unsued features, such as:
    // Flashlight, bHoldToReload, bReloadEffectDone, etc.
    // Do not uses this code as a general reference
    if( bHasAimingMode ) {
        if( bForceLeaveIronsights ) {
            if( bAimingRifle ) {
                ZoomOut(true);
                if( Role < ROLE_Authority)
                    ServerZoomOut(false);
            }
            bForceLeaveIronsights = false;
        }
        if( ForceZoomOutTime > 0 ) {
            if( bAimingRifle ) {
                if( Level.TimeSeconds - ForceZoomOutTime > 0 ) {
                    ForceZoomOutTime = 0;
                    ZoomOut(true);
                    if( Role < ROLE_Authority)
                        ServerZoomOut(false);
                }
            }
            else {
                ForceZoomOutTime = 0;
            }
        }
    }

     if ( Level.NetMode == NM_Client || Instigator == None )
        return;

    if ( bIsReloading ) {
        if ( Level.TimeSeconds > ReloadTimer ) {
            ActuallyFinishReloading();
        }
    }
    else if ( bBotControlled && MagAmmoRemaining < MagCapacity) {
        if ( MagAmmoRemaining == 0
                || (Level.TimeSeconds - Instigator.Controller.LastSeenTime) > min(MagAmmoRemaining, 5) )
        {
            ReloadMeNow();
        }
    }
}

function bool IsDoubleAmmo() {
    return bDoubleAmmo;
}

function SetDoubleAmmo(bool value) {
    if (bDoubleAmmo == value)
        return;
    bDoubleAmmo = value;
    NextAmmoCheckTime = Level.TimeSeconds - 1;
    NetUpdateTime = Level.TimeSeconds - 1;
    if (Ammo[0] != none) {
        Ammo[0].AmmoAmount = clamp(Ammo[0].AmmoAmount, 0, MaxAmmo(0));
        Ammo[0].NetUpdateTime = Level.TimeSeconds - 1;
    }
    if (ScrnHumanPawn(Instigator) != none) {
        ScrnHumanPawn(Instigator).SetTraderUpdate();
    }
}

simulated function float GetAmmoMulti()
{
    local KFPlayerReplicationInfo KFPRI;

    if (DualGuns != none)
        return DualGuns.GetAmmoMulti();

    if ( NextAmmoCheckTime > Level.TimeSeconds )
        return LastAmmoResult;

    NextAmmoCheckTime = Level.TimeSeconds + 0.1;

    LastAmmoResult = 1.0 + int(bDoubleAmmo);
    if ( Instigator != none )
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        LastAmmoResult *= KFPRI.ClientVeteranSkill.static.AddExtraAmmoFor(KFPRI, AmmoClass[0]);
    }
    return LastAmmoResult;
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
    if ( AmmoClass[0] == None )
        return;

    if ( Ammo[0] != None ) {
        MaxAmmoPrimary = int(Ammo[0].default.MaxAmmo * GetAmmoMulti());
        CurAmmoPrimary = Ammo[0].AmmoAmount;
    }
    else {
        MaxAmmoPrimary = int(AmmoClass[0].Default.MaxAmmo * GetAmmoMulti());
        CurAmmoPrimary = AmmoCharge[0];
    }
}

//allowing +1 reload with full mag
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if( bBotControlled ) {
        return !bIsReloading && MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining;
    }

    return !( FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || ClientState == WS_BringUp
            || MagAmmoRemaining >= MagCapacity + 1 || AmmoAmount(0) <= MagAmmoRemaining
            || (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 );
}

exec function ReloadMeNow()
{
    local float ReloadMulti;
    local KFPlayerReplicationInfo KFPRI;
    local KFPlayerController KFPC;

    if(!AllowReload())
        return;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    KFPC = KFPlayerController(Instigator.Controller);

    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if (KFPRI != none && KFPRI.ClientVeteranSkill != none )
        ReloadMulti = KFPRI.ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPRI, self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    bShortReload = MagAmmoRemaining > 0;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;
    ReloadTimer = Level.TimeSeconds + ReloadRate;

    if( bHoldToReload )
    {
        NumLoadedThisReload = 0;
    }
    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);
    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPC != none
        && Level.TimeSeconds - KFPC.LastReloadMessageTime > KFPC.ReloadMessageDelay )
    {
        KFPC.Speech('AUTO', 2, "");
        KFPC.LastReloadMessageTime = Level.TimeSeconds;
    }
}

simulated function ClientReload()
{
    local float ReloadMulti;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    if (MagAmmoRemaining <= 0)
    {
        bShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        ResetSlidePosition(); //reset slide so that the animation's slide position gets used
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent slide from sliding
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move the slide forward to compensate animations's pull back
    }
}

function ActuallyFinishReloading()
{
   bDoSingleReload=false;
   // no need to replicate ClientFinishReloading, it gets called on the client side by ClientReplicateAmmo
   // ClientFinishReloading();
   bIsReloading = false;
   // bReloadEffectDone = false;
   AddReloadedAmmo();

   if ( Instigator.IsLocallyControlled() ) {
       PlayIdle();
       if(bShortReload) {
           StartTweeningSlide();
       }
   }
}

function AddReloadedAmmo()
{
    local PlayerController PC;
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    if ( bShortReload )
        a++; // 1 bullet already bolted

    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);
    ReplicateAmmo();

    PC = PlayerController(Instigator.Controller);
    if ( PC != none && KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements) != none ) {
        KFSteamStatsAndAchievements(PC.SteamStatsAndAchievements).OnWeaponReloaded();
    }
}

function ReplicateAmmo()
{
    local int a;

    a = AmmoAmount(0);
    ClientReplicateAmmo((AmmoAmount(0) << 8) | (MagAmmoRemaining & 0xFF));
}

simulated protected function ClientReplicateAmmo(int SrvAmmo)
{
    if ( Instigator != none ) {
        UpdateMagCapacity(Instigator.PlayerReplicationInfo);
    }

    MagAmmoRemaining = SrvAmmo & 0xFF;
    ClientForceAmmoUpdate(0, (SrvAmmo >> 8));

    if ( bIsReloading ) {
        ClientFinishReloading();
    }
    else {
        SetSlidePositions();
    }
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;
    PlayIdle();

    if(bShortReload) {
        StartTweeningSlide();  // compensate slide movement in tween from reload to idle
    }

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

//original TWI code contained some gay issues like always -- by PooSH
function bool HandlePickupQuery( pickup Item )
{
    if ( Item.InventoryType != none )
    {
        if ( KFPlayerController(Instigator.Controller) != none )
        {
            KFPlayerController(Instigator.Controller).PendingAmmo = WeaponPickup(Item).AmmoAmount[0];
        }

        return false; // Allow to "pickup" so this weapon can be replaced with dual MK23.
    }

    return Super(KFWeapon).HandlePickupQuery(Item);
}

simulated function DetachFromPawn(Pawn P)
{
    // Triggers on the server side on weapon put down. PutDown() is client-side only.
    if ( DualGuns != none ) {
        DualGuns.SyncDualFromSingle();
    }
    super.DetachFromPawn(P);
}

function DropFrom(vector StartLocation)
{
    local Pawn MyInstigator;

    if ( DualGuns != none ) {
        DualGuns.Velocity = Velocity;
        DualGuns.DropFrom(StartLocation);
        return;
    }

    MyInstigator = Instigator; // backup, as it gets cleared in DropFrom()

    super.DropFrom(StartLocation);

    if (bDoubleAmmo) {
        class'ScrnDualMK23Laser'.static.CheckDoubleAmmo(MyInstigator, self);
    }
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    local KFPlayerReplicationInfo KFPRI;
    local KFWeaponPickup WeapPickup;

    KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);
    WeapPickup = KFWeaponPickup(Pickup);
    bBotControlled = !Other.IsHumanControlled();

    //pick the lowest sell value
    if ( WeapPickup != None && KFPRI != None && KFPRI.ClientVeteranSkill != none ) {
        SellValue = 0.75 * min(WeapPickup.Cost, WeapPickup.default.Cost
            * KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, WeapPickup.class));
    }

    Super.GiveTo(Other,Pickup);

    class'ScrnDualMK23Laser'.static.CheckDoubleAmmo(Other);
}


defaultproperties
{
    ReloadShortRate=1.83
    ReloadShortAnim="Reload"
    PistolSlideOffset=(X=0,Y=-0.0275000,Z=0.0)
    Weight=3.000000
    FireModeClass(0)=class'ScrnMK23Fire'
    Description="Match grade .45 ACP caliber pistol featuring a good balance between power, ammo count, and rate of fire. Damage is near to .44 Magnum but has no bullet overpenetration."
    PickupClass=class'ScrnMK23Pickup'
    ItemName="MK23 SE"
    Priority=80

    PutDownTime=0.15
    BringUpTime=0.15
    SelectAnimRate=3.5556
    PutDownAnimRate=3.5556
}
