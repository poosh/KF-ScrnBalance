class ScrnSingle extends Single;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload

var bool bAnimatingHammer;
var rotator PistolHammerRotation; //for 9mm's stupid hammer
var transient float HammerRotateRate;
var transient float HammerRotateBackTime;
var transient float HammerRotateForwardTime;
var transient float HammerRotateMult;

var float DefaultHammerRotateMult;
var float DefaultHammerRotateRate;

var bool bFiringLastRound;

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( MagAmmoRemaining == 0 && !bIsReloading ) {
            LockSlideBack();
        }
    }
}

simulated function Fire(float F)
{
    bFiringLastRound = MagAmmoRemaining == 1;
    super.Fire(f);
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (Level.NetMode != NM_DedicatedServer)
    {
        SetBoneRotation( '9mm_hammer', -1*PistolHammerRotation, , 100); //rotate hammer to cocked position
        if (MagAmmoRemaining == 0)
            LockSlideBack(); //lock Slide back
    }
}

simulated function bool PutDown()
{
    if (  Instigator.PendingWeapon != none && Instigator.PendingWeapon.class == class'ScrnDualies' )
    {
        bIsReloading = false;
    }

    return super.PutDown();
}

function bool HandlePickupQuery( pickup Item )
{
    if ( Item.InventoryType == Class )
    {
        if ( KFPlayerController(Instigator.Controller) != none )
        {
            KFPlayerController(Instigator.Controller).PendingAmmo = WeaponPickup(Item).AmmoAmount[0];
        }

        return false; // Allow to "pickup" so this weapon can be replaced with dual deagle.
    }

    return Super.HandlePickupQuery(Item);
}

simulated function LockSlideBack()
{
    SetBoneLocation( '9mm_Slide', -PistolSlideOffset, 100 ); //lock Slide back
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( '9mm_hammer', -DefaultHammerRotateMult*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( '9mm_hammer', 0.5*DefaultHammerRotateMult*PistolHammerRotation, , 100 - Rate*RateMult*2 ); //needs to move from 0 to 45
}

//this function sets the times for hammer drop, and is called by ScrnSingleFire
simulated function DoHammerDrop(float FireRateMod)
{
    bAnimatingHammer = True;
    HammerRotateRate = DefaultHammerRotateRate/FireRateMod; //0.08
    HammerRotateForwardTime = Level.TimeSeconds + HammerRotateRate; //set time
    HammerRotateBackTime = Level.TimeSeconds + 4*HammerRotateRate; //set time (3 times longer than)
}

//only called by clients
simulated function HandleSlideMovement()
{
    if ( bTweeningSlide && TweenEndTime > 0 )
    {
        if (TweenEndTime - Level.TimeSeconds > 0)
            SetBoneLocation( '9mm_Slide', PistolSlideOffset, (TweenEndTime - Level.TimeSeconds)*500 ); //
        if (TweenEndTime - Level.TimeSeconds < 0)
        {
            SetBoneLocation( '9mm_Slide', PistolSlideOffset, 0 ); //reset slide position
            TweenEndTime = 0;
            bTweeningSlide = false;
        }
    }
}

//only called by clients
simulated function HandleHammerRotation()
{
    if (Level.TimeSeconds < HammerRotateForwardTime && Level.TimeSeconds < HammerRotateBackTime )
        RotateHammerSmooth(HammerRotateForwardTime - Level.TimeSeconds, false); //rotate hammer forwards
    if (Level.TimeSeconds > HammerRotateForwardTime )
        RotateHammerSmooth(HammerRotateBackTime - Level.TimeSeconds, true); //rotate hammer backwards
    if (Level.TimeSeconds > HammerRotateBackTime )
    {
        bAnimatingHammer = false; //finished rotating hammer
        SetBoneRotation( '9mm_hammer', -1*PistolHammerRotation, , 100); //rotate hammer to cocked position
    }
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
        if (bAnimatingHammer)
        {
            HandleHammerRotation();
        }
    }
    Super.WeaponTick(dt);
}

//allowing +1 reload with full mag
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if(KFInvasionBot(Instigator.Controller) != none && !bIsReloading &&
        MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining)
        return true;

    if(KFFriendlyAI(Instigator.Controller) != none && !bIsReloading &&
        MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining)
        return true;


    if(FireMode[0].IsFiring() || FireMode[1].IsFiring() ||
           bIsReloading || MagAmmoRemaining > MagCapacity ||
           ClientState == WS_BringUp ||
           AmmoAmount(0) <= MagAmmoRemaining ||
                   (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 )
        return false;
    return true;
}

simulated function ClientFinishReloading()
{
    PlayIdle();
    if(bShortReload)
        StartTweeningSlide(); //start tweening Slide back
    bIsReloading = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

exec function ReloadMeNow()
{
    local float ReloadMulti;

    if(!AllowReload())
        return;
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
    ReloadTimer = Level.TimeSeconds;
    bShortReload = MagAmmoRemaining > 0;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;

    if( bHoldToReload )
    {
        NumLoadedThisReload = 0;
    }
    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);
    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPlayerController(Instigator.Controller) != none &&
        Level.TimeSeconds - KFPlayerController(Instigator.Controller).LastReloadMessageTime > KFPlayerController(Instigator.Controller).ReloadMessageDelay )
    {
        KFPlayerController(Instigator.Controller).Speech('AUTO', 2, "");
        KFPlayerController(Instigator.Controller).LastReloadMessageTime = Level.TimeSeconds;
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
        SetBoneLocation( '9mm_Slide', PistolSlideOffset, 0 ); //reset Slide so that the animation's Slide position gets used
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent Slide from sliding
        SetBoneLocation( '9mm_Slide', PistolSlideOffset, 100 ); //move the Slide forward
    }
}

//called by clientfinishreloading()
simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start Slide tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

function AddReloadedAmmo()
{
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    //StartTweeningSlide(); //putting this here fixed tactical reload but broke empty
    if ( bShortReload )
    {
        //StartTweeningSlide(); //trying this again
        a++; // 1 bullet already bolted
    }
    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    // this seems redudant -- PooSH
    // if( !bHoldToReload )
    // {
        // ClientForceKFAmmoUpdate(MagAmmoRemaining,AmmoAmount(0));
    // }

    if ( PlayerController(Instigator.Controller) != none && KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements) != none )
    {
        KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements).OnWeaponReloaded();
    }
}

defaultproperties
{
    ReloadShortRate=1.4
    ReloadShortAnim="Reload"
    PistolSlideOffset=(X=0.02330,Y=0.0,Z=0.0)
    PistolHammerRotation=(Pitch=145,Yaw=0,Roll=0) //tripwire why did you do this
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSingleFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnSinglePickup'
    ItemName="9mm Tactical SE"
    Priority=4
    bKFNeverThrow=False
    Weight=0
    DefaultHammerRotateRate = 0.02
    DefaultHammerRotateMult = 1.0
}
