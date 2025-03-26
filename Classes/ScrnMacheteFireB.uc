class ScrnMacheteFireB extends ScrnMeleeFire;

function DoFireEffect() { }

simulated event ModeDoFire()
{
    local ScrnHumanPawn ScrnPawn;
    local float SpeedSq;

    ScrnPawn = ScrnHumanPawn(Instigator);
    MeleeDamage = default.MeleeDamage;
    if ( ScrnPawn != none && ScrnPawn.bMacheteDamageBoost && ScrnPawn.MacheteBoost > 0 ) {
        SpeedSq = VSizeSquared(ScrnPawn.Velocity);
        MeleeDamage += ScrnPawn.MacheteBoost * 3;
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
    MeleeDamage=130
    bWaitForRelease=false

    ProxySize=0.120000
    DamagedelayMin=0.710000
    DamagedelayMax=0.710000
    hitDamageClass=Class'KFMod.DamTypeMachete'
    MeleeHitSounds(0)=SoundGroup'KF_AxeSnd.Axe_HitFlesh'
    HitEffectClass=Class'KFMod.KnifeHitEffect'
    FireAnim="PowerAttack"
    FireRate=1.100000
    BotRefireRate=0.710000
}
