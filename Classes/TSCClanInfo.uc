Class TSCClanInfo extends Object
    PerObjectConfig
    Config(ScrnClans);

var bool bPersistent;

var config string Acronym;
var config string ClanName;
var config string DecoName; // decorated name with colors and line breaks (optional)
var config string LogoRef;
var config string BannerRef;
var config array<string> Captains;
var config array<string> Players;

event created()
{
    log("TSCClanInfo created name="$name $ " Acronym="$Acronym);
    bPersistent = Acronym != "";
}

function Create()
{
    if (Acronym == "" || ClanName == "") {
        warn("Clan is missing mandatory parameters");
        return;
    }
    SaveConfig();
    bPersistent = true;
}

function bool Exists()
{
    return bPersistent;
}

function Save()
{
    if (bPersistent) {
        SaveConfig();
    }
}

function bool IsMember(string PlayerID)
{
    return IsPlayer(PlayerID) || IsCaptain(PlayerID);
}

function bool IsPlayer(string PlayerID)
{
    return class'ScrnFunctions'.static.SearchStr(Players, PlayerID) != -1;
}

// 0 - highest priority, -1 - not a captain
function int CaptainPriority(string PlayerID)
{
    return class'ScrnFunctions'.static.SearchStr(Captains, PlayerID);
}

function bool IsCaptain(string PlayerID)
{
    return CaptainPriority(PlayerID) != -1;
}

function bool AddPlayer(string PlayerID)
{
    if (IsCaptain(PlayerID) || IsPlayer(PlayerID))
        return false;

    Players[Players.length] = PlayerID;
    Save();
    return true;
}

function bool AddCaptain(string PlayerID)
{
    if (IsCaptain(PlayerID))
        return false;

    RemovePlayer(PlayerID);
    Captains[Captains.length] = PlayerID;
    Save();
    return true;
}

function bool RemovePlayer(string PlayerID)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(Players, PlayerID);
    if (i == -1)
        return false;

    Players.remove(i, 1);
    Save();
    return true;
}

function bool RemoveCaptain(string PlayerID)
{
    local int i;

    i = class'ScrnFunctions'.static.SearchStr(Captains, PlayerID);
    if (i == -1)
        return false;

    Captains.remove(i, 1);
    Save();
    return true;
}
