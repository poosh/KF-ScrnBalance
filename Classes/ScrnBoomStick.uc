class ScrnBoomStick extends BoomStick;

var string NewAnimRef;
var string OldAnimRef;
var MeshAnimation NewAnim;
var float SingleReloadRate;  // animation duration in seconds
var float SingleReloadAnimRate; //animation playrate modifier for reload_half
var name SingleReloadAnim;

var float ReloadPhaseTimes[3];
var float SingleReloadPhaseTimes[3];
var transient bool bSingleReload;
var transient float NextReloadPhase;


replication
{
    reliable if ( Role == ROLE_Authority )
        ClientReloadSync, ClientFinishReloadingSync;
}


static function PreloadAssets(Inventory Inv, optional bool bSkipRefCount)
{
    local ScrnBoomStick spawned;

    super.PreloadAssets(Inv, bSkipRefCount);

    if (default.NewAnimRef == "")
        return;

    default.NewAnim = MeshAnimation(DynamicLoadObject(default.NewAnimRef, class'MeshAnimation', true));

    spawned = ScrnBoomStick(Inv);
    if( spawned != none ) {
        spawned.NewAnim = default.NewAnim;
        spawned.AddNewAnim();
    }
}

static function bool UnloadAssets()
{
    default.NewAnim = none;
    return super.UnloadAssets();
}

//new anim in PostBeginPlay because adding it in PreloadAssets didn't work
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    AddNewAnim();
}

simulated function AddNewAnim()
{
    if (NewAnim == none || NewAnimRef == "")
        return;

    LinkSkelAnim(NewAnim); //load new anim
    //for some reason linking the new anim removed the link to the old one, so we need to load it again
    LinkSkelAnim(MeshAnimation(DynamicLoadObject(OldAnimRef, class'MeshAnimation', true)));
}

// C&P from KFWeapon to cut out all reloading crap
simulated function WeaponTick(float dt)
{
    if( bHasAimingMode ) {
        if( ForceZoomOutTime > 0 ) {
            if( bAimingRifle ) {
                if( Level.TimeSeconds > ForceZoomOutTime ) {
                    ForceZoomOutTime = 0;
                    bForceLeaveIronsights = true;
                }
            }
            else {
                ForceZoomOutTime = 0;
            }
        }
        if( bForceLeaveIronsights ) {
            if( bAimingRifle ) {
                ZoomOut(true);
                if( Role < ROLE_Authority)
                    ServerZoomOut(false);
            }
            bForceLeaveIronsights = false;
        }
    }
}

function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    super(KFWeapon).GiveAmmo(m, WP, bJustSpawned);
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    super(KFWeapon).GiveTo(Other, Pickup);
}

simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
    if( super(Weapon).ConsumeAmmo(0, Load, bAmountNeededIsMax) ) {
        MagAmmoRemaining -= Load;
        if ( MagAmmoRemaining < 0 ) {
            warn("Boomstick MagAmmoRemaining="$MagAmmoRemaining);
            MagAmmoRemaining = 0;
        }

        NetUpdateTime = Level.TimeSeconds - 1;
        return true;
    }
    return false;
}

function AmmoPickedUp() { }

simulated function Fire(float F)
{
    ScrnBoomStickSingleFire(FireMode[0]).bLastBulletInMag = (MagAmmoRemaining == 1);
    if( MagAmmoRemaining < 1 && !bIsReloading && FireMode[0].NextFireTime <= Level.TimeSeconds ) {
        ServerRequestAutoReload();
        PlayOwnedSound(FireMode[0].NoAmmoSound,SLOT_None,2.0,,,,false);
    }
    super(Weapon).Fire(F);
}

simulated function AltFire(float F)
{
    ScrnBoomStickDualFire(FireMode[1]).bLastBulletInMag = (MagAmmoRemaining == 1);
    if( MagAmmoRemaining < 1 && !bIsReloading && FireMode[0].NextFireTime <= Level.TimeSeconds ) {
        ServerRequestAutoReload();
        PlayOwnedSound(FireMode[0].NoAmmoSound,SLOT_None,2.0,,,,false);
    }
    super(Weapon).AltFire(F);
}

simulated event ClientStartFire(int Mode)
{
    // bypass vanilla Boomstick's bull crap. ScrN Boomstick can handle 1 bullet in dual fire.
    super(KFWeapon).ClientStartFire(Mode);
}

simulated event ClientStopFire(int Mode)
{
    super(KFWeapon).ClientStopFire(Mode);
}

simulated function bool StartFire(int Mode)
{
    return super(KFWeapon).StartFire(Mode);
}

//allow reload single shell
simulated function bool AllowReload()
{
    if ( bIsReloading || MagAmmoRemaining >= MagCapacity || AmmoAmount(0) <= MagAmmoRemaining )
        return false;

    if( AIController(Instigator.Controller) != none )
        return true;

    return true;
    // return !FireMode[0].IsFiring() && !FireMode[1].IsFiring();
}

