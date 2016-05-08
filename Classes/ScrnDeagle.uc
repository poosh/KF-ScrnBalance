class ScrnDeagle extends Deagle;


simulated function bool PutDown()
{
	if ( Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnDualDeagle' )
	{
		bIsReloading = false;
	}

	return super(KFWeapon).PutDown();
}


function GiveTo( pawn Other, optional Pickup Pickup )
{
	local KFPlayerReplicationInfo KFPRI;
	local KFWeaponPickup WeapPickup;

	KFPRI = KFPlayerReplicationInfo(Other.PlayerReplicationInfo);
	WeapPickup = KFWeaponPickup(Pickup);
	
	//pick the lowest sell value
	if ( WeapPickup != None && KFPRI != None && KFPRI.ClientVeteranSkill != none ) {
		SellValue = 0.75 * min(WeapPickup.Cost, WeapPickup.default.Cost 
			* KFPRI.ClientVeteranSkill.static.GetCostScaling(KFPRI, WeapPickup.class));
	}

	Super.GiveTo(Other,Pickup);
}

defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDeagleFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnDeaglePickup'
     ItemName="Handcannon SE"
	 Weight=4
}
