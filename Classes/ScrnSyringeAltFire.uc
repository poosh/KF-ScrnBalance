// Self Healing Fire //
class ScrnSyringeAltFire extends SyringeAltFire;

function Timer()
{
    local float HealSum, HealPotency;
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo); 

    if ( Weapon.Level.Game.NumPlayers == 1 || (KFPRI != none && KFPRI.Team != none && KFPRI.Team.Size == 1) )
        HealSum = 50;
    else
        HealSum = Syringe(Weapon).HealBoostAmount;
        
    HealPotency = 1.0;

    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);
    HealSum *= HealPotency;

    Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
    if ( ScrnHumanPawn(Instigator) != none )
        ScrnHumanPawn(Instigator).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency, KFWeapon(Instigator.Weapon));
    else 
        KFPawn(Instigator).GiveHealth(HealSum, Instigator.HealthMax);
}

defaultproperties
{
}
