class ScrnM4203AssaultRifle extends M4203AssaultRifle
	config(user);

var transient bool bTriggerReleased;   		// indicates that fire button is released, but need to end the burst
var transient float PrevFireTime;
	
simulated function bool StartFire(int Mode)
{
    if ( Mode > 0 ) {
        if ( FireMode[0].IsInState('WaitingForFireButtonRelease') )
            FireMode[0].GotoState(''); 
		if ( AmmoAmount(1) > 1 ) {
			KFShotgunFire(FireMode[1]).FireAimedAnim='Fire_Iron_Secondary';
			FireMode[1].FireAnim='Fire_Secondary';
			FireMode[1].default.FireRate=3.33;
		}
		else {
			KFShotgunFire(FireMode[1]).FireAimedAnim='FireLast_Iron_Secondary';
			FireMode[1].FireAnim='FireLast_Secondary';
			FireMode[1].default.FireRate=0.5;
		}
		return super.StartFire(Mode);
    }

    if (FireMode[0].IsInState('WaitingForFireButtonRelease') || FireMode[0].IsInState('FireBurst'))
        return false;

	if( !super(KFWeapon).StartFire(0) )  // returns false when mag is empty
	   return false;

	//AnimStopLooping();
                                                                         //prevent fire button spam-clicking
	if( !FireMode[0].IsInState('FireBurst') && (AmmoAmount(0) > 0) && Level.TimeSeconds > PrevFireTime + 0.2 )
	{   
        PrevFireTime = Level.TimeSeconds;
        bTriggerReleased = false;
        FireMode[0].GotoState('FireBurst');
		return true;
	}

	return false;
}

simulated function ReallyStopFire(int Mode) 
{
    super.StopFire(Mode);
}

simulated function StopFire(int Mode)
{
    //log("StopFire("$Mode$")", class.outer.name);
    if ( Mode > 0 ) {
        if ( FireMode[0].IsInState('WaitingForFireButtonRelease') ) //this shouldn't happed, but just to be sure
            FireMode[0].GotoState('');    
            
        super.StopFire(Mode);
        return;
    }
    // Dear Server and Mighty Cthulhu, who's living inside KFMod code and makes stuff glitching all the time,
    // By setting the flag below I want to acknowledge you my wish of stopping bring death to this holy place
    // as soon as my weapon stops firing (burst ends).
    // So please allow me to reload my gun this time!
    // kind regards,
    // Client.
    bTriggerReleased = true;
        
    if ( FireMode[0].IsInState('WaitingForFireButtonRelease') )
        FireMode[0].GotoState('');
    else if ( !FireMode[0].IsInState('FireBurst') )
        super.StopFire(0);
}


simulated exec function ReloadMeNow()
{
    // tbs burst fire won't screw reload
    if ( FireMode[0].IsInState('FireBurst') || FireMode[0].IsInState('WaitingForFireButtonRelease') )
        FireMode[0].GotoState('');

    //log("ReloadMeNow()", class.outer.name);
        
    super.ReloadMeNow();
}

defaultproperties
{
     ReloadRate=2.794846
     ReloadAnimRate=1.300000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM4203BulletFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnM203Fire'
     Description="An assault rifle with an attached grenade launcher. Shoots in 3-bullet fixed-burst mode."
     InventoryGroup=3
     PickupClass=Class'ScrnBalanceSrv.ScrnM4203Pickup'
     ItemName="M4 203 SE"
}
