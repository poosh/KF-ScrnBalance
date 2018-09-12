class ScrnSingle extends Single;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var bool bSlideLocked;
var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload
var vector PistolSlideLockedOffset; //for tactical reload


simulated function BringUp(optional Weapon PrevWeapon)
{
	Super.BringUp(PrevWeapon);
    if (MagAmmoRemaining == 0 || bSlideLocked)
        LockSlideBack();
}

simulated function ResetSlidePosition()
{
    SetBoneLocation( '9mm_Slide', PistolSlideOffset, 0 ); //reset Slide position
}

simulated function LockSlideBack()
{
    SetBoneLocation( '9mm_Slide', -PistolSlideOffset, 100 ); //lock Slide back
    bSlideLocked = true; //set this bool so weapon Slide will stay locked if dropped
}

simulated function InterpolateSlide(float time)
{
    SetBoneLocation( '9mm_Slide', PistolSlideOffset, (time*500) ); //
}

simulated function WeaponTick(float dt)
{
    if (bTweeningSlide && TweenEndTime > 0)
    {
        if (TweenEndTime - Level.TimeSeconds > 0)
            InterpolateSlide(TweenEndTime - Level.TimeSeconds);
        if (TweenEndTime - Level.TimeSeconds < 0)
        {
            ResetSlidePosition();
            TweenEndTime = 0;
            bTweeningSlide = false;
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
    bSlideLocked = false; //reset bool
    if (MagAmmoRemaining <= 0)
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( '9mm_Slide', PistolSlideOffset, 0 ); //reset Slide so that the animation's Slide position gets used
    }
    else if (MagAmmoRemaining >= 1)
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent Slide from sliding
        SetBoneLocation( '9mm_Slide', PistolSlideOffset, 100 ); //move the Slide forward
    }
}

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
    if ( bShortReload )
        a++; // 1 bullet already bolted

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

defaultproperties
{
    ReloadShortRate=1.4
    ReloadShortAnim="Reload"
    PistolSlideOffset=(X=0.02330,Y=0.0,Z=0.0)
    PistolSlideLockedOffset=(X=-0.02330,Y=0,Z=0) //locked pistol Slide position
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSingleFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnSinglePickup'
    ItemName="9mm Tactical SE"
    Priority=4
    bKFNeverThrow=False
    Weight=0
}
