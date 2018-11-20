class ScrnTrenchgun extends Trenchgun;

var bool bChamberThisReload; //if full reload is uninterrupted, play chambering animation

simulated function HideBullet()
{
    SetBoneScale(1, 0.001, 'Shell');
}

simulated function ShowBullet()
{
    SetBoneScale(1, 1.0, 'Shell');
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
     ReloadAnimRate=0.9 //synced to reloadrate
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnTrenchgunFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnTrenchgunPickup'
     ItemName="Dragon's Breath Trenchgun SE"
     PlayerViewPivot=(Pitch=0,Roll=0,Yaw=-5) //fix to make sight centered
}
