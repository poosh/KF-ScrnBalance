class ScrnNailGunFire extends NailGunFire;


function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile p;
    local ScrnNailGunProjectile nail;
    local ScrnNailGun w;

    p = super.SpawnProjectile(Start, Dir);
    nail = ScrnNailGunProjectile(p);
    w = ScrnNailGun(Weapon);

    if ( nail != none && w != none ) {
        nail.ach_Nail100m = w.ach_Nail100m;
        nail.ach_NailToWall = w.ach_NailToWall;
        nail.ach_PushShiver = w.ach_PushShiver;
        nail.ach_ProNailer = w.ach_ProNailer;
    }
    return p;
}


function ModeDoFire()
{
    local float Rec;
    local KFPlayerReplicationInfo KFPRI;

    if (!AllowFire())
        return;

    Load = min(AmmoPerFire, KFWeapon(Weapon).MagAmmoRemaining);  // must set it before fire in case player just changed fire mode

    Rec = GetFireSpeed();
    FireRate = default.FireRate/Rec;
    FireAnimRate = default.FireAnimRate*Rec;
    Rec = 1;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
    {
        Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);
    }

    if( !bFiringDoesntAffectMovement )
    {
        if (FireRate > 0.25)
        {
            Instigator.Velocity.x *= 0.1;
            Instigator.Velocity.y *= 0.1;
        }
        else
        {
            Instigator.Velocity.x *= 0.5;
            Instigator.Velocity.y *= 0.5;
        }
    }

    super(BaseProjectileFire).ModeDoFire();

    // client
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil(Rec);
    }
}

defaultproperties
{
    ProjPerFire=1
    AmmoClass=class'ScrnNailGunAmmo'
    ProjectileClass=class'ScrnNailGunProjectile'
    NoAmmoSoundRef="KF_NailShotgun.KF_NailShotgun_Dryfire"
}
