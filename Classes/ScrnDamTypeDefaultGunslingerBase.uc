class ScrnDamTypeDefaultGunslingerBase extends KFProjectileWeaponDamageType
    abstract;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    local SRStatsBase stats;
    
    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None ) {
        stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress',1);
    }    
}

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
    local SRStatsBase stats;
    
    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None )
        stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress',Amount);
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
