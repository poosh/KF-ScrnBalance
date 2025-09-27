class ScrnM79IncGrenadeProjectile extends ScrnM79GrenadeProjectile;

simulated function ProcessExplosionFX(Emitter Explosion)
{
    Explosion.SetRotation(rotator(vect(0,0,1)));
}


defaultproperties
{
    Func=class'ScrnExplosiveFunc_Burn'
    SmokeTrailClass=class'ScrnFlameNadeTrail'
    ArmDistSquared=2500.000000
    ImpactDamage=50
    ExplosionSoundRef="KF_GrenadeSnd.FlameNade_Explode"
    ExplosionSoundVolume=200
    ExplosionClass=Class'KFIncendiaryExplosion'
    Damage=60
    MyDamageType=Class'KFMod.DamTypeFlameNade'
}
