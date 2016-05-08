class ScrnMP5MFire extends MP5MFire;

// fixes double shot bug -- PooSH
state FireLoop
{
    function BeginState()
    {
        super.BeginState();
        
		NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
    }
}  

defaultproperties
{
    DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMP7M'
    AmmoClass=Class'ScrnBalanceSrv.ScrnMP5MAmmo'
    DamageMin=32
    DamageMax=32     
}
