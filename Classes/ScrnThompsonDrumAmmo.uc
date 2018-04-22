//=============================================================================
// Thompson DrumMag Ammo.
//=============================================================================
class ScrnThompsonDrumAmmo extends ThompsonDrumAmmo;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
    PickupClass=Class'ScrnBalanceSrv.ScrnThompsonDrumAmmoPickup'

     AmmoPickupAmount=50
     MaxAmmo=500
     InitialAmount=200
}
