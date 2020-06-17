class ScrnScytheFire extends ScytheFire;

defaultproperties
{
    hitDamageClass=Class'ScrnBalanceSrv.ScrnDamTypeScythe'
    bWaitForRelease=True
    FireAnims(0)="Fire1"
    FireAnims(1)="Fire2"
    FireAnims(2)="Fire2"
    FireAnims(3)="Fire4"

    MeleeDamage=260
    weaponRange=105
    WideDamageMinHitAngle=0.5  // 120 degree angle: cos(120/2)=0.5
}
