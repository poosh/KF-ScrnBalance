class ScrnDualFlareRevolver extends DualFlareRevolver;

var transient ScrnFlareRevolver SingleGun;
var byte LeftGunAmmoRemaining;  // ammo in the left pistol. Left pistol always has more or equal bullets than the right one
var bool bConsumeLeft;
var transient int OtherGunAmmoRemaining; // ammo remaining in the other gun while holding a single pistol
var deprecated int OutOfOrderShots;  // equalize ammo in case when a single pistol was used before
var transient bool bFindSingleGun;
var transient bool bBotControlled;

var name  ReloadShortAnim;
var float ReloadShortRate;
var transient bool bShortReload;

replication
{
    reliable if ( Role == ROLE_Authority )
        LeftGunAmmoRemaining;

    reliable if ( Role == ROLE_Authority )
        ClientReplicateAmmo;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if( Role < ROLE_Authority) {
        bFindSingleGun = true;
    }
}

simulated function Destroyed()
{
    if ( SingleGun != none ) {
        SingleGun.DualGuns = none;
        SingleGun.InventoryGroup = SingleGun.default.InventoryGroup;
        SingleGun.UpdateMagCapacity(SingleGun.Instigator.PlayerReplicationInfo);
        SingleGun = none;
    }

    super.Destroyed();
}

