class ScrnExplosiveFunc_Pipebomb extends ScrnExplosiveFunc abstract;

static function ScaleHumanDamage(Projectile Proj, KFPawn Human, vector HitLocation, out float DamScale)
{
    DamScale *= 0.5;

    if (Proj.Damage >= 4000) {
        // Limit suicide bombs to 2000 damage (200 at FF10%) against humans
        DamScale *= 4000.0 / Proj.Damage;
    }

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
