class ScrnDeaglePickup extends DeaglePickup;

var class<KFWeapon> DualInventoryType; // dual class

function inventory SpawnCopy( pawn Other ) {
    local ScrnDeagle SinglePistol;

    SinglePistol = ScrnDeagle(Other.FindInventoryType(default.InventoryType));
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
    local ScrnDeagle SinglePistol;

    bCanCarry = true;
    AddWeight = class<KFWeapon>(default.InventoryType).default.Weight;
    SinglePistol = ScrnDeagle(Hm.FindInventoryType(default.InventoryType));
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
    DualInventoryType=class'ScrnDualDeagle'
    cost=750
    AmmoCost=15
    BuyClipSize=7
    ItemName="Handcannon SE"
    ItemShortName="Handcannon SE"
    AmmoItemName=".50 AE"
    InventoryType=class'ScrnDeagle'
    Weight=4
}
