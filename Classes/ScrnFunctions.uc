class ScrnFunctions extends Object
abstract;

var const private string pad;

// Left-pads string to a given length with "with" or spaces.
// Makes use of native functions as much as possible for better perfomance (unless TWI screwed up C++ code too)
// Max padding is limited to 80 characters (len(pad))
static function string LPad(coerce string src, int to_len, optional string with)
{
    local string custom_pad;
    local int pad_len;

    pad_len = to_len - len(src);
    if ( pad_len <= 0 )
        return src; // source string already has enough characters

    if ( with != "" && with != " " ) {
        custom_pad = Repl(default.pad, " ", with, true);
        return left(custom_pad, pad_len) $ src;
    }
    return left(default.pad, pad_len) $ src;
}

static function string RPad(coerce string src, int to_len, optional string with)
{
    local string custom_pad;
    local int pad_len;

    pad_len = to_len - len(src);
    if ( pad_len <= 0 )
        return src; // source string already has enough characters

    if ( with != "" && with != " " ) {
        custom_pad = Repl(default.pad, " ", with, true);
        return src $ left(custom_pad, pad_len);
    }
    return src $ left(default.pad, pad_len);
}


defaultproperties
{
    pad="                                                                                "
}
