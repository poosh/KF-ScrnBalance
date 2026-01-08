class ScrnWeldFire extends WeldFire;

simulated Function Timer()
{
    super.Timer();
    if (LastHitActor != none && Level.NetMode!=NM_Client) {
        LastHitActor.NetUpdateTime = Level.TimeSeconds - 1;
    }
}
