class ScrnFunctions extends Object
abstract;


//returns true, if clip size to buy is determined by Pickup.BuyClipSize
//returns false, if clip size to buy is determined by Weapon.MagCapacity
static function bool ShouldUseBuyClipSize(class<KFWeaponPickup> APickup, class<Ammunition> AmmoClass)
{
  return class<HuskGunPickup>(APickup) != none
            || class<ScrnBoomStickPickup>(APickup) != none 
            || class<ScrnLAWPickup>(APickup) != none;
}

defaultproperties
{
}
