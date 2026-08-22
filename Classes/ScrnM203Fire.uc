class ScrnM203Fire extends M203Fire;

//copypaste for recoil to apply to firemode 1
simulated function HandleRecoil(float Rec)
{
    local rotator NewRecoilRotation;
    local float NewRecoilSpeed;
    local KFPlayerController KFPC;
    local KFPawn P;
    local vector HorzVelocity;
    local float HorzSpeed;

    if (Instigator == none)
        return;

    KFPC = KFPlayerController(Instigator.Controller);
    P = KFPawn(Instigator);

    if (KFPC == none || P == none)
        return;

    if (KFPC.bFreeCamera || !bIsFiring)
        return;

    NewRecoilRotation.Pitch = RandRange(maxVerticalRecoilAngle * 0.5, maxVerticalRecoilAngle);
    NewRecoilRotation.Yaw = RandRange(maxHorizontalRecoilAngle * 0.5, maxHorizontalRecoilAngle);
    NewRecoilRotation *= Rec;
    NewRecoilSpeed = RecoilRate / (default.FireRate / FireRate);
    KFPC.SetRecoil(NewRecoilRotation, NewRecoilSpeed);
}

simulated function bool AllowFire()
{
    //don't allow firing nade while reloading rifle mag
    if( KFWeapon(Weapon).bIsReloading )
    {
        return false;
    }
    return super.AllowFire();
}

defaultproperties
{
     ProjectileClass=class'ScrnM203GrenadeProjectile'
     FireRate=1.99
     FireAnimRate=1.666667
}
