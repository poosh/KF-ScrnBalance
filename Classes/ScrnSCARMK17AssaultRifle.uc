//=============================================================================
// SCAR MK17 Inventory class
//=============================================================================
class ScrnSCARMK17AssaultRifle extends SCARMK17AssaultRifle
	config(user);

defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSCARMK17Fire'
     PickupClass=Class'ScrnBalanceSrv.ScrnSCARMK17Pickup'
     ItemName="SCARMK17 SE"
}
