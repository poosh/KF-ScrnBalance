class ScrnKnifeFire extends ScrnMeleeFire;

var name LastFireAnim;


function PlayFiring()
{
     Super.PlayFiring();
}

event ModeDoFire()
{
    if (FireAnims.length > 0) {
        LastFireAnim = FireAnim;
        FireAnim = FireAnims[rand(FireAnims.length)];
        DamagedelayMin = default.DamagedelayMin;
        // 3 and 2 should never play consecutively. it looks screwey.
        // 3 should never repeat directly after itself. buffer with 1
        if ((LastFireAnim == FireAnims[1] && FireAnim == FireAnims[2])
                ||  (LastFireAnim == FireAnims[2] && FireAnim == FireAnims[1])
                || (LastFireAnim == FireAnims[2] && FireAnim == FireAnims[2]))
        FireAnim = FireAnims[0];
    }
    Super(KFMeleeFire).ModeDoFire();
}

defaultproperties
{
    bWaitForRelease = false;
    FireAnims(0)="Fire"
    FireAnims(1)="Fire2"
    FireAnims(2)="fire3"
    FireAnims(3)="Fire4"
    MeleeDamage=19
    DamagedelayMin=0.450000
    DamagedelayMax=0.450000
    hitDamageClass=Class'KFMod.DamTypeKnife'
    MeleeHitSounds(0)=SoundGroup'KF_KnifeSnd.Knife_HitFlesh'
    HitEffectClass=Class'KFMod.KnifeHitEffect'
    WideDamageMinHitAngle=0
    FireRate=0.600000
    BotRefireRate=0.300000
}