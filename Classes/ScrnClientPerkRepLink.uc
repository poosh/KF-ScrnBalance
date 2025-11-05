class ScrnClientPerkRepLink extends ClientPerkRepLink
dependson(ScrnBalance)
dependson(ScrnAchievements);

var ScrnPlayerController OwnerPC;

var String CurrentJob; // for debug purposes
var byte TotalCategories, TotalPerks;
var int TotalWeaponBonuses, TotalWeapons, TotalChars, TotalLocks, TotalZeds;
var transient float RepStartTime;
var bool bClientDebug;
var transient int LastAckIndex;
var int NetSpeed;
var int WindowSize;
var int NetBurstSize;
var float SleepTime;
var float WaitForAckTime;
var transient int ClientAckRequests;
var transient float NextClientAckRequestTime;
var array< class<KFMonster> > Zeds;
var transient bool bShopInited;

const DLC_LOCK_STEAM_APP    = 1;
const DLC_LOCK_STEAM_ACH    = 2;
const DLC_LOCK_SCRN         = 5;

struct SPickupLock {
    var class<Pickup> PickupClass;
    var byte Group;
    var ScrnBalance.ECustomLockType Type;
    var name ID;

    var material Icon;
    var string Title, Text;
    var int MaxProgress, CurProgress;

    var ScrnAchievements.AchStrInfo AchInfo; // used by LOCK_Ach only
    // if true, then lock state can't be changed during the rest of the game anymore,
    // and there is no need to parse it anymore
    var bool bNoParse;
    var bool bUnlocked; // true if this or any in its group unlocked
};
var array<SPickupLock> Locks;
var material IconPerkLocked, IconAchLocked, IconGrpLocked, IconChecked;

var protected array<ScrnBalance.SNameValuePair> PermGroupStats; // achievement group stats that do not change during the game
var transient protected array<ScrnBalance.SNameValuePair> GroupStatCache; // cache group stats to avoid multiple calls on the same group

var localized string strLevelTitle, strLevelText;
var localized string strUnknownAchTitle, strUnknownAchText;
var localized string strGrpTitle, strGrpText;


struct SWeaponBonus {
    var class <ScrnVeterancyTypes> Perk;
    var class <KFWeapon> Weapon;
    var int BonusMask;
};
var array<SWeaponBonus> WeaponBonuses;

const JOB_PERK            = 1;
const JOB_WEAPONBONUS     = 2;
const JOB_SHOPCATEGOGY    = 3;
const JOB_SHOPITEM        = 4;
const JOB_DLCLOCK         = 5;
const JOB_ZED             = 6;
const JOB_CHAR            = 7;
const JOB_EMOJI           = 8;
const JOB_DONE            = 0xFFFF;
var transient int JobID;
var transient int JobItemCount;
var transient float JobStartTime;
var transient int JobBurstSize, JobBurstLeft;

delegate JobWorker(int Index);

replication
{
    reliable if ( bNetOwner && bNetInitial && Role == ROLE_Authority )
        TotalPerks, TotalCategories;

    reliable if ( bNetOwner && bNetInitial && Role == ROLE_Authority )
        TotalWeaponBonuses, TotalWeapons, TotalLocks, TotalChars, TotalZeds;

    reliable if ( Role < ROLE_Authority )
        ServerStartInitialReplication, ServerAck, ServerSelectPerkSE;

    reliable if ( Role == ROLE_Authority )
        ClientReceiveLevelLock, ClientReceiveAchLock, ClientReceiveGroupLock, ClientReceiveZed, ClientReceiveTagSE,
        ClientReceiveWeaponBonus;

    reliable if ( Role == ROLE_Authority )
        ReliableClientAckRequest, ClientStartJob;

    unreliable if ( Role == ROLE_Authority )
        UnreliableClientAckRequest;

}

// Just look for the stats. Don't do mysterious things as Marco intended in FindStats()
static final function ScrnClientPerkRepLink FindMe( PlayerController MyOwner )
{
    local LinkedReplicationInfo L;
    local ScrnClientPerkRepLink PerkLink;

    if( MyOwner == none || MyOwner.PlayerReplicationInfo == None )
        return none;

    if ( MyOwner.Level.NetMode != NM_Client && SRStatsBase(MyOwner.SteamStatsAndAchievements) != none ) {
        PerkLink = ScrnClientPerkRepLink(SRStatsBase(MyOwner.SteamStatsAndAchievements).Rep);
        if ( PerkLink != none )
            return PerkLink;
    }

    for( L=MyOwner.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo ) {
        PerkLink = ScrnClientPerkRepLink(L);
        if( PerkLink != None )
            return PerkLink;
    }
    if ( MyOwner.Level.NetMode == NM_Client ) {
        foreach MyOwner.DynamicActors(Class'ScrnClientPerkRepLink',PerkLink) {
            // not added to PRI yet
            PerkLink.OwnerPC = ScrnPlayerController(MyOwner);
            PerkLink.OwnerPRI = KFPlayerReplicationInfo(MyOwner.PlayerReplicationInfo);
            PerkLink.AddMeToPRI();
            return PerkLink;
        }
    }
    return none;
}

