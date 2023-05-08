class FtgGame extends TSCGame
    config;

var config bool bDebugStinkyPath;
// log stinky paths beforehand, i.e. server admins can cheat by looking into the log during the game
var bool bDebugStinkyPathCheat;

var class<StinkyClot> StinkyClass;
var transient StinkyController StinkyControllers[2];
var transient array<KFAmmoPickup> StinkyAmmoPickups;   // ammo pickups that are valid for StinkyClot pickup
var transient array<NavigationPoint> StinkyTargets;

var transient float NextStinkySpawnTime;

struct SPathRedirect {
    var name From;
    var name To;
    var NavigationPoint N[3];
};
var transient array<SPathRedirect> StinkyPaths;

event InitGame( string Options, out string Error )
{
    super.InitGame(Options, Error);

    if ( bSingleTeamGame ) {
        FriendlyFireScale = 0;
        bSingleTeam = true;
        bTeamWiped = true;
        if ( ScrnGameLength == none ) {
            bUseEndGameBoss = true;
            OvertimeWaves = 1; // boss wave
            SudDeathWaves = 0;
        }
    }
}

function CheckZedSpawnList()
{
    local int i, j, k;
    local ScrnMapInfo MapInfo;
    local NavigationPoint N[3];
    local name TestName;
    local bool bHasNull;

    super.CheckZedSpawnList();

    MapInfo =  ScrnBalanceMut.MapInfo;
    StinkyAmmoPickups = AmmoPickups;
    for ( i = 0; i < StinkyAmmoPickups.length; ++i ) {
        TestName = ScrnAmmoPickup(StinkyAmmoPickups[i]).OriginalName;
        if ( MapInfo.IsBadAmmo(TestName) ) {
            log("Remove " $ TestName $ " from Stinky targets", class.name);
            StinkyAmmoPickups.remove(i--, 1);
        }
    }

    if ( MapInfo.bReplaceFTGTargets && MapInfo.FTGTargets.length == 0 ) {
        warn("MapInfo has no FTGTargets defined!");
        MapInfo.bReplaceFTGTargets = false;
    }

    if ( MapInfo.bReplaceFTGTargets ) {
        StinkyTargets.length = 0;
    }
    else {
        // add ammo boxes as targets
        StinkyTargets.length = StinkyAmmoPickups.length;
        for ( i = 0; i < StinkyAmmoPickups.length; ++i ) {
            // moving directly to ammo box is kinda bugged. So we are moving to closest path node instead
            StinkyTargets[i] = FindClosestPathNode(StinkyAmmoPickups[i]);
            if ( bDebugStinkyPath ) {
                log("Target for "
                        $ class'ScrnF'.static.RPad(ScrnAmmoPickup(StinkyAmmoPickups[i]).OriginalName, 14)
                        $ " is " $ StinkyTargets[i],
                        class.name);
            }
        }
    }

    if ( MapInfo.FTGTargets.length > 0 ) {
        i = StinkyTargets.length;
        StinkyTargets.length = i + MapInfo.FTGTargets.length;
        for ( j = 0; j < MapInfo.FTGTargets.length; ++j ) {
            N[0] = FindPathNodeByName(MapInfo.FTGTargets[j]);
            if ( N[0] != none ) {
                StinkyTargets[i++] = N[0];
            }
            else {
                log("Invalid FTGTarget: " $ MapInfo.FTGTargets[j], class.name);
            }
        }
    }
    // Make sure that there are no null targets
    for ( i = StinkyTargets.length - 1; i >= 0; --i ) {
        if ( StinkyTargets[i] == none )
            StinkyTargets.remove(i, 1);
    }
    log("Stinky Clot has " $ StinkyTargets.length $ " targets", class.name);
    if ( bDebugStinkyPath ) {
        for ( i = StinkyTargets.length - 1; i >= 0; --i ) {
            log(StinkyTargets[i], class.name);
        }
    }

    for ( i = 0; i < MapInfo.FTGPaths.length; ++i ) {
        if ( MapInfo.FTGPaths[i].From == MapInfo.FTGPaths[i].To
                || MapInfo.FTGPaths[i].Via[0] == ''
                || (MapInfo.FTGPaths[i].From == '' && MapInfo.FTGPaths[i].To == '') ) {
            log("Invalid FTGPath: " $ MapInfo.PathStr(MapInfo.FTGPaths[i]), class.name);
            continue;
        }
        if ( FindPathRedirect(StinkyPaths, MapInfo.FTGPaths[i].From, MapInfo.FTGPaths[i].To) != -1 ) {
            log("FTGPath " $ MapInfo.FTGPaths[i].From $ " => " $ MapInfo.FTGPaths[i].To $ " already exist!",
                    class.name);
            continue;
        }

        bHasNull = false;
        for ( j = 0; j < 3; ++j ) {
            TestName = MapInfo.FTGPaths[i].Via[j];
            if ( TestName == '' ) {
                N[j] = none;
                bHasNull = true;
            }
            else if ( TestName == MapInfo.FTGPaths[i].From || TestName == MapInfo.FTGPaths[i].To ) {
                break;
            }
            else {
                if ( bHasNull )
                    break;  // values cannot follow empty fields
                N[j] = FindPathNodeByName(TestName);
                if ( N[j] == none ) {
                    log("Invalid path node: " $ TestName, class.name);
                    break;
                }
            }
        }
        if ( j < 3 || N[0] == N[1] || N[0] == N[2] || ( N[1] != none && N[1] == N[2]) ) {
            log("Invalid FTGPath: " $ MapInfo.PathStr(MapInfo.FTGPaths[i]), class.name);
            continue;
        }

        k = StinkyPaths.length;
        StinkyPaths.insert(k, 1);
        StinkyPaths[k].From = MapInfo.FTGPaths[i].From;
        StinkyPaths[k].To = MapInfo.FTGPaths[i].To;
        for ( j = 0; j < 3; ++j ) {
            StinkyPaths[k].N[j] = N[j];
        }
    }
}

