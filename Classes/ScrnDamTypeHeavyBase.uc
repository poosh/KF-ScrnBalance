// Base damage type for HMG perk
class ScrnDamTypeHeavyBase extends KFWeaponDamageType
    abstract;

static function AwardDamage(KFSteamStatsAndAchievements KFStatsAndAchievements, int Amount)
{
}

defaultproperties
{
    bIsPowerWeapon=true // allow HMG weapons to contribute to shotgun achievements but no sup achievement progress
    bCheckForHeadShots=false
}