simulated function AddMeToPRI()
{
    local LinkedReplicationInfo L;

    if ( OwnerPRI.CustomReplicationInfo == none )
        OwnerPRI.CustomReplicationInfo = self;
    else {
        for( L=OwnerPRI.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo ) {
            if( L==self )
                return; // Make sure not already added.
            if ( L.NextReplicationInfo == none ) {
                L.NextReplicationInfo = self;
                NextReplicationInfo = none; // avoid circular links in case we received it from server
                return;
            }
        }
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if ( Role < ROLE_Authority ) {
        log("ScrnClientPerkRepLink spawned", class.name);
        StartClientInitialReplication();
    }
}


simulated function ClientReceivePerk( int Index, class<SRVeterancyTypes> V, byte lvl )
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Perk " $ (Index+1)$"/"$TotalPerks @ V $ " Level=" $ lvl, 'log');

    // Setup correct icon for trader.
    if( V.Default.PerkIndex<255 && V.Default.OnHUDIcon!=None )
    {
        if( ShopPerkIcons.Length <= V.Default.PerkIndex )
            ShopPerkIcons.Length = V.Default.PerkIndex+1;
        ShopPerkIcons[V.Default.PerkIndex] = V.Default.OnHUDIcon;
    }

    if( CachePerks.Length <= Index )
        CachePerks.Length = Index+1;
    CachePerks[Index].PerkClass = V;
    ClientPerkLevel(Index, lvl);
    OnClientRepItemReceived(Index);
}

simulated function ClientPerkLevel( int Index, byte NewLevel )
{
    if ( NewLevel == 255 ) {
        class<ScrnVeterancyTypes>(CachePerks[Index].PerkClass).default.bLocked = true;
        CachePerks[Index].CurrentLevel = 0;
    }
    else if ( (NewLevel & 0x80) > 0 ) {
        // highest bit indicates that perk should be unlocked
        class<ScrnVeterancyTypes>(CachePerks[Index].PerkClass).default.bLocked = false;
        CachePerks[Index].CurrentLevel = NewLevel & 0x7F;
    }
    else if ( class<ScrnVeterancyTypes>(CachePerks[Index].PerkClass).default.bLocked == false ) {
        if ( CachePerks[Index].CurrentLevel > 0 && NewLevel > CachePerks[Index].CurrentLevel )
            Level.GetLocalPlayerController().ReceiveLocalizedMessage(Class'ScrnPromotedMessage',(NewLevel-1),,,CachePerks[Index].PerkClass);
        CachePerks[Index].CurrentLevel = NewLevel;
    }
}

function ServerSelectPerkSE(class<ScrnVeterancyTypes> VetType)
{
    local KFGameType KF;
    local bool bDifferentPerk;

    KF = KFGameType(Level.Game);

    if ( VetType == none || VetType.default.bLocked )
        OwnerPC.ClientMessage(OwnerPC.strPerkLocked);
    else if ( OwnerPC == none || KF == none || KF.bWaitingToStartMatch || OwnerPC.Mut.bAllowAlwaysPerkChanges )
        StatObject.ServerSelectPerk(VetType);
    else {
        if ( OwnerPC.Mut.bNoPerkChanges && OwnerPC.bHadPawn
                && (!OwnerPC.Mut.bPerkChangeBoss || OwnerPC.Mut.bTSCGame || KF.WaveNum < KF.FinalWave)
                && (!OwnerPC.Mut.bPerkChangeDead || (OwnerPC.Pawn != none && OwnerPC.Pawn.Health > 0)) )
        {
            OwnerPC.ClientMessage(OwnerPC.strNoPerkChanges);
            return;
        }

        if ( KF.WaveNum == OwnerPC.PerkChangeWave && !KF.bWaveInProgress ) {
            OwnerPC.ClientMessage(OwnerPC.PerkChangeOncePerWaveString);
            return;
        }

        bDifferentPerk = OwnerPRI != none && VetType != OwnerPRI.ClientVeteranSkill;
        StatObject.ServerSelectPerk(VetType);
        if ( bDifferentPerk && VetType == OwnerPRI.ClientVeteranSkill )
            OwnerPC.PerkChangeWave = KF.WaveNum;
    }
}

function bool ForcePerk(class<ScrnVeterancyTypes> Perk, optional bool bDisableNotify)
{
    local int i;
    local ScrnHumanPawn ScrnPawn;

    for (i = 0; i < CachePerks.Length; ++i) {
        if (CachePerks[i].PerkClass == Perk) {
            if (CachePerks[i].CurrentLevel == 0)
                return false;
            OwnerPC.SelectedVeterancy = Perk;
            OwnerPRI.ClientVeteranSkill = Perk;
            OwnerPRI.ClientVeteranSkillLevel = CachePerks[i].CurrentLevel - 1;
            if (!bDisableNotify) {
                ScrnPawn = ScrnHumanPawn(OwnerPC.Pawn);
                if (ScrnPawn != none) {
                    ScrnPawn.VeterancyChanged();
                }
            }
            return true;
        }
    }
    return false;
}

// this is triggered every time client receives any item from the server
simulated function OnClientRepItemReceived(int Index) {
    SendIndex = Index;
    if (Index + 1 == JobItemCount || (Index - LastAckIndex) >= (WindowSize >> 1)) {
        // log(GetJobName() $ " OnClientRepItemReceived send ACK on item #" $ Index, class.name);
        ServerAck(JobID, SendIndex);
        LastAckIndex = SendIndex;
    }
}

