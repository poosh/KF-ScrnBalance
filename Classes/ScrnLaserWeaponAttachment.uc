// Base class for 3rd person weapon attachments with laser sight
// @author PooSH, 2015

class ScrnLaserWeaponAttachment extends KFWeaponAttachment
abstract;

var() const class<ScrnLaserBeam3rd>     BeamClass;
var ScrnLaserBeam3rd                    Beam;
var() name                              LaserAttachmentBone;
var() byte                              LaserType;


replication {
    reliable if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        LaserType;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( Beam == none )
            SpawnBeam();
        SetLaserType(LaserType);
    }
}


simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    SpawnBeam();
}

simulated function Destroyed()
{
    if ( Beam != none )
        Beam.Destroy();
    super.Destroyed();
}

simulated function SpawnBeam()
{
    if ( Beam != none || Level.NetMode == NM_DedicatedServer || Instigator == none /*|| Instigator.IsLocallyControlled()*/ )
        return; // spawn only on clients and only if Instigator is already replicated

    Beam = spawn(BeamClass, self);
    if ( Beam != None ) {
        Beam.MyWeaponAttachment = self;
        Beam.Instigator = Instigator;
        Beam.MyAttachmentBone = LaserAttachmentBone;
        Beam.SetLaserType(LaserType);
    }
}

simulated function byte GetLaserType()
{
    if ( Beam != none )
        return Beam.GetLaserType();
    return LaserType;
}

simulated function SetLaserType(byte value)
{
    LaserType = value;
    if ( Role == ROLE_Authority ) {
        NetUpdateTime = Level.TimeSeconds - 1;
        if ( Level.NetMode != NM_DedicatedServer && Beam == none )
            SpawnBeam(); // spawn beam on listen server
    }
    if ( Beam != none )
        Beam.SetLaserType(value);
}



defaultproperties
{
    LaserAttachmentBone="Tip"
    BeamClass=class'ScrnBalanceSrv.ScrnLaserBeam3rd'
    bNetNotify=True
}
