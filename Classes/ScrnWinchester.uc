class ScrnWinchester extends Winchester;


simulated function ClientFinishReloading()
{
	bIsReloading = false;

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Winchester's animation is 30 frames long, so 1.0 seconds
    if ( NumLoadedThisReload == MagCapacity)
    {
        //PlayIdle();
        SetTimer(1.0/ReloadMulti, false); 
    }
    else
    {
        PlayIdle();
    }

	if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
		Instigator.Controller.ClientSwitchToBestWeapon();
}

simulated function Timer()
{
    if ( ClientState == WS_ReadyToFire )
        PlayIdle();
    else
        super.Timer();
}


defaultproperties
{
    SelectAnim="Select " //thanks tripwire
    SelectAnimRate=1.9
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
