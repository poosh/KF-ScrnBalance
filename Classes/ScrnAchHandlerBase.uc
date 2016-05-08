class ScrnAchHandlerBase extends Info 
    abstract;

var protected ScrnGameRules GameRules;

const IGNORE_STAT = 0x7FFFFFFF;

// Damage flags
// copy-pasted from ScrnGameRules for easy access
const DF_STUNNED   = 0x01; // stun shot
const DF_RAGED     = 0x02; // rage shot
const DF_STUPID    = 0x04; // damage shouldn't be done to this zed
const DF_DECAP     = 0x08; // decapitaion shot
const DF_HEADSHOT  = 0x10; // 100% sure that this damage was made by headshot

function PostBeginPlay()
{
    FindGameRules();
}

function FindGameRules()
{
    local GameRules G;
    
    if ( GameRules != none )
        return;
        
    for ( G=Level.Game.GameRulesModifiers; G!=None; G=G.NextGameRules ) {
        if ( ScrnGameRules(G) != none ) {
            GameRules = ScrnGameRules(G);
            GameRules.RegisterAchHandler(self);
            return;
        }
    }
    log(GetItemName(String(self)) $ ": unable to find ScrnGameRules. Trying again in 5 seconds.", 'ScrnBalance');
    SetTimer(5.0, false);
}

function Timer()
{
    FindGameRules();
}

// -----------------------------------------------------------------------------------
// STATIC FUNCTIONS 
// -----------------------------------------------------------------------------------

/*
    Helper function for quickly determining whether a pawn is rotated at a point in space.
    original authors :  Alex Quick, Ron Prestenback.

 * @param    Pawn            pawn, which rotation needs to be checked    
 * @param    TargetLocation    the location to check
 * @param    MinDotResult    a value between 0 and 1 representing the minimum dot result value that should be
 *                            considered acceptable for testing whether the location is within our field of
 *                            view.  Default value (0) is corresponds to a maximum angle of around 180 degrees
 *
 * @return    TRUE if the location is within the angle specified from the pawn's rotation.
 */
static function bool IsRotatedAtLocation(Pawn Pawn, vector TargetLocation, optional float MinDotResult)
{
    local vector DirectionNormal;
    local float ViewAngleCosine;

    // get the normalized distance between the two locations
    DirectionNormal = Normal(TargetLocation - Pawn.Location);

    // get the dot result of the pawn's rotation and the target location
    ViewAngleCosine = DirectionNormal dot vector(Pawn.Rotation);

    // determine if the angle between pawn's rotation and the target location is within range.
//    log("IS LOOKING AT LOCATION - "@ViewAngleCosine@" Required : "@MinDotResult);
    return ViewAngleCosine >= MinDotResult;
}

// returns number of not triggered pipeboms, which detonation range covers Pawn's location
// and are in lone of sight of a given pawn
static function int InPipeBombRange(Pawn Pawn, float PipeDetonationRange)
{
    local PipeBombProjectile pipe;
    local int count;
    local Controller C;

    C = Pawn.Controller;
    if ( C == none )
        return 0;
    
    foreach Pawn.VisibleCollidingActors( class 'PipeBombProjectile', pipe, PipeDetonationRange, Pawn.Location ) {
        if ( !pipe.bTriggered && !pipe.bHasExploded && !pipe.bDisintegrated && !pipe.bEnemyDetected 
                && IsRotatedAtLocation(Pawn, pipe.Location, 0.5) )
            count++;
    }
    return count;
}

//returns how much damage Instigator made to Victim
static function int GetTotalDamageMade(KFMonster Victim, Pawn Instigator) 
{
    if ( Victim == none || Instigator == none )
        return 0;
        
    return GetTotalDamageMadeC(KFMonsterController(Victim.Controller), Instigator.Controller);
}

