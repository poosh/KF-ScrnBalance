class ScrnSyringe extends Syringe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	
	HealBoostAmount = default.HealBoostAmount;
	// allow dropping syringe in Story Mode
	bKFNeverThrow = KF_StoryGRI(Level.GRI) == none;
	AmmoCharge[0]=0; // prevent dropping exploit
}


defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSyringeFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnSyringeAltFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnSyringePickup'
     ItemName="Med-Syringe SE"
}
