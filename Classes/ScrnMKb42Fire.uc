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

static function bool UnloadAssets()
{
    default.BoltCloseSound = none;
    return super.UnloadAssets();
}

function DoCloseBolt()
{
    ScrnMKb42AssaultRifle(KFWeap).CloseBolt();

    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
    }
}

function ModeDoFire()
{
    if ( Instigator != none && Instigator.IsLocallyControlled() ) {
        if (KFWeap.MagAmmoRemaining <= 0 && !KFWeap.bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate )
                && !ScrnMKb42AssaultRifle(KFWeap).bBoltClosed )
        {
            LastFireTime = Level.TimeSeconds; //moved to allowfire
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
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMKb42AssaultRifle'
}
