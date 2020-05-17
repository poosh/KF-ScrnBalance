class SocIsoReplicationInfo extends ReplicationInfo;

var float VirusSpreadDist;
var transient int ProximityCounter;

replication {
    reliable if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
        VirusSpreadDist;
}

simulated function PostBeginPlay()
{
    if ( Level.NetMode == NM_DedicatedServer ) {
        return;
    }
    SetTimer(1.0, true);
}

simulated function Timer()
{
    local PlayerController PC;
    local ScrnHumanPawn P;

    PC = Level.GetLocalPlayerController();
    if ( PC == none || PC.Pawn == none || PC.Pawn.Health <= 0 )
        return;

    if ( PC.IsInState('GameEnded') ) {
        SetTimer(0, false);
        Destroy();
    }

    foreach PC.Pawn.VisibleCollidingActors( class'ScrnHumanPawn', P, VirusSpreadDist ) {
        if ( P != PC.Pawn && P.Health > 0 ) {
            PC.ReceiveLocalizedMessage(class'SocDistanceMsg', ++ProximityCounter, P.PlayerReplicationInfo);
            return;
        }
    }
    ProximityCounter = 0;
}

defaultproperties
{
    VirusSpreadDist=250  // 5m
}
