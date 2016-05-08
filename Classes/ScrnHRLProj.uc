class ScrnHRLProj extends ScrnLAWProj;

//don't blow up on minor damage
//destoy 
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
	if( damageType == class'SirenScreamDamage')
	{
		Disintegrate(HitLocation, vect(0,0,1));
	}
	else if ( !bDud && Damage >= 200 ) {
        if ( (VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))  
            Disintegrate(HitLocation, vect(0,0,1));
        else
            Explode(HitLocation, vect(0,0,0));
	}
}

defaultproperties
{
     Speed=3900.000000
     MaxSpeed=4500.000000
     Damage=625.000000
     DamageRadius=450.000000
}
