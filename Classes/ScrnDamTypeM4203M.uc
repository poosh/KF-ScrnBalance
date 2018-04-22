class ScrnDamTypeM4203M extends ScrnDamTypeMedic
    abstract;
    
// Award also Shiver kills with 2x Stalker progress 
// v4.59 - count only 1 kill from now on, because new version of Shiver.se calls 
// AwardKill() twice: for the decapitator and for the killer
static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    if( Killed.IsA('ZombieShiver') || Killed.IsA('ZombieStalker') )
        KFStatsAndAchievements.AddStalkerKill();
}    

defaultproperties
{
    HeadShotDamageMult=1.100000
    WeaponClass=Class'ScrnBalanceSrv.ScrnM4203MMedicGun'
    DeathString="%k killed %o (M4 203)."
    FemaleSuicide="%o shot herself in the foot."
    MaleSuicide="%o shot himself in the foot."
    bRagdollBullet=True
    KDamageImpulse=1500.000000
    KDeathVel=110.000000
    KDeathUpKick=2.000000
}
