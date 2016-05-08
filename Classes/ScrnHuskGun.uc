/**
 * Attempt to make Husk Gun more usefull 
 *
 * @author PooSH, 2012
 */
 
class ScrnHuskGun extends HuskGun;

var float ChargeAmount; //defined here for replication purpose

replication
{
    reliable if (Role == ROLE_Authority && bNetDirty && bNetOwner)
        ChargeAmount;
}


//v8.41: fixed loosing bonus ammo on drop
function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    super(KFWeapon).GiveAmmo(m, WP, bJustSpawned);
}


//v2.60: Reload speed bonus affects charge rate
simulated function bool StartFire(int Mode)
{
    local ScrnHuskGunFire f;
    local KFPlayerReplicationInfo KFPRI;
    

	if ( super.StartFire(Mode) ) {
        f = ScrnHuskGunFire(FireMode[Mode]);
        if ( Mode == 0 && f != none ) {
            f.MaxChargeTime = f.default.MaxChargeTime;
            KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
            if ( KFPRI != none && KFPRI.ClientVeteranSkill != none)
                f.MaxChargeTime /= KFPRI.ClientVeteranSkill.static.GetReloadSpeedModifier(KFPRI, self);
        }
        return true;
    }
	return false;
}

defaultproperties
{
     Weight=9.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnHuskGunFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnHuskGunAltFire'
     Description="A fireball cannon ripped from the arm of a dead Husk. Does more damage when charged up. Fully-charged headshot stuns Scrake.|Alternate fire shoots Napalm, burning everything in 12m radius."
     PickupClass=Class'ScrnBalanceSrv.ScrnHuskGunPickup'
     ItemName="Husk Gun / Napalm Launcher"
}
