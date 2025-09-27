class ScrnExplosiveFunc_Burn extends ScrnExplosiveFunc abstract;

static function DealDamage(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType)
{
    local KFMonster Zed;

    Zed = KFMonster(Victim);


    if ( Zed != none && class'ScrnBalance'.default.Mut.BurnMech != none) {
        class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(Zed, Damage, Proj.Instigator, Hitlocation, Momentum,
            DamageType);
    }
    else {
        super.DealDamage(Proj, Victim, Damage, Hitlocation, Momentum, DamageType);
    }

    Victim.TakeDamage(Damage, Proj.Instigator, HitLocation, Momentum, DamageType);
}
