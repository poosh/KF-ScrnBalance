class ScrnSyringe extends Syringe;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    
    HealBoostAmount = default.HealBoostAmount;
    // allow dropping syringe in Story Mode
    bKFNeverThrow = KF_StoryGRI(Level.GRI) == none;
    bCanThrow = !bKFNeverThrow; // prevent dropping syringe on dying
    AmmoCharge[0]=0; // prevent dropping exploit
}


defaultproperties
{
     FireModeClass(0)=class'ScrnSyringeFire'
     FireModeClass(1)=class'ScrnSyringeAltFire'
     PickupClass=class'ScrnSyringePickup'
     ItemName="Med-Syringe SE"
     TraderInfoTexture=Texture'KillingFloorHUD.WeaponSelect.Syringe'
}