function InvalidatePathTarget(Actor BadTarget, optional bool bForceAdd)
{
    local int i;
    local byte t;
    local NavigationPoint NewTarget;
    local StinkyController SC;

    if ( BadTarget == none )
        return;

    super.InvalidatePathTarget(BadTarget, bForceAdd);

    NewTarget = FindClosestPathNode(BadTarget);
    if ( NewTarget == none ) {
        for ( i = 0; i < StinkyTargets.length; ++i ) {
            if ( StinkyTargets[i] == BadTarget ) {
                StinkyTargets.remove(i--, 1);
            }
        }

        for ( t = 0; t < 2; ++t ) {
            SC = StinkyControllers[t];
            if ( SC == none )
                continue;
            for ( i = SC.ActionNum; i < SC.MoveTargets.length - 1; ++i ) {
                if ( SC.MoveTargets[i] == BadTarget ) {
                    SC.MoveTargets.remove(i--, 1);
                }
            }
        }
    }
    else {
        for ( i = 0; i < StinkyTargets.length; ++i ) {
            if ( StinkyTargets[i] == BadTarget ) {
                StinkyTargets[i] = NewTarget;
            }
        }

        for ( t = 0; t < 2; ++t ) {
            SC = StinkyControllers[t];
            if ( SC == none )
                continue;
            for ( i = SC.ActionNum; i < SC.MoveTargets.length - 1; ++i ) {
                if ( SC.MoveTargets[i] == BadTarget ) {
                    SC.MoveTargets[i] = NewTarget;
                }
            }
        }
    }
}

function MaximizeDebugLogging()
{
    super.MaximizeDebugLogging();

    bDebugStinkyPath = true;
    bDebugStinkyPathCheat = true;
}

function SetupWave()
{
    local byte t;

    super.SetupWave();

    if ( (ScrnGameLength != none && ScrnGameLength.Wave.bOpenTrader) || (ScrnGameLength == none && WaveNum > 0) ) {
        ZedSpawnLoc = default.ZedSpawnLoc;
        //TotalMaxMonsters *= 0.75; // reduce amount of zeds in wave
        FriendlyFireScale = HDmgScale;

        if ( bSingleTeamGame ) {
            bSingleTeam = true;
            bTeamWiped = true;
            t = 1; // skip team 0
        }
        while ( t < 2 ) {
            if ( !TeamBases[t].bActive ) {
                // if players have lost base during the Trader Time
                TeamBases[t].MoveToShop(TeamShops[t]);
                TeamBases[t].ScoreOrHome();
            }
            ++t;
        }
        NextStinkySpawnTime = Level.TimeSeconds + 10;
    }
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType)
{
    local byte t;

    super.Killed(Killer, Killed, KilledPawn, damageType);

    if ( TSCGRI.MaxMonsters == 9 ) {
        // allow stinky clots to be killed at the end of the wave
        for ( t = 0; t < 2; ++t ) {
            if ( StinkyControllers[t] != none && StinkyControllers[t] != Killed
                    && StinkyControllers[t].StinkyClot != none )
            {
                StinkyControllers[t].StinkyClot.SetInvulnerability(false);
            }
        }
    }
}

