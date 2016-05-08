//for storing long numerical data that can't fit inside int
Class ScrnCustomProgressBytes extends SRCustomProgress
    Abstract;

const CHR_MAX_VAL = 0x3FFFFFC0; //don't use 6 lowest and 2 highest bits in unicode character (16-bit)
const CHR_STEP = 0x40; // 0x40 = 1 >>> 6
const CHR_1ST_BIT = 6;
const CHR_CONTROL_VALUE = 1; // highest bits of a character must be "01"

const MAX_SIZE = 512;

// most left char contains Data[0], right - Data[Data.length-1]
var private string          OldValueStr; // previous value that client received
var private string          CurrentValueStr; // value to store in perks DB
var protected array<byte>   Data;
var protected bool          bFixedDataSize; //if true, Data.Length won't be modified (sublasses need to overrire InitData() to it)
var protected bool          bReplicateDataToClients; // if true, CurrentValueStr will be always replicated to clients

//reason why CurrentValueStr has been updated
enum EValueSource
{
    SRC_None,
    SRC_External, // updated from outer source (e.g. perk DB)
    SRC_Internal // updated from Data
};
var private transient EValueSource ValueSource;

enum EStringStoreMethod
{
    SM_Hex,     //store data as string representation of hex values  (2 chars per byte, but data is human-readable)
    SM_Unicode  //store data inside unicode character (1 char per byte, but human will see crazy unicode chars instead of data)
};
var protected EStringStoreMethod StoreMethod;

replication
{
    reliable if( bReplicateDataToClients && bNetOwner && ( bNetDirty || bNetInitial ) && Role==ROLE_Authority )
        ValueSource, CurrentValueStr;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();
    if ( Role < Role_Authority && OldValueStr != CurrentValueStr ) {
        //log(GetItemName(String(name))$".PostNetReceive()  OldValueStr="$OldValueStr $ " CurrentValueStr="$CurrentValueStr, 'ScrnBalance');
        UpdateData();
        OldValueStr = CurrentValueStr;
    }
}

simulated function EValueSource GetValueSource()
{
    return ValueSource;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    InitData();
}

simulated function InitData();

simulated function string GetProgress()
{
    return CurrentValueStr;
}

simulated function int GetProgressInt()
{
    return 0;
}

simulated function string GetDisplayString()
{
    return class'SRCustomProgress'.default.ProgressName; //Lazy modder! Kill him!! :)
}

function SetProgress( string S )
{
    if ( Len(S) > MAX_SIZE) {
        log("ScrnCustomProgressBytes: Passed string is longer than " $ String(MAX_SIZE), 'ScrnBalance');
        S = left(S, MAX_SIZE); //trim long string
    }

    //log("SetProgress("$S$")", 'ScrnBalance');

    CurrentValueStr = S;
    ValueSource = SRC_External;
    if ( bReplicateDataToClients ) {
        NetUpdateTime = Level.TimeSeconds - 1; //send CurrentValueStr to clients
    }
    UpdateData();
}

function IncrementProgress( int Count );

static function String ByteToBin(byte AValue)
{
    local int i;
    local string s;

    while ( i++ < 8 ) {
        S = String(AValue & 1) $ S;
        AValue = AValue >>> 1;
    }
    return s;
}

static function String ByteToHex(byte AValue, optional bool bAddPrefix)
{
    local int i;
    local string s,c;
    local byte a;

    while ( i++ < 2 ) {
        a = AValue & 0xF;
        if ( a < 10 )
            c = chr(0x30 + a);
        else
            c = chr(0x41 + a-10);
        S = c $ S;
        AValue = AValue >>> 4;
    }
    if ( bAddPrefix )
        S = "0x" $ S;

    return S;
}

static function String IntToHex(int AValue, optional bool bAddPrefix)
{
    local int i;
    local string s,c;
    local byte a;

    while ( i++ < 8 ) {
        a = AValue & 0xF;
        if ( a < 10 )
            c = chr(0x30 + a);
        else
            c = chr(0x41 + a-10);
        S = c $ S;
        AValue = AValue >>> 4;
    }
    if ( bAddPrefix )
        S = "0x" $ S;

    return S;
}


