class ScrnM99SniperRifle extends M99SniperRifle;

//disable skipping realod animation
//v4.39 - you need to reload, but can skip aiming animation
simulated function bool PutDown()
{
    if ( Level.TimeSeconds <  FireMode[0].NextFireTime - FireMode[0].FireRate * (1.0 - MinReloadPct)
            && AmmoAmount(0) >= FireMode[0].AmmoPerFire) {
        Instigator.PendingWeapon = none;
        return false;
    }

    FireMode[0].NextFireTime = Level.TimeSeconds - 0.01;
    return super.PutDown();
}


defaultproperties
{
    Weight=13
    FireModeClass(0)=class'ScrnM99Fire'
    MinReloadPct=0.800000
    PickupClass=class'ScrnM99Pickup'
    ItemName="M99AMR 'The NoobGun'"
    AttachmentClass=Class'ScrnM99Attachment'
}
