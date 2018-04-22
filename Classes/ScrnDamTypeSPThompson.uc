class ScrnDamTypeSPThompson extends DamTypeSPThompson
    abstract;

// Award also Shiver kills with 2x Stalker progress 
// Count only 1 kill from now on, because new version of Shiver.se calls 
// AwardKill() twice: for the decapitator and for the killer
static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    if( Killed.IsA('ZombieStalker') || Killed.IsA('ZombieShiver') )
        KFStatsAndAchievements.AddStalkerKill();
} 


defaultproperties
{
     WeaponClass=Class'ScrnBalanceSrv.ScrnSPThompsonSMG'
}