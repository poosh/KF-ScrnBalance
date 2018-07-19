/* CODE BREAKING WARNING in v5.17
Removed AchInfo objects. Used AchDef.CurrentProgress instead

Changed variables and functions:
! AchDef
- SpawnReplicationInfo(), GetAchievementByIndex()
! GetAchievementByID()
+ ClientSetAchProgress()
+ GetIcon(), IsUnlocked()
*/

Class ScrnAchievements extends ScrnCustomProgressBytes
    Abstract;

#exec OBJ LOAD FILE=KillingFloorHUD.utx
#exec OBJ LOAD FILE=KillingFloor2HUD.utx

var texture LockedIcon;

const DATA_USE_PREVIOUS = -1;
const DATA_DONT_USE = -2;

// Copy-Pasted from ScrnBalance
const ACH_ALLFLAGS   = 0xFFFFFFFF;
const ACH_ENABLE     = 0x0001;
const ACH_HARD       = 0x0002;
const ACH_SUI        = 0x0004;
const ACH_HOE        = 0x0008;
const ACH_SCRNZEDS   = 0x0010;
const ACH_WPCZEDS    = 0x0020;
const ACH_HARDPAT    = 0x0040;
const ACH_DOOM3      = 0x0080;

struct AchDef
{
    var name ID;
    var string DisplayName, Description;
    var texture Icon;
    var int MaxProgress;

    var bool bForceShow; // show achievement event if it was earned before

    // Filters achievements to mach ScrnBalanceSrv.AchievementFlags.
    // Used for hiding achievements can't be earned on the current server
    // FilterAll - AchievementFlags must have all bits set respecting filter mask
    // FilterAny - AchievementFlags must have at least one bit set respecting filter mask
    // Achievement will be shown in the list only if both FilterMaskAll and FilterMaskAny
    // requirements are met or mask = 0
    var int FilterMaskAll, FilterMaskAny;

    // How many BITS required to store progress value of the achievement?
    // Value range: 1 - 32. Default = 1
    // Special Values:
    // -1 - use value from previous achievement
    var int DataSize;

    var int CurrentProgress;
    var bool bUnlockedJustNow;
    var bool bDisplayFlag; // use to show/hime achievement from the list

    var name Group;
};
var array<AchDef> AchDefs;
var protected int VisibleAchCount; // achievement count with bDisplayFlag = true. Valid only after SetVisibility() call.

struct AchStrInfo
{
    var ScrnAchievements AchHandler;
    var int AchIndex;
};

//system data to store AchDefs
struct SysInfoRec
{
    var int ArrayIndex;
    var byte BitOffset;
    var byte RealDataSize; // AchDef store suggested size for storing data. This one stores actual
};
var private array<SysInfoRec> SysInfo;

var name DefaultAchGroup; // default value to set to AchDefs.Group
var private array< class<ScrnAchievements> > AchClassList; // add here custom achievement classes to load their data from SP custom progress

struct AchGroupInfo {
    var name                 Group;         // AchDef.Group
    var localized string     Caption;     // what player sees in GUI
};
var array<AchGroupInfo> GroupInfo;


var protected bool bNeedToSetDefaultAchievementData; //if true SetDefaultAchievementData() will be called on InitData()

replication
{
    reliable if( Role == ROLE_Authority )
        ClientSetAchProgress;
}


