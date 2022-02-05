//=============================================================================
// Thompson DrumMag Ammo.
//=============================================================================
class ScrnThompsonDrumAmmo extends ThompsonDrumAmmo;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
    ItemName=".45 ACP"
    MaxAmmo=600
    InitialAmount=200
    AmmoPickupAmount=50
    PickupClass=class'ScrnThompsonDrumAmmoPickup'
}
