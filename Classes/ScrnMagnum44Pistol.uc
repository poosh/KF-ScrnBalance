class ScrnMagnum44Pistol extends Magnum44Pistol;

var transient ScrnDual44Magnum DualGuns;

var transient bool bBotControlled;


replication
{
    reliable if ( Role == ROLE_Authority )
        ClientReplicateAmmo;
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

simulated function WeaponTick(float dt)
{
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

     if ( Level.NetMode == NM_Client || Instigator == None  )
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

simulated function UpdateMagCapacity(PlayerReplicationInfo PRI)
{
    local KFPlayerReplicationInfo KFPRI;

    MagCapacity = default.MagCapacity;
    KFPRI = KFPlayerReplicationInfo(PRI);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        MagCapacity *= KFPRI.ClientVeteranSkill.Static.GetMagCapacityMod(KFPRI, self);
    }
    NextAmmoCheckTime = 0;   // check on the next call
}

simulated function float GetAmmoMulti()
{
    local KFPlayerReplicationInfo KFPRI;

    if ( NextAmmoCheckTime > Level.TimeSeconds )
        return LastAmmoResult;

    NextAmmoCheckTime = Level.TimeSeconds + 1;

    if ( DualGuns != none ) {
        LastAmmoResult = 2.0;
    }
    else {
        LastAmmoResult = 1.0;
    }

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

simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if( !Other.IsHumanControlled() ) {
        return !bIsReloading && MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining;
    }

    return !( FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || ClientState == WS_BringUp
            || MagAmmoRemaining >= MagCapacity || AmmoAmount(0) <= MagAmmoRemaining
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
    PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
}

function ActuallyFinishReloading()
{
   bDoSingleReload=false;
   // no need to replicate ClientFinishReloading, it gets called on the client side by ClientReplicateAmmo
   // ClientFinishReloading();
   bIsReloading = false;
   // bReloadEffectDone = false;
   AddReloadedAmmo();
}

function AddReloadedAmmo()
{
    local PlayerController PC;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    MagAmmoRemaining = min(MagCapacity, AmmoAmount(0));
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
    MagAmmoRemaining = SrvAmmo & 0xFF;
    ClientForceAmmoUpdate(0, (SrvAmmo >> 8));

    if ( bIsReloading ) {
        ClientFinishReloading();
    }
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;
    PlayIdle();

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
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
    if ( DualGuns != none ) {
        DualGuns.Velocity = Velocity;
        DualGuns.DropFrom(StartLocation);
    }
    else {
        super.DropFrom(StartLocation);
    }
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    local KFPlayerReplicationInfo KFPRI;
    local KFWeaponPickup WeapPickup;

    // remember it once to stop calling the function on every tick
    bBotControlled = !Other.IsHumanControlled();
    KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);
    WeapPickup = KFWeaponPickup(Pickup);

    //pick the lowest sell value
    if ( WeapPickup != None && KFPRI != None && KFPRI.ClientVeteranSkill != none ) {
        SellValue = 0.75 * min(WeapPickup.Cost, WeapPickup.default.Cost
            * KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, WeapPickup.class));
    }

    Super.GiveTo(Other,Pickup);
}


defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnMagnum44Fire'
     PickupClass=Class'ScrnBalanceSrv.ScrnMagnum44Pickup'
     ItemName="44 Magnum SE"
     Weight=2
     Priority=70
}
