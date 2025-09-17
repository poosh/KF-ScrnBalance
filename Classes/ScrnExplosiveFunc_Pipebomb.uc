class ScrnExplosiveFunc_Pipebomb extends ScrnExplosiveFunc abstract;

static function ScaleHumanDamage(Projectile Proj, KFPawn Human, vector HitLocation, out float DamScale)
{
    DamScale *= 0.5;

    if (Human == Proj.Instigator) {
        ScrnPipeBombProjectile(Proj).bDamagedInstigator = true;
    }
}

static function Killed(Projectile Proj, class<Pawn> KilledClass)
{
    if (ClassIsChildOf(KilledClass, class'ZombieFleshPound')
            || KilledClass.name == 'FemaleFP' || KilledClass.name == 'FemaleFP_MKII') {
        ScrnPipeBombProjectile(Proj).NumKilledFP++;
    }
    else if (ClassIsChildOf(KilledClass, class'ZombieCrawler')) {
        ScrnPipeBombProjectile(Proj).NumKilledCR++;
    }
}
