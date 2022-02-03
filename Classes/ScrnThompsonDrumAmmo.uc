//=============================================================================
// Thompson DrumMag Ammo.
//=============================================================================
class ScrnThompsonDrumAmmo extends ThompsonDrumAmmo;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
    PickupClass=class'ScrnThompsonDrumAmmoPickup'

     AmmoPickupAmount=50
     MaxAmmo=500
     InitialAmount=200
}
