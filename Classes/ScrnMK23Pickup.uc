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
     DualInventoryType=Class'ScrnBalanceSrv.ScrnDualMK23Pistol'
     Weight=3.000000
     Description="Match grade 45 caliber pistol. Good balance between power, ammo count and rate of fire. Damage is near to Magnum's, but has no bullet penetration."
     ItemName="MK23 SE"
     ItemShortName="MK23 SE"
     InventoryType=Class'ScrnBalanceSrv.ScrnMK23Pistol'
}
