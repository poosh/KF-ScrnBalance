class ScrnDualDeagle extends DualDeagle;

function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType==Class'ScrnBalanceSrv.ScrnDeagle' )
	{
		if( LastHasGunMsgTime < Level.TimeSeconds && PlayerController(Instigator.Controller) != none )
		{
			LastHasGunMsgTime = Level.TimeSeconds + 0.5;
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages', 1);
		}

		return True;
	}

	return Super.HandlePickupQuery(Item);
}

function DropFrom(vector StartLocation)
{
	local int m;
	local KFWeaponPickup Pickup;
	local int AmmoThrown, OtherAmmo;
	local KFWeapon SinglePistol;

	if( !bCanThrow )
		return;

	AmmoThrown = AmmoAmount(0);
	ClientWeaponThrown();

	for (m = 0; m < NUM_FIRE_MODES; m++)
	{
		if (FireMode[m].bIsFiring)
			StopFire(m);
	}

	if ( Instigator != None )
		DetachFromPawn(Instigator);

	if( Instigator.Health > 0 )
	{
		OtherAmmo = AmmoThrown / 2;
		AmmoThrown -= OtherAmmo;
		SinglePistol = KFWeapon(Spawn(DemoReplacement));
		SinglePistol.SellValue = SellValue / 2;
		SinglePistol.GiveTo(Instigator);
		SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
		SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
		MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);
        
        Pickup = KFWeaponPickup(Spawn(SinglePistol.PickupClass,,, StartLocation));
	}
    else
        Pickup = KFWeaponPickup(Spawn(class<KFWeapon>(DemoReplacement).default.PickupClass,,, StartLocation));

	if ( Pickup != None )
	{
		Pickup.InitDroppedPickupFor(self);
		Pickup.DroppedBy = PlayerController(Instigator.Controller);
		Pickup.Velocity = Velocity;
		//fixing dropping exploit
		Pickup.SellValue = SellValue / 2;
		Pickup.Cost = Pickup.SellValue / 0.75; 
		Pickup.AmmoAmount[0] = AmmoThrown;
		Pickup.MagAmmoRemaining = MagAmmoRemaining;
		if (Instigator.Health > 0)
			Pickup.bThrown = true;
	}

    Destroyed();
	Destroy();
}

simulated function bool PutDown()
{
	if ( Instigator.PendingWeapon.class == DemoReplacement )
	{
		bIsReloading = false;
	}

	return super.PutDown();
}

defaultproperties
{
    Weight=6.000000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualDeagleFire'
    DemoReplacement=Class'ScrnBalanceSrv.ScrnDeagle'
    PickupClass=Class'ScrnBalanceSrv.ScrnDualDeaglePickup'
    ItemName="Dual Handcannons SE"

    HudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.dual_handcannon"
    SelectSoundRef="KF_HandcannonSnd.50AE_Select"
    MeshRef="KF_Weapons_Trip.Dual50_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.Pistols.deagle_cmb"
}
