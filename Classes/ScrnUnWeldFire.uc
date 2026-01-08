class ScrnUnWeldFire extends UnWeldFire;

simulated Function Timer()
{
    super.Timer();
    if (LastHitActor != none && Level.NetMode!=NM_Client) {
        LastHitActor.NetUpdateTime = Level.TimeSeconds - 1;
    }
}
