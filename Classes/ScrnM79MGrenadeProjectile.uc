class ScrnM79MGrenadeProjectile extends M79GrenadeProjectile;

#exec OBJ LOAD FILE=KF_GrenadeSnd.uax
#exec OBJ LOAD FILE=Inf_WeaponsTwo.uax
#exec OBJ LOAD FILE=KF_LAWSnd.uax

var()   int                 HealBoostAmount;// How much we heal a player by default with the medic nade

var transient int           TotalHeals;     // The total number of times this nade has healed (or hurt enemies)
var()   int                 MaxHeals;       // The total number of times this nade will heal (or hurt enemies) until its done healing
var transient float         NextHealTime;   // The next time that this nade will heal friendlies or hurt enemies
var()   float               HealInterval;   // How often to do healing

var 	int		            MaxNumberOfPlayers;

var transient int           HealedAmount;   //total amount of HP restored to players
var transient array<Pawn>   HealedPlayers;


var float                   ExplodeTimer; //time between first hitting a wall and explosion
var float                   PlayerCheckRate; //how many times per second nade will be checking for players nearby
var transient float         LastSparkTime;
var transient bool          bTimerSet;
var() float                 DampenFactor, DampenFactorParallel;
var class<xEmitter>         HitEffectClass;
var transient KFWeapon      InstigatorWeapon;



var Emitter GreenCloud;
var class<Emitter> GreenCloudClass;
//var transient Vector PrevLocation; // used to determine if nade has moved since explosion

var transient float TimeToExplode;

var vector    ExplodeLocation;
//var transient bool      bNeedToPlayEffects; // Whether or not effects have been played yet

var Rotator  IntitialRotationAdjustment; // used to rotate nade in a proper direction


replication
{
    reliable if ( Role==ROLE_Authority )
        ExplodeLocation;
}

simulated function PostNetReceive()
{
    // log("ScrnM79MGrenadeProjectile.PostNetReceive():  bHasExploded=" $ bHasExploded @ "bHidden=" $bHidden
        // @ "ExplodeLocation=" $ExplodeLocation @ "Location=" $Location
        // @ "AmmoAmount=" $ Instigator.Weapon.AmmoAmount(0), class.outer.name);

    // Level.GetLocalPlayerController().TeamMessage(Level.GetLocalPlayerController().PlayerReplicationInfo, "PostNetReceive: bHasExploded=" $ bHasExploded @ "bHidden=" $bHidden
        // @ "ExplodeLocation=" $ExplodeLocation @ "Location=" $Location
        // @ "AmmoAmount=" $ Instigator.Weapon.AmmoAmount(0), 
        // 'Event'); 

    // this doesn't work :(
    if( bHidden ) {
        if ( !bDisintegrated )
            Disintegrate(Location, vect(0,0,1));
    }
    else if ( ExplodeLocation != vect(0,0,0) ) {
        if( !bHasExploded ) {
            SetLocation(ExplodeLocation); 
            Explode(ExplodeLocation, vect(0,0,1));
        }
        else if ( ExplodeLocation != Location ) {
            //synchronize healing location between server and client
            SetLocation(ExplodeLocation); 
            if ( GreenCloud != none ) 
                GreenCloud.SetLocation(ExplodeLocation);
        }
    }
}


//overrided to disable smoke trail
simulated function PostBeginPlay()
{
    local rotator SmokeRotation;

    BCInverse = 1 / BallisticCoefficient;
    
    OrigLoc = Location;

    if( !bDud )
    {
        Dir = vector(Rotation);
        Velocity = speed * Dir;
    }
	
    if ( Level.NetMode != NM_DedicatedServer)
    {
        SmokeTrail = Spawn(class'ScrnBalanceSrv.ScrnMedicNadeTrail',self);
        SmokeTrail.SetBase(self);
		SmokeRotation.Pitch = 32768;
        SmokeTrail.SetRelativeRotation(SmokeRotation);
        //Corona = Spawn(class'KFMod.KFLAWCorona',self);
    }

	SetRotation(Rotation + IntitialRotationAdjustment);



    if (PhysicsVolume.bWaterVolume)
    {
        bHitWater = True;
        Velocity=0.6*Velocity;
    }
    super(Projectile).PostBeginPlay();
    
    if ( Instigator != none)
        InstigatorWeapon = KFWeapon(Instigator.Weapon);
}

