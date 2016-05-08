class ScrnSPThompsonAmmo extends SPThompsonAmmo;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
     MaxAmmo=400
     InitialAmount=200
     PickupClass=Class'ScrnBalanceSrv.ScrnSPThompsonAmmoPickup'
}