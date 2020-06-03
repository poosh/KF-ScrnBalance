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
        ClientReloadSync;
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

//allow reload single shell
simulated function bool AllowReload()
{
    return super(KFWeapon).AllowReload();
}

// ReloadMeNow is executed only on the server side.
function ReloadMeNow()
{
    if ( !AllowReload() )
        return;

    if ( bHasAimingMode && bAimingRifle ) {
        ZoomOut(false);
    }

    ClientReloadSync(MagAmmoRemaining);
    Instigator.SetAnimAction(WeaponReloadAnim);

    GotoState('ManualReload');
}

simulated function ClientReload() {}

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

function ServerRequestAutoReload()
{
    ReloadMeNow();
    NumClicks++;
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
    super(KFWeapon).GiveAmmo(m,WP,bJustSpawned);
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    super(KFWeapon).GiveTo( Other, Pickup );
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
    bDoSingleReload = false;
    bIsReloading = false;
    bReloadEffectDone = false;
    GotoState('');
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
}

simulated state ReloadPhase1 extends Reloading
{
    ignores AnimEnd, PlayIdle;

    simulated function BeginState()
    {
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
        if ( Role == ROLE_Authority ) {
            ReloadRate -= 0.2; // finish faster on server to preveng glitches on the client
        }
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
        bDoSingleReload = false;
        bIsReloading = false;
        bReloadEffectDone = false;
    }

    simulated function WeaponTick(float dt)
    {
        global.WeaponTick(dt);
        if ( Level.TimeSeconds > NextReloadPhase) {
            ActuallyFinishReloading();
            GotoState('');
        }
    }

    simulated function bool InterruptReload()
    {
        ServerInterruptReload();
        GotoState('');
        return true;
    }
}

// simulated function dbg(optional string msg)
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

    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBoomStickSingleFire'
    FireModeClass(1)=Class'ScrnBalanceSrv.ScrnBoomStickDualFire'
    Description="This is my BOOMstick (c) Ash, Evil Dead - Army of Darkness, 1992.|Has been used through the centuries to hunt down Demons, Aliens and Zombies. Now it's time for the ZEDs.|Can shoot from one or two barrels simultaneousely. Single shell reload is avaliable."
    PickupClass=Class'ScrnBalanceSrv.ScrnBoomStickPickup'
    ItemName="Ash's Boomstick"
    //Priority=220 // 160 - switch before aa12
    NewAnimRef="ScrnAnims.boomstick_anim_new"
    OldAnimRef="KF_Weapons_Trip.boomstick_anim"
}
