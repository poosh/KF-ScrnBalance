class ScrnMagnum44Pickup extends Magnum44Pickup;

var class<KFWeapon> DualInventoryType; // dual class

function inventory SpawnCopy( pawn Other ) {
    local Inventory CurInv;
    local KFWeapon PistolInInventory;

    For( CurInv=Other.Inventory; CurInv!=None; CurInv=CurInv.Inventory ) {
        PistolInInventory = KFWeapon(CurInv);
        if( PistolInInventory != None && (PistolInInventory.class == default.InventoryType 
                || ClassIsChildOf(default.InventoryType, PistolInInventory.class)) )
        {
            // destroy the inventory to force parent SpawnCopy() to make a new instance of class
            // we specified below
            if( Inventory!=None )
                Inventory.Destroy();
            // spawn dual guns instead of another instance of single
            InventoryType = DualInventoryType;
            // Make dualies to cost twice of lowest value in case of PERKED+UNPERKED pistols
            SellValue = 2 * min(SellValue, PistolInInventory.SellValue);
            AmmoAmount[0]+= PistolInInventory.AmmoAmount(0);
            MagAmmoRemaining+= PistolInInventory.MagAmmoRemaining;
            PistolInInventory.Destroyed();
            PistolInInventory.Destroy();
            Return Super(KFWeaponPickup).SpawnCopy(Other);
        }
    }
    InventoryType = Default.InventoryType;
    Return Super(KFWeaponPickup).SpawnCopy(Other);
}

function bool CheckCanCarry(KFHumanPawn Hm) {
    local Inventory CurInv;
    local bool bHasSinglePistol;
    local float AddWeight;

    AddWeight = class<KFWeapon>(default.InventoryType).default.Weight;
    for ( CurInv = Hm.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
        if ( CurInv.class == default.DualInventoryType ) {
            //already have duals, can't carry a single
            if ( LastCantCarryTime < Level.TimeSeconds && PlayerController(Hm.Controller) != none )
            {
                LastCantCarryTime = Level.TimeSeconds + 0.5;
                PlayerController(Hm.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 2);
            }
            return false; 
        }
        else if ( CurInv.class == default.InventoryType ) {
            bHasSinglePistol = true;
            AddWeight = default.DualInventoryType.default.Weight - AddWeight;
            break;
        }
    }

    if ( !Hm.CanCarry(AddWeight) ) {
        if ( LastCantCarryTime < Level.TimeSeconds && PlayerController(Hm.Controller) != none )
        {
            LastCantCarryTime = Level.TimeSeconds + 0.5;
            PlayerController(Hm.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 2);
        }

        return false;
    }

    return true;
}

defaultproperties
{
     DualInventoryType=Class'ScrnBalanceSrv.ScrnDual44Magnum'
     cost=150
     AmmoCost=11
     ItemName="44 Magnum SE"
     ItemShortName="44 Magnum SE"
     InventoryType=Class'ScrnBalanceSrv.ScrnMagnum44Pistol'
     Weight=2
}
