/**
 * Laser beam effect for a third person laser site
 * Implemented another color mode: Green laser
 * @author PooSH, 2012
 */

class ScrnLaserBeamEffect extends LaserBeamEffect
    dependson(ScrnLaserDot)
    config(user);

#exec OBJ LOAD FILE=ScrnTex.utx

var     class<LaserDot>                    LaserDotClass;

var ScrnLaserDot.ELaserColor LaserColor;
var protected transient ScrnLaserDot.ELaserColor CurrentLaserColor;


var KFWeaponAttachment MyAttachment; // where to attach myself?
var name MyAttachmentBone; // bone name of MyAttachment to attach myself

replication
{
    reliable if ( bNetInitial && !bNetOwner && Role == ROLE_Authority )
        MyAttachment, MyAttachmentBone;
        
    reliable if ( !bNetOwner && Role == ROLE_Authority )
        LaserColor;
}

simulated function PostNetReceive()
{
    if ( Role < ROLE_Authority && LaserColor != CurrentLaserColor ) {
        if ( LaserColor == LASER_Destroyed ) {
            if ( Spot != none )
                Spot.Destroy();
            Destroy();
            return;
        }
    
        if ( ScrnPlayerController(Level.GetLocalPlayerController()) != none 
                && ScrnPlayerController(Level.GetLocalPlayerController()).bOtherPlayerLasersBlue ) {
            SetLaserColor(LASER_Blue);
        }
        else {
            SetLaserColor(LaserColor);
        }
    }
    super.PostNetReceive();
}

// replicate to clients and destroy
function DelayedDestroy()
{
    if ( Spot != none )
        Spot.Destroy();    
    SetLaserColor(LASER_Destroyed);
    bHidden = true; // just in case
    NetUpdateTime = Level.TimeSeconds - 1;
    SetTimer(1.0, false);
}

function Timer()
{
    Destroy();
}

simulated function SpawnDot()
{
    //spawn this dot only for 3-rd person actor
    if (!Instigator.IsLocallyControlled()) {
        if (Spot == None)
            Spot = Spawn(LaserDotClass, self);
        ScrnLaserDot(Spot).SetLaserColor(LaserColor);
    }
}

//no need to simulate, because beam is seen only for others 
simulated function SetLaserColor(ScrnLaserDot.ELaserColor NewLaserColor)
{
    local bool bActivate;
    
    LaserColor = NewLaserColor;
    CurrentLaserColor = NewLaserColor;
    
    bActivate = true;
    switch (NewLaserColor) {
        case LASER_Red:
            Skins[0]=Texture'ScrnTex.Laser.Laser_Red';
            break;
        case LASER_Green:
            Skins[0]=Texture'ScrnTex.Laser.Laser_Green';
            break;
        case LASER_Blue:
            Skins[0]=Texture'ScrnTex.Laser.Laser_Blue';
            break;
        case LASER_Orange:
            Skins[0]=Texture'ScrnTex.Laser.Laser_Orange';
            break;
        default:
            bActivate = false;
    }
    SetActive(bActivate);
    
    if (Spot != None) 
        ScrnLaserDot(Spot).SetLaserColor(NewLaserColor);
}

// copy-pasted with add off SpawnDot()
simulated function Tick(float dt)
{
    local Vector BeamDir;
    local rotator NewRotation;
    local float LaserDist;
    
    if ( LaserColor == LASER_Destroyed )
        return;

    if (Role == ROLE_Authority && (Instigator == None || Instigator.Controller == None || Instigator.Weapon != Owner) )
    {
        DelayedDestroy();
        return;
    }

    // set beam start location
    if ( Instigator == None || (Instigator.Weapon != none && Instigator.IsFirstPerson()) 
            || MyAttachment == none || (Level.TimeSeconds - MyAttachment.LastRenderTime) > 1 )
    {      
       // hide beam, if Instigator or 3rd person weapon attachment are not replecated yet or irrelevant
       bHidden = true;
    }
    else {
        bHidden=!bLaserActive;
        if( bLaserActive && Spot == none && Level.NetMode != NM_DedicatedServer )
            SpawnDot(); //spawn dot of LaserDotClass

        LaserDist = VSize(EndBeamEffect - StartEffect);
        if( LaserDist > 100 )
            LaserDist = 100;
        else
            LaserDist *= 0.5;

        StartEffect= MyAttachment.GetTipLocation();
        NewRotation = Rotator(-MyAttachment.GetBoneCoords(MyAttachmentBone).XAxis);
        SetLocation( StartEffect + MyAttachment.GetBoneCoords(MyAttachmentBone).XAxis * LaserDist );
    }

    BeamDir = Normal(StartEffect - Location);
    SetRotation(NewRotation);

    mSpawnVecA = StartEffect;


    if (Spot != None) {
        Spot.bHidden = bHidden;
        
        if ( !bHidden ) {
            Spot.SetLocation(EndBeamEffect + BeamDir * SpotProjectorPullback);
            if( EffectHitNormal == vect(0,0,0) )
                Spot.SetRotation(Rotator(-BeamDir));
            else
                Spot.SetRotation(Rotator(-EffectHitNormal));
        }
    }
}

defaultproperties
{
     LaserDotClass=Class'ScrnBalanceSrv.ScrnLaserDot'
     MyAttachmentBone="tip"
     Skins(0)=Texture'ScrnTex.Laser.Laser_Blue'
     //bAlwaysRelevant=True
}
