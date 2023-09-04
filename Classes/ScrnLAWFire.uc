class ScrnLAWFire extends LAWFire;


function bool AllowFire()
{
     if (Weapon.Level.NetMode != NM_DedicatedServer && Instigator != none
               && Instigator.IsHumanControlled() && Instigator.IsLocallyControlled())
     {
          if (!KFWeapon(Weapon).bAimingRifle || KFWeapon(Weapon).bZoomingIn) {
               return false;
          }
     }
     return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire;
}


defaultproperties
{
     AmmoClass=class'ScrnLAWAmmo'
     ProjectileClass=class'ScrnLAWProj'
}
