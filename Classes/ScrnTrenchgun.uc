class ScrnTrenchgun extends Trenchgun;

simulated function ClientFinishReloading()
{
	bIsReloading = false;

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Trenchgun's animation is 30 frames long, so 1.0 seconds
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
     ReloadAnimRate=0.9 //synced to reloadrate
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnTrenchgunFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnTrenchgunPickup'
     ItemName="Dragon's Breath Trenchgun SE"
     PlayerViewPivot=(Pitch=0,Roll=0,Yaw=-5) //fix to make sight centered
}
