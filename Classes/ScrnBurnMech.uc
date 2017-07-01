// Alternate Burning Mechanism
// Big thanx to Scary Ghost for inspiring me to do it this way

class ScrnBurnMech extends ReplicationInfo;

struct BurningMonster {
    var KFMonster Victim;
    var int BurnDown;
	var Pawn InstigatedBy;
	var int Damage;
	var class<DamageType> FireDamageClass;
	var float NextBurnTime;
	var int BurnTicks; //how many ticks zed is already burning
	var int FlareCount; //how many flares are burning inside a zed (excluding first one)
};
var array<BurningMonster> Monsters;

var array<ScrnFlareCloud> FlareClouds;

var int BurnDuration; // tick count from ignition till the end of burning
var int BurnInCount; // tick count from ignition till reaching the maximum burn damage
var float BurnPeriod; // how often zeds will receive damage from burning

var(Sound) 	Sound 	FlareSound;
var			string	FlareSoundRef;

var bool bOutputDamage;

var float NextBurnTime; // global check time to prevent calculations on every tick

function PostBeginPlay()
{
	FlareSound = sound(DynamicLoadObject(FlareSoundRef, class'Sound', true));
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


function FlareMonster(KFMonster Other)
{
	local int i;
	local KFMonster  M;

	//log("FlareMonster", 'ScrnBalance');
	Other.AmbientSound = FlareSound;

	while ( i < FlareClouds.length ) {
		if ( FlareClouds[i] == none ) {
			FlareClouds.remove(i, 1);
			continue;
		}
		M = KFMonster(FlareClouds[i].Owner);
		if ( M == none || M.Health <= 0 ) {
			FlareClouds[i].bHidden = true;
			FlareClouds[i].NetUpdateTime = Level.TimeSeconds - 1;
			FlareClouds[i].SetTimer(0.2, false); // give it some time to replicate bHidden property, then kill it
			FlareClouds.remove(i, 1);
			continue;
		}
		if ( M == Other ) {
            if ( FlareClouds[i].FlareCount < 10 )
                FlareClouds[i].FlareCount++;
            FlareClouds[i].NetUpdateTime = Level.TimeSeconds - 1;
			FlareClouds[i].AdjustCloudSize();

			return; //already flaming
		}
		i++;
	}
	FlareClouds[FlareClouds.length] = Spawn(Class'ScrnBalanceSrv.ScrnFlareCloud',Other,,, rotator(vect(0,0,1)));
}

function UnFlareMonster(optional KFMonster Other)
{
	local int i;
	local KFMonster  M;

	if ( Other.AmbientSound == FlareSound )
		Other.AmbientSound = none;

	while ( i < FlareClouds.length ) {
		if ( FlareClouds[i] == none ) {
			FlareClouds.remove(i, 1);
			continue;
		}
		M = KFMonster(FlareClouds[i].Owner);
		if ( M == none || M.Health <= 0 || M == Other ) {
			FlareClouds[i].bHidden = true;
			FlareClouds[i].NetUpdateTime = Level.TimeSeconds - 1;
			FlareClouds[i].SetTimer(0.2, false); // give it some time to replicate bHidden property, then kill it

			FlareClouds.remove(i, 1);
			continue;
		}
		i++;
	}
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

	if ( Monster.AmbientSound == FlareSound )
		Monster.AmbientSound = none;

	UnFlareMonster(Monster);
}


function MakeBurnDamage(KFMonster Victim, int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum,
		class<DamageType> DamType, optional int HitIndex)
{
	local bool bIncDamage, bFlareDamage;
    local int OldHealth;
	local int i;

    // ScrnDamTypeHuskGun_Alt required for achievement
	bIncDamage = ClassIsChildOf(DamType, class'DamTypeMAC10MPInc') || DamType == class'ScrnBalanceSrv.ScrnDamTypeHuskGun_Alt';
	bFlareDamage = ClassIsChildOf(DamType, class'DamTypeFlareRevolver');
	//PlayerController(InstigatedBy.Controller).ClientMessage("Is MAC10 Damage? : " $ bMAC10Damage);

	// check if zed is already burning
    for( i = 0; i < Monsters.Length; i++ ) {
        if (Monsters[i].Victim == Victim) {
			//PlayerController(InstigatedBy.Controller).ClientMessage("Monster found in burning list");

			// Flares make incremental damage, i.e. each next flare raises damage per tick
			// Need to check for damage value to ensure this is a direct hit, not a splash damage
			if ( bFlareDamage && Damage >= 15 && DamType == Monsters[i].FireDamageClass ) {
				Monsters[i].BurnDown = max(Monsters[i].BurnDown, BurnDuration + Monsters[i].FlareCount/2); //flares don't use burn in; each 2 flares adds +1s to burning
				Monsters[i].Damage = Monsters[i].Damage + max(1, Damage / (1.0 + Monsters[i].FlareCount * 0.25)); // 1st shot makes 30, 2nd +24, 3rd +20, 4rth +17 etc
				Monsters[i].FlareCount++;
                Monsters[i].InstigatedBy = instigatedBy;
			}
			else if ( Damage >= Monsters[i].Damage * 0.8 ) { //lower fire damage can't increase burn ticks, e.g. shooting with MAC10 after Husk gun
				// remove flare, if zed now is burnified by higher fire damage
				UnFlareMonster(Victim);
				Monsters[i].FlareCount = 0;
				//received extra burn damage while still burning
				Monsters[i].BurnDown = max(Monsters[i].BurnDown, BurnDuration - BurnInCount); //increase burn time to the maximum again (excluding 2 burn-in ticks)
				Monsters[i].Damage = max(Damage, Monsters[i].Damage);
				if ( bIncDamage || bFlareDamage )
					Monsters[i].FireDamageClass = DamType;
				else
					Monsters[i].FireDamageClass = class'DamTypeFlamethrower';
				Monsters[i].InstigatedBy = instigatedBy;
			}
			Victim.BurnDown = Monsters[i].BurnDown;
			Victim.TakeDamage(Damage, instigatedBy, hitLocation, momentum, DamType, HitIndex);
			if ( Victim.Health <= 0 )
				StopBurningBehavior(Victim);
			else if ( bFlareDamage && Damage >= 15 )
				FlareMonster(Victim);
			return;
        }
    }

	// If we've reached here, zed isn't burning yet.
	// First we need to check if zed can be set on fire, otherwise don't apply burning mechanism
	// on it (e.g. some Doom3 monsters are immune to fire).

	//Victim.HeatAmount += 5; // just to be sure this gay feature don't block zed's ignition
	//damage zed and check if it's burning
	OldHealth = Victim.Health;
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

	if ( bFlareDamage && Damage >= 15 )
		FlareMonster(Victim);


/*	this doesn't work at it should - zed continue burning
	// if zed is set on fire in lame KFMonster code, it doesn't mean we'll allow him burning
	// check the requirements - need to deal fire damage at least 3% of zed health  or 75 to set zed on fire
	if( Victim.HeatAmount < min(75, Victim.HealthMax * 0.03) ) {
		//don't set on fire yet
		StopBurningBehavior(Victim);
		return;
	}
*/

	// if we reached here, zed is ignited and should burning - OUR WAY

	// KFMonster.Timer() makes fire damage based on LastBurnDamage + 3 + rand(2)
	// if player is lucky, monster will take another +1 damage per tick :)
	Victim.SetTimer(0, false); //disable timer, cuz we'll be using our own
	Victim.LastBurnDamage = -3;
	Victim.BurnDown = BurnDuration;

	//add new record
	i = Monsters.Length;
	Monsters.Length = i + 1;
    Monsters[i].Victim = Victim;
    Monsters[i].NextBurnTime = Level.TimeSeconds + BurnPeriod;
	Monsters[i].BurnDown = BurnDuration;
    Monsters[i].InstigatedBy = InstigatedBy;
    Monsters[i].Damage = Damage;
	if ( bIncDamage || bFlareDamage) {
		Monsters[i].FireDamageClass = DamType;
		if ( bFlareDamage )
			Monsters[i].FlareCount = 1;
	}
	else
		Monsters[i].FireDamageClass = class'DamTypeFlamethrower';
	Enable('Tick');
	//PlayerController(InstigatedBy.Controller).ClientMessage("Monsters.Length = " $ String(Monsters.Length));
}


function Tick(float DeltaTime)
{
    local int i;
    local int OldHealth;
	local bool bRemoveMonster;
	local int Damage;

	if ( Monsters.Length == 0 ) {
		Disable('Tick');
		return;
	}

    if ( Level.TimeSeconds < NextBurnTime )
        return;

    while(i < Monsters.Length) {
		bRemoveMonster = false;

		if ( Monsters[i].Victim == none) {
			bRemoveMonster = true;
		}
		else if ( Monsters[i].Victim.Health <= 0 ) {
			StopBurningBehavior(Monsters[i].Victim);
			bRemoveMonster = true;
		}
		else {
			Monsters[i].Victim.SetTimer(0,false); // ensure that timer is disabled
			if (Monsters[i].NextBurnTime < Level.TimeSeconds) {
				Monsters[i].Victim.bSTUNNED = false; // manualy remove flinching effect here, cuz we disabled the timer

				Monsters[i].Victim.BurnDown = max(Monsters[i].BurnDown, 2); //can't be less, or TakeFireDamage() will decrease it to 0 and turn off burning

				if ( Monsters[i].FlareCount > 0 )
					Damage = Monsters[i].Damage; // flares don't use burn in
				else
					Damage = GetAvgBurnDamage(Monsters[i].BurnDown, Monsters[i].Damage);

				OldHealth = Monsters[i].Victim.Health;
				Monsters[i].Victim.TakeDamage(Damage*BurnPeriod, Monsters[i].InstigatedBy, Monsters[i].Victim.Location,
					vect(0, 0, 0), Monsters[i].FireDamageClass);
				Monsters[i].Victim.LastBurnDamage = -3; //reset to default

				if ( bOutputDamage && Monsters[i].InstigatedBy != none && PlayerController(Monsters[i].InstigatedBy.Controller) != none)
					PlayerController(Monsters[i].InstigatedBy.Controller).ClientMessage(
						"Fire DoT: " $ String(Damage)$ "/" $ String(OldHealth - Monsters[i].Victim.Health)
						@ " -> "@ Monsters[i].Victim.MenuName @ "("$String(i+1)$"/"$Monsters.Length$"). Burns = " $ String(Monsters[i].BurnDown)
					);

				Monsters[i].BurnDown--;
				Monsters[i].BurnTicks++;
				Monsters[i].NextBurnTime += BurnPeriod;

				if (Monsters[i].BurnTicks * BurnPeriod > 10 - Monsters[i].Victim.CrispUpThreshhold)
					Monsters[i].Victim.ZombieCrispUp(); // Melt em' :)

				if (Monsters[i].BurnDown <= 0 || Monsters[i].Victim.Health <= 0) {
					StopBurningBehavior(Monsters[i].Victim);
					bRemoveMonster = true;
				}
			}
		}
		if (bRemoveMonster) {
			Monsters.remove(i, 1);
		}
        else {
            i++;
		}
    }
    NextBurnTime = Level.TimeSeconds + default.NextBurnTime;
}

defaultproperties
{
    BurnDuration=8
    BurnInCount=2
    BurnPeriod=1.0
    FlareSoundRef="KF_IJC_HalloweenSnd.KF_FlarePistol_Projectile_Loop"
    NextBurnTime=0.2
}
