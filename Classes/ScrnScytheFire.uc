class ScrnScytheFire extends ScrnMeleeFire;

defaultproperties
{
    hitDamageClass=class'ScrnDamTypeScythe'
    FireAnims(0)="Fire1"
    FireAnims(1)="Fire2"
    FireAnims(2)="Fire2"
    FireAnims(3)="Fire4"

    MeleeDamage=260
    weaponRange=105
    WideDamageMinHitAngle=0.5  // 120 degree angle: cos(120/2)=0.5

    ProxySize=0.150000
    DamagedelayMin=0.650000
    DamagedelayMax=0.650000
    HitEffectClass=Class'KFMod.ScytheHitEffect'
    FireRate=1.200000
    BotRefireRate=0.850000
}
