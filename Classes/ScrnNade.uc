class ScrnNade extends Nade;

var int ScrakeUnstunDamageThreshold;
var bool bBlewInHands; 

simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;
    local int NumKilled;
    local KFMonster KFMonsterVictim;
    local bool bMonster;
    local Pawn P;
    local KFPawn KFP;
    local array<Pawn> CheckedPawns;
    local int i;
    local bool bAlreadyChecked;
    local SRStatsBase Stats;


    if ( bHurtEntry )
        return;

    bHurtEntry = true;
    
    if( Role == ROLE_Authority && Instigator != none && Instigator.PlayerReplicationInfo != none )
        Stats = SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements);
        
    foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        P = none;
        KFMonsterVictim = none;
        bMonster = false;
        KFP = none;
        bAlreadyChecked = false;

        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
            && ExtendedZCollision(Victims)==None )
        {
            if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
                Continue;
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);

            if ( Instigator == None || Instigator.Controller == None )
            {
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            }

            P = Pawn(Victims);
            if( P != none ) {
                for (i = 0; i < CheckedPawns.Length; i++) {
                    if (CheckedPawns[i] == P) {
                        bAlreadyChecked = true;
                        break;
                    }
                }
                if( bAlreadyChecked )
                    continue;
                CheckedPawns[CheckedPawns.Length] = P;

                KFMonsterVictim = KFMonster(Victims);
                if( KFMonsterVictim != none && KFMonsterVictim.Health <= 0 )
                    KFMonsterVictim = none;

                KFP = KFPawn(Victims);

                if( KFMonsterVictim != none ) {
                    damageScale *= KFMonsterVictim.GetExposureTo(Location + 15 * -Normal(PhysicsVolume.Gravity));
                    bMonster = true; // in case TakeDamage() and further Die() deletes the monster
                }
                else if( KFP != none ) {
                    damageScale *= KFP.GetExposureTo(Location + 15 * -Normal(PhysicsVolume.Gravity));
                }

                if ( damageScale <= 0)
                    continue;

                // Scrake Nader ach    
                if ( Role == ROLE_Authority && KFMonsterVictim != none && ZombieScrake(KFMonsterVictim) != none ) {
                    // need to check Scrake's stun before dealing damage, because he can unstun by himself from damage received
                    ScrakeNader(damageScale * DamageAmount, ZombieScrake(KFMonsterVictim), Stats);
                }
            }
            Victims.TakeDamage(damageScale * DamageAmount,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir
                ,(damageScale * Momentum * dir), DamageType);

            if( bMonster && (KFMonsterVictim == none || KFMonsterVictim.Health < 1) ) {
                NumKilled++;
            }

            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            {
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
            }
        }
    }
    
    if( Role == ROLE_Authority )
    {
        if ( bBlewInHands && NumKilled >= 5 && Stats != none ) 
            class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(Stats.Rep, 'SuicideBomber', 1);  

        if ( NumKilled >= 4 )
        {
            KFGameType(Level.Game).DramaticEvent(0.05);
        }
        else if ( NumKilled >= 2 )
        {
            KFGameType(Level.Game).DramaticEvent(0.03);
        }
    }

    bHurtEntry = false;
}

//grant achievement for nading stunned Scrakes
function ScrakeNader(int DamageAmount, ZombieScrake Scrake, SRStatsBase Stats)
{
    local name  Sequence;
    local float Frame, Rate;
    
    if ( Scrake == none || Stats == none || DamageAmount < ScrakeUnstunDamageThreshold )
        return;

    Scrake.GetAnimParams(Scrake.ExpectingChannel, Sequence, Frame, Rate);
    if ( Scrake.bShotAnim && (Sequence == 'KnockDown' || Sequence == 'SawZombieIdle') ) {
        //break the stun
        Scrake.bShotAnim= false;
        Scrake.SetAnimAction(Scrake.WalkAnims[0]);
        SawZombieController(Scrake.Controller).GoToState('ZombieHunt');        
        //progress achievement
        class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(Stats.Rep, 'ScrakeNader', 1);
        //mark Scrake as naded in game rules
        if ( ScrnHumanPawn(Instigator) != none && ScrnPlayerController(Instigator.Controller) != none )
            ScrnPlayerController(Instigator.Controller).Mut.GameRules.ScrakeNaded(Scrake);
            
    }
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController  LocalPlayer;
    local Projectile P;
    local byte i;

    bHasExploded = True;
    BlowUp(HitLocation);

    // null reference fix
    if ( ExplodeSounds.length > 0 )
        PlaySound(ExplodeSounds[rand(ExplodeSounds.length)],,2.0);

    // Shrapnel
    for( i=Rand(6); i<10; i++ )
    {
        P = Spawn(ShrapnelClass,,,,RotRand(True));
        if( P!=None )
            P.RemoteRole = ROLE_None;
    }
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    Destroy();
}

defaultproperties
{
     ScrakeUnstunDamageThreshold=50
     
     ExplodeSounds(0)=SoundGroup'KF_GrenadeSnd.Nade_Explode_1'
     ExplodeSounds(1)=SoundGroup'KF_GrenadeSnd.Nade_Explode_2'
     ExplodeSounds(2)=SoundGroup'KF_GrenadeSnd.Nade_Explode_3'
}