function bool SpawnStinkyClot()
{
    local ZombieVolume ZVol;
    local array< class<KFMonster> > StinkySquad;
    local EZedSpawnLocation OldZedSpawnLoc;
    local int StinkyCount;

    StinkySquad[0] = StinkyClass;
    if ( !bSingleTeamGame && StinkyControllers[0] == none && TeamBases[0].bActive
            && StinkyControllers[1] == none && TeamBases[1].bActive )
    {
        StinkySquad[1] = StinkyClass; // spawn two of them
    }
    StinkyCount = StinkySquad.length;

    OldZedSpawnLoc = ZedSpawnLoc;
    ZedSpawnLoc = ZSLOC_RANDOM;
    ZVol = FindSpawningVolumeForSquad(StinkySquad, false);
    if ( Zvol == none ) {
        ZVol = FindSpawningVolumeForSquad(StinkySquad, true);
    }
    ZedSpawnLoc = OldZedSpawnLoc;
    if( ZVol == none ) {
        LogZedSpawn(LOG_ERROR, "Could not find a place to spawn a Stinky Clot ("$StinkyClass$")! Trying again later.");
        return false;
    }

    MaxMonsters += StinkyCount;
    TotalMaxMonsters += StinkyCount;
    if ( SpawnSquadLog(ZVol, StinkySquad) == 0 ) {
        LogZedSquadSpawn(LOG_ERROR, "Failed to spawn Stinky Clot:", StinkySquad);
    }
    // at this moment, StinkySquad containes only not spawned zeds
    MaxMonsters -= StinkyCount;
    TotalMaxMonsters -= StinkySquad.length;

    return StinkySquad.length == 0;
}

function byte GetTeamForStinkyController(StinkyController SC)
{
    local byte t;

    if ( bSingleTeamGame || StinkyControllers[0] != none || !TeamBases[0].bActive )
        t = 1;

    if ( StinkyControllers[t] != none || !TeamBases[t].bActive )
        return 255; //kill me!!!
    return t;
}

function int FindPathRedirect(out array<SPathRedirect> paths, name From, name To)
{
    local int i;

    for ( i = 0; i < paths.length; ++i ) {
        if ( paths[i].From == From && paths[i].To == To )
            return i;
    }
    return -1;
}

function ProcessStinkyPaths(out array<Actor> Targets)
{
    local int i, j, k, c, idx;
    local array<Actor> NewTargets;
    local Actor NewTarget;
    local string s;

    if ( StinkyPaths.length == 0 )
        return;

    // StinkyPaths are sorted by name
    for ( i = 0; i < Targets.length - 1; ++i ) {
        NewTargets.length = 0;

        idx = FindPathRedirect(StinkyPaths, Targets[i].name, Targets[i+1].name);
        if (idx != -1 ) {
            // paths with matching From & To have priority
            for ( j = 0; j < 3 && StinkyPaths[idx].N[j] != none; ++j ) {
                NewTargets[NewTargets.Length] = StinkyPaths[idx].N[j];
            }
        }
        else {
            // Find global paths From this target
            idx = FindPathRedirect(StinkyPaths, Targets[i].name, '');
            if (idx != -1 ) {
                for ( j = 0; j < 3 && StinkyPaths[idx].N[j] != none; ++j ) {
                    NewTargets[NewTargets.Length] = StinkyPaths[idx].N[j];
                }
            }
            // Find global paths To this target
            idx = FindPathRedirect(StinkyPaths, '', Targets[i+1].name);
            if (idx != -1 ) {
                c = NewTargets.Length;
                for ( j = 0; j < 3 && StinkyPaths[idx].N[j] != none; ++j ) {
                    NewTarget = StinkyPaths[idx].N[j];
                    if ( c > 0 ) {
                        // merge From and To - make sure targets do no duplicate
                        for ( k = 0; k < c; ++k ) {
                            if ( NewTargets[k] == NewTarget )
                                break;
                        }
                        if ( k < c ) {
                            continue; // target found - skip
                        }
                    }
                    NewTargets[NewTargets.Length] = NewTarget;
                }
            }
        }
        if ( NewTargets.length > 0 ) {
            if ( bDebugStinkyPath ) {
                s = "Stinky path redirect: " $ Targets[i].name;
                for ( k = 0; k < NewTargets.length; ++k ) {
                    s $= " => " $  NewTargets[k].name;
                }
                s $= " => " $ Targets[i+1].name;
                log(s, class.name);
            }
            Targets.insert(i+1, NewTargets.length);
            for ( k = 0; k < NewTargets.length; ++k ) {
                Targets[++i] = NewTargets[k];
            }
        }
    }

    if ( bDebugStinkyPathCheat ) {
        log("Stinky Targets: ", class.name);
        for ( i = 0; i < Targets.length; ++i ) {
            log(Targets[i], class.name);
        }
    }
}

