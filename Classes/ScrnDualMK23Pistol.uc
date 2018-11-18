class ScrnDualMK23Pistol extends DualMK23Pistol;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;
var         float           ReloadHalfShortRate;

var transient bool bShortReload;
var transient bool bHalfShortReload;
var transient bool bTweeningSlide;
var transient bool bTweenLeftSlide;
var transient bool bTweenRightSlide;
var transient bool bFrameSkipRequired; //because of mk23's tactical reload
var float TweenEndTime;

var vector PistolSlideOffset; //for tactical reload

var float ShortReloadFrameSkip; //for tactical reload
var transient int ClientMagAmmoRemaining;
var transient int FiringRound;


simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( ClientMagAmmoRemaining != MagAmmoRemaining ) {
            if ( MagAmmoRemaining > ClientMagAmmoRemaining ) {
                // mag update after reload
                ScrnDualMK23Fire(GetFireMode(0)).SetPistolFireOrder( (MagAmmoRemaining%2) == 1 );
            }
            if ( MagAmmoRemaining <= 1 ) {
                LockLeftSlideBack();
                if ( MagAmmoRemaining == 0 )
                    LockRightSlideBack();
            }
            ClientMagAmmoRemaining = MagAmmoRemaining;
        }
    }
}

simulated function Fire(float F)
{
    FiringRound = MagAmmoRemaining;
    super.Fire(f);
}

function AttachToPawn(Pawn P)
{
    super(Dualies).AttachToPawn(P); // skip code duplication in Dual44Magnum
}

function bool HandlePickupQuery( pickup Item )
{
    if ( Item.InventoryType==Class'ScrnBalanceSrv.ScrnMK23Pistol' )
    {
        if( LastHasGunMsgTime < Level.TimeSeconds && PlayerController(Instigator.Controller) != none )
        {
            LastHasGunMsgTime = Level.TimeSeconds + 0.5;
            PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 1);
        }

        return True;
    }

    return Super.HandlePickupQuery(Item);
}

function DropFrom(vector StartLocation)
{
    local int m;
    local KFWeaponPickup Pickup;
    local int AmmoThrown, OtherAmmo;
    local KFWeapon SinglePistol;

    if( !bCanThrow )
        return;

    AmmoThrown = AmmoAmount(0);
    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

    if ( Instigator != None )
        DetachFromPawn(Instigator);

    if( Instigator.Health > 0 )
    {
        OtherAmmo = AmmoThrown / 2;
        AmmoThrown -= OtherAmmo;
        SinglePistol = Spawn(Class'ScrnBalanceSrv.ScrnMK23Pistol');
        SinglePistol.SellValue = SellValue / 2;
        SinglePistol.GiveTo(Instigator);
        SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
        SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
        MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);
    }

    Pickup = Spawn(class'ScrnBalanceSrv.ScrnMK23Pickup',,, StartLocation);

    if ( Pickup != None )
    {
        Pickup.InitDroppedPickupFor(self);
        Pickup.DroppedBy = PlayerController(Instigator.Controller);
        Pickup.Velocity = Velocity;
        //fixing dropping exploit
        Pickup.SellValue = SellValue / 2;
        Pickup.Cost = Pickup.SellValue / 0.75;
        Pickup.AmmoAmount[0] = AmmoThrown;
        Pickup.MagAmmoRemaining = MagAmmoRemaining;
        if (Instigator.Health > 0)
            Pickup.bThrown = true;
        //Log("--- Pickup "$String(Pickup)$" spawned with Cost = "$Pickup.Cost);
    }

    Destroyed();
    Destroy();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (MagAmmoRemaining == 0)
        {
            LockLeftSlideBack();
            LockRightSlideBack();
        }
        if (MagAmmoRemaining == 1)
            LockLeftSlideBack();
    }
}

