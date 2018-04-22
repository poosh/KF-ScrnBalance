class ScrnDamTypeBullpup extends DamTypeBullpup
    abstract;

// Award also Shiver kills with 2x Stalker progress 
// v4.59 - count only 1 kill from now on, because new version of Shiver.se calls 
// AwardKill() twice: for the decapitator and for the killer
static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    if( Killed.IsA('ZombieShiver') )
        KFStatsAndAchievements.AddStalkerKill();
    else 
        super.AwardKill(KFStatsAndAchievements, Killer, Killed);
}

defaultproperties
{
    WeaponClass=Class'ScrnBalanceSrv.ScrnBullpup'
}
