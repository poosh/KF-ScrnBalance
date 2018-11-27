class ScrnAA12Fire extends AA12Fire;

var ScrnAA12AutoShotgun ScrnWeap; // To avoid casting, store the owning KFWeapon

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnAA12AutoShotgun(Weapon);
}

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFShotgunFire Spawned)
{
    local ScrnAA12Fire ScrnSpawned;

    super.PreloadAssets(LevelInfo, Spawned);
    if ( default.BoltCloseSoundRef != "" )
    {
        default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
    }
    ScrnSpawned = ScrnAA12Fire(Spawned);
    if ( ScrnSpawned != none )
    {
        ScrnSpawned.BoltCloseSound = default.BoltCloseSound;
    }
}

static function bool UnloadAssets()
{
    default.BoltCloseSound = none;
    return super.UnloadAssets();
}

function DoCloseBolt()
{
    ScrnWeap.CloseBolt();

    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
    }
}

function ModeDoFire()
{
    if ( Instigator != none && Instigator.IsLocallyControlled() && !AllowFire() ) {
        if (ScrnWeap.MagAmmoRemaining <= 0 && !ScrnWeap.bIsReloading && !ScrnWeap.bBoltClosed )
        {
            DoCloseBolt(); //plays sound and sets bBoltClosed
        }
        else
        {
            bClientEffectPlayed = false; //reset if not empty
        }
    }
    Super.ModeDoFire();
}

defaultproperties
{
    BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"
    ProjectileClass=Class'ScrnBalanceSrv.ScrnAA12Bullet'
    AmmoClass=Class'ScrnBalanceSrv.ScrnAA12Ammo'
    Spread=1125.000000
}
