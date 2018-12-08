class ScrnBenelliShotgun extends BenelliShotgun;

var bool bChamberThisReload; //if full reload is uninterrupted, play chambering animation
var vector ReloadViewOffset, ReloadViewOffsetInterp, ReloadViewOffsetValue, TargetViewOffset; //offset used during reloads
var float ReloadTweenStartTime, ReloadTweenEndTime, ReloadTweenRate;

//copypaste from Scrn M14 and vanilla M14 for laser
var         LaserDot                    Spot;                       // The first person laser site dot
var()       float                       SpotProjectorPullback;      // Amount to pull back the laser dot projector from the hit location
var         bool                        bLaserActive;               // The laser site is active
var         LaserBeamEffect             Beam;                       // Third person laser beam effect

var()		class<InventoryAttachment>	LaserAttachmentClass;      // First person laser attachment class
var 		Actor 						LaserAttachment;           // First person laser attachment

var()    byte                                LaserType;       //current laser type
var const class<ScrnLocalLaserDot>          LaserDotClass;
var     ScrnLocalLaserDot                   LaserDot;
var     name                                LaserAttachmentBone;
var         float                         FireSpotRenrerTime;

//laser stuff
replication
{
    reliable if(Role < ROLE_Authority)
        ServerSetLaserType;
}

simulated function Destroyed()
{
	if (Spot != None)
		Spot.Destroy();

	if (Beam != None)
		Beam.Destroy();

    if (LaserDot != None)
        LaserDot.Destroy();

    if (LaserAttachment != None)
        LaserAttachment.Destroy();

    super(KFWeapon).Destroyed();
}

//bring Laser to current state, which is indicating by LaserType
simulated function ApplyLaserState()
{
    //bLaserActive = LaserType > 0;
    LaserType = 1; //always red laser
    bLaserActive = LaserType > 0;
    if( Role < ROLE_Authority  )
        ServerSetLaserType(LaserType);

    if ( ThirdPersonActor != none )
        ScrnLaserWeaponAttachment(ThirdPersonActor).SetLaserType(LaserType);

    if ( !Instigator.IsLocallyControlled() )
        return;

    if( bLaserActive ) {
        if ( LaserDot == none )
            LaserDot = Spawn(LaserDotClass, self);
        LaserDot.SetLaserType(LaserType);
        //spawn 1-st person laser attachment for weapon owner
        if ( LaserAttachment == none ) {
            LaserAttachment = Spawn(LaserAttachmentClass,,,,);
            AttachToBone(LaserAttachment, LaserAttachmentBone);
        }
        ConstantColor'ScrnTex.Laser.LaserColor'.Color =
            LaserDot.GetLaserColor(); // LaserAttachment's color
        LaserAttachment.bHidden = false;

    }
    else {
        if ( LaserAttachment != none )
            LaserAttachment.bHidden = true;
        if ( LaserDot != none )
            LaserDot.Destroy(); //bHidden = true;
    }
}

// Toggle laser modes: RED/GREEN/OFF
simulated function ToggleLaser()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    if ( (++LaserType) > 2 )
        LaserType = 0;
    ApplyLaserState();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    ApplyLaserState();
    Super.BringUp(PrevWeapon);
    if ( Level.NetMode != NM_DedicatedServer )
    {
        ReloadViewOffset = Vect(0,0,0);
    }
}

simulated function ClientReload()
{
    bChamberThisReload = ( MagAmmoRemaining == 0 && (AmmoAmount(0) - MagAmmoRemaining > MagCapacity) ); //for chambering animation
    Super.ClientReload();
    TargetViewOffset = ReloadViewOffsetValue;
    ReloadTweenStartTime = Level.TimeSeconds;
    ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
    ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
}

// Set the new fire mode on the server
function ServerSetLaserType(byte NewLaserType)
{
    LaserType = NewLaserType;
    bLaserActive = NewLaserType > 0;
    ScrnLaserWeaponAttachment(ThirdPersonActor).SetLaserType(LaserType);
}

simulated function bool PutDown()
{
    TurnOffLaser();
    if( Instigator.IsLocallyControlled() )
    {
        //don't do this stuff on dedicated servers
        TargetViewOffset = Vect(0,0,0);
        ReloadTweenStartTime = Level.TimeSeconds;
        ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
        ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
    }
    return super(KFWeapon).PutDown();
}

simulated function TurnOffLaser()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    if( Role < ROLE_Authority  )
        ServerSetLaserType(0);

    bLaserActive = false;
    //don't change Laser type here, because we need to restore it state
    //when next time weapon will be bringed up
    if ( LaserAttachment != none )
        LaserAttachment.bHidden = true;
    if (LaserDot != None)
        LaserDot.Destroy();
}

//tweens to reload offset when reloading and tweens back to 0,0,0 when reload ends or is interrupted by zoom or fire
simulated function TweenToReloadOffset()
{
    local float Alpha; //for lerp
    if (ReloadTweenEndTime == 0)
    {
        return; //do nothing
    }
    if (Level.TimeSeconds > ReloadTweenEndTime)
    {
        ReloadViewOffset = TargetViewOffset; //set target
        ReloadTweenEndTime = 0; //set this to 0
    }
    Alpha = (Level.TimeSeconds-ReloadTweenStartTime)/ReloadTweenRate; //returns float between 0 and 1
    if ( Level.NetMode != NM_DedicatedServer )
    {
        //lerp from current interp value to target
        ReloadViewOffset.X = Lerp(Alpha, ReloadViewOffsetInterp.X, TargetViewOffset.X);
        ReloadViewOffset.Y = Lerp(Alpha, ReloadViewOffsetInterp.Y, TargetViewOffset.Y);
        ReloadViewOffset.Z = Lerp(Alpha, ReloadViewOffsetInterp.Z, TargetViewOffset.Z);
    }
}

