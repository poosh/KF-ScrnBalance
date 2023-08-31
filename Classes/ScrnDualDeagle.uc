class ScrnDualDeagle extends DualDeagle;

var transient ScrnDeagle SingleGun;
var byte LeftGunAmmoRemaining;  // ammo in the left pistol. Left pistol always has more or equal bullets than the right one
var transient int OtherGunAmmoRemaining; // ammo remaining in the other gun while holding a single pistol
var transient bool bFindSingleGun;
var transient bool bBotControlled;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;
var         float           ReloadHalfShortRate;

var transient byte TacticalReload;  // 1 - tactical reload for one gun, 2 - tactical reload for both guns
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

var transient int FiringRound;
var transient int OutOfOrderShots;  // equalize ammo in case when a single pistol was used before


replication
{
    reliable if ( Role == ROLE_Authority )
        LeftGunAmmoRemaining;

    reliable if ( Role == ROLE_Authority )
        ClientReplicateAmmo;
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( Role < ROLE_Authority ) {
        bFindSingleGun = true;
    }
}

simulated function PostNetReceive()
{
    if ( Role < ROLE_Authority ) {
        if (!bIsReloading) {
            SetSlidePositions();
        }
    }
}

simulated function Destroyed()
{
    if ( SingleGun != none ) {
        SingleGun.DualGuns = none;
        SingleGun.InventoryGroup = SingleGun.default.InventoryGroup;
        SingleGun = none;
    }

    super.Destroyed();
}

simulated function WeaponTick(float dt)
{
    if ( Instigator == None )
        return;

    if (Level.NetMode != NM_DedicatedServer && Instigator.IsLocallyControlled() ) {
        HandleSlideMovement();
        HandleHammerRotation();

        if ( bFindSingleGun && SingleGun == none ) {
            SingleGun = ScrnDeagle(Instigator.FindInventoryType(DemoReplacement));
            if ( SingleGun != none ) {
                bFindSingleGun = false;
                SingleGun.DualGuns = self;
                SingleGun.InventoryGroup = 11;
            }
        }
    }

    // C&P from KFWepon to cut the crap out of it
    // WARNING! The code is stripped to remove unsued features, such as:
    // Flashlight, bHoldToReload, bReloadEffectDone, etc.
    // Do not uses this code as a general reference
    if( bHasAimingMode ) {
        if( bForceLeaveIronsights || ForceZoomOutTime > 0 ) {
            if( bAimingRifle && (bForceLeaveIronsights || Level.TimeSeconds > ForceZoomOutTime) ) {
                ZoomOut(true);  // sets bAimingRifle=false
                if( Role < ROLE_Authority)
                    ServerZoomOut(false);
            }
            if ( !bAimingRifle ) {
                bForceLeaveIronsights = false;
                ForceZoomOutTime = 0;
            }
        }
    }

     if ( Role < ROLE_Authority )
        return;
    // server-side stuff

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

simulated function Fire(float F)
{
    FiringRound = MagAmmoRemaining;
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
    if ( SingleGun == none )
        return;

    Instigator.PendingWeapon = SingleGun;
    PutDown();
}

simulated function int RightGunAmmoRemaining()
{
    return MagAmmoRemaining - LeftGunAmmoRemaining;
}

function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
    if ( !super(Weapon).ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
        return false;

    if ( Load > 0 && (Mode == 0 || bReduceMagAmmoOnSecondaryFire) ) {
        if (LeftGunAmmoRemaining > RightGunAmmoRemaining() && LeftGunAmmoRemaining > 0 ) {
            // LeftGunAmmoRemaining is byte (unsigned). Make sure to not overlap.
            --LeftGunAmmoRemaining;
        }
        if ( --MagAmmoRemaining < 0 )
            MagAmmoRemaining = 0;
    }
    NetUpdateTime = Level.TimeSeconds - 1;

    if ( !HasAmmo() ) {
        if ( ScrnHumanPawn(Instigator) != none ) {
            ScrnHumanPawn(Instigator).CheckOutOfAmmo(true);
        }
    }
    return true;
}

/**
 * BringUp() is executed on both server and client sides.
 * PutDown() is executed only on the CLIENT side.
 * We call SyncSingleFromDual() inside the PutDown() only to predict SingleGun.MagAmmoRemaining on the client side
 * Actual value will be set later on the server side, from SingleGun.BringUp()
 * By doing that we prevent HUD flickering while bringing the gun up before MagAmmoRemaining gets replicated
 */
simulated function BringUp(optional Weapon PrevWeapon)
{
    if ( Role == ROLE_Authority && SingleGun != none ) {
        SyncDualFromSingle();
        ReplicateAmmo();
    }

    Super.BringUp(PrevWeapon);

    if ( Instigator.IsLocallyControlled() ) {
        RotateHammersBack(); //always do this now
        SetSlidePositions();
    }
}

simulated function bool PutDown()
{
    if ( super(KFWeapon).PutDown() ) {
        if ( SingleGun != none ) {
            SyncSingleFromDual();
        }
        return true;
    }
    return false;
}

// sync the Single gun state based on Duals
simulated function SyncSingleFromDual()
{
    if ( SingleGun == none )
        return;

    SingleGun.MagAmmoRemaining = max(LeftGunAmmoRemaining, RightGunAmmoRemaining());
    OtherGunAmmoRemaining = MagAmmoRemaining - SingleGun.MagAmmoRemaining;
}

// sync the Dual gun state based on Single
simulated function SyncDualFromSingle()
{
    local int a;

    if ( SingleGun == none )
        return;

    a = AmmoAmount(0);
    MagAmmoRemaining = OtherGunAmmoRemaining + SingleGun.MagAmmoRemaining;
    if (MagAmmoRemaining > a) {
        MagAmmoRemaining = a;
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
        SingleGun.MagAmmoRemaining = MagAmmoRemaining - OtherGunAmmoRemaining;
    }
    // left gun ammo must be >= right gun. If not - silently swap magazines
    // Because the half-empty reload animation assumes that the left gun still has ammo.
    LeftGunAmmoRemaining = max(OtherGunAmmoRemaining, SingleGun.MagAmmoRemaining);
    OutOfOrderShots = max(0, LeftGunAmmoRemaining - RightGunAmmoRemaining() - 1);
    SetPistolFireOrder();
}

simulated function SetPistolFireOrder()
{
    ScrnDualDeagleFire(GetFireMode(0)).SetPistolFireOrder(LeftGunAmmoRemaining > RightGunAmmoRemaining());
}


function bool HandlePickupQuery( pickup Item )
{
    if ( DemoReplacement != none && Item.InventoryType == DemoReplacement ) {
        if( LastHasGunMsgTime < Level.TimeSeconds && PlayerController(Instigator.Controller) != none )
        {
            LastHasGunMsgTime = Level.TimeSeconds + 0.5;
            PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 1);
        }

        return true;
    }

    return Super.HandlePickupQuery(Item);
}