simulated function bool PutDown()
{
    if ( Instigator.PendingWeapon == none || Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnMK23Pistol' )
    {
        bIsReloading = false;
    }

    return super.PutDown();
}

simulated function ResetLeftSlidePosition()
{
    SetBoneLocation( 'Slide01', PistolSlideOffset, 0 ); //reset Slide position
}

simulated function ResetRightSlidePosition()
{
    SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset Slide position
}

simulated function LockLeftSlideBack()
{
    SetBoneLocation( 'Slide01', -PistolSlideOffset, 100 ); //lock slide back
}

simulated function LockRightSlideBack()
{
    SetBoneLocation( 'Slide', -PistolSlideOffset, 100 ); //lock slide back
}

simulated function InterpolateRightSlide(float time)
{
    SetBoneLocation( 'Slide', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
}

simulated function InterpolateLeftSlide(float time)
{
    SetBoneLocation( 'Slide01', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
}


simulated function HandleSlideMovement()
{
    if (TweenEndTime - Level.TimeSeconds > 0)
    {
        if (bTweenRightSlide)
            InterpolateRightSlide(TweenEndTime - Level.TimeSeconds);
        if (bTweenLeftSlide)
            InterpolateLeftSlide(TweenEndTime - Level.TimeSeconds);
    }
    if (TweenEndTime - Level.TimeSeconds < 0)
    {
        ResetLeftSlidePosition();
        ResetRightSlidePosition();
        TweenEndTime = 0;
        bTweeningSlide = false;
        bTweenLeftSlide = false;
        bTweenRightSlide = false;
    }
}

simulated function HandleFrameSkip()
 {
    if (Level.TimeSeconds - ReloadTimer >= ReloadRate*0.648)
    {
        //DoFrameSkip(); //do animation frame skip
        bFrameSkipRequired = false;
    }
}

simulated function WeaponTick(float dt)
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if ( bTweeningSlide && TweenEndTime > 0 )
        {
            HandleSlideMovement();
        }
        /*
        if (bIsReloading && bFrameSkipRequired)
        {
            HandleFrameSkip();
        }
        */
    }
    Super.WeaponTick(dt);
}

//added this to replace old reloadtimer mult check
simulated function Timer()
{
    if (bIsReloading)
        DoFrameSkip(); //skip to mag change frame
    //else
    //PlayIdle();
    Super.Timer();
}

//skip from ~frame 50 to 75
simulated function DoFrameSkip()
{
    SetAnimFrame(75, , 1);
    //left pistol slide gets released after this skip so reset left slide's position
    SetBoneLocation( 'Slide01', PistolSlideOffset, 0); //reset left slide position
}


simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start Slide tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

//after reload tween slide back if tactical reload
simulated function ClientFinishReloading()
{
    if( bShortReload || bHalfShortReload )
    {
        StartTweeningSlide(); //start tweening Slide back
    }
    Super.ClientFinishReloading();
}

//added slide offset to reload animation
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
        bHalfShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset Slide so that the animation's Slide position gets used
        SetBoneLocation( 'Slide01', PistolSlideOffset, 0 ); //reset Slide so that the animation's Slide position gets used
    }
    else if (MagAmmoRemaining == 1)
    {
        bShortReload = false;
        bHalfShortReload = true;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move right slide forward
        SetBoneLocation( 'Slide01', PistolSlideOffset, 0 ); //reset left slide so that the animation's slide position gets used
        bTweenRightSlide = true;
    }
    else if (MagAmmoRemaining >= 2)
    {
        bShortReload = true;
        bHalfShortReload = false;
        bFrameSkipRequired = true;
        bTweenRightSlide = true; //this is needed
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move slide forward
        SetBoneLocation( 'Slide01', PistolSlideOffset, 100 ); //move slide forward
        SetTimer(1.667/ReloadMulti, false); //timer skips from frame 50 to 75

    }
}

function AddReloadedAmmo()
{
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    if ( bShortReload )
        a+=2; // 2 bullets already bolted
    if ( bHalfShortReload )
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

    if ( MagAmmoRemaining >= 2 )
        ReloadRate = default.ReloadShortRate / ReloadMulti;
    else if (MagAmmoRemaining == 1)
        ReloadRate = default.ReloadHalfShortRate / ReloadMulti;
    else if (MagAmmoRemaining <= 0)
        ReloadRate = default.ReloadRate / ReloadMulti;

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


defaultproperties
{
     MagAmmoRemaining=24
     ClientMagAmmoRemaining=24
     ReloadShortRate = 2.57 //no slides locked back
     ReloadHalfShortRate = 3.35 //left slide locked back
     PistolSlideOffset=(X=0,Y=-0.0235000,Z=0.0)
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualMK23Fire'
     DemoReplacement=Class'ScrnBalanceSrv.ScrnMK23Pistol'
     PickupClass=Class'ScrnBalanceSrv.ScrnDualMK23Pickup'
     ItemName="Dual MK23 SE"
     ShortReloadFrameSkip=75
}
