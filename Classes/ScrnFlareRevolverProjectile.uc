class ScrnFlareRevolverProjectile extends ScrnFlareProjectile;

defaultproperties
{
    HeadShotDamageMult=1.5  // applied only on burn damage. Impact's headshot mult. is set in damage type
    ImpactDamage=85 // 100
    Damage=30.0 // initial fire damage
    ImpactDamageType=Class'ScrnBalanceSrv.ScrnDamTypeFlareRevolverImpact'
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeFlareRevolver'
}
