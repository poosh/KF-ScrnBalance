class ScrnHighROFFire extends KFHighROFFire;

var transient float FireRateReminder;


event ModeDoFire()
{
    if (bWaitForRelease) {
        super(KFFire).ModeDoFire();
    }
    // else must be in FireLoop state
}

state FireLoop
{
    function EndState()
    {
        super.EndState();
        FireRateReminder = 0;
    }

    event ModeDoFire()
    {
        if ( Level.TimeSeconds - LastFireTime > 0.1 )
            FireRateReminder = 0;
        else
            FireRateReminder += fmax(Level.TimeSeconds - FireRate - LastFireTime, 0.f); // do precise fire rate

        super(KFFire).ModeDoFire();

        if ( FireRateReminder > 0 ) {
            NextFireTime -= FireRateReminder;
            if ( NextFireTime < Level.TimeSeconds ) {
                FireRateReminder = Level.TimeSeconds - NextFireTime;
                NextFireTime = Level.TimeSeconds;
            }
        }
    }
}