function KFWeapon DetachSingle()
{
    local KFWeapon OldGun;

    if ( SingleGun == none )
        return none;

    SingleGun.DualGuns = none;
    SingleGun.SellValue = SellValue / 2;
    SingleGun.Ammo[0].AmmoAmount /= 2;
    if ( Instigator != none && Instigator.Weapon != SingleGun ) {
        // update ammo of the single gun only if it is not currently equipped
        SingleGun.MagAmmoRemaining = LeftGunAmmoRemaining;
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
    }

    SingleGun.InventoryGroup = SingleGun.default.InventoryGroup;
    SingleGun.Weight = SingleGun.default.Weight;
    Weight = default.Weight - SingleGun.Weight;

    OldGun = SingleGun;
    SingleGun = none;
    return OldGun;
}

simulated function DetachFromPawn(Pawn P)
{
    // Triggers on the server side on weapon put down. PutDown() is client-side only.
    if ( SingleGun != none ) {
        SyncSingleFromDual();
    }
    super.DetachFromPawn(P);
}

function DropFrom(vector StartLocation)
{
    local int m;
    local KFWeaponPickup Pickup;
    local int OldAmmo;

    if( !bCanThrow )
        return;

    OldAmmo = AmmoAmount(0);
    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

    DetachSingle();
    if ( Instigator != None )
        DetachFromPawn(Instigator);


    Pickup = KFWeaponPickup(Spawn(DemoReplacement.default.PickupClass,,, StartLocation));
    if ( Pickup != None ) {
        Pickup.InitDroppedPickupFor(self);
        Pickup.DroppedBy = PlayerController(Instigator.Controller);
        Pickup.Velocity = Velocity;
        Pickup.SellValue = SellValue / 2;
        Pickup.Cost = Pickup.SellValue * 3 / 4;
        Pickup.AmmoAmount[0] = OldAmmo - AmmoAmount(0);
        Pickup.MagAmmoRemaining = OtherGunAmmoRemaining;
        if (Instigator.Health > 0)
            Pickup.bThrown = true;
    }

    Destroyed();
    Destroy();
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
    local bool bSpawnSingle;
    local KFWeaponPickup KWP;
    local int OldAmmo;
    local KFPlayerReplicationInfo KFPRI;

    // remember it once to stop calling the function on every tick
    bBotControlled = !Other.IsHumanControlled();
    KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);
    KWP = KFWeaponPickup(Pickup);
    SingleGun = ScrnDeagle(Other.FindInventoryType(DemoReplacement));
    bSpawnSingle = SingleGun == none;
    if ( bSpawnSingle ) {
        SingleGun = ScrnDeagle(Spawn(DemoReplacement));
        SingleGun.SellValue = 0;
    }
    SingleGun.DualGuns = self;
    SingleGun.InventoryGroup = 11;
    if ( bSpawnSingle ) {
        SingleGun.GiveTo(Other);
    }
    OldAmmo = SingleGun.AmmoAmount(0);

    UpdateMagCapacity(Other.PlayerReplicationInfo);

    if ( KWP != none && KWP.bDropped ) {
        // picked on the ground
        SellValue = SingleGun.SellValue + KWP.SellValue;
        OtherGunAmmoRemaining = clamp(KWP.MagAmmoRemaining, 0, MagCapacity/2 + 1);
        OldAmmo += KWP.AmmoAmount[0];
    }
    else {
        // bought at the trader
        if (KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
            SellValue = ceil(class<KFWeaponPickup>(PickupClass).default.Cost * 0.375
                * KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, PickupClass));
        }
        else {
            // half of 3/4 of the price
            SellValue = class<KFWeaponPickup>(PickupClass).default.Cost * 3 / 8;
        }
        SellValue += SingleGun.SellValue;
        OtherGunAmmoRemaining = max(MagAmmoRemaining - SingleGun.MagAmmoRemaining, 0);
        OldAmmo += SingleGun.Ammo[0].InitialAmount;
    }

    Weight = default.Weight - SingleGun.Weight;

    Super(Weapon).GiveTo(Other, Pickup);

    // this workaround required to properly display weight in the trader
    Weight = default.Weight;
    SingleGun.Weight = 0;

    Ammo[0].AmmoAmount = clamp(OldAmmo, 0, MaxAmmo(0));
}

