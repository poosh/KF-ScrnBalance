// The base class for custom healing weapons that do not extend KFMedicGun
class ScrnCustomMedicGun extends KFWeapon abstract;

var bool bHealMessages;

var Sound HealSound;
var string HealSoundRef;
var class<Emitter> HealingFX;

var transient Vector HealLocation, ClientHealLocation;
var transient Rotator HealRotation;


replication
{
    reliable if( bNetDirty && Role == ROLE_Authority )
        HealRotation, HealLocation;
}

//=============================================================================
// Dynamic Asset Load
//=============================================================================
static function PreloadAssets(Inventory Inv, optional bool bSkipRefCount)
{
    local ScrnCustomMedicGun W;

    super.PreloadAssets(Inv, bSkipRefCount);

    default.HealSound = sound(DynamicLoadObject(default.HealSoundRef, class'Sound', true));

    W = ScrnCustomMedicGun(Inv);
    if (W != none) {
        W.HealSound = default.HealSound;
    }
}

static function bool UnloadAssets()
{
    super.UnloadAssets();
    default.HealSound = none;
    return true;
}


//=============================================================================
// Functions
//=============================================================================

simulated function PostNetReceive()
{
    if ( Role < ROLE_Authority && ClientHealLocation != HealLocation ) {
        ClientHealLocation = HealLocation;
        HitHealTarget(HealLocation, HealRotation);
    }
}

simulated function HitHealTarget(vector HitLocation, rotator HitRotation)
{
    HealLocation = HitLocation;
    HealRotation = HitRotation;

    if (Role == ROLE_Authority) {
       NetUpdateTime = Level.TimeSeconds - 1;
    }

    PlaySound(HealSound,,2.0);
    if (EffectIsRelevant(Location,false)) {
        Spawn(HealingFX,,, HitLocation, HitRotation);
    }
}

defaultproperties
{
    bHealMessages=true
    HealSoundRef="KF_MP7Snd.MP7_DartImpact"
    HealingFX=class'KFMod.HealingFX'
}
