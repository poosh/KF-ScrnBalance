class FtgGame extends TSCGame
    config;

var class<StinkyClot>   StinkyClass;
var StinkyController    StinkyControllers[2];

var transient float NextStinkySpawnTime;

event InitGame( string Options, out string Error )
{
    // setting bCustomScoreboard=true tells TSCGame to do NOT set TSC Scoreboard
    bCustomScoreboard = bSingleTeamGame;
    super.InitGame(Options, Error);
    HUDType = string(Class'FtgHUD');

    if ( bSingleTeamGame ) {
        FriendlyFireScale = 0;
        bSingleTeam = true;
        bTeamWiped = true;
        bUseEndGameBoss = true;
        OvertimeWaves = 1; // boss wave
        SudDeathWaves = 0;
    }
}

function SetupWave()
{
    local byte t;

    super.SetupWave();

    if ( WaveNum > 0 ) {
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
            if ( StinkyControllers[t] != none && StinkyControllers[t] != Killed && StinkyControllers[t].Pawn != none )
            {
                StinkyControllers[t].Pawn.SetCollision(true, true);
                StinkyClot(StinkyControllers[t].Pawn).SetSkin();
            }
        }
    }
}

function bool SpawnStinkyClot()
{
    local int numspawned;
    local ZombieVolume zvol;
    local array< class<KFMonster> > StinkySquad;
    local int i;
    local int total;

    while ( zvol == none && ++i < 5 )
    {
        zvol = ZedSpawnList[rand(ZedSpawnList.Length)];
        if ( !zvol.bNormalZeds )
            zvol = none; // unable to spawn clot in that zombie volume
    }
    if( zvol == none ) {
        log("Couldn't find a place to spawn a Stinky Clot ("$StinkyClass$")! Trying again later.", class.name);
        return false;
    }

    total = 32; // dummy value
    StinkySquad[0] = StinkyClass;
    if ( !bSingleTeamGame && StinkyControllers[0] == none && TeamBases[0].bActive
        && StinkyControllers[1] == none && TeamBases[1].bActive )
    {
        StinkySquad[1] = StinkyClass; // spawn two of them
    }
    if( zvol.SpawnInHere(StinkySquad,,numspawned,total,32,,true))
    {
        //NumMonsters+=numspawned;
        //WaveMonsters+=numspawned;
        return true;
    }
    else
    {
        log("Failed to spawn the Stinky Clot: "$StinkyClass, class.name);
        return false;
    }
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

function StinkyControllerReady(StinkyController SC)
{
    local byte t;
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

    // TODO: add support to custom destination on the map.
    // Until then StinkyClot will move to enemy shop as first target
    SC.ActionNum = 0;
    SC.MoveTargets.length = 3;
    SC.MoveTargets[0] = TeamBases[SC.TeamIndex];
    SC.MoveTargets[1] = TeamShops[1-SC.TeamIndex].TelList[1-SC.TeamIndex];
    SC.MoveTargets[2] = TeamShops[SC.TeamIndex].TelList[SC.TeamIndex]; // move to own shop
    if ( bWaveBossInProgress ) {
        SC.Pawn.SetCollision(true, true); // Stinky Clot allways can be killed during the boss wave
        StinkyClot(StinkyControllers[t].Pawn).SetSkin();
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
    if ( SC.ActionNum >= SC.MoveTargets.length ) {
        gnome.MoveToShop(TeamShops[SC.TeamIndex]);
        SC.Pawn.Suicide(); // nothing else to do = die!
    }
    else {
        if ( CompletedActionNum == 0 ) {
            SC.TakeActor(gnome);
            gnome.Holder = SC.StinkyClot;
            gnome.bHeld = true;
        }
        SC.GotoState('MoveToShop', 'Begin');
    }
}

// show path to base instead of shop
function ShowPathTo(PlayerController P, int DestinationIndex)
{
    local TSCBaseGuardian gnome;

    gnome = TeamBases[P.PlayerReplicationInfo.Team.TeamIndex];
    if ( gnome == none || gnome.bHidden || TSCGRI.AtOwnBase(P.Pawn) )
    {
        ScrnPlayerController(P).ServerShowPathTo(255); // turn off
        return;
    }

    if ( P.FindPathToward(gnome, false) != None ) {
		Spawn(BaseWhisp, P,, P.Pawn.Location);
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
        KillAllStinkyClots();
        if ( bSingleTeamGame )
            super(ScrnGameType).DoWaveEnd(); // bypass TSC
        else
            super.DoWaveEnd();
    }

    function Timer()
    {
        super.Timer();
        if ( bWaveInProgress ) {
            if ( WaveNum > 0 && NextStinkySpawnTime < Level.TimeSeconds
                && ( (StinkyControllers[1] == none && TeamBases[1].bActive)
                    || (!bSingleTeamGame && StinkyControllers[0] == none && TeamBases[0].bActive) )
                && (bWaveBossInProgress || TotalMaxMonsters > 0) )
            {
                SpawnStinkyClot();
                NextStinkySpawnTime = Level.TimeSeconds + 5; // if failed to spawn, try again in 5 seconds
            }
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

    bSingleTeamGame=true
    bUseEndGameBoss=True
    MinBaseZ = -500;
    MaxBaseZ =  500;

    BaseGuardianClasses(0)=class'ScrnBalanceSrv.TheGuardianRed'
    BaseGuardianClasses(1)=class'ScrnBalanceSrv.TheGuardianBlue'
    StinkyClass=class'ScrnBalanceSrv.StinkyClot'
}