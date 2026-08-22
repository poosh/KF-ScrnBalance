class ScrnUnWeldFire extends UnWeldFire;

simulated Function Timer()
{
    local KFDoorMover door;

    super.Timer();

    if (LastHitActor != none && Level.NetMode!=NM_Client) {
        door = KFDoorMover(LastHitActor);
        if (door != none && door.WeldStrength < 40 && door.bSealed && !door.bDisallowWeld) {
            // Instantly unweld when low hp to prevent zed breaking it.
            door.MyTrigger.UnWeld(door.WeldStrength, false, Instigator);
        }
        LastHitActor.NetUpdateTime = Level.TimeSeconds - 1;
    }
}
