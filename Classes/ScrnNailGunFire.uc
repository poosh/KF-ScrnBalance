class ScrnNailGunFire extends NailGunFire;

var float SingleSpread; //spead in single nail mode

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
    }
    else {
        Spread = default.Spread;
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
    SingleSpread=0.500000
    ProjPerFire=1
    AmmoClass=Class'ScrnBalanceSrv.ScrnNailGunAmmo'
    AmmoPerFire=5
    ProjectileClass=Class'ScrnBalanceSrv.ScrnNailGunProjectile'
    Spread=1250.000000
    FireRate=0.40 // 0.50
    FireAnimRate=1.25

}
