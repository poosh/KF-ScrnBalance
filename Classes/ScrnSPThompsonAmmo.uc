class ScrnSPThompsonAmmo extends SPThompsonAmmo;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
    ItemName=".45 ACP"
    MaxAmmo=420
    InitialAmount=160
    AmmoPickupAmount=40
    PickupClass=class'ScrnSPThompsonAmmoPickup'
}
