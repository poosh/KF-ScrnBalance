class ScrnS6Rocket extends SeekerSixRocketProjectile;


//don't blow up on minor damage
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if( damageType == class'SirenScreamDamage')
    {
        // disable disintegration by dead Siren scream
        if ( InstigatedBy != none && InstigatedBy.Health > 0 )
            Disintegrate(HitLocation, vect(0,0,1));
    }
    else if ( !bDud && Damage >= 10 ) {
        if ( (VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))  
            Disintegrate(HitLocation, vect(0,0,1));
        else
            Explode(HitLocation, vect(0,0,0));
    }
}


defaultproperties
{
    Damage=130.000000 // 100
    DamageRadius=200
    ImpactDamage=32 //75
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeSeekerSixRocket'
}