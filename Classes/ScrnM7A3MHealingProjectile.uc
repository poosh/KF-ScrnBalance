class ScrnM7A3MHealingProjectile extends ScrnMP7MHealingProjectile;

function ClientSuccessfulHeal(String PlayerName)
{
    if( ScrnM7A3MMedicGun(Instigator.Weapon) != none )
        ScrnM7A3MMedicGun(Instigator.Weapon).ClientSuccessfulHeal(PlayerName);
}

defaultproperties
{
     HealBoostAmount=30
}
