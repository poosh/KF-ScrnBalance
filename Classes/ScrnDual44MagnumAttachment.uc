class ScrnDual44MagnumAttachment extends ScrnDualiesAttachment;

simulated function UpdateTacBeam( float Dist );
simulated function TacBeamGone();

defaultproperties
{
    BrotherMesh=SkeletalMesh'KF_Weapons3rd3_Trip.revolver_3rd'
    mTracerClass=Class'KFMod.KFLargeTracer'
    mShellCaseEmitterClass=None
    bHeavy=True
    SplashEffect=Class'ROEffects.BulletSplashEmitter'
    CullDistance=5000.000000
    Mesh=SkeletalMesh'KF_Weapons3rd3_Trip.revolver_3rd'
}