//returns how much damage PC made to MC
static function int GetTotalDamageMadeC(KFMonsterController MC, Controller PC)
{
    local int i;
    
    if ( MC == none || PC == none )
        return 0;
        
    for ( i = 0; i < MC.KillAssistants.Length; ++i ) {
        if ( PC == MC.KillAssistants[i].PC )
            return MC.KillAssistants[i].Damage;
    }
    return 0;
}

static function bool IsPistolDamage(ScrnPlayerInfo InstigatorSPI, class<KFWeaponDamageType> DamageType) 
{
    local KFPlayerReplicationInfo KFPRI;
    
    if ( DamageType == none || InstigatorSPI == none || InstigatorSPI.PlayerOwner == none )
        return false;
      
    KFPRI =  KFPlayerReplicationInfo(InstigatorSPI.PlayerOwner.PlayerReplicationInfo);
    if ( KFPRI == none )
        return false;
    // Gunslinger gets damage bonus on all pistols (even level 0).
    // So if output damage > input damage, DamageType is pistol damage
    return  class'ScrnVetGunslinger'.static.AddDamage(KFPRI, none, none, 100, DamageType) > 100;
}

static function bool IsAssaultRifleDamage(ScrnPlayerInfo InstigatorSPI, class<KFWeaponDamageType> DamageType) 
{
    local KFPlayerReplicationInfo KFPRI;
    
    if ( DamageType == none || InstigatorSPI == none || InstigatorSPI.PlayerOwner == none )
        return false;
      
    KFPRI =  KFPlayerReplicationInfo(InstigatorSPI.PlayerOwner.PlayerReplicationInfo);
    if ( KFPRI == none )
        return false;
        
    return  class'ScrnVetCommando'.static.AddDamage(KFPRI, none, none, 100, DamageType) > 100;
}

// returns true, if player is using medic perk
static function bool IsMedic(ScrnPlayerInfo SPI)
{
    local KFPlayerReplicationInfo KFPRI;
    
    if ( SPI == none || SPI.PlayerOwner == none )
        return false;

    KFPRI = KFPlayerReplicationInfo(SPI.PlayerOwner.PlayerReplicationInfo);
    if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        return KFPRI.ClientVeteranSkill.static.GetHealPotency(KFPRI) > 1.01;

    return false;
}
// -----------------------------------------------------------------------------------



// give achievement to all players, except ExcludeSPI
final function Ach2All(name AchID, int Inc, optional ScrnPlayerInfo ExcludeSPI, optional TeamInfo Team)
{
    if ( GameRules != none )
        GameRules.ProgressAchievementForAllPlayers(AchID, Inc, false, ExcludeSPI, Team);
}
// give achievement to alive players, except ExcludeSPI
final function Ach2Alive(name AchID, int Inc, optional ScrnPlayerInfo ExcludeSPI, optional TeamInfo Team)
{
    if ( GameRules != none )
        GameRules.ProgressAchievementForAllPlayers(AchID, Inc, true, ExcludeSPI, Team);
}

/**
 * Function is called every time after the start of new wave
 * @param WaveNum - wave number, where 0 is first wave
 */
function WaveStarted(byte WaveNum) { }
/**
 * Function is called every time after the end of new wave
 * ScrnPlayerInfos aren't reset yet and can be used freely here
 * @param WaveNum - wave number, where 0 is first wave
 */
function WaveEnded(byte WaveNum) { }

// Function is called only when squad is survived.
// Map name without .rom, e.g. "KF-Farm". MapName is already checked for GameRules.MapAliases before
// calling GameWon()
function GameWon(string MapName) { }

// override this to catch all NetDamage() calls passed to GameRules. 
// NetDamage is executed after MonsterDamaged() or PlayerDamaged()
function NetDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, 
    class<DamageType> DamType ) {}
// override this to catch all ScoreKill() calls passed to GameRules. 
// score killed is executed after MonsterDied() or PlayerDied()
function ScoreKill(Controller Killer, Controller Killed) {}

