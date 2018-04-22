class ScrnDamTypeTrenchgun extends DamTypeTrenchgun
    abstract;

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    super.AwardDamage(KFStatsAndAchievements, Amount); //count shotgun progress too

    KFStatsAndAchievements.AddFlameThrowerDamage(Amount);
}

defaultproperties
{
     WeaponClass=Class'ScrnBalanceSrv.ScrnTrenchgun'
}
