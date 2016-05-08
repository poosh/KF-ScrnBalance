Class ScrnSteamStatsGetter extends KFSteamStatsAndAchievements
	transient;

var ScrnPlayerController ScrnPCOwner;

simulated event PostBeginPlay()
{
	PCOwner = Level.GetLocalPlayerController();
    ScrnPCOwner = ScrnPlayerController(PCOwner);
    if ( ScrnPCOwner == none ) {
        Destroy();
        return;
    }
	Initialize(PCOwner);
	GetStatsAndAchievements();
}

simulated event OnStatsAndAchievementsReady()
{
	local int i;

	InitStatInt(OwnedWeaponDLC, GetOwnedWeaponDLC());
    
    for ( i=0; i<ScrnPCOwner.DLC.length; ++i ) {
        ScrnPCOwner.DLC[i].bOwnsDLC = PlayerOwnsWeaponDLC(ScrnPCOwner.DLC[i].AppID);
        ScrnPCOwner.DLC[i].bChecked = true; 
    }
	Destroy();
}

defaultproperties
{
     RemoteRole=ROLE_None
     LifeSpan=60.000000
}