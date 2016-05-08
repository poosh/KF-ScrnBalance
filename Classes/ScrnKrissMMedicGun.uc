class ScrnKrissMMedicGun extends KrissMMedicGun;

defaultproperties
{
     HealAmmoCharge=0
     AmmoRegenRate=0.25 // down from 0.2
     Weight=5.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnKrissMFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnKrissMAltFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnKrissMPickup'
     bReduceMagAmmoOnSecondaryFire=False
     ItemName="Schneidzekk Medic Gun SE"
}
