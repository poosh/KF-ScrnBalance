// moved from ScrnBalanceSrv to avoid in-game changes to ScrnBalanceSrv.ini
class ScrnMapInfo extends Object
    PerObjectConfig
    Config(ScrnMapInfo);

var ScrnBalance Mut;

struct SZVolDoor {
    var config name ZVol;
    var config name Door;
};

struct SPath {
    var config name From;
    var config name To;
    var config name Via[3];
};

var config int MaxZombiesOnce;
var config float WaveSpawnPeriod;
var config float XPBonusMult;
var config byte ZedEventNum; // use event zeds for this map. 0 - don't force
var config bool bTestMap;

var config float ZVolDisableTime, ZVolDisableTimeMax;
var config bool bVanillaVisibilityCheck;
var config float ZedSpawnMaxDist;
var config float ZedSpawnMinDistWeight;
var config float FloorHeight, BasementZ;
var config float FloorPenalty;
var config float ElevatedSpawnMinZ, ElevatedSpawnMaxZ;
var config bool bHighGround;
var config bool bResetSpawnDesirability;
var config array<name> ZVolBad;
var config array<name> ZVolHidden;
var config array<name> ZVolClose;
var config array<name> ZVolElevated;
var config array<name> ZVolJumpable;
var config array<SZVolDoor> ZVolDoors;

var config byte GuardianLight;
var config byte GuardianHueRed, GuardianHueBlue;
var config byte FTGTargetsPerWave;
var config array<name> FTGBadAmmo;
var config array<name> FTGTargets;
var config bool bReplaceFTGTargets;
var config array<SPath> FTGPaths;

static function int FindNameInArray(out array<name> names, name n)
{
    local int i;

    for ( i = 0; i < names.length; ++i ) {
        if ( names[i] == n )
            return i;
    }
    return -1;
}

static function string PathStr(out SPath p)
{
    return "(From="$p.From $ ",To="$p.To $ ",Via[0]="$p.Via[0]$ ",Via[1]="$p.Via[1]$ ",Via[2]="$p.Via[2] $")";
}

function bool IsBadAmmo(name n)
{
    return FindNameInArray(FTGBadAmmo, n) != -1;
}

function ProcessZombieVolumes(out array<ZombieVolume> ZList)
{
    local int i, j, k;
    local ZombieVolume ZVol;
    local name n;
    local KFDoorMover Door;

    for ( i = 0; i < ZList.length; ++i ) {
        ZVol = ZList[i];
        n = ZVol.name;
        if ( FindNameInArray(ZVolBad, n) != -1 ) {
            log(n $ " marked bad", class.name);
            ZList.remove(i--, 1);
            continue;
        }
        if ( bResetSpawnDesirability ) {
            if ( abs(ZVol.SpawnDesirability - ZVol.default.SpawnDesirability) > 30 ) {
                log(n $ " SpawnDesirability reset " $ ZVol.SpawnDesirability $ " => " $ ZVol.default.SpawnDesirability,                        class.name);
            }
            ZVol.SpawnDesirability = class'ZombieVolume'.default.SpawnDesirability;
        }
        if ( bHighGround ) {
            ZVol.bNoZAxisDistPenalty = false;
        }
        if ( FindNameInArray(ZVolHidden, n) != -1 ) {
            log(n $ " marked hidden", class.name);
            ZVol.bAllowPlainSightSpawns = true;
        }
        if ( FindNameInArray(ZVolClose, n) != -1 ) {
            log(n $ " marked close", class.name);
            ZVol.MinDistanceToPlayer = 1;
        }
        ZVol.bHasInitSpawnPoints = false;  // reuse this flag for elevation mark
        if ( FindNameInArray(ZVolElevated, n) != -1 ) {
            log(n $ " marked elevated", class.name);
            ZVol.bNoZAxisDistPenalty = true;
            ZVol.bHasInitSpawnPoints = true;
        }
        else if ( FindNameInArray(ZVolJumpable, n) != -1 ) {
            log(n $ " marked jumpable", class.name);
            ZVol.bNoZAxisDistPenalty = true;
        }
        for ( j = 0; j < ZVolDoors.length; ++j ) {
            if ( ZVolDoors[j].ZVol == n ) {
                Door = Mut.FindDoorByName(ZVolDoors[j].Door);
                if ( Door == none ) {
                    log(ZVolDoors[j].Door $ " - door not found", class.name);
                }
                else {
                    k = ZVol.RoomDoorsList.length;
                    ZVol.RoomDoorsList.insert(k, 1);
                    ZVol.RoomDoorsList[k].DoorActor = Door;
                    ZVol.RoomDoorsList[k].bOnlyWhenWelded = true;
                    log(n $ " disabled while " $ Door.name $ " welded", class.name);
                }
            }
        }
    }
}


defaultproperties
{
    ZVolDisableTime=10
    ZVolDisableTimeMax=60
    ZedSpawnMaxDist=2000
    FloorPenalty=0.3
    FloorHeight=256
    XPBonusMult=1.0
    FTGTargetsPerWave=3
}
