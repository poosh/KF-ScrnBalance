class ScrnClientPerkRepLink extends ClientPerkRepLink
config(ScrnBalance)
dependson(ScrnBalance) 
dependson(ScrnAchievements);

var ScrnPlayerController OwnerPC;

var String CurrentJob; // for debug purposes
var byte TotalCategories;
var int TotalWeapons, TotalChars, TotalLocks;
// how many more records client is expecting to receive from the server
// used on client-side only
var transient int PendingItems;
var transient byte PendingCategories;
var transient int PendingWeapons, PendingChars, PendingLocks;
var bool bClientDebug;
var protected int CheckDataAttempts;

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
var transient array<SPickupLock> Locks;
var material IconPerkLocked, IconAchLocked, IconGrpLocked, IconChecked;

var protected array<ScrnBalance.SNameValuePair> PermGroupStats; // achievement group stats that do not change during the game
var transient protected array<ScrnBalance.SNameValuePair> GroupStatCache; // cache group stats to avoid multiple calls on the same group

var localized string strLevelTitle, strLevelText;
var localized string strUnknownAchTitle, strUnknownAchText;
var localized string strGrpTitle, strGrpText;

var config float CategorySendCooldown, WeaponSendCooldown, CharacterSendCooldown, SmileSendCooldown;
var config bool bWaitForACK;

var transient bool bInitReplicationReceived;

replication
{
    reliable if ( bNetOwner && bNetInitial && Role == ROLE_Authority )
        TotalWeapons, TotalChars, TotalCategories, TotalLocks; 

    reliable if ( Role < ROLE_Authority )
        ServerStartInitialReplication, ServerSelectPerkSE;
        
    // reliable if ( Role < ROLE_Authority )
        // ServerRequestCategories, ServerRequestWeapons, ServerRequestChars;        
    
    reliable if ( Role == ROLE_Authority )
        ClientReceiveLevelLock, ClientReceiveAchLock, ClientReceiveGroupLock;
}

// Just look for the stats. Don't do mysterious things as Marco intended in FindStats()
static final function ScrnClientPerkRepLink FindMe( PlayerController Other )
{
	local LinkedReplicationInfo L;
	if( Other != none && Other.PlayerReplicationInfo != None ) {
        for( L=Other.PlayerReplicationInfo.CustomReplicationInfo; L!=None; L=L.NextReplicationInfo ) {
            if( ScrnClientPerkRepLink(L) != None )
                return ScrnClientPerkRepLink(L);
        }
    }
	return None;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    
    if ( Role < ROLE_Authority && !bInitReplicationReceived ) {
        bInitReplicationReceived = true;
        GotoState('ClientInitialWaiting');
    }
}


function ServerSelectPerkSE(Class<SRVeterancyTypes> VetType)
{
    local ScrnPlayerController PC;
    local KFGameType KF;
    local bool bDifferentPerk;
    
    PC = ScrnPlayerController(Owner);
    KF = KFGameType(Level.Game);
    
    if ( PC == none || KF == none || KF.bWaitingToStartMatch || PC.Mut.bAllowAlwaysPerkChanges )
        StatObject.ServerSelectPerk(VetType); // shouldn't happen, but just to be sure...
    else {
        if ( PC.Mut.bNoPerkChanges && PC.bHadPawn 
                && (!PC.Mut.bPerkChangeBoss || PC.Mut.bTSCGame || KF.WaveNum < KF.FinalWave) ) 
        {
            PC.ClientMessage(PC.strNoPerkChanges);
            return;
        }
        
        if ( KF.WaveNum == PC.PerkChangeWave && !KF.bWaveInProgress ) {
            PC.ClientMessage(PC.PerkChangeOncePerWaveString);
            return;
        }

        bDifferentPerk = OwnerPRI != none && VetType != OwnerPRI.ClientVeteranSkill;
        StatObject.ServerSelectPerk(VetType);
        if ( bDifferentPerk && VetType == OwnerPRI.ClientVeteranSkill )
            PC.PerkChangeWave = KF.WaveNum;
    }
}

function ServerStartInitialReplication()
{
    GotoState('InitialReplication');
}

