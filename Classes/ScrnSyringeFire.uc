class ScrnSyringeFire extends SyringeFire;

var transient float PendingHealTime;

Function Timer()
{
    local KFPlayerReplicationInfo PRI;
    local KFHumanPawn Healed;
    local float HealSum, HealPotency; // for modifying based on perks
    local bool bHealed;

    PRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    Healed = CachedHealee;
    HealPotency = 1.0;
    CachedHealee = none;

    if ( Healed != none && Healed.Health > 0 && Healed != Instigator )
    {
        Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);

        if ( PRI != none && PRI.ClientVeteranSkill != none )
            HealPotency = PRI.ClientVeteranSkill.Static.GetHealPotency(PRI);

        if ( Weapon.Level.Game.NumPlayers == 1 )
            HealSum = 50;  // for healing NPC on Story Mode
        else
            HealSum = Syringe(Weapon).HealBoostAmount;

        HealSum *= HealPotency;

        if (ScrnHumanPawn(Healed) != none) {
            bHealed =  ScrnHumanPawn(Healed).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency,
                    KFWeapon(Instigator.Weapon));
        }
        else {
            bHealed = Healed.GiveHealth(HealSum, Healed.HealthMax);;
        }

        if (bHealed) {
            // Tell them we're healing them
            PlayerController(Instigator.Controller).Speech('AUTO', 5, "");
            LastHealMessageTime = Level.TimeSeconds;
        }
    }
}

function KFHumanPawn GetHealee()
{
    local KFHumanPawn KFHP, BestKFHP;
    local vector Dir;
    local float TempDot, BestDot;

    Dir = vector(Instigator.GetViewRotation());

    foreach Instigator.VisibleCollidingActors(class'KFHumanPawn', KFHP, 80.0)
    {
        if ( KFHP.Health < KFHP.HealthMax && KFHP.Health > 0 )
        {
            TempDot = Dir dot (KFHP.Location - Instigator.Location);
            if ( TempDot > 0.7 && TempDot > BestDot )
            {
                BestKFHP = KFHP;
                BestDot = TempDot;
            }
        }
    }

    return BestKFHP;
}

function float GetFireSpeed()
{
    local KFPlayerReplicationInfo KFPRI;

    KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if (KFPRI != none && KFPRI.ClientVeteranSkill != none) {
        return KFPRI.ClientVeteranSkill.Static.GetFireSpeedMod(KFPRI, Weapon);
    }

    return 1;
}

// client side only! On server will called AttemptHeal(), which will call super.ModeDoFire()
event ModeDoFire()
{
    local float Rec;

    if (!AllowFire())
        return;

    if ( Weapon.Role < ROLE_Authority ) {
        if ( Level.TimeSeconds < PendingHealTime )
            return;
        PendingHealTime = Level.TimeSeconds + InjectDelay + 0.05;

        // now medic has syring heal bonus
        Rec = GetFireSpeed();
        FireRate = default.FireRate/Rec;
        FireAnimRate = default.FireAnimRate*Rec;
        InjectDelay = default.InjectDelay/Rec;
    }

    Super.ModeDoFire();
}

// this is executing only on server side
function AttemptHeal()
{
    local float Rec;

    if (!AllowFire())
        return;

    // AttemptHeal() should be executing on server side only, but who knows what TWI will screw up next?
    if ( Weapon.Role == ROLE_Authority ) {
        if ( Level.TimeSeconds < PendingHealTime )
            return;
        PendingHealTime = Level.TimeSeconds + InjectDelay + 0.05;

        Rec = GetFireSpeed();
        FireRate = default.FireRate/Rec;
        FireAnimRate = default.FireAnimRate*Rec;
        InjectDelay = default.InjectDelay/Rec;
    }

    Super.AttemptHeal();
}

defaultproperties
{
    FireRate=1.45
    FireAnimRate=2.0
}
