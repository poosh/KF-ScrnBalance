class ScrnNailGunFireSingle extends ScrnNailGunFire;


defaultproperties
{
    AmmoPerFire=1
    FireRate=0.25
    FireAnimRate=2.0
    Spread=0.20
    maxVerticalRecoilAngle=250
    maxHorizontalRecoilAngle=150
    KickMomentum = vect(0,0,0);
    bFiringDoesntAffectMovement=true

    FireSoundRef="KF_NailShotgun.KF_NailShotgun_Fire_Alt_M"
    StereoFireSoundRef="KF_NailShotgun.KF_NailShotgun_Fire_Alt_S"
}
