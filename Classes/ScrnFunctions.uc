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

// Converts version number in user-friendly string, e.g. 1.23 or 1.23.45
static function string VersionStr(int v, optional bool bClean) {
    local string s;
    local int major, minor, patch;

    // for some reason, UnrealScript has operator % declared only for float not for int.
    // So we can't use % here due to precision
    if (v >= 10000) {
        major = v / 10000;  v -= major * 10000;
        minor = v / 100;    v -= minor * 100;
        patch = v;
    }
    else {
        major = v / 100;    v -= major * 100;
        minor = v;
    }

    if ( !bClean ) {
        s $= "v";
    }
    s $= major $ "." $ LPad(string(minor), 2, "0");
    if ( patch > 0) {
        s $= "." $ LPad(string(patch), 2, "0");
    }
    return s;
}


defaultproperties
{
    pad="                                                                                "
}
