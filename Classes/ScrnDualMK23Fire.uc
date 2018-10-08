class ScrnDualMK23Fire extends DualMK23Fire;

var float PenDmgReduction; //penetration damage reduction. 1.0 - no reduction, 0 - no penetration, 0.75 - 25% reduction
var byte  MaxPenetrations; //how many enemies can penetrate a single bullet

//lock slide back if fired last round
simulated function bool AllowFire()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if( (Level.TimeSeconds - LastFireTime > FireRate) && KFWeapon(Weapon).MagAmmoRemaining <= 2 && !KFWeapon(Weapon).bIsReloading )
        {
            if (KFWeapon(Weapon).MagAmmoRemaining == 2)
            {
                ScrnDualMK23Pistol(Weapon).LockLeftSlideBack();
                ScrnDualMK23Pistol(Weapon).bTweenLeftSlide = true;
            }
            else if (KFWeapon(Weapon).MagAmmoRemaining <= 1)
            {
                ScrnDualMK23Pistol(Weapon).LockLeftSlideBack();
                ScrnDualMK23Pistol(Weapon).LockRightSlideBack();
                ScrnDualMK23Pistol(Weapon).bTweenLeftSlide = true;
                ScrnDualMK23Pistol(Weapon).bTweenRightSlide = true;
            }
        }
    }
	return Super.AllowFire();
}

//called after reload and on zoom toggle, sets next pistol to fire to sync with slide lock order
function SetPistolFireOrder()
{
    //this gets toggled before firing, amazingly
    if (ScrnDualMK23Pistol(Weapon).MagAmmoRemaining%2 == 0)
    {
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    else
    {
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
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
}

/*
simulated function float GetSpread()
{
    local float AccuracyMod;

    AccuracyMod = 1.0;

    // Spread bonus while using laser sights
    if ( ScrnDualMK23Laser(Weapon) != none && ScrnDualMK23Laser(Weapon).bLaserActive) 
        AccuracyMod = 0.5;
    
    return AccuracyMod * super.GetSpread();
}
*/

// Remove left gun's aiming bug  (c) PooSH
// Thanks to n87, Benjamin
function DoFireEffect()
{
    super(KFFire).DoFireEffect();
}

defaultproperties
{
     PenDmgReduction=0.500000
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeDualMK23Pistol'
}
