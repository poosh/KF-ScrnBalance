class ScrnBenelliShotgun extends BenelliShotgun;

var int AmmoLoadedThisReload; //for some reason using NumLoadedThisReload doesn't work in multiplayer

//count ammo loaded
simulated function AddReloadedAmmo()
{
    AmmoLoadedThisReload++;
    Super.AddReloadedAmmo();
}

simulated function ClientReload()
{
    AmmoLoadedThisReload = 0;
    Super.ClientReload();
}

simulated function ClientFinishReloading()
{
    local float ReloadMulti;
    bIsReloading = false;

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Benelli's animation is 30 frames long, so 1.0 seconds
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
     ReloadRate=0.750000
     ReloadAnimRate=1.074 //1.200000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBenelliFire'
     Description="A military tactical shotgun with semi automatic fire capability. Holds up to 6 shells. Special shell construction allow pellets to penetrate fat much easier."
     PickupClass=Class'ScrnBalanceSrv.ScrnBenelliPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnBenelliAttachment' //New attachment to fix broken BenelliAttachment class
     ItemName="Combat Shotgun SE"
     PlayerViewPivot=(Pitch=-47,Roll=0,Yaw=-5) //fix to make sight centered
}
