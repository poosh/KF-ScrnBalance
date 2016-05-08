class ScrnKrissMHealingProjectile extends ScrnMP7MHealingProjectile;

function ClientSuccessfulHeal(String PlayerName)
{
    if( ScrnKrissMMedicGun(Instigator.Weapon) != none )
        ScrnKrissMMedicGun(Instigator.Weapon).ClientSuccessfulHeal(PlayerName);
}

defaultproperties
{
     HealBoostAmount=40
}
