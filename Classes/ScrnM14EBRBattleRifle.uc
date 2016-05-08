/**
 * M14EBR version with 2 laser sight modes (green/red)
 * and slightly increased headshot multiplier to 1-headshot kill 6p HoE Husks and Sirens
 *
 * @see ScrnDamTypeM14EBR
 * @author PooSH, 2012
 */

class ScrnM14EBRBattleRifle extends M14EBRBattleRifle
dependson(ScrnLaserDot)
    config(user);

var()	ScrnLaserDot.ELaserColor		LaserType; 	  //current laser type
var     class<ScrnLaserBeamEffect>      LaserBeamClass;  
var     class<LaserDot>                	LaserDotClass;

replication
{
	reliable if(Role < ROLE_Authority)
		ServerSetLaserType, LaserType;
}

function SpawnBeam()
{
    if ( Beam != none && ScrnLaserBeamEffect(Beam) == none ) {
        Beam.Destroy();
        Beam = none;
    }
    
	if ( Beam == None )
		Beam = Spawn(LaserBeamClass, self);
        
    if ( Beam != none ) {
        ScrnLaserBeamEffect(Beam).MyAttachment = KFWeaponAttachment(ThirdPersonActor);
    }        
}

function DestroyBeam()
{
    if (Beam != None)
        ScrnLaserBeamEffect(Beam).DelayedDestroy();    
}

simulated function SpawnDot()
{
	if (Spot == None)
		Spot = Spawn(LaserDotClass, self);
	//set dot texture
	ScrnLaserDot(Spot).SetLaserColor(LaserType);		
}

simulated function PostBeginPlay()
{
	super(KFWeapon).PostBeginPlay();

	if (Role == ROLE_Authority) 
		SpawnBeam();
}

// Use alt fire to switch laser type
simulated function AltFire(float F)
{
	//try to allow switching laser while reloading too
	//if(ReadyToFire(0))
	//{
		ToggleLaser();
	//}
}



//bring Laser to current state, which is indicating by LaserType 
simulated function ApplyLaserState()
{
	bLaserActive = LaserType != LASER_None;
	if( Role < ROLE_Authority  ) {
		ServerSetLaserType(LaserType);
	}

	if( Beam != none )
		ScrnLaserBeamEffect(Beam).SetLaserColor(LaserType);

	if( bLaserActive ) {
		//spawn 1-st person laser attachment for weapon owner
		ConstantColor'ScrnTex.Laser.LaserColor'.Color = 
			class'ScrnLaserDot'.static.GetLaserColor(LaserType);
		//LaserAttachment.Destroy();
		if ( LaserAttachment == none ) {
			LaserAttachment = Spawn(LaserAttachmentClass,,,,);
			AttachToBone(LaserAttachment,'LightBone');
		}
		LaserAttachment.bHidden = false;

		SpawnDot();
	}
	else {
		if ( LaserAttachment != none )
			LaserAttachment.bHidden = true;
		if (Spot != None) { 	
			Spot.Destroy();
		}
	}
}
// Toggle laser modes: RED/GREEN/OFF
simulated function ToggleLaser()
{
	if( !Instigator.IsLocallyControlled() ) return;

	switch ( LaserType ) {
		case LASER_None: 
			LaserType = LASER_Red;
			break;
		case LASER_Red: 
			LaserType = LASER_Green;
			break;
		default:
			LaserType = LASER_None;
	}
	ApplyLaserState();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if (Role == ROLE_Authority)
		SpawnBeam();
		
	ApplyLaserState();
	Super.BringUp(PrevWeapon);
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
    //when next time weapon will be bringed up
    if ( LaserAttachment != none )
        LaserAttachment.bHidden = true;

    if( Beam != none )
        Beam.SetActive(false);

    if (Spot != None) {
        Spot.Destroy();
    }
}



// Set the new fire mode on the server
function ServerSetLaserType(ScrnLaserDot.ELaserColor NewLaserType)
{
	if (NewLaserType == LASER_None) 
		bLaserActive = false;
		
	SpawnBeam();
	ScrnLaserBeamEffect(Beam).SetLaserColor(NewLaserType);

	if( NewLaserType != LASER_None )
	{
		bLaserActive = true;
		SpawnDot();
	}
	else
	{
		bLaserActive = false;
		if (Spot != None) {
			Spot.Destroy();
		}
	}
}

simulated function bool PutDown()
{
	TurnOffLaser();
	DestroyBeam();

	return super(KFWeapon).PutDown();
}

simulated function Destroyed()
{
	if (Spot != None)
		Spot.Destroy();

	DestroyBeam();

	if (LaserAttachment != None)
		LaserAttachment.Destroy();

	super(KFWeapon).Destroyed();
}

	

defaultproperties
{
     LaserBeamClass=Class'ScrnBalanceSrv.ScrnLaserBeamEffect'
     LaserDotClass=Class'ScrnBalanceSrv.ScrnLaserDot'
     LaserAttachmentClass=Class'ScrnBalanceSrv.ScrnLaserAttachmentFirstPerson'
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM14EBRFire'
     Description="Updated M14 Enhanced Battle Rifle - Semi Auto variant. Equipped with a laser sight. A special lens allows to change laser's color on the fly."
     PickupClass=Class'ScrnBalanceSrv.ScrnM14EBRPickup'
     ItemName="M14EBR SE"
}
