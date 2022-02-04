class ScrnUtility extends object;


static final function String FormatTime(int Seconds)
{
    local int Minutes, Hours;
    local String Time;

    if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

        Time = Hours$":";
    }
    Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    if( Minutes >= 10 || Hours == 0 )
        Time = Time $ Minutes $ ":";
    else
        Time = Time $ "0" $ Minutes $ ":";

    if( Seconds >= 10 )
        Time = Time $ Seconds;
    else
        Time = Time $ "0" $ Seconds;

    return Time;
}


//  Performs binary search on sorted array.
//  @param arr : array of sorted items (in ascending order). Array will not be modified.
//               out modifier is used just for performance purpose (pass by reference).
//  @param val : value to search
//  @return array index or -1, if value not found.
final static function int BinarySearch(out array<int> arr, int val)
{
    local int start, end, i;

    start = 0;
    end = arr.length;
    while ( start < end )
    {
        i = start + ((end - start)>>1);
        if ( arr[i] == val )
            return i;
        else if ( val < arr[i] )
            end = i;
        else
            start = i + 1;
    }
    return -1;
}


final static function int BinarySearchStr(out array<string> arr, string val)
{
    local int start, end, i;

    start = 0;
    end = arr.length;
    while ( start < end )
    {
        i = start + ((end - start)>>1);
        if ( arr[i] == val )
            return i;
        else if ( val < arr[i] )
            end = i;
        else
            start = i + 1;
    }
    return -1;
}

// ==============================================================
//                           STRINGS
// ==============================================================

//  Splits long message on short ones before sending it to client.
//  @param   Sender     Player, who will receive message(-s).
//  @param   S          String to send.
//  @param   MaxLen     Max length of one string. Default: 80. If S is longer than this value,
//                      then it will be splitted on serveral messages.
//  @param  Divider     Character to be used as divider. Default: Space. String is splitted
//                      at last divder's position before MaxLen is reached.
static function LongMessage(PlayerController Sender, string S, optional int MaxLen, optional string Divider)
{
    local int pos;
    local string part;

    if ( Sender == none )
        return;
    if ( MaxLen == 0 )
        MaxLen = 80;
    if ( Divider == "" )
        Divider = " ";

    while ( len(part) + len(S) > MaxLen ) {
        pos = InStr(S, Divider);
        if ( pos == -1 )
            break; // no more dividers

        if ( part != "" && len(part) + pos + 1 > MaxLen) {
            Sender.ClientMessage(part);
            part = "";
        }
        part $= Left(S, pos + 1);
        S = Mid(S, pos+1);
    }

    part $= S;
    if ( part != "" )
        Sender.ClientMessage(part);
}


// ==============================================================
//                           COLORS
// ==============================================================

// remove color characters from string
static final function string StripColor(string s)
{
    local int p;

    p = InStr(s,chr(27));
    while ( p>=0 )
    {
        s = left(s,p)$mid(S,p+4);
        p = InStr(s,Chr(27));
    }

    return s;
}


// returns first i amount of characters excluding escape color codes
static final function string LeftCol(string ColoredString, int i)
{
    local string s;
    local int p, c;

    if ( Len(ColoredString) <= i )
        return ColoredString;

    c = i;
    s = ColoredString;
    p = InStr(s,chr(27));
    while ( p >=0 && p < i ) {
        c+=4; // add 4 more characters due to color code
        s = left(s, p) $ mid(s, p+4);
        p = InStr(s,Chr(27));
    }

    return Left(ColoredString, c);
}