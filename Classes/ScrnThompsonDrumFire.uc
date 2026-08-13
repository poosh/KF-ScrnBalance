class ScrnThompsonDrumFire extends ScrnFire_OpenBolt;

var float AmbientSoundPitchMult;

function WeaponCloseBolt()
{
    ScrnThompsonDrum(KFWeap).CloseBolt();
}

function bool IsBoltClosed()
{
    return ScrnThompsonDrum(KFWeap).bBoltClosed;
}

// C&P to add AmbientSoundPitchMult
function PlayFiring()
{
    local float RandPitch;

    if ( Weapon.Mesh != None )
    {
        if ( FireCount > 0 )
        {
            if( KFWeap.bAimingRifle )
            {
                if ( Weapon.HasAnim(FireLoopAimedAnim) )
                {
                    Weapon.PlayAnim(FireLoopAimedAnim, FireLoopAnimRate, 0.0);
                }
                else if( Weapon.HasAnim(FireAimedAnim) )
                {
                    Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
                }
                else
                {
                    Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
                }
            }
            else
            {
                if ( Weapon.HasAnim(FireLoopAnim) )
                {
                    Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
                }
                else
                {
                    Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
                }
            }
        }
        else
        {
            if( KFWeap.bAimingRifle )
            {
                if( Weapon.HasAnim(FireAimedAnim) )
                {
                    Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
                }
                else
                {
                    Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
                }
            }
            else
            {
                Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
            }
        }
    }


    if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled() &&
       Weapon.Instigator.IsFirstPerson() && StereoFireSound != none )
    {
        if( bRandomPitchFireSound )
        {
            RandPitch = FRand() * RandomPitchAdjustAmt;

            if( FRand() < 0.5 )
            {
                RandPitch *= -1.0;
            }
        }

        Weapon.PlayOwnedSound(StereoFireSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,(1.0*AmbientSoundPitchMult + RandPitch),false);
    }
    else
    {
        if( bRandomPitchFireSound )
        {
            RandPitch = FRand() * RandomPitchAdjustAmt;

            if( FRand() < 0.5 )
            {
                RandPitch *= -1.0;
            }
        }

        Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0*AmbientSoundPitchMult + RandPitch),false);
    }
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}

// Handles toggling the weapon attachment's ambient sound on and off
// Overriden to change ambient sound pitch (700rpm to 800rpm)
function PlayAmbientSound(Sound aSound)
{
    local WeaponAttachment WA;

    WA = WeaponAttachment(Weapon.ThirdPersonActor);

    if ( Weapon == none || (WA == none))
        return;

    if(aSound == None)
    {
        WA.SoundVolume = WA.default.SoundVolume;
        WA.SoundRadius = WA.default.SoundRadius;
        WA.SoundPitch = WA.default.SoundPitch * AmbientSoundPitchMult;
    }
    else
    {
        WA.SoundVolume = AmbientFireVolume;
        WA.SoundRadius = AmbientFireSoundRadius;
        WA.SoundPitch = 64 * AmbientSoundPitchMult;
    }

    WA.AmbientSound = aSound;
}


defaultproperties
{
    // vanilla
    FireEndSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop_End_M"
    FireEndStereoSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop_End_S"
    AmbientFireSoundRef="KF_IJC_HalloweenSnd.ThompsonSMG_Fire_Loop"
    ShellEjectClass=Class'ROEffects.KFShellEjectMP5SMG'
    ShellEjectBoneName="Shell_eject"
    bRandomPitchFireSound=False
    FireSoundRef="KF_IJC_HalloweenSnd.Thompson_Fire_Single_M"
    StereoFireSoundRef="KF_IJC_HalloweenSnd.Thompson_Fire_Single_S"
    NoAmmoSoundRef="KF_AK47Snd.AK47_DryFire"
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=350.000000)
    ShakeRotRate=(X=5000.000000,Y=5000.000000,Z=5000.000000)
    ShakeRotTime=0.750000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=7.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.250000
    BotRefireRate=0.150000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000

    // scrn
    AmmoClass=class'ScrnThompsonDrumAmmo'
    DamageType=class'ScrnDamTypeThompsonDrum'
    RecoilRate=0.040000 //0.080000
    maxVerticalRecoilAngle=150
    maxHorizontalRecoilAngle=100
    DamageMax=40
    Momentum=12500
    FireRate=0.071 //0.085700
    FireAnimRate=1.2
    AmbientSoundPitchMult=1.2
    Spread=0.012000
    SpreadStyle=SS_Random
}
