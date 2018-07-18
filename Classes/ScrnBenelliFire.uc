class ScrnBenelliFire extends BenelliFire;

var float AimedSpread; //spead while aiming down the sights

simulated function bool AllowFire()
{
                                                                             //changed to 1 -- PooSH
    if( KFWeapon(Weapon).bIsReloading && KFWeapon(Weapon).MagAmmoRemaining < 1)
        return false;

    if(KFPawn(Instigator).SecondaryItem!=none)
        return false;
    if( KFPawn(Instigator).bThrowingNade )
        return false;

    if( Level.TimeSeconds - LastClickTime>FireRate )
    {
        LastClickTime = Level.TimeSeconds;
    }

    if( KFWeaponShotgun(Weapon).MagAmmoRemaining<1 )
        return false;

    return super(WeaponFire).AllowFire();
}

event ModeDoFire()
{
    local float Rec;

    if (!AllowFire())
        return;

    if( KFWeap.bAimingRifle )
        Spread = AimedSpread;
    else
        Spread = Default.Spread;

    Rec = GetFireSpeed();
    FireRate = default.FireRate/Rec;
    FireAnimRate = default.FireAnimRate*Rec;
    Rec = 1;

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

    Super(BaseProjectileFire).ModeDoFire();

    // client
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil(Rec);
    }
}


defaultproperties
{
     maxVerticalRecoilAngle=1250
     maxHorizontalRecoilAngle=700
     ProjectileClass=Class'ScrnBalanceSrv.ScrnBenelliBullet'
     AmmoClass=Class'ScrnBalanceSrv.ScrnBenelliAmmo'
     AimedSpread=750
     Spread=1075.000000
}
