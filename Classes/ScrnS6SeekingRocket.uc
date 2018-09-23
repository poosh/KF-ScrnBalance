class ScrnS6SeekingRocket extends SeekerSixSeekingRocketProjectile;

//copypasta from SeekerSixSeekingRocketProjectile and added lock on to head
simulated function Timer()
{
    local vector ForceDir;
    local float VelMag;
    local vector LocalSeekingLocation;

    if ( InitialDir == vect(0,0,0) )
        InitialDir = Normal(Velocity);

    Acceleration = vect(0,0,0);
    Super.Timer();
    if ( (Seeking != None) && (Seeking != Instigator) )
    {
        //if target has a headbone use those coords, otherwise lock onto position
        if (Pawn(Seeking).HeadBone != '')
        LocalSeekingLocation = Seeking.GetBoneCoords(Pawn(Seeking).HeadBone).origin; //get HeadBone name and location
        else
        LocalSeekingLocation = Seeking.Location; //get Actor's location
        // Do normal guidance to target.
        ForceDir = Normal(LocalSeekingLocation - Location);

        if( (ForceDir Dot InitialDir) > 0 )
        {
            VelMag = VSize(Velocity);
            // Increase the multiplier that is currently 0.8 to make the rocket track better if you need to
            ForceDir = Normal(ForceDir * 0.8 * VelMag + Velocity);
            Velocity =  VelMag * ForceDir;
            Acceleration += 5 * ForceDir;
        }
        // Update rocket so it faces in the direction its going.
        SetRotation(rotator(Velocity));
    }
}


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
    Damage=130.000000
    DamageRadius=200.000000
    ImpactDamage=32 //75
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeSeekerSixRocket'
}
