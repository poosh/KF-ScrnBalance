class ScrnZapFunc extends ScrnExplosiveFunc abstract;

static function DealDamage(Projectile Proj, Actor Victim, int Damage, vector HitLocation, vector Momentum,
        class<DamageType> DamageType)
{
    local KFMonster M;

    M = KFMonster(Victim);
    if (M != none) {
        // ignore damage scale and always apply full zap
        M.SetZapped(Proj.Damage * 0.01, Proj.Instigator);
        if (M.bZapped) {
            // longer stay in zapped state after the explosion
            M.RemainingZap *= 1.50;
        }
        else {
            M.LastZapTime = M.Level.TimeSeconds + ScrnZapProjectile(Proj).ZapKeepTime;
        }
    }
}
