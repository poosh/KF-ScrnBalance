class ScrnShotgun extends Shotgun;

var bool bChamberThisReload; //if full reload is uninterrupted, play chambering animation

simulated function ClientReload()
{
    bChamberThisReload = ( MagAmmoRemaining == 0 && (AmmoAmount(0) - MagAmmoRemaining > MagCapacity) ); //for chambering animation
    Super.ClientReload();
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;

    //play chambering animation if finished reloading from empty
    if ( !bChamberThisReload )
    {
        PlayIdle();
    }
    bChamberThisReload = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}


defaultproperties
{
    AttachmentClass=Class'ScrnBalanceSrv.ScrnShotgunAttachment'
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnShotgunFire'
    PickupClass=Class'ScrnBalanceSrv.ScrnShotgunPickup'
    ItemName="Shotgun SE"
    ReloadAnimRate=0.94 //sync animation to reloadrate

    HudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.combat_shotgun"
    SelectSoundRef="KF_PumpSGSnd.SG_Select"
    MeshRef="KF_Weapons_Trip.Shotgun_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.Shotguns.shotgun_cmb"

    ModeSwitchAnim="LightOn"
}
