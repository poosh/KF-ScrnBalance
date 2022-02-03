class ScrnDamTypeMagnum44Pistol extends DamTypeMagnum44Pistol;

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
    WeaponClass=class'ScrnMagnum44Pistol'
    HeadShotDamageMult=1.3
}
