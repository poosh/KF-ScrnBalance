class ScrnDeagle extends Deagle;

var transient ScrnDualDeagle DualGuns;

var transient bool bBotControlled;

//deagle has an additional fix for the hammer
//and also extra slide movement
//and extra slide locked back travel

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var transient bool bAnimatingHammer;
var transient bool bEnhancedSlideMovement; //adding extra slide movement to fire animation
var transient float SlideMoveRate; //stores total amount of time each slide movement is (in cases where fire animation is sped up)
var transient float SlideMoveBackTime;
var transient float SlideMoveForwardTime;
//var transient float SlideLockMult;

var bool bSlideReturned;
var float DefaultSlideReturnStartMult; //multiplier for reload timer to start slide return
var float DefaultSlideReturnEndMult; //multiplier for reload timer to start slide return
var float SlideReturnStartTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float SlideReturnEndTime; //time to that slide finishes moving forward for empty reload (in multiplier of reloadrate)
var float SlideReturnDuration; //amount of time in seconds the slide returns for

var transient float HammerRotateRate;
var transient float HammerRotateBackTime;
var transient float HammerRotateForwardTime;
var transient float HammerRotateMult;

var float DefaultSlideMoveMult;

var float DefaultHammerRotateMult;
var float DefaultHammerRotateRate;

var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload
var vector PistolSlideLockedOffset; //for tactical reload
var rotator PistolHammerRotation; //for deagle's stupid hammer

var bool bFiringLastRound;


replication
{
    reliable if ( Role == ROLE_Authority )
        ClientReplicateAmmo;
}


simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( MagAmmoRemaining == 0 && !bIsReloading ) {
            LockSlideBack();
            RotateHammerBack();
        }
    }
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
        RotateHammerBack(); //always do this now
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

simulated function ResetHammerRotation()
{
    SetBoneRotation( 'Hammer', PistolHammerRotation, , 0); //reset hammer rotation
}

simulated function LockSlideBack()
{
    SetBoneLocation( 'Slide', -1.4*PistolSlideOffset, 100 ); //lock slide back a lot
}

simulated function RotateHammerBack()
{
    SetBoneRotation( 'Hammer', -1*PistolHammerRotation, , 100); //set hammer rotation for empty reload
}

//used for tactical reload
simulated function InterpolateSlide(float time)
{
    local rotator AdjustedHammerPitch;
    AdjustedHammerPitch.Pitch = 120*time*5;
    SetBoneLocation( 'Slide', PistolSlideOffset, (time*500) ); //
    SetBoneRotation( 'Hammer', AdjustedHammerPitch-PistolHammerRotation, ,100 ); //(Pitch=120,Yaw=0,Roll=0)
}