simulated function WeaponTick(float dt)
{
    if ( Instigator == None )
        return;

    if (Level.NetMode != NM_DedicatedServer) {
        if ( bFindSingleGun && SingleGun == none ) {
            SingleGun = ScrnFlareRevolver(Instigator.FindInventoryType(DemoReplacement));
            if ( SingleGun != none ) {
                bFindSingleGun = false;
                SingleGun.DualGuns = self;
                SingleGun.InventoryGroup = 11;
                UpdateMagCapacity(Instigator.PlayerReplicationInfo);
            }
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

     if ( Role < ROLE_Authority )
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
    if ( SingleGun == none )
        return;

    Instigator.PendingWeapon = SingleGun;
    PutDown();
}

simulated function int RightGunAmmoRemaining()
{
    return MagAmmoRemaining - LeftGunAmmoRemaining;
}

simulated function UpdateMagCapacity(PlayerReplicationInfo PRI)
{
    local KFPlayerReplicationInfo KFPRI;

    MagCapacity = default.MagCapacity;
    KFPRI = KFPlayerReplicationInfo(PRI);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        MagCapacity *= KFPRI.ClientVeteranSkill.Static.GetMagCapacityMod(KFPRI, self);
    }
    NextAmmoCheckTime = 0;  // check on the next call
}

simulated function float GetAmmoMulti()
{
    local KFPlayerReplicationInfo KFPRI;

    if ( NextAmmoCheckTime > Level.TimeSeconds )
        return LastAmmoResult;

    NextAmmoCheckTime = Level.TimeSeconds + 1;
    LastAmmoResult = 2.0;
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

function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
    if ( !super(Weapon).ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
        return false;

    if ( Load > 0 && (Mode == 0 || bReduceMagAmmoOnSecondaryFire) ) {
        if (bConsumeLeft && LeftGunAmmoRemaining > 0 ) {
            // LeftGunAmmoRemaining is byte (unsigned). Make sure to not overlap.
            --LeftGunAmmoRemaining;
        }
        if ( --MagAmmoRemaining < 0 )
            MagAmmoRemaining = 0;
    }
    NetUpdateTime = Level.TimeSeconds - 1;

    if ( !HasAmmo() ) {
        if ( ScrnHumanPawn(Instigator) != none ) {
            ScrnHumanPawn(Instigator).CheckOutOfAmmo(true);
        }
    }
    return true;
}

/**
 * BringUp() is executed on both server and client sides.
 * PutDown() is executed only on the CLIENT side.
 * We call SyncSingleFromDual() inside the PutDown() only to predict SingleGun.MagAmmoRemaining on the client side
 * Actual value will be set later on the server side, from SingleGun.BringUp()
 * By doing that we prevent HUD flickering while bringing the gun up before MagAmmoRemaining gets replicated
 */
simulated function BringUp(optional Weapon PrevWeapon)
{
    local int i;
    local KFHumanPawn KFP;
    local bool bQuick;

    KFP = KFHumanPawn(Instigator);

    if (Role == ROLE_Authority && SingleGun != none) {
        SyncDualFromSingle();
        ReplicateAmmo();
    }

    //--- KFWeapon BEGIN
    HandleSleeveSwapping();

    if (KFP != none ) {
        KFP.SetAiming(false);
        bQuick = ClientGrenadeState == GN_BringUp || KFP.bIsQuickHealing > 0
                || (PrevWeapon == SingleGun && SingleGun != none);
    }

    bAimingRifle = false;
    bIsReloading = false;
    IdleAnim = default.IdleAnim;

    if (ClientState == WS_Hidden || ClientGrenadeState == GN_BringUp || (KFP != none && KFP.bIsQuickHealing > 0)) {
        PlayOwnedSound(SelectSound, SLOT_Interact,,,,, false);
        ClientPlayForceFeedback(SelectForce);  // jdf

        if (Instigator.IsLocallyControlled() && Mesh != none && HasAnim(SelectAnim)) {
            if (bQuick) {
                PlayAnim(SelectAnim, SelectAnimRate * BringUpTime / QuickBringUpTime, 0.0);
            }
            else {
                PlayAnim(SelectAnim, SelectAnimRate, 0.0);
            }
        }

        ClientState = WS_BringUp;
        if (bQuick) {
            ClientGrenadeState = GN_None;
            SetTimer(QuickBringUpTime, false);
        }
        else {
            SetTimer(BringUpTime, false);
        }
    }

    for (i = 0; i < NUM_FIRE_MODES; ++i) {
        FireMode[i].bIsFiring = false;
        FireMode[i].HoldTime = 0.0;
        FireMode[i].bServerDelayStartFire = false;
        FireMode[i].bServerDelayStopFire = false;
        FireMode[i].bInstantStop = false;
    }

    if (PrevWeapon != none && PrevWeapon.HasAmmo() && !PrevWeapon.bNoVoluntarySwitch) {
        OldWeapon = PrevWeapon;
    }
    else {
        OldWeapon = None;
    }
    //--- KFWeapon END
}

simulated function bool PutDown()
{
    local int i;
    local KFPawn KFP;
    local bool bQuick;

//--- KFWeapon BEGIN
    InterruptReload();

    if ( bIsReloading )
        return false;

    if( bAimingRifle )
        ZoomOut(False);

    KFP = KFPawn(Instigator);
    if (KFP != none) {
        bQuick = ClientGrenadeState == GN_TempDown || KFP.bIsQuickHealing > 0
                || (Instigator.PendingWeapon == SingleGun && SingleGun != none);
    }

    // From Weapon.uc
    if (ClientState == WS_BringUp || ClientState == WS_ReadyToFire) {
        if ( Instigator.PendingWeapon != none && !Instigator.PendingWeapon.bForceSwitch) {
            for (i = 0; i < NUM_FIRE_MODES; ++i) {
                if (FireMode[i].bFireOnRelease && FireMode[i].bIsFiring)
                    return false;
                if (FireMode[i].NextFireTime > Level.TimeSeconds + FireMode[i].FireRate * (1.f - MinReloadPct)) {
                    DownDelay = FMax(DownDelay, FireMode[i].NextFireTime - Level.TimeSeconds
                            - FireMode[i].FireRate * (1.f - MinReloadPct));
                }
            }
        }

        if (Instigator.IsLocallyControlled()) {
            for (i = 0; i < NUM_FIRE_MODES; ++i) {
                if (FireMode[i].bIsFiring)
                    ClientStopFire(i);
            }

            if (DownDelay <= 0 || bQuick) {
                if (ClientState == WS_BringUp || KFP.bIsQuickHealing > 0) {
                    TweenAnim(SelectAnim, PutDownTime);
                }
                else if (HasAnim(PutDownAnim)) {
                    if (bQuick) {
                        PlayAnim(PutDownAnim, PutDownAnimRate * PutDownTime / QuickPutDownTime, 0.0);
                    }
                    else {
                        PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
                    }

                }
            }
        }
        ClientState = WS_PutDown;
        if (Level.GRI.bFastWeaponSwitching)
            DownDelay = 0;
        if (DownDelay > 0) {
            SetTimer(DownDelay, false);
        }
        else if (bQuick) {
            SetTimer(QuickPutDownTime, false);
        }
        else {
            SetTimer(PutDownTime, false);
        }
    }

    for (i = 0; i < NUM_FIRE_MODES; ++i) {
        FireMode[i].bServerDelayStartFire = false;
        FireMode[i].bServerDelayStopFire = false;
    }
    Instigator.AmbientSound = None;
    OldWeapon = None;
//--- KFWeapon END

    if (SingleGun != none) {
        SyncSingleFromDual();
    }
    return true;
}

// sync the Single gun state based on Duals
simulated function SyncSingleFromDual()
{
    if ( SingleGun == none )
        return;

    SingleGun.MagAmmoRemaining = max(LeftGunAmmoRemaining, RightGunAmmoRemaining());
    OtherGunAmmoRemaining = MagAmmoRemaining - SingleGun.MagAmmoRemaining;
}

// sync the Dual gun state based on Single
simulated function SyncDualFromSingle()
{
    local int a;

    if ( SingleGun == none )
        return;

    a = AmmoAmount(0);
    MagAmmoRemaining = OtherGunAmmoRemaining + SingleGun.MagAmmoRemaining;
    if (MagAmmoRemaining > a) {
        MagAmmoRemaining = a;
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
        SingleGun.MagAmmoRemaining = MagAmmoRemaining - OtherGunAmmoRemaining;
    }
    // left gun ammo must be >= right gun. If not - silently swap magazines
    // Because the short reload animation assumes that the left gun is full
    LeftGunAmmoRemaining = max(OtherGunAmmoRemaining, SingleGun.MagAmmoRemaining);
    SetPistolFireOrder();
}

simulated function SetPistolFireOrder()
{
    ScrnDualFlareRevolverFire(GetFireMode(0)).SetPistolFireOrder(LeftGunAmmoRemaining > RightGunAmmoRemaining());
}

function AttachToPawn(Pawn P)
{
    super(Dualies).AttachToPawn(P);
}

function bool HandlePickupQuery( pickup Item )
{
    if ( DemoReplacement != none && Item.InventoryType == DemoReplacement ) {
        if( LastHasGunMsgTime < Level.TimeSeconds && PlayerController(Instigator.Controller) != none )
        {
            LastHasGunMsgTime = Level.TimeSeconds + 0.5;
            PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 1);
        }

        return true;
    }

    return Super.HandlePickupQuery(Item);
}

function KFWeapon DetachSingle()
{
    local KFWeapon OldGun;

    if ( SingleGun == none )
        return none;

    SingleGun.DualGuns = none;
    SingleGun.SellValue = SellValue / 2;
    SingleGun.Ammo[0].AmmoAmount /= 2;
    if ( Instigator != none && Instigator.Weapon != SingleGun ) {
        // update ammo of the single gun only if it is not currently equipped
        SingleGun.MagAmmoRemaining = RightGunAmmoRemaining();
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
    }

    SingleGun.InventoryGroup = SingleGun.default.InventoryGroup;
    SingleGun.Weight = SingleGun.default.Weight;
    Weight = default.Weight - SingleGun.Weight;

    SingleGun.UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    OldGun = SingleGun;
    SingleGun = none;
    return OldGun;
}

simulated function DetachFromPawn(Pawn P)
{
    // Triggers on the server side on weapon put down. PutDown() is client-side only.
    if ( SingleGun != none ) {
        SyncSingleFromDual();
    }
    super.DetachFromPawn(P);
}

function DropFrom(vector StartLocation)
{
    local int m;
    local KFWeaponPickup Pickup;
    local int OldAmmo;

    if( !bCanThrow )
        return;

    OldAmmo = AmmoAmount(0);
    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

    DetachSingle();
    if ( Instigator != None )
        DetachFromPawn(Instigator);


    Pickup = KFWeaponPickup(Spawn(DemoReplacement.default.PickupClass,,, StartLocation));
    if ( Pickup != None ) {
        Pickup.InitDroppedPickupFor(self);
        Pickup.DroppedBy = PlayerController(Instigator.Controller);
        Pickup.Velocity = Velocity;
        Pickup.SellValue = SellValue / 2;
        Pickup.Cost = Pickup.SellValue * 3 / 4;
        Pickup.AmmoAmount[0] = OldAmmo - AmmoAmount(0);
        Pickup.MagAmmoRemaining = OtherGunAmmoRemaining;
        if (Instigator.Health > 0)
            Pickup.bThrown = true;
    }

    Destroyed();
    Destroy();
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
    local bool bSpawnSingle;
    local KFWeaponPickup KWP;
    local int OldAmmo;
    local KFPlayerReplicationInfo KFPRI;

    // remember it once to stop calling the function on every tick
    bBotControlled = !Other.IsHumanControlled();
    KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);
    KWP = KFWeaponPickup(Pickup);
    SingleGun = ScrnFlareRevolver(Other.FindInventoryType(DemoReplacement));
    bSpawnSingle = SingleGun == none;
    if ( bSpawnSingle ) {
        SingleGun = ScrnFlareRevolver(Spawn(DemoReplacement));
        SingleGun.SellValue = 0;
    }
    SingleGun.DualGuns = self;
    SingleGun.InventoryGroup = 11;
    if ( bSpawnSingle ) {
        SingleGun.GiveTo(Other);
    }
    OldAmmo = SingleGun.AmmoAmount(0);

    SingleGun.UpdateMagCapacity(Other.PlayerReplicationInfo);
    UpdateMagCapacity(Other.PlayerReplicationInfo);

    if ( KWP != none && KWP.bDropped ) {
        // picked on the ground
        SellValue = SingleGun.SellValue + KWP.SellValue;
        OtherGunAmmoRemaining = clamp(KWP.MagAmmoRemaining, 0, MagCapacity/2 + 1);
        OldAmmo += KWP.AmmoAmount[0];
    }
    else {
        // bought at the trader
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
        OldAmmo += SingleGun.Ammo[0].InitialAmount;
    }

    Weight = default.Weight - SingleGun.Weight;

    Super(Weapon).GiveTo(Other, Pickup);

    // this workaround required to properly display weight in the trader
    Weight = default.Weight;
    SingleGun.Weight = 0;
    SingleGun.SellValue = 0;
    UpdateMagCapacity(Other.PlayerReplicationInfo);
    Ammo[0].AmmoAmount = clamp(OldAmmo, 0, MaxAmmo(0));
}

