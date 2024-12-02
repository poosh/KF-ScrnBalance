class ScrnDamTypeFlareProjectileImpact extends DamTypeFlareProjectileImpact;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer,
        KFMonster Killed )
{
    class'ScrnDamTypeDefaultGunslingerBase'.static.AwardKill(KFStatsAndAchievements, Killer, Killed);
}

static function ScoredHeadshot(KFSteamStatsAndAchievements KFStatsAndAchievements, class<KFMonster> MonsterClass,
        bool bLSM14Kill)
{
    class'ScrnDamTypeDefaultGunslingerBase'.static.ScoredHeadshot(KFStatsAndAchievements, MonsterClass, default.bSniperWeapon);
}

defaultproperties
{
    HeadShotDamageMult=2.0
}