simulated function InitData()
{
    local int i, index;
    local byte offset;

    if ( Role == ROLE_Authority )
        log(GetItemName(String(class.name)) $ " - loading achievement data for "$PlayerController(Owner).PlayerReplicationInfo.PlayerName, 'ScrnBalance');
    else
        log(GetItemName(String(class.name)) $ " - loading achievement my data", 'ScrnBalance');
    StopWatch(false); // reset timer

    if ( default.bNeedToSetDefaultAchievementData ) {
        // since all instances of the same class have the same data, SetDefaultAchievementData() can be called only once
        // and then set to default values
        SetDefaultAchievementData();
        for ( i = 0; i < AchDefs.Length; ++i ) {
            if ( AchDefs[i].Group == '' )
                AchDefs[i].Group = DefaultAchGroup;
            default.AchDefs[i].Group = AchDefs[i].Group;
            default.AchDefs[i].FilterMaskAny = AchDefs[i].FilterMaskAny;
            default.AchDefs[i].FilterMaskAll = AchDefs[i].FilterMaskAll;
        }
        if ( Level.NetMode != NM_DedicatedServer ) {
            for ( i = 0; i < AchDefs.Length; ++i ) {
                default.AchDefs[i].DisplayName = AchDefs[i].DisplayName;
                default.AchDefs[i].Description = AchDefs[i].Description;
                default.AchDefs[i].Icon = AchDefs[i].Icon;
            }
        }
        default.bNeedToSetDefaultAchievementData = false;
    }

    SysInfo.Length = AchDefs.Length;
    for ( i = 0; i < AchDefs.Length; ++i ) {


        if ( AchDefs[i].DataSize == DATA_DONT_USE ) {
            SysInfo[i].ArrayIndex = DATA_DONT_USE;
            SysInfo[i].BitOffset = 0;
            SysInfo[i].RealDataSize = 32;
        }
        else if ( AchDefs[i].DataSize == DATA_USE_PREVIOUS && i > 0 ) {
            SysInfo[i].ArrayIndex = SysInfo[i-1].ArrayIndex;
            SysInfo[i].BitOffset = SysInfo[i-1].BitOffset;
            SysInfo[i].RealDataSize = SysInfo[i-1].RealDataSize;
        }
        else {
            SysInfo[i].ArrayIndex = index;
            SysInfo[i].BitOffset = offset;
            SysInfo[i].RealDataSize = clamp(AchDefs[i].DataSize, 1, 32);

            //calculate position for the next record
            offset += SysInfo[i].RealDataSize;
            if ( offset >= 8) {
                index += offset/8;
                offset = offset%8;
            }
            // this prevents permamently locked AchDefs in cases when data size is set too short
            // and isn't able to store MaxProgress
            AchDefs[i].MaxProgress = clamp(AchDefs[i].MaxProgress, 1, 2**SysInfo[i].RealDataSize - 1);
        }

        //SpawnReplicationInfo(i);
    }
    if ( offset > 0)
        index++;
    Data.Length = index;

    StopWatch(true); // log elapsed time
}



simulated function SetDefaultAchievementData()
{
    local int i;

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    for ( i = 0; i < AchDefs.Length; ++i ) {
        if (InStr(AchDefs[i].Description, "%c") != -1 )
            ReplaceText(AchDefs[i].Description, "%c", string(AchDefs[i].MaxProgress));
    }
}

simulated function int GetAchievementCount()
{
    return min(AchDefs.length, SysInfo.length);
}

simulated function bool IsAchievementIndexValid(int AchIndex)
{
    return AchIndex >= 0 && AchIndex < GetAchievementCount();
}

