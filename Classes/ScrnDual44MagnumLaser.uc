/**
 * Dual-Magnum 44 with attached laser sights 
 *
 * @author PooSH, 2012-2013
 */

class ScrnDual44MagnumLaser extends ScrnDual44Magnum
dependson(ScrnLaserDot)
config(user);

var         ScrnLaserDot                Spot, LeftSpot;             // The first person laser site dot
var()       float                       SpotProjectorPullback;      // Amount to pull back the laser dot projector from the hit location
var         bool                        bLaserActive;               // The laser site is active
var         ScrnLaserBeamEffect         Beam, Beam2;                       // Third person laser beam effect

var()       class<InventoryAttachment>  LaserAttachmentClass;      // First person laser attachment class
var         Actor                       LaserAttachment, LeftLaserAttachment;           // First person laser attachment

var         ScrnLaserDot.ELaserColor    LaserType;       //current laser type
var         class<ScrnLaserBeamEffect>  LaserBeamClass;  
var         class<ScrnLaserDot>         LaserDotClass;

var         bool bCowboyMode;

var 		float 						FireSpotRenrerTime; 		// how long to render spot after weapon fire (after that spot will be put in the center of the screen)


replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        bCowboyMode;

    reliable if(Role < ROLE_Authority)
        ServerSetLaserType;
}

function SpawnBeam()
{
    if ( Beam == None )
        Beam = Spawn(LaserBeamClass, self);    
	if ( Beam2 == None )
        Beam2 = Spawn(LaserBeamClass, self);
    
    if ( Beam != none ) {
        Beam.MyAttachment = KFWeaponAttachment(ThirdPersonActor);
    }
    if ( Beam2 != none ) {
        Beam2.MyAttachment = KFWeaponAttachment(altThirdPersonActor);
    }
}

function DestroyBeam()
{
    if (Beam != None)
        Beam.DelayedDestroy();    
	if (Beam2 == None)
        Beam2.DelayedDestroy();
}


simulated function SpawnDot()
{
    if (Spot == None)
        Spot = Spawn(LaserDotClass, self);
    //set dot texture
    Spot.SetLaserColor(LaserType);  

    if (LeftSpot == None)
        LeftSpot = Spawn(LaserDotClass, self);
    //set dot texture
    LeftSpot.SetLaserColor(LaserType);	
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Role == ROLE_Authority) 
        SpawnBeam();
}

simulated function Destroyed()
{
    if (Spot != None)
        Spot.Destroy();    
	if (LeftSpot != None)
        LeftSpot.Destroy();

	DestroyBeam();

    if (LaserAttachment != None)
        LaserAttachment.Destroy();
    if (LeftLaserAttachment != None)
        LeftLaserAttachment.Destroy();

    super.Destroyed();
}

// Use alt fire to switch laser type
simulated function AltFire(float F)
{
    if(ReadyToFire(0))
    {
        ToggleLaser();
    }
}

// Cowboys don't use moder stuff like laser sights
// If laser is turned on, cowboy mode will be prohibited until the next reload
//if player turned off laser before reloading, enable CobwoyMode again
function AddReloadedAmmo()
{
    bCowboyMode = ! bLaserActive;

    super.AddReloadedAmmo();
}

