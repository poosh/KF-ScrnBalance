class ScrnFire_Dualies extends ScrnFire
    abstract;

var Dualies DualWeap;

var const bool bDefaultLeft;  // default pistol is the left one, alt - right
var protected bool bFireLeft;

var Emitter Flash2Emitter;

var Emitter         ShellEject2Emitter;          // The shell eject emitter
var name            ShellEject2BoneName;         // name of the shell eject bone

var name FireAnim2, FireAimedAnim2;

function PostBeginPlay()
{
    super.PostBeginPlay();
    DualWeap = Dualies(Weapon);
}

simulated function InitEffects()
{
    // don't even spawn on server
    if (Level.NetMode == NM_DedicatedServer || !Instigator.IsLocallyControlled())
        return;

    if (FlashEmitterClass != none) {
        if (FlashEmitter == none || FlashEmitter.bDeleteMe) {
            FlashEmitter = Weapon.Spawn(FlashEmitterClass);
            Weapon.AttachToBone(FlashEmitter, DualWeap.default.FlashBoneName);
        }
        if (Flash2Emitter == none || Flash2Emitter.bDeleteMe) {
            Flash2Emitter = Weapon.Spawn(FlashEmitterClass);
            Weapon.AttachToBone(Flash2Emitter, DualWeap.default.altFlashBoneName);
        }
    }

    if (SmokeEmitterClass != none) {
        if (SmokeEmitter == none || SmokeEmitter.bDeleteMe) {
            SmokeEmitter = Weapon.Spawn(SmokeEmitterClass);
        }
    }

    if (ShellEjectClass != none) {
        if (ShellEjectEmitter == none || ShellEjectEmitter.bDeleteMe) {
            ShellEjectEmitter = Weapon.Spawn(ShellEjectClass);
            Weapon.AttachToBone(ShellEjectEmitter, ShellEjectBoneName);
        }
        if (ShellEject2Emitter == none || ShellEject2Emitter.bDeleteMe){
            ShellEject2Emitter = Weapon.Spawn(ShellEjectClass);
            Weapon.AttachToBone(ShellEject2Emitter, ShellEject2BoneName);
        }
    }
}

simulated function DestroyEffects()
{
    super.DestroyEffects();

    if (ShellEject2Emitter != None)
        ShellEject2Emitter.Destroy();

    if (Flash2Emitter != None)
        Flash2Emitter.Destroy();
}

function DrawMuzzleFlash(Canvas Canvas)
{
    super.DrawMuzzleFlash(Canvas);

    if (ShellEject2Emitter != none)
        Canvas.DrawActor(ShellEject2Emitter, false, false, Weapon.DisplayFOV);
}

function FlashMuzzleFlash()
{
    if (Flash2Emitter == none || FlashEmitter == none)
        return;

    if (KFWeap.bAimingRifle) {
        if (FireAimedAnim == 'FireLeft_Iron') {
            Flash2Emitter.Trigger(Weapon, Instigator);
            if (ShellEjectEmitter != none)
                ShellEjectEmitter.Trigger(Weapon, Instigator);
        }
        else {
            FlashEmitter.Trigger(Weapon, Instigator);
            if (ShellEject2Emitter != none)
                ShellEject2Emitter.Trigger(Weapon, Instigator);
        }
    }
    else if(FireAnim == 'FireLeft') {
        Flash2Emitter.Trigger(Weapon, Instigator);
        if (ShellEjectEmitter != None)
            ShellEjectEmitter.Trigger(Weapon, Instigator);
    }
    else {
        FlashEmitter.Trigger(Weapon, Instigator);
        if (ShellEject2Emitter != None)
            ShellEject2Emitter.Trigger(Weapon, Instigator);
    }
}


//called after reload and on zoom toggle, sets next pistol to fire to sync with slide lock order
function SetPistolFireOrder(bool bNextFireLeft)
{
    bFireLeft = bNextFireLeft;

    if (bFireLeft != bDefaultLeft) {
        DualWeap.altFlashBoneName = DualWeap.default.FlashBoneName;
        DualWeap.FlashBoneName = DualWeap.default.altFlashBoneName;
        FireAnim2 = default.FireAnim;
        FireAimedAnim2 = default.FireAimedAnim;
        FireAnim = default.FireAnim2;
        FireAimedAnim = default.FireAimedAnim2;
    }
    else {
        DualWeap.altFlashBoneName = DualWeap.default.altFlashBoneName;
        DualWeap.FlashBoneName = DualWeap.default.FlashBoneName;
        FireAnim2 = default.FireAnim2;
        FireAimedAnim2 = default.FireAimedAnim2;
        FireAnim = default.FireAnim;
        FireAimedAnim = default.FireAimedAnim;
    }
}

function SwapPistolFireOrder()
{
    SetPistolFireOrder(!bFireLeft);
}

function bool GetPistolFireOrder()
{
    return bFireLeft;
}

event ModeDoFire()
{
    if ( !AllowFire() )
        return;

    super.ModeDoFire();

    InitEffects();
    SwapPistolFireOrder();
}



defaultproperties
{
    // Vanilla
    ShellEject2BoneName="Shell_eject_right"
    FireAnim2="FireLeft"
    FireAimedAnim2="FireLeft_Iron"
    FireAimedAnim="FireRight_Iron"
    RecoilRate=0.070000
    maxVerticalRecoilAngle=450
    maxHorizontalRecoilAngle=50
    ShellEjectClass=Class'ROEffects.KFShellEject9mm'
    ShellEjectBoneName="Shell_eject_left"
    StereoFireSoundRef="KF_9MMSnd.9mm_FireST"
    DamageMax=35
    Momentum=10500.000000
    bPawnRapidFireAnim=True
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=1.800000
    FireAnim="FireRight"
    FireLoopAnim=
    FireEndAnim=
    TweenTime=0.025000
    FireSound=SoundGroup'KF_9MMSnd.9mm_Fire'
    NoAmmoSound=Sound'KF_9MMSnd.9mm_DryFire'
    FireForce="AssaultRifleFire"
    FireRate=0.100000
    AmmoClass=Class'KFMod.SingleAmmo'
    AmmoPerFire=1
    ShakeRotMag=(X=75.000000,Y=75.000000,Z=250.000000)
    ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
    ShakeRotTime=3.000000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=10.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=2.000000
    BotRefireRate=0.250000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stMP'
    aimerror=30.000000
    Spread=0.015000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeDualies'
}
