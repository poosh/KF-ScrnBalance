// NAPALM THROWER
class ScrnHuskGunAltFire extends ScrnHuskGunFire;



//instant shot, without holding
function ModeHoldFire() { }
function Charge() { }
function PlayPreFire() { }
function Timer() { }

function class<Projectile> GetDesiredProjectileClass()
{
	return ProjectileClass;
}

function PostSpawnProjectile(Projectile P)
{
	super(KFShotgunFire).PostSpawnProjectile(P); // bypass HuskGunFire
}

simulated function bool AllowFire()
{
	return (Weapon.AmmoAmount(ThisModeNum) >= MaxChargeAmmo);
}

function ModeDoFire()
{
    if (!AllowFire())
        return;
        
    Weapon.ConsumeAmmo(ThisModeNum, MaxChargeAmmo-1); // +1 will be consumed in parent function
    super(KFShotgunFire).ModeDoFire();
}

defaultproperties
{
     MaxChargeAmmo=20
     ProjPerFire=7
     bFireOnRelease=False
     FireRate=1.500000
     ProjectileClass=Class'ScrnBalanceSrv.ScrnHuskGunProjectile_Alt'
     Spread=750.000000
     SpreadStyle=SS_Random
}
