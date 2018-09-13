class ScrnMKb42Fire extends MKb42Fire;

//close bolt if attempted to fire when empty
function bool AllowFire()
{
    if(KFWeapon(Weapon).MagAmmoRemaining == 0 )
    {
        ScrnMKb42AssaultRifle(Weapon).bBoltClosed = true;
    }
	if(!KFWeapon(Weapon).bIsReloading )
	{
        if(KFWeapon(Weapon).MagAmmoRemaining == 0 )
        {
            ScrnMKb42AssaultRifle(Weapon).MoveBoltForward(); //close bolt on empty chamber
            ScrnMKb42AssaultRifle(Weapon).bBoltClosed = true; //setting this here makes ClientReload's bShortReload work
        }
	}
	return Super.AllowFire();
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMKb42AssaultRifle'
}
