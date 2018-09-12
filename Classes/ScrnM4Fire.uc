class ScrnM4Fire extends M4Fire;

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
     FireLoopAnimRate=1.59
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeM4AssaultRifle'
}
