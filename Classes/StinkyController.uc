class StinkyController extends ScriptedController;

var FtgGame FtgGame;
var byte TeamIndex; // is set by FtgGame
var StinkyClot StinkyClot;

var array<Actor> MoveTargets;

var array<KFAmmoPickup> AmmoCandidates;
var transient KFAmmoPickup CurrentAmmoCandidate;

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
    if ( ActionNum < MoveTargets.length )
        return MoveTargets[ActionNum];
    return none;
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
		local Actor NextMoveTarget;

		Focus = ScriptedFocus;
		NextMoveTarget = GetMoveTarget();
		if ( NextMoveTarget == None )
		{
            Pawn.Suicide();
			//GotoState('Broken');
			return;
		}
		if ( Focus == None )
			Focus = NextMoveTarget;
		MoveTarget = NextMoveTarget;
		if ( !ActorReachable(MoveTarget) )
		{
			MoveTarget = FindPathToward(MoveTarget,false);
			if ( Movetarget == None )
			{
				AbortScript();
				return;
			}
			if ( Focus == NextMoveTarget )
				Focus = MoveTarget;
		}
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
    // MayShootTarget();
    if ( (MoveTarget != None) && (MoveTarget != Pawn) )
    {
        MoveToward(MoveTarget, Focus,,,Pawn.bIsWalking);
        if ( !Pawn.ReachedDestination(GetMoveTarget()) )
            Goto('KeepMoving');
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
    function Actor GetMoveTarget()
    {
        if ( ActionNum < MoveTargets.length-1 && FtgGame.TotalMaxMonsters <= 0
                && FtgGame.NumMonsters <= 16 + rand(16) )
        {
            ActionNum = MoveTargets.length-1; // end of the wave -> move directly to the last target
        }
        return global.GetMoveTarget();
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
                    && VSizeSquared(Pawn.Location - ammo.Location) < 1562500 // 25m
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
        if ( FtgGame.TotalMaxMonsters <=0 ) {
            if ( FtgGame.NumMonsters < 10 )
                return 150;
            else
                return 100;
        }
        else if ( FtgGame.TotalMaxMonsters < 50 )
            return Lerp( FtgGame.TotalMaxMonsters/50.0 , 100, 35 );
        else
            return 35;
    }
}

state MoveToAmmo extends Moving
{
    function BeginState()
    {
        super.BeginState();
        SetTimer( 60, false );
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
}