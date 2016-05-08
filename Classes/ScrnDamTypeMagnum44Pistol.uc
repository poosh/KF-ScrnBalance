class ScrnDamTypeMagnum44Pistol extends DamTypeMagnum44Pistol;

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
	local SRStatsBase stats;
	
	stats = SRStatsBase(KFStatsAndAchievements);
	if( stats !=None && stats.Rep!=None )
		stats.Rep.ProgressCustomValue(Class'ScrnBalanceSrv.ScrnPistolDamageProgress',Amount);
}

defaultproperties
{
     WeaponClass=Class'ScrnBalanceSrv.ScrnMagnum44Pistol'
}
