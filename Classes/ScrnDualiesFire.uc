class ScrnDualiesFire extends DualiesFire;

// Remove left gun's aiming bug  (c) PooSH
// Thanks to n87, Benjamin
function DoFireEffect()
{
    super(KFFire).DoFireEffect();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeDualies'
}
