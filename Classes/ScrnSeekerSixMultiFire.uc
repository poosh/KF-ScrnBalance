class ScrnSeekerSixMultiFire extends ScrnSeekerSixFire;

var byte FlockIndex;
var int MaxLoad;

simulated function bool AllowFire()
{
    if(KFWeapon(Weapon).bIsReloading)
        return false;
    if(KFPawn(Instigator).SecondaryItem!=none)
        return false;
    if(KFPawn(Instigator).bThrowingNade)
        return false;

    if(KFWeapon(Weapon).MagAmmoRemaining < 1)
    {
        if( Level.TimeSeconds - LastClickTime>FireRate )
        {
            LastClickTime = Level.TimeSeconds;
        }

        if( AIController(Instigator.Controller)!=None )
            KFWeapon(Weapon).ReloadMeNow();
        return false;
    }

    //log("Spread = "$Spread);

    return ( Weapon.AmmoAmount(ThisModeNum) >= 1);
}

function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal, FireLocation;
    local Actor Other;
    local int p,q, SpawnCount, i;
    local ScrnSeekerSixMultiRocket FiredRockets[6];
    local bool bCurl;

    if ( Load < 2 )
    {
        Super.DoFireEffect();
        return;
    }

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;
    if ( !Weapon.WeaponCentered() && !KFWeap.bAimingRifle )
        StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);

// Collision attachment debugging
/*   if( Other.IsA('ROCollisionAttachment'))
    {
        log(self$"'s trace hit "$Other.Base$" Collision attachment");
    }*/

    if (Other != None)
    {
        StartProj = HitLocation;
    }

    Aim = AdjustAim(StartProj, AimError);

    //DesiredSpawnCount = Min(KFWeapon(Weapon).MagAmmoRemaining, ProjPerFire * int(Load));

    SpawnCount = Max(1, ProjPerFire * int(Load));

//    switch (SpreadStyle)
//    {
//    case SS_Random:
//        X = Vector(Aim);
//        for (p = 0; p < SpawnCount; p++)
//        {
//            R.Yaw = Spread * (FRand()-0.5);
//            R.Pitch = Spread * (FRand()-0.5);
//            R.Roll = Spread * (FRand()-0.5);
//            SpawnProjectile(StartProj, Rotator(X >> R));
//        }
//        break;
//    case SS_Line:
//        for (p = 0; p < SpawnCount; p++)
//        {
//            theta = Spread*PI/32768*(p - float(SpawnCount-1)/2.0);
//            X.X = Cos(theta);
//            X.Y = Sin(theta);
//            X.Z = 0.0;
//            SpawnProjectile(StartProj, Rotator(X >> Aim));
//        }
//        break;
//    default:
//        SpawnProjectile(StartProj, Aim);
//    }

    for ( p=0; p<SpawnCount; p++ )
    {
        Firelocation = StartProj - 2*((Sin(p*2*PI/MaxLoad)*8 - 7)*Y - (Cos(p*2*PI/MaxLoad)*8 - 7)*Z) - X * 8 * FRand();
        FiredRockets[p] = ScrnSeekerSixMultiRocket(SpawnProjectile(FireLocation, Aim));
    }

    if (Instigator != none )
    {
        if( Instigator.Physics != PHYS_Falling  )
        {
            Instigator.AddVelocity(KickMomentum >> Instigator.GetViewRotation());
        }
        // Really boost the momentum for low grav
        else if( Instigator.Physics == PHYS_Falling
            && Instigator.PhysicsVolume.Gravity.Z > class'PhysicsVolume'.default.Gravity.Z)
        {
            Instigator.AddVelocity((KickMomentum * LowGravKickMomentumScale) >> Instigator.GetViewRotation());
        }
    }

    if ( SpawnCount < 2 )
        return;

    if ( FlockIndex == 255 )
        FlockIndex = 0;

    FlockIndex++;

    if ( FlockIndex == 0 )
        FlockIndex = 1;

    // To get crazy flying, we tell each projectile in the flock about the others.
    for ( p = 0; p < SpawnCount; p++ )
    {
        if ( FiredRockets[p] != None )
        {
            FiredRockets[p].bCurl = bCurl;
            FiredRockets[p].FlockIndex = FlockIndex;
            i = 0;
            for ( q=0; q<SpawnCount; q++ )
                if ( (p != q) && (FiredRockets[q] != None) )
                {
                    FiredRockets[p].Flock[i] = FiredRockets[q];
                    i++;
                }
            bCurl = !bCurl;
            if ( Level.NetMode != NM_DedicatedServer )
                FiredRockets[p].SetTimer(0.1, true);
        }
    }
}

