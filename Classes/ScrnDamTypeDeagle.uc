class ScrnDamTypeDeagle extends DamTypeDeagle;

/*
static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
	local SRStatsBase stats;
	
	stats = SRStatsBase(KFStatsAndAchievements);
	if( stats !=None && stats.Rep!=None )
		stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolKillProgress',1);
}
*/

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
	local SRStatsBase stats;
	
	stats = SRStatsBase(KFStatsAndAchievements);
	if( stats !=None && stats.Rep!=None )
		stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress',Amount);
}

defaultproperties
{
     WeaponClass=Class'ScrnBalanceSrv.ScrnDeagle'
}
