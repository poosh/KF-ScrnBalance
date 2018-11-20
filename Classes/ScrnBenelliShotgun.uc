class ScrnBenelliShotgun extends BenelliShotgun;

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
     ReloadRate=0.750000
     ReloadAnimRate=1.074 //1.200000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBenelliFire'
     Description="A military tactical shotgun with semi automatic fire capability. Holds up to 6 shells. Special shell construction allow pellets to penetrate fat much easier."
     PickupClass=Class'ScrnBalanceSrv.ScrnBenelliPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnBenelliAttachment' //New attachment to fix broken BenelliAttachment class
     ItemName="Combat Shotgun SE"
     PlayerViewPivot=(Pitch=-47,Roll=0,Yaw=-5) //fix to make sight centered
}
