class ScrnMK23Pickup extends MK23Pickup;

var class<KFWeapon> DualInventoryType; // dual class

function inventory SpawnCopy( pawn Other ) {
    local ScrnMK23Pistol SinglePistol;

    SinglePistol = ScrnMK23Pistol(Other.FindInventoryType(default.InventoryType));
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
    local ScrnMK23Pistol SinglePistol;

    bCanCarry = true;
    AddWeight = class<KFWeapon>(default.InventoryType).default.Weight;
    SinglePistol = ScrnMK23Pistol(Hm.FindInventoryType(default.InventoryType));
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
    DualInventoryType=class'ScrnDualMK23Pistol'
    Weight=3
    AmmoCost=14
    BuyClipSize=12
    AmmoItemName=".45 ACP"
    Description="Match grade .45 ACP caliber pistol featuring a good balance between power, ammo count, and rate of fire. Damage is near to .44 Magnum but has no bullet overpenetration."
    ItemName="MK23 SE"
    ItemShortName="MK23 SE"
    InventoryType=class'ScrnMK23Pistol'
}
