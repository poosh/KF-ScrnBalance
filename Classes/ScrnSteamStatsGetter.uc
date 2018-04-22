Class ScrnSteamStatsGetter extends KFSteamStatsAndAchievements
    transient;

var ScrnPlayerController ScrnPCOwner;
var ClientPerkRepLink Link;

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
    local int i, j;
    local class<KFWeapon> W;

    if ( Link == none )
        Link = Class'ScrnClientPerkRepLink'.Static.FindMe(PCOwner);
    InitStatInt(OwnedWeaponDLC, GetOwnedWeaponDLC());
    
    // weapon skins
    for ( j=0; j<ScrnPCOwner.DLC.length; ++j ) {
        ScrnPCOwner.DLC[j].bOwnsDLC = PlayerOwnsWeaponDLC(ScrnPCOwner.DLC[j].AppID);
        ScrnPCOwner.DLC[j].bChecked = true; 
    }
    
    // trader inventory    
    for( i=(Link.ShopInventory.Length-1); i>=0; --i ) {
        if ( Link.ShopInventory[i].bDLCLocked != 1 )
            continue;
            
        W = class<KFWeapon>(Link.ShopInventory[i].PC.Default.InventoryType);
        if( W != none ) {
            // Who cares about stupid vanilla achievements? :)
            //bCheckAch = W.Default.UnlockedByAchievement >= 0;
            if( W.Default.AppID == 0 ) 
                Link.ShopInventory[i].bDLCLocked = 0;
            else {
                for ( j=0; j<ScrnPCOwner.DLC.length; ++j ) {
                    if ( ScrnPCOwner.DLC[j].AppID == W.Default.AppID )
                        break;
                }     
                if ( j == ScrnPCOwner.DLC.length ) {
                    // new DLC
                    ScrnPCOwner.DLC.insert(j,1);
                    ScrnPCOwner.DLC[j].AppID = W.Default.AppID;
                    ScrnPCOwner.DLC[j].bOwnsDLC = PlayerOwnsWeaponDLC(ScrnPCOwner.DLC[j].AppID);
                    ScrnPCOwner.DLC[j].bChecked = true;                     
                }
                if ( ScrnPCOwner.DLC[j].bOwnsDLC )
                    Link.ShopInventory[i].bDLCLocked = 0;
            }
        }
    }
    // for ( i = 0; i < Achievements.Length; i++ )
        // GetAchievementDescription(Achievements[i].SteamName, Default.Achievements[i].DisplayName, Default.Achievements[i].Description);    
     
    // fix for solo mode or listen server
    if ( ScrnPCOwner.SteamStatsAndAchievements != none && (Level.NetMode == NM_ListenServer || Level.NetMode == NM_Standalone) )
        ScrnPCOwner.PlayerReplicationInfo.SteamStatsAndAchievements = ScrnPCOwner.SteamStatsAndAchievements;

    Destroy();
}

defaultproperties
{
     RemoteRole=ROLE_None
     LifeSpan=60.000000
}