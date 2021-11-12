class ScrnDamTypeDefaultGunslingerBase extends KFProjectileWeaponDamageType
    abstract;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer,
        KFMonster Killed )
{
    local SRStatsBase stats;

    // do not count kills of decapitated specimens - those are counted in ScoredHeadshot()
    if ( Killed != none && Killed.bDecapitated )
        return;

    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None )
        stats.Rep.ProgressCustomValue(Class'ScrnPistolKillProgress', 1);
}

static function ScoredHeadshot(KFSteamStatsAndAchievements KFStatsAndAchievements, class<KFMonster> MonsterClass,
        bool bSniper)
{
    local SRStatsBase stats;
    local int Amount;

    if ( KFStatsAndAchievements == none )
        return;

    if ( default.bSniperWeapon || bSniper )
        KFStatsAndAchievements.AddHeadshotKill(false);

    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats == none || stats.Rep == none )
        return;

    if ( ClassIsChildOf(MonsterClass, class'ZombieScrake') )
        Amount = 7;
    else if ( ClassIsChildOf(MonsterClass, class'ZombieBloat') )
        Amount = 3;
    else
        Amount = 1;
    stats.Rep.ProgressCustomValue(Class'ScrnPistolKillProgress', Amount);
}

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    local SRStatsBase stats;

    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None )
        stats.Rep.ProgressCustomValue(Class'ScrnPistolDamageProgress',Amount);
}


defaultproperties
{
     bSniperWeapon=False
     DeathString="%k killed %o (Pistol)."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
     bRagdollBullet=True
     bBulletHit=True
     FlashFog=(X=600.000000)
     KDamageImpulse=3500.000000
     KDeathVel=175.000000
     KDeathUpKick=15.000000
     VehicleDamageScaling=0.800000
}
