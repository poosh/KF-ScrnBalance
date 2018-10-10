class ScrnMK23Pistol extends MK23Pistol;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload

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
        if ( MagAmmoRemaining == 0 ) {
            LockSlideBack();
        }
    }
}

simulated function bool PutDown()
{
    if ( Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnDualMK23Pistol' )
    {
        bIsReloading = false;
    }

    return super(KFWeapon).PutDown();
}

simulated function LockSlideBack()
{
    SetBoneLocation( 'Slide', -PistolSlideOffset, 100 ); //lock slide back
}

//only called by clients
simulated function HandleSlideMovement()
{
    if ( TweenEndTime > 0 )
    {
        if (TweenEndTime - Level.TimeSeconds > 0)
            SetBoneLocation( 'Slide', PistolSlideOffset, (TweenEndTime - Level.TimeSeconds)*500 ); //
        if (TweenEndTime - Level.TimeSeconds < 0)
        {
            SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset slide position
            TweenEndTime = 0;
            bTweeningSlide = false;
        }
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
        StartTweeningSlide(); //start tweening slide back
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
        SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset slide so that the animation's slide position gets used
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent slide from sliding
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move the slide forward
    }
}

//called by clientfinishreloading
simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start slide tweening
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

function GiveTo( pawn Other, optional Pickup Pickup )
{
    local KFPlayerReplicationInfo KFPRI;
    local KFWeaponPickup WeapPickup;

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
     ReloadShortRate=1.83
     ReloadShortAnim="Reload"
     PistolSlideOffset=(X=0,Y=-0.0275000,Z=0.0)
     Weight=3.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnMK23Fire'
     Description="Match grade 45 caliber pistol. Good balance between power, ammo count and rate of fire. Damage is near to Magnum's, but has no bullet penetration."
     PickupClass=Class'ScrnBalanceSrv.ScrnMK23Pickup'
     ItemName="MK23 SE"
}
