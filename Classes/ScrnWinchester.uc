class ScrnWinchester extends Winchester;

defaultproperties
{
    MeshRef="KF_Weapons_Trip.Winchester_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.Rifles.winchester_cmb"
    HudImageRef="KillingFloorHUD.WeaponSelect.winchester_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.Winchester"
    SelectSoundRef="KF_RifleSnd.Rifle_Select"
    ReloadAnimRate=1.15000 //sync reload animation with reloadrate
    
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnWinchesterFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnWinchesterPickup'
    ItemName="Lever Action Rifle SE"
}
