class ScrnThompsonDrum extends ThompsonDrumSMG
    config(user);

simulated function AltFire(float F) 
{
    // disable semi-auto mode
}    
    
defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnThompsonDrumFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnThompsonDrumPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnThompsonDrumAttachment'

     Weight=6
     MagCapacity=50
     ReloadRate=3.304348 //3.8/1.15
     ReloadAnimRate=1.15

     Description="This Tommy gun with a drum magazine was used heavily during the WWII pacific battles as seen in Rising Storm."
     Priority=124
     GroupOffset=20
     ItemName="RS Tommy Gun SE"
}