// ReloadMeNow is executed only on the server side.
function ReloadMeNow()
{
    if ( !AllowReload() ) {
        //dmsg("Reload Rejected");
        return;
    }
    //dmsg("ReloadMeNow");

    if ( bHasAimingMode && bAimingRifle ) {
        ZoomOut(false);
    }

    ClientReloadSync(MagAmmoRemaining);
    Instigator.SetAnimAction(WeaponReloadAnim);

    GotoState('ManualReload');
}

simulated function ClientReload() {
    warn("ScrnBoomstick.ClientReload() called!");
}

simulated function ClientReloadSync(byte SrvMagAmmoRemaining)
{
    if ( bHasAimingMode && bAimingRifle ) {
        ZoomOut(false);
    }

    MagAmmoRemaining = SrvMagAmmoRemaining;
    bSingleReload = MagAmmoRemaining == 1;

    if ( bSingleReload ) {
        PlayAnim(SingleReloadAnim, SingleReloadAnimRate, 0.0);
    }
    else {
        PlayAnim(ReloadAnim, ReloadAnimRate, 0.0);
        SetAnimFrame(ReloadPhaseTimes[0], 0 , 0); //skip fire animation and jump to reload
    }

    GotoState('ManualReload');
}

simulated function ClientFinishReloadingSync(byte SrvMagAmmoRemaining)
{
    //dmsg("ClientFinishReloading");
    MagAmmoRemaining = SrvMagAmmoRemaining;
    bIsReloading = false; // should be false already. Just in case.
}

function ServerRequestAutoReload()
{
    ReloadMeNow();
    NumClicks++;
}

simulated function SetPendingReload() { }

simulated function AnimEnd(int channel)
{
    if ( ClientState == WS_ReadyToFire && !bIsReloading && !FireMode[0].bIsFiring && !FireMode[1].bIsFiring ) {
        PlayIdle();
    }
}

simulated function PlayIdle()
{
    if ( ClientState == WS_BringUp && MagAmmoRemaining == 0 && !bIsReloading )
        GotoState('PendingReload', 'Begin');
    else {
        super.PlayIdle();
    }
}

// XXX: wtf a server function is simulated?
function ServerInterruptReload()
{
    //dmsg("ServerInterruptReload");
    GotoState('');
    bDoSingleReload = false;
    bIsReloading = false;
    bReloadEffectDone = false;
    ClientFinishReloadingSync(MagAmmoRemaining);  // make sure the client has the correct MagAmmoRemaining value
}

simulated function bool InterruptReload()
{
    return false;
}

simulated state PendingReload
{
    ignores PlayIdle;

    simulated function EndState()
    {
        ReloadMeNow();
    }

    simulated function AnimEnd(int channel)
    {
        GotoState('');
    }

Begin:
    // wait for current animation to finish before starting to reload
    sleep(1.0);
    GotoState('');
}

// Base state of reloading. Don't switch to this state directly. Use child states.
simulated state Reloading
{
    ignores ToggleIronSights, IronSightZoomIn;

    simulated function bool AllowReload()
    {
        return false;
    }

    simulated function bool StartFire(int Mode)
    {
        return false;
    }

    simulated function ClientFinishReloadingSync(byte SrvMagAmmoRemaining)
    {
        //dmsg("ClientFinishReloading");
        GotoState('');
        MagAmmoRemaining = SrvMagAmmoRemaining;
        bIsReloading = false;
        if ( ClientGrenadeState == GN_None )
            PlayIdle();
        if ( Instigator.PendingWeapon != none && Instigator.PendingWeapon != self )
            Instigator.Controller.ClientSwitchToBestWeapon();
    }
}

simulated state ReloadPhase1 extends Reloading
{
    ignores AnimEnd, PlayIdle;

    simulated function BeginState()
    {
        //dmsg("Reload Started");
        bIsReloading = true;
        bSingleReload = false;
        ReloadTimer = Level.TimeSeconds;
        ReloadRate = default.ReloadRate;
    }

    simulated function WeaponTick(float dt)
    {
        global.WeaponTick(dt);
        if ( Level.TimeSeconds > NextReloadPhase)
            GotoState('ReloadPhase2');
    }

    simulated function bool InterruptReload()
    {
        //dmsg("InterruptReload");
        // single reload phase one takes only half a second. Player can wait.
        // Otherwise, we would risk of getting out-of-sync with the server.
        if ( bSingleReload )
            return false;

        ServerInterruptReload();
        bIsReloading = false;
        GotoState('');
        return true;
    }
}

