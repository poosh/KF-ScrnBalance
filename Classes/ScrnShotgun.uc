class ScrnShotgun extends Shotgun;

simulated function ClientFinishReloading()
{
    local float ReloadMulti;
	bIsReloading = false;

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Shotgun's animation is 23 frames long, so 0.76 seconds
    if ( NumLoadedThisReload == MagCapacity)
    {
        if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        {
            ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
        }
        else
        {
            ReloadMulti = 1.0;
        }
        //PlayIdle();
        SetTimer(0.76/ReloadMulti, false); 
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
}
