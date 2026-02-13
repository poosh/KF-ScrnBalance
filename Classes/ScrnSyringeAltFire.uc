// Self Healing Fire //
class ScrnSyringeAltFire extends SyringeAltFire;

function Timer()
{
    local int HealSum;
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

    Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
    if (ScrnPawn != none) {
        ScrnPawn.TakeHealingEx(ScrnPawn, 0, HealSum, MySyringe, false);
    }
    else {
        // shouldn't happen
        class'ScrnHumanPawn'.static.HealLegacyPawn(KFPawn(Instigator), Instigator, HealSum);
    }
}

defaultproperties
{
    FireRate=2.12
    FireAnimRate=2.0
}