/*

function ServerRequestCategories(byte Index, byte Count)
{
    local byte end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(ShopCategories.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveCategory(Index, ShopCategories[Index]);
    NextRepTime = Level.TimeSeconds + fclamp(Count * 0.1, 2.0, 10.0);
} 

function ServerRequestWeapons(int Index, byte Count)
{
    local int end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(ShopInventory.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveWeapon(Index, ShopInventory[Index].PC, ShopInventory[Index].CatNum);
    NextRepTime = Level.TimeSeconds + fclamp(Count * 0.05, 2.0, 10.0);
} 


function ServerRequestChars(int Index, byte Count)
{
    local int end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(CustomChars.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveChar(CustomChars[Index], Index);
    NextRepTime = Level.TimeSeconds + fclamp(Count * 0.1, 2.0, 10.0);
}
*/

simulated function ClientReceiveCategory( byte Index, FShopCategoryIndex S )
{  
    if ( Index >= ShopCategories.length )
        ShopCategories.length = Index+1; 
        
    if ( bClientDebug )
        OwnerPC.ClientMessage("Category " $ (Index+1)$"/"$TotalCategories@ S.Name); 
        
	if( ShopCategories[Index].Name=="" ) {
        --PendingItems;
		++ClientAccknowledged[1];
		ShopCategories[Index] = S;
	}
}  

simulated function ClientReceiveWeapon( int Index, class<Pickup> P, byte Categ )
{   
    if ( Index >= ShopInventory.length )
        ShopInventory.length = Index+1;   

    if ( bClientDebug )
        OwnerPC.ClientMessage("Weapon " $ (Index+1)$"/"$TotalWeapons @ P);        
        
	if( ShopInventory[Index].PC==None ) {
        --PendingItems;
		++ClientAccknowledged[0];
		ShopInventory[Index].PC = P;
		ShopInventory[Index].CatNum = Categ;
	}
}

simulated function ClientReceiveLevelLock(int Index, class<Pickup> PC, byte Group, byte MinLevel)
{
    if ( Index >= Locks.length )
        Locks.length = Index+1;

    if ( bClientDebug )
        OwnerPC.ClientMessage("LevelLock " $ (Index+1)$"/"$TotalLocks @ PC);
        
    if ( Locks[Index].PickupClass == None ) {
        --PendingItems;
        Locks[Index].Type = LOCK_Level;
        Locks[Index].PickupClass = PC;
        Locks[Index].Group = Group;
        Locks[Index].MaxProgress = MinLevel;
    }
} 

simulated function ClientReceiveAchLock(int Index, class<Pickup> PC, byte Group, name Achievement)
{
    if ( Index >= Locks.length )
        Locks.length = Index+1;
        
    if ( bClientDebug )
        OwnerPC.ClientMessage("AchLock " $ (Index+1)$"/"$TotalLocks @ PC @ Achievement); 
    if ( Locks[Index].PickupClass == None ) {
        --PendingItems;
        Locks[Index].Type = LOCK_Ach;
        Locks[Index].PickupClass = PC;
        Locks[Index].Group = Group;
        Locks[Index].ID = Achievement;
    }
}     

simulated function ClientReceiveGroupLock(int Index, class<Pickup> PC, byte Group, name AchGroup, byte Count)
{
    if ( Index >= Locks.length )
        Locks.length = Index+1;
      
    if ( bClientDebug )
        OwnerPC.ClientMessage("GroupLock " $ (Index+1)$"/"$TotalLocks @ PC@ AchGroup);       

    if ( Locks[Index].PickupClass == None ) {
        --PendingItems;
        Locks[Index].Type = LOCK_AchGroup;
        Locks[Index].PickupClass = PC;
        Locks[Index].Group = Group;
        Locks[Index].ID = AchGroup;
        Locks[Index].MaxProgress = Count;
    }
} 

    
simulated function ClientReceiveChar( string CharName, int Num )
{
    if ( bClientDebug )
        OwnerPC.ClientMessage("Character " $ (Num+1)$"/"$TotalChars@ CharName); 
    if ( Num >= CustomChars.length || CustomChars[Num] == "" ) {
        PendingItems--;
        ClientAckSkinNum++;
        CustomChars[Num] = CharName;
    }
}

simulated function ClientSendAcknowledge()
{
    ServerAcnowledge(ClientAccknowledged[0],ClientAccknowledged[1]);
    ServerAckSkin(ClientAckSkinNum);
}


