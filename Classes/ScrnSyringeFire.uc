class ScrnSyringeFire extends SyringeFire;

var transient float PendingHealTime;

Function Timer()
{
	local KFPlayerReplicationInfo PRI;
	local int MedicReward;
	local KFHumanPawn Healed;
	local float HealSum, HealPotency; // for modifying based on perks

	PRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
	Healed = CachedHealee;
    HealPotency = 1.0;
	CachedHealee = none;

	if ( Healed != none && Healed.Health > 0 && Healed != Instigator )
	{
        Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);

		if ( PRI != none && PRI.ClientVeteranSkill != none )
			HealPotency = PRI.ClientVeteranSkill.Static.GetHealPotency(PRI);

		if ( Weapon.Level.Game.NumPlayers == 1 )
			HealSum = 50;
		else
			HealSum = Syringe(Weapon).HealBoostAmount;
		
		HealSum	*= HealPotency;
		MedicReward = HealSum;

		if ( (Healed.Health + Healed.healthToGive + MedicReward) > Healed.HealthMax )
		{
			MedicReward = Healed.HealthMax - (Healed.Health + Healed.healthToGive);
			if ( MedicReward < 0 )
			{
				MedicReward = 0;
			}
		}

        if ( ScrnHumanPawn(Healed) != none )
            ScrnHumanPawn(Healed).TakeHealing(ScrnHumanPawn(Instigator), HealSum, HealPotency, KFWeapon(Instigator.Weapon));
        else 
            Healed.GiveHealth(HealSum, Healed.HealthMax);            

		// Tell them we're healing them
		PlayerController(Instigator.Controller).Speech('AUTO', 5, "");
		LastHealMessageTime = Level.TimeSeconds;

		if ( PRI != None )
		{
			if ( MedicReward > 0 && KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements) != none )
			{
				KFSteamStatsAndAchievements(PRI.SteamStatsAndAchievements).AddDamageHealed(MedicReward);
			}

            // Give the medic reward money as a percentage of how much of the person's health they healed
			MedicReward = int((FMin(float(MedicReward),Healed.HealthMax)/Healed.HealthMax) * 60); // Increased to 80 in Balance Round 6, reduced to 60 in Round 7

            if ( class'ScrnBalance'.default.Mut.bMedicRewardFromTeam && Healed.PlayerReplicationInfo != none && Healed.PlayerReplicationInfo.Team != none ) {
                // give money from team budget
                if ( Healed.PlayerReplicationInfo.Team.Score >= MedicReward ) {
                    Healed.PlayerReplicationInfo.Team.Score -= MedicReward;
                    PRI.Score += MedicReward;
                }
            }
			else 
				PRI.Score += MedicReward;

			if ( KFHumanPawn(Instigator) != none )
			{
				KFHumanPawn(Instigator).AlphaAmount = 255;
			}
		}
	}
}

function KFHumanPawn GetHealee()
{
	local KFHumanPawn KFHP, BestKFHP;
	local vector Dir;
	local float TempDot, BestDot;

	Dir = vector(Instigator.GetViewRotation());

	foreach Instigator.VisibleCollidingActors(class'KFHumanPawn', KFHP, 80.0)
	{
		if ( KFHP.Health < KFHP.HealthMax && KFHP.Health > 0 )
		{
			TempDot = Dir dot (KFHP.Location - Instigator.Location);
			if ( TempDot > 0.7 && TempDot > BestDot )
			{
				BestKFHP = KFHP;
				BestDot = TempDot;
			}
		}
	}

	return BestKFHP;
}

function float GetFireSpeed()
{
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		return KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetFireSpeedMod(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), Weapon);
	}

	return 1;
}

// client side only! On server will called AttemptHeal(), which will call super.ModeDoFire() 
event ModeDoFire()
{
	local float Rec;

	if (!AllowFire())
		return;

	if ( Weapon.Role < ROLE_Authority ) {
		if ( Level.TimeSeconds < PendingHealTime )
			return;
		PendingHealTime = Level.TimeSeconds + InjectDelay + 0.05;
		
		// now medic has syring heal bonus
		Rec = GetFireSpeed();
		FireRate = default.FireRate/Rec;
		FireAnimRate = default.FireAnimRate*Rec;
		InjectDelay = default.InjectDelay/Rec;
	}

	Super.ModeDoFire();
}

// this is executing only on server side
function AttemptHeal()
{
	local float Rec;
	
	if (!AllowFire())
		return;

	// AttemptHeal() should be executing on server side only, but who knows what TWI will screw up next?
	if ( Weapon.Role == ROLE_Authority ) {
		if ( Level.TimeSeconds < PendingHealTime )
			return;
		PendingHealTime = Level.TimeSeconds + InjectDelay + 0.05;
		
		Rec = GetFireSpeed();
		FireRate = default.FireRate/Rec;
		FireAnimRate = default.FireAnimRate*Rec;
		InjectDelay = default.InjectDelay/Rec;	
	}

	Super.AttemptHeal();	
}

defaultproperties
{
}
