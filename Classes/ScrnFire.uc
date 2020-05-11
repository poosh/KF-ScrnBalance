class ScrnFire extends KFFire;

var float PenDmgReduction; //penetration damage reduction. 1.0 - no reduction, 0.25 - 25% reduction
var byte  MaxPenetrations; //how many enemies can penetrate a single bullet
var protected int KillCountPerTrace;

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local byte HitCount, PenCounter;
    local float HitDamage, HitMomentum;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local array<Actor>    IgnoreActors;
    local Pawn DamagePawn;
    local int i;

    local KFMonster Monster;
    local bool bWasDecapitated;

    KillCountPerTrace = 0;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() ) {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
        Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    HitDamage = DamageMax;
    HitMomentum = Momentum;

    // HitCount isn't a number of max penetration. It is just to be sure we won't stuck in infinite loop
    while( ++HitCount < 127 && HitDamage >= 1.0 )
    {
        DamagePawn = none;
        Monster = none;

        Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
        if( Other==None ) {
            break;
        }
        else if( Other==Instigator || Other.Base == Instigator ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
            Start = HitLocation;
            continue;
        }

        if( ExtendedZCollision(Other)!=None && Other.Owner!=None ) {
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
            Other.SetCollision(false);
            Other.Owner.SetCollision(false);
            DamagePawn = Pawn(Other.Owner);
            Monster = KFMonster(Other.Owner);
        }

        if ( !Other.bWorldGeometry && Other!=Level ) {
            HitPawn = KFPawn(Other);

            if ( HitPawn != none )
            {
                 if(!HitPawn.bDeleteMe) {
                     HitPawn.ProcessLocationalDamage(int(HitDamage), Instigator, HitLocation, HitMomentum*X,DamageType,
                            HitPoints);
                 }
                IgnoreActors[IgnoreActors.Length] = Other;
                IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
                Other.SetCollision(false);
                HitPawn.AuxCollisionCylinder.SetCollision(false);
                DamagePawn = HitPawn;
            }
            else {
                if( DamagePawn == none )
                    DamagePawn = Pawn(Other);

                if( KFMonster(Other)!=None ) {
                    IgnoreActors[IgnoreActors.Length] = Other;
                    Other.SetCollision(false);
                    Monster = KFMonster(Other);
                }
                bWasDecapitated = Monster != none && Monster.bDecapitated;
                Other.TakeDamage(int(HitDamage), Instigator, HitLocation, HitMomentum*X, DamageType);
                if ( DamagePawn != none && (DamagePawn.Health <= 0
                        || (Monster != none && !bWasDecapitated && Monster.bDecapitated)) )
                {
                    ++KillCountPerTrace;
                }
            }

            if( ++PenCounter > MaxPenetrations || DamagePawn==None )
                break;

            HitDamage *= PenDmgReduction;
            HitMomentum *= PenDmgReduction;
            Start = HitLocation;
        }
        else if ( HitScanBlockingVolume(Other)==None )
        {
            if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
              KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
            break;
        }
    }

    // Turn the collision back on for any actors we turned it off
    if ( IgnoreActors.Length > 0 )
    {
        for (i=0; i<IgnoreActors.Length; i++)
        {
            if ( IgnoreActors[i] != none )
                IgnoreActors[i].SetCollision(true);
        }
    }
}

defaultproperties
{
     PenDmgReduction=0.500000
     MaxPenetrations=0
}