protected simulated function int ReadProgressFromData(int AchIndex)
{
    /* Warning! Need to be cautious with data sizes in binary shifting
       and negative bit in comparision (byte is unsigned type)
       Binary shift operators used on byte var return int value anyway, e.g.:
       byte b = 0xFF;
       b = 0xFF << 4 >> 4; // b = 0xFF
       b = 0xFF << 4;
       b = 0xFF >> 4; // b = 0x0F
       b = byte(0xFF << 4) >> 4; // b = 0x0F
    */
    local int count, result, index, bits2load; //bits2load must be integer, cuz it can be negative
    local byte offset, sh, bits_loaded;


    count = GetAchievementCount();
    if ( AchIndex < 0 || AchIndex >= count )
        return 0;


    index = SysInfo[AchIndex].ArrayIndex;
    if ( index == DATA_DONT_USE )
        return 0; // child functions should override ReadProgressFromData to implement getting data from other sources

    offset = SysInfo[AchIndex].BitOffset;
    result = Data[index] >>> offset; //load current byte, shifting by offset - amount of bytes that don't belong to the current record
    bits_loaded = 8 - offset; // how much bits of information are loaded
    bits2load = SysInfo[AchIndex].RealDataSize - bits_loaded;

    //debug
    // LogBytes(Data);
    // log("ReadProgressFromData("$AchIndex$"):"
        // @ "index="$index
        // @ "offset="$offset
        // @ "value_loaded="$result
        // @ "bits_loaded="$bits_loaded
        // @ "bits2load="$bits2load
        // ,'ScrnBalance');

    if (bits2load < 0) {
        //loaded too much - need to clear higher bits
        result = result & 0xFF>>(offset-bits2load);
    }
    else {
        while ( bits2load > 0 ) {
            sh = min(8, bits2load);
            // I'm really sorry about those, who'll try to understand a meaning of the expression below :)
            result = (Data[++index] & 0xFF>>(8-sh))<< bits_loaded | result;
            bits_loaded  += sh;
            bits2load -= sh;
        }
    }

    //log("result="$result,'ScrnBalance');

    return result;
}

protected function WriteProgressToData(int AchIndex, int Value)
{
    local int index;
    local byte offset, bits2write_total, bits2write_cur, mask, val2write;

    if ( !IsAchievementIndexValid(AchIndex) )
        return;


    index = SysInfo[AchIndex].ArrayIndex;
    if ( index == DATA_DONT_USE )
        return; // child functions should override WriteProgressToData to implement writting data to other sources

    offset = SysInfo[AchIndex].BitOffset;
    bits2write_total = SysInfo[AchIndex].RealDataSize;

    //debug
    // log("WriteProgressToData("$AchIndex$", "$Value$"):"
        // @ "index="$index
        // @ "offset="$offset
        // @ "bits2write_total="$bits2write_total
        // ,'ScrnBalance');

    while ( bits2write_total > 0 ) {
        bits2write_cur = min(bits2write_total, 8 - offset);
        // mask has 1 in bits that belong to current value
        mask = (0xFF << offset) & (0xFF >> (8- offset - bits2write_cur));
        //clear old value
        Data[index] = Data[index] & (mask ^ 0xFF);
        //write new value
        val2write = (value << offset) & mask;
        Data[index] = Data[index] | val2write;

        value = value >>> bits2write_cur;
        bits2write_total -= bits2write_cur;
        index++;
        offset = 0;
    }
    //debug
    //LogBytes(Data);

    UpdateValueString();
}



// load achievement progress from Data
protected simulated function UpdateAchievements()
{
    local int i, count, a;

    count = GetAchievementCount();

    for ( i = 0; i < count; ++i ) {
        a = ReadProgressFromData(i);
        if ( a != AchDefs[i].CurrentProgress ) {
            AchDefs[i].CurrentProgress = a;
        }
    }
}

simulated protected function ClientSetAchProgress(int AchIndex, int NewValue, bool bSilent)
{
    local int OldProgress, MaxProgress;
    local ScrnPlayerController PC;

    OldProgress = AchDefs[AchIndex].CurrentProgress;
    MaxProgress = AchDefs[AchIndex].MaxProgress;

    if ( Role < ROLE_Authority ) {
        // authority (solo or listen server) already have this values set in ProgressAchievement()
        AchDefs[AchIndex].CurrentProgress = NewValue;

        if ( OldProgress < MaxProgress && NewValue == MaxProgress )
            AchDefs[AchIndex].bUnlockedJustNow = true;
    }

    PC = ScrnPlayerController(Level.GetLocalPlayerController());
    if ( PC == none )
        return;

    // debug
    // PC.ClientMessage(GetItemName(String(name)) $ "("$AchIndex$") = "$NewValue);
    // log(GetItemName(String(name)) $ "("$AchIndex$") = "$NewValue, 'ScrnBalance');

    if ( !bSilent ) {
        // display achievement in the following circumtances:
        // - it forced to be shown every time by achievement author
        // - it has beed unlocked just now
        // - it has been found out just now (first progression)
        // - there was no achievement progress shown recently (higher progress requirement = rarer displayings)
        // - every 20% of progression
        if ( AchDefs[AchIndex].bForceShow || AchDefs[AchIndex].bUnlockedJustNow || OldProgress == 0 || NewValue == 1
                || ( PC.bAlwaysDisplayAchProgression && MaxProgress < 1000 )
                || PC.AchievementDisplayCooldown < -MaxProgress/5
                || NewValue % (max(MaxProgress/5, 1)) == 0) {
            PC.DisplayAchievementStatus(self, AchIndex);
        }
    }
}

