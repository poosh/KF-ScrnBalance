class ScrnHuskGunProjectile_Alt extends ScrnHuskGunProjectile_Strong;

//can't be destroyed by Siren's scream
//Explode only by heavy explosive damage
function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if ( !bDud && !bHasExploded && Damage >= 100 && class<KFWeaponDamageType>(damageType) != none 
            && class<KFWeaponDamageType>(damageType).default.bIsExplosive ) {
        Explode(HitLocation, vect(0,0,0));
	}
}

/*
simulated function float MosterDamageMult( KFMonster Victim )
{
    float mult;
    mult = super.MosterDamageMult();
    // prevent big monsters from 1-shot be killed by hitting all projectiles
    if ( KFMonsterVictim.bBurnified && KFMonsterVictim.default.Health >= 1000 )
        mult *= 0.5;
    return mult;
}
*/

// copy-pasted with deletion of impact damage
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	// Don't let it hit this player, or blow up on another player
	if ( Other == none || Other == Instigator || Other.Base == Instigator )
		return;

    // Don't collide with bullet whip attachments
    if( ROBulletWhipAttachment(Other) != none )
    {
        return;
    }

	/*
    // Don't allow hits on people on the same team
    if( KFHumanPawn(Other) != none && Instigator != none
        && KFHumanPawn(Other).PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex )
    {
        return;
    }
	*/

	if( !bDud && !bHasExploded )
	{
	   Explode(HitLocation,Normal(HitLocation-Other.Location));
	}
}

defaultproperties
{
     HeadShotDamageMult=1.000000
     ExplosionSoundVolume=1.000000
     ImpactDamageType=Class'ScrnBalanceSrv.ScrnDamTypeHuskGun_Alt'
     ImpactDamage=0
     AmbientVolumeScale=1.000000
     Speed=750.000000
     MaxSpeed=1000.000000
     Damage=50.000000
     DamageRadius=500.000000
     MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeHuskGun_Alt'
     LifeSpan=5.000000
}
