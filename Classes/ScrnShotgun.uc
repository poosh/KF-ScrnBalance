class ScrnShotgun extends Shotgun;

defaultproperties
{
    AttachmentClass=Class'ScrnBalanceSrv.ScrnShotgunAttachment'
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnShotgunFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnShotgunPickup'
    ItemName="Shotgun SE"
    ReloadAnimRate=0.90 //sync animation to reloadrate
    
    HudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun"
    SelectSoundRef="KF_PumpSGSnd.SG_Select"
    MeshRef="KF_Weapons_Trip.Shotgun_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.Shotguns.shotgun_cmb"
}