function bool ProgressAchievement(int AchIndex, int Inc)
{
    local int count, IndexToWrite, ProgressToWrite;
    local bool result;
    local bool bSilent;

    if ( !IsAchievementIndexValid(AchIndex) || Inc == 0 || Level.Game.GameDifficulty < 2 )
        return false;

    bReplicateDataToClients = false; // further data updates will be send via ClientSetAchProgress()
    result = (Inc > 0 && AchDefs[AchIndex].CurrentProgress < AchDefs[AchIndex].MaxProgress)
        || (Inc < 0 && AchDefs[AchIndex].CurrentProgress > 0);
    count = GetAchievementCount();

    // in cases when more achevements are sharing the same data
    while ( AchIndex > 0 && AchDefs[AchIndex].DataSize == DATA_USE_PREVIOUS )
        AchIndex--;

    IndexToWrite = AchIndex;

    do {
        if ( Inc < 0 ) {
            AchDefs[AchIndex].CurrentProgress += Inc;
            if ( AchDefs[AchIndex].CurrentProgress < 0 )
                AchDefs[AchIndex].CurrentProgress = 0;
            ClientSetAchProgress(AchIndex, AchDefs[AchIndex].CurrentProgress, true);
        }
        else if ( AchDefs[AchIndex].CurrentProgress < AchDefs[AchIndex].MaxProgress ) {
            AchDefs[AchIndex].CurrentProgress += Inc;
            result = true;
            if ( AchDefs[AchIndex].CurrentProgress >= AchDefs[AchIndex].MaxProgress ) {
                AchDefs[AchIndex].bUnlockedJustNow = true;
                AchDefs[AchIndex].CurrentProgress = AchDefs[AchIndex].MaxProgress; // in case prevprogress + inc > max
                class'ScrnBalance'.default.Mut.AchievementEarned(self, AchIndex);
                AnnounceEarn(self, AchIndex, true);
            }
            ClientSetAchProgress(AchIndex, AchDefs[AchIndex].CurrentProgress, bSilent);
            bSilent = true; //show progress only for a first achievement, if more of them are sharing same data
        }
        else if ( AchDefs[AchIndex].bForceShow ) {
            // achievement is already unlocked, but it is achieved again and author want to show it every time
            AchDefs[AchIndex].bUnlockedJustNow = false;
            ClientSetAchProgress(AchIndex, AchDefs[AchIndex].MaxProgress, false);
            class'ScrnBalance'.default.Mut.AchievementEarned(self, AchIndex);
            AnnounceEarn(self, AchIndex, false);
        }
        ProgressToWrite = max(ProgressToWrite, AchDefs[AchIndex].CurrentProgress);
        AchIndex++;
    } until ( AchIndex >= count || AchDefs[AchIndex].DataSize != DATA_USE_PREVIOUS );

    WriteProgressToData(IndexToWrite, ProgressToWrite);

    return result;
}

static final function bool ProgressAchievementByID(ClientPerkRepLink L, name ID, int Inc)
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
                if ( A.AchDefs[i].ID == ID )
                    return A.ProgressAchievement(i, Inc);
            }
        }
    }
    return false;
}

// override to handle achievement earning events
function AchievementEarned(ScrnAchievements A, int Index, bool bFirstTimeEarned) {}

