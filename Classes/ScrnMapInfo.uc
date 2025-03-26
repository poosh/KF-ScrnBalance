// moved from ScrnBalanceSrv to avoid in-game changes to ScrnBalanceSrv.ini
class ScrnMapInfo extends Object
    dependson(ScrnTypes)
    PerObjectConfig
    Config(ScrnMapInfo);

var ScrnBalance Mut;

struct SZVolDoor {
    var config name ZVol;
    var config name Door;
};

struct SZVolLink {
    var config name Src;
    var config name Dst;
    var config name Door;
};

struct SPath {
    var config name From;
    var config name To;
    var config name Via[3];
};

var config bool bDebug;
var config bool bTestMap;

var config int MaxZombiesOnce;
var config bool bFastTrack;
var config float WaveSpawnPeriod;
var config byte BoringStage;
var config float XPBonusMult;
var config byte ZedEventNum; // use event zeds for this map. 0 - don't force
var config string AchName;

var config float ZVolDisableTime, ZVolDisableTimeMax;
var config bool bVanillaVisibilityCheck;
var config bool bOnlyInvisibleZVol;
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
var config array<SZVolLink> ZVolLinks;

var config byte GuardianLight, GuardianHue;
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

static function int FindZVolByName(out array<ZombieVolume> ZList, name n) {
    local int i;

    for (i = 0; i < ZList.length; ++i) {
        if (ZList[i].name == n)
            return i;
    }
    return -1;
}

function ProcessZombieVolumes(out array<ZombieVolume> ZList, out array<ScrnTypes.ZVolInfo> ZVolInfos)
{
    local int i, j, k, L, ZVolHiddenCount;
    local ZombieVolume ZVol;
    local name n;
    local KFDoorMover Door;
    local string s;

    for ( i = 0; i < ZList.length; ++i ) {
        ZVol = ZList[i];
        n = ZVol.name;
        if ( FindNameInArray(ZVolBad, n) != -1 ) {
            log(n $ " marked bad", class.name);
            ZList.remove(i, 1);
            ZVolInfos.remove(i, 1);
            --i;
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
        if (ZVol.bAllowPlainSightSpawns) {
            ++ZVolHiddenCount;
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

        for (j = 0; j < ZVolDoors.length; ++j) {
            if (ZVolDoors[j].ZVol != n)
                continue;

            Door = Mut.FindDoorByName(ZVolDoors[j].Door);
            if (Door == none) {
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

    if (bOnlyInvisibleZVol) {
        if (ZVolHiddenCount < 5) {
            log("Cannot enforce bOnlyInvisibleZVol due to low invisible ZVol count: " $ ZVolHiddenCount, class.name);
        }
        else {
            for ( i = 0; i < ZList.length; ++i ) {
                ZVol = ZList[i];
                if (!ZVol.bAllowPlainSightSpawns) {
                    log(n $ " marked bad (visible)", class.name);
                    ZList.remove(i, 1);
                    ZVolInfos.remove(i, 1);
                    --i;
                    continue;
                }
            }
        }
    }

    for (j = 0; j < ZVolLinks.length; ++j) {
        // log("ZVolLinks["$j$"] Src="$ZVolLinks[j].Src $ " Dst="$ZVolLinks[j].Dst $ " Door=" $ ZVolLinks[j].Door, class.name);
        if (ZVolLinks[j].Src == '' || ZVolLinks[j].Dst == '' || ZVolLinks[j].Src == ZVolLinks[j].Dst) {
            log("ZVolLinks["$j$"] - invalid entry", class.name);
            continue;
        }

        i = FindZVolByName(ZList, ZVolLinks[j].Dst);
        if (i == -1) {
            log("ZVolLinks["$j$"] - '" $ ZVolLinks[j].Dst $ "' ZVol not found", class.name);
            continue;
        }

        k = FindZVolByName(ZList, ZVolLinks[j].Src);
        if (k == -1) {
            log("ZVolLinks["$j$"] - '" $ ZVolLinks[j].Src $ "' ZVol not found", class.name);
            continue;
        }
        if (ZList[k].bAllowPlainSightSpawns) {
            log("ZVolLinks["$j$"] - Src cannot be hidden", class.name);
            continue;
        }

        Door = none;
        if (ZVolLinks[j].Door != '') {
            Door = Mut.FindDoorByName(ZVolLinks[j].Door);
            if (Door == none) {
                log("ZVolLinks["$j$"] - '" $ ZVolLinks[j].Door $ "' - door not found", class.name);
            }
        }

        L = ZVolInfos[i].Links.Length;
        ZVolInfos[i].Links.insert(L, 1);
        ZVolInfos[i].Links[L].Src = ZList[k];
        ZVolInfos[i].Links[L].Door = Door;

        s = "ZVolLinks["$j$"] " $ ZVolInfos[i].Links[L].Src;
        if (Door != none) {
            s $= " | " $ ZVolInfos[i].Links[L].Door.name $ " | ";
        }
        s $= " => " $ ZList[i].name;
        log(s, class.name);
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
