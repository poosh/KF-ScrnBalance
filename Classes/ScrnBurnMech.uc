// Alternate Burning Mechanism
// Big thanx to Scary Ghost for inspiring me to do it this way

class ScrnBurnMech extends Info;

struct BurningMonster {
    var KFMonster Victim;
    var Pawn Instigator;
    var int BurnDown;
    var int BurnDamage;
    var class<DamageType> FireDamageClass;
    var float NextBurnTime;
    var int BurnTicks; //how many ticks zed is already burning
    var int FlareCount; //how many flares are burning inside a zed
    var int TotalInputDamage; // total amount of incoming damage
};
var array<BurningMonster> Monsters;

var array<ScrnFlareCloud> FlareClouds;

var int BurnDuration; // tick count from ignition till the end of burning
var int BurnInCount; // tick count from ignition till reaching the maximum burn damage
var float BurnPeriod; // how often zeds will receive damage from burning

var(Sound)     Sound     FlareSound;
var            string    FlareSoundRef;

var bool bOutputDamage;

function PostBeginPlay()
{
    FlareSound = sound(DynamicLoadObject(FlareSoundRef, class'Sound', true));
}

function int FindMonsterIndex(KFMonster Monster )
{
    local int i;

    for ( i = 0; i < Monsters.Length; ++i ) {
        if ( Monsters[i].Victim == Monster )
            return i;
    }
    return -1;
}

function int GetAvgBurnDamage(int BurnDown, int InitialDamage)
{
    local float AvgTickInc;

    // Fire damage is increasing by (3-4 points per tick) * 1.5. 10 ticks total. Average = sum / 2 = 18.

    // Ignition takes 2 ticks, then average, constant damage is applied till the end of burning process
    // Total DoT is weaker comparing to original game due to 2 less ticks and burn-in damage decrement
    if ( class'ScrnBalance'.default.Mut.bHardcore || BurnDown >= BurnDuration )
        AvgTickInc = 6;
    else if ( BurnDown > (BurnDuration - BurnInCount) )
        AvgTickInc = 12;
    else
        AvgTickInc = 18;

    return InitialDamage + AvgTickInc;
}

function FlareMonster(int idx)
{
    local ScrnPlayerController InstigatorController;
    local ScrnPlayerController PC;
    local Controller C;

    Monsters[idx].Victim.AmbientSound = FlareSound;

    if ( Monsters[idx].Instigator != none )
        InstigatorController = ScrnPlayerController(Monsters[idx].Instigator.Controller);

    for ( C = Level.ControllerList; C != none; C = C.NextController ) {
        PC = ScrnPlayerController(C);
        if ( PC != none && (PC == InstigatorController || PC.LineOfSightTo(Monsters[idx].Victim)) ) {
            PC.ClientFlareDamage(Monsters[idx].Victim, Monsters[idx].BurnDamage/4, Monsters[idx].BurnDown);
        }
    }
}

function StopFlareFX(KFMonster Monster)
{
    if ( Monster.AmbientSound == FlareSound )
        Monster.AmbientSound = none;
}

function StopBurningBehavior(KFMonster Monster)
{
    Monster.SetTimer(0, false);
    Monster.bSTUNNED = false; // maybe timer was set to turn it off?
    Monster.bBurnified = false;
    Monster.BurnDown = 0;
    //if monster is raged don't slow him down
    Monster.GroundSpeed = max(Monster.GroundSpeed, Monster.default.GroundSpeed);

    Monster.UnSetBurningBehavior();
    Monster.RemoveFlamingEffects();
    Monster.StopBurnFX();

    StopFlareFX(Monster);
}

function MakeBurnDamage(KFMonster Victim, int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum,
        class<DamageType> DamType, optional int HitIndex)
{
    local bool bIncDamage;
    local int OldHealth;
    local int i, FreeSlot;
    local class<ScrnDamTypeFlare> FlareDamType;
    local float AdjustedFlareCount;

    // ScrnDamTypeHuskGun_Alt required for achievement
    bIncDamage = ClassIsChildOf(DamType, class'DamTypeMAC10MPInc') || DamType == class'ScrnBalanceSrv.ScrnDamTypeHuskGun_Alt';
    FlareDamType = class<ScrnDamTypeFlare>(DamType);

