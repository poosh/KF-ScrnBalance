class ScrnFire_Inc extends ScrnFire_OpenBolt
    abstract;

function DoTrace(Vector Start, Rotator Dir)
{
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if (KFPRI != none && KFPRI.ClientVeteranSkill != none) {
        DamageType = KFPRI.ClientVeteranSkill.static.GetMAC10DamageType(KFPRI);

    }
    super.DoTrace(Start, Dir);
}

function DamageZed(KFMonster Victim, int Damage, vector HitLocation, vector HitMomentum)
{
    class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
            Victim, Damage, Instigator, HitLocation, HitMomentum, DamageType);
}


defaultproperties
{
    DamageType=Class'KFMod.DamTypeMAC10MP'
    DamageMax=35
}