static final private function AnnounceEarn(ScrnAchievements AchOwner, int AchIndex, bool bFirstTimeEarned)
{
    local SRCustomProgress S;
    local ScrnAchievements A;

    for( S = AchOwner.RepLink.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none )
            A.AchievementEarned(AchOwner, AchIndex, bFirstTimeEarned);
    }
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


simulated function UpdateData()
{
    super.UpdateData();
    UpdateAchievements();
}


// add custom progress values for all AchDefs
static final function InitAchievements(ClientPerkRepLink L)
{
    local int i;

    if ( L == none )
        return;

    for ( i = 0; i < class'ScrnAchievements'.default.AchClassList.Length; ++i ) {
        if ( class'ScrnAchievements'.default.AchClassList[i] != none )
            L.AddCustomValue(class'ScrnAchievements'.default.AchClassList[i]);
    }
}

// use this function to add custom achievements to the list
static final function RegisterAchievements( class<ScrnAchievements> NewAchClass )
{
    local int i;

    for ( i = 0; i < class'ScrnAchievements'.default.AchClassList.Length; ++i ) {
        if ( class'ScrnAchievements'.default.AchClassList[i] == NewAchClass )
            return;
    }
    class'ScrnAchievements'.default.AchClassList[i] = NewAchClass;
}

static final function UnRegisterAchievements( class<ScrnAchievements> AchClass )
{
    local int i;

    for ( i = 0; i < class'ScrnAchievements'.default.AchClassList.Length; ++i ) {
        if ( class'ScrnAchievements'.default.AchClassList[i] == AchClass ) {
            class'ScrnAchievements'.default.AchClassList.remove(i, 1);
            return;
        }
    }
}

static final function ResetAchList()
{
    class'ScrnAchievements'.default.AchClassList.Length = 2;
    class'ScrnAchievements'.default.AchClassList[0] = Class'ScrnBalanceSrv.Ach';
    class'ScrnAchievements'.default.AchClassList[1] = Class'ScrnBalanceSrv.AchMaps';
}

simulated function GetAchievementStats(out int Completed, out int Total, optional int AchievementFlags, optional name Group)
{
    local int i, count;

    Completed = 0;
    Total = 0;
    count = GetAchievementCount();

    for ( i = 0; i < count; ++i ) {
        if ( (Group == '' || Group == AchDefs[i].Group) && FilterMached(AchievementFlags, AchDefs[i].FilterMaskAll, AchDefs[i].FilterMaskAny) ) {
            Total++;
            if ( AchDefs[i].CurrentProgress >= AchDefs[i].MaxProgress )
                Completed++;
        }
    }
}

static final function GetGlobalAchievementStats(ClientPerkRepLink L, out int Completed, out int Total, optional int AchievementFlags, optional name Group)
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

simulated function string GetDisplayString()
{
    local int Completed, Total;
    GetAchievementStats(Completed, Total);
    return Completed $ " / " $ Total;
}



//returns true if Flags matched both FilterAll and FilterAny, or their values are 0
static function bool FilterMached(int Flags, int FilterMaskAll, int FilterMaskAny)
{
    return Flags == 0 || (
            (FilterMaskAll == 0 || (FilterMaskAll & Flags) == FilterMaskAll)
            && (FilterMaskAny == 0 || (FilterMaskAny & Flags) != 0) ); //this reminding me LISP ;)
}

simulated function int GetVisibleAchCount()
{
    return VisibleAchCount;
}

// returns real achievement index (which can be used to access AchDefs) by visible index
// uses bDisplayFlag
// returns -1 if visible index is you of bounds
simulated function int GetVisibleAchIndex(int VisibleIndex)
{
    local int i;
    if ( VisibleAchCount < 0 )
        return -1;

    for ( i=0; i < AchDefs.Length; ++i ) {
        if ( AchDefs[i].bDisplayFlag ) {
            if (VisibleIndex == 0)
                return i;
            else
                VisibleIndex--;
        }
    }

    return -1;
}

