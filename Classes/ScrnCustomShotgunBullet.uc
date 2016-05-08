/**
 * Base class for all ScrN shotgun bulelts.
 * Adjusted MaxPenetrations to be really max penetration count (off-perk)
 * Added feature to make additional penetration  damage reduction when hitting specific zeds
 *
 * @author PooSH, 2012
 */
class ScrnCustomShotgunBullet extends ShotgunBullet
    abstract;
    
var() float BigZedPenDmgReduction;      // Additional penetration  damage reduction after hitting big zeds. 0.5 = 50% dmg. red.
var() int   BigZedMinHealth;            // If zed's base Health >= this value, zed counts as Big
var() float MediumZedPenDmgReduction;   // Additional penetration  damage reduction after hitting medium-size zeds. 0.5 = 50% dmg. red.
var() int   MediumZedMinHealth;         // If zed's base Health >= this value, zed counts as Medium-size

var     String         StaticMeshRef;
var     String         AmbientSoundRef;


static function PreloadAssets()
{
    if ( default.AmbientSoundRef != "" )
        default.AmbientSound = sound(DynamicLoadObject(default.AmbientSoundRef, class'Sound', true));

        if ( default.StaticMeshRef != "" )
        UpdateDefaultStaticMesh(StaticMesh(DynamicLoadObject(default.StaticMeshRef, class'StaticMesh', true)));
}

static function bool UnloadAssets()
{
    if ( default.AmbientSoundRef != "" )
        default.AmbientSound = none;

    if ( default.StaticMeshRef != "" )
        UpdateDefaultStaticMesh(none);

    return true;
}


simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
	local Vector TempHitLocation, HitNormal;
	local array<int>	HitPoints;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn HitPawn;
    local Pawn Victim;
    local KFMonster KFM;

	if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
		return;
    
    X = Vector(Rotation);

 	if( Instigator != none && ROBulletWhipAttachment(Other) != none ) {
        // we touched player's auxilary collision cylinder, not let's trace to the player himself
        // Other.Base = KFPawn
        if( Other.Base == none || Other.Base.bDeleteMe ) 
            return;
	    
        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

        if( Other == none || HitPoints.Length == 0 )
            return; // bullet didn't hit a pawn

		HitPawn = KFPawn(Other);

        if (Role == ROLE_Authority) {
            if ( HitPawn != none && !HitPawn.bDeleteMe ) {
                HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * Normal(Velocity), MyDamageType,HitPoints);
            }
        }
	}
    else {
        if ( ExtendedZCollision(Other) != none) 
            Victim = Pawn(Other.Owner); // ExtendedZCollision is attached to KFMonster    
        else if ( Pawn(Other) != none )
            Victim = Pawn(Other);

        KFM = KFMonster(Victim);
    
        if ( Victim != none && Victim.IsHeadShot(HitLocation, X, 1.0))
            Victim.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
        else
            Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    }

    if ( Instigator != none )
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);    
	if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
   		PenDamageReduction = KFPRI.ClientVeteranSkill.static.GetShotgunPenetrationDamageMulti(KFPRI,default.PenDamageReduction);
	else
   		PenDamageReduction = default.PenDamageReduction;
    // loose penetrational damage after hitting specific zeds -- PooSH
    if ( KFM != none)
        PenDamageReduction *= ZedPenDamageReduction(KFM);    

   	Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.
    
    // if we've struck through more than the max number of foes, destroy.
    // MaxPenetrations now really means number of max penetration off-perk -- PooSH
    if ( Damage / default.Damage < (default.PenDamageReduction ** MaxPenetrations) + 0.0001 )
        Destroy();
	else {
		speed = VSize(Velocity);
		if( Speed < (default.Speed * 0.25) )
			Destroy();
    }
}

/**
 * Further damage reduction after hitting a specific zed
 * @param   Monster                         Zed that took damage
 * @return  Further penetration  damage reduction. Doesn't affect current Monster!
 *          1.0  - no additional penetration  damage reduction
 *          0.75 - 25% additional penetration  damage reduction
 */
simulated function float ZedPenDamageReduction(KFMonster Monster)
{
    if ( Monster == none ) 
        return 1.0;
    
    if ( Monster.default.Health >= BigZedMinHealth )
        return BigZedPenDmgReduction;
    else if ( Monster.default.Health >= MediumZedMinHealth )
        return MediumZedPenDmgReduction;
    
    return 1.0;
}

defaultproperties
{
     BigZedPenDmgReduction=0.500000
     BigZedMinHealth=1000
     MediumZedPenDmgReduction=0.750000
     MediumZedMinHealth=500
     MaxPenetrations=3
     PenDamageReduction=0.700000
}
