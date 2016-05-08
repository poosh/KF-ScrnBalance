class ScrnFNFAL_ACOG_AssaultRifle extends FNFAL_ACOG_AssaultRifle
	config(user);

    
var int FireModeEx; // 0 - F/A, 1 - S/A, 2 - 2 bullet fire
var int FireModeExCount;

replication
{
	reliable if(Role < ROLE_Authority)
		ServerChangeFireModeEx;
}


// Toggle semi/auto fire
simulated function DoToggle ()
{
	local PlayerController Player;

	Player = Level.GetLocalPlayerController();
	if ( Player!=None )
	{
        FireModeEx++;
        if (FireModeEx >= FireModeExCount) FireModeEx = 0;
		FireMode[0].bWaitForRelease = FireModeEx == 1;
		Player.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFireModeSwitchMessage',FireModeEx);
	}

	ServerChangeFireModeEx(FireModeEx);
}

// Set the new fire mode on the server
function ServerChangeFireModeEx(int NewFireModeEx)
{
    FireModeEx = NewFireModeEx;
    FireMode[0].bWaitForRelease = NewFireModeEx == 1;
}



simulated function bool StartFire(int Mode)
{
    if ( FireModeEx <= 1 ) return super.StartFire(Mode);
    
    if (FireMode[Mode].IsInState('WaitingForFireButtonRelease'))
        return false;

	if( !super(KFWeapon).StartFire(Mode) )  // returns false when mag is empty
	   return false;

	if( AmmoAmount(0) <= 0 )
	{
    	return false;
    }

	AnimStopLooping();

	if( !FireMode[Mode].IsInState('FireBurst') && (AmmoAmount(0) > 0) )
	{   
        ScrnFNFALFire(FireMode[Mode]).BurstSize = FireModeEx;
        FireMode[Mode].GotoState('FireBurst');
		return true;
	}

	return false;
}

simulated function StopFire(int Mode)
{
    super.StopFire(Mode);
    if (FireMode[Mode].IsInState('WaitingForFireButtonRelease'))
        FireMode[Mode].GotoState('');
}

defaultproperties
{
     FireModeExCount=3
     Weight=7.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnFNFALFire'
     Description="Classic NATO battle rifle. Can penetrate small targets and has a fixed-burst mode."
     PickupClass=Class'ScrnBalanceSrv.ScrnFNFAL_ACOG_Pickup'
     ItemName="FNFAL SE"
}