simulated function WeaponTick(float dt)
{
    local Vector StartTrace, EndTrace, X,Y,Z;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local vector MyEndBeamEffect;
    local coords C;

    super.WeaponTick(dt);

    if( Role == ROLE_Authority) {
		if ( Beam != none ) {
			if( bIsReloading && Beam.MyAttachment != none ) {
				C = Beam.MyAttachment.GetBoneCoords(Beam.MyAttachmentBone);
				X = C.XAxis;
				Y = C.YAxis;
				Z = C.ZAxis;
			}
			else
				GetViewAxes(X,Y,Z);

			// the to-hit trace always starts right in front of the eye
			StartTrace = Instigator.Location + Instigator.EyePosition() + X*Instigator.CollisionRadius;

			EndTrace = StartTrace + 65535 * X;

			Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

			if (Other != None && Other != Instigator && Other.Base != Instigator )
				MyEndBeamEffect = HitLocation;
			else
				MyEndBeamEffect = EndTrace;

			Beam.EndBeamEffect = MyEndBeamEffect;
			Beam.EffectHitNormal = HitNormal;
		}
		if ( Beam2 != none ) {
			if( bIsReloading && Beam2.MyAttachment != none ) {
				C = Beam2.MyAttachment.GetBoneCoords(Beam2.MyAttachmentBone);
				X = C.XAxis;
				Y = C.YAxis;
				Z = C.ZAxis;
			}
			else
				GetViewAxes(X,Y,Z);

			// the to-hit trace always starts right in front of the eye
			StartTrace = Instigator.Location + Instigator.EyePosition() + X*Instigator.CollisionRadius;

			EndTrace = StartTrace + 65535 * X;

			Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

			if (Other != None && Other != Instigator && Other.Base != Instigator )
				MyEndBeamEffect = HitLocation;
			else
				MyEndBeamEffect = EndTrace;

			Beam2.EndBeamEffect = MyEndBeamEffect;
			Beam2.EffectHitNormal = HitNormal;
		}	
    }
}

//bring Laser to current state, which is indicating by LaserType 
simulated function ApplyLaserState()
{
    if( !Instigator.IsLocallyControlled() ) 
		return;
		
    if( Role < ROLE_Authority  ) {
        ServerSetLaserType(LaserType);
    }
    bLaserActive = LaserType != LASER_None;
    if ( bLaserActive ) bCowboyMode = false;

    if( Beam != none )
        Beam.SetLaserColor(LaserType);
    if( Beam2 != none )
        Beam2.SetLaserColor(LaserType);

    if( bLaserActive ) {
        //spawn 1-st person laser attachment for weapon owner
        ConstantColor'ScrnTex.Laser.LaserColor'.Color = 
            class'ScrnLaserDot'.static.GetLaserColor(LaserType);
        
        if ( LaserAttachment == none ) {
            //Log("Magnum44 Bone rotation = " $ GetBoneRotation('Tip_Right'));
            LaserAttachment = Spawn(LaserAttachmentClass,self,,,);
            AttachToBone(LaserAttachment,'Tip_Right');
        }
        LaserAttachment.bHidden = false;
		
        if ( LeftLaserAttachment == none ) {
            //Log("Magnum44 Bone rotation = " $ GetBoneRotation('Tip_Right'));
            LeftLaserAttachment = Spawn(LaserAttachmentClass,self,,,);
            AttachToBone(LeftLaserAttachment,'Tip_Left');
        }
        LeftLaserAttachment.bHidden = false;		

        SpawnDot();
    }
    else {
        if ( LaserAttachment != none ) 
            LaserAttachment.bHidden = true;
        if ( LeftLaserAttachment != none ) 
            LeftLaserAttachment.bHidden = true;
        if (Spot != None) 
            Spot.Destroy();
        if (LeftSpot != None) 
            LeftSpot.Destroy();
    }
}
// Toggle laser on or off
simulated function ToggleLaser()
{
    if( !Instigator.IsLocallyControlled() ) return;

    if (bLaserActive) LaserType = LASER_None;
    else LaserType = LASER_Orange;

    ApplyLaserState();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    if (Role == ROLE_Authority)
        SpawnBeam();
        
    ApplyLaserState();
    Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
    TurnOffLaser();
	DestroyBeam();

    return super.PutDown();
}

simulated function DetachFromPawn(Pawn P)
{
    TurnOffLaser();

    Super.DetachFromPawn(P);

	DestroyBeam();
}

simulated function TurnOffLaser()
{
    if( !Instigator.IsLocallyControlled() )
        return;

        if( Role < ROLE_Authority  ) {
            ServerSetLaserType(LASER_None);
        }

        bLaserActive = false;
        //don't change Laser type here, because we need to restore it state 
        //when next time weapon will be brought up
        if ( LaserAttachment != none )
            LaserAttachment.bHidden = true;
        if ( LeftLaserAttachment != none )
            LeftLaserAttachment.bHidden = true;

        if( Beam != none )
            Beam.SetActive(false);
        if( Beam2 != none )
            Beam2.SetActive(false);

        if (Spot != None)
            Spot.Destroy();
        if (LeftSpot != None)
            LeftSpot.Destroy();
}



