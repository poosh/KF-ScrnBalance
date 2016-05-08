class ScrnM203MGrenadeProjectile extends ScrnM79MGrenadeProjectile;


function SuccessfulHealMessage(int HealedCount, int HealedAmount)
{
    if ( ScrnM4203MMedicGun(InstigatorWeapon) != none )
        ScrnM4203MMedicGun(InstigatorWeapon).ClientSuccessfulHeal(HealedPlayers.length, HealedAmount);
}

defaultproperties
{
}
