class ScrnVestPickup extends KFWeaponPickup
    abstract notplaceable;
    
var(Shield) int         ShieldCapacity; 
var(Shield) float       SpeedModifier;      // movement speed modifier. How slower you will move while wearing this shield. In % of default ground speed.
var         texture        TraderInfoTexture;  //Image to show in Info

defaultproperties
{
     TraderInfoTexture=Texture'KillingFloorHUD.Trader_Weapon_Images.Trader_Vest'
     Weight=0.000000
     cost=0
     Description="Kevlar vest. Affords the wearer limited protection from most forms of attack."
     ItemName="Vest"
     ItemShortName="Vest"
     EquipmentCategoryID=5
     CorrespondingPerkIndex=7
     PickupMessage="You got a Vest"
     PickupSound=Sound'KF_InventorySnd.Vest_Pickup'
     StaticMesh=StaticMesh'KillingFloorStatics.Vest'
     DrawScale3D=(Z=0.400000)
     TransientSoundVolume=150.000000
     CollisionRadius=30.000000
     CollisionHeight=5.000000
}
