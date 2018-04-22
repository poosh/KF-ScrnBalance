class ScrnCustomPRI extends LinkedReplicationInfo;

var byte                    BlameCounter;
var private Material        Avatar, ClanIcon, PreNameIcon, PostNameIcon;
var Color                   PrefixIconColor, PostfixIconColor;
var private int             TourneyPlayoffs, TourneyWins;

var private string          SteamID64;
var private int             SteamID32, ClientSteamID32;

var private transient byte SteamID64Attempts;

//0x0110000100000000 - 76561197960265728
const SteamUID_Part1 = 76561197;
const SteamUID_Part2 =         960265728;

replication
{
    reliable if ( bNetDirty && Role == Role_Authority )
        BlameCounter, SteamID32;
}  

function PostBeginPlay()
{
    if ( Level.NetMode == NM_DedicatedServer )
        GotoState('InitPRI');
}

simulated function PostNetReceive()
{
    super.PostNetReceive();
    
    if ( SteamID32 > 0 && SteamID32 != ClientSteamID32 ) {
        ClientSteamID32 = SteamID32;
        SetSteamID32(SteamID32);
    }
}


// UE2 doesn't support __int64 :(
final static function int SteamID64_to_32(string sid64)
{
    local int a, billions;
    
    if ( len(sid64) != 17 || left(sid64, 5) != "76561" )
        return 0;
    
    billions = int(left(sid64,8)) - SteamUID_Part1;
    a = int(right(sid64,9));

    if ( a < SteamUID_Part2 ) {
        billions--;
        a += 1000000000;
    }
    a -= SteamUID_Part2;
    
    
    if ( billions > 4 || (billions == 4 && a >= 294967296) ) { // 2^32
        log("Steam ID too high for 32-bit number: " $ sid64);
        return 0; //
    }
    
    if ( billions > 2 || (billions == 2 && a >= 147483648) ) { // 2^31
        // need to set highest (sign) bit to 1
        billions -= 2;
        a -= 147483648;
        a += billions * 1000000000;
        a = a | (1<<31);
    }
    else 
        a += billions * 1000000000; 
    
    return a;
}   

final static function string SteamID32_to_64(int sid32)
{
    local int a, billions;
    local string result;
    
    if ( sid32 < 0 ) {
        // negative number mean highest int32 bit is 1 -> 2147483648
        a = sid32 & 0x7FFFFFFF; // unset sign bit
        billions =  a / 1000000000;
        a -= billions * 1000000000;
        billions += SteamUID_Part1 + 2;
        a += SteamUID_Part2 + 147483648;
        if ( a > 1000000000 ) {
            billions += a / 1000000000;
            a = a % 1000000000;
        }
    }
    else {
        a = sid32;
        billions =  a / 1000000000;
        a -= billions * 1000000000;
        billions += SteamUID_Part1;
        a += SteamUID_Part2;
        if ( a > 1000000000 ) {
            billions++;
            a -= 1000000000;
        }        
    }
    result = string(a);
    while ( len(result) < 9 )
        result = "0" $ result;
    result = string(billions) $ result;
    return result;
} 

final simulated function SetSteamID64(string value)
{
    local int a;
    
    a = SteamID64_to_32(value);
    if ( a != 0 ) {
        SteamID64 = value;
        SteamID32 = a;
        LoadHighlyDecorated();
    }
    //PlayerController(Owner).ClientMessage("SteamID64="$SteamID64 $ ",  SteamID32="$SteamID32);
}
function simulated string GetSteamID64()
{
    return SteamID64;
}

final simulated function SetSteamID32(int value)
{
    SteamID64 = SteamID32_to_64(value);
    SteamID32 = value;
    LoadHighlyDecorated();
}
function simulated int GetSteamID32()
{
    return SteamID32;
}

final simulated function LoadHighlyDecorated()
{
    class'ScrnBalance'.static.GetHighlyDecorated(
        SteamID32, Avatar, ClanIcon, 
        PreNameIcon, PrefixIconColor, PostNameIcon, PostfixIconColor, 
        TourneyPlayoffs, TourneyWins);
}

final static function ScrnCustomPRI FindMe(PlayerReplicationInfo PRI)
{
    local LinkedReplicationInfo L;
    
    if ( PRI == none )
        return none;
    
    for( L = PRI.CustomReplicationInfo; L != none; L = L.NextReplicationInfo ) {
        if ( ScrnCustomPRI(L) != none )
            return ScrnCustomPRI(L);
    }
    return none;
}

final simulated function bool IsTourneyMember()
{
    return TourneyPlayoffs > 0;
}
final simulated function int GetPlayoffCount()
{
    return TourneyPlayoffs;
}
final simulated function int GetTourneyWinCount()
{
    return TourneyWins;
}
final simulated function material GetAvatar()
{
    return Avatar;
}
final simulated function material GetClanIcon()
{
    return ClanIcon;
}
final simulated function material GetSpecialIcon()
{
    if ( Avatar != none )
        return Avatar;
    return ClanIcon;
}
final simulated function material GetPreNameIcon()
{
    return PreNameIcon;
}
final simulated function material GetPostNameIcon()
{
    return PostNameIcon;
}


state InitPRI
{
Begin:
    while ( ++SteamID64Attempts <= 120 ) {
        sleep(1); // give time to execute PostLogin() and set SteamID64
        SteamID64 = PlayerController(Owner).GetPlayerIDHash();
        if ( len(SteamID64) == 17 && left(SteamID64, 5) == "76561" ) {  
            SetSteamID64(SteamID64);
            NetUpdateTime = Level.TimeSeconds - 1;
            break;
        }
    }
    GotoState('');
}


defaultproperties
{
    bNetNotify=True
    NetUpdateFrequency=1.0
}