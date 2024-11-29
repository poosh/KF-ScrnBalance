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
    local ScrnHumanPawn ScrnVictim;
    // Healing
    local KFPlayerReplicationInfo KFPRI;
    local float HealSum; // for modifying based on perks
    local float HealPotency;

    if ( bHurtEntry )
        return;
    bHurtEntry = true;
    NextHealTime = Level.TimeSeconds + HealInterval;

    HealPotency = 1.0;
    // raise it half a meter to be sure it doesn't stuck inside a floor like bugged pipes
    HealLocation.Z = HealLocation.Z + 25;

    if (Instigator != none)
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if (KFPRI != none && KFPRI.ClientVeteranSkill != none) {
        HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);
    }
    HealSum = HealAmount * HealPotency;

    foreach CollidingActors(class'KFHumanPawn', Victim, HealRadius, HealLocation) {
        if( Victim.Health <= 0 || Victim.Health >= Victim.HealthMax )
            continue;

        ScrnVictim = ScrnHumanPawn(Victim);


        if (ScrnVictim != none) {
            if (ScrnVictim.TakeHealing(ScrnVictim, HealSum, HealPotency, none)) {
                HealedHP += ScrnVictim.LastHealAmount;
                class'ScrnFunctions'.static.ObjAddUnique(HealedPlayers, Victim);
            }
        }
        else {
            Victim.GiveHealth(HealSum, Victim.HealthMax);
        }
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