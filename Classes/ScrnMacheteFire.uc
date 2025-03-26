class ScrnMacheteFire extends ScrnMeleeFire;

var name LastFireAnim;

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

    if (FireAnims.length > 0) {
        LastFireAnim = FireAnim;
        FireAnim = FireAnims[rand(FireAnims.length)];
        //  3  and 2 should never play consecutively. it looks screwey.
        //  3 should never repeat directly after itself. buffer with 1
        if ( LastFireAnim == FireAnims[1] && FireAnim == FireAnims[2] ||
                LastFireAnim == FireAnims[2] && FireAnim == FireAnims[1] ||
                LastFireAnim == FireAnims[2] && FireAnim == FireAnims[2] )
        {
            FireAnim = FireAnims[0];
        }
    }
	Super(KFMeleeFire).ModeDoFire();
}

defaultproperties
{
    WideDamageMinHitAngle=0.000000
    MeleeDamage=70
    bWaitForRelease=false

    FireAnims(0)="Fire"
    FireAnims(1)="Fire2"
    FireAnims(2)="fire3"
    FireAnims(3)="Fire4"
    ProxySize=0.120000
    DamagedelayMin=0.570000
    DamagedelayMax=0.570000
    hitDamageClass=Class'KFMod.DamTypeMachete'
    MeleeHitSounds(0)=SoundGroup'KF_AxeSnd.Axe_HitFlesh'
    HitEffectClass=Class'KFMod.KnifeHitEffect'
    FireRate=0.710000
    BotRefireRate=0.710000
}
