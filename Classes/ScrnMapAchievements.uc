Class ScrnMapAchievements extends ScrnAchievements
dependson(ScrnBalance)
abstract;

var const array<localized string> UniversalDescriptions[4];

simulated function SetDefaultAchievementData(int index) 
{
    local string s;
    local int diff_idx;
    
    super.SetDefaultAchievementData(index);
    
    diff_idx = index%4;
    switch ( diff_idx ) {
        case 1:
            AchDefs[index].FilterMaskAny = 0x0002;
            break;
        case 2:
            AchDefs[index].FilterMaskAny = 0x0004; // Custom boss: Doom3 (SE), custom (HardPat) or super boss (SuperPat)
            break;
        case 3:
            AchDefs[index].FilterMaskAll = 0x0008; // doom3
            break;
    }

    s = UniversalDescriptions[diff_idx];
    if ( s != "" && InStr(s, "%m") != -1 ) {
        ReplaceText(s, "%m", AchDefs[index].Description); 
        AchDefs[index].Description = s;           
    }    
}    


/**
 * Tries to find and unlock map achievement
 * @param L         link to player stats
 * @param MapName   Map file name with leading "KF-" but without ".rom"
 * @param DiffIndex 0 - normal, 1 - hard, 2 - sui, 3 - hoe
 * @return -2   Map not found (probably a custom map)
 * @return -1   Error in passed arguments
 * @return  0   Map found, but achievement was already unlocked 
 * @return  1   Map found and achievement unlocked (was locked before)
 */
static final function int UnlockMapAchievement(ClientPerkRepLink L, string MapName, byte DiffIndex)
{
	local SRCustomProgress S;
    local ScrnMapAchievements A;
    local int i;
    
    if ( L == none || DiffIndex < 0 || DiffIndex >= 4 || MapName == "" )
        return -1;

	for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnMapAchievements(S);
		if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; i += 4 ) {
                if ( String(A.AchDefs[i].ID) ~= MapName ) {
                    return int(A.ProgressAchievement(i+DiffIndex, 1));
                }
            }
        }
	}
    return -2;
}

defaultproperties
{
	UniversalDescriptions(0)="Survive on %m in ScrN Balance mode"
	UniversalDescriptions(1)="Survive on %m against Super/Custom specimens and Hardcore Level 5+"
	UniversalDescriptions(2)="Survive on %m against Custom end-game Boss and Hardcore Level 10+"
	UniversalDescriptions(3)="Survive on %m against Doom3 monsters and Hardcore Level 15+"

	DefaultAchGroup="MAP"
	GroupInfo(1)=(Group="MAP",Caption="Maps")
}
