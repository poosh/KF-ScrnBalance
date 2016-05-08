class ScrnM99Bullet extends M99Bullet;

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	local vector X,End,HL,HN;
	local Vector TempHitLocation, HitNormal;
	local array<int>	HitPoints;
    local KFPawn HitPawn;
	local bool	bHitWhipAttachment;
    local int AdjustedDamage;

	if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces || Other==IgnoreImpactPawn ||
        (IgnoreImpactPawn != none && Other.Base == IgnoreImpactPawn) )
		return;

	X =  Vector(Rotation);
    AdjustedDamage = Damage;

 	if( ROBulletWhipAttachment(Other) != none )
	{
        // hit other player
    	bHitWhipAttachment=true;

        if(!Other.Base.bDeleteMe) {
	        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (65535 * X), HitPoints, HitLocation,, 1);

			if( Other == none || HitPoints.Length == 0 )
				return;

			HitPawn = KFPawn(Other);

            if (Role == ROLE_Authority) {
    	    	if ( HitPawn != none ) {
     				// Hit detection debugging
    				/*log("Bullet hit "$HitPawn.PlayerReplicationInfo.PlayerName);
    				HitPawn.HitStart = HitLocation;
    				HitPawn.HitEnd = HitLocation + (65535 * X);*/

                    if( !HitPawn.bDeleteMe )
                    	HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);

        			Damage/=1.25;
        			Velocity*=0.85;

                    IgnoreImpactPawn = HitPawn;

            		if( Level.NetMode!=NM_Client )
            			PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);

                    // Hit detection debugging
    				/*if( Level.NetMode == NM_Standalone)
    					HitPawn.DrawBoneLocation();*/

    				 return;
    	    	}
    		}
		}
		else
			return;
	}

    if ( ExtendedZCollision(Other) != None)    
        IgnoreImpactPawn = Pawn(Other.Owner);
    else
        IgnoreImpactPawn = Pawn(Other);
        
    if ( IgnoreImpactPawn != none && class'ScrnBalance'.default.Mut.bWeaponFix ) {
        if ( ZombieFleshpound(IgnoreImpactPawn) != none )
            AdjustedDamage *= 0.7; // It will be multiplied by 0.5 in ZombieFleshpound.TakeDamage(), ending up with 0.35
        else if (ZombieBoss(IgnoreImpactPawn) != none )
             AdjustedDamage *= 0.8; // 20% resistance to Pat
        else if ( Level.Game.GameDifficulty >= 5.0 && ZombieScrake(IgnoreImpactPawn) != none )
            AdjustedDamage *= 0.5;
    }        
        
	if( Level.NetMode!=NM_Client )
		PlayhitNoise(IgnoreImpactPawn!=none && IgnoreImpactPawn.ShieldStrength>0);
        
	if( Physics==PHYS_Projectile && IgnoreImpactPawn!=None && Vehicle(IgnoreImpactPawn)==None ) {
		if( IgnoreImpactPawn.IsHeadShot(HitLocation, X, 1.0) ) {
            // achievement
            if ( Role == ROLE_authority && ZombieScrake(IgnoreImpactPawn) != none && IgnoreImpactPawn.Velocity != vect(0,0,0) && IgnoreImpactPawn.IsInState('RunningState') ) {
                if ( Instigator != none && Instigator.PlayerReplicationInfo != none && SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements) != none )
                    class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(SRStatsBase(Instigator.PlayerReplicationInfo.SteamStatsAndAchievements).Rep, 'M99Kill3SC', 1);  
            }
			Other.TakeDamage(AdjustedDamage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
        }
		else {
            Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
        }
		Damage/=1.25;
		Velocity*=0.85;
		Return;
	}

    
	if( Level.NetMode!=NM_DedicatedServer && SkeletalMesh(Other.Mesh)!=None && Other.DrawType==DT_Mesh && Pawn(Other)!=None )
	{ // Attach victim to the wall behind if it dies.
		End = Other.Location+X*600;
		if( Other.Trace(HL,HN,End,Other.Location,False)!=None )
			Spawn(Class'BodyAttacher',Other,,HitLocation).AttachEndPoint = HL-HN;
	}
	//Stick(Other,HitLocation);
	if( Level.NetMode!=NM_Client )
	{
		if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
			Pawn(Other).TakeDamage(AdjustedDamage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
		else 
            Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
	}
}

defaultproperties
{
     HeadShotDamageMult=3.000000
     Damage=800.000000
	 DamageRadius=0
}
