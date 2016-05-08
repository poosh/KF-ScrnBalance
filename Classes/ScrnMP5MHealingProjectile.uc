class ScrnMP5MHealingProjectile extends ScrnMP7MHealingProjectile;

function ClientSuccessfulHeal(String PlayerName)
{
    if( MP5MMedicGun(Instigator.Weapon) != none )
        MP5MMedicGun(Instigator.Weapon).ClientSuccessfulHeal(PlayerName);
}

defaultproperties
{
     HealBoostAmount=30
}
