// dummy class that indicates player doesn't wear armor currently
class ScrnNoVestPickup extends ScrnVestPickup
    notplaceable abstract ;

defaultproperties
{
    Description="You have no armor. Either you have balls of steel or a brain of turd."
    ItemName="No Armor"
    ItemShortName="No Armor"
    PickupMessage="You lost the armor"
}
