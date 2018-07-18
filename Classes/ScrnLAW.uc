class ScrnLAW extends LAW;

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
            PlayAnim('Raise',2.7,0.1); //increased to 2.7
        }
        else
        {
            PlayAnim('Raise',2.7,0.1); //increased to 2.7
        }
    }
}

defaultproperties
{
     Weight=12.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnLAWFire'
     PlayerIronSightFOV=65 //give some zoom when aiming
     Description="Light Anti-tank Weapon. Designed to punch through armored vehicles... but can't kill even a Scrake! Maybe because he doesn't wear armor to punch through ^^"
     PickupClass=Class'ScrnBalanceSrv.ScrnLAWPickup'
     ItemName="L.A.W. SE"
}
