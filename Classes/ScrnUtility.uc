class ScrnUtility extends object;


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