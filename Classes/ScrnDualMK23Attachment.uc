class ScrnDualMK23Attachment extends ScrnDualiesAttachment;


simulated function UpdateTacBeam( float Dist );
simulated function TacBeamGone();

defaultproperties
{
    BrotherMesh=SkeletalMesh'KF_Weapons3rd4_Trip.MK23_3rd'
    Mesh=SkeletalMesh'KF_Weapons3rd4_Trip.MK23_3rd'
    bMyFlashTurn=false
    bLastMyTurn=false
}