simulated function Disintegrate(vector HitLocation, vector HitNormal)
{
    super.Disintegrate(HitLocation, HitNormal);
    
    // if ( SmokeTrail != None )
	// {
		// SmokeTrail.HandleOwnerDestroyed();
	// }
    
    // if ( GreenCloud != none && !GreenCloud.bDeleteMe )     
        // GreenCloud.Kill(); 
        
    if ( Role < ROLE_Authority )
        Destroy(); // server will destroy it on timer
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    // local PlayerController  LocalPlayer;

    if ( bHasExploded )
        return; 
        
	bHasExploded = True;
	BlowUp(HitLocation);

	if ( SmokeTrail != None ) {
		SmokeTrail.HandleOwnerDestroyed();
	}
    
    //stop nade and drop it on the ground
    Speed = 0;
    Velocity = Vect(0,0,0);
    SetPhysics(PHYS_Falling);
    LifeSpan = float(MaxHeals) * HealInterval + 1; //delete after healing is over

	PlaySound(ExplosionSound,,TransientSoundVolume);

	if( Role == ROLE_Authority ) {
        ExplodeLocation = Location;
        //bNeedToPlayEffects = true;
        AmbientSound=Sound'Inf_WeaponsTwo.smoke_loop';
        NetUpdateTime = Level.TimeSeconds - 1; // replicate ExplodeLocation to clients
        // PlayerController(Instigator.Controller).ClientMessage("Medic nade exploded on SERVER @ " @ ExplodeLocation);
    }

	if ( Level.NetMode != NM_DedicatedServer ) {
        GreenCloud = Spawn(GreenCloudClass,self,, HitLocation, rotator(vect(0,0,1)));
		Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
	}
    
    // LocalPlayer = Level.GetLocalPlayerController();
    // if ( LocalPlayer != None ) 
        // LocalPlayer.TeamMessage(LocalPlayer.PlayerReplicationInfo, "Medic nade exploded @ " @ HitLocation, 'Event'); 
}

simulated function Destroyed()
{
	if ( SmokeTrail != None )
		SmokeTrail.HandleOwnerDestroyed();
    if ( GreenCloud != none )     
        GreenCloud.Kill();         

	// if( !bHasExploded && !bHidden && !bDud )
		// Explode(Location,vect(0,0,1));
	// if( bHidden && !bDisintegrated )
        // Disintegrate(Location,vect(0,0,1));

    Super(ROBallisticProjectile).Destroyed();
}

simulated function Timer()
{
	local KFHumanPawn KFP;
	
    if( !bHidden ) {
        if( !bHasExploded ) {
			//search for wounded players in healing radius and explode immediately, if found any
			if ( ExplodeTimer > 0 && Speed < 100 ) {
				ExplodeTimer-= PlayerCheckRate;
				foreach CollidingActors( class'KFHumanPawn', KFP, DamageRadius, Location ) {
					if ( KFP.Health > 0 && KFP.Health < KFP.HealthMax ) {
						ExplodeTimer = 0; //explode now
						//PlayerController(KFP.Controller).ClientMessage("Medic nade found you");
						break;
					}
				}
			}
			//else ExplodeTimer-= PlayerCheckRate*0.5; //twice longer explosion time when flying fast
			
			if ( ExplodeTimer <= 0 ) {
				Explode(Location, vect(0,0,1));
				SetTimer(0, false);
			}
        }
    }
    else {
        AmbientSound=none;
        Destroy();
    }
}

simulated function Tick( float DeltaTime )
{
    if( bHasExploded && !bHidden && NextHealTime < Level.TimeSeconds ) {
        // show an emiter where healing actually is
        // if ( bHasExploded && Location != ExplodeLocation ) {
            // ExplodeLocation = Location;
            // if ( GreenCloud != none ) 
                // GreenCloud.SetLocation(Location);
            // NetUpdateTime = Level.TimeSeconds - 1; // replicate ExplodeLocation to clients
        // }

        HealRadius(Damage,DamageRadius, MyDamageType, MomentumTransfer, Location);
        NextHealTime = Level.TimeSeconds + HealInterval;

        if( ++TotalHeals >= MaxHeals ) {
            AmbientSound=none;
            HealingFinished();
            
            bHidden = true; // tell clients to destroy
            NetUpdateTime = Level.TimeSeconds - 1;
            SetTimer(0.1, false); //destroy on server after a short time
        }
    }
}


function BlowUp(vector HitLocation)
{
	MakeNoise(1.0);
}

function HealRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
	local KFHumanPawn Victim;
	local float damageScale;
	//local vector dir;
	local array<Pawn> CheckedPawns;
	local int i;
	local bool bAlreadyChecked;
	// Healing
	local KFPlayerReplicationInfo KFPRI;
	local int MedicReward;
	local float HealSum; // for modifying based on perks
    local float HealPotency;


    if ( Instigator==None || Instigator.Health<=0 ) {
        if ( !bDeleteMe )
            Destroy();
        return;
    }
    
	if ( bHurtEntry )
		return;

	bHurtEntry = true;
    
    // raise it half a meter to be sure it doesn't stuck inside a floor like bugged pipes
    HitLocation.Z = HitLocation.Z + 25; 
    
	foreach CollidingActors (class'KFHumanPawn', Victim, DamageRadius, HitLocation) {
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( Victim.Role < ROLE_Authority ) 
            continue; 
            
        damageScale = 1.0;

        if ( Instigator.Controller == None )
            Victim.SetDelayedDamageInstigatorController( InstigatorController );

        bAlreadyChecked = false;
        for (i = 0; i < CheckedPawns.Length; i++) {
            if (CheckedPawns[i] == Victim) {
                bAlreadyChecked = true;
                break;
            }
        }
        if( bAlreadyChecked )
            continue;

        CheckedPawns[CheckedPawns.Length] = Victim;

        // damageScale *= Victim.GetExposureTo(Location + 15 * -Normal(PhysicsVolume.Gravity));
        // if ( damageScale <= 0)
            // continue;

        if( Victim.Health > 0 && Victim.Health < Victim.HealthMax ) {
            KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
            HealPotency = 1.0;

            if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
                HealPotency = KFPRI.ClientVeteranSkill.Static.GetHealPotency(KFPRI);

            MedicReward = HealBoostAmount * HealPotency;
            HealSum = MedicReward;

            if ( (Victim.Health + Victim.healthToGive + MedicReward) > Victim.HealthMax )
                MedicReward = max(0, Victim.HealthMax - (Victim.Health + Victim.healthToGive));

            //used to set different health restore rate
            if ( ScrnHumanPawn(Victim) != none )
                ScrnHumanPawn(Victim).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency, InstigatorWeapon);
            else 
                Victim.GiveHealth(HealSum, Victim.HealthMax);
            
            // calculate total amount of health and unique player count
            HealedAmount += MedicReward;
            i = 0;
            while ( i < HealedPlayers.Length && HealedPlayers[i] != Victim ) 
                i++;
            if ( i == HealedPlayers.Length ) {
                HealedPlayers[i] = Victim;
            }
            
            if ( KFPRI != None )
            {
                if ( MedicReward > 0 && KFSteamStatsAndAchievements(KFPRI.SteamStatsAndAchievements) != none )
                {
                    KFSteamStatsAndAchievements(KFPRI.SteamStatsAndAchievements).AddDamageHealed(MedicReward);
                }

                // Give the medic reward money as a percentage of how much of the person's health they healed
                MedicReward = int((FMin(float(MedicReward),Victim.HealthMax)/Victim.HealthMax) * 60);

                if ( class'ScrnBalance'.default.Mut.bMedicRewardFromTeam && Victim.PlayerReplicationInfo != none && Victim.PlayerReplicationInfo.Team != none ) {
                    // give money from team budget
                    if ( Victim.PlayerReplicationInfo.Team.Score >= MedicReward ) {
                        Victim.PlayerReplicationInfo.Team.Score -= MedicReward;
                        KFPRI.Score += MedicReward;
                    }
                }
				else 
					KFPRI.Score += MedicReward;

                if ( KFHumanPawn(Instigator) != none )
                {
                    KFHumanPawn(Instigator).AlphaAmount = 255;
                }
            }
        }
    }
	bHurtEntry = false;
}

simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if( damageType == class'SirenScreamDamage')
    {
        Disintegrate(HitLocation, vect(0,0,1));
    }
}



function HealingFinished()
{
    if ( HealedAmount == 0 || Instigator == none )
        return;
        
    if ( HealedPlayers.Length >= MaxNumberOfPlayers && Instigator.PlayerReplicationInfo != none 
            && SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements) != none ) 
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements).Rep, 'ExplosionLove', 1);  
    
    SuccessfulHealMessage(HealedPlayers.length, HealedAmount);
}

function SuccessfulHealMessage(int HealedCount, int HealedAmount)
{
    if ( ScrnM79M(InstigatorWeapon) != none )
        ScrnM79M(InstigatorWeapon).ClientSuccessfulHeal(HealedPlayers.length, HealedAmount);
}


simulated function ProcessTouch( actor Other, vector HitLocation )
{
    if( bHasExploded ) //don't move nade if it's already exploded (healing)
        return;

    // ExtendedZCollision is attached to KFMonsters
    // KFBulletWhipAttachment is attached to KFPawns
    if ( ExtendedZCollision(Other) != none || ROBulletWhipAttachment(Other) != none )    
        return; // don't collide with this shit, cuz it is on server side only and screws clients
        
    if ( Pawn(Other) != none
            // || (ExtendedZCollision(Other)!=None && Pawn(Other.Owner)!=None) 
            // || (ROBulletWhipAttachment(Other) != none && Pawn(Other.Owner)!=None && Other.Owner != Instigator) 
        )
    {
        ExplodeTimer = 0;
        bTimerSet = true;
        SetTimer(0, false);
        Explode(Location, vect(0,0,1));
        //PlayerController(KFHumanPawn(Other).Controller).ClientMessage("Healing nade touched you");
        return;
    }

	// more realistic interactions with karma objects.
	if (Other.IsA('NetKActor'))
		KAddImpulse(Velocity,HitLocation,);

}

