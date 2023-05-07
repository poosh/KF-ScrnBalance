class ScrnSpeedPawn extends ScrnHumanPawn;

var float FallingDamageMod;

simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if (damageType == class'Fell') {
        Damage *= FallingDamageMod;
    }
    super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, damageType, HitIndex);
}


defaultproperties
{
    GroundSpeed=260
    WalkingPct=0.60
    AirSpeed=400
    AirControl=0.35
    AccelRate=10000
    HealthSpeedModifier=0.00
    BaseMeleeIncrease=0.15
    WeightSpeedModifier=0.173077
    MeleeWeightSpeedReduction=4
    WeaponWeightSpeedReduction=0
    bAllowMacheteBoost=false
    TraderSpeedBoost=1.0
    FallingDamageMod=0.5
}