simulated function ClientReceiveWeaponBonus(int Index, class <ScrnVeterancyTypes> Perk, class <KFWeapon> Weapon,
        int BonusMask)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("WeaponBonus " $ (Index+1)$"/"$TotalWeaponBonuses @ Weapon $ " for " $ Perk
                $ " BonusMask=" $ BonusMask, 'log');

    WeaponBonuses[Index].Perk = Perk;
    WeaponBonuses[Index].Weapon = Weapon;
    WeaponBonuses[Index].BonusMask = BonusMask;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveCategory(byte Index, FShopCategoryIndex S)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Category " $ (Index+1)$"/"$TotalCategories@ S.Name, 'log');

    ShopCategories[Index] = S;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveWeapon(int Index, class<Pickup> P, byte Categ)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Weapon " $ (Index+1)$"/"$TotalWeapons @ P, 'log');

    ShopInventory[Index].PC = P;
    ShopInventory[Index].CatNum = Categ;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveZed(int Index, class<KFMonster> Zed)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Zed " $ Zed, 'log');

    Zeds[Index] = Zed;
    Zed.static.PreCacheMaterials(Level);
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveLevelLock(int Index, class<Pickup> PC, byte Group, byte MinLevel)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("LevelLock " $ (Index+1)$"/"$TotalLocks @ PC, 'log');

    Locks[Index].Type = LOCK_Level;
    Locks[Index].PickupClass = PC;
    Locks[Index].Group = Group;
    Locks[Index].MaxProgress = MinLevel;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveAchLock(int Index, class<Pickup> PC, byte Group, name Achievement)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("AchLock " $ (Index+1)$"/"$TotalLocks @ PC @ Achievement, 'log');

    Locks[Index].Type = LOCK_Ach;
    Locks[Index].PickupClass = PC;
    Locks[Index].Group = Group;
    Locks[Index].ID = Achievement;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveGroupLock(int Index, class<Pickup> PC, byte Group, name AchGroup, byte Count)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("GroupLock " $ (Index+1)$"/"$TotalLocks @ PC@ AchGroup, 'log');

    Locks[Index].Type = LOCK_AchGroup;
    Locks[Index].PickupClass = PC;
    Locks[Index].Group = Group;
    Locks[Index].ID = AchGroup;
    Locks[Index].MaxProgress = Count;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveChar(string CharName, int Index)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Character " $ (Index+1)$"/"$TotalChars@ CharName, 'log');

    CustomChars[Index] = CharName;
    OnClientRepItemReceived(Index);
}

simulated function ClientReceiveTagSE(int Index, Texture T, string Tag, bool bInCaps)
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("SmileyTag " $ Tag, 'log');

    ClientReceiveTag(T, Tag, bInCaps);
    OnClientRepItemReceived(Index);
}

// depricated
simulated function ClientSendAcknowledge();

simulated function InitShop()
{
    local int i;
    local class<KFWeapon> WC;

    InitCustomLocks();
    // Marks Steam DLC requirements
    for (i = 0; i < ShopInventory.length; ++i) {
        if (ShopInventory[i].bDLCLocked != DLC_LOCK_SCRN) {
            WC = class<KFWeapon>(ShopInventory[i].PC.Default.InventoryType);
            if (WC != none && WC.Default.AppID > 0)
                ShopInventory[i].bDLCLocked = DLC_LOCK_STEAM_APP;
        }
    }
    bShopInited = true;
}

simulated function ClientAllReceived()
{
    bRepCompleted = true;
    CurrentJob = "ALL OK";
    JobID = JOB_DONE;

    if (OwnerPC != Level.GetLocalPlayerController())
        return;  // Remote client on a listen server

    InitShop();

    if (SmileyTags.Length > 0 && ScrnHUD(OwnerPC.MyHUD) != none) {
        ScrnHUD(OwnerPC.MyHUD).SmileyMsgs = SmileyTags;
    }

    Spawn(Class'ScrnSteamStatsGetter', OwnerPC).Link = self;
}

simulated protected function int GetAchGroupProgress(name GroupName)
{
    local int i, v, m;

    for ( i=0; i<PermGroupStats.length; ++i ) {
        if ( PermGroupStats[i].ID == GroupName )
            return PermGroupStats[i].Value;
    }
    for ( i=0; i<GroupStatCache.length; ++i ) {
        if ( GroupStatCache[i].ID == GroupName )
            return GroupStatCache[i].Value;
    }
    class'ScrnAchCtrl'.static.GetGlobalAchievementStats(self, v, m, 0, GroupName);
    GroupStatCache.insert(i, 1);
    GroupStatCache[i].ID = GroupName;
    GroupStatCache[i].Value = v;
    return v;
}

