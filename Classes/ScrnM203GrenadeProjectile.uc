class ScrnM203GrenadeProjectile extends M203GrenadeProjectile;

var class<PanzerfaustTrail> SmokeTrailClass;

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
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
            Other.TakeDamage( ImpactDamage, Instigator, HitLocation, Normal(Velocity), ImpactDamageType );
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


//overrided to change smoke emiter
simulated function PostBeginPlay()
{
    local rotator SmokeRotation;
    BCInverse = 1 / BallisticCoefficient;
    if ( Level.NetMode != NM_DedicatedServer)
    {
        SmokeTrail = Spawn(SmokeTrailClass,self);
        SmokeTrail.SetBase(self);
        SmokeRotation.Pitch = 32768;
        SmokeTrail.SetRelativeRotation(SmokeRotation);
        //Corona = Spawn(class'KFMod.KFLAWCorona',self);
    }
    OrigLoc = Location;
    if( !bDud )
    {
        Dir = vector(Rotation);
        Velocity = speed * Dir;
    }
    if (PhysicsVolume.bWaterVolume)
    {
        bHitWater = True;
        Velocity=0.6*Velocity;
    }
    super(Projectile).PostBeginPlay();
}

defaultproperties
{
     DamageRadius=450.000000
     Damage=400
     SmokeTrailClass=Class'ScrnBalanceSrv.ReducedGrenadeTrail'
}
