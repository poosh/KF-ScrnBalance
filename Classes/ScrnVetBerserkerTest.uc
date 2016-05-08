class ScrnVetBerserkerTest extends ScrnVetBerserker
	abstract;
 

// have a health boost instead of damage resistance
static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( DmgType == class'DamTypeVomit' )
	{
		switch ( GetClientVeteranSkillLevel(KFPRI) )
		{
			case 0:
				return float(InDamage) * 0.90;
			case 1:
				return float(InDamage) * 0.78;
			case 2:
				return float(InDamage) * 0.72;
			case 3:
				return float(InDamage) * 0.58;
			case 4:
				return float(InDamage) * 0.43;
			case 5:
				return float(InDamage) * 0.35;
			default:
				return float(InDamage) * 0.30; // 70% reduced Bloat Bile damage
		}
	}

	return float(InDamage);
}


// give a health boost instead of damage resistance
// 10hp per level up to 150 @ L4
// 175hp @ L5
// 200hp @ L6
// 5hp per level above L6
static function float HealthMaxMult(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    if ( GetClientVeteranSkillLevel(KFPRI) <= 4)
        return 1.10 + 0.10 * GetClientVeteranSkillLevel(KFPRI);
    else if ( GetClientVeteranSkillLevel(KFPRI) == 5)
        return 1.75;   
    else if ( GetClientVeteranSkillLevel(KFPRI) == 6)
        return 2.00;   
    //level 7+
    return 2.00 + 0.05 * (GetClientVeteranSkillLevel(KFPRI) - 6);
}


static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    local int wounded_hp;

    super.AddDefaultInventory(KFPRI, P);
    
    wounded_hp = P.HealthMax - P.Health;
    // call to adjust HealthMax
    P.GiveHealth(0, P.HealthMax);
    // raise health by boost, but don't lower it
    P.Health = max(P.Health, P.HealthMax - wounded_hp);
}


static function string GetCustomLevelInfo( byte Level )
{
	local string S;
	local byte BonusLevel;

	BonusLevel = GetBonusLevel(Level);
	S = super.GetCustomLevelInfo(BonusLevel);
	
	ReplaceText(S,"%L",string(BonusLevel+6));
	ReplaceText(S,"%h",GetPercentStr(1.0 + 0.05*float(BonusLevel-6)));
	return S;
}

defaultproperties
{
     CustomLevelInfo="*** BONUS LEVEL %L|%s extra melee damage|%m faster melee attacks|30% faster melee movement|70% less damage from Bloat Bile|%h more health|%d discount on Melee Weapons|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     SRLevelEffects(0)="*** BONUS LEVEL 0|10% extra melee damage|5% faster melee movement|10% less damage from Bloat Bile|10% more health|10% discount on Melee Weapons|Can't be grabbed by Clots"
     SRLevelEffects(1)="*** BONUS LEVEL 1|20% extra melee damage|5% faster melee attacks|10% faster melee movement|22% less damage from Bloat Bile|20% more health|20% discount on Melee Weapons|Can't be grabbed by Clots"
     SRLevelEffects(2)="*** BONUS LEVEL 2|40% extra melee damage|10% faster melee attacks|15% faster melee movement|28% less damage from Bloat Bile|30% more health|30% discount on Melee Weapons|Can't be grabbed by Clots|Zed-Time can be extended by killing an enemy while in slow motion"
     SRLevelEffects(3)="*** BONUS LEVEL 3|60% extra melee damage|10% faster melee attacks|20% faster melee movement|42% less damage from Bloat Bile|40% more health|40% discount on Melee Weapons|Can't be grabbed by Clots|Up to 2 Zed-Time Extensions"
     SRLevelEffects(4)="*** BONUS LEVEL 4|80% extra melee damage|15% faster melee attacks|20% faster melee movement|47% less damage from Bloat Bile|50% more health|50% discount on Melee Weapons|Can't be grabbed by Clots|Up to 3 Zed-Time Extensions"
     SRLevelEffects(5)="*** BONUS LEVEL 5|100% extra melee damage|20% faster melee attacks|20% faster melee movement|65% less damage from Bloat Bile|75% more health|60% discount on Melee Weapons|Spawn with an Axe|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     SRLevelEffects(6)="*** BONUS LEVEL 6|100% extra melee damage|25% faster melee attacks|30% faster melee movement|70% less damage from Bloat Bile|100% more health|70% discount on Melee Weapons|Spawn with a Chainsaw|Can't be grabbed by Clots|Up to 4 Zed-Time Extensions"
     VeterancyName="BerserkerT"
}
