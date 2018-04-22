Class ScrnMapAchievements extends ScrnAchievements
dependson(ScrnBalance)
abstract;

var const array<localized string> UniversalDescriptions[4];
var const array<int> UniversalFilters[4];
var const array<localized string> MapDifficultyNames[4];

simulated function SetDefaultAchievementData()
{
    local int i;
    local byte d;
    local string s;

    super.SetDefaultAchievementData();

    for ( i = 0; i < AchDefs.Length; ++i ) {
        AchDefs[i].FilterMaskAll = UniversalFilters[d];
        if ( ++d > 3 )
            d = 0;
    }

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    d = 0;
    for ( i = 0; i < AchDefs.Length; ++i ) {
        s = UniversalDescriptions[d];
        ReplaceText(s, "%m", AchDefs[i].Description);
        AchDefs[i].Description = s;
        if ( ++d > 3 )
            d = 0;
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

// Added Support for special groups
simulated function GetAchievementStats(out int Completed, out int Total, optional int AchievementFlags, optional name Group)
{
    local int i, count;
    local byte MinDiff, Diff;

    Completed = 0;
    Total = 0;
    count = GetAchievementCount();

    switch ( Group ) {
        case 'MAP_Normal':
            MinDiff=0;
            Group='';
            break;
        case 'MAP_Hard':
            MinDiff=1;
            Group='';
            break;
        case 'MAP_Sui':
            MinDiff=2;
            Group='';
            break;
        case 'MAP_HoE':
            MinDiff=3;
            Group='';
            break;
    }

    for ( i = 0; i < count; ++i ) {
        if ( (Group == '' || Group == AchDefs[i].Group) && Diff >= MinDiff && FilterMached(AchievementFlags, AchDefs[i].FilterMaskAll, AchDefs[i].FilterMaskAny) ) {
            Total++;
            if ( AchDefs[i].CurrentProgress >= AchDefs[i].MaxProgress )
                Completed++;
        }
        if ( Diff == 3 )
            Diff = 0;
        else
            Diff++;
    }
}

simulated function string LocalGroupCaption(ClientPerkRepLink L, name Group)
{
    switch ( Group ) {
        case 'MAP_Normal':  return MapDifficultyNames[0];
        case 'MAP_Hard':    return MapDifficultyNames[1];
        case 'MAP_Sui':     return MapDifficultyNames[2];
        case 'MAP_HoE':     return MapDifficultyNames[3];
    }
    return super.LocalGroupCaption(L, Group);

}

defaultproperties
{
    UniversalDescriptions(0)="Survive on %m in ScrN Balance mode"
    UniversalDescriptions(1)="Survive on %m against Super/Custom specimens and Hardcore Level 5+"
    UniversalDescriptions(2)="Survive on %m in Turbo mode or against Custom end-game Boss and HL 10+"
    UniversalDescriptions(3)="Survive on %m in FTG mode or against Doom3 monsters and HL 15+"

    UniversalFilters(0)=0
    UniversalFilters(1)=2 // custom monsters
    UniversalFilters(2)=4 // Custom boss: Doom3 (SE), custom (HardPat) or super boss (SuperPat)
    UniversalFilters(3)=8 // doom3

    MapDifficultyNames(0)="Map"
    MapDifficultyNames(1)="Hard+ Map"
    MapDifficultyNames(2)="Suicidal+ Map"
    MapDifficultyNames(3)="HoE Map"

    DefaultAchGroup="MAP"
    GroupInfo(1)=(Group="MAP",Caption="Maps")
}