// player-to-monster damages
// called from ScrnPlayerInfo.MadeDamage()
// At this moment InstigatorInfo.LastDmgTime still stores previos damage time (not the given one).
// So time between subsequent damages can be calculated by Level.TimeSeconds - InstigatorInfo.LastKillTime
function MonsterDamaged(int Damage, KFMonster Victim, ScrnPlayerInfo InstigatorInfo, 
    class<KFWeaponDamageType> DamType, bool bIsHeadshot, bool bWasDecapitated) {}

// monster got killed by a player    
// called from ScrnPlayerInfo.KilledMonster()
// At this moment KillerInfo.LastKillTime still stores previos kill time (not the given one).
// So time between subsequent kills can be calculated by Level.TimeSeconds - KillerInfo.LastKillTime
function MonsterKilled(KFMonster Victim, ScrnPlayerInfo KillerInfo, class<KFWeaponDamageType> DamType) {}

// player took a hit from monster
// called from ScrnPlayerInfo.TookDamage()
function PlayerDamaged(int Damage, ScrnPlayerInfo VictimSPI, KFMonster InstigatedBy, class<DamageType> DamType) {}

// player got killed
// called from ScrnPlayerInfo.Died()
// DeadPlayerInfo already has bDead = true and increased Deaths
function PlayerDied(ScrnPlayerInfo DeadPlayerInfo, Controller Killer, class<DamageType> DamType) {}
    
/**
 * Triggers when end game boss spawned on the map.
 * This function is called before KFMonster.PostBeginPlay(), where difficulty multipliers are applied, 
 * so it can't be used for checking actual monster parameters such as health or damage!
 * @param EndGameBoss The monster to spawned as end game boss (usually Patriarch)
 */
function BossSpawned(KFMonster EndGameBoss) {}

/**
 * Triggers when monster of a new class first time spawns in the game, i.e. it triggers on first Clot, first Gorefast etc.
 * This function is called before KFMonster.PostBeginPlay(), where difficulty multipliers are applied, 
 * so it can't be used for checking actual monster parameters such as health or damage!
 * 
 * @param Monster The momnster who spawned first time in the game
 */
function MonsterIntroduced(KFMonster Monster) {}



// Functions below are triggered, if stat value reaches a given number.
// AchHandler must return the minimal number, which it wants to be triggered.
// If AchHandler isn't interested in a given stat, it must return IGNORE_STAT.
// Keep in mind that return value is used as recomendation, not as a rule. It means that even
// if function had returned 5, there are no guaranties that it won't be triggered with a lower value
// e.g. 3. So input value must be checked always.

/**
 * Triggers when player scored multiple headshots in a row.
 * @param SPI Intigator's ScrnPlayerInfo record
 * @param Count Headhot count in a row
 * @return Minimal headshot count to be reached before the next call of this function
 */
function int RowHeadhots(ScrnPlayerInfo SPI, int Count)
{
    return IGNORE_STAT;
}

/**
 * Triggers when player scored multiple headshots in a row with one weapon.
 * @param SPI Intigator's ScrnPlayerInfo record
 * @param Weapon Weapon that PROBABLY was used to produce this damage type
 * @param DamType Damage type that was catched by GameRules
 * @param Count Headhot count in a row
 * @return Minimal headshot count to be reached before the next call of this function
 */
function int WRowHeadhots(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    return IGNORE_STAT;
}

/**
 * Triggers when player scored multiple headshots per single fire 
 * (due to bullet penetration or F/A mode without releasing a trigger).
 * @param SPI Intigator's ScrnPlayerInfo record
 * @param Weapon Weapon that PROBABLY was used to produce this damage type
 * @param DamType Damage type that was catched by GameRules
 * @param Count Headhot count scored without releasing a fire trigger
 * @return Minimal headshot count to be reached before the next call of this function
 */
function int WInstantHeadhots(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    return IGNORE_STAT;
}

