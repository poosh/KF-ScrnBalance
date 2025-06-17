class ScrnWaveRule_ReachTrader extends ScrnWaveRule;

var Actor ReachActors[2];
var Vector ReachLocations[2];

var float ReachDistSq, ReachDistZ;
var float StayDistSq;

var transient byte AlivePlayers[2];
var transient byte ReachedPlayers[2];
var transient bool bFinalCountdown;
var transient bool bRunning;
var int FinalCountdown;

function bool FindReachLocation(ShopVolume Shop, byte Team)
{
    if (!Shop.bTelsInit) {
        Shop.InitTeleports();
    }
    if (Shop.TelList.Length == 0)
        return false;

    ReachActors[Team] = Shop.TelList[0];
    ReachLocations[Team] = Shop.TelList[0].Location;
    return true;
}

function PlanB()
{
    log("Reach Trader wave failed. Falling back to Timeout", class.name);
    GL.Wave.EndRule = RULE_Timeout;
    GL.Rule = none;
}

function Run()
{
    local byte t;
    local Controller C;

    if (GL.TSC != none) {
        for (t = 0; t < 2; ++t) {
            if (GL.TSC.TeamShops[t] != none && !FindReachLocation(GL.TSC.TeamShops[t], t)) {
                PlanB();
                return;
            }
        }
    }
    else if (!FindReachLocation(GL.Game.ScrnGRI.CurrentShop, t)) {
        PlanB();
        return;
    }

    bRunning = true;
    GL.Game.ScrnGRI.TimeToNextWave = -1;  // hide countdown until any player reach the trader

    for (C = GL.Game.Level.ControllerList; C != none; C = C.NextController) {
        if (C.bIsPlayer) {
            MarkTrader(ScrnPlayerController(C));
        }
    }
}

function MarkTrader(ScrnPlayerController PC)
{
    local byte t;

    if (PC == none)
        return;

    t = PC.PlayerReplicationInfo.Team.TeamIndex;
    PC.ClientMark(KFPlayerReplicationInfo(PC.PlayerReplicationInfo), none, ReachLocations[t], "",
            class'ScrnHUD'.default.MARK_TRADER);
}

function UpdateStats()
{
    local Controller C;
    local PlayerReplicationInfo PRI;
    local ScrnCustomPRI ScrnPRI;
    local float dist;
    local byte t;

    AlivePlayers[0] = 0;
    AlivePlayers[1] = 0;
    ReachedPlayers[0] = 0;
    ReachedPlayers[1] = 0;

    for (C = GL.Game.Level.ControllerList; C != none; C = C.NextController) {
        if (!C.bIsPlayer || C.Pawn == none || C.Pawn.Health <= 0)
            continue;

        PRI = C.PlayerReplicationInfo;
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
        if (ScrnPRI == none || PRI.Team == none || PRI.Team.TeamIndex > 1)
            continue;

        t = PRI.Team.TeamIndex;
        ++AlivePlayers[t];

        dist = VSizeSquared(C.Pawn.Location - ReachLocations[t]);
        if (ScrnPRI.bReachedGoal) {
            if (dist > StayDistSq) {
                ScrnPRI.bReachedGoal = false;
                MarkTrader(ScrnPlayerController(C));
            }
            else {
                ++ReachedPlayers[t];
            }
        }
        else if (dist < ReachDistSq && abs(C.Pawn.Location.Z - ReachLocations[t].Z) < ReachDistZ) {
            ScrnPRI.bReachedGoal = true;
            ++ReachedPlayers[t];
        }
    }
}

function WaveTimer()
{
    local byte t;
    local int Counter;
    local int MissingPlayers;

    if (!bRunning)
        return;

    UpdateStats();
    GL.Game.ScrnGRI.ScoredPlayers[0] = ReachedPlayers[0];
    GL.Game.ScrnGRI.ScoredPlayers[1] = ReachedPlayers[1];

    if (bFinalCountdown) {
        if (GL.Game.ScrnGRI.TimeToNextWave > 0) {
            GL.Game.ScrnGRI.TimeToNextWave--;
        }
        return;
    }

    if (ReachedPlayers[0] == 0 && ReachedPlayers[1] == 0)
        return;

    for (t = 0; t < 2; ++t) {
        if (AlivePlayers[t] == 0)
            continue;

        if (ReachedPlayers[t] >= AlivePlayers[t]) {
            bFinalCountdown = true;
            GL.Game.ScrnGRI.TimeToNextWave = FinalCountdown;
            return;
        }

        Counter = GL.Wave.Counter;
        MissingPlayers = AlivePlayers[t] - ReachedPlayers[t] - GL.Wave.PerPlayerExclude;
        if (MissingPlayers > 0) {
            Counter *= 1.0 * GL.Wave.PerPlayerMult * MissingPlayers;
        }
        if (GL.Wave.MaxCounter > 0) {
            Counter = min(Counter, GL.Wave.MaxCounter);
        }

        if (GL.Game.ScrnGRI.TimeToNextWave < 0 || GL.Game.ScrnGRI.TimeToNextWave > Counter) {
            GL.Game.ScrnGRI.TimeToNextWave = Counter + 1;
        }
    }

    if (--GL.Game.ScrnGRI.TimeToNextWave <= FinalCountdown) {
        bFinalCountdown = true;
    }
}

function bool CheckWaveEnd() {
    return GL.Game.ScrnGRI.TimeToNextWave == 0;
}

defaultproperties
{
    ReachDistSq=62500  // 5m
    ReachDistZ=50
    StayDistSq=1000000  // 20m
    FinalCountdown=5
}
