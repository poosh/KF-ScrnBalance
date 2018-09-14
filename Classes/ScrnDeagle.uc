class ScrnDeagle extends Deagle;
//deagle has an additional fix for the hammer
//and also extra slide movement
//and extra slide locked back travel

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningSlide;
var transient bool bEnhancedSlideMovement; //adding extra slide movement to fire animation
var transient float SlideMoveRate; //stores total amount of time each slide movement is (in cases where fire animation is sped up)
var transient float SlideMoveBackTime;
var transient float SlideMoveForwardTime;
var transient float SlideLockMult;
var float DefaultSlideMoveRate;
var float DefaultSlideMoveMult;
var float TweenEndTime;
var vector PistolSlideOffset; //for tactical reload
var vector PistolSlideLockedOffset; //for tactical reload
var rotator PistolHammerRotation; //for deagle's stupid hammer

simulated function BringUp(optional Weapon PrevWeapon)
{
	Super.BringUp(PrevWeapon);
    if (MagAmmoRemaining == 0)
        LockSlideBack();
}

simulated function ResetSlidePosition()
{
    SetBoneLocation( 'Slide', PistolSlideOffset, 0 ); //reset slide position
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
    SetBoneLocation( 'Slide', PistolSlideOffset, (time*500) ); //
    SetBoneRotation( 'Hammer', PistolHammerRotation, , (time*500));
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


//this function makes slide move back more when firing because default animation moves less than 9mm and looks really bad
simulated function AddExtraSlideMovement(float FireRateMod)
{
    bEnhancedSlideMovement = True;
    SlideMoveRate = DefaultSlideMoveRate/FireRateMod; //0.08
    SlideMoveBackTime = Level.TimeSeconds + SlideMoveRate; //set time
    SlideMoveForwardTime = Level.TimeSeconds + 2*SlideMoveRate; //set time
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
    if (bEnhancedSlideMovement)
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
    else
        ResetSlidePosition(); //since deagle has additional slide correction
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
        SetBoneLocation( 'Slide', -0.45*PistolSlideOffset, 100 ); //special case for deagle because default slide animation sucks
        SetBoneRotation( 'Hammer', PistolHammerRotation, , 0); //reset hammer rotation on reload start
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent slide from sliding
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move the slide forward
        SetBoneRotation( 'Hammer', PistolHammerRotation, , 100); //fix hammer rotation so it looks good
    }
}

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



simulated function bool PutDown()
{
    if ( Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnDualDeagle' )
    {
        bIsReloading = false;
    }

    return super(KFWeapon).PutDown();
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
     ReloadShortRate=1.66
     ReloadShortAnim="Reload"
     ReloadRate=1.96 //1.96
     PistolSlideOffset=(X=0.01970,Y=0.0,Z=0.0)
     //PistolSlideLockedOffset=(X=-0.01970,Y=0,Z=0) //locked pistol slide position
     PistolHammerRotation=(Pitch=120,Yaw=0,Roll=0) //tripwire why did you do this
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDeagleFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnDeaglePickup'
     ItemName="Handcannon SE"
     Weight=4
     DefaultSlideMoveRate = 0.04
     DefaultSlideMoveMult = 1.4
     SlideLockMult = 0.5
}
