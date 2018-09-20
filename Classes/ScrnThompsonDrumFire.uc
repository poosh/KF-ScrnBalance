class ScrnThompsonDrumFire extends ThompsonDrumFire;

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnThompsonDrumFire ScrnSpawned;
    super.PreloadAssets(LevelInfo, Spawned);
	if ( default.BoltCloseSoundRef != "" )
	{
		default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
	}
    ScrnSpawned = ScrnThompsonDrumFire(Spawned);
    if ( ScrnSpawned != none )
    {
        ScrnSpawned.BoltCloseSound = default.BoltCloseSound;
    }
}

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

//sets bCloseBolt and plays sound
function CloseBolt()
{
    if (KFWeap != none)
        ScrnThompsonDrum(KFWeap).bBoltClosed = true;
    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
    }
    bClientEffectPlayed = true;
}

//setting bBoltClosed in a non simulated function test
function ModeDoFire()
{
    if (KFWeap.MagAmmoRemaining <= 0 && !KFWeapon(Weapon).bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate ) && !ScrnThompsonDrum(KFWeap).bBoltClosed )
    {
        LastFireTime = Level.TimeSeconds; //moved to allowfire
        ScrnThompsonDrum(KFWeap).MoveBoltForward(); //visual effect only
        CloseBolt(); //plays sound and sets bBoltClosed
        ScrnThompsonDrum(KFWeap).bBoltClosed = true; //attempt force setting it here
    }
    else
    {
        bClientEffectPlayed = false; //reset if not empty
    }
    Super.ModeDoFire();
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
     BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"

     RecoilRate=0.080000
     maxVerticalRecoilAngle=150
     maxHorizontalRecoilAngle=100
     DamageMax=40
     Momentum=12500.000000
     FireRate=0.085700
     Spread=0.012000
     SpreadStyle=SS_Random
}