simulated state FireAndReload extends ReloadPhase1
{
    simulated function BeginState()
    {
        super.BeginState();
        NextReloadPhase = ReloadTimer + ReloadPhaseTimes[0] + ReloadPhaseTimes[1];
    }
}

simulated state ManualReload extends ReloadPhase1
{
    simulated function BeginState()
    {
        super.BeginState();

        bSingleReload = MagAmmoRemaining == 1;
        if ( bSingleReload ) {
            NextReloadPhase = ReloadTimer + SingleReloadPhaseTimes[1];
        }
        else {
            // skip the fire part
            ReloadRate -= ReloadPhaseTimes[0];
            NextReloadPhase = ReloadTimer + ReloadPhaseTimes[1];
        }
    }
}

simulated state ReloadPhase2 extends Reloading
{
    ignores AnimEnd, PlayIdle;

    simulated function BeginState()
    {
        if ( bSingleReload ) {
            NextReloadPhase = ReloadTimer + SingleReloadPhaseTimes[2];
        }
        else {
            NextReloadPhase = ReloadTimer + ReloadPhaseTimes[2];
        }
    }

    simulated function WeaponTick(float dt)
    {
        global.WeaponTick(dt);
        if ( Level.TimeSeconds > NextReloadPhase) {
            if ( Role == ROLE_Authority ) {
                MagAmmoRemaining = min(MagCapacity, AmmoAmount(0));
                NetUpdateTime = Level.TimeSeconds - 1;
            }
            GotoState('ReloadPhase3');
        }
    }

    simulated function bool PutDown()
    {
        return false;  // cannot interrupt reload at this phase
    }

    simulated function bool InterruptReload()
    {
        //dmsg("InterruptReload");
        return false;
    }
}

simulated state ReloadPhase3 extends Reloading
{
    simulated function BeginState()
    {
        if ( bSingleReload ) {
            NextReloadPhase = ReloadTimer + SingleReloadRate;
        }
        else {
            NextReloadPhase = ReloadTimer + ReloadRate;
        }

        if ( Instigator.PendingWeapon != none && Instigator.PendingWeapon != self )
            Instigator.Controller.ClientSwitchToBestWeapon();
    }

    simulated function EndState()
    {
        //dmsg("Reload Ended");

        bDoSingleReload = false;
        bIsReloading = false;
        bReloadEffectDone = false;
        ClientFinishReloadingSync(MagAmmoRemaining);
    }

    simulated function WeaponTick(float dt)
    {
        global.WeaponTick(dt);
        if ( Role == ROLE_Authority ) {
            if ( Level.TimeSeconds > NextReloadPhase) {
                GotoState('');
            }
        }
        // else wait for ClientFinishReloadingSync()
    }

    simulated function bool InterruptReload()
    {
        //dmsg("InterruptReload");
        ServerInterruptReload();
        bIsReloading = false;
        GotoState('');
        return true;
    }
}

// simulated function dmsg(optional string msg)
// {
//     local string s;
//
//     if ( Level.NetMode == NM_Client )
//         s = "(client) ";
//     else if ( !Instigator.IsLocallyControlled() )
//         s = "(server) ";
//     s $= GetStateName() $ ": " $ msg;
//     PlayerController(Instigator.Controller).ClientMessage(s, 'Log');
// }

defaultproperties
{
    MagCapacity=2
    bHoldToReload=true  // doesn't mean what it says. Set to allow stuff like interrupt reload etc.

    // Instigator anim
    WeaponReloadAnim="Reload_HuntingShotgun"

    ReloadAnim="Fire_Last"
    ReloadPhaseTimes(0)=0.217500            // fire
    ReloadPhaseTimes(1)=1.000               // start inserting shells
    ReloadPhaseTimes(2)=2.340               // shells inserted
    ReloadRate=2.75
    ReloadAnimRate=1.0

    SingleReloadAnim="reload_half"
    SingleReloadPhaseTimes(0)=0             // fire
    SingleReloadPhaseTimes(1)=0.5210        // start inserting a shell
    SingleReloadPhaseTimes(2)=1.0000        // the shell is inserted
    SingleReloadRate=1.4375
    SingleReloadAnimRate=1.6

    FireModeClass(0)=class'ScrnBoomStickSingleFire'
    FireModeClass(1)=class'ScrnBoomStickDualFire'
    Description="This is my BOOMstick (c) Ash, Evil Dead - Army of Darkness, 1992.|Has been used through the centuries to hunt down Demons, Aliens and Zombies. Now it's time for the ZEDs.|Can shoot from one or two barrels simultaneousely. Single shell reload is avaliable."
    PickupClass=class'ScrnBoomStickPickup'
    ItemName="Ash's Boomstick"
    //Priority=220 // 160 - switch before aa12
    NewAnimRef="ScrnAnims.boomstick_anim_new"
    OldAnimRef="KF_Weapons_Trip.boomstick_anim"
}
