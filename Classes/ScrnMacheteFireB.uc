class ScrnMacheteFireB extends MacheteFireB;

function DoFireEffect() { }

simulated event ModeDoFire()
{
    local ScrnHumanPawn ScrnPawn;
    local float SpeedSq;

    ScrnPawn = ScrnHumanPawn(Instigator);
    MeleeDamage = default.MeleeDamage;
    if ( ScrnPawn != none && ScrnPawn.MacheteBoost > 0 ) {
        SpeedSq = VSizeSquared(ScrnPawn.Velocity);
        MeleeDamage += ScrnPawn.MacheteBoost * 3;
        if ( SpeedSq > 62500 ) {
            // exponentially raise damage when speed > 250
            MeleeDamage *= 1.0 + SpeedSq / 62500;
        }
    }
    super.ModeDoFire();
}

defaultproperties
{
     WideDamageMinHitAngle=0.000000
     MeleeDamage=130
}
