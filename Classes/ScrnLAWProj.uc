class ScrnLAWProj extends LAWProj;

var class<Emitter> ExplosionClass;

//don't blow up on minor damage
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if( damageType == class'SirenScreamDamage')
    {
        // disable disintegration by dead Siren scream
        if ( InstigatedBy != none && InstigatedBy.Health > 0 )
            Disintegrate(HitLocation, vect(0,0,1));
    }
    else if ( !bDud && Damage >= 200 ) {
        if ( (VSizeSquared(Location - OrigLoc) < ArmDistSquared) || OrigLoc == vect(0,0,0))
            Disintegrate(HitLocation, vect(0,0,1));
        else
            Explode(HitLocation, vect(0,0,0));
    }
}

// overrided to add ExplosionClass
simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController  LocalPlayer;

    bHasExploded = True;

    // Don't explode if this is a dud
    if( bDud )
    {
        Velocity = vect(0,0,0);
        LifeSpan=1.0;
        SetPhysics(PHYS_Falling);
    }


    PlaySound(ExplosionSound,,2.0);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(ExplosionClass,,,HitLocation + HitNormal*20,rotator(HitNormal));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    BlowUp(HitLocation);
    Destroy();

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
}

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

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dirs;
    local int NumKilled;
    local KFMonster KFMonsterVictim;
    local Pawn P;
    local KFPawn KFP;
    local array<Pawn> CheckedPawns;
    local int i;
    local bool bAlreadyChecked;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;

    foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        KFMonsterVictim = none;
        KFP = none;

        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
         && ExtendedZCollision(Victims)==None )
        {
            dirs = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dirs));
            dirs = dirs/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;

            P = Pawn(Victims);

            if( P != none )
            {
                for (i = 0; i < CheckedPawns.Length; i++)
                {
                    if (CheckedPawns[i] == P)
                    {
                        bAlreadyChecked = true;
                        break;
                    }
                }

                if( bAlreadyChecked )
                {
                    bAlreadyChecked = false;
                    P = none;
                    continue;
                }

                KFMonsterVictim = KFMonster(Victims);

                if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
                {
                    KFMonsterVictim = none;
                }

                KFP = KFPawn(Victims);

                if( KFMonsterVictim != none )
                {
                    damageScale *= KFMonsterVictim.GetExposureTo(HitLocation/*Location + 15 * -Normal(PhysicsVolume.Gravity)*/);
                }
                else if( KFP != none )
                {
                    damageScale *= KFP.GetExposureTo(HitLocation/*Location + 15 * -Normal(PhysicsVolume.Gravity)*/);
                }

                CheckedPawns[CheckedPawns.Length] = P;

                if ( damageScale <= 0)
                {
                    P = none;
                    continue;
                }
                else
                {
                    //Victims = P;
                    P = none;
                }
            }

            if ( ExtendedZCollision(Victims) != none )
                KFMonsterVictim = KFMonster(Victims.Owner);

            if ( KFMonsterVictim != none ) {
                damageScale *= ScaleMonsterDamage(KFMonsterVictim);
            }

            Victims.TakeDamage
            (
                damageScale * DamageAmount,
                Instigator,
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
                (damageScale * Momentum * dirs),
                DamageType
            );

            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

            if( Role == ROLE_Authority && KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
            {
                NumKilled++;
            }
        }
    }
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
    {
        Victims = LastTouched;
        LastTouched = None;
        dirs = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dirs));
        dirs = dirs/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
        if ( Instigator == None || Instigator.Controller == None )
            Victims.SetDelayedDamageInstigatorController(InstigatorController);

        if ( ExtendedZCollision(Victims) != none )
            KFMonsterVictim = KFMonster(Victims.Owner);
        else
            KFMonsterVictim = KFMonster(Victims);
            
        if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 ) {
            KFMonsterVictim = none;
        }
        else if ( KFMonsterVictim != none ) {
            damageScale *= ScaleMonsterDamage(KFMonsterVictim);
        }

        Victims.TakeDamage
        (
            damageScale * DamageAmount,
            Instigator,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
            (damageScale * Momentum * dirs),
            DamageType
        );
        if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        if( Role == ROLE_Authority && KFMonsterVictim != none && KFMonsterVictim.Health <= 0 ) {
            NumKilled++;
        }
    }

    if( Role == ROLE_Authority )
    {
        if( NumKilled >= 10 )
            KFGameType(Level.Game).DramaticEvent(0.20);
        else if( NumKilled >= 4 )
            KFGameType(Level.Game).DramaticEvent(0.05);
        else if( NumKilled >= 2 )
            KFGameType(Level.Game).DramaticEvent(0.03);
    }

    bHurtEntry = false;
}

function float ScaleMonsterDamage(KFMonster Victim)
{
    return 1.0;
}


defaultproperties
{
     ExplosionClass=Class'ScrnBalanceSrv.ScrnLawExplosion'
     Damage=1000.000000
     ImpactDamage=350
     //adds light to projectile
     LightType=LT_Steady
     LightBrightness=128.0 //128
     LightRadius=6.000000 //4.0
     LightHue=25
     LightSaturation=100
     LightCone=16
     bDynamicLight=True
}
