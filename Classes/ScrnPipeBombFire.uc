class ScrnPipeBombFire extends PipeBombFire;

function PostSpawnProjectile(Projectile P)
{
     super.PostSpawnProjectile(P);
     ScrnPipeBombExplosive(Weapon).ServerSendCount();
}

defaultproperties
{
     AmmoClass=class'ScrnPipeBombAmmo'
     ProjectileClass=class'ScrnPipeBombProjectile'
}