// fills permanent data of Locks. Should be called only once. But it is safe to call it multiple times
simulated function InitCustomLocks()
{
    local int i, j, a;
    local string s, g;
    local class<Pickup> PC;

    // load and store map achievement stats
    for ( i=0; i<PermGroupStats.length; ++i ) {
        class'ScrnAchCtrl'.static.GetGlobalAchievementStats(self, j, a, 0, PermGroupStats[i].ID);
        PermGroupStats[i].Value = j;
    }

    for ( i=0; i<Locks.length; ++i ) {
        // mark corresponding shop inventory items as ScrN-locked
        if ( Locks[i].PickupClass != PC ) {
            PC = Locks[i].PickupClass;
            for( j=0; j<ShopInventory.Length; ++j ) {
                if ( ShopInventory[j].PC == PC )
                    ShopInventory[j].bDLCLocked = DLC_LOCK_SCRN;
            }
        }

        switch ( Locks[i].Type ) {
            case LOCK_Level:
                if ( Level.NetMode != NM_DedicatedServer ) {
                    Locks[i].Icon = IconPerkLocked;
                    s = strLevelTitle;
                    s = Repl(s, "%C", string(Locks[i].MaxProgress));
                    Locks[i].Title = s;
                    s = strLevelText;
                    s = Repl(s, "%C", string(Locks[i].MaxProgress));
                    Locks[i].Text = s;
                }
                break;

            case LOCK_Ach:
                Locks[i].AchInfo = class'ScrnAchCtrl'.static.GetAchievementByID(self, Locks[i].ID);
                if ( Locks[i].AchInfo.AchHandler == none ) {
                    if ( Level.NetMode != NM_DedicatedServer ) {
                        Locks[i].Title = strUnknownAchTitle;
                        Locks[i].Text = strUnknownAchText;
                        Locks[i].Icon = IconAchLocked;
                    }
                    Locks[i].MaxProgress = 1;
                    Locks[i].CurProgress = 0;
                    Locks[i].bNoParse = true;
                }
                else if ( Level.NetMode != NM_DedicatedServer ) {
                    Locks[i].Title = Locks[i].AchInfo.AchHandler.AchDefs[Locks[i].AchInfo.AchIndex].DisplayName;
                    Locks[i].Text = Locks[i].AchInfo.AchHandler.AchDefs[Locks[i].AchInfo.AchIndex].Description;
                    Locks[i].Icon = Locks[i].AchInfo.AchHandler.GetIcon(Locks[i].AchInfo.AchIndex);
                }
                break;

            case LOCK_AchGroup:
                // map achievements can't change during the game, so get stats only once
                for ( j=0; j<PermGroupStats.length; ++j ) {
                    if ( PermGroupStats[j].ID == Locks[i].ID ) {
                        Locks[i].CurProgress = PermGroupStats[j].Value;
                        Locks[i].bNoParse = true;
                    }
                }
                if ( Level.NetMode != NM_DedicatedServer ) {
                    g = class'ScrnAchCtrl'.static.GroupCaption(self, Locks[i].ID);
                    s = strGrpTitle;
                    s = Repl(s, "%C", string(Locks[i].MaxProgress));
                    s = Repl(s, "%G", g);
                    Locks[i].Title = s;
                    s = strGrpText;
                    s = Repl(s, "%C", string(Locks[i].MaxProgress));
                    s = Repl(s, "%G", g);
                    Locks[i].Text = s;

                    if ( Locks[i].CurProgress >= Locks[i].MaxProgress )
                        Locks[i].Icon = IconChecked;
                    else
                        Locks[i].Icon = IconGrpLocked;
                }
                break;
        }
    }
    ParseLocks();
}

simulated function ParseLocks()
{
    local int i, PerkLevel;

    GroupStatCache.length = 0; // force update

    // just to be sure
    // if ( OwnerPRI == none ) {
        // if ( Role == ROLE_Authority )
            // OwnerPRI = KFPlayerReplicationInfo(StatObject.PlayerOwner.PlayerReplicationInfo);
        // else
            // OwnerPRI = KFPlayerReplicationInfo(Level.GetLocalPlayerController().PlayerReplicationInfo);
    // }
    if ( OwnerPRI != none )
        PerkLevel = OwnerPRI.ClientVeteranSkillLevel;

    for ( i=0; i<Locks.length; ++i ) {
        if ( Locks[i].bNoParse )
            continue;

        switch ( Locks[i].Type ) {
            case LOCK_Level:
                Locks[i].CurProgress = PerkLevel;
                if ( Locks[i].CurProgress >= Locks[i].MaxProgress )
                    Locks[i].Icon = IconChecked;
                else
                    Locks[i].Icon = IconPerkLocked;
                break;

            case LOCK_Ach:
                Locks[i].MaxProgress = Locks[i].AchInfo.AchHandler.AchDefs[Locks[i].AchInfo.AchIndex].MaxProgress;
                Locks[i].CurProgress = Locks[i].AchInfo.AchHandler.AchDefs[Locks[i].AchInfo.AchIndex].CurrentProgress;
                if ( Locks[i].CurProgress >= Locks[i].MaxProgress ) {
                    Locks[i].Icon = Locks[i].AchInfo.AchHandler.GetIcon(Locks[i].AchInfo.AchIndex);
                    Locks[i].bNoParse = true;
                }
                break;

            case LOCK_AchGroup:
                Locks[i].CurProgress = GetAchGroupProgress(Locks[i].ID);
                if ( Locks[i].CurProgress >= Locks[i].MaxProgress ) {
                    Locks[i].Icon = IconChecked;
                    Locks[i].bNoParse = true;
                }
                break;
        }
    }
}

