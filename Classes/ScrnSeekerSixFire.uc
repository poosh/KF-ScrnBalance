class ScrnSeekerSixFire extends SeekerSixFire;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    return Super(BaseProjectileFire).SpawnProjectile(Start, Dir);
}

function PostSpawnProjectile(Projectile P)
{
    local ScrnSeekerSixRocketLauncher W;
    local ScrnSeekerSixRocket R;

    super.PostSpawnProjectile(P);

    W = ScrnSeekerSixRocketLauncher(Weapon);
    R = ScrnSeekerSixRocket(P);
    if (W != none && R != none) {
        W.bBreakLock = true;

        if (W.bLockedOn && W.SeekTarget != none) {
            R.SeekTarget = W.SeekTarget;
        }
    }
}


defaultproperties
{
    AmmoClass=class'ScrnSeekerSixAmmo'
    ProjectileClass=class'ScrnSeekerSixRocket'

    bWaitForRelease=False
    //FireRate=0.330000
}
