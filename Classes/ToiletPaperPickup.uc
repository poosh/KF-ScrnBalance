class ToiletPaperPickup extends KFWeaponPickup;

defaultproperties
{
    Weight=0
    Cost=5
    AmmoCost=5
    BuyClipSize=1
    Description="Toilet Paper. Rumors say that it somehow helps to survive the Virus Outbreak. Who knows? At least you will die with the clean butt."
    ItemName="Toilet Paper"
    ItemShortName="Toilet Paper"
    AmmoItemName="TP Rolls"
    EquipmentCategoryID=4
    InventoryType=Class'ScrnBalanceSrv.ToiletPaper'
    PickupMessage="You got Toilet Paper"
    CorrespondingPerkIndex=7

    // placeholder
    AmmoMesh=StaticMesh'KillingFloorStatics.FragPickup'
    PickupSound=Sound'KF_GrenadeSnd.Nade_Pickup'
    StaticMesh=StaticMesh'KF_pickups_Trip.explosive.Frag_pickup'
    CollisionRadius=10.000000
    CollisionHeight=10.000000
}
