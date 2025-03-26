class ScrnKnifeFireB extends ScrnMeleeFire;

defaultproperties
{
    bWaitForRelease = false;

    MeleeDamage=55
    DamagedelayMin=0.600000
    DamagedelayMax=0.600000
    hitDamageClass=Class'KFMod.DamTypeKnife'
    MeleeHitSounds(0)=SoundGroup'KF_KnifeSnd.Knife_HitFlesh'
    HitEffectClass=Class'KFMod.KnifeHitEffect'
    WideDamageMinHitAngle=0.700000
    FireAnim="Stab"
    FireRate=1.100000
    BotRefireRate=1.100000
}