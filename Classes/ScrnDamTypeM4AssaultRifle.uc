class ScrnDamTypeM4AssaultRifle extends DamTypeM4AssaultRifle
    abstract;

// Award also Shiver kills with 2x Stalker progress
// v4.59 - count only 1 kill from now on, because new version of Shiver.se calls
// AwardKill() twice: for the decapitator and for the killer
static function AwardKill(KFSteamStatsAndAchievements KFStatsAndAchievements, KFPlayerController Killer, KFMonster Killed )
{
    if( Killed.IsA('Shiver') || Killed.IsA('ZombieStalker') )
        KFStatsAndAchievements.AddStalkerKill();
}

defaultproperties
{
     HeadShotDamageMult=1.20
     WeaponClass=Class'ScrnBalanceSrv.ScrnM4AssaultRifle'
}
