class ScrnWelder extends Welder;


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    bCanThrow = KF_StoryGRI(Level.GRI) != none; // throw knife on dying only in story mode
}

defaultproperties
{
    PickupClass=Class'ScrnWelderPickup'
    TraderInfoTexture=Texture'KillingFloorHUD.WeaponSelect.Welder'
    ItemName="Welder SE"
}