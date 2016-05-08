class ScrnVetFirebugTest extends ScrnVetFirebug
	abstract;


static function int ReduceDamage(KFPlayerReplicationInfo KFPRI, KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType)
{
	if ( class<DamTypeBurned>(DmgType) != none || class<DamTypeFlamethrower>(DmgType) != none 
            || (class<KFWeaponDamageType>(DmgType) != none && class<KFWeaponDamageType>(DmgType).default.bDealBurningDamage) 
        )
        return float(InDamage) * fmax(0.1, (0.60 - (0.10 * float(GetClientVeteranSkillLevel(KFPRI))))); // 90% fire resistance max
	return InDamage;
}

/*
static function AddDefaultInventory(KFPlayerReplicationInfo KFPRI, Pawn P)
{
    super(ScrnVeterancyTypes).AddDefaultInventory(KFPRI, P);
    
    if ( GetClientVeteranSkillLevel(KFPRI) == 5 )
        KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnMAC10MP", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnMAC10Pickup'));
    else if ( GetClientVeteranSkillLevel(KFPRI) >= 6 ) {
        KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnFlameThrower", GetInitialCostScaling(KFPRI, class'ScrnBalanceSrv.ScrnFlamethrowerPickup'));
		//REMOVE BEFORE RELEASE
        //KFHumanPawn(P).CreateInventoryVeterancy("ScrnBalanceSrv.ScrnFlareRevolver", 0);
	}
}
*/

defaultproperties
{
     CustomLevelInfo="*** BONUS LEVEL %L|%s extra flame weapon damage|%m faster Flamethrower reload|%m faster Husk Gun charging|%s more flame weapon ammo|90% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|%d discount on flame weapons|Spawn with a Flamethrower"
     SRLevelEffects(0)="*** BONUS LEVEL 0|5% extra flame weapon damage|40% resistance to fire|10% discount on the flame weapons"
     SRLevelEffects(1)="*** BONUS LEVEL 1|10% extra flame weapon damage|10% faster Flamethrower reload|10% faster Husk Gun charging|10% more flame weapon ammo|50% resistance to fire|20% discount on flame weapons"
     SRLevelEffects(2)="*** BONUS LEVEL 2|20% extra flame weapon damage|20% faster Flamethrower reload|20% faster Husk Gun charging|20% more flame weapon ammo|60% resistance to fire|30% discount on flame weapons"
     SRLevelEffects(3)="*** BONUS LEVEL 3|30% extra flame weapon damage|30% faster Flamethrower reload|30% faster Husk Gun charging|30% more flame weapon ammo|70% resistance to fire|50% extra Flamethrower range|Grenades set enemies on fire|40% discount on flame weapons"
     SRLevelEffects(4)="*** BONUS LEVEL 4|40% extra flame weapon damage|40% faster Flamethrower reload|40% faster Husk Gun charging|40% more flame weapon ammo|80% resistance to fire|50% extra Flamethrower range|Grenades set enemies on fire|50% discount on flame weapons"
     SRLevelEffects(5)="*** BONUS LEVEL 5|50% extra flame weapon damage|50% faster Flamethrower reload|50% faster Husk Gun charging|50% more flame weapon ammo|90% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|60% discount on flame weapons|Spawn with a MAC-10"
     SRLevelEffects(6)="*** BONUS LEVEL 6|60% extra flame weapon damage|60% faster Flamethrower reload|60% faster Husk Gun charging|60% more flame weapon ammo|90% resistance to fire|100% extra Flamethrower range|Grenades set enemies on fire|70% discount on flame weapons|Spawn with a Flamethrower"
     VeterancyName="FirebugT"
}