// Set the new fire mode on the server
function ServerSetLaserType(ScrnLaserDot.ELaserColor NewLaserType)
{
    LaserType = NewLaserType;
    bLaserActive = NewLaserType != LASER_None;
    if ( bLaserActive ) 
        bCowboyMode = false;

    if( NewLaserType != LASER_None )
    {
        SpawnBeam();
        if( Beam != none )
            Beam.SetLaserColor(NewLaserType);
        if( Beam2 != none )
            Beam2.SetLaserColor(NewLaserType);

        bLaserActive = true;
        SpawnDot();
    }
    else  {
        if( Beam != none )
            Beam.SetLaserColor(LASER_None);
        if( Beam2 != none )
            Beam2.SetLaserColor(LASER_None);      
            
        bLaserActive = false;
        if (Spot != None)
            Spot.Destroy();
        if (LeftSpot != None)
            LeftSpot.Destroy();
    }
}


//copy-pasted from M14EBR
simulated function RenderOverlays( Canvas Canvas )
{
    local int m;
    local Vector StartTrace, EndTrace;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local vector X,Y,Z;
    local coords C;
	local KFFire KFM;

    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != None)
        {
            FireMode[m].DrawMuzzleFlash(Canvas);
        }
    }
	
	KFM = KFFire(FireMode[0]);

    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
    SetRotation( Instigator.GetViewRotation() + ZoomRotInterp);

    // Handle drawing the laser dot
    if (Spot != None)
    {
        StartTrace = Instigator.Location + Instigator.EyePosition();
        GetViewAxes(X, Y, Z);

        //move spot on weapon recoil too -- PooSH
        if( Instigator.IsLocallyControlled() && (bIsReloading || (Level.TimeSeconds < KFM.LastFireTime + FireSpotRenrerTime
			&& ( (!bAimingRifle && KFM.FireAnim == 'FireLeft') 
				 || (bAimingRifle && KFM.FireAimedAnim == 'FireLeft_Iron') ) )) )
        {
            C = GetBoneCoords('Tip_Right');
            X = C.XAxis;
            Y = C.YAxis;
            Z = C.ZAxis;
        }

        EndTrace = StartTrace + 65535 * X;

        Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

        if (Other != None && Other != Instigator && Other.Base != Instigator )
        {
            EndBeamEffect = HitLocation;
        }
        else
        {
            EndBeamEffect = EndTrace;
        }

        Spot.SetLocation(EndBeamEffect - X*SpotProjectorPullback);

        if(  Pawn(Other) != none )
        {
            Spot.SetRotation(Rotator(X));
            Spot.SetDrawScale(Spot.default.DrawScale * 0.5);
        }
        else if( HitNormal == vect(0,0,0) )
        {
            Spot.SetRotation(Rotator(-X));
            Spot.SetDrawScale(Spot.default.DrawScale);
        }
        else
        {
            Spot.SetRotation(Rotator(-HitNormal));
            Spot.SetDrawScale(Spot.default.DrawScale);
        }
    }
    if (LeftSpot != None)
    {
        StartTrace = Instigator.Location + Instigator.EyePosition();
        GetViewAxes(X, Y, Z);

        //move LeftSpot on weapon recoil too -- PooSH
        if( Instigator.IsLocallyControlled() && (bIsReloading || (Level.TimeSeconds < KFM.LastFireTime + FireSpotRenrerTime
			&& ( (!bAimingRifle && KFM.FireAnim == 'FireRight') 
				 || (bAimingRifle && KFM.FireAimedAnim == 'FireRight_Iron') ) )) )
        {
            C = GetBoneCoords('Tip_Left');
            X = C.XAxis;
            Y = C.YAxis;
            Z = C.ZAxis;
        }

        EndTrace = StartTrace + 65535 * X;

        Other = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

        if (Other != None && Other != Instigator && Other.Base != Instigator )
        {
            EndBeamEffect = HitLocation;
        }
        else
        {
            EndBeamEffect = EndTrace;
        }

        LeftSpot.SetLocation(EndBeamEffect - X*SpotProjectorPullback);

        if(  Pawn(Other) != none )
        {
            LeftSpot.SetRotation(Rotator(X));
            LeftSpot.SetDrawScale(LeftSpot.default.DrawScale * 0.5);
        }
        else if( HitNormal == vect(0,0,0) )
        {
            LeftSpot.SetRotation(Rotator(-X));
            LeftSpot.SetDrawScale(LeftSpot.default.DrawScale);
        }
        else
        {
            LeftSpot.SetRotation(Rotator(-HitNormal));
            LeftSpot.SetDrawScale(LeftSpot.default.DrawScale);
        }
    }	

    //PreDrawFPWeapon();    // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
}