/**
 * Function checks if shop inventory item is locked by ScrN locks.
 * It assumes that Locks have already been parsed and sorted by group number.
 * Call ParseLocks() to ensure that Locks have been parsed.
 * @param   Index   item index in ShopInventory array
 * @return  true    if shop inventory item is unlocked (available for purchase)
*/
simulated function bool IsShopInventoryUnlocked(int Index)
{
    local byte result;

    if ( Index <= 0 || Index >= ShopInventory.Length )
        return false;
    if ( ShopInventory[Index].bDLCLocked != DLC_LOCK_SCRN )
        return true;

    result = IsPickupUnlocked(ShopInventory[Index].PC);
    if (result == 2)
        ShopInventory[Index].bDLCLocked = 0; // permanently mark item as unlocked
    return result > 0;
}

/**
 * Function checks if item is locked by ScrN locks.
 * It assumes that Locks have already been parsed and sorted by group number.
 * @param   PC  item class to check
 * @return  0 - item is locked
 *          1 - temporary unlocked (may change during game)
 *          2 - permanently unlocked (will stay unlocked till the rest of the game and no need to check it anymore)
 */
simulated function byte IsPickupUnlocked(class<Pickup> PC)
{
    local int i, j;
    local byte LastLockedGroup, LastUnlockedGroup;
    local bool bLevelLock;

    for ( i=0; i<Locks.length; ++i ) {
        if ( Locks[i].PickupClass != PC || Locks[i].bUnlocked )
            continue;

        if ( LastLockedGroup > 0 && Locks[i].Group != LastLockedGroup )
            return 0; // previous group wan't unlocked

        if ( Locks[i].CurProgress >= Locks[i].MaxProgress ) {
            // this achievement is unlocked
            LastUnlockedGroup = Locks[i].Group;
            LastLockedGroup = 0; // make sure this group is not locked anymore
            if ( Locks[i].Type == LOCK_Level )
                bLevelLock = true; // level lock isn't permanent
            else {
                Locks[i].bUnlocked = true;
                if ( LastUnlockedGroup > 0 ) {
                    // mark all locks in the current group as unlocked
                    for ( j=0; j<Locks.length; ++j ) {
                        if ( Locks[j].PickupClass == PC && Locks[j].Group == LastUnlockedGroup )
                            Locks[j].bUnlocked = true;
                    }
                }
            }
        }
        else if ( Locks[i].Group == 0 )
            return 0;
        else if ( Locks[i].Group != LastUnlockedGroup )
            LastLockedGroup = Locks[i].Group; // check if next achievements in the same group are unlocked
    }
    if ( LastLockedGroup > 0 )
        return 0;

    // if we reached here, than item is unlocked
    if ( bLevelLock )
        return 1;

    return 2;
}

simulated function int FindShopInventoryIndex(class<Pickup> PC)
{
    local int i;

    for( i = 0; i < ShopInventory.length; ++i ) {
        if( ShopInventory[i].PC == PC )
            return i;
    }
    return -1;
}

simulated function bool IsInShopInventory(class<Pickup> PC)
{
    return FindShopInventoryIndex(PC) != -1;
}

simulated function Tick( float DeltaTime )
{
    Disable('Tick');
    // if replication link is broken, then it is better for client to reconnect rather
    // than trying "fixing" stuff, which at the end makes things even worse
}

simulated function string GetJobName()
{
    return "Job #" $ JobID $ " - " $ CurrentJob;
}

simulated function InitWeaponBonuses()
{
    local int i;

    for (i = 0; i < WeaponBonuses.Length; ++i) {
        class'ScrnGlobalRepLink'.static.AddWeaponBonuses(WeaponBonuses[i].Perk, WeaponBonuses[i].Weapon,
                WeaponBonuses[i].BonusMask);
    }
}



//=============================================================================
// CLIENT STATES
//=============================================================================

simulated function StartClientInitialReplication()
{
    if (Role == ROLE_Authority)
        return;

    GotoState('ClientInitialWaiting');
}

simulated function ClientStartJob(int ID, int ItemCount, int NewWindowSize)
{
    if (JobID > 0) {
        ClientEndJob();
    }

    JobID = ID;
    JobItemCount = ItemCount;
    WindowSize = NewWindowSize;
    JobStartTime = Level.TimeSeconds;
    SendIndex = -1;
    LastAckIndex = -1;
    CurrentJob = "";

    switch(JobID) {
        case JOB_PERK:
            CurrentJob = "Receiving Perks";
            break;
        case JOB_WEAPONBONUS:
            CurrentJob = "Receiving Weapon Bonuses";
            break;
        case JOB_SHOPCATEGOGY:
            CurrentJob = "Receiving Shop Categories";
            break;
        case JOB_SHOPITEM:
            CurrentJob = "Receiving Shop Items";
            break;
        case JOB_DLCLOCK:
            CurrentJob = "Receiving DLC Locks";
            break;
        case JOB_ZED:
            CurrentJob = "Receiving Zeds";
            break;
        case JOB_CHAR:
            CurrentJob = "Receiving Characters";
            break;
        case JOB_EMOJI:
            CurrentJob = "Receiving Emoji";
            break;
    }

    log(GetJobName() $ " started (" $ JobItemCount $ " items)", class.name);
}

simulated function ClientEndJob()
{
    log(GetJobName() $ " finished in " $ (Level.TimeSeconds - JobStartTime) $ "s", class.name);

    switch (JobID) {
        case JOB_WEAPONBONUS:
            InitWeaponBonuses();
            break;
    }
}

