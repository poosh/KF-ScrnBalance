class ScrnExplosiveFunc_Nade extends ScrnExplosiveFunc abstract;

static function bool HurtVictim(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType, bool bCheckExposure, optional vector ExposureLocation)
{
    ExposureLocation.Z += 25; // raise above debris that a lazy L.D. forgot to disable collision on
    return super.HurtVictim(Proj, Victim, damage, hitlocation, momentum, DamageType, bCheckExposure, ExposureLocation);
}
