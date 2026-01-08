class ScrnChainsawFire extends ChainsawFire;

var float LastClickTime;

simulated function bool AllowFire()
{
    local KFWeapon KFWeap;
    local KFPawn KFP;

    KFWeap = KFWeapon(Weapon);
    KFP = KFPawn(Instigator);

    if ( KFWeap.bIsReloading )
        return false;

    if ( KFP.SecondaryItem != none || KFP.bThrowingNade )
        return false;

    if ( KFWeap.MagAmmoRemaining < 1 ) {
        if( Level.TimeSeconds - LastClickTime > FireRate )
            LastClickTime = Level.TimeSeconds;

        if( AIController(Instigator.Controller) != none )
            KFWeap.ReloadMeNow();
        return false;
    }

    return Super.AllowFire();
}

function PlayDefaultAmbientSound()
{
    local WeaponAttachment WA;

    WA = WeaponAttachment(Weapon.ThirdPersonActor);

    if ( KFWeapon(Weapon) == none || (WA == none))
        return;

    WA.SoundVolume = WA.default.SoundVolume;
    WA.SoundRadius = WA.default.SoundRadius;
    if ( KFWeapon(Weapon).MagAmmoRemaining > 0 )
        WA.AmbientSound = WA.default.AmbientSound;
    else
        WA.AmbientSound = none;
}

function DoFireEffect()
{
    local KFMeleeGun MGun;
    local bool bHitActor;
    local Actor HitActor;
    local Pawn Victim;
    local KFMonster Zed;
    local KFPawn HitPawn;
    local vector StartTrace, EndTrace, HitLocation, HitNormal, PointDir;
    local int MyDamage;
    local bool bBackStabbed;
    local array<int> HitPoints;
    local array<Actor> IgnoreActors;
    local int c;

    MGun = KFMeleeGun(Weapon);
    if (MGun == none || mGun.bNoHit)
        return;

    MyDamage = MeleeDamage;
    StartTrace = Instigator.Location + Instigator.EyePosition();

    if (Instigator.Controller != none && !Instigator.Controller.bIsPlayer && Instigator.Controller.Enemy != none) {
        PointDir = Instigator.Controller.Enemy.Location - StartTrace; // Give aimbot for bots.
    }
    else {
        PointDir = vector(Instigator.GetViewRotation());
    }

    // Instigator.ClearStayingDebugLines();

    EndTrace = StartTrace + PointDir * WeaponRange;
    while (++c < 100) {  // a safety guard to prevent infinite loops
        HitActor = Instigator.HitPointTrace(HitLocation, HitNormal, EndTrace, HitPoints, StartTrace,, 1);
        if (HitActor == none)
            break;

        if (HitActor == Instigator || HitActor.Base == Instigator || KFBulletWhipAttachment(HitActor) != none) {
            IgnoreActors[IgnoreActors.Length] = HitActor;
            HitActor.SetCollision(false);
            StartTrace = HitLocation;
            continue;
        }

        // Instigator.DrawStayingDebugLine(StartTrace, HitLocation, 0, 255, 0);
        bHitActor = true;
        ImpactShakeView();

        if (HitActor.IsA('ExtendedZCollision')) {
            HitActor = HitActor.Base;
        }

        Victim = Pawn(HitActor);
        Zed = KFMonster(Victim);
        HitPawn = KFPawn(Victim);

        if (Victim != none && MGun.BloodyMaterial != none) {
            Weapon.Skins[MGun.BloodSkinSwitchArray] = MGun.BloodyMaterial;
            Weapon.texture = Weapon.default.Texture;
        }

        if (Level.NetMode == NM_Client) {
            if (Victim != none) {
                Weapon.PlayOwnedSound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
            }
        }
        else {
            bBackStabbed = Victim != none
                    && Normal(Victim.Location - Instigator.Location) dot vector(Victim.Rotation) > 0;
            if (bBackStabbed) {
                MyDamage *= 2;
            }

            if (Zed != none) {
                Zed.bBackstabbed = bBackStabbed;
                Zed.TakeDamage(MyDamage, Instigator, HitLocation, PointDir, hitDamageClass);
                // Zed can be already dead here
                if (MeleeHitSounds.Length > 0) {
                    Weapon.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
                }
            }
            else if (HitPawn != none) {
                HitPawn.ProcessLocationalDamage(MyDamage, Instigator, HitLocation, PointDir,
                        hitDamageClass, HitPoints);
                if (MeleeHitSounds.Length > 0) {
                    Weapon.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
                }
            }
            else {
                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, PointDir, hitDamageClass) ;
                Spawn(HitEffectClass,,, HitLocation, rotator(HitLocation - StartTrace));
            }
        }
        break;
    }

    // Turn the collision back on for any actors we turned it off
    for (c = 0; c < IgnoreActors.Length; ++c) {
        if (IgnoreActors[c] != none) {
            IgnoreActors[c].SetCollision(true);
        }
    }
}


defaultproperties
{
    MeleeDamage=25
    MaxAdditionalDamage=0
    weaponRange=80.000000
    hitDamageClass=class'ScrnDamTypeChainsawAlt'
    AmmoClass=class'ScrnChainsawAmmo'
    AmmoPerFire=1
}
