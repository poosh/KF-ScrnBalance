class ScrnHRLFire extends ScrnLAWFire;

function bool AllowFire()
{
    //  allow fire without zooming
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
    
}

defaultproperties
{
     FireAnimRate=1.600000
     FireRate=2.031250
     AmmoClass=Class'ScrnBalanceSrv.ScrnHRLAmmo'
     ProjectileClass=Class'ScrnBalanceSrv.ScrnHRLProj'
}
