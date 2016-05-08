class ScrnThompsonIncAmmo extends KFAmmunition;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
     AmmoPickupAmount=20
     MaxAmmo=240
     InitialAmount=150
     PickupClass=Class'ScrnBalanceSrv.ScrnThompsonIncAmmoPickup'
     IconMaterial=Texture'KillingFloorHUD.Generic.HUD'
     IconCoords=(X1=336,Y1=82,X2=382,Y2=125)
     ItemName="45. ACP Incendiary bullets"
}
