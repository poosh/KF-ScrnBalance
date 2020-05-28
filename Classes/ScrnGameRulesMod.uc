class ScrnGameRulesMod extends ScrnGameRulesExt
    dependsOn(ScrnGameRules)
    abstract;

var ScrnGameRulesMod Next;

protected function OnGameRules()
{
    GameRules.AddMod(self);
}

function AddMod(ScrnGameRulesMod Mod)
{
    if ( Next != None )
        Next.AddMod(Mod);
    else
        Next = Mod;
}

function int ModifyMonsterDamage(out ScrnGameRules.MonsterInfo MI, ScrnPlayerController instigatedBy,
        int OriginalDamage, int Damage, vector HitLocation, out vector Momentum, class<KFWeaponDamageType> KFDamType)
{
    if ( Next != None )
        Damage = Next.ModifyMonsterDamage(MI, instigatedBy, OriginalDamage, Damage, HitLocation, Momentum, KFDamType);

    return Damage;
}