// sets bDisplayFlag of AchDefs
simulated function SetVisibility(optional int AchievementFlags, optional name Group, optional bool bOnlyLocked)
{
    local int i;

    VisibleAchCount = 0;
    for ( i = 0; i < AchDefs.length; ++i ) {

        AchDefs[i].bDisplayFlag = (!bOnlyLocked || !IsUnlocked(i) )
                && (Group == '' || Group == AchDefs[i].Group)
                && FilterMached(AchievementFlags, AchDefs[i].FilterMaskAll, AchDefs[i].FilterMaskAny);

        if ( AchDefs[i].bDisplayFlag )
            VisibleAchCount++;
        // else
            // log("Achievement "$AchDefs[i].ID $ " didn't pass filter " $ IntToHex(AchievementFlags), 'ScrnBalance');
    }
}

static final function AchStrInfo GetAchievementByID(ClientPerkRepLink L, name ID, optional bool bOnlyLocked )
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i;
    local AchStrInfo result;

    if ( L == none )
        return result;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                if ( A.AchDefs[i].ID == ID ) {
                    if ( !bOnlyLocked || !A.IsUnlocked(i) ) {
                        result.AchHandler = A;
                        result.AchIndex = i;
                    }
                    return result;
                }
            }
        }
    }
    return result;
}

// returns true if achievement with a given ID is unlocked
// returns false if achievement is locked or doesn't exist
static final function bool IsAchievementUnlocked(ClientPerkRepLink L, name ID)
{
    local AchStrInfo A;

    A = GetAchievementByID(L, ID, false);
    if ( A.AchHandler == none )
        return false;

    return A.AchHandler.IsUnlocked(A.AchIndex);
}

// sets list of all achievement handlers with bDisplayFlag set
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
            count += A.VisibleAchCount;
        }
    }
    return count;
}

static final function ResetAchievements(ClientPerkRepLink L, name Group)
{
    local SRCustomProgress S;
    local ScrnAchievements A;
    local int i;

    if ( L == none )
        return;

    for( S = L.CustomLink; S != none; S = S.NextLink ) {
        A = ScrnAchievements(S);
        if( A != none ) {
            for ( i = 0; i < A.AchDefs.length; ++i ) {
                if ( Group == A.AchDefs[i].Group ) {
                    A.AchDefs[i].CurrentProgress = 0;
                    A.WriteProgressToData(i, 0);
                }
            }
        }
    }
}

simulated function texture GetIcon(int AchIndex)
{
    if ( AchDefs[AchIndex].CurrentProgress >= AchDefs[AchIndex].MaxProgress )
        return AchDefs[AchIndex].Icon;

    return LockedIcon;
}

simulated function bool IsUnlocked(int AchIndex)
{
    return AchDefs[AchIndex].CurrentProgress >= AchDefs[AchIndex].MaxProgress;
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

simulated function string LocalGroupCaption(ClientPerkRepLink L, name GroupName)
{
    local int i;

    for ( i = 0; i < GroupInfo.length; ++i ) {
        if ( GroupInfo[i].Group == GroupName )
            return GroupInfo[i].Caption;
    }
    return "";
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

simulated function ClientPerkRepLink GetRepLink()
{
    if ( RepLink == none && Level.NetMode == NM_Client )
        RepLink = Class'ScrnClientPerkRepLink'.Static.FindMe(Level.GetLocalPlayerController());
    return RepLink;
}



defaultproperties
{
    LockedIcon=Texture'KillingFloorHUD.Achievements.KF_Achievement_Lock'
    AchClassList(0)=Class'ScrnBalanceSrv.Ach'
    AchClassList(1)=Class'ScrnBalanceSrv.AchMaps'
    bFixedDataSize=True
    bReplicateDataToClients=true
    bNeedToSetDefaultAchievementData=true

    GroupInfo(0)=(Group="",Caption="ALL")
}
