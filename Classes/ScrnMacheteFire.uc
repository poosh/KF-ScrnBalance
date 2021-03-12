class ScrnMacheteFire extends MacheteFire;

function DoFireEffect() { }

simulated event ModeDoFire()
{
    local ScrnHumanPawn ScrnPawn;
    local float SpeedSq;

    ScrnPawn = ScrnHumanPawn(Instigator);
    MeleeDamage = default.MeleeDamage;
    if ( ScrnPawn != none && ScrnPawn.bMacheteDamageBoost && ScrnPawn.MacheteBoost > 0 ) {
        SpeedSq = VSizeSquared(ScrnPawn.Velocity);
        MeleeDamage += ScrnPawn.MacheteBoost * 2;
        if ( SpeedSq > 90000 ) {
            // exponentially raise damage when speed > 300
            MeleeDamage *= SpeedSq / 90000;
        }
        ScrnPawn.bMacheteDamageBoost = false;
    }
    super.ModeDoFire();
}

defaultproperties
{
     WideDamageMinHitAngle=0.000000
     MeleeDamage=70
}