// === RELOAD ================================================================
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if( bBotControlled ) {
        return !bIsReloading && MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining;
    }

    return !( FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || ClientState == WS_BringUp
            || MagAmmoRemaining >= MagCapacity || AmmoAmount(0) <= MagAmmoRemaining
            || (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 );
}

exec function ReloadMeNow()
{
    local float ReloadMulti;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

    if(!AllowReload())
        return;

    KFPC = KFPlayerController(Instigator.Controller);
    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    if ( bHasAimingMode && bAimingRifle ) {
        FireMode[1].bIsFiring = False;
        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        ReloadMulti = KFPRI.ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPRI, self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    if ( LeftGunAmmoRemaining == default.LeftGunAmmoRemaining ) {
        // full gun loaded - reload only the left gun
        bShortReload = true;
        ReloadRate = default.ReloadShortRate / ReloadMulti;
    }
    else {
        bShortReload = false;
        ReloadRate = default.ReloadRate / ReloadMulti;
    }
    ReloadTimer = Level.TimeSeconds + ReloadRate;

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
    local KFPlayerReplicationInfo KFPRI;
    local float ReloadMulti;

    if ( bHasAimingMode && bAimingRifle ) {
        FireMode[1].bIsFiring = False;
        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if ( KFPRI != none &&KFPRI.ClientVeteranSkill != none )
        ReloadMulti = KFPRI.ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPRI, self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    bShortReload = ( LeftGunAmmoRemaining == default.LeftGunAmmoRemaining );
    PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
}

function ActuallyFinishReloading()
{
   bDoSingleReload=false;
   // no need to replicate ClientFinishReloading, it gets called on the client side by ClientReplicateAmmo
   // ClientFinishReloading();
   // bReloadEffectDone = false;
   AddReloadedAmmo();
   bIsReloading = false;
}

function AddReloadedAmmo()
{
    local PlayerController PC;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    MagAmmoRemaining = min(MagCapacity, AmmoAmount(0));
    LeftGunAmmoRemaining = (MagAmmoRemaining + 1) / 2;
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
    ClientReplicateAmmo(MagAmmoRemaining, LeftGunAmmoRemaining, a, a >> 8);
    SetPistolFireOrder();
}

simulated protected function ClientReplicateAmmo(byte SrvMagAmmoRemaining, byte SrvLeftGunAmmoRemaining,
        byte SrvAmmoAmountLow, byte SrvAmmoAmountHigh)
{
    MagAmmoRemaining = SrvMagAmmoRemaining;
    LeftGunAmmoRemaining = SrvLeftGunAmmoRemaining;
    ClientForceAmmoUpdate(0, (SrvAmmoAmountHigh << 8) | SrvAmmoAmountLow);

    if ( bIsReloading ) {
        ClientFinishReloading();
    }
    SetPistolFireOrder();
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;
    PlayIdle();

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

defaultproperties
{
    MagAmmoRemaining=12
    LeftGunAmmoRemaining=6
    ReloadShortAnim="Reload_DualFlare"
    ReloadShortRate=2.4

    FireModeClass(0)=class'ScrnDualFlareRevolverFire'
    DemoReplacement=class'ScrnFlareRevolver'
    PickupClass=class'ScrnDualFlareRevolverPickup'
    ItemName="Dual Flare revolvers SE"
}
