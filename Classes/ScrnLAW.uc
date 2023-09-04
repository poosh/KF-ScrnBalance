class ScrnLAW extends LAW;

var(Zooming) name ZoomAnimName;
var(Zooming) float ZoomAnimRate;

simulated event WeaponTick(float dt)
{
    super(KFWeapon).WeaponTick(dt);
}

simulated function ZoomOut(bool bAnimateTransition)
{
    super.ZoomOut(bAnimateTransition);
    bZoomingIn = false;
}

//overwriting to increase raise animation play rate
simulated function ZoomIn(bool bAnimateTransition)
{
    if (Level.TimeSeconds < FireMode[0].NextFireTime)
        return;

    super(KFWeapon).ZoomIn(bAnimateTransition);

    if (bAnimateTransition) {
        PlayAnim(ZoomAnimName, ZoomAnimRate, 0.1);
    }
}

defaultproperties
{
    Weight=12
    FireModeClass(0)=class'ScrnLAWFire'
    ForceZoomOutOnFireTime=0.05
    PlayerIronSightFOV=65 //give some zoom when aiming
    ZoomAnimName="Raise"
    ZoomAnimRate=2.0
    ZoomTime=0.33
    Description="Light Anti-tank Weapon. Designed to punch through armored vehicles... but can't kill even a Scrake! Maybe because he doesn't wear armor to punch through ^^"
    PickupClass=class'ScrnLAWPickup'
    AttachmentClass=class'ScrnLAWAttachment'
    ItemName="L.A.W. SE"
    bHoldToReload=false // to show correct ammo amount on classic hud
}
