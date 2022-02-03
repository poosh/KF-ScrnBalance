class ToiletPaperFire extends FragFire;

function class<Projectile> GetDesiredProjectileClass()
{
    return ProjectileClass;
}

state LoadNext
{
    function BeginState()
    {
        // do not play weapon reload sound
    }
}

defaultproperties
{
    AmmoClass=class'ToiletPaperAmmo'
    ProjectileClass=class'ToiletPaperProj'
}
