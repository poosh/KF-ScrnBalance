//=============================================================================
 //SCARMK17 Fire
//=============================================================================
class ScrnSCARMK17Fire extends SCARMK17Fire;

//lock charging handle after firing last shot
simulated function bool AllowFire()
{   
    if (Super.AllowFire() && KFWeapon(Weapon).MagAmmoRemaining <= 1 && !ScrnSCARMK17AssaultRifle(Weapon).bBoltLockQueued )
    {
        ScrnSCARMK17AssaultRifle(Weapon).bBoltLockQueued = true; //make sure it only gets set once
        ScrnSCARMK17AssaultRifle(Weapon).BoltLockTime = (Level.TimeSeconds + 0.075); //move bolt to locked position after 0.075 seconds
    }
    return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSCARMK17AssaultRifle'
}
