// Self Healing Fire //
class ScrnSyringeAltFire extends SyringeAltFire;

function Timer()
{
    local int HealSum;
    local ScrnHumanPawn ScrnPawn;
    local ScrnSyringe MySyringe;

    ScrnPawn = ScrnHumanPawn(Instigator);
    MySyringe = ScrnSyringe(Weapon);

    // The first self-heal after all teammates are dead still has bSoloHealBoost=false, healing only 20hp.
    // That's intended to prevent selfishness.
    // If you and your teammates are heavily wounded, you are encouraged to heal the teammate (2x20hp)
    // rather than waiting for them to die and get +50hp for yourself.
    if (MySyringe.bSoloHealBoost) {
        HealSum = max(MySyringe.HealBoostAmount, MySyringe.SoloHealBoostAmount);
    }
    else {
        HealSum = MySyringe.HealBoostAmount;
    }

    Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
    if (ScrnPawn != none) {
        ScrnPawn.TakeHealingEx(ScrnPawn, 0, HealSum, MySyringe, false);
    }
    else {
        // shouldn't happen
        class'ScrnHumanPawn'.static.HealLegacyPawn(KFPawn(Instigator), Instigator, HealSum);
    }

    MySyringe.UpdateCharge();
}

defaultproperties
{
    FireRate=2.12
    FireAnimRate=2.0
}
