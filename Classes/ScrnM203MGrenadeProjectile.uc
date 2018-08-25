class ScrnM203MGrenadeProjectile extends ScrnM79MGrenadeProjectile;


function SuccessfulHealMessage()
{
    if ( ScrnM4203MMedicGun(InstigatorWeapon) != none )
        ScrnM4203MMedicGun(InstigatorWeapon).ClientSuccessfulHeal(HealedPlayers.length, HealedHP);
}

defaultproperties
{
}