    // check if zed is already burning
    FreeSlot = Monsters.Length;
    for( i = 0; i < Monsters.Length; ++i ) {
        if ( Monsters[i].Victim == none ) {
            if ( FreeSlot == Monsters.Length )
                FreeSlot = i;
        }
        else if ( Monsters[i].Victim == Victim
                // Flare and regular burn damages occupy different slots
                && (FlareDamType == none) == (Monsters[i].FlareCount == 0) )
        {
            if ( FlareDamType != none ) {
                // Flares make incremental damage, i.e. each next flare raises damage per tick

                // Adjust flare count for this amount of damage.
                // For instance, monster was hit by 4 small flares (15 damage each) and now hit by
                // a big flare which causing 60 damage. Total flare count = 5, but if scaled by current damage,
                // then adjusted flare count = 2.
                AdjustedFlareCount = float(Monsters[i].TotalInputDamage) / Damage;
                if ( bOutputDamage && InstigatedBy != none && PlayerController(InstigatedBy.Controller) != none )
                    PlayerController(InstigatedBy.Controller).ClientMessage(
                            "AdjustedFlareCount="$AdjustedFlareCount
                            @ "TotalInputDamage="$Monsters[i].TotalInputDamage
                            @ "Damage="$Damage
                        );

                Monsters[i].BurnDown += FlareDamType.default.BurnTimeBoost;
                Monsters[i].BurnDown = max(Monsters[i].BurnDown,
                        FlareDamType.default.MinBurnTime + AdjustedFlareCount * FlareDamType.default.BurnTimeInc);
                Monsters[i].BurnDown = min(Monsters[i].BurnDown, FlareDamType.default.MaxBurnTime);
                Monsters[i].BurnDamage += max(Damage * FlareDamType.default.iDoT_MinBoostRatio,
                        Damage / (1.0 + AdjustedFlareCount * FlareDamType.default.iDoT_FadeFactor));
                Monsters[i].FlareCount++;
            }
            else if ( Damage >= Monsters[i].BurnDamage * 0.8 ) { //lower fire damage can't increase burn ticks, e.g. shooting with MAC10 after Husk gun
                //received extra burn damage while still burning
                Monsters[i].BurnDown = max(Monsters[i].BurnDown, BurnDuration - BurnInCount); //increase burn time to the maximum again (excluding 2 burn-in ticks)
                Monsters[i].BurnDamage = max(Damage, Monsters[i].BurnDamage);
                if ( bIncDamage )
                    Monsters[i].FireDamageClass = DamType;
                else
                    Monsters[i].FireDamageClass = class'DamTypeFlamethrower';
            }
            Monsters[i].Instigator = instigatedBy;
            Monsters[i].TotalInputDamage += Damage;
            Victim.BurnDown = Monsters[i].BurnDown;
            Victim.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType, HitIndex);
            if ( Victim.Health <= 0 )
                StopBurningBehavior(Victim);
            else if ( FlareDamType != none )
                FlareMonster(i);
            return;
        }
    }

    // If we've reached here, zed isn't burning yet.
    // First we need to check if zed can be set on fire, otherwise don't apply burning mechanism
    // on it (e.g. some Doom3 monsters are immune to fire).

    if ( FlareDamType != none ) {
        Victim.HeatAmount = 5; // just to be sure this gay feature don't block zed's ignition
    }
    OldHealth = Victim.Health;
    //damage zed and check if it's burning
    Victim.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType, HitIndex);
    if ( bOutputDamage && InstigatedBy != none && PlayerController(InstigatedBy.Controller) != none )
        PlayerController(InstigatedBy.Controller).ClientMessage(
            "Initial Damage: " $ Damage $ "/" $ String(OldHealth - Victim.Health)
            @ " -> "@ Victim.MenuName);
    //store burned damage in this variable. It is of Byte type, so can't write big values into it
    //Victim.HeatAmount = min(127, Victim.HeatAmount + OldHealth - Victim.Health);

    if ( !Victim.bBurnified && Victim.BurnDown == 0 )
        return; // can't be set on fire

    if ( Victim.Health <= 0 ) {
        StopBurningBehavior(Victim);
        return;
    }

    // if we reached here, zed is ignited and should burning - OUR WAY

    // KFMonster.Timer() makes fire damage based on LastBurnDamage + 3 + rand(2)
    // if player is lucky, monster will take another +1 damage per tick :)
    Victim.SetTimer(0, false); //disable timer, cuz we'll be using our own
    Victim.LastBurnDamage = -3;
    Victim.BurnDown = BurnDuration;

    //add new record
    i = FreeSlot;
    if ( i == Monsters.Length ) {
        Monsters.insert( i, 1 );
    }
    Monsters[i].Victim = Victim;
    Monsters[i].Instigator = InstigatedBy;
    Monsters[i].NextBurnTime = Level.TimeSeconds + BurnPeriod;
    Monsters[i].BurnTicks = 0;
    Monsters[i].BurnDamage = Damage;
    Monsters[i].TotalInputDamage = Damage;
    if ( FlareDamType != none ) {
        Monsters[i].FireDamageClass = FlareDamType;
        Monsters[i].BurnDown = FlareDamType.default.MinBurnTime;
        Monsters[i].FlareCount = 1;
        FlareMonster(i);
    }
    else {
        if ( bIncDamage )
            Monsters[i].FireDamageClass = DamType;
        else
            Monsters[i].FireDamageClass = class'DamTypeFlamethrower';
        Monsters[i].BurnDown = BurnDuration;
        Monsters[i].FlareCount = 0;
    }

    if ( !bTimerLoop ) {
        SetTimer(0.1, true);
    }
}


