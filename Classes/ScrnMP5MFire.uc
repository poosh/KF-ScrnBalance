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
     AmmoClass=Class'ScrnBalanceSrv.ScrnMP5MAmmo'
}
