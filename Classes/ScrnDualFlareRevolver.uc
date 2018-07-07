class ScrnDualFlareRevolver extends DualFlareRevolver;

function bool HandlePickupQuery( pickup Item )
{
    if ( Item.InventoryType==Class'ScrnBalanceSrv.ScrnFlareRevolver' )
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
        SinglePistol = Spawn(Class'ScrnBalanceSrv.ScrnFlareRevolver');
        SinglePistol.SellValue = SellValue / 2;
        SinglePistol.GiveTo(Instigator);
        SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
        SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
        MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);
    }

    Pickup = Spawn(class'ScrnBalanceSrv.ScrnFlareRevolverPickup',,, StartLocation);

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
    if ( Instigator.PendingWeapon == none || Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnFlareRevolver' )
    {
        bIsReloading = false;
    }

    return super.PutDown();
}

defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualFlareRevolverFire'
     DemoReplacement=Class'ScrnBalanceSrv.ScrnFlareRevolver'
     PickupClass=Class'ScrnBalanceSrv.ScrnDualFlareRevolverPickup'
     ItemName="Dual Flare revolvers SE"
}
