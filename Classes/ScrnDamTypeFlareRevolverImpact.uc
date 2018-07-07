class ScrnDamTypeFlareRevolverImpact extends ScrnDamTypeFlareProjectileImpact;

static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    local SRStatsBase stats;
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(Killer.PlayerReplicationInfo);
    stats = SRStatsBase(KFStatsAndAchievements);
    if( stats !=None && stats.Rep!=None && KFPRI != none
            && ClassIsChildOf(KFPRI.ClientVeteranSkill, class'ScrnVetGunslinger') )
    {
        // add gunslinger progress only when played as gunslinger
        stats.Rep.ProgressCustomValue(Class'ScrnPistolKillProgress',1);
    }
}

defaultproperties
{
    HeadShotDamageMult=2.0
}
