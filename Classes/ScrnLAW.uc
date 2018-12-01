class ScrnLAW extends LAW;
var     float       RaiseAnimRate; //multiplier for Raise anim rate

//overwriting to disable tween to idle if zoomed out while firing
simulated function ZoomOut(bool bAnimateTransition)
{
	super(BaseKFWeapon).ZoomOut(bAnimateTransition);

	bAimingRifle = False;

	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);

	if( Level.NetMode != NM_DedicatedServer && KFPlayerController(Instigator.Controller) != none )
	{
		if( AimOutSound != none )
		{
            PlayOwnedSound(AimOutSound, SLOT_Misc,,,,, false);
        }
		KFPlayerController(Instigator.Controller).TransitionFOV(KFPlayerController(Instigator.Controller).DefaultFOV,ZoomTime);
	}
    if( Level.TimeSeconds > FireMode[0].NextFireTime )
    {
        TweenAnim(IdleAnim,FastZoomOutTime);
    }
}

//overwriting to increase raise animation play rate
simulated function ZoomIn(bool bAnimateTransition)
{
    if( Level.TimeSeconds < FireMode[0].NextFireTime )
    {
        return;
    }
    super.ZoomIn(bAnimateTransition);

    if( bAnimateTransition )
    {
        if( bZoomOutInterrupted )
        {
            PlayAnim('Raise',RaiseAnimRate,0.1);
        }
        else
        {
            PlayAnim('Raise',RaiseAnimRate,0.1);
        }
    }
}

defaultproperties
{
     Weight=12.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnLAWFire'
     ForceZoomOutOnFireTime=0.05
     PlayerIronSightFOV=65 //give some zoom when aiming
     RaiseAnimRate=2.7
     Description="Light Anti-tank Weapon. Designed to punch through armored vehicles... but can't kill even a Scrake! Maybe because he doesn't wear armor to punch through ^^"
     PickupClass=Class'ScrnBalanceSrv.ScrnLAWPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnLAWAttachment'
     ItemName="L.A.W. SE"
	 bHoldToReload=false // to show correct ammo amount on classic hud
}
