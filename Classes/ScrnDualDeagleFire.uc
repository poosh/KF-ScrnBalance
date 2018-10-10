class ScrnDualDeagleFire extends DualDeagleFire;

var ScrnDualDeagle ScrnWeap; // avoid typecasting

var float PenDmgReduction; //penetration damage reduction. 1.0 - no reduction, 25% reduction
var byte  MaxPenetrations; //how many enemies can penetrate a single bullet
var bool  bCheck4Ach;

var protected bool bFireLeft;


function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualDeagle(Weapon);
}

//called after reload and on zoom toggle, sets next pistol to fire to sync with slide lock order
function SetPistolFireOrder(bool bNextFireLeft)
{
    bFireLeft = bNextFireLeft;

    if (bFireLeft)
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.FlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.altFlashBoneName;
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    else
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.altFlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.FlashBoneName;
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
    }
}

function bool GetPistolFireOrder()
{
    return bFireLeft;
}

event ModeDoFire()
{
    if ( !AllowFire() )
        return;

    super(KFFire).ModeDoFire();

    InitEffects();
    SetPistolFireOrder(!bFireLeft);
}

function PlayFiring()
{
    local int MagAmmoRemainingAfterShot;

    super.PlayFiring();

    // The problem is that we MagAmmoRemaining is changed by ConsumeAmmo() on server-side only
    // and we cannon be sure if the replication happened at this moment or not yet
    // FiringRound stores MagAmmoRemaining on client before the fire.
    // If FiringRound == MagAmmoRemaining, then property is not replicated yet.
    // If FiringRound - 1 == MagAmmoRemaining, then property is already replicated.
    if ( ScrnWeap.FiringRound <= ScrnWeap.MagAmmoRemaining ) {
        MagAmmoRemainingAfterShot = ScrnWeap.FiringRound - 1;
    }
    else {
        MagAmmoRemainingAfterShot = ScrnWeap.MagAmmoRemaining;
    }

    if( MagAmmoRemainingAfterShot == 0 ) {
        ScrnWeap.LockLeftSlideBack();
        ScrnWeap.LockRightSlideBack();
    }
    else if ( MagAmmoRemainingAfterShot == 1 ) {
        ScrnWeap.LockRightSlideBack();
        ScrnWeap.bTweenLeftSlide = true;
    }
    else if ( bFireLeft ) {
        ScrnWeap.DoLeftHammerDrop( GetFireSpeed() );
        ScrnWeap.AddExtraLeftSlideMovement( GetFireSpeed() );
    }
    else {
        ScrnWeap.DoRightHammerDrop( GetFireSpeed() );
        ScrnWeap.AddExtraRightSlideMovement( GetFireSpeed() );
    }
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local byte HitCount, PenCounter, KillCount;
    local float HitDamage;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local array<Actor>    IgnoreActors;
    local Pawn DamagePawn;
    local int i;

    local KFMonster Monster;
    local bool bWasDecapitated;
    //local int OldHealth;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() )
    {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else
    {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
         Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    HitDamage = DamageMax;

    // HitCount isn't a number of max penetration. It is just to be sure we won't stuck in infinite loop
    While( ++HitCount < 127 )
    {
        DamagePawn = none;
        Monster = none;

        Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
        if( Other==None )
        {
            Break;
        }
        else if( Other==Instigator || Other.Base == Instigator )
        {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
            Start = HitLocation;
            Continue;
        }

        if( ExtendedZCollision(Other)!=None && Other.Owner!=None )
        {
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
            Other.SetCollision(false);
            Other.Owner.SetCollision(false);
            DamagePawn = Pawn(Other.Owner);
            Monster = KFMonster(Other.Owner);
        }

        if ( !Other.bWorldGeometry && Other!=Level )
        {
            HitPawn = KFPawn(Other);

            if ( HitPawn != none )
            {
                 // Hit detection debugging
                 /*log("PreLaunchTrace hit "$HitPawn.PlayerReplicationInfo.PlayerName);
                 HitPawn.HitStart = Start;
                 HitPawn.HitEnd = End;*/
                 if(!HitPawn.bDeleteMe)
                     HitPawn.ProcessLocationalDamage(int(HitDamage), Instigator, HitLocation, Momentum*X,DamageType,HitPoints);

                 // Hit detection debugging
                 /*if( Level.NetMode == NM_Standalone)
                       HitPawn.DrawBoneLocation();*/

                IgnoreActors[IgnoreActors.Length] = Other;
                IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
                Other.SetCollision(false);
                HitPawn.AuxCollisionCylinder.SetCollision(false);
                DamagePawn = HitPawn;
            }
            else
            {
                if( DamagePawn == none )
                    DamagePawn = Pawn(Other);

                if( KFMonster(Other)!=None )
                {
                    IgnoreActors[IgnoreActors.Length] = Other;
                    Other.SetCollision(false);
                    Monster = KFMonster(Other);
                    //OldHealth = KFMonster(Other).Health;
                }
                bWasDecapitated = Monster != none && Monster.bDecapitated;
                Other.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
                if ( DamagePawn != none && (DamagePawn.Health <= 0 || (Monster != none
                        && !bWasDecapitated && Monster.bDecapitated)) )
                {
                    KillCount++;
                }

                // debug info
                // if ( KFMonster(Other) != none )
                    // log(String(class) $ ": Damage("$PenCounter$") = "
                        // $ int(HitDamage) $"/"$ (OldHealth-KFMonster(Other).Health)
                        // @ KFMonster(Other).MenuName , 'ScrnBalance');
            }
            if( ++PenCounter > MaxPenetrations || DamagePawn==None )
            {
                Break;
            }
            HitDamage *= PenDmgReduction;
            Start = HitLocation;
        }
        else if ( HitScanBlockingVolume(Other)==None )
        {
            if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
              KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
            Break;
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

    if ( Weapon.Role == Role_Authority && bCheck4Ach && KillCount >= 4 && Weapon.Instigator.PlayerReplicationInfo != none
            && SRStatsBase(Weapon.Instigator.PlayerReplicationInfo.SteamStatsAndAchievements) != none ) {
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(SRStatsBase(Weapon.Instigator.PlayerReplicationInfo.SteamStatsAndAchievements).Rep, 'HC4Kills', 1);
        bCheck4Ach = false;
    }

}

defaultproperties
{
     PenDmgReduction=0.650000
     MaxPenetrations=4
     bCheck4Ach=True
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeDualDeagle'
}
