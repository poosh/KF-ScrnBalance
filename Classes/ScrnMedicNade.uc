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
    local KFPawn Victim;
    local ScrnHumanPawn ScrnVictim;

    if ( bHurtEntry )
        return;
    bHurtEntry = true;
    NextHealTime = Level.TimeSeconds + HealInterval;

    // raise it half a meter to be sure it doesn't stuck inside a floor like bugged pipes
    HealLocation.Z = HealLocation.Z + 25;

    foreach CollidingActors(class'KFPawn', Victim, HealRadius, HealLocation) {
        if( Victim.Health <= 0 || Victim.Health >= Victim.HealthMax )
            continue;

        ScrnVictim = ScrnHumanPawn(Victim);
        if (ScrnVictim != none) {
            if (ScrnVictim.TakeHealingEx(ScrnHumanPawn(Instigator), 0, HealAmount, KFWeapon(Instigator.Weapon), false)) {
                HealedHP += ScrnVictim.LastHealAmount;
                class'ScrnFunctions'.static.ObjAddUnique(HealedPlayers, Victim);
            }
        }
        else {
            class'ScrnHumanPawn'.static.HealLegacyPawn(Victim, Instigator, HealAmount);
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