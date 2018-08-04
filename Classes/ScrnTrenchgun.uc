class ScrnTrenchgun extends Trenchgun;

defaultproperties
{
     ReloadAnimRate=0.9 //synced to reloadrate
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnTrenchgunFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnTrenchgunPickup'
     ItemName="Dragon's Breath Trenchgun SE"
     PlayerViewPivot=(Pitch=0,Roll=0,Yaw=-5) //fix to make sight centered
}
