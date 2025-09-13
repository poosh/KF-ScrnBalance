/**
 * Base class for all ScrN shotgun bulelts.
 * Adjusted MaxPenetrations to be really max penetration count (off-perk)
 * Added feature to make additional penetration  damage reduction when hitting specific zeds
 * v9.63.01 - Fixed a huge bug where bullets didn't penetrate at point-blank
 *
 * @author PooSH, 2012
 */
class ScrnCustomShotgunBullet extends ShotgunBullet
    abstract;

var   float MinDamage;                  // minimum damage that bullet can do. If the damage drops below this threshold,
                                        // the bullet gets destroyed.
var() float BigZedPenDmgReduction;      // Additional penetration  damage reduction after hitting big zeds. 0.5 = 50% dmg. red.
var() int   BigZedMinHealth;            // If zed's base Health >= this value, zed counts as Big
var() float MediumZedPenDmgReduction;   // Additional penetration  damage reduction after hitting medium-size zeds. 0.5 = 50% dmg. red.
var() int   MediumZedMinHealth;         // If zed's base Health >= this value, zed counts as Medium-size

var     String         StaticMeshRef;
var     String         AmbientSoundRef;

var EDetailMode DetailFilter;  // Drop detail if Level.DetailMode <= this value

var transient Pawn OldVictim;
var transient bool bHeadshot;
var transient int SameVictimCounter;

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

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    MinDamage = default.Damage * (default.PenDamageReduction ** MaxPenetrations) + 0.0001;
}

simulated function PostNetBeginPlay()
{
    if (Level.NetMode == NM_DedicatedServer || !bDynamicLight)
        return;

    if (Level.bDropDetail || Level.DetailMode <= DetailFilter) {
        bDynamicLight = false;
        LightType = LT_None;
        return;
    }
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int>    HitPoints;
    local KFPlayerReplicationInfo KFPRI;
    local KFPawn HitPawn;
    local Pawn Victim;
    local KFMonster KFM;
    local bool bNoDamageReduction;

    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
        return;

    X = Vector(Rotation);

    if ( Instigator != none && ROBulletWhipAttachment(Other) != none ) {
        // we touched player's auxilary collision cylinder, now let's trace to the player himself
        // Other.Base = KFPawn
        if( Other.Base == none || Other.Base.bDeleteMe )
            return;

        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

        if( Other == none || HitPoints.Length == 0 || Other.bDeleteMe )
            return; // bullet didn't hit a pawn

        HitPawn = KFPawn(Other);
        if ( HitPawn != none ) {
            Victim = HitPawn;
            // cannot hit a player more than once
            OldVictim = HitPawn;
            SameVictimCounter = 3;
            bNoDamageReduction = Victim.Health <= 0;
            HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);
        }
    }
    else {
        if ( ExtendedZCollision(Other) != none)
            Victim = Pawn(Other.Owner); // ExtendedZCollision is attached to KFMonster
        else if ( Pawn(Other) != none )
            Victim = Pawn(Other);

        KFM = KFMonster(Victim);

        if ( Victim != none ) {
            // kick dead bodies for visual fx but no gameplay impact
            bNoDamageReduction = Victim.Health <= 0;

            if ( OldVictim != Victim ) {
                OldVictim = Victim;
                SameVictimCounter = 1;
            }
            else if ( ++SameVictimCounter > 2 ) {
                // the same target can hit twice max
                return;
            }

            bHeadshot = Victim.IsHeadShot(HitLocation, X, 1.0);
            if ( bHeadshot ) {
                Victim.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
            }
            else {
                Victim.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
            }
        }
        else {
            Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
        }
    }

    if (bNoDamageReduction)
        return;

    if ( Instigator != none )
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none ) {
        PenDamageReduction = KFPRI.ClientVeteranSkill.static.GetShotgunPenetrationDamageMulti(KFPRI,
                default.PenDamageReduction);
    }
    else {
        PenDamageReduction = default.PenDamageReduction;
    }

    if ( Victim != none && Victim.Health <= 0 ) {
        // dead bodies reduce damage less
        PenDamageReduction += (1.0 - PenDamageReduction) * 0.5;
    }
    else if ( KFM != none ) {
        // loose penetrational damage after hitting specific zeds -- PooSH
        PenDamageReduction *= ZedPenDamageReduction(KFM);
    }

    Damage *= PenDamageReduction;
    if ( Damage < MinDamage )
        Destroy();
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
    BigZedPenDmgReduction=0.33
    BigZedMinHealth=1000
    MediumZedPenDmgReduction=0.50
    MediumZedMinHealth=500
    MaxPenetrations=3
    PenDamageReduction=0.700000
    Damage=35
    HeadShotDamageMult=1.5
    MinDamage=10
    DetailFilter=DM_Low
}
