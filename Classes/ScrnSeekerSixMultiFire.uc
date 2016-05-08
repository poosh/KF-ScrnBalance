class ScrnSeekerSixMultiFire extends SeekerSixMultiFire;

defaultproperties
{
	FireRate=1.0
	FireAnimRate=0.33
	AmmoClass=Class'ScrnBalanceSrv.ScrnSeekerSixAmmo'
    // it will be changed in ScrnSeekerSixRocketLauncher.SpawnProjectile(). 
    // put different projectiles for preloading assets
	ProjectileClass=Class'ScrnBalanceSrv.ScrnS6SeekingRocket' 
}