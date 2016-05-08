class ScrnSPThompsonSMG extends SPThompsonSMG
	config(user);

simulated function AltFire(float F) 
{
	// disable semi-auto mode
}


defaultproperties
{
     Weight=5
     MagCapacity=40
     ReloadRate=3.304348 //3.8/1.15
     ReloadAnimRate=1.15
     
     Priority=123
     GroupOffset=19
     PickupClass=Class'ScrnBalanceSrv.ScrnSPThompsonPickup'
	 FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSPThompsonFire'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnSPThompsonAttachment'
     ItemName="Dr. T's Lead Delivery System SE"
}
