class StinkyController extends ScriptedController;

var FtgGame FtgGame;
var byte TeamIndex; // is set by FtgGame
var StinkyClot StinkyClot;

var array<Actor> MoveTargets;

var array<KFAmmoPickup> AmmoCandidates;
var transient KFAmmoPickup CurrentAmmoCandidate;

var transient Actor LastAlternatePathTarget;
var transient NavigationPoint LastAlternatePathPoint;

var localized string BlameStr;

function PostBeginPlay()
{
    FtgGame = FtgGame(Level.Game);
    AmmoCandidates = FtgGame.AmmoPickups;
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


function Actor GetMoveTarget()
{
    local Actor result;

    if ( ActionNum < MoveTargets.length ) {
        result = MoveTargets[ActionNum];
        if ( result == LastAlternatePathTarget && LastAlternatePathPoint != none )
            result = LastAlternatePathPoint; // target unreachable -> reroute to closest nav. point
    }
    return result;
}

function NavigationPoint FindClosestPathNode(Actor anActor)
{
    local NavigationPoint N, BestN;
    local float NDistSquared, BestDistSquared;
    local bool bNVisible, bBestVisible;

    if ( anActor == none )
        return none;

    for (N = Level.NavigationPointList; N != none; N = N.nextNavigationPoint) {
        if ( !N.IsA('PathNode') )
            continue; // ignore teleporters, jumpads etc.
        NDistSquared = VSizeSquared(anActor.Location - N.Location);
        if ( NDistSquared < 250000 ) {
            // 10m or closer
            bNVisible = FastTrace(anActor.Location, N.Location);
            if ( bBestVisible && !bNVisible )
                continue; // ignore invisible points if there are visible alteratives
            else if ( BestN == none || (bNVisible && !bBestVisible) || NDistSquared < BestDistSquared ) {
                if ( FtgGame.IsPathTargetValid(N) ) {
                    BestN = N;
                    BestDistSquared = NDistSquared;
                    bBestVisible = bNVisible;
                }
            }
        }
    }
    return BestN;
}

// returns closest reachable point to a given actor
function Actor FindAlternatePath(Actor anActor)
{
    local NavigationPoint N;
    local Actor result;

    if ( LastAlternatePathTarget == anActor && LastAlternatePathPoint != none )
        N = LastAlternatePathPoint;
    else {
        N = FindClosestPathNode(anActor);
        log("Unreachable actor " $ anActor $ " @ (" $ anActor.Location $ ") -> rerouting to " $ N, class.name);
        if ( TheGuardian(anActor) != none ) {
            FtgGame.ScrnBalanceMut.BlamePlayer(ScrnPlayerController(TheGuardian(anActor).FirstTouch), BlameStr);
        }
    }
    if ( N != none ) {
        result = FindPathToward(N, false);
        if ( result != none ) {
            // cache found navigation point for next calls
            LastAlternatePathTarget = anActor;
            LastAlternatePathPoint = N;
        }
        else {
            FtgGame.InvalidatePathTarget(N, true); // make sure we don't use this navigation point anymore
            LastAlternatePathPoint = none;
        }
    }
    return result;
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
    return Pawn.default.GroundSpeed;
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

function DoAdditionalActions()
{
}

state LatentDeath
{
Begin:
    sleep(2.0);
    Pawn.Suicide();
}

state Moving extends Scripting
{
    ignores Timer;

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
        if ( !ActorReachable(MoveTarget) ) {
            MoveTarget = FindPathToward(MoveTarget,false);
            if ( MoveTarget == None ) {
                // if we can't reach the target, then move to closest NavigationPoint
                MoveTarget = FindAlternatePath(Target);
            }
            if ( MoveTarget == None ) {
                AbortScript();
                return;
            }
            if ( Focus == Target )
                Focus = MoveTarget;
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
    SetMoveTarget();
    DoAdditionalActions();
    Pawn.GroundSpeed = CalcSpeed();
    Pawn.WaterSpeed = Pawn.GroundSpeed;
    Pawn.AirSpeed = Pawn.GroundSpeed;
    StinkyClot.HiddenGroundSpeed = Pawn.GroundSpeed;
    // MayShootTarget();
    if ( MoveTarget != None && MoveTarget != Pawn ) {
        if ( StinkyClot.StuckCounter >= 25 &&
                (MoveTarget == StinkyClot.LastMoveTarget[0] || MoveTarget == StinkyClot.LastMoveTarget[1]) )
        {
            // force teleport
            if ( NextRoutePath != none && NextRoutePath.End != none ) {
                MoveTarget = NextRoutePath.End; // jump one path node forward
                // Level.GetLocalPlayerController().ClientMessage("Teleporting to next target " $ MoveTarget, 'log');
            }
            StinkyClot.TeleportLocation = MoveTarget.Location;
            StinkyClot.TeleportLocation.Z += StinkyClot.CollisionHeight;
            StinkyClot.StartTeleport();
            sleep(1.0);
            WaitForLanding();
        }
        else {
            MoveToward(MoveTarget, Focus,,,Pawn.bIsWalking);
        }

        if ( !Pawn.ReachedDestination(GetMoveTarget()) ) {
            Goto('KeepMoving');
        }

        // make sure the Stinky Clot won't teleport at this phase
        MoveTarget = none;
        StinkyClot.LastMoveTarget[0] = none;
        StinkyClot.LastMoveTarget[1] = none;
    }
    sleep( PlayCompleteAnimation() );
    CompleteAction();
}

state MoveToGuardian extends Moving
{
    function int CalcSpeed()
    {
        if ( FtgGame.bWaveBossInProgress )
            return 150;

        return min( Pawn.GroundSpeed + 3, 150 ) ; // each call move faster and faster
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

    function Actor FindAlternatePath(Actor anActor)
    {
        if ( KFAmmoPickup(anActor) != none ) {
            return none; // no alternate paths for ammo boxes -> simply go to next action
        }
        return super.FindAlternatePath(anActor);
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
                } // else ammo is already spawned
                return;
            }
        }
    }

    function int CalcSpeed()
    {
        local TSCBaseGuardian gnome;

        gnome = FtgGame.TeamBases[TeamIndex];
        if ( FtgGame.TotalMaxMonsters <=0 ) {
            if ( FtgGame.NumMonsters < 10 )
                return 150;
            else if ( gnome.SameTeamCounter + 5 < gnome.default.SameTeamCounter)
                return 35; // slowdown when nobody at the base to give team a chance to reach the base
            else
                return 100;
        }
        else if ( gnome.SameTeamCounter + 5 < gnome.default.SameTeamCounter)
            return 35; // slowdown when nobody at the base to give team a chance to reach the base
        else if ( FtgGame.TotalMaxMonsters < 50 )
            return Lerp( FtgGame.TotalMaxMonsters/50.0 , 100, 35 );
        else
            return 35;
    }

    function CompleteAction()
    {
        AmmoCandidates = FtgGame.AmmoPickups; // allow respawing ammo boxes
        global.CompleteAction();
    }
}

state MoveToAmmo extends Moving
{
    function BeginState()
    {
        super.BeginState();
        SetTimer(30, false);
    }

    function EndState()
    {
        super.EndState();
        SetTimer(0, false);
    }

    function Timer()
    {
        CurrentAmmoCandidate = none;
        GotoState('MoveToShop', 'Begin'); // abort ammo get
    }

    function Actor GetMoveTarget()
    {
        return CurrentAmmoCandidate;
    }

    function AbortScript()
    {
        // if can't reach ammo box, then just exit the state intead of aborting the entire script
        CompleteAction();
    }

    function Actor FindAlternatePath(Actor anActor)
    {
        return none;
    }

    function CompleteAction()
    {
        CurrentAmmoCandidate.GotoState('Pickup');
        CurrentAmmoCandidate = none;
        GotoState('MoveToShop', 'Begin'); // get back to the mision
    }
}

defaultproperties
{
    TeamIndex=1
    BlameStr="%p blamed for placing base in a glitch spot!"
}