simulated function ClientAckRequest(int AckRequest, int SrvJobID, int SrvIndex, int SrvWindowSize)
{
    log("Server requires ACK (#"$AckRequest$"). Job #" $ SrvJobID $ ", Server item #" $ SrvIndex
            $ ". Our last received item #" $ SendIndex, class.name);
    if (SrvJobID != JobID) {
        log("Job sync mismatch. Server Job # " $ SrvJobID $ ". Our " $ GetJobName(), class.name);
    }
    if (SrvWindowSize != WindowSize) {
        log("WindowSize adjust: " $ WindowSize $ " => " $ SrvWindowSize, class.name);
        WindowSize = SrvWindowSize;
    }
    ServerAck(JobID, SendIndex);
}

simulated function ReliableClientAckRequest(int SrvJobID, int SrvIndex, int SrvWindowSize)
{
    ClientAckRequest(0, SrvJobID, SrvIndex, SrvWindowSize);
}

simulated function UnreliableClientAckRequest(int AckRequest, int SrvJobID, int SrvIndex, int SrvWindowSize)
{
    ClientAckRequest(AckRequest, SrvJobID, SrvIndex, SrvWindowSize);
}

simulated function CheckNetSpeed()
{
    // Check for the absolute minimum. Further checks are done in ScrnGuiNetspeedDialog
    if (OwnerPC.Player.ConfiguredInternetSpeed < default.NetSpeed
            || OwnerPC.Player.ConfiguredLanSpeed < OwnerPC.Player.ConfiguredInternetSpeed) {
        log("Fixing netspeed", class.name);
        OwnerPC.FixLegacySettings();
        OwnerPC.SetClientNetSpeed(default.NetSpeed);
    }
    NetSpeed = max(default.NetSpeed, min(OwnerPC.Player.ConfiguredInternetSpeed, OwnerPC.Mut.SrvNetSpeed));
}

simulated state ClientInitialWaiting
{
ignores StartClientInitialReplication;

Begin:
    CurrentJob="Looking for KFPlayerReplicationInfo";
    if (Level.NetMode != NM_Client) {
        log("ClientInitialWaiting - broken state", class.name);
        stop;
    }

    // first make sure OwnerPC and OwnerPRI are replicated
WaitForPC:
    OwnerPC = ScrnPlayerController(Level.GetLocalPlayerController());
    if (OwnerPC == none) {
        sleep(0.1);
        Goto('WaitForPC');
    }
WaitForPRI:
    OwnerPRI = KFPlayerReplicationInfo(OwnerPC.PlayerReplicationInfo);
    if (OwnerPRI == none) {
        sleep(0.1);
        Goto('WaitForPRI');
    }
    while (OwnerPC.Mut == none) {
        sleep(0.1);
    }

    if (!bRepCompleted) {
        Class'SRLevelCleanup'.Static.AddSafeCleanup(OwnerPC);
    }
    AddMeToPRI();

    bClientDebug = OwnerPC.bDebugRepLink;
    bRepCompleted = false;
    // CachePerks.Length = TotalPerks;
    WeaponBonuses.Length = TotalWeaponBonuses;
    ShopCategories.Length = TotalCategories;
    ShopInventory.Length = TotalWeapons;
    Zeds.Length = TotalZeds;
    Locks.Length = TotalLocks;
    CustomChars.Length = TotalChars;
    ClientAccknowledged[0] = 0;
    ClientAccknowledged[1] = 0;
    ClientAckSkinNum = 0;
    GotoState('ReceivingData');
}

// client state
simulated state ReceivingData
{
ignores StartClientInitialReplication;

    simulated function BeginState()
    {
        if (Level.NetMode != NM_Client) {
            GotoState(''); // just in case
            return;
        }
        CurrentJob = "Receiving Data";
        RepStartTime = Level.TimeSeconds;
        log("["$Level.TimeSeconds$"s] Waiting for server data: "
                $ " Perks="$TotalPerks $ " Bonuses="$TotalWeaponBonuses
                $ " Categories="$TotalCategories $ " Weapons="$TotalWeapons $ " Locks="$TotalLocks
                $ " Zeds="$TotalZeds  $ " Characters="$TotalChars, class.name);

        // tell server that we are ready to receive data
        CheckNetSpeed();
        ServerStartInitialReplication(NetSpeed);
    }

    simulated function ClientAllReceived()
    {
        if (JobID > 0 && JobID < JOB_DONE) {
            ClientEndJob();
        }
        log("["$Level.TimeSeconds$"s] Server data received in " $string(Level.TimeSeconds-RepStartTime)$"s", class.name);
        global.ClientAllReceived();
        GotoState('');
    }
}

//=============================================================================
// SERVER STATES
//=============================================================================