//used for enhanced slide movement backwards during firing
simulated function MoveSlideSmooth(float rate, bool bMovingSlideBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/SlideMoveRate;
    if(bMovingSlideBack )
        SetBoneLocation( 'Slide', -DefaultSlideMoveMult*PistolSlideOffset, Rate*RateMult ); //move slide back
     else
        SetBoneLocation( 'Slide', -DefaultSlideMoveMult*PistolSlideOffset, 100 - Rate*RateMult ); //move slide forward
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( 'Hammer', -1*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( 'Hammer', 0.3*PistolHammerRotation, , 100- Rate*RateMult ); //needs to move from 0 to 45
}

//returns slide after empty reload
simulated function DoSlideReturn()
{
    bSlideReturned = false;
    SlideReturnStartTime = Level.TimeSeconds + DefaultSlideReturnStartMult*ReloadRate;
    SlideReturnEndTime = Level.TimeSeconds + DefaultSlideReturnEndMult*ReloadRate;
    SlideReturnDuration = SlideReturnEndTime - SlideReturnStartTime;
}

simulated function ReturnSlideSmooth(float rate)
{
    local float RateMult;
    RateMult = 100/SlideReturnDuration;
    //calculate how much rate should be multiplied by to give 100 at end
    SetBoneLocation( 'Slide', -0.45*DefaultSlideMoveMult*PistolSlideOffset, (rate*rateMult) ); //return slide back from -0.45 to 0
    SetBoneRotation( 'Hammer', -1*PistolHammerRotation, ,100 - (rate*rateMult) ); //needs to move from 0 to -120
}

//this function makes slide move back more when firing because default animation moves less than 9mm and looks really bad
simulated function AddExtraSlideMovement(float FireRateMod)
{
    bEnhancedSlideMovement = True;
    SlideMoveRate = 0.04/FireRateMod; //0.08
    SlideMoveBackTime = Level.TimeSeconds + SlideMoveRate; //set time
    SlideMoveForwardTime = Level.TimeSeconds + 2*SlideMoveRate; //set time
}

//this function sets the times for hammer drop
simulated function DoHammerDrop(float FireRateMod)
{
    bAnimatingHammer = True;
    HammerRotateRate = 0.04/FireRateMod; //0.08
    HammerRotateForwardTime = Level.TimeSeconds + HammerRotateRate; //set time
    HammerRotateBackTime = Level.TimeSeconds + 4*HammerRotateRate; //set time (3 times longer than)
}

simulated function HandleSlideMovement()
{
    if (TweenEndTime > 0)
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
}

simulated function EnhanceSlideMovement()
{
    if (Level.TimeSeconds < SlideMoveBackTime && Level.TimeSeconds < SlideMoveForwardTime )
        MoveSlideSmooth(SlideMoveBackTime - Level.TimeSeconds, false); //move slide backwards with vector and "rate"
    if (Level.TimeSeconds > SlideMoveBackTime )
        MoveSlideSmooth(SlideMoveForwardTime - Level.TimeSeconds, true); //move slide forwards with vector and "rate"
    if (Level.TimeSeconds > SlideMoveForwardTime )
    {
        bEnhancedSlideMovement = false; //finished moving slide
        ResetSlidePosition(); //reset it to normal position
    }
}

simulated function DoHammerRotation()
{
    if (Level.TimeSeconds < HammerRotateForwardTime && Level.TimeSeconds < HammerRotateBackTime )
        RotateHammerSmooth(HammerRotateForwardTime - Level.TimeSeconds, false); //rotate hammer forwards
    if (Level.TimeSeconds > HammerRotateForwardTime )
        RotateHammerSmooth(HammerRotateBackTime - Level.TimeSeconds, true); //rotate hammer backwards
    if (Level.TimeSeconds > HammerRotateBackTime )
    {
        bAnimatingHammer = false; //finished rotating hammer
        RotateHammerBack(); //reset it to normal position
        ResetSlidePosition();
    }
}

simulated function ReleaseEnhancedSlide()
{
    if (bIsReloading && !bShortReload && !bSlideReturned && Level.TimeSeconds > SlideReturnStartTime && Level.TimeSeconds < SlideReturnEndTime)
    {
        ReturnSlideSmooth( SlideReturnEndTime - Level.TimeSeconds ); //0 to 100
    }
    if (Level.TimeSeconds > SlideReturnEndTime)
    {
        bSlideReturned = true;
        SlideReturnEndTime = 0;
        RotateHammerBack(); //reset it to normal position
    }
}

// compensates reload animation to keep slide in place
simulated function StartTweeningSlide()
{
    bTweeningSlide = true;
    TweenEndTime = Level.TimeSeconds + 0.2;
    HandleSlideMovement();
}

simulated function WeaponTick(float dt)
{
    if ( Instigator == None )
        return;

    if ( Level.NetMode != NM_DedicatedServer && Instigator.IsLocallyControlled() )
    {
        if (bTweeningSlide )
        {
            HandleSlideMovement();
        }
        if (bEnhancedSlideMovement)
        {
            EnhanceSlideMovement();
        }
        if (bAnimatingHammer)
        {
            DoHammerRotation();
        }
        if (SlideReturnEndTime > 0)
        {
            ReleaseEnhancedSlide();
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

simulated function ClientFinishReloading()
{
    bIsReloading = false;
    PlayIdle();

    RotateHammerBack();
    if(bShortReload)
        StartTweeningSlide(); //start tweening slide back
    else
        ResetSlidePosition(); //since deagle has additional slide correction

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
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
    ResetHammerRotation(); //use reload animation's
    if (MagAmmoRemaining <= 0)
    {
        bShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);

        SetBoneLocation( 'Slide', -0.45*PistolSlideOffset, 100 ); //special case for deagle because default slide animation sucks
        DoSlideReturn(); //sets times for slide return
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent slide from sliding
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move the slide forward
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
    MagAmmoRemaining = SrvAmmo & 0xFF;
    ClientForceAmmoUpdate(0, (SrvAmmo >> 8));

    if ( bIsReloading ) {
        ClientFinishReloading();
    }
    else {
        SetSlidePositions();
    }
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
    MagCapacity=7  // +1 in chamber in case of a tactical reload
    ReloadShortRate=1.66
    ReloadShortAnim="Reload"
    ReloadRate=2.2
    PistolSlideOffset=(X=0.01970,Y=0.0,Z=0.0)
    PistolHammerRotation=(Pitch=120,Yaw=0,Roll=0) //tripwire why did you do this
    FireModeClass(0)=class'ScrnDeagleFire'
    PickupClass=class'ScrnDeaglePickup'
    ItemName="Handcannon SE"
    Weight=4
    DefaultSlideMoveMult = 1.4
    DefaultSlideReturnStartMult=0.84848 //for timing slide release with empty reload
    DefaultSlideReturnEndMult=0.87878 //for timing slide release with empty reload
    Priority=100

    PutDownTime=0.15
    BringUpTime=0.15
    SelectAnimRate=4.0
    PutDownAnimRate=4.0
}
