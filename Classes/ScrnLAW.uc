class ScrnLAW extends LAW;
var     float       RaiseAnimRate; //multiplier for Raise anim rate

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
     PlayerIronSightFOV=65 //give some zoom when aiming
     RaiseAnimRate=2.7
     Description="Light Anti-tank Weapon. Designed to punch through armored vehicles... but can't kill even a Scrake! Maybe because he doesn't wear armor to punch through ^^"
     PickupClass=Class'ScrnBalanceSrv.ScrnLAWPickup'
     ItemName="L.A.W. SE"
}
