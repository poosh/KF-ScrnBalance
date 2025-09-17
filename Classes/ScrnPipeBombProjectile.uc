class ScrnPipeBombProjectile extends PipeBombProjectile;

var() bool bDetectEnemies;
var transient int NumKilled, NumKilledFP, NumKilledCR;
var transient bool bDamagedInstigator;
var class<ScrnExplosiveFunc> Func;

static function PreloadAssets()
{
}

static function bool UnloadAssets()
{
    return true;
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
    if ( bTriggered || Damage < 5 )
        return;

    if ( Monster(InstigatedBy) == none && class<KFWeaponDamageType>(damageType) != none && class<KFWeaponDamageType>(damageType).default.bDealBurningDamage )
        return; // make pipebombs immune to fire, unless instigated by monsters

    super.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, damageType, HitIndex);
}

simulated function Disintegrate(vector HitLocation, vector HitNormal)
{
    if ( bHidden || bHasExploded )
        return;
    super.Disintegrate(HitLocation, HitNormal);
}

function Timer()
{
    local Pawn CheckPawn;
    local float ThreatLevel;
    local vector DetectLocation;
    local bool bSameTeam; //pawn is from the same team as instigator

    DetectLocation = Location;
    DetectLocation.Z += 25; // raise a detection poin half a meter up to prevent small objects on the ground bloking the trace

    if ( bHidden || bTriggered ) {
        Destroy();
        return;
    }

    if( ArmingCountDown >= 0 ) {
        ArmingCountDown -= 0.1;
        if( ArmingCountDown <= 0 ) {
            SetTimer(1.0,True);
        }
    }
    else if( bEnemyDetected ) {
        bAlwaysRelevant=true;

        if( --CountDown > 0 ) {
            PlaySound(BeepSound,SLOT_Misc,2.0,,150.0);
        }
        else{
            Explode(DetectLocation, vector(Rotation));
        }
    }
    else if (bDetectEnemies) {
        bAlwaysRelevant=false;
        PlaySound(BeepSound,,0.5,,50.0);

        foreach VisibleCollidingActors( class'Pawn', CheckPawn, DetectionRadius, DetectLocation ) {
            // don't trigger pipes on NPC  -- PooSH
            bSameTeam = KF_StoryNPC(CheckPawn) != none
                || (CheckPawn.PlayerReplicationInfo != none
                    && CheckPawn.PlayerReplicationInfo.Team.TeamIndex == PlacedTeam);
            if( CheckPawn == Instigator || (bSameTeam && KFGameType(Level.Game).FriendlyFireScale > 0) ) {
                // Make the thing beep if someone on our team is within the detection radius
                // This gives them a chance to get out of the way
                ThreatLevel += 0.001;
            }
            else {
                if( CheckPawn.Health > 0 //don't trigger pipes by dead bodies  -- PooSH
                    && CheckPawn != Instigator && CheckPawn.Role == ROLE_Authority
                    && !bSameTeam )
                {
                    if( KFMonster(CheckPawn) != none ) {
                        ThreatLevel += KFMonster(CheckPawn).MotionDetectorThreat;
                    }
                    else {
                        ThreatLevel = ThreatThreshhold;
                    }
                }
            }
        }

        if ( ThreatLevel >= ThreatThreshhold ) {
            bEnemyDetected = true;
            SetTimer(0.15, true);
        }
        else if( ThreatLevel > 0 ) {
            SetTimer(0.5, true);
        }
        else {
            SetTimer(1.0, true);
        }
    }
}


simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
    local SRStatsBase Stats;

    if ( bHurtEntry )
        return;

    if (Role == ROLE_Authority && Instigator != none && Instigator.PlayerReplicationInfo != none )
        Stats = SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements);

    NumKilled = Func.static.HurtRadius(self, DamageAmount, DamageRadius, DamageType, Momentum, HitLocation, true);

    if (NumKilled == 0 || Stats == none)
        return;

    if (NumKilled >= 10)
        Stats.Killed10ZedsWithPipebomb();

    // ScrN Achievements
    if (bDamagedInstigator && NumKilledFP > 0)
        class'ScrnAchCtrl'.static.ProgressAchievementByID(Stats.Rep, 'MindBlowingSacrifice', NumKilledFP);
    if (NumKilledCR == 1 && NumKilled == 1)
        class'ScrnAchCtrl'.static.ProgressAchievementByID(Stats.Rep, 'Overkill3', 1);
    if (bDamagedInstigator && (Instigator == none || Instigator.Health <= 0))
        class'ScrnAchCtrl'.static.ProgressAchievementByID(Stats.Rep, 'MadeinChina', 1);
}

defaultproperties
{
    // sound and mesh already statically linked elsewhere - dynamic load is redundant
    ExplodeSounds(0)=SoundGroup'Inf_Weapons.antitankmine.antitankmine_explode01'
    StaticMesh=StaticMesh'KF_pickups2_Trip.Supers.Pipebomb_Pickup'
    StaticMeshRef="KF_pickups2_Trip.Supers.Pipebomb_Pickup"  // unused
    bDetectEnemies=True
    Func=class'ScrnExplosiveFunc_Pipebomb'
}