simulated function ClientAllReceived()
{
	local PlayerController LocalPC;
	local int i;
    local class<KFWeapon> WC;

	bRepCompleted = true;
    //PendingItems = 0;
	LocalPC = Level.GetLocalPlayerController();
	
	if( (LocalPC!=None && LocalPC==Owner) || Level.NetMode==NM_Client ) {
        InitCustomLocks();
		// Marks Steam DLC requirements
		for( i=0; i<ShopInventory.length; ++i ) {
            if ( ShopInventory[i].bDLCLocked != DLC_LOCK_SCRN ) {
                WC = class<KFWeapon>(ShopInventory[i].PC.Default.InventoryType);
                if ( WC != none && WC.Default.AppID > 0 )
                    ShopInventory[i].bDLCLocked = DLC_LOCK_STEAM_APP;
            }
        }
        Spawn(Class'ScrnSteamStatsGetter',Owner).Link = self;
	}

	if( SmileyTags.Length > 0 && LocalPC!=None && SRHUDKillingFloor(LocalPC.MyHUD)!=None )
		SRHUDKillingFloor(LocalPC.MyHUD).SmileyMsgs = SmileyTags;
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
    class'ScrnAchievements'.static.GetGlobalAchievementStats(self, v, m, 0, GroupName);
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
        class'ScrnAchievements'.static.GetGlobalAchievementStats(self, j, a, 0, PermGroupStats[i].ID);
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
                    ReplaceText(s, "%C", string(Locks[i].MaxProgress));
                    Locks[i].Title = s;
                    s = strLevelText;
                    ReplaceText(s, "%C", string(Locks[i].MaxProgress));
                    Locks[i].Text = s;
                }
                break;                
                
            case LOCK_Ach:
                Locks[i].AchInfo = class'ScrnAchievements'.static.GetAchievementByID(self, Locks[i].ID);
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
                    g = class'ScrnAchievements'.static.GroupCaption(self, Locks[i].ID);
                    s = strGrpTitle;
                    ReplaceText(s, "%C", string(Locks[i].MaxProgress));
                    ReplaceText(s, "%G", g);
                    Locks[i].Title = s;
                    s = strGrpText;
                    ReplaceText(s, "%C", string(Locks[i].MaxProgress));
                    ReplaceText(s, "%G", g);
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

simulated function Tick( float DeltaTime )
{
    Disable('Tick');
    // if replication link is broken, then it is better for client to reconnect rather
    // than trying "fixing" stuff, which at the end makes things even worse
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
                return;
            }
        }
    }
}

simulated state ClientInitialWaiting
{
Begin:
    CurrentJob="Looking for KFPlayerReplicationInfo";
    // first make sure OwnerPC and OwnerPRI are replicated
    while (true) {
        if ( OwnerPC == none )
            OwnerPC = ScrnPlayerController(Level.GetLocalPlayerController());
        if ( OwnerPC != none )
            OwnerPRI = KFPlayerReplicationInfo(OwnerPC.PlayerReplicationInfo);
        if ( OwnerPRI != none )
            break;
        sleep(0.5);
    }
    // C&P from ServerPerks.ClientPerkRepLink.Tick()
    Class'SRLevelCleanup'.Static.AddSafeCleanup(OwnerPC);
    AddMeToPRI();
    
    bClientDebug = OwnerPC.bDebugRepLink;
    ShopCategories.Length = TotalCategories;
    ShopInventory.Length = TotalWeapons;
    Locks.Length = TotalLocks; 
    CustomChars.Length = TotalChars;
    PendingItems = TotalCategories + TotalWeapons + TotalLocks + TotalChars;
    // tell server that we are ready to receive data
    ServerStartInitialReplication();
    GotoState('ReceivingData');
}

