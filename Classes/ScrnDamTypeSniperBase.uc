//default damage type for Sharpshooter

class ScrnDamTypeSniperBase extends KFProjectileWeaponDamageType
    abstract;

defaultproperties
{
     bSniperWeapon=True
     DeathString="%k killed %o."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
     bRagdollBullet=True
     bBulletHit=True
     FlashFog=(X=600.000000)
     KDamageImpulse=4500.000000
     KDeathVel=200.000000
     KDeathUpKick=20.000000
     VehicleDamageScaling=0.800000
}
