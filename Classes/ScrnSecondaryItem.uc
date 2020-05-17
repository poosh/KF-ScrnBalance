// base class for "SecondaryItem" weapons - those that cannot be directly equipped
class ScrnSecondaryItem extends KFWeapon
    abstract;

// don't select this weapon
simulated function float RateSelf()
{
    return -100;
}

// Never select this directly
simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( Inventory == None )
        return CurrentChoice;
    return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}

simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    if ( Inventory == None )
        return CurrentChoice;
    return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}

simulated function Weapon WeaponChange( byte F, bool bSilent )
{
    if ( Inventory == None )
        return None;
    return Inventory.WeaponChange(F,bSilent);
}

defaultproperties
{
    MagCapacity=1
    Weight=0
    bKFNeverThrow=True
    FireModeClass(0)=Class'KFMod.NoFire'
    FireModeClass(1)=Class'KFMod.NoFire'
    PutDownAnim="PutDown"
    AIRating=-5.0
    CurrentRating=-5.0
    InventoryGroup=0
}
