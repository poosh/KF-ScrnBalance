class ScrnThompsonDrumFire extends ThompsonDrumFire;

//close bolt if attempted to fire when empty
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).MagAmmoRemaining == 0 && !KFWeapon(Weapon).bIsReloading )
	{
    	if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnThompsonDrum(Weapon).MoveBoltForward(); //close bolt on empty chamber
	}
	return Super.AllowFire();
}

// fixes double shot bug -- PooSH
state FireLoop
{
    function BeginState()
    {
        super.BeginState();
        
        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
    }
}  

defaultproperties
{
     AmmoClass=Class'ScrnBalanceSrv.ScrnThompsonDrumAmmo'
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeThompsonDrum'
     

     RecoilRate=0.080000
     maxVerticalRecoilAngle=150
     maxHorizontalRecoilAngle=100
     DamageMax=40
     Momentum=12500.000000
     FireRate=0.085700
     Spread=0.012000
     SpreadStyle=SS_Random
}
