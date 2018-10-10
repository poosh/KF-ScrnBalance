class ScrnDualies extends Dualies;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;
var         float           ReloadHalfShortRate;

var transient bool bShortReload;
var transient bool bHalfShortReload;
var bool bTweeningSlide;
var bool bTweenLeftSlide;
var bool bTweenRightSlide;

var bool bAnimatingLeftHammer;
var bool bAnimatingRightHammer;
var float LeftHammerRotateForwardTime;
var float RightHammerRotateForwardTime;
var float LeftHammerRotateBackTime;
var float RightHammerRotateBackTime;

var transient float HammerRotateMult;
var transient float HammerRotateRate;
var float DefaultHammerRotateMult;
var float DefaultHammerRotateRate;

var float TweenEndTime;

var vector PistolSlideOffset; //for tactical reload
var rotator PistolHammerRotation;

var transient int NumKillsWithoutReleasingTrigger;

var transient int ClientMagAmmoRemaining;
var transient int FiringRound;


simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( ClientMagAmmoRemaining != MagAmmoRemaining ) {
            if ( MagAmmoRemaining > ClientMagAmmoRemaining ) {
                // mag update after reload
                ScrnDualiesFire(GetFireMode(0)).SetPistolFireOrder( (MagAmmoRemaining%2) == 1 );
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

function DropFrom(vector StartLocation)
{
    local int m;
    local KFWeaponPickup Pickup;
    local Inventory I;
    local int AmmoThrown,OtherAmmo;

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

    if( Instigator.Health>0 )
    {
        OtherAmmo = AmmoThrown/2;
        AmmoThrown-=OtherAmmo;
        I = Spawn(Class'ScrnBalanceSrv.ScrnSingle');
        I.GiveTo(Instigator);
        Weapon(I).Ammo[0].AmmoAmount = OtherAmmo;
        Single(I).MagAmmoRemaining = MagAmmoRemaining/2;
        MagAmmoRemaining = Max(MagAmmoRemaining-Single(I).MagAmmoRemaining,0);
    }
    Pickup = Spawn(class'ScrnBalanceSrv.ScrnSinglePickup',,, StartLocation);
    if ( Pickup != None )
    {
        Pickup.InitDroppedPickupFor(self);
        Pickup.DroppedBy = PlayerController(Instigator.Controller);
        Pickup.Velocity = Velocity;
        Pickup.AmmoAmount[0] = AmmoThrown;
        Pickup.MagAmmoRemaining = MagAmmoRemaining;
        if (Instigator.Health > 0)
            Pickup.bThrown = true;
    }

    Destroyed();
    Destroy();
}

function ServerStopFire(byte Mode)
{
    super.ServerStopFire(Mode);
    NumKillsWithoutReleasingTrigger = 0;
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


simulated function RotateHammersBack()
{
    SetBoneRotation( '9mm_hammer', -1*PistolHammerRotation, , 100); //set hammer rotation for empty reload
    SetBoneRotation( '9mm_hammer01', -1*PistolHammerRotation, , 100); //set hammer rotation for empty reload
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
    SetBoneRotation( '9mm_hammer01', -1*PistolHammerRotation, , 100); //set hammer rotation
}

simulated function RotateRightHammerBack()
{
    SetBoneRotation( '9mm_hammer', -1*PistolHammerRotation, , 100); //set hammer rotation
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateLeftHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( '9mm_hammer01', -DefaultHammerRotateMult*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( '9mm_hammer01', 0.3*DefaultHammerRotateMult*PistolHammerRotation, , 100- Rate*RateMult ); //needs to move from 0 to 45
}

//used for enhanced hammer rotation forwards during firing
simulated function RotateRightHammerSmooth(float rate, bool bRotatingHammerBack)
{
    local float RateMult;
    //calculate how much rate should be multiplied by to give 100 at end
    RateMult = 100/HammerRotateRate;
    if(bRotatingHammerBack )
        SetBoneRotation( '9mm_hammer', -DefaultHammerRotateMult*PistolHammerRotation, ,100 - Rate*RateMult/3 ); //needs to move from 0 to -120
     else
        SetBoneRotation( '9mm_hammer', 0.3*DefaultHammerRotateMult*PistolHammerRotation, , 100- Rate*RateMult ); //needs to move from 0 to 45
}

simulated function ResetLeftSlidePosition()
{
    SetBoneLocation( '9mm_slide01', PistolSlideOffset, 0 ); //reset Slide position
}

simulated function ResetRightSlidePosition()
{
    SetBoneLocation( '9mm_slide', PistolSlideOffset, 0 ); //reset Slide position
}

simulated function LockLeftSlideBack()
{
    SetBoneLocation( '9mm_slide01', -1*PistolSlideOffset, 100 ); //lock slide back
}

simulated function LockRightSlideBack()
{
    SetBoneLocation( '9mm_slide', -1*PistolSlideOffset, 100 ); //lock slide back
}

simulated function InterpolateRightSlide(float time)
{
    local rotator AdjustedHammerPitch;
    AdjustedHammerPitch.Pitch = 120*time*5;
    SetBoneLocation( '9mm_slide', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
    //SetBoneRotation( '9mm_hammer', AdjustedHammerPitch-PistolHammerRotation, ,100 ); //(Pitch=120,Yaw=0,Roll=0)
}

simulated function InterpolateLeftSlide(float time)
{
    local rotator AdjustedHammerPitch;
    AdjustedHammerPitch.Pitch = 120*time*5;
    SetBoneLocation( '9mm_slide01', PistolSlideOffset, (time*500)); //after tactical reload tween this from 100 to 0
    //SetBoneRotation( '9mm_hammer01', AdjustedHammerPitch-PistolHammerRotation, ,100 ); //(Pitch=120,Yaw=0,Roll=0)
}

//handles all slide movement
simulated function HandleSlideMovement()
{
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
}

//handles all hammer rotation
function HandleHammerRotation()
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
        SetBoneLocation( '9mm_slide', PistolSlideOffset, 0 ); //reset right Slide position
    }
    else
    {
        SetBoneLocation( '9mm_slide01', PistolSlideOffset, 0 ); //reset left slide position
        SetBoneLocation( '9mm_slide', PistolSlideOffset, 0 ); //reset right slide position
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

    if (MagAmmoRemaining <= 0)
    {
        bShortReload = false;
        bHalfShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        ResetLeftSlidePosition(); //use reload animation's
        ResetRightSlidePosition(); //use reload animation's
    }
    else if (MagAmmoRemaining == 1)
    {
        bShortReload = false;
        bHalfShortReload = true;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        ResetRightSlidePosition(); //use reload animation's for right slide
        SetBoneLocation( '9mm_slide01', PistolSlideOffset, 100 ); //move left slide forward
        bTweenLeftSlide = true;
    }
    else if (MagAmmoRemaining >= 2)
    {
        bShortReload = true;
        bHalfShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( '9mm_slide', PistolSlideOffset, 100 ); //move slide forward
        SetBoneLocation( '9mm_slide01', PistolSlideOffset, 100 ); //move slide forward
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


defaultproperties
{
     MagAmmoRemaining=30
     ClientMagAmmoRemaining=30
     ReloadShortRate = 2.93 //no slides locked back
     ReloadHalfShortRate = 3.23 //right slide locked back
     //ReloadRate=3.500000 //both
     Weight=1
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualiesFire'
     DemoReplacement=Class'ScrnBalanceSrv.ScrnSingle'
     PickupClass=Class'ScrnBalanceSrv.ScrnDualiesPickup'
     ItemName="Dual 9mms SE"
     PistolSlideOffset=(X=0.02330,Y=0.0,Z=0.0)
     PistolHammerRotation=(Pitch=145,Yaw=0,Roll=0) //tripwire why did you do this
     DefaultHammerRotateMult=1
     DefaultHammerRotateRate=0.02
}
