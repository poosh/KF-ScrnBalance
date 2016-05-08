class ScrnDamTypeDefaultSupportBase extends KFProjectileWeaponDamageType
    abstract;

    
defaultproperties
{
    bIsPowerWeapon=True
    WeaponClass=Class'KFMod.Shotgun'
    DeathString="%k killed %o (Shotgun)."
    FemaleSuicide="%o shot herself in the foot."
    MaleSuicide="%o shot himself in the foot."
    bRagdollBullet=True
    bBulletHit=True
    FlashFog=(X=600.000000)
    KDamageImpulse=10000.000000
    KDeathVel=300.000000
    KDeathUpKick=100.000000
    VehicleDamageScaling=0.700000
}