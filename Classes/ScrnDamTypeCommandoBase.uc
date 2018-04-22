class ScrnDamTypeCommandoBase extends KFProjectileWeaponDamageType
    abstract;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    if( Killed.IsA('ZombieStalker') || Killed.IsA('ZombieShiver') )
        KFStatsAndAchievements.AddStalkerKill();
}

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    KFStatsAndAchievements.AddBullpupDamage(Amount);
}

defaultproperties
{
     DeathString="%k killed %o (Assault Rifle)."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
     bRagdollBullet=True
     KDamageImpulse=1500.000000
     KDeathVel=110.000000
     KDeathUpKick=2.000000
}