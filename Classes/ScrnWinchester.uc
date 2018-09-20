class ScrnWinchester extends Winchester;

var int AmmoLoadedThisReload; //for some reason using NumLoadedThisReload doesn't work in multiplayer

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
    AmmoLoadedThisReload = 0;
    Super.ClientReload();
}

//this is called when out of ammo to load, or mag is full
simulated function ClientFinishReloading()
{
    local float ReloadMulti;
    bIsReloading = false;
    
    //log("ClientFinishReloading: AmmoLoadedThisReload is  "@ AmmoLoadedThisReload, 'ScrnWinchester'); 
    //log("ClientFinishReloading: NumLoadedThisReload is  "@ NumLoadedThisReload, 'ScrnWinchester'); 

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Winchester's animation is 30 frames long, so 1.0 seconds
    if ( AmmoLoadedThisReload == MagCapacity)
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
        //SetTimer(1.0/ReloadMulti, false); 
    }
    else
    {
        PlayIdle();
    }

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}
/*
simulated function Timer()
{
    //if ( ClientState == WS_ReadyToFire )
        //PlayIdle();
    //else
        super.Timer();
}
*/

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
