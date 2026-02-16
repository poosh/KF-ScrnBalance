class ScrnExplosiveFunc_Nade extends ScrnExplosiveFunc abstract;

var int ScrakeUnstunDamageThreshold;


static function bool HurtVictim(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType, bool bCheckExposure, optional vector ExposureLocation)
{
    ExposureLocation.Z += 25; // raise above debris that a lazy L.D. forgot to disable collision on
    return super.HurtVictim(Proj, Victim, damage, hitlocation, momentum, DamageType, bCheckExposure, ExposureLocation);
}

static function DealDamage(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType)
{
    super.DealDamage(Proj, Victim, Damage, Hitlocation, Momentum, DamageType);

    if (ZombieScrake(Victim) != none) {
        ScrakeNader(Proj, Damage, ZombieScrake(Victim));
    }
}


static function ScrakeNader(Projectile Proj, int DamageAmount, ZombieScrake Scrake)
{
    local name  Sequence;
    local float Frame, Rate;

    if ( Scrake == none || Proj.Instigator == none || DamageAmount < default.ScrakeUnstunDamageThreshold )
        return;

    Scrake.GetAnimParams(Scrake.ExpectingChannel, Sequence, Frame, Rate);
    if ( Scrake.bShotAnim && (Sequence == 'KnockDown' || Sequence == 'SawZombieIdle') ) {
        //break the stun
        Scrake.bShotAnim = false;
        Scrake.SetAnimAction(Scrake.WalkAnims[0]);
        Scrake.Controller.GoToState('ZombieHunt');
        class'ScrnAchCtrl'.static.Ach2Pawn(Proj.Instigator, 'ScrakeNader', 1);
        //mark Scrake as naded in game rules
        if ( ScrnPlayerController(Proj.Instigator.Controller) != none )
            ScrnPlayerController(Proj.Instigator.Controller).Mut.GameRules.ScrakeNaded(Scrake);
    }
}

defaultproperties
{
    ScrakeUnstunDamageThreshold=50
}