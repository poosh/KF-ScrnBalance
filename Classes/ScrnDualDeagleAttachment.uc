class ScrnDualDeagleAttachment extends ScrnDualiesAttachment;

simulated function UpdateTacBeam( float Dist );
simulated function TacBeamGone();

defaultproperties
{
    BrotherMesh=SkeletalMesh'KF_Weapons3rd_Trip.Handcannon_3rd'
    mTracerClass=Class'KFMod.KFLargeTracer'
    bHeavy=True
    SplashEffect=Class'ROEffects.BulletSplashEmitter'
    CullDistance=5000.000000
    Mesh=SkeletalMesh'KF_Weapons3rd_Trip.Handcannon_3rd'
}
