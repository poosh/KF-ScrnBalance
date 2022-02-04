class ScrnAchCtrl extends Object
    dependson(ScrnAchievements)
    abstract;

struct SAchCache {
    var ClientPerkRepLink Rep;
    var name ID;
    var ScrnAchievements.AchStrInfo Ach;
};

var private array< class<ScrnAchievements> > AchClassList; // add here custom achievement classes to load their data from SP custom progress

// var private SAchCache LastAch;
// var private SAchCache AchCache[16];
// var private int AchCacheIndex;

static final function ClientPerkRepLink PlayerLink(PlayerController PC)
{
    local SRStatsBase stats;

    if ( PC == none )
        return none;

    stats = SRStatsBase(PC.SteamStatsAndAchievements);
    if ( stats == none )
        return none;

    return stats.Rep;
}

static final function ClientPerkRepLink PawnLink(Pawn P)
{
    if ( P == none )
        return none;

    return PlayerLink(PlayerController(P.Controller));
}

static final function bool Ach2Player(PlayerController PC, name ID, optional int Inc)
{
    return ProgressAchievementByID(PlayerLink(PC), ID, Inc);
}

static final function bool Ach2Pawn(Pawn P, name ID, optional int Inc)
{
    return ProgressAchievementByID(PawnLink(P), ID, Inc);
}

// use this function to add custom achievements to the list
static final function RegisterAchievements( class<ScrnAchievements> NewAchClass )
{
    local int i;

    if ( NewAchClass == none )
        return;

    for ( i = 0; i < default.AchClassList.Length; ++i ) {
        if ( default.AchClassList[i] == NewAchClass )
            return;
    }
    default.AchClassList[i] = NewAchClass;
}

static final function UnRegisterAchievements( class<ScrnAchievements> AchClass )
{
    local int i;

    for ( i = 0; i < default.AchClassList.Length; ++i ) {
        if ( default.AchClassList[i] == AchClass ) {
            default.AchClassList.remove(i, 1);
            return;
        }
    }
}

static final function bool ProgressAchievementByID(ClientPerkRepLink L, name ID, optional int Inc)
{
    local ScrnAchievements.AchStrInfo A;
    local int CacheIndex;

    if ( L == none || L.Level.Game.GameDifficulty < 2 )
        return false;

    if ( !FindAchievement(L, ID, A, CacheIndex) )
        return false;

    if ( Inc == 0 )
        Inc = 1;

    // default.LastAch.ID = ID;
    // default.LastAch.Ach = A;
    // if ( CacheIndex == -1 && A.AchHandler.AchDefs[A.AchIndex].MaxProgress > 1 ) {
    //     // cache achievements with multiple progress because those are accessed more often
    //     default.AchCache[default.AchCacheIndex].ID = ID;
    //     default.AchCache[default.AchCacheIndex].Ach = A;
    //     if ( ++default.AchCacheIndex >= ArrayCount(default.AchCache) )
    //         default.AchCacheIndex = 0;
    // }

    return A.AchHandler.ProgressAchievement(A.AchIndex, Inc);
}

static final function bool ResetAchievementByID(ClientPerkRepLink L, name ID)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i;

    if ( L == none || L.Level.Game.GameDifficulty < 2 )
        return false;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                if ( A.AchDefs[i].ID == ID ) {
                    A.ProgressAchievement(i, -A.AchDefs[i].CurrentProgress);
                    return true;
                }
            }
        }
    }
    return false;
}

static final function GetGlobalAchievementStats(ClientPerkRepLink L, out int Completed, out int Total,
        optional int AchievementFlags, optional name Group)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int c, t;

    Completed = 0;
    Total = 0;

    if ( L == none )
        return;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none )  {
            A.GetAchievementStats(c, t, AchievementFlags, Group);
            Completed += c;
            Total += t;
        }
    }
}

static final function bool FindAchievement(ClientPerkRepLink L, name ID, out ScrnAchievements.AchStrInfo result,
        out int CacheIndex)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i;

    if ( L == none )
        return false;

    // CacheIndex = -1;

    // if ( default.LastAch.ID == ID ) {
    //     result = default.LastAch.Ach;
    //     return true;
    // }

    // for ( i = 0; i < ArrayCount(default.AchCache); ++i ) {
    //     if ( default.AchCache[i].ID == ID ) {
    //         CacheIndex = i;
    //         result = default.AchCache[i].Ach;
    //         return true;
    //     }
    // }
    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none && ScrnMapAchievements(A) == none ) {
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                if ( A.AchDefs[i].ID == ID ) {
                    result.AchHandler = A;
                    result.AchIndex = i;
                    return true;
                }
            }
        }
    }
    return false;
}

