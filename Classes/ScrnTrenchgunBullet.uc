class ScrnTrenchgunBullet extends TrenchgunBullet;

//copy-pasted from ScrnCustomShotgunBullet
var() float BigZedPenDmgReduction;      // Additional penetration  damage reduction after hitting big zeds. 0.5 = 50% dmg. red.
var() int   BigZedMinHealth;            // If zed's base Health >= this value, zed counts as Big
var() float MediumZedPenDmgReduction;   // Additional penetration  damage reduction after hitting medium-size zeds. 0.5 = 50% dmg. red.
var() int   MediumZedMinHealth;         // If zed's base Health >= this value, zed counts as Medium-size

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local KFPlayerReplicationInfo KFPRI;
    local KFMonster KFMonsterVictim;
    local int HSDamage; //damage, including headshot mult

    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces  )
        return;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    X = Vector(Rotation);

    if( ROBulletWhipAttachment(Other) != none )
    {
        if(!Other.Base.bDeleteMe)
        {
            Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (200 * X), HitPoints, HitLocation,, 1);

            if( Other == none || HitPoints.Length == 0 )
                return;

            HitPawn = KFPawn(Other);

            if (Role == ROLE_Authority)
            {
                if ( HitPawn != none )
                {
                     // Hit detection debugging
                    /*log("Bullet hit "$HitPawn.PlayerReplicationInfo.PlayerName);
                    HitPawn.HitStart = HitLocation;
                    HitPawn.HitEnd = HitLocation + (65535 * X);*/

                    if( !HitPawn.bDeleteMe )
                        HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * Normal(Velocity), MyDamageType,HitPoints);


                    // Hit detection debugging
                    //if( Level.NetMode == NM_Standalone)
                    //    HitPawn.DrawBoneLocation();
                }
            }
        }
    }
    else
    {
        if ( ExtendedZCollision(Other) != none)
            Other = Other.Owner; // ExtendedZCollision is attached to and owned by a KFMonster
        KFMonsterVictim = KFMonster(Other);

        HSDamage = Damage;
        if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
            HSDamage *= HeadShotDamageMult;

        if ( KFMonsterVictim != none && KFMonsterVictim.Health > 0 && class'ScrnBalance'.default.Mut.BurnMech != none)
            class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                KFMonsterVictim, HSDamage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
        else
           Other.TakeDamage(HSDamage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);

    }

    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
    {
           PenDamageReduction = KFPRI.ClientVeteranSkill.static.GetShotgunPenetrationDamageMulti(KFPRI,default.PenDamageReduction);
    }
    else
    {
           PenDamageReduction = default.PenDamageReduction;
       }
    // loose penetrational damage after hitting specific zeds -- PooSH
    if (KFMonsterVictim != none)
        PenDamageReduction *= ZedPenDamageReduction(KFMonsterVictim);

       Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.

    // if we've struck through more than the max number of foes, destroy.
    // MaxPenetrations now really means number of max penetration off-perk -- PooSH
    if ( Damage / default.Damage < (default.PenDamageReduction ** MaxPenetrations) + 0.0001 )
    {
        Destroy();
    }

    speed = VSize(Velocity);

    if( Speed < (default.Speed * 0.25) )
    {
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
     BigZedMinHealth=1000
     MediumZedPenDmgReduction=0.750000
     MediumZedMinHealth=500
     PenDamageReduction=0.700000
     HeadShotDamageMult=1.000000
     Damage=12.000000
     MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeTrenchgun'
}
