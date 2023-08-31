class ScrnFunctions extends ScrnF
    abstract;


struct SColorTag
{
    var string T;
    var byte R, G, B;
};
var array<SColorTag> ColorTags;


// ==============================================================
//                           STRINGS
// ==============================================================

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

final static function int SearchStr(out array<string> arr, string val)
{
    local int i;

    if (val == "" || arr.length == 0)
        return -1;

    for (i = 0; i < arr.length; ++i) {
        if (arr[i] == val)
            return i;
    }
    return -1;
}

final static function int SearchStrIgnoreCase(out array<string> arr, string val)
{
    local int i;

    if (val == "" || arr.length == 0)
        return -1;

    for (i = 0; i < arr.length; ++i) {
        if (arr[i] ~= val)
            return i;
    }
    return -1;
}

final static function int SearchName(out array<name> arr, name val)
{
    local int i;

    if (val == '' || arr.length == 0)
        return -1;

    for (i = 0; i < arr.length; ++i) {
        if (arr[i] == val)
            return i;
    }
    return -1;
}

// fancy time formatting
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

// parse tags and color strings
static final function string ParseColorTags(string ColoredText, optional PlayerReplicationInfo PRI)
{
    local int i;
    local string s;

    s = ColoredText;
    if ( PRI != none && PRI.Team != none )
        s = Repl(s, "^t", ColorStringC("", class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex]), true);
    else
        s = Repl(s, "^t", "", true);

    if ( KFPlayerReplicationInfo(PRI) != none )
        s = Repl(s, "^p", ColorStringC("", class'ScrnHUD'.static.PerkColor(KFPlayerReplicationInfo(PRI).ClientVeteranSkillLevel)), true);
    else
        s = Repl(s, "^p", "", true);


    for (i = 0; i < default.ColorTags.Length; ++i)
    {
        s = Repl(s, default.ColorTags[i].T, ColorString("",
                default.ColorTags[i].R, default.ColorTags[i].G, default.ColorTags[i].B), true);
    }

    return s;
}


// CHANGE ME!!!
// copy-pasted from ScrnPlayerController for easy access
static final function string ColorString(string s, byte R, byte G, byte B)
{
    return chr(27)$chr(max(R,1))$chr(max(G,1))$chr(max(B,1))$s;
}

static final function string ColorStringC(string s, color c)
{
    return chr(27)$chr(max(c.R,1))$chr(max(c.G,1))$chr(max(c.B,1))$s;
}


// remove color tags from string
static final function string StripColorTags(string ColoredText)
{
    local int i;
    local string s;

    s = ColoredText;
    s = Repl(s, "^p", "", true);
    s = Repl(s, "^t", "", true);
    for (i = 0; i < default.ColorTags.Length; ++i)
    {
        s = Repl(s, default.ColorTags[i].T, "", true);
    }

    return s;
}


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

static function class<ScrnVeterancyTypes> FindPerkByName(ClientPerkRepLink L, string VeterancyNameOrIndex)
{
    local int i;
    local class<ScrnVeterancyTypes> Perk;
    local string s1, s2;

    if ( L == none )
        return none;

    i = int(VeterancyNameOrIndex);
    if ( i > 0 && i <= L.CachePerks.Length )
        return class<ScrnVeterancyTypes>(L.CachePerks[i-1].PerkClass);
    // log("CachePerks.Length="$L.CachePerks.Length, 'ScrnBalance');
    for ( i = 0; i < L.CachePerks.Length; ++i ) {
        Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
        if ( Perk != none ) {
            // log(GetItemName(String(Perk.class)) @ Perk.default.VeterancyNameOrIndex, 'ScrnBalance');
            if ( Perk.default.ShortName ~= VeterancyNameOrIndex || Perk.default.VeterancyName ~= VeterancyNameOrIndex
                    || (Divide(Perk.default.VeterancyName, " ", s1, s2)
                        && (VeterancyNameOrIndex ~= s1 || VeterancyNameOrIndex ~= s2)) )
                return Perk;
        }
    }
    return none;
}