//copy-pasted from M14EBR
exec function SwitchModes()
{
    ToggleLaser();
}

//copy-pasted from M14EBR
simulated function SetZoomBlendColor(Canvas c)
{
    local Byte    val;
    local Color   clr;
    local Color   fog;

    clr.R = 255;
    clr.G = 255;
    clr.B = 255;
    clr.A = 255;

    if( Instigator.Region.Zone.bDistanceFog )
    {
        fog = Instigator.Region.Zone.DistanceFogColor;
        val = 0;
        val = Max( val, fog.R);
        val = Max( val, fog.G);
        val = Max( val, fog.B);
        if( val > 128 )
        {
            val -= 128;
            clr.R -= val;
            clr.G -= val;
            clr.B -= val;
        }
    }
    c.DrawColor = clr;
}


function bool HandlePickupQuery( pickup Item )
{
	if ( ClassIsChildOf(Item.InventoryType, Class'Magnum44Pistol') || ClassIsChildOf(Item.InventoryType, Class'Dual44Magnum') )
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
    //just drop this weapon, don't split it on single guns
    super(KFWeapon).DropFrom(StartLocation);
}
    
function GiveTo( pawn Other, optional Pickup Pickup )
{
	local Inventory Inv;
    local KFWeapon W;
	local int AmmoToAdd;
    local int count;

    // when picking up laser dual-44, destroy all magnums (single or duals)
    // found in inventory, saving their ammo first
    Inv = Other.Inventory;
    while ( Inv != none && ++count < 1000 ) {
        W = KFWeapon(Inv);
        if ( W!= none && (Magnum44Pistol(W) != none || Dual44Magnum(W) != none) ) {
            AmmoToAdd += W.AmmoAmount(0);
            // first get next inventory, next - destroy
            Inv = W.Inventory;
            W.Destroyed();
            W.Destroy();
        }
        else {
            Inv = Inv.Inventory;
        }
	}
    
    if ( WeaponPickup(Pickup) != none ) {
        WeaponPickup(Pickup).AmmoAmount[0] += AmmoToAdd;
        AmmoToAdd = 0;
    }

	Super(KFWeapon).GiveTo(Other, Pickup);

	if ( AmmoToAdd > 0 ) {
		AddAmmo(AmmoToAdd, 0);
	}
}

defaultproperties
{
     LaserAttachmentClass=Class'ScrnBalanceSrv.ScrnLaserAttachmentFirstPerson'
     LaserBeamClass=Class'ScrnBalanceSrv.ScrnLaserBeamEffect'
     LaserDotClass=Class'ScrnBalanceSrv.ScrnLaserDot'
     bCowboyMode=True
     ReloadRate=3.500000
     ReloadAnimRate=1.276200
     Weight=5.000000
     bIsTier3Weapon=True
     Description="Yeah! One in each hand! Now with laser attachment."
     DemoReplacement=None
     InventoryGroup=4
     PickupClass=Class'ScrnBalanceSrv.ScrnDual44MagnumLaserPickup'
     ItemName="Laser Dual 44 Magnums"
	 FireSpotRenrerTime=1.0
     MagAmmoRemaining=12
}