function StinkyControllerReady(StinkyController SC)
{
    local int i, t, r;
    local array<NavigationPoint> UniqueTargets;

    SC.TeamIndex = GetTeamForStinkyController(SC);
    if ( SC.TeamIndex > 1 )
    {
        // wtf?
        SC.GotoState('LatentDeath', 'Begin'); // can't kill pawn in its PostBeginPlay(). Need to wait a bit.
        return;
    }

    if ( bWaveBossInProgress)
        SelectShop(); // during boss wave select different move locations per each stinky clot

    for ( t=0; t < 2; ++t ) {
        if ( !TeamShops[t].bTelsInit )
            TeamShops[t].InitTeleports();
        if ( TeamShops[t].TelList.Length == 1 ) {
            // from stupid maps with only 1 player teleport per trader
            TeamShops[t].TelList[1] = TeamShops[t].TelList[0];
        }
    }

    SC.ActionNum = 0;

    if ( bWaveBossInProgress || (ScrnGameLength != none && ScrnGameLength.NextWave != none
        && !ScrnGameLength.NextWave.bOpenTrader) )
    {
        // if there is no trader on the next wave, don't hurry to the closed shop - go for more ammo
        if ( StinkyTargets.length >= 5 ) {
            t = StinkyTargets.length * 3 / 4;
        }
        else {
            t = StinkyTargets.length;
        }
    }
    else {
        t = min(StinkyTargets.length, ScrnBalanceMut.MapInfo.FTGTargetsPerWave);
    }

    i = 0;
    SC.MoveTargets[i++] = TeamBases[SC.TeamIndex];
    if ( t > 0 ) {
        UniqueTargets = StinkyTargets;
        while ( t > 0 && UniqueTargets.length > 0) {
            --t;
            r = rand(UniqueTargets.length);
            SC.MoveTargets[i++] = UniqueTargets[r];
            UniqueTargets.remove(r--, 1);
        }
    }
    if ( SC.MoveTargets.length < 2 ) {
        // at least move somewhere else
        log("Not enought targets for Stinky Clot. Add FTGTargets in MapInfo.", class.name);
        SC.MoveTargets[i++] = TeamShops[1-SC.TeamIndex].TelList[1-SC.TeamIndex];
    }
    SC.MoveTargets[i++] = TeamShops[SC.TeamIndex].TelList[SC.TeamIndex]; // move to own shop
    SC.MoveTargets.length = i;
    ProcessStinkyPaths(SC.MoveTargets);
    if ( bWaveBossInProgress ) {
        SC.StinkyClot.SetInvulnerability(false); // Stinky Clot allways can be killed during the boss wave
    }
    StinkyControllers[SC.TeamIndex] = SC;
    SC.GotoState('MoveToGuardian', 'Begin');
}

function StinkyControllerCompeledAction(StinkyController SC, int CompletedActionNum)
{
    local TSCBaseGuardian gnome;

    gnome = TeamBases[SC.TeamIndex];
    if ( !gnome.bActive ) {
        SC.Pawn.Suicide(); // base does not exist - stinky clot has nothing to do
    }

    if ( bDebugStinkyPath && CompletedActionNum > 0 && CompletedActionNum < SC.MoveTargets.length ) {
        log("Stinky has completed action #"$CompletedActionNum  $ ": " $ SC.MoveTargets[CompletedActionNum-1]
                $ " => " $ SC.MoveTargets[CompletedActionNum], class.name);
    }

    if ( SC.ActionNum >= SC.MoveTargets.length ) {
        SC.Pawn.Suicide(); // nothing else to do = die!
    }
    else {
        if ( CompletedActionNum == 0 ) {
            SC.TakeActor(gnome);
            gnome.SetRelativeLocation(gnome.GameObjOffset);
            gnome.SetRelativeRotation(gnome.GameObjRot);
            gnome.Holder = SC.StinkyClot;
            gnome.bHeld = true;
            ZedSpawnLoc = ZSLOC_RANDOM;
            SetBoringStage(0);
            if ( !bWaveBossInProgress && ScrnGameLength != none ) {
                NextMonsterTime += ScrnGameLength.FtgSpawnDelayOnPickup;
            }
        }
        if ( bDebugStinkyPathCheat ) {
            log("Next Stinky Path: " $ SC.MoveTargets[CompletedActionNum] $ " => " $ SC.MoveTargets[SC.ActionNum],
                class.name);
        }
        SC.GotoState('MoveToShop', 'Begin');
    }
}

