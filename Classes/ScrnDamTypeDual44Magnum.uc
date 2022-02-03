class ScrnDamTypeDual44Magnum extends DamTypeDual44Magnum
    abstract;

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

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    class'ScrnDamTypeDefaultGunslingerBase'.static.AwardDamage(KFStatsAndAchievements, Amount);
}


defaultproperties
{
    HeadShotDamageMult=1.30
    bSniperWeapon=False
    WeaponClass=class'ScrnDual44Magnum'
}
