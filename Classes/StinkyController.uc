class StinkyController extends ScriptedController;

var FtgGame FtgGame;
var byte TeamIndex; // is set by FtgGame
var StinkyClot StinkyClot;

var array<Actor> MoveTargets;

var array<KFAmmoPickup> AmmoCandidates;
var transient KFAmmoPickup CurrentAmmoCandidate;
var int AmmoSpawnCount, MaxAmmoSpawnCount;
var transient int AmmoSpawned, AmmoExisted;
var float AmmoPPPM; // Ammo spawned Per Player Per Minute
var transient float LastAmmoSpawnTime;

var transient Actor LastAlternatePathTarget;
var transient NavigationPoint LastAlternatePathPoint;
var transient Actor OldMoveTarget;
var transient Actor TeleportTarget;
var transient int TeleportAttempts;
var transient int ActionMoves;
var int MoveAttempts;
var float GuardianReachTime; // max time to reach the guardian. Gets extended if Stinky cannot see the guardian;
var transient float GuardianReachDeadline;
var int GuardianVisibilityChecks;

var localized string BlameStr;

function PostBeginPlay()
{
    FtgGame = FtgGame(Level.Game);
    AmmoCandidates = FtgGame.StinkyAmmoPickups;
    LastAmmoSpawnTime = Level.TimeSeconds;
    super.PostBeginPlay();
}

function Possess(Pawn aPawn)
{
    super.Possess(aPawn);
    StinkyClot = StinkyClot(Pawn);
    if ( StinkyClot != none && FtgGame != none) {
        FtgGame.StinkyControllerReady(self);
    }
}

function TakeControlOf(Pawn aPawn) {}

function int GetActionCount()
{
    return MoveTargets.length;
}

function Actor GetActionStart()
{
    if ( ActionNum > 0 && ActionNum - 1 < MoveTargets.length )
        return MoveTargets[ActionNum - 1];
    return none;
}

function Actor GetActionTarget()
{
    if ( ActionNum < MoveTargets.length )
        return MoveTargets[ActionNum];
    return none;
}

function Actor GetMoveTarget()
{
    local Actor result;

    result = GetActionTarget();
    if ( result != none && result == LastAlternatePathTarget && LastAlternatePathPoint != none )
        result = LastAlternatePathPoint; // target unreachable -> reroute to closest nav. point
    return result;
}

function Stuck()
{
    local NavigationPoint N;
    local string s;

    if ( Target == none ) {
        warn("No Target");
        return;
    }

    if ( LastAlternatePathTarget == Target && LastAlternatePathPoint != none ) {
        // make sure we don't use this navigation point anymore
        FtgGame.InvalidatePathTarget(LastAlternatePathPoint);
    }

    s = "Unreachable actor " $ GetItemName(string(Target)) $ " @ (" $ Target.Location $ ")";
    N = FtgGame.FindClosestPathNode(Target);

    if ( N == none ) {
        log(s $ " => abort", class.name);
    }
    else {
        log(s $ " => rerouting to " $ N, class.name);
        MoveTarget = FindPathToward(N, false);
    }
    LastAlternatePathTarget = Target;
    LastAlternatePathPoint = N;
}

function CompleteAction()
{
    FtgGame.StinkyControllerCompeledAction(self, ActionNum++);
}

function TakeActor(Actor A)
{
    A.SetBase(Pawn);
    Pawn.AttachToBone(A, StinkyClot.GrabBone);
}

function int CalcSpeed()
{
    return StinkyClot.OriginalGroundSpeed;
}

function AdjustSpeed()
{
    local int spd;

    if (StinkyClot == none || StinkyClot.Health <= 0)
        return;

    spd = CalcSpeed();
    // if (spd != int(StinkyClot.GroundSpeed)) {
    //     log("Stinky Speed " $ int(StinkyClot.GroundSpeed) $ " => " $ spd, class.name);
    // }
    StinkyClot.GroundSpeed = spd;
    StinkyClot.WaterSpeed = spd;
    StinkyClot.AirSpeed = spd;
    StinkyClot.HiddenGroundSpeed = spd;
}

function bool CanSpeedAdjust()
{
    return false;
}