static final function ScrnAchievements.AchStrInfo GetAchievementByID(ClientPerkRepLink L, name ID,
        optional bool bOnlyLocked )
{
    local ScrnAchievements.AchStrInfo result;
    local int CacheIndex;

    if ( FindAchievement(L, ID, result, CacheIndex)
            && bOnlyLocked && result.AchHandler.IsUnlocked(result.AchIndex) ) {
        result.AchHandler = none;
    }
    return result;
}

// returns true if achievement with a given ID is unlocked
// returns false if achievement is locked or doesn't exist
static final function bool IsAchievementUnlocked(ClientPerkRepLink L, name ID)
{
    local ScrnAchievements.AchStrInfo A;
    local int i;

    return FindAchievement(L, ID, A, i) && A.AchHandler.IsUnlocked(A.AchIndex);
}

// returns visible achievement count
static final function int GetAllAchievements(ClientPerkRepLink L, out array<ScrnAchievements> AchHandlers,
    optional int AchievementFlags, optional name Group, optional bool bOnlyLocked )
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int count;

    AchHandlers.Length = 0;

    if ( L == none )
        return 0;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            AchHandlers[AchHandlers.Length] = A;
            A.SetVisibility(AchievementFlags, Group, bOnlyLocked);
            count += A.GetVisibleAchCount();
        }
    }
    return count;
}

static final function ResetAchievements(ClientPerkRepLink L, name Group)
{
    local SRCustomProgress S;
    local ScrnAchievements A;

    if ( L == none )
        return;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            A.ResetAchievements(L, Group);
        }
    }
}

static final function RetrieveGroups(ClientPerkRepLink L, out array<name> GroupNames, out array<string> GroupCaptions)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i, j;
    local bool bFound;

    if ( L == none )
        return;

    if ( GroupNames.length != GroupCaptions.length )
        GroupCaptions.length = GroupNames.length;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.GroupInfo.length; ++i ) {
                bFound = false;
                for ( j = 0; j < GroupNames.length; ++j ) {
                    if ( A.GroupInfo[i].Group == GroupNames[j] ) {
                        bFound = true;
                        break;
                    }
                }
                if ( !bFound ) {
                    j = GroupNames.length;
                    GroupNames[j] = A.GroupInfo[i].Group;
                    GroupCaptions[j] = A.GroupInfo[i].Caption;
                }
            }
        }
    }
}

static final function string GroupCaption(ClientPerkRepLink L, name GroupName)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local string result;

    if ( L != none ) {
        for( S = L.CustomLink; S != none; S = S.NextLink ) {
            A = ScrnAchievements(S);
            if( A != none ) {
                result = A.LocalGroupCaption(L, GroupName);
                if ( result != ""  )
                    return result;
            }
        }
    }
    return string(GroupName);
}


// --- INTERNAL FUNCTIONS --------------------------------

// add custom progress values for all AchDefs
// Invoked internally by ScrnBalance.
// Do not call this directly!
static final function InitLink(ClientPerkRepLink L)
{
    local int i;

    if ( L == none )
        return;

    for ( i = 0; i < default.AchClassList.Length; ++i ) {
        if ( default.AchClassList[i] != none )
            L.AddCustomValue(default.AchClassList[i]);
    }
}

// Invoked internally by ScrnBalance.
// Do not call this directly!
static final function Cleanup()
{
    // local int i;

    default.AchClassList.Length = 2;
    default.AchClassList[0] = class'Ach';
    default.AchClassList[1] = class'AchMaps';

    // default.LastAch.Ach.AchHandler = none;
    // for ( i = 0; i < ArrayCount(default.AchCache); ++i ) {
    //     default.AchCache[i].ID = '';
    //     default.AchCache[i].Ach.AchHandler = none;
    // }
}

defaultproperties
{
    AchClassList(0)=class'Ach'
    AchClassList(1)=class'AchMaps'
}