// Overridden to tweak the handling of the impact sound
simulated function HitWall( vector HitNormal, actor Wall )
{
    local Vector VNorm;
	local PlayerController PC;

    if ( ROBulletWhipAttachment(Wall) != none )    
        return; // don't collide with this shit, cuz it is on server side only and screws clients	
	/*
	if ( (Pawn(Wall) != None) || (GameObjective(Wall) != None) )
	{
		Explode(Location, HitNormal);
		return;
	}.*/

    // Reflect off Wall w/damping
    VNorm = (Velocity dot HitNormal) * HitNormal;
    Velocity = -VNorm * DampenFactor + (Velocity - VNorm) * DampenFactorParallel;

    RandSpin(100000);
    //DesiredRotation.Roll = 0;
    //RotationRate.Roll = 0;
    Speed = VSize(Velocity);
	
	if ( !bTimerSet ) {
        SetTimer(PlayerCheckRate, true); // start to check wounded players nearby or explode when ExplodeTimer is reached 
        bTimerSet = true;
	}
	
    if ( GreenCloud != none ) 
        GreenCloud.SetLocation(Location);

    if ( Speed < 20 )
    {
        bBounce = False;
        PrePivot.Z = -1.5;
		//Speed = 0;
		//SetPhysics(PHYS_Falling);
		DesiredRotation = Rotation;
		DesiredRotation.Pitch = 0;
		DesiredRotation.Roll = 0;
		SetRotation(DesiredRotation);
		bRotateToDesired=false;

    }
    else
    {
		if ( (Level.NetMode != NM_DedicatedServer) && (Speed > 500) )
			PlaySound(ImpactSound, SLOT_Misc );
		//else
		//{
			bFixedRotationDir = false;
			DesiredRotation = Rotation;
			DesiredRotation.Pitch = 0;
			DesiredRotation.Roll = 0;
			bRotateToDesired = true;
			RotationRate.Pitch = 50000;
			RotationRate.Roll = 50000;
		//}
        if ( HitEffectClass != none && !Level.bDropDetail && (Level.DetailMode != DM_Low) && (Level.TimeSeconds - LastSparkTime > 0.5) && EffectIsRelevant(Location,false) )
        {
			PC = Level.GetLocalPlayerController();
			if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 6000 )
				Spawn(HitEffectClass,,, Location, Rotator(HitNormal));
            LastSparkTime = Level.TimeSeconds;
        }
    }
}


/*
static function PreloadAssets()
{
	default.ExplosionSound = sound(DynamicLoadObject(default.ExplosionSoundRef, class'Sound', true));
	default.DisintegrateSound = sound(DynamicLoadObject(default.DisintegrateSoundRef, class'Sound', true));

	UpdateDefaultStaticMesh(StaticMesh(DynamicLoadObject(default.StaticMeshRef, class'StaticMesh', true)));
}

static function bool UnloadAssets()
{
	default.ExplosionSound = none;
	default.DisintegrateSound = none;

	UpdateDefaultStaticMesh(none);

	return true;
}
*/


defaultproperties
{
    HealBoostAmount=8
    MaxHeals=8
    HealInterval=1.000000
    MaxNumberOfPlayers=6
    ExplodeTimer=3.000000
    PlayerCheckRate=0.500000
    DampenFactor=0.500000
    DampenFactorParallel=0.800000
    ArmDistSquared=1.000000
    StraightFlightTime=0.000000
    StaticMeshRef="KF_pickups5_Trip.nades.MedicNade_Pickup"
    ExplosionSoundRef="KF_GrenadeSnd.NadeBase.MedicNade_Explode"
    Speed=1000.000000
    MaxSpeed=1250.000000
    Damage=1.000000
    DamageRadius=200.000000
    MyDamageType=Class'KFMod.DamTypeMedicNade'
    ExplosionDecal=Class'KFMod.MedicNadeDecal'
    LifeSpan=15
    SoundVolume=150
    SoundRadius=100.000000
    TransientSoundRadius=200.000000
    bBounce=True
    GreenCloudClass=Class'ScrnBalanceSrv.ScrnNadeHealing'

    
    // damned, why ExplodeLocation isn't replicated?!!!
    RemoteRole=ROLE_SimulatedProxy
    bSkipActorPropertyReplication=false
    bReplicateMovement=true
    bUpdateSimulatedPosition=true    
    bNetNotify=true
    bAlwaysRelevant=true
    bOnlyRelevantToOwner=false

	//DrawScale=2.3
	DrawScale=2.0

	IntitialRotationAdjustment=(Pitch=-8192,Roll=16384)
}
