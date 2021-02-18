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

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local Vector X;

    // Don't let it hit this player, or blow up on another player
    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces )
        return;

    // Don't collide with bullet whip attachments
    if( KFBulletWhipAttachment(Other) != none )
    {
        return;
    }

    // Don't allow hits on people on the same team - except hardcore mode
    if( !class'ScrnBalance'.default.Mut.bHardcore && KFPawn(Other) != none && Instigator != none
            && KFPawn(Other).GetTeamNum() == Instigator.GetTeamNum() )
    {
        return;
    }

    X = Vector(Rotation);

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if( Instigator != none )
    {
        OrigLoc = Instigator.Location;
    }

    if( !bDud && ((VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0)) )
    {
        if( Role == ROLE_Authority )
        {
            AmbientSound=none;
            PlaySound(Sound'ProjectileSounds.PTRD_deflect04',,2.0);
            Other.TakeDamage( ImpactDamage, Instigator, HitLocation, X, ImpactDamageType );
        }

        bDud = true;
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }

    if( !bDud )
    {
       Explode(HitLocation,Normal(HitLocation-Other.Location));
    }
}


defaultproperties
{
    Damage=130.000000 // 100
    DamageRadius=200
    ImpactDamage=32 //75
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeSeekerSixRocket'
}