event ModeDoFire()
{
    if (!AllowFire())
        return;

    Load = Min(AmmoPerFire,KFWeapon(Weapon).MagAmmoRemaining);

    Super.ModeDoFire();
}

simulated function HandleRecoil(float Rec)
{
    local rotator NewRecoilRotation;
    local KFPlayerController KFPC;
    local KFPawn KFPwn;
    local vector AdjustedVelocity;
    local float AdjustedSpeed;

    if( Instigator != none )
    {
        KFPC = KFPlayerController(Instigator.Controller);
        KFPwn = KFPawn(Instigator);
    }

    if( KFPC == none || KFPwn == none )
        return;

    if( !KFPC.bFreeCamera )
    {
        if( Weapon.GetFireMode(1).bIsFiring )
        {
              NewRecoilRotation.Pitch = RandRange( maxVerticalRecoilAngle * 0.5 * Load, maxVerticalRecoilAngle );
             NewRecoilRotation.Yaw = RandRange( maxHorizontalRecoilAngle * 0.5 * Load, maxHorizontalRecoilAngle );

              if( Rand( 2 ) == 1 )
                 NewRecoilRotation.Yaw *= -1;

            if( Weapon.Owner != none && Weapon.Owner.Physics == PHYS_Falling &&
                Weapon.Owner.PhysicsVolume.Gravity.Z > class'PhysicsVolume'.default.Gravity.Z )
            {
                AdjustedVelocity = Weapon.Owner.Velocity;
                // Ignore Z velocity in low grav so we don't get massive recoil
                AdjustedVelocity.Z = 0;
                AdjustedSpeed = VSize(AdjustedVelocity);
                //log("AdjustedSpeed = "$AdjustedSpeed$" scale = "$(AdjustedSpeed* RecoilVelocityScale * 0.5));

                // Reduce the falling recoil in low grav
                NewRecoilRotation.Pitch += (AdjustedSpeed* 3 * 0.5);
                NewRecoilRotation.Yaw += (AdjustedSpeed* 3 * 0.5);
            }
            else
            {
                //log("Velocity = "$VSize(Weapon.Owner.Velocity)$" scale = "$(VSize(Weapon.Owner.Velocity)* RecoilVelocityScale));
                NewRecoilRotation.Pitch += (VSize(Weapon.Owner.Velocity)* 3);
                NewRecoilRotation.Yaw += (VSize(Weapon.Owner.Velocity)* 3);
            }

            NewRecoilRotation.Pitch += (Instigator.HealthMax / Instigator.Health * 5);
            NewRecoilRotation.Yaw += (Instigator.HealthMax / Instigator.Health * 5);
            NewRecoilRotation *= Rec;

             KFPC.SetRecoil(NewRecoilRotation,RecoilRate * (default.FireRate/FireRate));
        }
     }
}

defaultproperties
{
    MaxLoad=6
    FireSoundRef="KF_FY_SeekerSixSND.Fire.WEP_Seeker_Fire_All_M"
    StereoFireSoundRef="KF_FY_SeekerSixSND.Fire.WEP_Seeker_Fire_All_S"
    AmmoPerFire=6
    FlashEmitterClass=Class'KFMod.SeekerSixSecondaryMuzzleFlash1P'

    FireRate=1.0
    FireAnimRate=0.33
    AmmoClass=class'ScrnSeekerSixAmmo'
    ProjectileClass=class'ScrnSeekerSixMultiRocket'
}