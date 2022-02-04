class ScrnMagnum44Pickup extends Magnum44Pickup;

var class<KFWeapon> DualInventoryType; // dual class

function inventory SpawnCopy( pawn Other ) {
    local ScrnMagnum44Pistol SinglePistol;

    SinglePistol = ScrnMagnum44Pistol(Other.FindInventoryType(default.InventoryType));
    if (SinglePistol != none ) {
        InventoryType = DualInventoryType;
    }
    else {
        InventoryType = default.InventoryType;
    }
    return Super(KFWeaponPickup).SpawnCopy(Other);
}

function bool CheckCanCarry(KFHumanPawn Hm) {
    local bool bCanCarry;
    local float AddWeight;
    local ScrnMagnum44Pistol SinglePistol;

    bCanCarry = true;
    AddWeight = class<KFWeapon>(default.InventoryType).default.Weight;
    SinglePistol = ScrnMagnum44Pistol(Hm.FindInventoryType(default.InventoryType));
    if ( SinglePistol != none ) {
        if ( SinglePistol.DualGuns != none ) {
            bCanCarry = false;
        }
        else {
            AddWeight = default.DualInventoryType.default.Weight - AddWeight;
        }
    }

    if ( !bCanCarry || !Hm.CanCarry(AddWeight) ) {
        if ( LastCantCarryTime < Level.TimeSeconds && PlayerController(Hm.Controller) != none ) {
            LastCantCarryTime = Level.TimeSeconds + 0.5;
            PlayerController(Hm.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 2);
        }
        return false;
    }

    return true;
}

defaultproperties
{
     DualInventoryType=class'ScrnDual44Magnum'
     cost=150
     AmmoCost=10
     BuyClipSize=6
     ItemName="44 Magnum SE"
     ItemShortName="44 Magnum SE"
     InventoryType=class'ScrnMagnum44Pistol'
     Weight=2
}
