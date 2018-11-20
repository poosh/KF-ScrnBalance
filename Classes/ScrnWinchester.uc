class ScrnWinchester extends Winchester;

var bool bChamberThisReload; //if full reload is uninterrupted, play chambering animation

simulated function HideBullet()
{
    SetBoneScale(1, 0.001, 'Bullet');
}

simulated function ShowBullet()
{
    SetBoneScale(1, 1.0, 'Bullet');
}

simulated function ClientReload()
{
    ShowBullet();
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
    SelectAnim="Select " //thanks tripwire
    SelectAnimRate=2.25
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
