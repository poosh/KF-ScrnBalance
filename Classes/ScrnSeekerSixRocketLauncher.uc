class ScrnSeekerSixRocketLauncher extends SeekerSixRocketLauncher;

var int MultiFireLoad;

simulated function WeaponTick(float dt)
{
    super(KFWeapon).WeaponTick(dt);

    if ( Level.NetMode!=NM_DedicatedServer)
    {
        if ( MagAmmoRemaining == 0 )
            Skins[2] = Counter0;
        else {
            switch ( ceil(float(MagAmmoRemaining) / MultiFireLoad) ) {
                case 1:     Skins[2] = Counter1; break;
                case 2:     Skins[2] = Counter2; break;
                case 3:     Skins[2] = Counter3; break;
                case 4:     Skins[2] = Counter4; break;
                case 5:     Skins[2] = Counter5; break;
                default:     Skins[2] = Counter6; break;
            }
        }

        // Swap the site reticle if you are locked on
        if( bOldLockedOn != bLockedOn )
        {
            bOldLockedOn = bLockedOn;
            if( bLockedOn )
            {
                Skins[1] = SiteReticleLocked;
            }
            else
            {
                Skins[1] = SiteReticle;
            }
        }
     }
}

// deprecated
function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    return Spawn(class'ScrnSeekerSixRocket',,, Start, Dir);
}

// can lock on only when aiming
function bool CanLockOnTo(Actor Other)
{
    if ( !bAimingRifle )
        return false;

    return super.CanLockOnTo(Other);
}

simulated function ZoomOut(bool bAnimateTransition)
{
    super.ZoomOut(bAnimateTransition);
    bBreakLock = true;
}

function Tick(float dt)
{
    if (!bAimingRifle) {
        bBreakLock = true;
    }

    if (bBreakLock) {
        bBreakLock = false;
        bLockedOn = false;
        SeekTarget = none;
        SeekCheckTime = Level.TimeSeconds + SeekCheckFreq;
        return;
    }

    super.Tick(dt);
}

defaultproperties
{
    PickupClass=class'ScrnSeekerSixPickup'
    FireModeClass(0)=class'ScrnSeekerSixFire'
    FireModeClass(1)=class'ScrnSeekerSixMultiFire'

    MultiFireLoad=6
    MagCapacity=24 // 6
    ReloadRate=3.9125 // 3.13
    ReloadAnim="Reload"
    ReloadAnimRate=0.8 // 3.13 / 3.9125

    ItemName="SeekerSix Rocket Launcher SE"
}