function float PlayCompleteAnimation()
{
    if( Pawn.Physics==PHYS_Falling )
    {
        Pawn.SetPhysics(PHYS_Walking);
    }

    Pawn.SetAnimAction('KnockDown'); // dunno why but the next anim doesn't work without this
    Pawn.SetAnimAction(StinkyClot.CompleteAnim);
    Pawn.Acceleration = vect(0, 0, 0);
    Pawn.Velocity.X = 0;
    Pawn.Velocity.Y = 0;
    Return 0.8;
}

function float AfterCompleteCooldown()
{
    return 2.0;
}

function WhatToDoNext()
{
    log("Stuck at state " $ GetStateName(), class.name);
}

function DoAdditionalActions()
{
}

state LatentDeath
{
Begin:
    sleep(2.0);
    if ( Pawn != none ) {
        Pawn.Suicide();
    }
}

state Moving extends Scripting
{
    ignores Timer;

    function AbortScript()
    {
        if ( StinkyClot != none ) {
            StinkyClot.Suicide();
        }
        LeaveScripting();
    }

    function SetMoveTarget()
    {
        Focus = ScriptedFocus;
        Target = GetMoveTarget();
        if ( Target == None ) {
            Pawn.Suicide();
            //GotoState('Broken');
            return;
        }
        if ( Focus == None )
            Focus = Target;
        MoveTarget = Target;
        TeleportTarget = none;

        if ( MoveTarget != none && !ActorReachable(MoveTarget) ) {
            MoveTarget = FindPathToward(MoveTarget, false);
            if ( MoveTarget == none && ActionMoves == 0 ) {
                // this could be a dead end, like badly placed ammo box or base guardian
                // teleport one step back and try again
                log("No path to " $ GetItemName(string(Target)), class.name);
                TeleportTarget = StinkyClot.MoveHistory[1];
                ActionMoves++;
                if ( TeleportTarget != none )
                    return;
            }

            if ( MoveTarget == none || (MoveTarget == OldMoveTarget && --MoveAttempts <= 0) ) {
                log("Stuck @ (" $ Pawn.Location $ ") while navigating to " $ GetItemName(string(MoveTarget))
                        $ " / " $ GetItemName(string(Target)), class.name);
                StinkyClot.LogPath();

                switch (TeleportAttempts) {
                    case 0:
                        if ( CurrentPath != none && CurrentPath.End != none ) {
                            TeleportTarget = CurrentPath.End;
                            break;
                        }
                        // else fallthrough
                    case 1:
                        if ( NextRoutePath != none && NextRoutePath.End != none ) {
                            TeleportTarget = NextRoutePath.End;
                            break;
                        }
                        // else fallthrough
                    default:
                        Stuck();
                }
                if ( TeleportTarget != none )
                    return;
            }
        }

        if ( MoveTarget == None ) {
            AbortScript();
            return;
        }

        if ( Focus == Target )
            Focus = MoveTarget;
        if ( OldMoveTarget != MoveTarget ) {
            ActionMoves++;
            StinkyClot.OnMoveTarget(MoveTarget);
            OldMoveTarget = MoveTarget;
            MoveAttempts = default.MoveAttempts;
        }
        // Level.GetLocalPlayerController().ClientMessage("Moving to " $ GetItemName(string(MoveTarget)) $ " / " $ GetItemName(string(Target)), 'log');
    }

    function CompleteAction()
    {
        global.CompleteAction();
    }

Begin:
    Pawn.SetMovementPhysics();
    WaitForLanding();
KeepMoving:
    if ( StinkyClot.TeleportPhase != StinkyClot.TELEPORT_NONE ) {
        // wait for teleportation to finish
        sleep(1.0);
        Goto('Begin');
    }
    DoAdditionalActions();
    SetMoveTarget();
Teleporting:
    if ( TeleportTarget != none ) {
        StinkyClot.TeleportToActor(TeleportTarget);
        TeleportTarget = none;
        TeleportAttempts++;
        Goto('KeepMoving');
    }
    TeleportAttempts = 0;
    AdjustSpeed();
    // MayShootTarget();
    if ( MoveTarget != None && MoveTarget != Pawn ) {
        MoveToward(MoveTarget, Focus,,,Pawn.bIsWalking);

        if ( !Pawn.ReachedDestination(GetMoveTarget()) ) {
            Goto('KeepMoving');
        }

        ActionMoves = 0;
        MoveTarget = none;
        // make sure the Stinky Clot won't teleport at this phase
        StinkyClot.StuckCounter = 0;
        StinkyClot.NextStuckTestTime = Level.TimeSeconds + 5;
    }
Completing:
    sleep(PlayCompleteAnimation());
    CompleteAction();
    sleep(AfterCompleteCooldown());
    WhatToDoNext();
}