function ServerStartInitialReplication(int ClientNetSpeed)
{
    local int TickRate, BytesPerTick;

    if (Level.Game.bGameEnded)
        return;

    NetSpeed = min(ClientNetSpeed, OwnerPC.Mut.SrvNetSpeed);
    TickRate = OwnerPC.Mut.GetTickRate();
    // how much data can we send per tick
    BytesPerTick = min(NetSpeed, 120000) / min(TickRate, 120);
    // RepLink can occupy up to half of the bandwidth
    BytesPerTick /= 2;
    // Assume an average RPC requre 30 bytes
    NetBurstSize = BytesPerTick / 30;

    log(class'ScrnF'.static.PlainPlayerName(OwnerPC.PlayerReplicationInfo) $ " NetSpeed=" $ NetSpeed $ " TickRate="
            $ TickRate $ " NetBurstSize=" $ NetBurstSize, class.name);

    GotoState('InitialReplication');
}

function ServerAck(int ClientJobID, int ClientIndex)
{
    if (ClientJobID != JobID) {
        log("Job sync mismatch. Client Job # " $ ClientJobID $ ". Our " $ GetJobName(), class.name);
        return;
    }
    // log(GetJobName() $ " ACK received on item #" $ ClientIndex $ ". Last sent index = " $ SendIndex, class.name);
    LastAckIndex = ClientIndex;
}

function bool CheckClientACK()
{
    local bool bAllSent;

    bAllSent = SendIndex + 1 >= JobItemCount;

    if ((SendIndex == LastAckIndex) || (SendIndex < LastAckIndex + WindowSize && !bAllSent)) {
        ClientAckRequests = 0;
        NextClientAckRequestTime = Level.TimeSeconds + WaitForAckTime;
        return true;
    }

    if (Level.TimeSeconds > NextClientAckRequestTime) {
        log(GetJobName() $ " ACK request on item #" $ SendIndex, class.name);
        if (ClientAckRequests == 0) {
            ReliableClientAckRequest(JobID, SendIndex, WindowSize);
        }
        else {
            UnreliableClientAckRequest(ClientAckRequests, JobID, SendIndex, WindowSize);
        }
        ++ClientAckRequests;
        NextClientAckRequestTime = Level.TimeSeconds + WaitForAckTime + 0.1 * ClientAckRequests;
    }

    if (bAllSent) {
        // Always sleep while waiting for ACK.
        JobBurstSize = 0;
    }
    else {
        // Reduce burst if we need to wait for client ACK
        JobBurstSize = JobBurstSize >> 1;
        log(GetJobName() $ " Reduce burst to " $ JobBurstSize, class.name);
    }
    return false;
}

function bool StartNextJob()
{
    local byte ScaleFactor;

    ++JobID;
    JobItemCount = 0;
    SendIndex = 0;
    LastAckIndex = 0;
    JobWorker = DummyWorker;
    CurrentJob = "";
    ScaleFactor = 1;

    switch(JobID) {
        case JOB_PERK:
            CurrentJob = "Sending Perks";
            JobWorker = PerkWorker;
            JobItemCount = CachePerks.Length;
            ScaleFactor = 2;
            break;
        case JOB_WEAPONBONUS:
            CurrentJob = "Sending Weapon Bonuses";
            JobWorker = WeaponBonusWorker;
            JobItemCount = WeaponBonuses.Length;
            ScaleFactor = 2;
            break;
        case JOB_SHOPCATEGOGY:
            CurrentJob = "Sending Shop Categories";
            JobWorker = ShopCategoryWorker;
            JobItemCount = ShopCategories.Length;
            break;
        case JOB_SHOPITEM:
            CurrentJob = "Sending Shop Items";
            JobWorker = ShopItemWorker;
            JobItemCount = ShopInventory.Length;
            ScaleFactor = 2;
            break;
        case JOB_DLCLOCK:
            CurrentJob = "Sending DLC Locks";
            JobWorker = DlcLockWorker;
            JobItemCount = Locks.Length;
            ScaleFactor = 2;
            break;
        case JOB_ZED:
            CurrentJob = "Sending Zeds";
            JobWorker = ZedWorker;
            JobItemCount = Zeds.Length;
            ScaleFactor = 2;
            break;
        case JOB_CHAR:
            CurrentJob = "Sending Characters";
            JobWorker = CharWorker;
            JobItemCount = CustomChars.Length;
            break;
        case JOB_EMOJI:
            CurrentJob = "Sending Emoji";
            JobWorker = EmojiWorker;
            JobItemCount = SmileyTags.Length;
            ScaleFactor = 2;
            break;
        default:
            return false;
    }

    if (JobItemCount == 0) {
        // log(GetJobName() $ " has no items", class.name);
        return StartNextJob();
    }
    WindowSize = default.WindowSize << ScaleFactor;
    JobBurstSize = min(NetBurstSize, WindowSize >> 2);
    ClientStartJob(JobID, JobItemCount, WindowSize);
    return true;
}

function DummyWorker(int Index);

function PerkWorker(int Index)
{
    local class<ScrnVeterancyTypes> Perk;
    local byte lvl;

    Perk = class<ScrnVeterancyTypes>(CachePerks[Index].PerkClass);
    if (Perk.default.bLocked) {
        lvl = 255;
    }
    else {
        lvl = 0x80 | CachePerks[Index].CurrentLevel;
    }
    ClientReceivePerk(Index, Perk, lvl);
}

function WeaponBonusWorker(int Index)
{
    ClientReceiveWeaponBonus(Index, WeaponBonuses[Index].Perk,  WeaponBonuses[Index].Weapon,
            WeaponBonuses[Index].BonusMask);
}

