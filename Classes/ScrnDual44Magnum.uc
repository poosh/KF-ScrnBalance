class ScrnDual44Magnum extends Dual44Magnum;

function AttachToPawn(Pawn P)
{
    super(Dualies).AttachToPawn(P); // skip code duplication in Dual44Magnum
}

function bool HandlePickupQuery( pickup Item )
{
    if ( ClassIsChildOf(Item.InventoryType, Class'Magnum44Pistol') ) {
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
        SinglePistol = Spawn(Class'ScrnBalanceSrv.ScrnMagnum44Pistol');
        SinglePistol.SellValue = SellValue / 2;
        SinglePistol.GiveTo(Instigator);
        SinglePistol.Ammo[0].AmmoAmount = OtherAmmo;
        SinglePistol.MagAmmoRemaining = MagAmmoRemaining / 2;
        MagAmmoRemaining = Max(MagAmmoRemaining-SinglePistol.MagAmmoRemaining,0);
    }

    Pickup = Spawn(class'ScrnBalanceSrv.ScrnMagnum44Pickup',,, StartLocation);

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
    if ( Instigator.PendingWeapon == none || Instigator.PendingWeapon.class == class'ScrnBalanceSrv.ScrnMagnum44Pistol' )
    {
        bIsReloading = false;
    }

    return super.PutDown();
}



defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDual44MagnumFire'
     Description="A pair of 44 Magnum Pistols. Cowboy's best choise to clear Wild West for hordes of zeds!"
     DemoReplacement=Class'ScrnBalanceSrv.ScrnMagnum44Pistol'
     InventoryGroup=3
     PickupClass=Class'ScrnBalanceSrv.ScrnDual44MagnumPickup'
     ItemName="Dual 44 Magnums SE"
    Weight=4.000000     
}
