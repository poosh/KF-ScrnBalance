class ScrnWelder extends Welder;


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    bCanThrow = KF_StoryGRI(Level.GRI) != none; // throw knife on dying only in story mode
}

defaultproperties
{
    PickupClass=Class'ScrnWelderPickup'
    FireModeClass(0)=Class'ScrnWeldFire'
    FireModeClass(1)=Class'ScrnUnWeldFire'
    TraderInfoTexture=Texture'KillingFloorHUD.WeaponSelect.Welder'
    ItemName="Welder SE"

    PutDownAnimRate=4.2222
    SelectAnimRate=3.5556
    BringUpTime=0.15
    PutDownTime=0.15
}