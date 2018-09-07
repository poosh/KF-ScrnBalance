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

  // remove that shit, when you need to wait some time after switching back to this weapon,
  // if you skipped reload
  FireMode[0].NextFireTime = Level.TimeSeconds - 0.01;
  return super.PutDown();
}


defaultproperties
{
    Weight=13
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM99Fire'
    MinReloadPct=0.800000
    PickupClass=Class'ScrnBalanceSrv.ScrnM99Pickup'
    ItemName="M99AMR 'The NoobGun'"
}
