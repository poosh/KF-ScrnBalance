class ScrnM203Fire extends M203Fire;

simulated function bool AllowFire()
{
    //don't allow firing nade while reloading rifle mag
    if( KFWeapon(Weapon).bIsReloading )
    {
        return false;
    }
    return super.AllowFire();
}

defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnM203GrenadeProjectile'
     FireRate=1.99
     FireAnimRate=1.666667
}
