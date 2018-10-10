class ScrnDualDeagle extends DualDeagle;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;
var         float           ReloadHalfShortRate;

var transient bool bShortReload;
var transient bool bHalfShortReload;
var transient bool bTweeningSlide;
var transient bool bTweenLeftSlide;
var transient bool bTweenRightSlide;

var transient bool bAnimatingLeftHammer;
var transient bool bAnimatingRightHammer;
var float LeftHammerRotateForwardTime;
var float RightHammerRotateForwardTime;
var float LeftHammerRotateBackTime;
var float RightHammerRotateBackTime;

var float DefaultSlideMoveMult;

var transient bool bEnhancedRightSlideMovement; //adding extra slide movement to fire animation
var transient float SlideMoveRate; //stores total amount of time each slide movement is (in cases where fire animation is sped up)
var transient float RightSlideMoveBackTime;
var transient float RightSlideMoveForwardTime;

var transient bool bEnhancedLeftSlideMovement; //adding extra slide movement to fire animation
var transient float LeftSlideMoveBackTime;
var transient float LeftSlideMoveForwardTime;

//used for returning slide
var bool bRightSlideReturned;
var float DefaultRightSlideReturnStartMult; //multiplier for reload timer to start slide return
var float DefaultRightSlideReturnEndMult; //multiplier for reload timer to start slide return
var float RightSlideReturnStartTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float RightSlideReturnEndTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float RightSlideReturnDuration; //amount of time in seconds the slide returns for
//used for returning slide
var bool bLeftSlideReturned;
var float DefaultLeftSlideReturnStartMult; //multiplier for reload timer to start slide return
var float DefaultLeftSlideReturnEndMult; //multiplier for reload timer to start slide return
var float LeftSlideReturnStartTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float LeftSlideReturnEndTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float LeftSlideReturnDuration; //amount of time in seconds the slide returns for

var transient float HammerRotateMult;
var transient float HammerRotateRate;

var float DefaultHammerRotateMult;
var float DefaultHammerRotateRate;

var float TweenEndTime;

var vector PistolSlideOffset; //for tactical reload
var rotator PistolHammerRotation;

var transient int ClientMagAmmoRemaining;
var transient int FiringRound;


simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( ClientMagAmmoRemaining != MagAmmoRemaining ) {
            if ( MagAmmoRemaining > ClientMagAmmoRemaining ) {
                // mag update after reload
                ScrnDualDeagleFire(GetFireMode(0)).SetPistolFireOrder( (MagAmmoRemaining%2) == 1 );
            }
            if ( MagAmmoRemaining <= 1 ) {
                LockRightSlideBack();
                if ( MagAmmoRemaining == 0 )
                    LockLeftSlideBack();
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

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (Level.NetMode != NM_DedicatedServer)
    {
        RotateHammersBack(); //always do this now
        if (MagAmmoRemaining == 0)
        {
            LockLeftSlideBack();
            LockRightSlideBack();
        }
        if (MagAmmoRemaining == 1)
            LockRightSlideBack();
    }
}

simulated function bool PutDown()
{
    if ( Instigator.PendingWeapon.class == DemoReplacement )
    {
        bIsReloading = false;
    }

    return super.PutDown();
}

simulated function RotateHammersBack()
{
    SetBoneRotation( 'Hammer', -1*PistolHammerRotation, , 100); //set hammer rotation for empty reload
    SetBoneRotation( 'Hammer01', -1*PistolHammerRotation, , 100); //set hammer rotation for empty reload
}

//this function sets the times for left hammer drop
simulated function DoLeftHammerDrop(float FireRateMod)
{
    bAnimatingLeftHammer = True;
    HammerRotateRate = DefaultHammerRotateRate/FireRateMod; //0.08
    LeftHammerRotateForwardTime = Level.TimeSeconds + HammerRotateRate; //set time
    LeftHammerRotateBackTime = Level.TimeSeconds + 4*HammerRotateRate; //set time (3 times longer than)
}

//this function sets the times for right hammer drop
simulated function DoRightHammerDrop(float FireRateMod)
{
    bAnimatingRightHammer = True;
    HammerRotateRate = DefaultHammerRotateRate/FireRateMod; //0.08
    RightHammerRotateForwardTime = Level.TimeSeconds + HammerRotateRate; //set time
    RightHammerRotateBackTime = Level.TimeSeconds + 4*HammerRotateRate; //set time (3 times longer than)
}

simulated function RotateLeftHammerBack()
{
    SetBoneRotation( 'Hammer01', -1*PistolHammerRotation, , 100); //set hammer rotation
}

simulated function RotateRightHammerBack()
{
    SetBoneRotation( 'Hammer', -1*PistolHammerRotation, , 100); //set hammer rotation
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateLeftHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( 'Hammer01', -DefaultHammerRotateMult*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( 'Hammer01', 0.3*DefaultHammerRotateMult*PistolHammerRotation, , 100- Rate*RateMult ); //needs to move from 0 to 45
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateRightHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( 'Hammer', -DefaultHammerRotateMult*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( 'Hammer', 0.3*DefaultHammerRotateMult*PistolHammerRotation, , 100- Rate*RateMult ); //needs to move from 0 to 45
}

//this function makes slide move back more when firing because default animation moves less than 9mm and looks really bad
simulated function AddExtraRightSlideMovement(float FireRateMod)
{
    bEnhancedRightSlideMovement = True;
    SlideMoveRate = 0.04/FireRateMod;
    RightSlideMoveBackTime = Level.TimeSeconds + SlideMoveRate; //set time
    RightSlideMoveForwardTime = Level.TimeSeconds + 2*SlideMoveRate; //set time
}

//this function makes slide move back more when firing because default animation moves less than 9mm and looks really bad
simulated function AddExtraLeftSlideMovement(float FireRateMod)
{
    bEnhancedLeftSlideMovement = True;
    SlideMoveRate = 0.04/FireRateMod;
    LeftSlideMoveBackTime = Level.TimeSeconds + SlideMoveRate; //set time
    LeftSlideMoveForwardTime = Level.TimeSeconds + 2*SlideMoveRate; //set time
}

//used for enhanced slide movement backwards during firing
simulated function MoveRightSlideSmooth(float rate, bool bMovingSlideBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/SlideMoveRate;
    if(bMovingSlideBack )
        SetBoneLocation( 'Slide', -DefaultSlideMoveMult*PistolSlideOffset, Rate*RateMult ); //move slide back
     else
        SetBoneLocation( 'Slide', -DefaultSlideMoveMult*PistolSlideOffset, 100 - Rate*RateMult ); //move slide forward
}

//used for enhanced slide movement backwards during firing
simulated function MoveLeftSlideSmooth(float rate, bool bMovingSlideBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/SlideMoveRate;
    if(bMovingSlideBack )
        SetBoneLocation( 'Slide01', -DefaultSlideMoveMult*PistolSlideOffset, Rate*RateMult ); //move slide back
     else
        SetBoneLocation( 'Slide01', -DefaultSlideMoveMult*PistolSlideOffset, 100 - Rate*RateMult ); //move slide forward
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
    SetBoneLocation( 'Slide01', -1.4*PistolSlideOffset, 100 ); //lock slide back
    bEnhancedLeftSlideMovement = false;
    LeftSlideReturnEndTime = 0;
}

simulated function LockRightSlideBack()
{
    SetBoneLocation( 'Slide', -1.4*PistolSlideOffset, 100 ); //lock slide back
    bEnhancedRightSlideMovement = false;
    RightSlideReturnEndTime = 0;
}

simulated function InterpolateRightSlide(float time)
{
    local rotator AdjustedHammerPitch;
    AdjustedHammerPitch.Pitch = 120*time*5;
    SetBoneLocation( 'Slide', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
    SetBoneRotation( 'Hammer', AdjustedHammerPitch-PistolHammerRotation, ,100 ); //(Pitch=120,Yaw=0,Roll=0)
}

simulated function InterpolateLeftSlide(float time)
{
    local rotator AdjustedHammerPitch;
    AdjustedHammerPitch.Pitch = 120*time*5;
    SetBoneLocation( 'Slide01', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
    SetBoneRotation( 'Hammer01', AdjustedHammerPitch-PistolHammerRotation, ,100 ); //(Pitch=120,Yaw=0,Roll=0)
}

simulated function ReturnRightSlideSmooth(float rate)
{
    local float RateMult;
    RateMult = 100/RightSlideReturnDuration;
    //calculate how much rate should be multiplied by to give 100 at end
    SetBoneLocation( 'Slide', -0.45*PistolSlideOffset, (rate*rateMult) ); //return slide back from -0.45 to 0
    SetBoneRotation( 'Hammer', -1*PistolHammerRotation, ,100 - (rate*rateMult) ); //needs to move from 0 to -120
}

simulated function ReturnLeftSlideSmooth(float rate)
{
    local float RateMult;
    RateMult = 100/LeftSlideReturnDuration;
    //calculate how much rate should be multiplied by to give 100 at end
    SetBoneLocation( 'Slide01', -0.45*PistolSlideOffset, (rate*rateMult) ); //return slide back from -0.45 to 0
    SetBoneRotation( 'Hammer01', -1*PistolHammerRotation, ,100 - (rate*rateMult) ); //needs to move from 0 to -120
}

//handles all slide movement
simulated function HandleSlideMovement()
{
    if (bEnhancedRightSlideMovement)
    {
        if (Level.TimeSeconds < RightSlideMoveBackTime && Level.TimeSeconds < RightSlideMoveForwardTime )
            MoveRightSlideSmooth(RightSlideMoveBackTime - Level.TimeSeconds, false); //move slide backwards with vector and "rate"
        if (Level.TimeSeconds > RightSlideMoveBackTime )
            MoveRightSlideSmooth(RightSlideMoveForwardTime - Level.TimeSeconds, true); //move slide forwards with vector and "rate"
        if (Level.TimeSeconds > RightSlideMoveForwardTime )
        {
            bEnhancedRightSlideMovement = false; //finished moving slide
            ResetRightSlidePosition(); //reset it to normal position
        }
    }
    if (bEnhancedLeftSlideMovement)
    {
        if (Level.TimeSeconds < LeftSlideMoveBackTime && Level.TimeSeconds < LeftSlideMoveForwardTime )
            MoveLeftSlideSmooth(LeftSlideMoveBackTime - Level.TimeSeconds, false); //move slide backwards with vector and "rate"
        if (Level.TimeSeconds > LeftSlideMoveBackTime )
            MoveLeftSlideSmooth(LeftSlideMoveForwardTime - Level.TimeSeconds, true); //move slide forwards with vector and "rate"
        if (Level.TimeSeconds > LeftSlideMoveForwardTime )
        {
            bEnhancedLeftSlideMovement = false; //finished moving slide
            ResetLeftSlidePosition(); //reset it to normal position
        }
    }
    if (bTweeningSlide && TweenEndTime > 0)
    {
        if (Level.TimeSeconds < TweenEndTime )
        {
            if (bTweenRightSlide)
                InterpolateRightSlide(TweenEndTime - Level.TimeSeconds);
            if (bTweenLeftSlide)
                InterpolateLeftSlide(TweenEndTime - Level.TimeSeconds);
        }
        if (Level.TimeSeconds > TweenEndTime )
        {
            ResetLeftSlidePosition();
            ResetRightSlidePosition();
            TweenEndTime = 0;
            bTweeningSlide = false;
            bTweenLeftSlide = false;
            bTweenRightSlide = false;
        }
    }
    if (RightSlideReturnEndTime > 0)
    {
        if (bIsReloading && !bRightSlideReturned && Level.TimeSeconds > RightSlideReturnStartTime && Level.TimeSeconds < RightSlideReturnEndTime)
        {
            ReturnRightSlideSmooth( RightSlideReturnEndTime - Level.TimeSeconds ); //0 to 100
        }
        if (Level.TimeSeconds > RightSlideReturnEndTime)
        {
            bRightSlideReturned = true;
            RightSlideReturnEndTime = 0;
            RotateRightHammerBack(); //reset it to normal position
        }
    }
    if (LeftSlideReturnEndTime > 0)
    {
        if (bIsReloading && !bLeftSlideReturned && Level.TimeSeconds > LeftSlideReturnStartTime && Level.TimeSeconds < LeftSlideReturnEndTime)
        {
            ReturnLeftSlideSmooth( LeftSlideReturnEndTime - Level.TimeSeconds ); //0 to 100
        }
        if (Level.TimeSeconds > LeftSlideReturnEndTime)
        {
            bLeftSlideReturned = true;
            LeftSlideReturnEndTime = 0;
            RotateLeftHammerBack(); //reset it to normal position
        }
    }
}

//handles all hammer rotation
simulated function HandleHammerRotation()
{
    if (bAnimatingLeftHammer)
    {
        if (Level.TimeSeconds < LeftHammerRotateForwardTime && Level.TimeSeconds < LeftHammerRotateBackTime )
            RotateLeftHammerSmooth(LeftHammerRotateForwardTime - Level.TimeSeconds, false); //rotate hammer forwards
        if (Level.TimeSeconds > LeftHammerRotateForwardTime )
            RotateLeftHammerSmooth(LeftHammerRotateBackTime - Level.TimeSeconds, true); //rotate hammer backwards
        if (Level.TimeSeconds > LeftHammerRotateBackTime )
        {
            bAnimatingLeftHammer = false; //finished rotating hammer
            RotateLeftHammerBack(); //reset it to normal position
        }
    }
    if (bAnimatingRightHammer)
    {
        if (Level.TimeSeconds < RightHammerRotateForwardTime && Level.TimeSeconds < RightHammerRotateBackTime )
            RotateRightHammerSmooth(RightHammerRotateForwardTime - Level.TimeSeconds, false); //rotate hammer forwards
        if (Level.TimeSeconds > RightHammerRotateForwardTime )
            RotateRightHammerSmooth(RightHammerRotateBackTime - Level.TimeSeconds, true); //rotate hammer backwards
        if (Level.TimeSeconds > RightHammerRotateBackTime )
        {
            bAnimatingRightHammer = false; //finished rotating hammer
            RotateRightHammerBack(); //reset it to normal position
        }
    }
}

simulated function WeaponTick(float dt)
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        HandleSlideMovement();
        HandleHammerRotation();
    }
    Super.WeaponTick(dt);
}

simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start Slide tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

//after reload tween slide back if tactical reload
simulated function ClientFinishReloading()
{
    RotateHammersBack(); //always
    if(bShortReload)
    {
        StartTweeningSlide(); //allow tweening of both slides
    }
    else if (bHalfShortReload)
    {
        StartTweeningSlide(); //allow tweening of both slides, only left should trigger
        SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset right Slide position
    }
    else
    {
        SetBoneLocation( 'Slide01', PistolSlideOffset, 0 ); //reset left slide position
        SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset right slide position
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
    bAnimatingLeftHammer = false;
    bAnimatingRightHammer = false;
    bEnhancedLeftSlideMovement = false;
    bEnhancedRightSlideMovement = false;
    SetBoneRotation( 'Hammer', PistolHammerRotation, , 0); //always reset hammer rotations
    SetBoneRotation( 'Hammer01', PistolHammerRotation, , 0); //always reset hammer rotations

    if (MagAmmoRemaining <= 0)
    {
        bShortReload = false;
        bHalfShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', -0.45*PistolSlideOffset, 100 ); //special case for deagle because default slide animation sucks
        SetBoneLocation( 'Slide01', -0.45*PistolSlideOffset, 100 ); //special case for deagle because default slide animation sucks

        bRightSlideReturned = false;
        RightSlideReturnStartTime = Level.TimeSeconds + 0.88571*ReloadRate;
        RightSlideReturnEndTime = Level.TimeSeconds + 0.90476*ReloadRate;
        RightSlideReturnDuration = 2/(30*reloadmulti); //its 2 frames

        bLeftSlideReturned = false;
        LeftSlideReturnStartTime = Level.TimeSeconds + 0.93333*ReloadRate;
        LeftSlideReturnEndTime = Level.TimeSeconds + 0.95238*ReloadRate;
        LeftSlideReturnDuration = 2/(30*reloadmulti); //its 2 frames
    }
    else if (MagAmmoRemaining == 1)
    {
        bShortReload = false;
        bHalfShortReload = true;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide01', PistolSlideOffset, 100 ); //move left slide forward
        SetBoneLocation( 'Slide', -0.45*PistolSlideOffset, 100 ); //special case for deagle because default slide animation sucks
        bTweenLeftSlide = true;

        //replacement for DoRightSlideReturn
        bRightSlideReturned = false;
        RightSlideReturnStartTime = Level.TimeSeconds + 0.95876*ReloadRate;
        RightSlideReturnEndTime = Level.TimeSeconds + 0.97938*ReloadRate;
        RightSlideReturnDuration = 2/(30*reloadmulti); //its 2 frames
    }
    else if (MagAmmoRemaining >= 2)
    {
        bShortReload = true;
        bHalfShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move slide forward
        SetBoneLocation( 'Slide01', PistolSlideOffset, 100 ); //move slide forward
        bTweenLeftSlide = true;
        bTweenRightSlide = true;
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

function bool HandlePickupQuery( pickup Item )
{
    if ( Item.InventoryType==Class'ScrnBalanceSrv.ScrnDeagle' )
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
        SinglePistol = KFWeapon(Spawn(DemoReplacement));
        SinglePistol.SellValue = SellValue / 2;
        SinglePistol.GiveTo(Instigator);
        SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
        SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
        MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);

        Pickup = KFWeaponPickup(Spawn(SinglePistol.PickupClass,,, StartLocation));
    }
    else
        Pickup = KFWeaponPickup(Spawn(class<KFWeapon>(DemoReplacement).default.PickupClass,,, StartLocation));

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
    }

    Destroyed();
    Destroy();
}

defaultproperties
{
    MagAmmoRemaining=16
    ClientMagAmmoRemaining=16
    ReloadShortRate = 2.9333 //no slides locked back
    ReloadHalfShortRate = 3.2333 //right slide locked back
    ReloadRate=3.500000 //default
    PistolSlideOffset=(X=0.01970,Y=0.0,Z=0.0)
    PistolHammerRotation=(Pitch=120,Yaw=0,Roll=0) //tripwire why did you do this
    DefaultHammerRotateRate = 0.04
    DefaultHammerRotateMult = 1.0
    Weight=6.000000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualDeagleFire'
    DemoReplacement=Class'ScrnBalanceSrv.ScrnDeagle'
    PickupClass=Class'ScrnBalanceSrv.ScrnDualDeaglePickup'
    ItemName="Dual Handcannons SE"

    HudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon"
    SelectSoundRef="KF_HandcannonSnd.50AE_Select"
    MeshRef="KF_Weapons_Trip.Dual50_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.Pistols.deagle_cmb"
    DefaultRightSlideReturnStartMult=0.88571 //only applies to empty
    DefaultRightSlideReturnEndMult=0.90476 //95
    DefaultLeftSlideReturnStartMult=0.93333 //98
    DefaultLeftSlideReturnEndMult=0.95238 //100
    DefaultSlideMoveMult = 1.4
}
