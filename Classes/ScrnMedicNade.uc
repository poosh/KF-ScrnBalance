class ScrnMedicNade extends MedicNade;

var transient int           HealedHP;   //total amount of HP restored to players
var transient array<Pawn>   HealedPlayers;

function HealOrHurt(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
    // no hurting
    HealRadius(DamageAmount, DamageRadius, HitLocation);
}

function HealRadius(float HealAmount, float HealRadius, vector HealLocation)
{
    local KFHumanPawn Victim;
    local int i;
    // Healing
    local KFPlayerReplicationInfo KFPRI;
    local KFSteamStatsAndAchievements Stats;
    local int MedicReward, TotalEarnedDosh;
    local float HealSum; // for modifying based on perks
    local float HealPotency;

    if ( bHurtEntry )
        return;
    bHurtEntry = true;
    NextHealTime = Level.TimeSeconds + HealInterval;

    HealPotency = 1.0;
    // raise it half a meter to be sure it doesn't stuck inside a floor like bugged pipes
    HealLocation.Z = HealLocation.Z + 25;

    if ( Instigator != none )
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    if ( KFPRI != none ) {
        Stats = KFSteamStatsAndAchievements(KFPRI.SteamStatsAndAchievements);

        if ( KFPRI.ClientVeteranSkill != none )
            HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);
    }

    foreach CollidingActors(class'KFHumanPawn', Victim, HealRadius, HealLocation) {
        if( Victim.Health <= 0 || Victim.Health >= Victim.HealthMax )
            continue;

        MedicReward = HealAmount * HealPotency;
        HealSum = MedicReward;

        if ( (Victim.Health + Victim.healthToGive + MedicReward) > Victim.HealthMax )
            MedicReward = max(0, Victim.HealthMax - (Victim.Health + Victim.healthToGive));

        //used to set different health restore rate
        if ( ScrnHumanPawn(Victim) != none )
            ScrnHumanPawn(Victim).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency, none);
        else
            Victim.GiveHealth(HealSum, Victim.HealthMax);

        // calculate total amount of health and unique player count
        HealedHP += MedicReward;
        i = 0;
        while ( i < HealedPlayers.Length && HealedPlayers[i] != Victim ) {
            i++;
        }
        if ( i == HealedPlayers.Length ) {
            HealedPlayers[i] = Victim;
        }

        if ( KFPRI != None ) {
            if ( MedicReward > 0 && Stats != none ) {
                Stats.AddDamageHealed(MedicReward);
            }

            // Give the medic reward money as a percentage of how much of the person's health they healed
            MedicReward = int((FMin(float(MedicReward),Victim.HealthMax)/Victim.HealthMax) * 60);

            if ( class'ScrnBalance'.default.Mut.bMedicRewardFromTeam && Victim.PlayerReplicationInfo != none && Victim.PlayerReplicationInfo.Team != none ) {
                // give money from team wallet
                if ( Victim.PlayerReplicationInfo.Team.Score >= MedicReward ) {
                    Victim.PlayerReplicationInfo.Team.Score -= MedicReward;
                    KFPRI.Score += MedicReward;
                    TotalEarnedDosh += MedicReward;
                }
            }
            else {
                KFPRI.Score += MedicReward;
                TotalEarnedDosh += MedicReward;
            }
        }
    }

    if ( TotalEarnedDosh > 0 && KFHumanPawn(Instigator) != none ) {
        KFHumanPawn(Instigator).AlphaAmount = 255;
    }
    bHurtEntry = false;
}

function SuccessfulHealAchievements()
{
    if ( HealedPlayers.Length >= 4 && Instigator != none )
        class'ScrnAchCtrl'.static.Ach2Pawn(Instigator, 'ExplosionLove', 1);
}

function SuccessfulHealMessage()
{
    local string str;
    local PlayerController PC;

    if (Instigator != none)
        PC = PlayerController(Instigator.Controller);

    if (PC != none) {
        str = class'ScrnM79M'.default.SuccessfulHealMessage;
        str = Repl(str, "%c", String(HealedPlayers.length), true);
        str = Repl(str, "%a", String(HealedHP), true);
        PC.ClientMessage(str, 'CriticalEvent');
    }
}


defaultproperties
{
    HealBoostAmount=4
    Damage=4
    DamageRadius=225
    MaxHeals=20
    LifeSpan=15
}