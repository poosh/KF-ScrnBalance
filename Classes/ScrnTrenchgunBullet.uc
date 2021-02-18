class ScrnTrenchgunBullet extends TrenchgunBullet;

//copy-pasted from ScrnCustomShotgunBullet
var() float BigZedPenDmgReduction;      // Additional penetration  damage reduction after hitting big zeds. 0.5 = 50% dmg. red.
var() int   BigZedMinHealth;            // If zed's base Health >= this value, zed counts as Big
var() float MediumZedPenDmgReduction;   // Additional penetration  damage reduction after hitting medium-size zeds. 0.5 = 50% dmg. red.
var() int   MediumZedMinHealth;         // If zed's base Health >= this value, zed counts as Medium-size

var   float MinDamage;                  // minimum damage that bullet can do. If the damage drops below this threshold,
                                        // the bullet gets destroyed.


simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    MinDamage = default.Damage * (default.PenDamageReduction ** MaxPenetrations) + 0.0001;
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
    local int HSDamage; //damage, including headshot mult

    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
        return;

    X = Vector(Rotation);

    if ( Instigator != none && ROBulletWhipAttachment(Other) != none ) {
        // we touched player's auxilary collision cylinder, not let's trace to the player himself
        // Other.Base = KFPawn
        if( Other.Base == none || Other.Base.bDeleteMe )
            return;

        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

        if( Other == none || HitPoints.Length == 0 || Other.bDeleteMe )
            return; // bullet didn't hit a pawn

        HitPawn = KFPawn(Other);
        if ( HitPawn != none ) {
            Victim = HitPawn;
            HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);
        }
    }
    else {
        if ( ExtendedZCollision(Other) != none)
            Victim = Pawn(Other.Owner); // ExtendedZCollision is attached to KFMonster
        else if ( Pawn(Other) != none )
            Victim = Pawn(Other);

        KFM = KFMonster(Victim);

        HSDamage = Damage;
        if (Victim != none && !(HeadShotDamageMult ~= 1.0) && Victim.IsHeadShot(HitLocation, X, 1.0))
            HSDamage *= HeadShotDamageMult;

        if ( KFM != none && KFM.Health > 0 && class'ScrnBalance'.default.Mut.BurnMech != none)
            class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                KFM, HSDamage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
        else
            Other.TakeDamage(HSDamage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
    }

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
     BigZedPenDmgReduction=0.0
     BigZedMinHealth=1000
     MediumZedPenDmgReduction=0.750000
     MediumZedMinHealth=500
     PenDamageReduction=0.700000
     HeadShotDamageMult=1.000000
     Damage=12.000000
     MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeTrenchgun'
}