// === fx ====================================================================

simulated function SetSlidePositions()
{
    if ( MagAmmoRemaining <= LeftGunAmmoRemaining )
        LockRightSlideBack();
    else
        ResetRightSlidePosition();

    if ( MagAmmoRemaining <= RightGunAmmoRemaining() )
        LockLeftSlideBack();
    else
        ResetLeftSlidePosition();
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

simulated function StartTweeningSlide()
{
    bTweeningSlide = true; //start Slide tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

// === RELOAD ================================================================
//allowing +2 reload with full mag
simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if( bBotControlled ) {
        return !bIsReloading && MagAmmoRemaining <= MagCapacity && AmmoAmount(0) > MagAmmoRemaining;
    }

    return !( FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || ClientState == WS_BringUp
            || MagAmmoRemaining >= MagCapacity + 2 || AmmoAmount(0) <= MagAmmoRemaining
            || (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 );
}

exec function ReloadMeNow()
{
    local float ReloadMulti;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;

    if(!AllowReload())
        return;

    KFPC = KFPlayerController(Instigator.Controller);
    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    if ( bHasAimingMode && bAimingRifle )  {
        FireMode[1].bIsFiring = False;
        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        ReloadMulti = KFPRI.ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPRI, self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    if ( MagAmmoRemaining <= 0 ) {
        TacticalReload = 0;
        ReloadRate = default.ReloadRate / ReloadMulti;
    }
    else if ( MagAmmoRemaining == LeftGunAmmoRemaining ) {
        TacticalReload = 1;
        ReloadRate = default.ReloadHalfShortRate / ReloadMulti;
    }
    else {
        TacticalReload = 2;
        ReloadRate = default.ReloadShortRate / ReloadMulti;
    }
    ReloadTimer = Level.TimeSeconds + ReloadRate;

    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);

    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPC != none
            && Level.TimeSeconds - KFPC.LastReloadMessageTime > KFPC.ReloadMessageDelay )
    {
        KFPC.Speech('AUTO', 2, "");
        KFPC.LastReloadMessageTime = Level.TimeSeconds;
    }
}

//added slide offset to reload animation
simulated function ClientReload()
{
    local KFPlayerReplicationInfo KFPRI;
    local float ReloadMulti;

    if ( bHasAimingMode && bAimingRifle ) {
        FireMode[1].bIsFiring = False;
        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if ( KFPRI != none &&KFPRI.ClientVeteranSkill != none )
        ReloadMulti = KFPRI.ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPRI, self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;

    bAnimatingLeftHammer = false;
    bAnimatingRightHammer = false;
    bEnhancedLeftSlideMovement = false;
    bEnhancedRightSlideMovement = false;
    SetBoneRotation( 'Hammer', PistolHammerRotation, , 0); //always reset hammer rotations
    SetBoneRotation( 'Hammer01', PistolHammerRotation, , 0); //always reset hammer rotations

    if ( MagAmmoRemaining <= 0 ) {
        TacticalReload = 0;
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
    else if ( MagAmmoRemaining == LeftGunAmmoRemaining ) {
        TacticalReload = 1;
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
    else {
        TacticalReload = 2;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Slide', PistolSlideOffset, 100 ); //move slide forward
        SetBoneLocation( 'Slide01', PistolSlideOffset, 100 ); //move slide forward
        bTweenLeftSlide = true;
        bTweenRightSlide = true;
    }
}

function ActuallyFinishReloading()
{
   bDoSingleReload=false;
   // no need to replicate ClientFinishReloading, it gets called on the client side by ClientReplicateAmmo
   // ClientFinishReloading();
   // bReloadEffectDone = false;
   AddReloadedAmmo();
   bIsReloading = false;
}

function AddReloadedAmmo()
{
    local PlayerController PC;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    MagAmmoRemaining = min(MagCapacity + TacticalReload, AmmoAmount(0));
    LeftGunAmmoRemaining = (MagAmmoRemaining + 1) / 2;
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
    ClientReplicateAmmo(MagAmmoRemaining, LeftGunAmmoRemaining, a, a >> 8);
}

simulated protected function ClientReplicateAmmo(byte SrvMagAmmoRemaining, byte SrvLeftGunAmmoRemaining,
        byte SrvAmmoAmountLow, byte SrvAmmoAmountHigh)
{
    MagAmmoRemaining = SrvMagAmmoRemaining;
    LeftGunAmmoRemaining = SrvLeftGunAmmoRemaining;
    ClientForceAmmoUpdate(0, (SrvAmmoAmountHigh << 8) | SrvAmmoAmountLow);

    if ( bIsReloading ) {
        ClientFinishReloading();
    }
    else {
        SetSlidePositions();
    }
    SetPistolFireOrder();
}

//after reload tween slide back if tactical reload
simulated function ClientFinishReloading()
{
    bIsReloading = false;
    PlayIdle();

    RotateHammersBack(); //always
    if( TacticalReload > 0 ) {
        StartTweeningSlide(); //allow tweening of both slides
        if (TacticalReload == 1) {
            // only left should tweening
            ResetRightSlidePosition();
        }
    }
    else {
        ResetLeftSlidePosition(); //reset left slide position
        ResetRightSlidePosition(); //reset right slide position
    }

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}


defaultproperties
{
    MagCapacity=14
    MagAmmoRemaining=14
    LeftGunAmmoRemaining=7
    ReloadShortRate = 2.9333 //no slides locked back
    ReloadHalfShortRate = 3.2333 //right slide locked back
    ReloadRate=3.500000 //default
    PistolSlideOffset=(X=0.01970,Y=0.0,Z=0.0)
    PistolHammerRotation=(Pitch=120,Yaw=0,Roll=0) //tripwire why did you do this
    DefaultHammerRotateRate = 0.04
    DefaultHammerRotateMult = 1.0
    Weight=6.000000
    FireModeClass(0)=class'ScrnDualDeagleFire'
    DemoReplacement=class'ScrnDeagle'
    InventoryGroup=3
    PickupClass=class'ScrnDualDeaglePickup'
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
    Priority=130
}
