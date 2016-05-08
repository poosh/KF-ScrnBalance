class ScrnMK23Pistol extends MK23Pistol;



simulated function bool PutDown()
{
	if ( Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnDualMK23Pistol' )
	{
		bIsReloading = false;
	}

	return super(KFWeapon).PutDown();
}

//original TWI code contained some gay issues like always -- by PooSH
function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType != none )
	{
		if ( KFPlayerController(Instigator.Controller) != none )
		{
			KFPlayerController(Instigator.Controller).PendingAmmo = WeaponPickup(Item).AmmoAmount[0];
		}

		return false; // Allow to "pickup" so this weapon can be replaced with dual MK23.
	}

	return Super(KFWeapon).HandlePickupQuery(Item);
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
     Weight=3.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnMK23Fire'
     Description="Match grade 45 caliber pistol. Good balance between power, ammo count and rate of fire. Damage is near to Magnum's, but has no bullet penetration."
     PickupClass=Class'ScrnBalanceSrv.ScrnMK23Pickup'
     ItemName="MK23 SE"
}