// show path to base instead of shop
function ShowPathTo(PlayerController P, int DestinationIndex)
{
    ShowPathToBase(P);
}

function ShowPathToBase(PlayerController P)
{
    local TSCBaseGuardian gnome;
    local Actor Dest;

    gnome = TeamBases[P.PlayerReplicationInfo.Team.TeamIndex];
    if ( gnome == none || gnome.bHidden || TSCGRI.AtOwnBase(P.Pawn) )
    {
        ScrnPlayerController(P).ServerShowPathTo(255); // turn off
        return;
    }

    if (gnome.bHeld && gnome.Holder != none) {
        Dest = gnome.Holder;
    }
    else {
        Dest = gnome;
    }
    if ( P.FindPathToward(Dest, false) != None ) {
        Spawn(BaseWhisp, P,, P.Pawn.Location);
    }
}

function KillRemainingZeds(bool bForceKill)
{
    super.KillRemainingZeds(bForceKill);
    if (bForceKill) {
        KillAllStinkyClots();
    }
}

function KillAllStinkyClots()
{
    local array <StinkyClot> Monsters;
    local StinkyClot M;
    local int i;

    // kill all stinky clots
    foreach DynamicActors(class 'StinkyClot', M) {
        if(M.Health > 0 && !M.bDeleteMe)
            Monsters[Monsters.length] = M;
    }
    for ( i=0; i<Monsters.length; ++i )
        Monsters[i].Suicide();
}

function DoBossDeath()
{
    KillAllStinkyClots();
    super.DoBossDeath();
}


State MatchInProgress
{
    function DoWaveEnd()
    {
        local byte t;

        if ( bSingleTeamGame )
            super(ScrnGameType).DoWaveEnd(); // bypass TSC
        else
            super.DoWaveEnd();

        if ( ScrnGameLength == none || ScrnGameLength.Wave.bOpenTrader ) {
            KillAllStinkyClots();
        }
        else {
            // Wave ended but trader doors are closed.
            // Keep the stinky clots but apply new trader destinations.
            for ( t = 0; t < 2; ++t ) {
                if ( StinkyControllers[t] != none && StinkyControllers[t].MoveTargets.length != 0 ) {
                    StinkyControllers[t].MoveTargets[StinkyControllers[t].MoveTargets.length-1] = TeamShops[t].TelList[t];
                }
            }
        }
    }

    function BattleTimer()
    {
        super.BattleTimer();

        if ( NextStinkySpawnTime < Level.TimeSeconds
                && (bWaveBossInProgress || TotalMaxMonsters > 0)
                && ( (StinkyControllers[1] == none && TeamBases[1].bActive)
                    || (!bSingleTeamGame && StinkyControllers[0] == none && TeamBases[0].bActive) )
           )
        {
            SpawnStinkyClot();
            NextStinkySpawnTime = Level.TimeSeconds + 5; // if failed to spawn, try again in 5 seconds
        }
    }

    function StartWaveBoss()
    {
        local byte t;

        if ( bSingleTeamGame )
            t = 1; // skip red team

        while ( t < 2 ) {
            if ( !TeamBases[t].bActive ) {
                // if players have lost base during the Trader Time
                TeamBases[t].MoveToShop(TeamShops[t]);
                TeamBases[t].ScoreOrHome();
            }
            ++t;
        }

        NextStinkySpawnTime = Level.TimeSeconds + 30; // give enough time for Boss to spawn
        super.StartWaveBoss();
    }
}

defaultproperties
{
    GameName="Follow the Guardian"
    Description="Non-competitive TSC version for single team."
    ScreenShotName="TSC_T.Team.SteampunkLogo"

    DefaultGameLength=51
    bSingleTeamGame=true
    bUseEndGameBoss=true
    MinBaseZ = -500
    MaxBaseZ =  500
    ZedSpawnLoc=ZSLOC_AUTO

    HUDType="ScrnBalanceSrv.FtgHUD"
    ScoreBoardType="ScrnBalanceSrv.ScrnScoreBoard"
    BaseGuardianClasses(0)=class'TheGuardianRed'
    BaseGuardianClasses(1)=class'TheGuardianBlue'
    StinkyClass=class'StinkyClot'
}
