class ScrnFire_HighROF extends ScrnFire
    abstract;

var sound FireEndSound;             // The sound to play at the end of the ambient fire sound
var sound FireEndStereoSound;       // The sound to play at the end of the ambient fire sound in first person stereo
var float AmbientFireSoundRadius;   // The sound radius for the ambient fire sound
var sound AmbientFireSound;         // How loud to play the looping ambient fire sound
var byte AmbientFireVolume;         // The ambient fire sound

var string FireEndSoundRef;
var string FireEndStereoSoundRef;
var string AmbientFireSoundRef;

static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnFire_HighROF ScrnSpawned;
    super.PreloadAssets(LevelInfo, Spawned);

    if (default.FireEndSoundRef != "")
        default.FireEndSound = sound(DynamicLoadObject(default.FireEndSoundRef, class'sound', true));

    if (LevelInfo.bLowSoundDetail || (default.FireEndStereoSoundRef == "" && default.FireEndStereoSound == none)) {
        default.FireEndStereoSound = default.FireEndSound;
    }
    else {
        default.FireEndStereoSound = sound(DynamicLoadObject(default.FireEndStereoSoundRef, class'Sound', true));
    }

    if (default.AmbientFireSoundRef != "") {
        default.AmbientFireSound = sound(DynamicLoadObject(default.AmbientFireSoundRef, class'sound', true));
    }

    ScrnSpawned = ScrnFire_HighROF(Spawned);
    if (ScrnSpawned != none) {
        ScrnSpawned.FireEndSound = default.FireEndSound;
        ScrnSpawned.FireEndStereoSound = default.FireEndStereoSound;
        ScrnSpawned.AmbientFireSound = default.AmbientFireSound;
    }
}

static function bool UnloadAssets()
{
    super.UnloadAssets();

    default.FireEndSound = none;
    default.FireEndStereoSound = none;
    default.AmbientFireSound = none;

    return true;
}

// Sends the fire class to the looping state
function StartFiring()
{
    if (bWaitForRelease || !bHasFireLoop) {
        super.StartFiring();
        return;
    }

    GotoState('FireLoop');
}

function PlayFireEnd()
{
    if (!bWaitForRelease || !bHasFireLoop) {
        super.PlayFireEnd();
    }
}

// Handles toggling the weapon attachment's ambient sound on and off
function PlayAmbientSound(Sound aSound)
{
    local WeaponAttachment WA;

    WA = WeaponAttachment(Weapon.ThirdPersonActor);

    if (Weapon == none || WA == none)
        return;

    if (aSound == none) {
        WA.SoundVolume = WA.default.SoundVolume;
        WA.SoundRadius = WA.default.SoundRadius;
    }
    else {
        WA.SoundVolume = AmbientFireVolume;
        WA.SoundRadius = AmbientFireSoundRadius;
    }

    WA.AmbientSound = aSound;
}

event ModeDoFire()
{
    if (bWaitForRelease || !bHasFireLoop) {
        super.ModeDoFire();
    }
    // else must fire from the FireLoop state
}

state FireLoop
{
    // Ignored because we play an anbient fire sound
    function PlayFiring() {}
    function ServerPlayFiring() {}


    function BeginState()
    {
        NextFireTime = Level.TimeSeconds  - 0.000001; //fire now!

        if (KFWeap.bAimingRifle) {
            Weapon.LoopAnim(FireLoopAimedAnim, FireLoopAnimRate, TweenTime);
        }
        else {
            Weapon.LoopAnim(FireLoopAnim, FireLoopAnimRate, TweenTime);
        }
        PlayAmbientSound(AmbientFireSound);
    }

    function EndState()
    {
        Weapon.AnimStopLooping();
        PlayAmbientSound(none);
        if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled()
                && Weapon.Instigator.IsFirstPerson() && StereoFireSound != none ) {
            Weapon.PlayOwnedSound(FireEndStereoSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius,,false);
        }
        else {
            Weapon.PlayOwnedSound(FireEndSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius);
        }
        Weapon.StopFire(ThisModeNum);
    }

    function StopFiring()
    {
        GotoState('');
    }

    function ModeTick(float dt)
    {
        Super.ModeTick(dt);

        if (!bIsFiring || !AllowFire() || bWaitForRelease) {
            GotoState('');
            return;
        }
    }
}


defaultproperties
{
    // vanilla
    AmbientFireSoundRadius=500.000000
    AmbientFireVolume=255
    FireAimedAnim="Fire_Iron"
    FireEndAimedAnim="Fire_Iron_End"
    FireLoopAimedAnim="Fire_Iron_Loop"
    bAccuracyBonusForSemiAuto=True
    bPawnRapidFireAnim=True
    TransientSoundVolume=1.800000
    FireLoopAnim="Fire_Loop"
    FireEndAnim="Fire_End"
    TweenTime=0.025000
    FireForce="AssaultRifleFire"
    AmmoPerFire=1
    BotRefireRate=0.100000
    aimerror=30.000000

    // ScrN
    bHasFireLoop=true
}
