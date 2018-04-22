class ScrnDualies extends Dualies;

var transient int NumKillsWithoutReleasingTrigger;

function DropFrom(vector StartLocation)
{
    local int m;
    local KFWeaponPickup Pickup;
    local Inventory I;
    local int AmmoThrown,OtherAmmo;

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

    if( Instigator.Health>0 )
    {
        OtherAmmo = AmmoThrown/2;
        AmmoThrown-=OtherAmmo;
        I = Spawn(Class'ScrnBalanceSrv.ScrnSingle');
        I.GiveTo(Instigator);
        Weapon(I).Ammo[0].AmmoAmount = OtherAmmo;
        Single(I).MagAmmoRemaining = MagAmmoRemaining/2;
        MagAmmoRemaining = Max(MagAmmoRemaining-Single(I).MagAmmoRemaining,0);
    }
    Pickup = Spawn(class'ScrnBalanceSrv.ScrnSinglePickup',,, StartLocation);
    if ( Pickup != None )
    {
        Pickup.InitDroppedPickupFor(self);
        Pickup.DroppedBy = PlayerController(Instigator.Controller);
        Pickup.Velocity = Velocity;
        Pickup.AmmoAmount[0] = AmmoThrown;
        Pickup.MagAmmoRemaining = MagAmmoRemaining;
        if (Instigator.Health > 0)
            Pickup.bThrown = true;
    }

    Destroyed();
    Destroy();
}

function ServerStopFire(byte Mode)
{
    super.ServerStopFire(Mode);
    NumKillsWithoutReleasingTrigger = 0;
}

defaultproperties
{
     Weight=1
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnDualiesFire'
     DemoReplacement=Class'ScrnBalanceSrv.ScrnSingle'
     PickupClass=Class'ScrnBalanceSrv.ScrnDualiesPickup'
     ItemName="Dual 9mms SE"
}
