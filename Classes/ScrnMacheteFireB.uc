class ScrnMacheteFireB extends MacheteFireB;

function DoFireEffect() { }

simulated event ModeDoFire()
{
    MeleeDamage = default.MeleeDamage; 
    if ( ScrnHumanPawn(Instigator) != none )
        MeleeDamage += ScrnHumanPawn(Instigator).MacheteBoost * 4;
    super.ModeDoFire();
}

defaultproperties
{
     WideDamageMinHitAngle=0.000000
}
