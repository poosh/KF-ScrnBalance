class ScrnHuskGunFire extends HuskGunFire;

var int         AmmoInCharge;     //current charged amount
var() int       MaxChargeAmmo;    //maximum charge


function Timer()
{
    //consume ammo while charging
    if ( HoldTime > 0.0  && !bNowWaiting && AmmoInCharge < MaxChargeAmmo && Weapon.AmmoAmount(ThisModeNum) > 0 ) {
        Charge();
    }
    super.Timer();
}

function Charge()
{
    local int AmmoShouldConsumed;

    if( HoldTime < MaxChargeTime)
        AmmoShouldConsumed = clamp(round(MaxChargeAmmo*HoldTime/MaxChargeTime), 1, MaxChargeAmmo);
    else
        AmmoShouldConsumed = MaxChargeAmmo;// full charge

    if (AmmoShouldConsumed != AmmoInCharge) {
        if (AmmoShouldConsumed - AmmoInCharge > Weapon.AmmoAmount(ThisModeNum))
            AmmoShouldConsumed = Weapon.AmmoAmount(ThisModeNum) + AmmoInCharge;
        Weapon.ConsumeAmmo(ThisModeNum, AmmoShouldConsumed - AmmoInCharge);
        SetChargeAmount(AmmoShouldConsumed);
    }
}

function SetChargeAmount(int amount)
{
    AmmoInCharge = amount;
    ScrnHuskGun(Weapon).ChargeAmount = GetChargeAmount();
}

function float GetChargeAmount()
{
  return float(AmmoInCharge) / float(MaxChargeAmmo);
}

simulated function bool AllowFire()
{
    return (Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

//overrided to use AmmoInCharge in instead of HoldTime
//(c) PooSH
function PostSpawnProjectile(Projectile P)
{
    super(KFShotgunFire).PostSpawnProjectile(P);
    ApplyCharge(ScrnHuskGunProjectile(P));
}

function ApplyCharge(ScrnHuskGunProjectile proj)
{
    if ( proj == none || proj.bAppliedCharge )
        return;

    if( AmmoInCharge < MaxChargeAmmo )
    {
        proj.ImpactDamage *= AmmoInCharge;
        proj.Damage *= 1.0 + GetChargeAmount(); // up to 2x damage
        proj.DamageRadius *= 1.0 + GetChargeAmount();// up 2x the damage radius
    }
    else
    {
        proj.ImpactDamage *= MaxChargeAmmo; //650 max, down from 750
        proj.Damage *= 2.0; // up from 2x
        proj.DamageRadius *= 2.0; // down from x3
    }
    proj.bAppliedCharge = true;
    SetChargeAmount(0);
}

//copy pasted and cutted out ammo consuming, because we did it in time
function ModeDoFire()
{
    local float Rec;

    if (!AllowFire() && HoldTime ~= 0)
        return;

    Spread = Default.Spread;
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

    if (!AllowFire() && HoldTime ~= 0)
        return;

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if (Weapon.Role == ROLE_Authority)
    {
        Charge();

        DoFireEffect();
        HoldTime = 0;    // if bot decides to stop firing, HoldTime must be reset first
        SetChargeAmount(0);
        if ( (Instigator == None) || (Instigator.Controller == None) )
            return;

        if ( AIController(Instigator.Controller) != None )
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        ShakeView();
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
    }
    else // server
    {
        ServerPlayFiring();
    }

    Weapon.IncrementFlashCount(ThisModeNum);

    // set the next firing time. must be careful here so client and server do not get out of sync
    if (bFireOnRelease)
    {
        if (bIsFiring)
            NextFireTime += MaxHoldTime + FireRate;
        else
            NextFireTime = Level.TimeSeconds + FireRate;
    }
    else
    {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }

    Load = AmmoPerFire;
    HoldTime = 0;
    SetChargeAmount(0);

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil(Rec);
    }
}

// function StopFiring()
// {
//     super.StopFiring();
//     SetChargeAmount(0);
// }

defaultproperties
{
    MaxHoldTime=0.0 // no auto fire
    MaxChargeTime=3.0 // 3s to full charge
    MaxChargeAmmo=10
    WeakProjectileClass=Class'ScrnBalanceSrv.ScrnHuskGunProjectile_Weak'
    StrongProjectileClass=Class'ScrnBalanceSrv.ScrnHuskGunProjectile_Strong'
    AmmoClass=Class'ScrnBalanceSrv.ScrnHuskGunAmmo'
    ProjectileClass=Class'ScrnBalanceSrv.ScrnHuskGunProjectile'

    SpreadStyle=SS_None
    Spread=0
}
