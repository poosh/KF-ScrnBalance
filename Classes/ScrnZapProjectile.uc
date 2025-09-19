class ScrnZapProjectile extends ScrnRocketProjectile;


simulated function ProcessExplosionFX(Emitter Explosion)
{
    ZEDMKIISecondaryProjectileExplosion(Explosion).ExplosionRadius = DamageRadius;
}


defaultproperties
{
    Func=class'ScrnZapFunc'
    ExplosionClass=Class'KFMod.ZEDMKIISecondaryProjectileExplosion'
    TracerClass=Class'KFMod.ZEDMKIISecondaryProjectileTrail'
    ExplosionSoundVolume=1.650000
    ArmDistSquared=0.000000
    StaticMeshRef="ZED_FX_SM.Energy.ZED_FX_Energy_Card"
    ExplosionSoundRef="KF_FY_ZEDV2SND.WEP_ZEDV2_Secondary_Explode"
    AmbientSoundRef="KF_FY_ZEDV2SND.WEP_ZEDV2_Secondary_Projectile_LP"
    AmbientVolumeScale=2.500000
    Speed=1000.000000
    MaxSpeed=1000.000000
    bDoubleDamageOnImpact=false
    Damage=1.5  // ZapAmount
    DamageRadius=300.000000
    MyDamageType=Class'KFMod.DamTypeZEDGunMKII'
    ExplosionDecal=Class'KFMod.FlameThrowerBurnMark_Medium'
    LightType=LT_Steady
    LightHue=128
    LightSaturation=64
    LightBrightness=255.000000
    LightRadius=8.000000
    LightCone=16
    bDynamicLight=True
    DrawScale=4.000000
    AmbientGlow=254
    bUnlit=True
}