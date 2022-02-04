class ScrnMachetePickup extends MachetePickup;

// Fixed "Accessed none: Inventory" warning in KFWeaponPickup. This should be copied into all pickup classes.
function Destroyed()
{
    if ( bDropped && Inventory != none && KFGameType(Level.Game) != none )
            KFGameType(Level.Game).WeaponDestroyed(class<Weapon>(Inventory.Class));

    super(WeaponPickup).Destroyed();
}

defaultproperties
{
     cost=100
     ItemName="Machete SE"
     ItemShortName="Machete SE"
     InventoryType=class'ScrnMachete'
     CorrespondingPerkIndex=7

     CollisionRadius=30
     CollisionHeight=20
     PrePivot=(Z=20)
}
