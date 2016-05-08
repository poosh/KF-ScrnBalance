class ScrnSPThompsonFire extends SPThompsonFire;

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
	DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSPThompson'
}