// Same as WInstantHeadhots, but triggers on headshots without reloading
function int WHeadshotsPerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    return IGNORE_STAT;
} 
    
/**
 * Triggers when players scored multiple kills with one shot or without releasing a trigger 
 * (depends from a weapon). Sometimes shot isn't registred and multiple shots are registred as one.
 * So DeltaTime needs to be checked too.
 *
 * @param SPI Intigator's ScrnPlayerInfo record
 * @param Weapon Weapon that PROBABLY was used to produce this damage type
 * @param DamType Damage type that was catched by GameRules
 * @param Count Kill count in one shot
 * @param DeltaTime time between last and previous kill
 * @return Minimal headshot count to be reached before the next call of this function
 */
function int WKillsPerShot(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count, float DeltaTime)
{
    return IGNORE_STAT;
}    
// Same as WKillsPerShot, but triggers on kills without reloading
function int WKillsPerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    return IGNORE_STAT;
}    
// number of decapitaions per shot
function int WDecapsPerShot(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count, float DeltaTime)
{
    return IGNORE_STAT;
}    
// Same as WDecapsPerShot, but triggers on kills without reloading
function int WDecapsPerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    return IGNORE_STAT;
}
// amount of damage per shot
function int WDamagePerShot(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Damage, float DeltaTime)
{
    return IGNORE_STAT;
}    
// Same as WDamagePerShot, but triggers on kills without reloading
function int WDamagePerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Damage)
{
    return IGNORE_STAT;
}


/**
 * Triggers each time when one player healed another one. Doesn't trigger if player already had 100% hp.
 * @param HealAmount    the amount of health Patient received
 * @param Patient        player, who received healing
 * @param InstigatorSPI    Instigator's player info. Player, who made healing.
 * @param MedicGun        Instigator's weapon, which was used for healing
 *  
 */
function HealingMade(int HealAmount, ScrnHumanPawn Patient, ScrnPlayerInfo InstigatorSPI, KFWeapon MedicGun) {}


/**
 * Triggers when player picks up the cash. ReceiverInfo.CashReceived and CashFound and DonatorInfo.CashDonated,
 * as well as their PerWave variables, already include CashAmount. 
 * Function isn't triggered, when player picks up own cash.
 *
 * @param CashAmount     amount of cash picked up 
 * @param ReceiverInfo     player, who received cash (always != none)
 * @param DonatorInfo    player, who dropped the cash (can be none)
 * @param bDroppedCash    if true, cash was dropped by a player. False means it was spawned on the map.
 *                        There can be situations when bDroppedCash=true and DonatorInfo=none, so 
 *                        DonatorInfo must be always checked for none.
 */
function PickedCash(int CashAmount, ScrnPlayerInfo ReceiverInfo, ScrnPlayerInfo DonatorInfo, bool bDroppedCash) {}

/**
 * Triggers when player picks up a weapon. Weapon is not added to player's inventory yet. 
 * Function is triggered on picking up own weapons too.
 * @param SPI Player's info, who picked up a weapon
 * @param WeaponPickup The weapon picked up by the player
 */
function PickedWeapon(ScrnPlayerInfo SPI, KFWeaponPickup WeaponPickup) {}

/**
 * Triggers when player picks up an item from the ground, excluding cash and weapons, 
 * which have own trigger functions. Item is not added to player's inventory yet.
 * Function is triggered on picking up own items too.
 * @param SPI Player's info, who picked up an item
 * @param Item The item picked up by the player.
 */
function PickedItem(ScrnPlayerInfo SPI, Pickup Item) {}

/**
 * Triggers every time players reloads weapon. 
 * Per-magazine weapon stats are not nulled at this moment yet (e.g. KillsPerMagazine) 
 * @param SPI Player's info, who picked up an item
 * @param W Reloaded Weapon 
 */
function WeaponReloaded(ScrnPlayerInfo SPI, KFWeapon W) {}
    
defaultproperties
{
}    