function ShopCategoryWorker(int Index)
{
    ClientReceiveCategory(Index, ShopCategories[Index]);
}

function ShopItemWorker(int Index)
{
    ClientReceiveWeapon(Index, ShopInventory[Index].PC, ShopInventory[Index].CatNum);
}

function DlcLockWorker(int Index)
{
    switch (Locks[Index].Type) {
        case LOCK_Level:
            ClientReceiveLevelLock(Index, Locks[Index].PickupClass, Locks[Index].Group, Locks[Index].MaxProgress);
            break;
        case LOCK_Ach:
            ClientReceiveAchLock(Index, Locks[Index].PickupClass, Locks[Index].Group, Locks[Index].ID);
            break;
        case LOCK_AchGroup:
            ClientReceiveGroupLock(Index, Locks[Index].PickupClass, Locks[Index].Group,
                    Locks[Index].ID, Locks[Index].MaxProgress);
            break;
        default:
            // avoid getting stuck in replication due to broken type
            log("Bad Lock #" $ Index $ " type: " $ Locks[Index].Type, class.name);
            ClientReceiveLevelLock(Index, Locks[Index].PickupClass, Locks[Index].Group, 0);
    }
}

function ZedWorker(int Index)
{
    ClientReceiveZed(Index, Zeds[Index]);
}

function CharWorker(int Index)
{
    ClientReceiveChar(CustomChars[Index], Index);
}

function EmojiWorker(int Index)
{
    ClientReceiveTagSE(Index, SmileyTags[Index].SmileyTex, SmileyTags[Index].SmileyTag, SmileyTags[Index].bInCAPS);
}

auto state RepSetup
{
Begin:
    CurrentJob = "RepSetup";
    sleep(1.0);
    // OwnerPC and OwnerPRI on server side now are set in ScrnBalance.SetupRepLink
    if (NetConnection(StatObject.PlayerOwner.Player) == none) {
        AddMeToPRI(); // ScrnBalance does not need that. But it is used by ServerPerks.
        // standalone or server listener
        bReceivedURL = true;
        ClientAllReceived();
        CurrentJob = "Solo or Listen Server";
        GoToState('UpdatePerkProgress');
    }
}

// Sending replication data for the first time.
// No ACK checks here - clients should request missing data later.
state InitialReplication
{
    ignores ServerStartInitialReplication;
    //ignores ServerRequestCategories, ServerRequestWeapons, ServerRequestChars;

Begin:
    AddMeToPRI(); // do it here to prevent redudant replication of NextReplicationInfo
    NextRepTime = Level.TimeSeconds + 999999;  // ScrN doesn't use this
    JobID = 0;
    CurrentJob = "Initial Replication";
    if (Level.NetMode == NM_Client || NetConnection(StatObject.PlayerOwner.Player) == none) {
        log("InitialReplication - broken state", class.name);
        Stop;
    }

    NetUpdateFrequency = 0.5; // this doesn't affect replication of function calls

    ClientReceiveURL(ServerWebSite, StatObject.PlayerOwner.GetPlayerIDHash());
    sleep(0.2);

    while (StartNextJob()) {
        sleep(SleepTime);
        JobBurstLeft = JobBurstSize;
        for (SendIndex = 0; SendIndex < JobItemCount; ++SendIndex) {
            JobWorker(SendIndex);
            do {
                if (--JobBurstLeft <= 0) {
                    sleep(SleepTime);
                    JobBurstLeft = JobBurstSize;
                }
            } until (CheckClientACK());
        }
    }

    bRepCompleted = true;
    JobID = JOB_DONE;
    ClientAllReceived();
    CurrentJob = "ALL OK";
    SmileyTags.Length = 0; // we don't need emoji on the server
    sleep(5.0);
    NetPriority = 1.0;
    GotoState('UpdatePerkProgress');
}

// deprecated
state WaitingForACK
{
Begin:
    log("ScrnClientPerkRepLink: deprecated state WaitingForACK!", class.name);
    CurrentJob = "ERROR - WaitingForACK";
}

defaultproperties
{
    strLevelTitle="Perk Level %C"
    strLevelText="This item has the minimum perk level restriction."
    strUnknownAchTitle="Unknown Achievement"
    strUnknownAchText="Item cannot be unlocked in the current game mode"
    strGrpTitle="%C %G Achievements"
    strGrpText="Unlock %C achievements in '%G' group to unlock this item."

    IconChecked=Texture'ScrnAch_T.Achievements.Checked'
    IconPerkLocked=Texture'ScrnAch_T.Achievements.PerkLocked'
    IconAchLocked=Texture'KillingFloorHUD.Achievements.KF_Achievement_Lock'
    IconGrpLocked=Texture'ScrnAch_T.Achievements.AchGroupLocked'

    PermGroupStats(0)=(ID="MAP")
    PermGroupStats(1)=(ID="MAP_Normal")
    PermGroupStats(2)=(ID="MAP_Hard")
    PermGroupStats(3)=(ID="MAP_Sui")
    PermGroupStats(4)=(ID="MAP_HoE")

    WindowSize=32
    NetSpeed=15000
    SleepTime=0.008  // send data every server tick up to 120 tickrate
    WaitForAckTime=1.0
    NetPriority=1.3
    bOnlyRelevantToOwner=True
    bAlwaysRelevant=False
}
