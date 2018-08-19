class ScrnBenelliBullet extends ScrnCustomShotgunBullet;

// make Siren's scream accelerate bullet and make higher damage
// made just for fun and to demonstrate penetration altering features
// should be removed later
// (c) PooSH
simulated function float ZedPenDamageReduction(KFMonster Monster)
{
    local name SeqName;
    local float AnimFrame, AnimRate;

    if ( ZombieSiren(Monster) != none) {
        Monster.GetAnimParams(1, SeqName, AnimFrame, AnimRate); //thanks to Marco for this one
        if (SeqName == 'Siren_Scream') {
            return 10;
        }
    }

    return super.ZedPenDamageReduction(Monster);
}

defaultproperties
{
     BigZedPenDmgReduction=0.75  // buff from 0.50 in v9.60.3
     MediumZedPenDmgReduction=1.000000
     MyDamageType=Class'KFMod.DamTypeBenelli'
}
