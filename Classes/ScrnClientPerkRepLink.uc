class ScrnClientPerkRepLink extends ClientPerkRepLink;

var byte TotalCategories;
var int TotalWeapons, TotalChars;

var String CurrentJob; // for debug purposes

// how many more records client is expecting to receive from the server
// used on client-side only
var byte PendingItems;

replication
{
    reliable if ( bNetOwner && bNetInitial && Role == ROLE_Authority )
        TotalWeapons, TotalChars, TotalCategories; 

    reliable if ( Role < ROLE_Authority )
        ServerStartInitialReplication, ServerSelectPerkSE;
}


simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    
    if ( Role < ROLE_Authority ) {
        ShopCategories.Length = TotalCategories;
        ShopInventory.Length = TotalWeapons;
        CustomChars.Length = TotalChars;
        PendingItems = TotalCategories + TotalWeapons + TotalChars;
        // tell server that we are ready to receive data
        ServerStartInitialReplication();
        GotoState('ReceivingData');
    }
}

function ServerSelectPerkSE(Class<SRVeterancyTypes> VetType)
{
    local ScrnPlayerController PC;
    local KFGameType KF;
    local bool bDifferentPerk;
    
    PC = ScrnPlayerController(Owner);
    KF = KFGameType(Level.Game);
    
    if ( PC == none || KF == none || KF.bWaitingToStartMatch || class'ScrnBalance'.default.Mut.bAllowAlwaysPerkChanges )
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

function ServerRequestCategories(byte Index, byte Count)
{
    local byte end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(ShopCategories.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveCategory(Index, ShopCategories[Index]);
    NextRepTime = Level.TimeSeconds+2.f;
} 

function ServerRequestWeapons(int Index, byte Count)
{
    local int end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(ShopInventory.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveWeapon(Index, ShopInventory[Index].PC, ShopInventory[Index].CatNum);
    NextRepTime = Level.TimeSeconds+2.f;
} 


function ServerRequestChars(int Index, byte Count)
{
    local int end;
    
    if( NextRepTime<Level.TimeSeconds )
        return ;
        
    end = min(CustomChars.Length, Index + Count);
    while ( Index < end )   
        ClientReceiveChar(CustomChars[Index], Index);
    NextRepTime = Level.TimeSeconds+2.f;
}

simulated function ClientReceiveCategory( byte Index, FShopCategoryIndex S )
{  
    if ( Index >= ShopCategories.length || ShopCategories[Index].Name=="" )
        PendingItems--;
        
    super.ClientReceiveCategory(Index, S);
}  

simulated function ClientReceiveWeapon( int Index, class<Pickup> P, byte Categ )
{   
    if ( Index >= ShopInventory.length || ShopInventory[Index].PC==None )
        PendingItems--;

    super.ClientReceiveWeapon(Index, P, Categ);
}
    
simulated function ClientReceiveChar( string CharName, int Num )
{
    if ( Num >= CustomChars.length || CustomChars[Num] == "" ) {
        PendingItems--;
        ClientAckSkinNum++;
    }
    CustomChars[Num] = CharName;
}

simulated function ClientReceiveTag( Texture T, string Tag, bool bInCaps )
{
    local PlayerController PC;
    
    super.ClientReceiveTag(T, Tag, bInCaps);
 
    // todo: add delay before upating the HUD (wait for more incoming smiletags)
    PC = Level.GetLocalPlayerController();
    if( PC!=None && SRHUDKillingFloor(PC.MyHUD)!=None )
        SRHUDKillingFloor(PC.MyHUD).SmileyMsgs = SmileyTags;    
}

simulated function ClientSendAcknowledge()
{
    ServerAcnowledge(ClientAccknowledged[0],ClientAccknowledged[1]);
    ServerAckSkin(ClientAckSkinNum);
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
        local int i, j;
        
        // weapon categories 
        CurrentJob = "Receiving Categories";
        for ( i=0; i<ShopCategories.Length; ++i ) {
            if ( ShopCategories[i].Name == "") {
                // check if we need more categories in a row
                j = i+1;
                while ( j<ShopCategories.Length && ShopCategories[j].Name == "" )
                    ++j;
                PendingItems = j-i;
                
                // v7.51 - in theory, reliable function calls always must be replicated, sooner or later.
                // So let's just try to wait without additional requests
                //ServerRequestCategories(i, PendingItems);
                SetTimer(2.0, true);
                return;
            }
        }
        
        // weapons 
        CurrentJob = "Receiving Weapons";
        for ( i=0; i<ShopInventory.Length; ++i ) {
            if ( ShopInventory[i].PC == none) {
                // check if we need more categories in a row
                j = i+1;
                while ( j<ShopInventory.Length && ShopInventory[j].PC == none )
                    ++j;
                PendingItems = j-i;
                //ServerRequestWeapons(i, PendingItems);
                SetTimer(2.0, true);
                return;
            }
        } 

        // if we reached here, then client received all categories and weapons
        if ( !bRepCompleted ) {
            // call it before receiving custom characters  
            ClientAllReceived();
            // tell server that we've got all weapons
            ServerAcnowledge(ClientAccknowledged[0],ClientAccknowledged[1]);
        }

        // characters
        CurrentJob = "Receiving Characters";
        for ( i=0; i<CustomChars.Length; ++i ) {
            if ( CustomChars[i] == "") {
                // check if we need more categories in a row
                j = i+1;
                while ( j<CustomChars.Length && CustomChars[j] == "" )
                    ++j;
                PendingItems = j-i;
                //ServerRequestChars(i, PendingItems);
                SetTimer(2.0, true);
                return;
            }
        }  
        ServerAckSkin(CustomChars.Length); // tell server that we've got all characters
        
        CurrentJob = "ALL OK";
        GotoState('');
    }
    
    simulated function ClientReceiveCategory( byte Index, FShopCategoryIndex S )
    {  
        global.ClientReceiveCategory(Index, S);
        if ( PendingItems > 0 )
            SetTimer(1.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now
    }  

    simulated function ClientReceiveWeapon( int Index, class<Pickup> P, byte Categ )
    {   
        global.ClientReceiveWeapon(Index, P, Categ);
        if ( PendingItems > 0 )
            SetTimer(1.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }
    
    simulated function ClientReceiveChar( string CharName, int Num )
    {
        global.ClientReceiveChar(CharName, Num);
        if ( PendingItems > 0 )
            SetTimer(1.0, true); // take a little pause before checking - more items should come from server
        else 
            CheckData(); // no pending items left, check now    
    }
}


auto state RepSetup
{
Begin:
    CurrentJob = "RepSetup";
    sleep(1.0);
    if( NetConnection(StatObject.PlayerOwner.Player)==None ) {
        // standalone or server listener
        bReceivedURL = true;
        InitDLCCheck();
        ClientAllReceived();
        CurrentJob = "Solo or Listen Server ";
        GoToState('UpdatePerkProgress');
    }
}

// Sending replication data for the first time. 
// No ACK checks here - clients should request missing data later.
state InitialReplication
{
    ignores ServerRequestCategories, ServerRequestWeapons, ServerRequestChars;
    
Begin:
    CurrentJob = "InitialReplication";
    if( Level.NetMode==NM_Client || NetConnection(StatObject.PlayerOwner.Player)==None )
        Stop;

    NetUpdateFrequency = 0.5; // this doesn't affect replication of function calls
    
    ClientReceiveURL(ServerWebSite,StatObject.PlayerOwner.GetPlayerIDHash());
    
    CurrentJob = "Sending Categories";
    for( SendIndex=0; SendIndex<ShopCategories.Length; ++SendIndex ) {
        ClientReceiveCategory(SendIndex, ShopCategories[SendIndex]);
        Sleep(0.1);
    }    
    
    CurrentJob = "Sending Weapons";
    for( SendIndex=0; SendIndex<ShopInventory.Length; ++SendIndex ) {
        ClientReceiveWeapon(SendIndex, ShopInventory[SendIndex].PC, ShopInventory[SendIndex].CatNum);
        Sleep(0.1);
    }
    CurrentJob = "Sending Characters";
    for( SendIndex=0; SendIndex<CustomChars.Length; ++SendIndex ) {
        ClientReceiveChar(CustomChars[SendIndex],SendIndex);
        Sleep(0.15);
    }    
    
    GoToState('WaitingForACK');
}

// server is waiting for client's acknowledgement that everything is received
state WaitingForACK
{
Begin:
    CurrentJob = "Waiting for Weapon ACK";
    SendIndex = 0;
    while ( ClientAccknowledged[0]<ShopInventory.Length || ClientAccknowledged[1]<ShopCategories.Length ) {
        if ( ++SendIndex == 5 ) {
            ClientSendAcknowledge();  
            SendIndex = 0;
        }
        sleep(1.0);
    }
    CurrentJob = "Waiting for Character ACK";
    while ( ClientAckSkinNum < CustomChars.length ) {
        if ( ++SendIndex == 5 ) {
            ClientSendAcknowledge();  
            SendIndex = 0;
        }
        sleep(1.0);
    }    

    bRepCompleted = true;
    
    CurrentJob = "Sending Smiles";
    for( SendIndex=0; SendIndex<SmileyTags.Length; ++SendIndex )
    {
        ClientReceiveTag(SmileyTags[SendIndex].SmileyTex,SmileyTags[SendIndex].SmileyTag,SmileyTags[SendIndex].bInCAPS);
        Sleep(0.1f);
    }
    SmileyTags.Length = 0;  

        
    CurrentJob = "ALL OK";
    GotoState('UpdatePerkProgress');
}