state MoveToGuardian extends Moving
{
    function BeginState()
    {
        super.BeginState();
        SetTimer(60, false);
        GuardianReachDeadline = 0;
        GuardianVisibilityChecks = GuardianReachTime;
    }

    function EndState()
    {
        super.EndState();
        SetTimer(GuardianReachTime, false);
    }

    function Timer()
    {
        if (GuardianReachDeadline == 0) {
            if (GuardianVisibilityChecks <= 0 || LineOfSightTo(Target)) {
                GuardianReachDeadline = Level.TimeSeconds + GuardianReachTime;
                SetTimer(GuardianReachTime + 0.1, false);
                log(FtgGame.ScrnBalanceMut.GameTimeStr() $ " Base Deadline in " $ GuardianReachTime, class.name);
            }
            else {
                // wait for the line of sight
                SetTimer(1, false);
                --GuardianVisibilityChecks;
            }
        }
        else if (Level.TimeSeconds < GuardianReachDeadline) {
            SetTimer(GuardianReachDeadline - Level.TimeSeconds + 0.1, false);
        }
        else {
            log(FtgGame.ScrnBalanceMut.GameTimeStr() $ " Base Deadline reached", class.name);
            SetTimer(GuardianReachTime, false); // shouldn't trigger
            // FtgBaseGuardian(Target).BlameBaseSetter(BlameStr);
            TeleportTarget = GetMoveTarget();
            GotoState(, 'Teleporting');
        }
    }

    function Stuck()
    {
        global.Stuck();

        if ( MoveTarget == none && LastAlternatePathPoint != none && TeleportAttempts < 3 ) {
            // Most-likely spawned in glitch spot due to map level design
            // teleport next to guardian
            TeleportTarget = LastAlternatePathPoint;
        }
        // else if ( FtgBaseGuardian(Target) != none ) {
        //     FtgBaseGuardian(Target).BlameBaseSetter(BlameStr);
        // }
    }

    function int CalcSpeed()
    {
        if ( FtgGame.bWaveBossInProgress )
            return StinkyClot.MaxBoostSpeed;

        return min( Pawn.GroundSpeed + 2, StinkyClot.MaxBoostSpeed ) ; // each call move faster and faster
    }
}

state MoveToShop extends Moving
{
    function AbortScript()
    {
        if ( ActionNum < MoveTargets.length-1 )
            CompleteAction();
        else
            super.AbortScript();
    }

    function Actor GetMoveTarget()
    {
        if ( ActionNum < MoveTargets.length-1 && FtgGame.TotalMaxMonsters <= 0
                && FtgGame.NumMonsters <= 16 + rand(16) )
        {
            ActionNum = MoveTargets.length-1; // end of the wave -> move directly to the last target
        }
        return global.GetMoveTarget();
    }

    function Stuck()
    {
        if ( KFAmmoPickup(Target) != none ) {
            AbortScript();
        }
        else {
            global.Stuck();
        }
    }

    function DoAdditionalActions()
    {
        local KFAmmoPickup ammo;
        local int i;

        if ( FtgGame.TSCGRI.MaxMonsters < 16 )
            return; // no ammo spawning during end of the game

        for ( i = AmmoCandidates.length - 1; i >= 0; --i ) {
            ammo = AmmoCandidates[i];
            if ( abs(Pawn.Location.Z - ammo.Location.Z) < 100
                    && VSizeSquared(Pawn.Location - ammo.Location) < 1000000 // 20m
                    && Pawn.FastTrace(Pawn.Location, ammo.Location) )
            {
                AmmoCandidates.remove(i, 1);
                if ( ammo.bSleeping ) {
                    CurrentAmmoCandidate = ammo;
                    GotoState( 'MoveToAmmo', 'Begin' ); // go for ammo
                }
                else {
                    // ammo is already spawned
                    ++AmmoExisted;
                }
                return;
            }
        }
    }

    function int CalcSpeed()
    {
        local TSCBaseGuardian gnome;

        gnome = FtgGame.TeamBases[TeamIndex];
        if (FtgGame.TotalMaxMonsters <= 0 && !FtgGame.bWaveBossInProgress) {
            if ( FtgGame.NumMonsters < 10 )
                return StinkyClot.MaxBoostSpeed;
            else if (gnome.SameTeamCounter < gnome.default.SameTeamCounter)
                return StinkyClot.OutOfBaseSpeed; // slowdown when nobody at the base to give team a chance to reach the base
            else
                return 2.0 * StinkyClot.OriginalGroundSpeed;
        }
        else if (gnome.SameTeamCounter < gnome.default.SameTeamCounter)
            return StinkyClot.OutOfBaseSpeed; // slowdown when nobody at the base to give team a chance to reach the base
        else if (FtgGame.TotalMaxMonsters < 50  && !FtgGame.bWaveBossInProgress)
            return StinkyClot.OriginalGroundSpeed * (2.0 - FtgGame.TotalMaxMonsters/50.0);
        else
            return StinkyClot.OriginalGroundSpeed;
    }

    function CompleteAction()
    {
        AmmoCandidates = FtgGame.StinkyAmmoPickups; // allow respawing ammo boxes
        global.CompleteAction();
    }
}

