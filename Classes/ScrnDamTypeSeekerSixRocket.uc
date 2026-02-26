// made to avoid x1.25 damage multiplier on FP
class ScrnDamTypeSeekerSixRocket extends DamTypeSeekerSixRocket;

defaultproperties
{
    WeaponClass=Class'ScrnSeekerSixRocketLauncher'
    // KFMod has messed up %o with %k in the death string.
    DeathString="%k filled %o's body with shrapnel."
}
