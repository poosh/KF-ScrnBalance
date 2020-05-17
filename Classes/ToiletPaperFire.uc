class ToiletPaperFire extends KFFire;

simulated function bool AllowFire()
{
    return false;
}

defaultproperties
{
    AmmoClass=Class'ScrnBalanceSrv.ToiletPaperAmmo'
    DamageMax=0
}
