class ScrnFlareProjectile extends FlareRevolverProjectile;

//overrided to use alternate burning mechanism
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    // v9.57 - flares do not explode anymore but do burn damage on impact
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal, OtherLocation;
    local array<int>    HitPoints;
    local KFPawn HitPawn;

    // Don't let it hit this player, or blow up on another player
    if ( Other == none || Other == Instigator || Other.Base == Instigator )
        return;

    // Don't collide with bullet whip attachments
    // if( KFBulletWhipAttachment(Other) != none )
    // {
    //     return;
    // }

    // Don't allow hits on poeple on the same team
    HitPawn = KFPawn(Other);
    if( HitPawn != none && Instigator != none && HitPawn.PlayerReplicationInfo != none
            && HitPawn.PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex )
        return;

    // Use the instigator's location if it exists. This fixes issues with
    // the original location of the projectile being really far away from
    // the real Origloc due to it taking a couple of milliseconds to
    // replicate the location to the client and the first replicated location has
    // already moved quite a bit.
    if( Instigator != none )
        OrigLoc = Instigator.Location;

    X = Vector(Rotation);
    OtherLocation = Other.Location;

    if ( Role == ROLE_Authority ) {
        if( ROBulletWhipAttachment(Other) != none )
        {
            if ( Other.Base.bDeleteMe )
                return; // don't collide with dead players

            Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);
            if( Other == none || HitPoints.Length == 0 )
                return;

            HitPawn = KFPawn(Other);
            if ( HitPawn != none ) {

                if( !HitPawn.bDeleteMe )
                    return;

                if( Instigator != none && HitPawn.PlayerReplicationInfo != none
                        && HitPawn.PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex )
                    return;

                HitPawn.ProcessLocationalDamage(ImpactDamage, Instigator, TempHitLocation, MomentumTransfer * Normal(Velocity), ImpactDamageType,HitPoints);
                HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, vect(0,0,0), MyDamageType, HitPoints);
            }
        }
        else {
            if ( ExtendedZCollision(Other) != none)
                Other = Other.Owner; // ExtendedZCollision is attached to and owned by a KFMonster

            if ( Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0) ) {
                // ImpactDamage *= HeadShotDamageMult;  // don't use projectile's mult. but damtype's
                Damage *= HeadShotDamageMult;
            }

            Other.TakeDamage( ImpactDamage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), ImpactDamageType );

            if ( KFMonster(Other) != none && class'ScrnBalance'.default.Mut.BurnMech != none ) {
                class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                        KFMonster(Other), Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType );
            }
            else {
                Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
            }
        }
    }

    if( !bDud )
        Explode(HitLocation,Normal(HitLocation-Other.Location));
}


defaultproperties
{
    HeadShotDamageMult=1.5  // applied only on burn damage. Impact's headshot mult. is set in damage type
    ImpactDamage=85 // 100
    Damage=30.0 // initial fire damage
    ExplosionEmitter=Class'ScrnBalanceSrv.ScrnFlareRevolverImpact'
    FlameTrailEmitterClass=Class'ScrnBalanceSrv.ScrnFlareRevolverTrail'
    ImpactDamageType=Class'ScrnBalanceSrv.ScrnDamTypeFlareProjectileImpact'
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeFlare'
    
    //reducing brightness of dynamic light by 70%
    LightBrightness=170 //255
    LightSaturation=64
    LightCone=16

    AmbientGlow=170 //254
    AmbientVolumeScale=2.5
    
}
