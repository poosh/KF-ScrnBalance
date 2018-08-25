class ScrnHuskGunProjectile extends HuskGunProjectile;

var bool bAppliedCharge;

//overrided to use alternate burning mechanism
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dirs;
    local int NumKilled;
    local Pawn P;
    local KFMonster KFMonsterVictim;
    local KFPawn KFP;
    local array<Pawn> CheckedPawns;
    local int i;
    local bool bAlreadyChecked;

    //local int OldHealth;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;

    foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation) {
        // null pawn variables here just to be sure they didn't left from previous iteration
        // and waste another day of my life to looking for this fucking bug -- PooSH /totallyPissedOff!!!
        P = none;
        KFMonsterVictim = none;
        KFP = none;

        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Victims != Instigator) &&(Hurtwall != Victims)
                && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
                && ExtendedZCollision(Victims)==None && KFBulletWhipAttachment(Victims)==None )
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

            if( P != none ) {
                for (i = 0; i < CheckedPawns.Length; i++) {
                    if (CheckedPawns[i] == P) {
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

                if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 ) {
                    KFMonsterVictim = none;
                }

                KFMonsterVictim = KFMonster(Victims);
                KFP = KFPawn(Victims);

                if( KFMonsterVictim != none )
                    damageScale *= KFMonsterVictim.GetExposureTo(HitLocation);
                else if( KFP != none )
                    damageScale *= KFP.GetExposureTo(HitLocation);

                CheckedPawns[CheckedPawns.Length] = P;

                if ( damageScale <= 0)
                    continue;
            }


            if ( KFMonsterVictim != none && class'ScrnBalance'.default.Mut.BurnMech != none) {
                class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                    KFMonsterVictim,
                    damageScale * DamageAmount,
                    Instigator,
                    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
                    (damageScale * Momentum * dirs),
                    DamageType
                );
            }
            else {
                Victims.TakeDamage
                (
                    damageScale * DamageAmount,
                    Instigator,
                    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
                    (damageScale * Momentum * dirs),
                    DamageType
                );
            }

            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

            if( Role == ROLE_Authority && KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
            {
                NumKilled++;
            }
        }
    }

    if( Role == ROLE_Authority )
    {
        if( NumKilled >= 4 )
        {
            KFGameType(Level.Game).DramaticEvent(0.05);
        }
        else if( NumKilled >= 2 )
        {
            KFGameType(Level.Game).DramaticEvent(0.03);
        }
    }

    bHurtEntry = false;
}

// in case when the projectile touched a victim on spawn and WeaponFire haven't applied charge yet
function CheckCharge()
{
    local ScrnHuskGunFire FireMode;

    if ( bAppliedCharge )
        return;

    if ( Instigator != none && Instigator.Weapon != none )
        FireMode = ScrnHuskGunFire( Instigator.Weapon.GetFireMode(0) );
    if ( FireMode != none )
        FireMode.ApplyCharge(self);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal, OtherLocation;
    local array<int>    HitPoints;
    local KFPawn HitPawn;

    // Don't let it hit this player, or blow up on another player
    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces )
        return;

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if( Instigator != none ) {
        OrigLoc = Instigator.Location;
    }

    X = Vector(Rotation);
    OtherLocation = Other.Location;

     if( Instigator != none && ROBulletWhipAttachment(Other) != none ) {
        // we touched player's auxilary collision cylinder, not let's trace to the player himself
        // Other.Base = KFPawn
        if( Other.Base == none || Other.Base.bDeleteMe )
            return;

        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

        if( Other == none || HitPoints.Length == 0 || Other.bDeleteMe )
            return; // bullet didn't hit a pawn

        HitPawn = KFPawn(Other);
        if ( HitPawn != none ) {
            // Don't allow hits on people on the same team - except hardcore mode
            if ( !class'ScrnBalance'.default.Mut.bHardcore && HitPawn.GetTeamNum() == Instigator.GetTeamNum() )
                return;
            CheckCharge();
            HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * Normal(Velocity), MyDamageType,HitPoints);
        }
    }
    else {
        CheckCharge();
        Other.TakeDamage(ImpactDamage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), ImpactDamageType);
    }

    if( !bDud ) {
        Explode(HitLocation,Normal(HitLocation-OtherLocation));
    }
}

defaultproperties
{
    ImpactDamage=65
    ImpactDamageType=Class'ScrnBalanceSrv.ScrnDamTypeHuskGunProjectileImpact'

    Damage=30.000000
    DamageRadius=150.000000
    HeadShotDamageMult=1.0 // not used
}
