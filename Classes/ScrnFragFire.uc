class ScrnFragFire extends FragFire;

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Grenade gProj;
    local ScrnFrag aFrag;

    gProj = Grenade(super.SpawnProjectile(Start, Dir));
    aFrag = ScrnFrag(Weapon);
    if ( aFrag != none && aFrag.bThrowingCooked ) {
        gProj.ExplodeTimer = fclamp(aFrag.CookExplodeTimer - Level.TimeSeconds, 0.01, Class'ScrnBalanceSrv.ScrnNade'.default.ExplodeTimer);
        gProj.SetTimer(gProj.ExplodeTimer, false);
        gProj.bTimerSet = true; //don't reset the time if hit the wall
        if ( ScrnNade(gProj) != none )
            ScrnNade(gProj).bBlewInHands = aFrag.bBlewInHands;

        aFrag.bCooking = false;
        aFrag.bThrowingCooked = false;
        aFrag.bBlewInHands = false;
    }
    return gProj;
}

function DoFireEffect()
{
    super.DoFireEffect();
}

defaultproperties
{
     ProjectileClass=Class'ScrnBalanceSrv.ScrnNade'
}