state MoveToAmmo extends Moving
{
    function BeginState()
    {
        super.BeginState();
        SetTimer(30, false);

        AmmoSpawned = 0;
        AmmoSpawnCount = default.AmmoSpawnCount;
        if (AmmoPPPM < 1.1 * default.AmmoPPPM) {
            // extra ammo box per 3 players
            AmmoSpawnCount += FtgGame.AliveTeamPlayerCount[TeamIndex] / 3;
            // If AmmoPPPM drastically drops, spawn more ammo even in 1-2 player games
            AmmoSpawnCount = max(AmmoSpawnCount, 1.5 * default.AmmoPPPM / AmmoPPPM);
            AmmoSpawnCount = min(AmmoSpawnCount, MaxAmmoSpawnCount);
        }
    }

    function EndState()
    {
        super.EndState();
        SetTimer(0, false);
    }

    function Timer()
    {
        AbortScript();
    }

    function Actor GetMoveTarget()
    {
        return CurrentAmmoCandidate;
    }

    function AbortScript()
    {
        // if can't reach ammo box, then just exit the state intead of aborting the entire script
        CurrentAmmoCandidate = none;
        WhatToDoNext();
    }

    function Stuck()
    {
        AbortScript();
    }

    function CompleteAction()
    {
        local float dt;

        CurrentAmmoCandidate.GotoState('Pickup');

        if (++AmmoSpawned >= AmmoSpawnCount) {
            dt = Level.TimeSeconds - LastAmmoSpawnTime;
            class'ScrnFunctions'.static.lpf(AmmoPPPM,
                    (AmmoSpawned + AmmoExisted) * 60.0 / dt / fmax(1.0, FtgGame.AliveTeamPlayerCount[TeamIndex]),
                    dt, 60.0);
            // class'ScrnF'.static.dbg(self, "Sinky Spawned " $ AmmoSpawned $ " ammo in " $ dt $ "s. AmmoPPPM=" $ AmmoPPPM);
            LastAmmoSpawnTime = Level.TimeSeconds;
            AmmoSpawned = 0;
            AmmoExisted = 0;
            WhatToDoNext();
        }
    }

    function WhatToDoNext()
    {
        if (AmmoSpawnCount <= 0 || CurrentAmmoCandidate == none || CurrentAmmoCandidate.IsInState('Pickup')) {
            // get back to the mision
            CurrentAmmoCandidate = none;
            GotoState('MoveToShop', 'Begin');
        }
        else {
            // spawn ammo once again
            GotoState(, 'Completing');
        }
    }
}

defaultproperties
{
    GuardianReachTime=45
    MoveAttempts=5
    TeamIndex=1
    BlameStr="%p blamed for setting the base in a glitch spot!"
    AmmoSpawnCount=1
    MaxAmmoSpawnCount=5
    AmmoPPPM=1.0
}
