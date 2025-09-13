//
//=============================================================================
class ScrnFlameBurstFire extends FlameBurstFire;

simulated function bool AllowFire()
{
    local KFPawn KFP;

    if (KFWeap.bIsReloading)
        return false;

    KFP = KFPawn(Instigator);
    if (KFP != none && (KFP.SecondaryItem != none || KFP.bThrowingNade))
        return false;

    if (KFWeap.MagAmmoRemaining < AmmoPerFire) {
        if ( Level.TimeSeconds - LastClickTime > FireRate ) {
            if (NoAmmoSound != none)
                Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
            LastClickTime = Level.TimeSeconds;
            if(Weapon.HasAnim(EmptyAnim))
                weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
        }
        return false;
    }
    LastClickTime = Level.TimeSeconds;
    return super(WeaponFire).AllowFire();
}

defaultproperties
{
     ProjectileClass=class'ScrnFlameTendril'
     AmmoClass=class'ScrnFlameAmmo'
}
