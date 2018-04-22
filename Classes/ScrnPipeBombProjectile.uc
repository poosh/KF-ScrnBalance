class ScrnPipeBombProjectile extends PipeBombProjectile;

static function PreloadAssets()
{
    //default.ExplodeSounds[0] = sound(DynamicLoadObject(default.ExplodeSoundRefs[0], class'Sound', true));

    UpdateDefaultStaticMesh(StaticMesh(DynamicLoadObject(default.StaticMeshRef, class'StaticMesh', true)));
}

static function bool UnloadAssets()
{
    //default.ExplodeSounds[0] = none;

    UpdateDefaultStaticMesh(none);

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

function Timer()
{
    local Pawn CheckPawn;
    local float ThreatLevel;
    local vector DetectLocation;
    local bool bSameTeam; //pawn is from the same team as instigator

    DetectLocation = Location;
    DetectLocation.Z += 25; // raise a detection poin half a meter up to prevent small objects on the ground bloking the trace

    if( !bHidden && !bTriggered )
    {
        if( ArmingCountDown >= 0 )
        {
            ArmingCountDown -= 0.1;
            if( ArmingCountDown <= 0 )
            {
                SetTimer(1.0,True);
            }
        }
        else
        {
            // Check for enemies
            if( !bEnemyDetected )
            {
                bAlwaysRelevant=false;
                PlaySound(BeepSound,,0.5,,50.0);

                foreach VisibleCollidingActors( class 'Pawn', CheckPawn, DetectionRadius, DetectLocation )
                {
                    // don't trigger pipes on NPC  -- PooSH
                    bSameTeam = KF_StoryNPC(CheckPawn) != none
                        || (CheckPawn.PlayerReplicationInfo != none && CheckPawn.PlayerReplicationInfo.Team.TeamIndex == PlacedTeam);
                    if( CheckPawn == Instigator
                        || (bSameTeam && KFGameType(Level.Game).FriendlyFireScale > 0) )
                    {
                        // Make the thing beep if someone on our team is within the detection radius
                        // This gives them a chance to get out of the way
                        ThreatLevel += 0.001;
                    }
                    else
                    {
                        if( CheckPawn.Health > 0 //don't trigger pipes by dead bodies  -- PooSH
                            && CheckPawn != Instigator && CheckPawn.Role == ROLE_Authority
                            && !bSameTeam )
                        {
                            if( KFMonster(CheckPawn) != none )
                            {
                                ThreatLevel += KFMonster(CheckPawn).MotionDetectorThreat;
                                if( ThreatLevel >= ThreatThreshhold )
                                {
                                    bEnemyDetected=true;
                                    SetTimer(0.15,True);
                                }
                            }
                            else
                            {
                                bEnemyDetected=true;
                                SetTimer(0.15,True);
                            }
                        }
                    }

                }

                if( ThreatLevel >= ThreatThreshhold )
                {
                    bEnemyDetected=true;
                    SetTimer(0.15,True);
                }
                else if( ThreatLevel > 0 )
                {
                    SetTimer(0.5,True);
                }
                else
                {
                    SetTimer(1.0,True);
                }
            }
            // Play some fast beeps and blow up
            else
            {
                bAlwaysRelevant=true;
                Countdown--;

                if( CountDown > 0 )
                {
                    PlaySound(BeepSound,SLOT_Misc,2.0,,150.0);
                }
                else
                {
                    Explode(DetectLocation, vector(Rotation));
                }
            }
        }
    }
    else
    {
        Destroy();
    }
}


// copy-pasted, adding ScrN achievements
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;
    local int NumKilled;
    local KFMonster KFMonsterVictim;
    local Pawn P;
    local KFPawn KFP;
    local array<Pawn> CheckedPawns;
    local int i;
    local bool bAlreadyChecked;

    local bool bDamagedInstigator, bKilledCrawler;
    local byte NumKilledFP; // number of Fleshpounds killed by this exposion
    local SRStatsBase Stats;
    local bool bMonster, bFP, bCrawler;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;

    if ( Instigator != none && Instigator.PlayerReplicationInfo != none )
        Stats = SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements);


    foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
         && ExtendedZCollision(Victims)==None )
        {
            if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
                Continue;

            P = none;
            KFMonsterVictim = none;
            KFP = none;
            bMonster = false;
            bFP = false;
            bCrawler = false;

            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

            if ( Instigator == None || Instigator.Controller == None )
            {
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            }

            P = Pawn(Victims);

            if( P != none )
            {
                bAlreadyChecked = false;
                for (i = 0; i < CheckedPawns.Length; i++)
                {
                    if (CheckedPawns[i] == P)
                    {
                        bAlreadyChecked = true;
                        break;
                    }
                }

                if( bAlreadyChecked )
                    continue;


                KFMonsterVictim = KFMonster(Victims);

                if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
                {
                    KFMonsterVictim = none;
                }

                KFP = KFPawn(Victims);

                if( KFMonsterVictim != none )
                {
                    bMonster = true;
                    bFP = ZombieFleshpound(KFMonsterVictim) != none || KFMonsterVictim.IsA('FemaleFP');
                    bCrawler = ZombieCrawler(KFMonsterVictim) != none;

                    damageScale *= KFMonsterVictim.GetExposureTo(Location + 15 * -Normal(PhysicsVolume.Gravity));
                }
                else if( KFP != none )
                {
                    damageScale *= KFP.GetExposureTo(Location + 15 * -Normal(PhysicsVolume.Gravity));
                    // Reduce damage to poeple so I can make the damage radius a bit bigger for killing zeds
                    damageScale *= 0.5;
                    if ( KFP == Instigator && damageScale * DamageAmount > 0 )
                        bDamagedInstigator = true;
                }

                CheckedPawns[CheckedPawns.Length] = P;

                if ( damageScale <= 0)
                    continue;
            }

            Victims.TakeDamage(damageScale * DamageAmount,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius)
             * dir,(damageScale * Momentum * dir),DamageType);

            if( Role == ROLE_Authority && bMonster && (KFMonsterVictim == none || KFMonsterVictim.Health <= 0 ) )
            {
                NumKilled++;
                if ( bFP )
                    NumKilledFP++;
                else
                    bKilledCrawler = bKilledCrawler || bCrawler;
            }

            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            {
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
            }
        }
    } //foreach

    if( Role == ROLE_Authority )
    {
        if ( Stats != none ) {
            if (NumKilled >= 10)
                Stats.Killed10ZedsWithPipebomb();

            // ScrN Achievements
            if ( bDamagedInstigator && NumKilledFP > 0 )
                class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(Stats.Rep, 'MindBlowingSacrifice', NumKilledFP);
            if ( bKilledCrawler && NumKilled == 1 )
                class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(Stats.Rep, 'Overkill3', 1);
            if ( bDamagedInstigator && (Instigator == none || Instigator.Health <= 0) )
                class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(Stats.Rep, 'MadeinChina', 1);
        }

        if( NumKilled >= 4 )
        {
            KFGameType(Level.Game).DramaticEvent(0.05);
        }
        else if( NumKilled >= 2 )
        {
            KFGameType(Level.Game).DramaticEvent(0.03);
        }
    }

    bHurtEntry = false;
}

defaultproperties
{
    ExplodeSounds(0)=SoundGroup'Inf_Weapons.antitankmine.antitankmine_explode01'
}
