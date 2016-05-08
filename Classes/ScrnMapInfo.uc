// moved from ScrnBalanceSrv to avoid in-game changes to ScrnBalanceSrv.ini 
class ScrnMapInfo extends Info
    Config(ScrnMapInfo);

struct SMapInfo {
    var String MapName;
    var int MaxZombiesOnce;
    var float Difficulty; // map difficulty, where 0 is normal difficulty, -1.0 - easiest, 2.0 - twice harder that normal
    var byte ForceEventNum; // use event zeds for this map. 0 - don't force
};

var config array<SMapInfo> MapInfo;



/* Searches MapInfo array for a given map 
 * @param bCreateNew [default = false] : should new record be created, if it doesn't exist?
 * @param MapName [default = <current map>] : map file name without extension
 * @return record index in MapInfo array or -1 if map info not found nad bCreateNew=false
 */
function int FindMapInfo(optional bool bCreateNew, optional string MapName)
{
    local int i;
    
    if ( MapName == "" )
        MapName = class'KFGameType'.static.GetCurrentMapName(Level);
    
    for ( i = 0; i < MapInfo.length; ++i ) {
        if ( MapInfo[i].MapName ~= MapName )
            return i;
    }
    
    // if we reached here, then MapInfo doesn't exist
    if ( bCreateNew ) {
        MapInfo.insert(i, 1);
        MapInfo[i].MapName = MapName;    
        return i;
    }
    
    return -1;
}

function bool SetMapZeds(int value, PlayerController Sender)
{
    local int i;
    i = FindMapInfo(false);

    if ( value == 0 ) {
        if ( i == -1 || MapInfo[i].MaxZombiesOnce == 0 )
            Sender.ClientMessage("Map-zeds-at-once = DEFAULT");
        else 
            Sender.ClientMessage("Map-zeds-at-once = " $ MapInfo[i].MaxZombiesOnce);
        return false;
    }
    
    if ( value < 32 || value > 192 ) {
        Sender.ClientMessage("Map-zeds-at-once must be in range [32..192], e.g. 'MUTATE MAPZEDS 64'");
        return false;
    }
    
    if ( i == -1 ) 
        i = FindMapInfo(true);    
    MapInfo[i].MaxZombiesOnce = value;
    Sender.ClientMessage("Map-zeds-at-once set to "$value$".");
    SaveConfig();
    return true;
}

function bool SetMapDifficulty(string StrDiff, PlayerController Sender)
{
    local int i;
    local float d;
    
    i = FindMapInfo(false);
    if ( StrDiff == "" ) {
        if ( i != -1 )
            d = MapInfo[i].Difficulty;
        Sender.ClientMessage("Map Difficulty = "$d$". (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
        return false;
    }
    if ( StrDiff != "0" && StrDiff != "0.0" && StrDiff != "0.00" ) {
        d = float(StrDiff);
        if ( d == 0.0 ) {
            Sender.ClientMessage("Map Difficulty must be a number between -1.0 and 1.0! (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
            return false;
        }
    }
    if ( d < -1.0 || d > 1.0 ) {
        Sender.ClientMessage("Map Difficulty must be a number between -1.0 and 1.0! (-1.0 = easiest; 0.0 = normal; 1.0 = hardest)");
        return false;
    }
    
    if ( i == -1 ) 
        i = FindMapInfo(true);
    MapInfo[i].Difficulty = d;
    Sender.ClientMessage("Map Difficulty set to "$d$".");
    SaveConfig();
    return true;
}
 
 
defaultproperties
{
    MapInfo(0)=(MapName="KF-AbusementPark",Difficulty=0.50,ForceEventNum=1)
    MapInfo(1)=(MapName="KF-Steamland",ForceEventNum=1)
    MapInfo(2)=(MapName="KF-Hellride",Difficulty=-0.25,ForceEventNum=1)
    MapInfo(3)=(MapName="KF-HillbillyHorror",ForceEventNum=2)
    MapInfo(4)=(MapName="KF-FrightYard",ForceEventNum=2)
    MapInfo(5)=(MapName="KF-Clandestine",ForceEventNum=2)
    MapInfo(6)=(MapName="KF-EvilSantasLair",ForceEventNum=3)
    MapInfo(7)=(MapName="KF-IceCave",Difficulty=0.25,ForceEventNum=3)
    MapInfo(8)=(MapName="KF-ThrillsChills",ForceEventNum=3)
    MapInfo(9)=(MapName="KF-BioticsLab",ForceEventNum=255)
    MapInfo(10)=(MapName="KF-Farm",Difficulty=-0.25,ForceEventNum=255)
    MapInfo(11)=(MapName="KF-Manor",ForceEventNum=255)
    MapInfo(12)=(MapName="KF-Offices",ForceEventNum=255)
    MapInfo(13)=(MapName="KF-WestLondon",ForceEventNum=255)
}    