static function byte HexToByte(String S)
{
    local int i, end, a;
    local byte result;

    if ( left(S, 2) ~= "0x" )
        i = 2; //skip prefix
    end = min(i + 2, len(S));

    while ( i < end ) {
        result = result << 4;
        a = asc(mid(s, i, 1));
        if ( a >= 0x30 && a <= 0x39 )
            a -= 0x30; //digit
        else if ( a >= 0x41 && a <= 0x46 )
            a = a + 10 - 0x41; //A-F
        else if ( a >= 0x61 && a <= 0x46 )
            a = a + 10 - 0x61; //a-f
        else
            return 0; // illegal character

        result = result | a;
        i++;
    }
    return result;
}

static function LogBytes(array<byte> AValues)
{
    local int i, a, count, c_len;
    local string i_str;

    count = AValues.Length;
    c_len=len(count);

    for ( i=0; i < count; ++i) {
        i_str = string(i+1);
        while ( len(i_str) < c_len )
            i_str = "0" $ i_str;
        a = AValues[i];
        log("#"$i_str$"/"$count$":" @ ByteToBin(a) @ ByteToHex(a,true) @ a, 'ScrnBalance');
    }
}

simulated function LogValues()
{
    log("ScrnCustomProgressBytes: Value of '"$CurrentValueStr$"':", 'ScrnBalance');
    LogBytes(Data);
}


static function StringToValues(string AString, out array<byte> AValues)
{
    if ( default.StoreMethod == SM_Unicode)
        UnicodeStringToValues(AString, AValues);
    else
        HexStringToValues(AString, AValues);
}

static function UnicodeStringToValues(string AString, out array<byte> AValues)
{
    local int i, count, val;
    local string c;

    if ( !default.bFixedDataSize )
        AValues.Length = len(AString);

    count = min(len(AString), AValues.Length);

    for ( i = 0; i < count; ++i ) {
        c = mid(AString,i,1);
        val = asc(c) >>> CHR_1ST_BIT;
        if ( val>>>8 != CHR_CONTROL_VALUE ) {
            // in case server admin manually edits stat table and screws the data
            log("ScrnCustomProgressBytes: Illegal Character #"$i$" '"$c$"' ("$asc(c)$") in string '"$AString$"'", 'ScrnBalance');
        }
        else {
            val = val & 0xFF; //clear a highest byte;
            AValues[i] = val;
        }
    }
}

static function HexStringToValues(string AString, out array<byte> AValues)
{
    local int i, count;

    if ( !default.bFixedDataSize )
        AValues.Length = len(AString)/2; //2 chars per one byte

    count = min(len(AString)/2, AValues.Length);

    for ( i = 0; i < count; ++i ) {
        AValues[i] = HexToByte(mid(AString,i*2,2));
    }
}


static function string ValuesToString(array<byte> AValues)
{
    if ( default.StoreMethod == SM_Unicode)
        return ValuesToUnicodeString(AValues);
    else
        return ValuesToHexString(AValues);
}

static function string ValuesToUnicodeString(array<byte> AValues)
{
    local int i;
    local string s;

    for ( i = 0; i < AValues.length; ++i ) {
        // add contro value, shift left 8 bits, fill data, shift dummy bits, which fill with random numbers
        s $= chr((CHR_CONTROL_VALUE<<8 | AValues[i])<<CHR_1ST_BIT | rand(0x3F));
    }
    return s;
}

static function string ValuesToHexString(array<byte> AValues)
{
    local int i;
    local string s;

    for ( i = 0; i < AValues.length; ++i ) {
        s $= ByteToHex(AValues[i], false);
    }
    return s;
}

simulated function UpdateData()
{
    StringToValues(CurrentValueStr, Data);
    //LogValues();
}

//clients can't update String, they just receive it from server
function UpdateValueString()
{
    CurrentValueStr = ValuesToString(Data);
    ValueSource = SRC_Internal;
    if ( bReplicateDataToClients )
        NetUpdateTime = Level.TimeSeconds - 1; //send CurrentValueStr to clients
}

/*
protected function FillWithTestData(int ValueCount)
{
    local int i;

    Data.Length = ValueCount;
    for ( i = 0; i < ValueCount; ++i ) {
        Data[i] = i;
    }
    UpdateString();
}
*/

defaultproperties
{
    bNetNotify=True
}
