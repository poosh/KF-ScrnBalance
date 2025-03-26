class ScrnMeleeFire extends KFMeleeFire;

var array<name> FireAnims;

simulated event ModeDoFire()
{
    if (FireAnims.length > 0) {
        FireAnim = FireAnims[rand(FireAnims.length)];
    }
    Super.ModeDoFire();
}

function Timer()
{
    local KFMeleeGun MGun;
    local bool bHitActor;
    local Actor HitActor;
    local Pawn Victim;
    local KFMonster Zed;
    local vector StartTrace, EndTrace, HitLocation, HitNormal;
    local rotator PointRot;
    local int MyDamage;
    local bool bBackStabbed;
    local vector dir, lookdir;
    local float DiffAngle, VictimDistSq;

    MGun = KFMeleeGun(Weapon);
    if (MGun == none || mGun.bNoHit)
        return;

    MyDamage = MeleeDamage;
    StartTrace = Instigator.Location + Instigator.EyePosition();

    if (Instigator.Controller != none && !Instigator.Controller.bIsPlayer && Instigator.Controller.Enemy != none) {
        PointRot = rotator(Instigator.Controller.Enemy.Location - StartTrace); // Give aimbot for bots.
    }
    else {
        PointRot = Instigator.GetViewRotation();
    }

    // Instigator.ClearStayingDebugLines();

    EndTrace = StartTrace + vector(PointRot) * WeaponRange;
    HitActor = Instigator.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
    if (HitActor != None) {
        // Instigator.DrawStayingDebugLine(StartTrace, HitLocation, 0, 255, 0);
        bHitActor = true;
        ImpactShakeView();

        if (HitActor.IsA('ExtendedZCollision')) {
            HitActor = HitActor.Base;
        }

        Victim = Pawn(HitActor);
        Zed = KFMonster(HitActor);
        if (Victim != none && MGun.BloodyMaterial != none) {
            Weapon.Skins[MGun.BloodSkinSwitchArray] = MGun.BloodyMaterial;
            Weapon.texture = Weapon.default.Texture;
        }
        if (Level.NetMode==NM_Client) {
            if (Victim != none) {
                Weapon.PlayOwnedSound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
            }
        }
        else {
            if (Victim != none && !Victim.IsA('Vehicle')
                    && Normal(Victim.Location - Instigator.Location) dot vector(Victim.Rotation) > 0) {
                bBackStabbed = true;
                MyDamage*=2;
            }

            if (Zed != none) {
                Zed.bBackstabbed = bBackStabbed;
                Zed.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
                if (MeleeHitSounds.Length > 0) {
                    Weapon.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
                }
                if (Zed.Mass <= Instigator.Mass && VSizeSquared(Instigator.Velocity) > 90000) {
                    Zed.FlipOver();
                }
            }
            else {
                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
                Spawn(HitEffectClass,,, HitLocation, rotator(HitLocation - StartTrace));
            }
        }
    }

    if (WideDamageMinHitAngle <= 0)
        return;

    lookdir = Normal(Vector(Instigator.GetViewRotation()));
    foreach Weapon.VisibleCollidingActors(class'Pawn', Victim, 2*weaponRange, StartTrace) {
        if (Victim == HitActor || Victim == Instigator || Victim.Health <= 0)
            continue;

        EndTrace = Victim.Location;
        if (bHitActor) {
            // align horizontal plane of all hits
            EndTrace.Z = HitLocation.Z;
            // Instigator.DrawStayingDebugLine(StartTrace, EndTrace, 0, 255, 255);
        }
        else {
            // a dirty hack
            EndTrace.Z += 0.7 * Victim.CollisionHeight;
            // Instigator.DrawStayingDebugLine(StartTrace, EndTrace, 255, 0, 0);
        }

        VictimDistSq = VSizeSquared(EndTrace - StartTrace);
        if (VictimDistSq > ((Victim.CollisionRadius + 1.1*weaponRange) ** 2))
            continue;

        dir = Normal(EndTrace - StartTrace);
        DiffAngle = lookdir dot dir;

        if (DiffAngle < WideDamageMinHitAngle)
            continue;

        Victim.TakeDamage(MyDamage*DiffAngle, Instigator, EndTrace - dir * Victim.CollisionRadius, dir,
                hitDamageClass);
        if(MeleeHitSounds.Length > 0) {
            if (Level.NetMode==NM_Client) {
                Victim.PlayOwnedSound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
            }
            else {
                Victim.PlaySound(MeleeHitSounds[Rand(MeleeHitSounds.length)],SLOT_None,MeleeHitVolume,,,,false);
            }
        }
    }
}

defaultproperties
{
    bWaitForRelease=True
    MeleeHitSounds(0)=SoundGroup'KF_AxeSnd.Axe_HitFlesh'
}