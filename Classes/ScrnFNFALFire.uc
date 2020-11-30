class ScrnFNFALFire extends FNFALFire;

var int BurstSize;
var transient int BurstShotCount; //how many bullets were fired in the current burst?
var transient float FireBurstEndTime; //this is just to be sure we don't stuck inside FireBurst state, if shit happens

var float PenDmgReduction; //penetration damage reduction. 1.0 - no reduction, 25% reduction
var byte  MaxPenetrations; //how many enemies can penetrate a single bullet

// fixes double shot bug -- PooSH
state FireLoop
{
    function BeginState()
    {
        super.BeginState();

        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
    }
}

state WaitingForFireButtonRelease
{
    function PlayFiring() {}
    function ServerPlayFiring() {}
    function PlayFireEnd() {}
    function ModeDoFire() {}
}

state FireBurst
{
    function BeginState()
    {
        NumShotsInBurst = 0;
        BurstShotCount = 0;
        NextFireTime = Level.TimeSeconds - 0.0001; //fire now!
        FireBurstEndTime = Level.TimeSeconds + ( FireRate * BurstSize ) + 0.1; // if shit happens - get us out of this state when this time hits
    }

    function EndState()
    {
        PlayFireEnd();
    }

    function StopFiring()
    {
        GotoState('');
    }

    function ModeTick(float dt)
    {
        Super.ModeTick(dt);

        if ( !bIsFiring ||  !AllowFire() )  // stopped firing, magazine empty
            GotoState('');
        else if ( Level.TimeSeconds > FireBurstEndTime )
        {
            GotoState('');
            log("ScrnM4203BulletFire stuck inside FireBurst state after making "$BurstShotCount$" shots! Getting us out of it.", 'ScrnBalance');
        }
    }

    // Calculate modifications to spread
    simulated function float GetSpread()
    {
        local float NewSpread;
        local float AccuracyMod;

        AccuracyMod = 1.0;

        // Spread bonus for firing aiming
        if( KFWeap.bAimingRifle )
        {
            AccuracyMod *= 0.5;
        }

        // Small spread bonus for firing crouched
        if( Instigator != none && Instigator.bIsCrouched )
        {
            AccuracyMod *= 0.85;
        }

        NumShotsInBurst++;

        // Small spread bonus for firing in semi auto mode
        // make spread bonus for first 2 shots -- PooSH
        if( NumShotsInBurst < 2 || (bAccuracyBonusForSemiAuto && bWaitForRelease) )
        {
            AccuracyMod *= 0.5;
        }


        if ( Level.TimeSeconds - LastFireTime > 0.5 ) {
            NewSpread = Default.Spread;
            NumShotsInBurst=0;
        }
        else if (BurstSize <= 2) {
            //2-nd shot doesn't get spread penalty
            NewSpread = Default.Spread;
        }
        else {
            // Decrease accuracy up to MaxSpread by the number of recent shots up to a max of six
            NewSpread = FMin(Default.Spread + (NumShotsInBurst * (MaxSpread/6.0)),MaxSpread);
        }

        NewSpread *= AccuracyMod;

        return NewSpread;
    }

    //copy-pasted from KFFire
    function ModeDoFire()
    {
        local float Rec;
        local KFPlayerReplicationInfo KFPRI;

        if (!AllowFire())
            return;

        if( Instigator==None || Instigator.Controller==none )
            return;

        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

        Spread = GetSpread();

        Rec = GetFireSpeed();
        FireRate = default.FireRate/Rec;
        FireAnimRate = default.FireAnimRate*Rec;
        ReloadAnimRate = default.ReloadAnimRate*Rec;
        Rec = 1;

        if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        {
            Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);
        }

        LastFireTime = Level.TimeSeconds;

        if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement)
        {
            if (FireRate > 0.25)
            {
                Weapon.Owner.Velocity.x *= 0.1;
                Weapon.Owner.Velocity.y *= 0.1;
            }
            else
            {
                Weapon.Owner.Velocity.x *= 0.5;
                Weapon.Owner.Velocity.y *= 0.5;
            }
        }

        Super(WeaponFire).ModeDoFire();

        // client
        if (Instigator.IsLocallyControlled())
        {
            if( bDoClientRagdollShotFX && Weapon.Level.NetMode == NM_Client )
            {
                DoClientOnlyFireEffect();
            }
            //reduce recoil for first 2 bullets
            if (NumShotsInBurst <= 1) {
                maxVerticalRecoilAngle = default.maxVerticalRecoilAngle *  0.1;
                maxHorizontalRecoilAngle = default.maxHorizontalRecoilAngle *  0.1;
            }
            HandleRecoil(Rec);
            //restore defaults
            maxVerticalRecoilAngle = default.maxVerticalRecoilAngle;
            maxHorizontalRecoilAngle = default.maxHorizontalRecoilAngle;
        }

        if ( ++BurstShotCount >= BurstSize ) {
            GotoState('WaitingForFireButtonRelease');
            return;
        }
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

defaultproperties
{
     BurstSize=2
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeFNFALAssaultRifle'
     AmmoClass=Class'ScrnBalanceSrv.ScrnFNFALAmmo'
     Spread=0.007500
     DamageMin=55  // unused
     DamageMax=55
     PenDmgReduction=0.75
     MaxPenetrations=2
}
