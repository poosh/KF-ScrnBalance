class ScrnLAWFire extends LAWFire;

//disabled instant zoom out
function ServerPlayFiring()
{
    Super(KFShotgunFire).ServerPlayFiring();
}

//disabled instant zoom out
function PlayFiring()
{
    Super(KFShotgunFire).PlayFiring();
}

defaultproperties
{
     AmmoClass=class'ScrnLAWAmmo'
     ProjectileClass=class'ScrnLAWProj'
}
