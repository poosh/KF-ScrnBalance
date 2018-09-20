class ScrnTrenchgun extends Trenchgun;

var int AmmoLoadedThisReload; //for some reason using NumLoadedThisReload doesn't work in multiplayer

simulated function HideBullet()
{
    SetBoneScale(1, 0.001, 'Shell');
}

simulated function ShowBullet()
{
    SetBoneScale(1, 1.0, 'Shell');
}

//count ammo loaded
simulated function AddReloadedAmmo()
{
    AmmoLoadedThisReload++;
    Super.AddReloadedAmmo();
}

simulated function ClientReload()
{
    ShowBullet();
    AmmoLoadedThisReload = 0;
    Super.ClientReload();
}

simulated function ClientFinishReloading()
{
    local float ReloadMulti;
    bIsReloading = false;

    // The reload animation is complete, but there is still some animation to play
    // Let's reward player for waiting the full reload time by playing the full reload animation (Can be skipped by firing)
    // Trenchgun's animation is 30 frames long, so 1.0 seconds
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
     ReloadAnimRate=0.9 //synced to reloadrate
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnTrenchgunFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnTrenchgunPickup'
     ItemName="Dragon's Breath Trenchgun SE"
     PlayerViewPivot=(Pitch=0,Roll=0,Yaw=-5) //fix to make sight centered
}
