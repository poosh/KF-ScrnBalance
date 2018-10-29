class ScrnSPThompsonFire extends SPThompsonFire;


var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnSPThompsonFire ScrnSpawned;

    super.PreloadAssets(LevelInfo, Spawned);
    if ( default.BoltCloseSoundRef != "" )
    {
        default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
    }
    ScrnSpawned = ScrnSPThompsonFire(Spawned);
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
    ScrnSPThompsonSMG(KFWeap).CloseBolt();

    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
    }
}

//setting bBoltClosed in a non simulated function test
function ModeDoFire()
{
    if ( Instigator != none && Instigator.IsLocallyControlled() ) {
        if (KFWeap.MagAmmoRemaining <= 0 && !KFWeap.bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate )
                && !ScrnSPThompsonSMG(KFWeap).bBoltClosed )
        {
            LastFireTime = Level.TimeSeconds; 
            DoCloseBolt(); //plays sound and sets bBoltClosed
        }
        else
        {
            bClientEffectPlayed = false; //reset if not empty
        }
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
    DamageType=Class'ScrnBalanceSrv.ScrnDamTypeSPThompson'
    AmmoClass=Class'ScrnBalanceSrv.ScrnSPThompsonAmmo'
}