//added function to calculate and apply reload view offset
simulated function WeaponTick(float dt)
{
    Super.WeaponTick(dt);
    TweenToReloadOffset();
}

// Server forces the reload to be cancelled
simulated function bool InterruptReload()
{
    //solo testing kek
    if ( Level.NetMode != NM_DedicatedServer )
	{
        TargetViewOffset = Vect(0,0,0);
        ReloadTweenStartTime = Level.TimeSeconds;
        ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
        ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
	}
    return Super.InterruptReload();
}

//supports laser and reload view offset
simulated function RenderOverlays( Canvas Canvas )
{
    local vector DrawOffset;
    local int i;
    local Vector StartTrace, EndTrace;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local vector X,Y,Z;
    local coords C;
    local KFShotgunFire KFSGM;
    local array<Actor> HitActors;

    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for ( i = 0; i < NUM_FIRE_MODES; ++i ) {
        if (FireMode[i] != None)
            FireMode[i].DrawMuzzleFlash(Canvas);
    }

    DrawOffset = (90/DisplayFOV * ReloadViewOffset) >> Instigator.GetViewRotation(); //calculate additional offset
    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) + DrawOffset); //add additional offset
    SetRotation( Instigator.GetViewRotation() + ZoomRotInterp);

    KFSGM = KFShotgunFire(FireMode[0]);

    // Handle drawing the laser dot
    if ( LaserDot != None )
    {
        //move LaserDot during fire animation too  -- PooSH
        if( bIsReloading || (Level.TimeSeconds < KFSGM.LastClickTime + FireSpotRenrerTime) )
        {
            C = GetBoneCoords(LaserAttachmentBone);
            X = C.XAxis;
            Y = C.YAxis;
            Z = C.ZAxis;
        }
        else
            GetViewAxes(X, Y, Z);

        StartTrace = Instigator.Location + Instigator.EyePosition();
        EndTrace = StartTrace + 65535 * X; //65535

        while (true) {
            Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
            if ( ROBulletWhipAttachment(Other) != none ) {
                HitActors[HitActors.Length] = Other;
                Other.SetCollision(false);
                StartTrace = HitLocation + X;
            }
            else {
                if (Other != None && Other != Instigator && Other.Base != Instigator )
                    EndBeamEffect = HitLocation;
                else
                    EndBeamEffect = EndTrace;
                break;
            }
        }
        // restore collision
        for ( i=0; i<HitActors.Length; ++i )
            HitActors[i].SetCollision(true);

        LaserDot.SetLocation(EndBeamEffect - X*LaserDot.ProjectorPullback);

        if(  Pawn(Other) != none ) {
            LaserDot.SetRotation(Rotator(X));
            LaserDot.SetDrawScale(LaserDot.default.DrawScale * 0.5);
        }
        else if( HitNormal == vect(0,0,0) ) {
            LaserDot.SetRotation(Rotator(-X));
            LaserDot.SetDrawScale(LaserDot.default.DrawScale);
        }
        else {
            LaserDot.SetRotation(Rotator(-HitNormal));
            LaserDot.SetDrawScale(LaserDot.default.DrawScale);
        }
    }

    //PreDrawFPWeapon();    // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;

    //do reload tween stuff
    TargetViewOffset = Vect(0,0,0);
    ReloadTweenStartTime = Level.TimeSeconds;
    ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
    ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation

    //play chambering animation if finished reloading from empty
    if ( !bChamberThisReload )
    {
        PlayIdle();
    }
    bChamberThisReload = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

defaultproperties
{
     ReloadRate=0.750000
     ReloadAnimRate=1.074 //1.200000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBenelliFire'
     Description="A military tactical shotgun with semi automatic fire capability. Holds up to 6 shells. Special shell construction allow pellets to penetrate fat much easier."
     PickupClass=Class'ScrnBalanceSrv.ScrnBenelliPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnBenelliAttachment' //New attachment to fix broken BenelliAttachment class
     ItemName="Combat Shotgun SE"
     PlayerViewPivot=(Pitch=-47,Roll=0,Yaw=-5) //fix to make sight centered
     ReloadViewOffset=(X=0.000000,Y=0.000000,Z=0.000000) //reload offset to get the weapon away from the center of the screen while reloading
     ReloadViewOffsetValue=(X=10.000000,Y=-5.000000,Z=-10.000000) //used to store the vector values
     ReloadTweenRate = 0.2 //little less than zoomtime

     //laser stuff
     LaserAttachmentBone="LightBone"
     LaserDotClass=Class'ScrnBalanceSrv.ScrnLocalLaserDot'
     LaserAttachmentClass=Class'ScrnBalanceSrv.ScrnLaserAttachmentFirstPerson'
     FireSpotRenrerTime=1.5

     ModeSwitchAnim="LightOn"
}