// client state
simulated state ReceivingData
{
    simulated function BeginState() 
    {
        if ( Level.NetMode != NM_Client ) {
            GotoState(''); // just in case           
            return;
        }
        SetTimer(10.0, true); // give server reasonable time to send us data
        CurrentJob = "Receiving Data";
        log("["$Level.TimeSeconds$"s] Waiting for server data: Categories="$TotalCategories $ " Weapons="$TotalWeapons
            $ " DLCLocks="$TotalLocks $ " Characters="$TotalChars, 'ScrnBalance');
    }
    
    simulated function EndState()
    {
        SetTimer(0, false);
    }
    
    simulated function Timer()
    {
        CheckData();
    }    
    
    simulated function CheckData()
    {
        local int i, pending;
        
        --CheckDataAttempts;
        // weapon categories 
        CurrentJob = "Receiving Categories";
        for ( i=0; i<ShopCategories.Length; ++i )
            if ( ShopCategories[i].Name == "") 
                pending++; 
        // weapons 
        if ( pending == 0 )
            CurrentJob = "Receiving Weapons";
        for ( i=0; i<ShopInventory.Length; ++i )
            if ( ShopInventory[i].PC == none)
                pending++;
                
        // DLC Locks  
        if ( pending == 0 )
            CurrentJob = "Receiving DLC Locks";
        for ( i=0; i<Locks.Length; ++i )
            if ( Locks[i].PickupClass == none)
                pending++;        

        if ( pending > 0 && CheckDataAttempts > 0) {
            SetTimer(2.0, false);
            return;
        }        
        
        // if we reached here, then client received all categories and weapons
        if ( !bRepCompleted ) {
            // call it before receiving custom characters  
            ClientAllReceived();
            // tell server that we've got all weapons
            ServerAcnowledge(ClientAccknowledged[0],ClientAccknowledged[1]);
        }

        // characters
        if ( pending == 0 )
            CurrentJob = "Receiving Characters";
        for ( i=0; i<CustomChars.Length; ++i )
            if ( CustomChars[i] == "") 
                ++pending;
        if ( pending > 0 && CheckDataAttempts > 0 ) {
            SetTimer(2.0, false);
            return;
        }                
        ServerAckSkin(CustomChars.Length); // tell server that we've got all characters
        
        if ( pending == 0 ) {
            CurrentJob = "ALL OK";
            log("["$Level.TimeSeconds$"s] All data received from the server", 'ScrnBalance');
        }
        else {
            log("["$Level.TimeSeconds$"s] Unable to receive "$pending$" items", 'ScrnBalance');
        }
        NetPriority = 1.0;
        GotoState('ReceivingExtraData');
    }
    
    simulated function ClientReceiveCategory( byte Index, FShopCategoryIndex S )
    {  
        global.ClientReceiveCategory(Index, S);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now
    }  

    simulated function ClientReceiveWeapon( int Index, class<Pickup> P, byte Categ )
    {   
        global.ClientReceiveWeapon(Index, P, Categ);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }
    
    simulated function ClientReceiveChar( string CharName, int Num )
    {
        global.ClientReceiveChar(CharName, Num);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }
    
    simulated function ClientReceiveLevelLock(int Index, class<Pickup> PC, byte Group, byte MinLevel)
    {
        global.ClientReceiveLevelLock(Index, PC, Group, MinLevel);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    } 

    simulated function ClientReceiveAchLock(int Index, class<Pickup> PC, byte Group, name Achievement)
    {
        global.ClientReceiveAchLock(Index, PC, Group, Achievement);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }     

    simulated function ClientReceiveGroupLock(int Index, class<Pickup> PC, byte Group, name AchGroup, byte Count)
    {
        global.ClientReceiveGroupLock(Index, PC, Group, AchGroup, Count);
        if ( PendingItems > 0 )
            SetTimer(2.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }    
}

simulated state ReceivingExtraData
{
    simulated function BeginState()
    {
        Timer();
    }
    simulated function EndState()
    {
        SetTimer(0, false);
    }    
    simulated function Timer()
    {
        if( OwnerPC!=None && SRHUDKillingFloor(OwnerPC.MyHUD)!=None )
            SRHUDKillingFloor(OwnerPC.MyHUD).SmileyMsgs = SmileyTags;       
    }

    simulated function ClientReceiveTag( Texture T, string Tag, bool bInCaps )
    {
        super.ClientReceiveTag(T, Tag, bInCaps);
        SetTimer(1.0, false);
    }
}


auto state RepSetup
{
Begin:
    CurrentJob = "RepSetup";
    sleep(1.0);
    
    // OwnerPC and OwnerPRI on server side now are set in ScrnBalance.SetupRepLink
    OwnerPC = ScrnPlayerController(StatObject.PlayerOwner);
    OwnerPRI = KFPlayerReplicationInfo(StatObject.PlayerOwner.PlayerReplicationInfo);
    AddMeToPRI(); 
    
    if( NetConnection(StatObject.PlayerOwner.Player)==None ) {
        // standalone or server listener
        bReceivedURL = true;
        ClientAllReceived();
        CurrentJob = "Solo or Listen Server ";
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
    CurrentJob = "InitialReplication";
    if( Level.NetMode==NM_Client || NetConnection(StatObject.PlayerOwner.Player)==None )
        Stop;

    NetUpdateFrequency = 0.5; // this doesn't affect replication of function calls
    
    ClientReceiveURL(ServerWebSite,StatObject.PlayerOwner.GetPlayerIDHash());
    sleep(0.2);
    
    CurrentJob = "Sending Perks";
    SendClientPerks();
    NextRepTime = Level.TimeSeconds + 5.0; // no effin spamming us until we're done
    sleep(1.0);
    
    CurrentJob = "Sending Categories";
    for( SendIndex=0; SendIndex<ShopCategories.Length; ++SendIndex ) {
        ClientReceiveCategory(SendIndex, ShopCategories[SendIndex]);
        NextRepTime += CategorySendCooldown;
        Sleep(CategorySendCooldown);
    }    
    
    CurrentJob = "Sending Weapons";
    for( SendIndex=0; SendIndex<ShopInventory.Length; ++SendIndex ) {
        ClientReceiveWeapon(SendIndex, ShopInventory[SendIndex].PC, ShopInventory[SendIndex].CatNum);
        NextRepTime += WeaponSendCooldown;
        Sleep(WeaponSendCooldown);
    }
    
    CurrentJob = "Sending DLC Locks";
    for( SendIndex=0; SendIndex<Locks.Length; ++SendIndex ) {
        switch (Locks[SendIndex].Type) {
            case LOCK_Level:
                ClientReceiveLevelLock(SendIndex, Locks[SendIndex].PickupClass, Locks[SendIndex].Group, 
                    Locks[SendIndex].MaxProgress);
                break;
            case LOCK_Ach:
                ClientReceiveAchLock(SendIndex, Locks[SendIndex].PickupClass, Locks[SendIndex].Group, 
                    Locks[SendIndex].ID);
                break;
            case LOCK_AchGroup:
                ClientReceiveGroupLock(SendIndex, Locks[SendIndex].PickupClass, Locks[SendIndex].Group, 
                    Locks[SendIndex].ID, Locks[SendIndex].MaxProgress);
                break;
        }
        NextRepTime += WeaponSendCooldown;
        Sleep(WeaponSendCooldown);
    }
    
    CurrentJob = "Sending Characters";
    for( SendIndex=0; SendIndex<CustomChars.Length; ++SendIndex ) {
        ClientReceiveChar(CustomChars[SendIndex],SendIndex);
        NextRepTime += CharacterSendCooldown;
        Sleep(CharacterSendCooldown);
    }    
    
    GoToState('WaitingForACK');
}

// server is waiting for client's acknowledgement that everything is received
state WaitingForACK
{
    ignores ServerStartInitialReplication;

Begin:
    sleep(1.0);
    if ( bWaitForACK ) {
        CurrentJob = "Waiting for Weapon ACK";
        SendIndex = 0;
        while ( ClientAccknowledged[0]<ShopInventory.Length || ClientAccknowledged[1]<ShopCategories.Length ) {
            if ( ++SendIndex == 10 ) {
                ClientSendAcknowledge();  
                SendIndex = 0;
            }
            sleep(1.0);
        }
        CurrentJob = "Waiting for Character ACK";
        SendIndex = 0;
        while ( ClientAckSkinNum < CustomChars.length ) {
            if ( ++SendIndex == 10 ) {
                ClientSendAcknowledge();  
                SendIndex = 0;
            }
            sleep(1.0);
        } 
    }    

    bRepCompleted = true;
    
    CurrentJob = "Sending Smiles";
    for( SendIndex=0; SendIndex<SmileyTags.Length; ++SendIndex )
    {
        ClientReceiveTag(SmileyTags[SendIndex].SmileyTex,SmileyTags[SendIndex].SmileyTag,SmileyTags[SendIndex].bInCAPS);
        Sleep(SmileSendCooldown);
    }
    SmileyTags.Length = 0;  
    
    CurrentJob = "ALL OK";
    sleep(5.0);
    NetPriority = 1.0;
    GotoState('UpdatePerkProgress');
}

defaultproperties
{
    strLevelTitle="Perk Level %C"
    strLevelText="This item has minimal perk level restriction."
    strUnknownAchTitle="Unknown Achievement"
    strUnknownAchText="Item can't be unlocked in the current game mode"
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
    
    CategorySendCooldown=0.10
    WeaponSendCooldown=0.025
    CharacterSendCooldown=0.1
    SmileSendCooldown=0.1
    bWaitForACK=False
    CheckDataAttempts=30
    
    NetPriority=1.3
}