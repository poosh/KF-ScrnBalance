class ScrnDualFlareRevolverFire extends DualFlareRevolverFire;

var ScrnDualFlareRevolver ScrnWeap; // avoid typecasting
var protected bool bFireLeft;

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnDualFlareRevolver(Weapon);
}

function SetPistolFireOrder(bool bNextFireLeft)
{
    bFireLeft = bNextFireLeft;
    ScrnWeap.bConsumeLeft = bFireLeft;

    if (bFireLeft)
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.FlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.altFlashBoneName;
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    else
    {
        ScrnWeap.altFlashBoneName = ScrnWeap.default.altFlashBoneName;
        ScrnWeap.FlashBoneName = ScrnWeap.default.FlashBoneName;
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
    }
}

function bool GetPistolFireOrder()
{
    return bFireLeft;
}

event ModeDoFire()
{
    if ( !AllowFire() )
        return;

    super(KFShotgunFire).ModeDoFire();

    InitEffects();
    SetPistolFireOrder(!bFireLeft || ScrnWeap.RightGunAmmoRemaining() == 0);
}

defaultproperties
{
     AmmoClass=class'ScrnFlareRevolverAmmo'
     ProjectileClass=class'ScrnFlareRevolverProjectile'
     ProjSpawnOffset=(X=0,Y=0,Z=0)
}
