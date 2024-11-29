class ScrnRandomItemSpawn extends KFRandomItemSpawn;

var bool bPermanentlyDisabled;

simulated function PostBeginPlay()
{
     local ScrnGameType ScrnGT;

     ScrnGT = ScrnGameType(Level.Game);
     if (ScrnGT != none) {
          ScrnGT.SetupRandomItemSpawn(self);
     }
     super.PostBeginPlay();
}

function EnableMe()
{
     if (!bPermanentlyDisabled) {
          super.EnableMe();
     }
}

defaultproperties
{
     bForceDefault=false
     PickupClasses(0)=Class'ScrnVest'
     PickupClasses(1)=class'ScrnDualiesPickup'
     PickupClasses(2)=class'ScrnMagnum44Pickup'
     PickupClasses(3)=class'ScrnShotgunPickup'
     PickupClasses(4)=class'ScrnBullpupPickup'
     PickupClasses(5)=class'ScrnWinchesterPickup'
     PickupClasses(6)=class'ScrnMachetePickup'
     PickupClasses(7)=class'ScrnAxePickup'
     PickupClasses(8)=class'ScrnMAC10Pickup'
     PickupWeight(0)=8
     PickupWeight(1)=2
     PickupWeight(2)=2
     PickupWeight(3)=4
     PickupWeight(4)=4
     PickupWeight(5)=4
     PickupWeight(6)=2
     PickupWeight(7)=2
     PickupWeight(8)=4
}
