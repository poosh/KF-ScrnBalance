// Can't share fire mod classes with many guns, cuz destorying one of them will unload its assets
class ScrnM4203MBulletFire extends ScrnM4203BulletFire;

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeM4203M'
}
