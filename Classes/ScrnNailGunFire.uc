class ScrnNailGunFire extends NailGunFire;

var float SingleSpread; //spead in single nail mode

var string SingleFireSoundRef;
var string StereoSingleFireSoundRef;

var() Sound SingleFireSound;
var() Sound StereoSingleFireSound;

var() Sound MultiFireSound; // used for backing up default FireSound
var() Sound StereoMultiFireSound;


static function PreloadAssets(LevelInfo LevelInfo, optional KFShotgunFire Spawned)
{
    local ScrnNailGunFire ScrnSpawned;

    super.PreloadAssets(LevelInfo, Spawned);

    if ( default.SingleFireSoundRef != "" ) {
        default.SingleFireSound = sound(DynamicLoadObject(default.SingleFireSoundRef, class'Sound', true));
    }

    if ( LevelInfo.bLowSoundDetail ) {
        default.StereoSingleFireSound = default.SingleFireSound;
    }
    else {
        if ( default.StereoSingleFireSoundRef == "" ) {
            default.StereoSingleFireSound = sound(DynamicLoadObject(default.StereoSingleFireSoundRef, class'Sound', true));
        }
        if ( default.StereoSingleFireSound == none )
            default.StereoSingleFireSound = default.SingleFireSound;
    }

    default.MultiFireSound = default.FireSound;
    default.StereoMultiFireSound = default.StereoMultiFireSound;

    ScrnSpawned = ScrnNailGunFire(Spawned);
    if ( ScrnSpawned != none ) {
        ScrnSpawned.SingleFireSound = default.SingleFireSound;
        ScrnSpawned.StereoSingleFireSound = default.StereoSingleFireSound;
        ScrnSpawned.MultiFireSound = default.MultiFireSound;
        ScrnSpawned.StereoMultiFireSound = default.StereoMultiFireSound;
    }
}

static function bool UnloadAssets()
{
    default.SingleFireSound = none;
    default.StereoSingleFireSound = none;
    default.MultiFireSound = none;
    default.StereoMultiFireSound = none;

    return super.UnloadAssets();
}


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

    if (!AllowFire())
        return;

    Load = min(AmmoPerFire, KFWeapon(Weapon).MagAmmoRemaining);  // must set it before fire in case player just changed fire mode

    Rec = GetFireSpeed();
    FireRate = default.FireRate/Rec;
    FireAnimRate = default.FireAnimRate*Rec;
    Rec = 1;

    if ( Load == 1 ) {
        Spread = SingleSpread;
        KickMomentum = vect(0,0,0);
        FireSound = SingleFireSound;
        StereoFireSound = StereoSingleFireSound;
    }
    else {
        Spread = default.Spread;
        KickMomentum = default.KickMomentum;
        FireSound = MultiFireSound;
        StereoFireSound = StereoMultiFireSound;
    }
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
    {
        Spread *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.ModifyRecoilSpread(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self, Rec);
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
    SingleSpread=0.20
    ProjPerFire=1
    AmmoClass=Class'ScrnBalanceSrv.ScrnNailGunAmmo'
    AmmoPerFire=7
    ProjectileClass=Class'ScrnBalanceSrv.ScrnNailGunProjectile'
    Spread=1750  // nerf from 1250 in v9.60.3
    FireRate=0.40 // 0.50
    FireAnimRate=1.25

    SingleFireSoundRef="KF_NailShotgun.KF_NailShotgun_Fire_Alt_M"
    StereoSingleFireSoundRef="KF_NailShotgun.KF_NailShotgun_Fire_Alt_S"
}
