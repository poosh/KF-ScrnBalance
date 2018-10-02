class ScrnDualiesFire extends DualiesFire;

//called after reload and on zoom toggle, sets next pistol to fire to sync with slide lock order
function SetPistolFireOrder()
{
    //this gets toggled before firing, amazingly
    if (ScrnDualies(Weapon).MagAmmoRemaining%2 == 1)
    {
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    if (ScrnDualies(Weapon).MagAmmoRemaining%2 == 0)
    {
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
    }
}

//lock slide back if fired last round
simulated function bool AllowFire()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if( (Level.TimeSeconds - LastFireTime > FireRate) && KFWeapon(Weapon).MagAmmoRemaining > 2 && !KFWeapon(Weapon).bIsReloading )
        {
            if (KFWeapon(Weapon).MagAmmoRemaining%2 == 0) 
            {
                ScrnDualies(Weapon).DoRightHammerDrop( GetFireSpeed() ); //drop hammer
            }
            if (KFWeapon(Weapon).MagAmmoRemaining%2 == 1) 
            {
                ScrnDualies(Weapon).DoLeftHammerDrop( GetFireSpeed() ); //drop hammer
            }
        }
        if( (Level.TimeSeconds - LastFireTime > FireRate) && KFWeapon(Weapon).MagAmmoRemaining <= 2 && !KFWeapon(Weapon).bIsReloading )
        {
            if (KFWeapon(Weapon).MagAmmoRemaining == 2)
            {
                ScrnDualies(Weapon).LockRightSlideBack();
                ScrnDualies(Weapon).bTweenLeftSlide = true;
            }
            else if (KFWeapon(Weapon).MagAmmoRemaining <= 1)
            {
                ScrnDualies(Weapon).LockLeftSlideBack();
                ScrnDualies(Weapon).LockRightSlideBack();
            }
        }
    } 
	return Super.AllowFire();
}
    
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
