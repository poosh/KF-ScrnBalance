class ScrnFire_OpenBolt extends ScrnFire_HighROF
    abstract;

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

// subclasses MUST override these
function WeaponCloseBolt();
function bool IsBoltClosed();


static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnFire_OpenBolt ScrnSpawned;

    super.PreloadAssets(LevelInfo, Spawned);

    if (default.BoltCloseSoundRef != "") {
        default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
    }

    ScrnSpawned = ScrnFire_OpenBolt(Spawned);
    if (ScrnSpawned != none) {
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
    WeaponCloseBolt();
    if (BoltCloseSound != none && !bClientEffectPlayed) {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
    }
}

function ModeDoFire()
{
    if (Instigator != none && Instigator.IsLocallyControlled()) {
        if (KFWeap.MagAmmoRemaining <= 0 && !MayClientHaveAmmo() && !KFWeap.bIsReloading
                && (Level.TimeSeconds - LastFireTime > FireRate) && !IsBoltClosed())
        {
            LastFireTime = Level.TimeSeconds;
            DoCloseBolt();
        }
        else {
            bClientEffectPlayed = false; //reset if not empty
        }
    }
    Super.ModeDoFire();
}

state FireLoop
{
    function ModeTick(float dt)
    {
        if (KFWeap.MagAmmoRemaining < 1) {
            DoCloseBolt();
        }
        Super.ModeTick(dt);
    }
}

defaultproperties
{
    BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"
}