function Timer()
{
    local int i, EmptyTailBegin;
    local int OldHealth;
    local int Damage;
    local KFMonster M;

    if ( Monsters.Length == 0 ) {
        SetTimer(0, false);
        return;
    }

    EmptyTailBegin = Monsters.Length;
    for ( i = 0; i < Monsters.Length; ++i ) {
        if ( Monsters[i].Victim != none && Monsters[i].Victim.Health <= 0 ) {
            StopBurningBehavior(Monsters[i].Victim);
            Monsters[i].Victim = none;
        }

        if ( Monsters[i].Victim == none ) {
            if ( EmptyTailBegin == Monsters.Length ) {
                EmptyTailBegin = i;
            }
            continue;
        }

        EmptyTailBegin = Monsters.Length;
        M = Monsters[i].Victim;
        M.SetTimer(0, false); // ensure that timer is disabled
        if ( Monsters[i].NextBurnTime < Level.TimeSeconds ) {
            M.bSTUNNED = false; // manualy remove flinching effect here, cuz we disabled the timer
            M.BurnDown = max(Monsters[i].BurnDown, 2); //can't be less, or TakeFireDamage() will decrease it to 0 and turn off burning

            if ( Monsters[i].FlareCount > 0 )
                Damage = Monsters[i].BurnDamage; // flares don't use burn in
            else
                Damage = GetAvgBurnDamage(Monsters[i].BurnDown, Monsters[i].BurnDamage);

            OldHealth = Monsters[i].Victim.Health;
            M.TakeDamage(Damage*BurnPeriod, Monsters[i].Instigator, M.Location,
                vect(0, 0, 0), Monsters[i].FireDamageClass);
            M.LastBurnDamage = -3; //reset to default

            if ( bOutputDamage && Monsters[i].Instigator != none && PlayerController(Monsters[i].Instigator.Controller) != none)
                PlayerController(Monsters[i].Instigator.Controller).ClientMessage(
                    "Fire DoT: " $ String(Damage)$ "/" $ String(OldHealth - M.Health)
                    @ " -> "@ M.MenuName @ "("$String(i+1)$"/"$Monsters.Length$"). Burns = " $ String(Monsters[i].BurnDown)
                );

            Monsters[i].BurnDown--;
            Monsters[i].BurnTicks++;
            Monsters[i].NextBurnTime += BurnPeriod;

            if ( Monsters[i].FlareCount == 0 && Monsters[i].BurnTicks * BurnPeriod > 10 - M.CrispUpThreshhold )
                M.ZombieCrispUp(); // Melt em' :)

            if ( M.Health <= 0 ) {
                Monsters[i].Victim = none;
                StopBurningBehavior(M);
            }
            else if ( Monsters[i].BurnDown <= 0 ) {
                Monsters[i].Victim = none;
                if ( FindMonsterIndex(M) == -1 ) {
                    StopBurningBehavior(M);
                }
                else if ( Monsters[i].FlareCount > 0 ) {
                    StopFlareFX(M); // flares burned down, but other burning continues
                }
            }
        }
    }

    if ( EmptyTailBegin != Monsters.Length ) {
        // Remove empty records from the end of the monsters array.
        // Shouldn't do it in the middle of array to prevent record shifts in memory.
        Monsters.Length = EmptyTailBegin;
    }
}

defaultproperties
{
    BurnDuration=8
    BurnInCount=2
    BurnPeriod=1.0
    FlareSoundRef="KF_IJC_HalloweenSnd.KF_FlarePistol_Projectile_Loop"
}
