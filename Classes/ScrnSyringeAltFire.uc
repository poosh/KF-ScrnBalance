// Self Healing Fire //
class ScrnSyringeAltFire extends SyringeAltFire;

function Timer()
{
    local float HealSum, HealPotency;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnHumanPawn ScrnPawn;
    local ScrnGameType ScrnGT;
    local ScrnSyringe MySyringe;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    ScrnPawn = ScrnHumanPawn(Instigator);
    ScrnGT = ScrnGameType(Weapon.Level.Game);
    MySyringe = ScrnSyringe(Weapon);

    HealSum = MySyringe.HealBoostAmount;
    if ( Weapon.Level.Game.NumPlayers == 1 || (KFPRI != none && KFPRI.Team != none
            && (KFPRI.Team.Size == 1 || (ScrnGT != none && ScrnGT.AliveTeamPlayerCount[KFPRI.Team.TeamIndex] == 1))) )
    {
        HealSum = max(HealSum, MySyringe.SoloHealBoostAmount);
    }

    HealPotency = 1.0;
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);
    HealSum *= HealPotency;

    Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
    if ( ScrnPawn != none )
        ScrnPawn.TakeHealing(ScrnPawn, HealSum, HealPotency, MySyringe);
    else
        Instigator.GiveHealth(HealSum, Instigator.HealthMax);
}

defaultproperties
{
}