static function SendPerkList(PlayerController PC)
{
    local ScrnClientPerkRepLink L;
    local class<ScrnVeterancyTypes> Perk;
    local KFPlayerReplicationInfo KFPRI;
    local int i;
    local string s;

    L = class'ScrnClientPerkRepLink'.Static.FindMe(PC);
    if ( L == none )
        return;
    KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if ( KFPRI == none )
        return;

    for ( i = 0; i < L.CachePerks.Length; ++i ) {
        Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
        if ( Perk == none )
            continue;

        if ( Perk.default.bLocked ) {
            s = "[LOCKED] ";
        }
        else if (KFPRI.ClientVeteranSkill == Perk) {
            s = "*** ";
        }
        else {
            s = "";
        }
        s $= string(i + 1) $ ". " $ Perk.default.ShortName $ " - " $ Perk.default.VeterancyName;
        PC.ClientMessage(s);
    }
}

static function bool AddGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup) {
    local int i;

    if (BasePickup == none || SkinnedPickup == none) {
        return false;
    }

    for (i = 0; i < BasePickup.default.VariantClasses.length; ++i) {
        if (BasePickup.default.VariantClasses[i] == SkinnedPickup) {
            return false;
        }
    }

    BasePickup.default.VariantClasses[i] = SkinnedPickup;
    return true;
}

static function RemoveGunSkin(class<KFWeaponPickup> BasePickup, class<KFWeaponPickup> SkinnedPickup) {
    local int i;

    if (BasePickup == none) {
        return;
    }

    for (i = 0; i < BasePickup.default.VariantClasses.length; ++i) {
        if (BasePickup.default.VariantClasses[i] == SkinnedPickup) {
            BasePickup.default.VariantClasses.remove(i--, 1);
        }
    }
}


defaultproperties
{
    ColorTags(00)=(T="^0",R=1,G=1,B=1)
    ColorTags(01)=(T="^1",R=200,G=1,B=1)
    ColorTags(02)=(T="^2",R=1,G=200,B=1)
    ColorTags(03)=(T="^3",R=200,G=200,B=1)
    ColorTags(04)=(T="^4",R=1,G=1,B=255)
    ColorTags(05)=(T="^5",R=1,G=255,B=255)
    ColorTags(06)=(T="^6",R=200,G=1,B=200)
    ColorTags(07)=(T="^7",R=200,G=200,B=200)
    ColorTags(08)=(T="^8",R=255,G=127,B=0)
    ColorTags(09)=(T="^9",R=128,G=128,B=128)

    ColorTags(10)=(T="^w$",R=255,G=255,B=255)
    ColorTags(11)=(T="^r$",R=255,G=1,B=1)
    ColorTags(12)=(T="^g$",R=1,G=255,B=1)
    ColorTags(13)=(T="^b$",R=1,G=1,B=255)
    ColorTags(14)=(T="^y$",R=255,G=255,B=1)
    ColorTags(15)=(T="^c$",R=1,G=255,B=255)
    ColorTags(16)=(T="^o$",R=255,G=140,B=1)
    ColorTags(17)=(T="^u$",R=255,G=20,B=147)
    ColorTags(18)=(T="^s$",R=1,G=192,B=255)
    ColorTags(19)=(T="^n$",R=139,G=69,B=19)

    ColorTags(20)=(T="^W$",R=112,G=138,B=144)
    ColorTags(21)=(T="^R$",R=132,G=1,B=1)
    ColorTags(22)=(T="^G$",R=1,G=132,B=1)
    ColorTags(23)=(T="^B$",R=1,G=1,B=132)
    ColorTags(24)=(T="^Y$",R=255,G=192,B=1)
    ColorTags(25)=(T="^C$",R=1,G=160,B=192)
    ColorTags(26)=(T="^O$",R=255,G=69,B=1)
    ColorTags(27)=(T="^U$",R=160,G=32,B=240)
    ColorTags(28)=(T="^S$",R=65,G=105,B=225)
    ColorTags(29)=(T="^N$",R=80,G=40,B=20)
}