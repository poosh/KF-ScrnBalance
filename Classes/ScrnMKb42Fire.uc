class ScrnMKb42Fire extends MKb42Fire;

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnMKb42Fire ScrnSpawned;
    super.PreloadAssets(LevelInfo, Spawned);
	if ( default.BoltCloseSoundRef != "" )
	{
		default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
	}
    ScrnSpawned = ScrnMKb42Fire(Spawned);
    if ( ScrnSpawned != none )
    {
        ScrnSpawned.BoltCloseSound = default.BoltCloseSound;
    }
}
/*
//play bolt close sound if firing single shot, because modedofire only works for automatic fire
simulated function bool AllowFire()
{
	if(!KFWeap.bIsReloading )
	{
        if( ( Level.TimeSeconds - LastFireTime>FireRate ) && KFWeap.MagAmmoRemaining <= 0 && !ScrnMKb42AssaultRifle(KFWeap).bBoltClosed)
        {
            LastFireTime = Level.TimeSeconds; //avoid spamming this
            ScrnMKb42AssaultRifle(KFWeap).MoveBoltForward(); //visual effect
            CloseBolt(); //set bool and play sound
            log("AllowFire ScrnMKb42 moved bolt forward at MagAmmoRemaining"@ ScrnMKb42AssaultRifle(KFWeap).MagAmmoRemaining, 'ScrnMKb42Fire');
            log("AllowFire ScrnMKb42 moved bolt forward, bBoltClosed is "@ ScrnMKb42AssaultRifle(KFWeap).bBoltClosed, 'ScrnMKb42Fire');
        }
	}
	return Super.AllowFire();
}
*/
//sets bCloseBolt and plays sound
function CloseBolt()
{
    if (KFWeap != none)
        ScrnMKb42AssaultRifle(KFWeap).bBoltClosed = true;
    if (BoltCloseSound != none && !bClientEffectPlayed)
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
        log("ClosedBolt() played empty sound, bBoltClosed is "@ ScrnMKb42AssaultRifle(KFWeap).bBoltClosed, 'ScrnMKb42Fire');
    }

}

//setting bBoltClosed in a non simulated function test
function ModeDoFire()
{
    if (KFWeap.MagAmmoRemaining <= 0 && !KFWeapon(Weapon).bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate ) && !ScrnMKb42AssaultRifle(KFWeap).bBoltClosed )
    {
        LastFireTime = Level.TimeSeconds; //moved to allowfire
        ScrnMKb42AssaultRifle(KFWeap).MoveBoltForward(); //visual effect only
        CloseBolt(); //plays sound and sets bBoltClosed
        ScrnMKb42AssaultRifle(KFWeap).bBoltClosed = true; //attempt force setting it here
        log("ModeDoFire ScrnMKb42 moved bolt forward, bBoltClosed is "@ ScrnMKb42AssaultRifle(KFWeap).bBoltClosed, 'ScrnMKb42Fire');
    }
    else
    {
        bClientEffectPlayed = false; //reset if not empty
    }
    Super.ModeDoFire();
}

defaultproperties
{
     BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMKb42AssaultRifle'
}
