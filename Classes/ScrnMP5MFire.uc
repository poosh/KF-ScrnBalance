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

//rotate shell eject emitter
simulated function InitEffects()
{
    super.InitEffects();

    // don't do this on server
    if ( (Level.NetMode == NM_DedicatedServer) || (AIController(Instigator.Controller) != None) )
        return;
    if (ShellEjectEmitter != None)
    {
        ShellEjectEmitter.SetRelativeRotation(rot(-10000,0,0));
    }
}

defaultproperties
{
    DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMP7M'
    AmmoClass=Class'ScrnBalanceSrv.ScrnMP5MAmmo'
    ShellEjectClass=class'ROEffects.KFShellEjectMP' //default KFShellEjectMP5M is missing
    DamageMin=32
    DamageMax=32     
}
