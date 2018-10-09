class ScrnSingleFire extends SingleFire;

var ScrnSingle ScrnWeap; // avoid typecasting

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnSingle(Weapon);
}

event ModeDoFire()
{
    if ( !AllowFire() )
        return;

    super.ModeDoFire();

    if ( ScrnWeap.Instigator != none && ScrnWeap.Instigator.IsLocallyControlled() ) {
        // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
        // and we cannon be sure if the replication happened at this moment or not yet
        if( ScrnWeap.MagAmmoRemaining == 0 || ScrnWeap.bFiringLastRound ) {
            //lock slide back if fired last round
            ScrnWeap.LockSlideBack();
        }
        else {
            ScrnWeap.DoHammerDrop( GetFireSpeed() );
        }
    }
}

defaultproperties
{
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSingle'
}
